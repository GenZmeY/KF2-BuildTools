# KF2-BuildTools
[![title](https://img.shields.io/badge/Help-Page-w)](https://github.com/GenZmeY/KF2-BuildTools)
[![version](https://img.shields.io/github/v/tag/genzmey/KF2-BuildTools)](https://github.com/GenZmeY/KF2-BuildTools/tags)
[![docs-autoupdate](https://github.com/GenZmeY/KF2-BuildTools/actions/workflows/docs-autoupdate.yml/badge.svg)](https://github.com/GenZmeY/KF2-BuildTools/actions/workflows/docs-autoupdate.yml)
```
Usage: ./tools/builder OPTIONS

Build, pack, test and upload your kf2 packages to the Steam Workshop.

Available options:
   -ib, --init-build   generate build.cfg with build parameters
   -it, --init-test    generate test.cfg with test parameters
    -i, --init         the same as "./builder --init-build; ./builder --init-test"
    -c, --compile      build package(s)
    -b, --brew         compress *.upk and place inside *.u
   -bm, --brew-manual  the same (almost) as above, but with patched kfeditor by @notpeelz
    -u, --upload       upload package(s) to the Steam Workshop
    -t, --test         run local single player test with test.cfg parameters
    -q, --quiet        run without output
    -w, --warnings     do not close kf2editor automatically (to be able to read warnings)
   -nc, --no-colors    do not use color output
    -d, --debug        print every executed command (script debug)
    -v, --version      show version
    -h, --help         show this help

Short options can be combined, examples:
  -cbu                 compile, brew, upload
 -cbmt                 compile, brew_manual, run_test
  -wcb                 compile and brew without closing kf2editor
                       etc...
```
