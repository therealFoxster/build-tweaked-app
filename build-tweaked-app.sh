#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd ) # https://stackoverflow.com/a/246128/19227228

format_text=$SCRIPT_DIR/vendor/format-text
azule=$SCRIPT_DIR/vendor/Azule/azule

function error {
	$format_text "error: " -bt red
	echo "$1"
}

function fatal_error {
	error "$1"
	exit 1
}

function log {
	$format_text "==> " -b
	echo "$1"
}

function input_prompt {
	$format_text "==> " -bt blue
	$format_text "$1" -b # Prompt
	[ ! -z $2 ] && echo -n " ($2)" # Default value
	$format_text ": " -b
}

function read_input {
	prompt=$1; default_value=$2

	input_prompt "$prompt" "$default_value"
	read input

	# If input is not empty, set returned_input to input, else set returned_input to default_value
	[[ "$(echo "$input" | xargs)" != "" ]] && returned_input="$input" || returned_input=$default_value

	echo -en "\033[1A\033[2K" # https://stackoverflow.com/a/9135153/19227228
	# \033[1A moves cursor to previous line
	# \033[2K erases line

	input_prompt "$prompt"; echo "$returned_input$3"
}

function validate_yesno {
	input=$(echo $1 | awk '{print tolower($0)}') # Convert input to lowercase
	input=${input:0:1} # Get first character of input
	
	if [[ $input != "y" ]] && [[ $input != "n" ]]; then
		error "Enter \"y\" or \"n\""
		yesno=false
		return
	fi

	yesno=true
}

echo -n "==> "
$format_text "Running $(basename $0)..." -bt blue -n

### Remove app extensions ###
yesno=false
while [ $yesno == false ]; do
	read_input "Customize output .ipa file" "n"
	validate_yesno $returned_input
done
customize=$returned_input

#######################
### Check directory ###
#######################

if [ -z $1 ]; then
	fatal_error "Please provide a directory"
elif [ ! -d $1 ]; then
	fatal_error "Unable to find directory \"$1\""
fi

cd $1
log "Taking a look at \"$1\"..."

temp="$PWD/temp"
output="$PWD/products"

####################
### Check tweaks ###
####################

if [ ! -d ./tweaks/ ]; then
	fatal_error "Unable to find \"tweaks/\" directory."
