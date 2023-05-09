# KF2-BuildTools
[![title](https://img.shields.io/badge/Help-Page-w)](https://github.com/GenZmeY/KF2-BuildTools)
[![version](https://img.shields.io/github/v/tag/genzmey/KF2-BuildTools)](https://github.com/GenZmeY/KF2-BuildTools/tags)
[![docs-autoupdate](https://github.com/GenZmeY/KF2-BuildTools/actions/workflows/docs-autoupdate.yml/badge.svg)](https://github.com/GenZmeY/KF2-BuildTools/actions/workflows/docs-autoupdate.yml)
```text
Usage: ./tools/builder OPTIONS

Compile, brew, test and upload your kf2 packages to the Steam Workshop.

Available options:
    -i, --init         generate builder.cfg and PublicationContent
    -c, --compile      compile package(s)
    -b, --brew         compress *.upk and place inside *.u
    -u, --upload       upload package(s) to the Steam Workshop
    -t, --test         run local single player test
    -f, --force        overwrites existing files when used with --init
    -q, --quiet        run without output
   -he, --hold-editor  do not close kf2editor automatically
   -nc, --no-colors    do not use color output
    -d, --debug        print every executed command (script debug)
    -v, --version      show version
    -h, --help         show this help

Short options can be combined, examples:
   -if                 recreate build.cfg and PublicationContent, replace old ones
  -cbu                 compile, brew, upload
 -cbhe                 compile and brew without closing kf2editor
                       etc...
```
