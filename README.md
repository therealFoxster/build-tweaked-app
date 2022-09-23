# build-tweaked-app
Shell script that makes building tweaked apps with [azule](https://github.com/Al4ise/Azule) easier

## Getting Started

Clone this repository:
```
git clone https://github.com/therealFoxster/build-tweaked-app.git
```

`cd` to the repository and run `sudo chmod -R +x .` to make all scripts in the directory executable.

## Usage

Create a sub-directory to store the .ipa file and tweaks to be injected. 
All tweaks must be placed in a sub-directory called `tweaks`. 
You may also create a sub-directory inside `tweaks/` to store tweaks that should not be injected. 

Example directory structure:
```
AppName/
├── app.ipa
└── tweaks/
    ├── me.foxster.tweak1_0.0.1_iphoneos-arm.deb
    ├── me.foxster.tweak2_0.0.1_iphoneos-arm.deb
    └── ignore/
        └── me.foxster.ignored-tweak_0.0.1_iphoneos-arm.deb
```

Run `build-tweaked-app.sh`, passing the directory created earlier as the first argument:
```
./build-tweaked-app.sh ./AppName/
```

## Example
### Directory Structure
```
.
├── YouTube/
│   ├── YouTube_17.37.3_com.google.ios.youtube_.ipa
│   └── tweaks/
│       ├── com.ps.noytpremium_1.0.3_iphoneos-arm.deb
│       ├── com.ps.youpip_1.7.10_iphoneos-arm.deb
│       ├── ignore/
│       │   ├── com.michaelmelita1.ytsideloadfix_0.0.1_iphoneos-arm.deb
│       │   ├── com.miwix.youtubezoom_2.1.3_iphoneos-arm.deb
│       │   ├── com.ps.ytsystemappearance_1.0.0_iphoneos-arm.deb
│       │   └── weeb.lillie.youtubedislikesreturn_1.6.6_iphoneos-arm.deb
│       ├── me.alfhaily.cercube_5.3.11_iphoneos-arm.deb
│       ├── me.foxster.donteatmycontent_1.0.0_iphoneos-arm.deb
│       ├── me.foxster.ytsideloadsigninfix_1.0.0_iphoneos-arm.deb
│       └── weeb.lillie.youtubedislikesreturn_1.6.8_iphoneos-arm.deb
├── build-tweaked-app.sh
└── vendor/
    ├── Azule/
    └── format-text
```

### Command
```
./build-tweaked-app.sh ./YouTube/
```

### Output
```
log: Found 6 tweaks in "tweaks/" directory: NoYTPremium, YouPiP, Cercube, DontEatMyContent, YTSideloadSignInFix, YouTubeDislikesReturn.
log: Extracting app information from "YouTube_17.37.3_com.google.ios.youtube_.ipa"...
log: Extracted app information.
log: Tweaks will be injected into YouTube.app (com.google.ios.youtube).
For each of the prompt below, press [ENTER] to use the default value.
==> Output filename: YouTube_17.37.3_tweaked.ipa
==> App display name: YouTube
==> App bundle ID: com.google.ios.youtube
==> App version: 17.37.3
==> Remove UISupportedDevices: y
==> Remove app extensions: y
==> Additional args for azule: 
log: Running azule...
...
log: Done.

Information (useful for AltStore source)
Name: YouTube
Bundle ID: com.google.ios.youtube
Version: 17.37.3
Version date: 2022-09-22T21:37:01-07:00
Tweaks injected: • NoYTPremium v1.0.3\n • YouPiP v1.7.10\n • Cercube v5.3.11\n • DontEatMyContent v1.0.0\n • YTSideloadSignInFix v1.0.0\n • YouTubeDislikesReturn v1.6.8\n 
Size: 121083343

```


