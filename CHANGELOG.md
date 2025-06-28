# Changelog

## v1.9.2 (2023-05-12)
- add check of staged files so as not to add extra files to the commit

## v1.9.1 (2023-05-10)
- use version in update commit

## v1.9.0 (2023-05-10)
- feature: build script self-updating

## v1.8.2 (2023-05-10)
- little style fixes

## v1.8.1 (2023-05-01)
- fix unpublished test

## v1.8.0 (2023-04-03)
- add support for any steam library folders
- add checks for build dependencies (kf2/sdk)
- add a check for quotes in the description
- update ci/cd

## v1.7.2 (2023-04-03)
- redo the output of messages
- fix the build when stripsource is off

## v1.7.1 (2023-04-01)
- fix script for spaces in path

## v1.7.0 (2022-10-02)
- add weapons upk/bnk support

## v1.6.4 (2022-09-26)
- add KFEditor.ini check

## v1.6.3 (2022-09-08)
- removed idle start brew when it is not needed

## v1.6.2 (2022-09-02)
- fix looping if there is partial match in base class

## v1.6.1 (2022-09-02)
- fix BrewedPC check

## v1.6.0 (2022-09-02)
- make @peelz brew a parameter in the config
- refactor brewing
- *.upk can be in any subpath
- fixed project initialization: now it finds all available modes and mutators
- detection of maps in the project
- ability to add additional content to BrewedPC

## v1.5.0 (2022-06-06)
- add gif preview support
- add built-in dummy preview in case only the script file is used
- fixed validation of upload tool results

## v1.4.2 (2022-05-10)
- fixed search for last log file

## v1.4.1 (2022-03-24)
- fix log parsing: errors without specifying a file are now handled correctly
- script terminates if no package is found

## v1.4.0 (2022-03-20)
- compilation errors and warnings in terminal

## v1.3.3 (2022-03-20)
- edit KFEditor.ini for brewing to prevent annoying messages

## v1.3.2 (2022-03-20)
- add missing error checks

## v1.3.1 (2022-02-21)
- fix help text
- version and help options can be combined

## v1.3.0 (2022-02-21)
- auto-generated publication content
- one config file
- one --init option
- new parameter: --force

## v1.2.0 (2022-02-14)
- new argument parser
- new output system
- new parameters: quiet, warnings, no-colors

## v1.1.2 (2022-02-13)
- one file

## v1.1.1 (2022-01-24)
- remove empty directories before upload

## v1.1.0 (2022-01-24)
- add debug mode
- fix manual merge (merging multiple files)
- upload without brewing refactoring
- add brew cleanup

## v1.0.0 (2022-01-16)
- first version

## v0.0.1 (2022-01-12)
- first version, let's see how it works
