# KF2-BuildTools
[![version](https://img.shields.io/github/v/tag/genzmey/KF2-BuildTools)](https://github.com/GenZmeY/KF2-BuildTools/tags)
[![shellcheck](https://github.com/GenZmeY/KF2-BuildTools/actions/workflows/shellcheck-master.yml/badge.svg)](https://github.com/GenZmeY/KF2-BuildTools/actions/workflows/shellcheck-master.yml)
[![docs-autoupdate](https://github.com/GenZmeY/KF2-BuildTools/actions/workflows/docs-autoupdate.yml/badge.svg)](https://github.com/GenZmeY/KF2-BuildTools/actions/workflows/docs-autoupdate.yml)
[![license](https://img.shields.io/github/license/GenZmeY/KF2-Server-Extension)](LICENSE)

# Features:
- Build, brew, test and upload to Steam Workshop;
- No need to edit KFEditor.ini at all;
- Sources can be stored in any path;
- Easily switch between different projects.

# Requirements
- [git-bash](https://git-scm.com/download/win)

# Add to your project
Make sure that the location of folders and files in your project is as follows (Correct it if it's not):  
`/<PackageName>/Classes/*.uc`

**There are two ways to add KF2-BuildTools to your project:
## 1. As [git submodule](https://git-scm.com/book/en/v2/Git-Tools-Submodules)
Open git-bash and go to your project: `cd <your_project_path>`  
Add submodule: `git submodule add https://github.com/GenZmeY/KF2-BuildTools tools`  

**updating build tools:**  
Get updates: `pushd tools && git pull && popd`  
Commit the changes: `git add tools && git commit -m 'update tools'`  

## 2. As standalone script
Just create a `tools` folder and put [builder](builder) there.  
Now you can use the script in the same way as in the first case, but you will have to update it yourself.  

# Usage
Available commands can be found here: [USAGE.md](USAGE.md)  

If you have a simple mutator or game mode, then the usage is also simple: just use [the commands](USAGE.md) to compile, test and upload to the steam workshop.

# Usage (Advanced)
If your project contains several mutators, *.upk files, external dependencies, or you want to customize the whole process in more detail, then this section is for you. 

## Prepare
**UNDER CONSTRUCTION**  

## Compilation
**UNDER CONSTRUCTION**  

## Brewing
**UNDER CONSTRUCTION**  

## Testing
**UNDER CONSTRUCTION**  

## Uploading to steam workshop
**UNDER CONSTRUCTION**  

# Other
[TODO List](TODO.md)

# License
[GNU GPLv3](LICENSE)