else # Get tweak count
	num_tweaks=$(ls ./tweaks/*.deb 2> /dev/null | wc -l | xargs)
	if [[ num_tweaks -eq 0 ]]; then
		fatal_error "Unable to find any tweaks. Place tweaks inside the \"tweaks/\" directory before proceeding."
	fi
fi

# Logging tweak count
str="Found $num_tweaks tweak"
[ $num_tweaks -gt 1 ] && str="${str}s" # Add "s" if there are more than 1 tweak
str="${str} in \"tweaks/\" directory:"

tweak_paths=$(ls -d "$PWD"/tweaks/*.deb)

rm -rf $temp # Remove temp/ if exists
mkdir -p $temp # Make temp/

count=0
for tweak_path in $tweak_paths; do
	count=$((count+1))
	
	cp $tweak_path "$temp/" # Copy tweak to temp/
	tweak_path="$temp/$(basename $tweak_path)" # Set tweak_path to temp tweak path
	dpkg -x $tweak_path "$temp/temp/" # Extract tweak package content to temp/temp/
	
	tweak_filename=$(basename $(ls $temp/temp/Library/MobileSubstrate/DynamicLibraries/*.dylib))
	tweak_name=${tweak_filename%%.*} # Remove .deb extension
	
	# Add tweak name to str (to be logged)
	[[ count -gt 1 ]] && str="${str}," # If not first tweak, add comma before tweak_name
	str="$str $tweak_name"

	tweaks_str="${tweaks_str}• $tweak_name" # String containing tweaks and their versions (if any)

	# https://stackoverflow.com/a/63821654/19227228
	version=$(echo $(basename $tweak_path) | cut -d '_' -f2) # Getting version from tweak_path
	
	# Check if version starts with a number; if not then it might not be a version so won't be added to the string
	[ ${version:0:1} -eq ${version:0:1} 2>/dev/null ] && version_ok=true || version_ok=false
	# If version_ok, add to string
	[[ $version_ok == true ]] && tweaks_str="$tweaks_str v$version" 
	# Add newline character to string
	tweaks_str="$tweaks_str\n" 

	rm -rf "$temp/temp" # Remove temp/temp/
done

rm -rf $temp # Remove temp/ if exists

log "$str."

#######################
### Check .ipa file ###
#######################

num_ipas=$(ls ./*.ipa 2> /dev/null | wc -l | xargs)
if [[ num_ipas -eq 0 ]]; then
	fatal_error "Unable to find any .ipa files."
elif [[ num_ipas -gt 1 ]]; then
	fatal_error "Found too many ($num_ipas) .ipa files."
fi

# Extracting .ipa file
ipa=$(ls $PWD/*.ipa)
# log $ipa

log "Extracting app information from \"$(basename $ipa)\"..."

rm -rf $temp # Remove temp/ if exists
mkdir -p $temp # Make temp/
cp $ipa $temp # Copy .ipa file to temp/
temp_ipa=$(ls $temp/*.ipa)
mv $temp_ipa "$temp/ipa.zip" # .ipa -> .zip
unzip -q "$temp/ipa.zip" -d $temp # unzip quietly (-q) into $temp (-d)
payload=$(ls -d $temp/Payload/*.app)

app_name=$(defaults read "$payload/Info" CFBundleDisplayName)
app_bundle_id=$(defaults read "$payload/Info" CFBundleIdentifier)
app_version=$(defaults read "$payload/Info" CFBundleVersion)

output_filename="${app_name}_${app_version}_tweaked"
remove_uisupporteddevices="y"
remove_extensions="y"
add_args=""

log "Extracted app information."
rm -rf $temp # Remove temp/

log "Tweaks will be injected into $app_name.app ($app_bundle_id)."

##################
### User input ###
##################

if [[ $customize == "y" ]]; then
	log "$($format_text 'For each of the following input prompt, press' -bt blue) $($format_text '[ENTER]' -bt yellow) $($format_text 'to use the default value.' -bt blue)"

	### Display name ###
	read_input "App display name" "$app_name"
	app_name=$returned_input
	# log $app_name

	### Bundle ID ###
	read_input "App bundle ID" "$app_bundle_id"
	app_bundle_id=$returned_input
	# log $app_bundle_id

	### App version ###
	read_input "App version" "$app_version"
	app_version=$returned_input
	# log $app_version

	### Output filename ###
	output_filename="${app_name}_${app_version}_tweaked"
	read_input "Output filename" "$output_filename" ".ipa"
	output_filename=$returned_input
	# log $output_filename

	### Remove UISupportedDevices ###
	yesno=false
	while [ $yesno == false ]; do
		read_input "Remove UISupportedDevices" "y"
		validate_yesno $returned_input
	done
	remove_uisupporteddevices=$returned_input
	# log $remove_uisupporteddevices

	### Remove app extensions ###
	yesno=false
	while [ $yesno == false ]; do
		read_input "Remove app extensions" "y"
		validate_yesno $returned_input
	done
	remove_extensions=$returned_input
	# log $remove_extensions

	### Additional args for azule ###
	read_input "Additional args for azule"
	add_args="$returned_input"
	# log "$add_args"
fi

command="$azule -n $output_filename -i $ipa -o $output -f $tweak_paths -c $app_version -b $app_bundle_id -p $app_name"
[[ $remove_uisupporteddevices == "y" ]] && command="$command -u"
[[ $remove_extensions == "y" ]] && command="$command -e"
command="$command $add_args"

log "Running azule..."
if $command; then
	log "Done."
else
	fatal_error "An error occurred. Try running the script again."
fi

### Information (useful for AltStore source) ###
echo
$format_text "Information (useful for AltStore source)" -bnt blue
echo "Name: $app_name"
echo "Bundle ID: $app_bundle_id"
echo "Version: $app_version"
echo "Version date: $(sed 's/.\{2\}$/:&/' <<< $(date +"%Y-%m-%dT%H:%M:%S%z"))" # ISO 8601 date
echo "Tweaks injected: $tweaks_str"
app_size=$(ls -l "$output/$output_filename.ipa" | awk '{print $5}' | grep [0-9])
echo "Size: $app_size"
echo