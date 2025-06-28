# Build Tools
[![shellcheck](https://github.com/GenZmeY/KF2-BuildTools/actions/workflows/shellcheck.yml/badge.svg)](https://github.com/GenZmeY/KF2-BuildTools/actions/workflows/shellcheck.yml)
[![docs-autoupdate](https://github.com/GenZmeY/KF2-BuildTools/actions/workflows/docs-autoupdate.yml/badge.svg)](https://github.com/GenZmeY/KF2-BuildTools/actions/workflows/docs-autoupdate.yml)
[![version](https://img.shields.io/github/v/tag/genzmey/KF2-BuildTools)](CHANGELOG.md)
[![license](https://img.shields.io/github/license/GenZmeY/KF2-BuildTools)](COPYING)

## Description
Automation of mod assembly for [Killing Floor 2](https://store.steampowered.com/app/232090/Killing_Floor_2/) and some related actions.  

## Features
- Build, brew, test and upload to Steam Workshop  
- No need to edit KFEditor.ini at all  
- Sources can be stored in any path  
- Easily switch between different projects  

## Requirements
- [Killing Floor 2](https://store.steampowered.com/app/232090/Killing_Floor_2/);
- Killing Floor 2 - SDK;
- [git-bash](https://git-scm.com/download/win). **(\*)**

**(\*)** Should also work fine on [MSYS2](https://www.msys2.org/) with [git](https://packages.msys2.org/package/git) installed (`pacman -S git`). But I don't test it.  

## Add to your project
Make sure that the location of folders and files in your project as follows (Correct it if it's not):  
`/<PackageName>/Classes/*.uc`

**There are two ways to add KF2-BuildTools to your project:**  
### 1. As [git submodule](https://git-scm.com/book/en/v2/Git-Tools-Submodules)
Open git-bash and go to your project: `cd <your_project_path>`  
Add submodule: `git submodule add https://github.com/GenZmeY/KF2-BuildTools tools`  

**updating build tools (manual)**  
Get updates: `pushd tools && git pull origin master; popd`  
Commit the changes: `git add tools && git commit -m 'update build tools'`  

### 2. As standalone script
Just create a `tools` folder and put [builder](builder) there.  

## Updating build tools
Since version 1.9.0 build script can update itself:  
`./tools/builder --update`  

*if you have an older version you need to update once manually to start using this feature*  

## Usage
Available commands can be found here: [USAGE.md](USAGE.md)  

If you have a simple mutator or game mode, then the usage is also simple: just use [the commands](USAGE.md) to compile, test and upload to the steam workshop.

![demo](example.gif)

### The result can be found here
**Compiled packages:**  
`%USERPROFILE%\Documents\My Games\KillingFloor2\KFGame\Unpublished\`  

**Brewed packages:**  
`%USERPROFILE%\Documents\My Games\KillingFloor2\KFGame\Published\`  

**Uploaded packages:**  
your steam workshop 🙃  

## Usage (Advanced)
If your project contains several mutators, *.upk files, external dependencies, or you want to customize the whole process in more details, then this section is for you.  

### Setup
When you run compilation for the first time or do `./tools/builder --init` `builder.cfg` appears in your project folder.  
Edit it to set build/test/upload options. The config contains the necessary comments inside.  

Edit the files in the `PublicationContent` folder - they are responsible for the description in the Steam Workshop.  

### Project filesystem
If you have *.upk or localization files, they must be in a specific location.  

Change the filesystem of the project to such a form that everything works correctly:  
```text
📂 <ProjectName>
├── 📁 <SomePackageName1>
│   ├── 📁 Classes
│   │   ├── 📄 *.uc
│   │   └── 📄 *.upkg
│   ├── 📄 *.uci
│   └── 📦 *.upk
├── 📁 <SomePackageName2>
│   ├── 📁 Classes
│   │   ├── 📄 *.uc
│   │   └── 📄 *.upkg
│   ├── 📄 *.uci
│   └── 📦 *.upk
├── 📁 PublicationContent
│   ├── 🌆 preview.png
│   ├── 📄 description.txt
│   ├── 📄 tags.txt
│   └── 📄 title.txt
├── 📁 Localization
│   └── 📁 INT
│       └── 📄 *.int
├── 📁 Config
│   └── 📄 *.ini
├── 📁 BrewedPC
│   └── 📦 *.*
├── 📁 tools
│   └── ⚙️ builder
└── 📄 builder.cfg
```

**Note:** Use the `BrewedPC` folder for additional content such as sound files for your weapons or other stuff. This will be copied to the final BrewedPC before being uploaded to the workshop.  
By the way, this allows you to use a script to upload maps (although this was not its original purpose). Just put the map(s) in `BrewedPC` (don't forget to edit the `PublicationContent`) and run `./tools/builder -u`.  

## Troubleshooting
⚠️ Do not run the build while `KFEditor.exe` or `KFGame.exe` is running - they will interfere with the build. Running build separately will already allow you to avoid most problems.  

**The build is stuck but KFEditor.exe window doesn't disappear and shows successful compilation/brewing:**  
Make the KFEditor.exe window active and press CTRL+C.  

**The build is stuck at the "wait for the log" stage:**  
Stop the build, clear the logs folder:  
```
%USERPROFILE%\Documents\My Games\KillingFloor2\KFGame\Logs\
```
Then repeat the build.  

## Examples (Projects that use Build Tools)
**Simplest case (one mutator):**  
- [AdminAutoLogin](https://github.com/GenZmeY/KF2-AdminAutoLogin)
- [StartWave](https://github.com/GenZmeY/KF2-StartWave)
- [TAWOD](https://github.com/GenZmeY/KF2-TAWOD)
- [ZedSpawner](https://github.com/GenZmeY/KF2-ZedSpawner)

**Mutator + Localization:**  
- [ControlledVoteCollector](https://github.com/GenZmeY/KF2-ControlledVoteCollector)
- [CustomTraderInventory](https://github.com/GenZmeY/KF2-CustomTraderInventory)
- [YetAnotherScoreboard](https://github.com/GenZmeY/KF2-YetAnotherScoreboard)

**Two mutators are compiled, there are upk and localization:**  
- [ServerExtension](https://github.com/GenZmeY/KF2-Server-Extension)

**Three mutators are compiled (one of them is a dependency),**  
**two mutators are uploaded to the steam workshop:**  
- [UnofficialMod](https://github.com/GenZmeY/UnofficialMod)

## Contributors and Credits
- [amione](https://github.com/xamionex) - bug fixes  

## Status: Completed
- Build Tools works with the current version of the game (v1150) and I have implemented everything I planned.  
- Development has stopped: I no longer have the time or motivation to maintain this tool. No further updates or bug fixes are planned.  

## Mirrors
- https://github.com/GenZmeY/KF2-BuildTools  
- https://codeberg.org/GenZmeY/KF2-BuildTools  

## License
**GPL-3.0-or-later**  
  
[![license](https://www.gnu.org/graphics/gplv3-with-text-136x68.png)](COPYING)  
