# KF2-BuildTools
[![version](https://img.shields.io/github/v/tag/genzmey/KF2-BuildTools)](https://github.com/GenZmeY/KF2-BuildTools/tags)
[![shellcheck](https://github.com/GenZmeY/KF2-BuildTools/actions/workflows/shellcheck-master.yml/badge.svg)](https://github.com/GenZmeY/KF2-BuildTools/actions/workflows/shellcheck-master.yml)
[![docs-autoupdate](https://github.com/GenZmeY/KF2-BuildTools/actions/workflows/docs-autoupdate.yml/badge.svg)](https://github.com/GenZmeY/KF2-BuildTools/actions/workflows/docs-autoupdate.yml)
[![license](https://img.shields.io/github/license/GenZmeY/KF2-Server-Extension)](LICENSE)

## Features:
- Build, brew, test and upload to Steam Workshop;
- No need to edit KFEditor.ini at all;
- Sources can be stored in any path;
- Easily switch between different projects.

## Add to your project
[git-bash](https://git-scm.com/) is the only thing you need. If you're already using git, you probably already have it. If not, [install it](https://git-scm.com/download/win).

**There are two options to add KF2-BuildTools to your project:**

### As git submodule
Make sure that the location of folders and files in your project is as follows (Correct it if it's not):  
`/<PackageName>/Classes/*uc`

Open git-bash and go to your project: `cd <your_project_path>`  
Then run the command:  
`git submodule add https://github.com/GenZmeY/KF2-BuildTools tools`  

**updating build tools:**  
Open git-bash and go to your project: `cd <your_project_path>`  
Get updates with the following command: `pushd tools && git pull && popd`  
Now if you run `git status` you can see that `tools` has changed: 
```
$ git status
On branch master
Your branch is up to date with 'origin/master'.

Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
        modified:   tools (new commits)

no changes added to commit (use "git add" and/or "git commit -a")
```
Commit the changes: `git add tools && git commit -m 'update tools'`

### As standalone script
Just create a `tools` folder and put [builder](builder) there.  
Now you can use the script in the same way as in the first case, but you will have to update it yourself.  

## If you are using someone else's project that has BuildTools...
If you haven't downloaded the project yet, just add `--recurse-submodules` when cloning it:  
`git clone --recurse-submodules <someone_else's_project>`  
If you have already downloaded the project, just run the command in the project folder:  
`git submodule update --init --recursive`  

## Usage (Basic)
If you have a simple mutator or game mode, then the usage is also simple:  
`./tools/builder --compile` build project  
`./tools/builder --test` start project test  
`./tools/builder --upload` upload/update your project to/in the steam workshop  

If you need help with commands, run: `./tools/builder --help`, or visit [this page](USAGE.md).

## Usage (Advanced)
If your project contains several mutators, *.upk files, external dependencies, or you want to customize the whole process in more detail, then this section is for you. 

### Prepare
**UNDER CONSTRUCTION**  

### Compilation
**UNDER CONSTRUCTION**  

### Brewing
**UNDER CONSTRUCTION**  

### Testing
**UNDER CONSTRUCTION**  

### Uploading to steam workshop
**UNDER CONSTRUCTION**  

## Other
[TODO List](TODO.md)

## License
[GNU GPLv3](LICENSE)
