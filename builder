#!/bin/bash

# Copyright (C) 2022 GenZmeY
# mailto: genzmey@gmail.com

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.

# Requirements: git-bash
# https://git-scm.com/download/win

set -Eeuo pipefail

trap cleanup SIGINT SIGTERM ERR EXIT

function reg_readkey () # $1: path, $2: key
{
	cygpath -u "$(
	reg query "$1" //v "$2"      | \
	grep -F "$2"                 | \
	awk '{ $1=$2=""; print $0 }' | \
	sed -r 's|^\s*(.+)\s*|\1|g')"
}

# Whoami
ScriptFullname=$(readlink -e "$0")
ScriptName=$(basename "$0")
ScriptDir=$(dirname "$ScriptFullname")

# Common
SteamPath=$(reg_readkey "HKCU\Software\Valve\Steam" "SteamPath")
DocumentsPath=$(reg_readkey "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" "Personal")
ThirdPartyBin="$ScriptDir/3rd-party-bin"

# Usefull KF2 executables / Paths / Configs
KFDoc="$DocumentsPath/My Games/KillingFloor2"
KFPath="$SteamPath/steamapps/common/killingfloor2"
KFWin64="$KFPath/Binaries/Win64"
KFEditor="$KFWin64/KFEditor.exe"
KFEditorPatcher="$KFWin64/kfeditor_patcher.exe"
KFEditorMergePackages="$KFWin64/KFEditor_mergepackages.exe"
KFGame="$KFWin64/KFGame.exe"
KFWorkshop="$KFPath/Binaries/WorkshopUserTool.exe"
KFUnpublish="$KFDoc/KFGame/Unpublished"
KFPublish="$KFDoc/KFGame/Published"
KFEditorConf="$KFDoc/KFGame/Config/KFEditor.ini"

# Source filesystem
MutSource="$ScriptDir/.."
MutPubContent="$MutSource/PublicationContent"
MutConfig="$MutSource/Config"
MutLocalization="$MutSource/Localization"
MutBuildConfig="$MutSource/build.cfg"
MutTestConfig="$MutSource/test.cfg"

# Steam workshop upload filesystem
KFUnpublishBrewedPC="$KFUnpublish/BrewedPC"
KFUnpublishPackages="$KFUnpublishBrewedPC/Packages"
KFUnpublishScript="$KFUnpublishBrewedPC/Script"
KFUnpublishConfig="$KFUnpublish/Config"
KFUnpublishLocalization="$KFUnpublish/Localization"
KFPublishBrewedPC="$KFPublish/BrewedPC"
KFPublishPackages="$KFPublishBrewedPC/Packages"
KFPublishScript="$KFPublishBrewedPC/Script"
KFPublishConfig="$KFPublish/Config"
KFPublishLocalization="$KFPublish/Localization"

# Tmp files
MutWsInfo="$KFDoc/wsinfo.txt"
KFEditorConfBackup="$KFEditorConf.backup"

# Args
ArgInitBuild="false"
ArgInitTest="false"
ArgCompile="false"
ArgBrew="false"
ArgBrewManual="false"
ArgUpload="false"
ArgTest="false"
ArgVersion="false"
ArgHelp="false"
ArgDebug="false"
ArgQuiet="false"
ArgWarnings="false"
ArgNoColors="false"

# Colors
RED=''
GRN=''
YLW=''
BLU=''
DEF=''
BLD=''

function is_true () # $1: Bool arg to check
{
	echo "$1" | grep -Piq '^true$'
}

function get_latest () # $1: Reponame, $2: filename, $3: output filename
{
	local ApiUrl="https://api.github.com/repos/$1/releases/latest"
	local LatestTag=""
	LatestTag=$(curl --silent "$ApiUrl" | grep -Po '"tag_name": "\K.*?(?=")')
	local DownloadUrl="https://github.com/$1/releases/download/$LatestTag/$2"
	
	msg "download $2 ($LatestTag)"
	mkdir -p "$(dirname "$3")/"
	curl -LJs "$DownloadUrl" -o "$3"
	msg "${GRN}successfully downloaded${DEF}"
}

function get_latest_multini () # $1: file to save
{
	get_latest "GenZmeY/multini" "multini-windows-amd64.exe" "$1"
}

function get_latest_kfeditor_patcher () # $1: file to save
{
	get_latest "notpeelz/kfeditor-patcher" "kfeditor_patcher.exe" "$1"
}

function setup_colors ()
{
	if [[ -t 2 ]] && ! is_true "$ArgNoColors" && [[ "${TERM-}" != "dumb" ]]; then
		RED='\e[31m'
		GRN='\e[32m'
		YLW='\e[33m'
		BLU='\e[34m'
		DEF='\e[0m'
		BLD='\e[1m'
	fi
}

function err () # $1: String
{
	if ! is_true "$ArgQuiet"; then
		echo -e "${RED}${1-}${DEF}" >&2
	fi
}

function msg () # $1: String
{
	if ! is_true "$ArgQuiet"; then
		if is_true "$ArgDebug"; then
			echo -e "${BLU}${1-}${DEF}" >&1
		else
			echo -e "${DEF}${1-}${DEF}" >&1
		fi
	fi
}

function die () # $1: String, $2: Exit code
{
	err  "${1-}"
	exit "${2-3}"
}

function usage ()
{
	local HelpMessage=""
	
	HelpMessage=$(cat <<EOF
${BLD}Usage:${DEF} $0 OPTIONS

Build, pack, test and upload your kf2 packages to the Steam Workshop.

${BLD}Available options:${DEF}
   -ib, --init-build   generate $(basename "$MutBuildConfig") with build parameters
   -it, --init-test    generate $(basename "$MutTestConfig") with test parameters
    -i, --init         the same as "./$ScriptName --init-build; ./$ScriptName --init-test"
    -c, --compile      build package(s)
    -b, --brew         compress *.upk and place inside *.u
   -bm, --brew-manual  the same (almost) as above, but with patched kfeditor by @notpeelz
    -u, --upload       upload package(s) to the Steam Workshop
    -t, --test         run local single player test with $(basename "$MutTestConfig") parameters
    -q, --quiet        run without output
    -w, --warnings     do not close kf2editor automatically (to be able to read warnings)
   -nc, --no-colors    do not use color output
    -d, --debug        print every executed command (script debug)
    -v, --version      show version
    -h, --help         show this help

${BLD}Short options can be combined, examples:${DEF}
  -cbu                 compile, brew, upload
 -cbmt                 compile, brew_manual, run_test
  -wcb                 compile and brew without closing kf2editor
                       etc...
EOF
)
	msg "$HelpMessage"
}

function version ()
{
	msg "${BLD}$ScriptName $(git describe 2> /dev/null)${DEF}"
}

function cleanup()
{
	trap - SIGINT SIGTERM ERR EXIT
	restore_kfeditorconf
}

function backup_kfeditorconf ()
{
	msg "backup $(basename "$KFEditorConf") to $(basename "$KFEditorConfBackup")"
	cp -f "$KFEditorConf" "$KFEditorConfBackup"
}

function restore_kfeditorconf ()
{
	if [[ -f "$KFEditorConfBackup" ]]; then
		msg "restore $(basename "$KFEditorConf") from backup"
		mv -f "$KFEditorConfBackup" "$KFEditorConf"
	fi
}

function init_build ()
{
	local PackageList=""
	
	msg "creating new build config"
	
	:> "$MutBuildConfig"
	
	while read -r Package
	do
		if [[ -z "$PackageList" ]]; then
			PackageList="$Package"
		else
			PackageList="$PackageList $Package"
		fi
	done < <(find "$MutSource" -mindepth 2 -maxdepth 2 -type d -ipath '*/Classes' | sed -r 's|.+/([^/]+)/[^/]+|\1|' | sort)
	
	msg "packages found: $PackageList"
	
	cat > "$MutBuildConfig" <<EOF
# Build parameters 

# If True - compresses the mutator when compiling
# Scripts will be stored in binary form
# (reduces the size of the output file)
StripSource="True"

# Mutators to be compiled
# Specify them with a space as a separator,
# Mutators will be compiled in the specified order 
PackageBuildOrder="$PackageList"

# Mutators that will be uploaded to the workshop
# Specify them with a space as a separator,
# The order doesn't matter 
PackageUpload="$PackageList"
EOF

	msg "${GRN}$(basename "$MutBuildConfig") created${DEF}"
}

function read_build_settings ()
{
	if ! [[ -f "$MutBuildConfig" ]]; then init_build; fi
	
	if bash -n "$MutBuildConfig"; then
		# shellcheck source=./.shellcheck/build.cfg
		source "$MutBuildConfig"
	else
		die "$MutBuildConfig broken! Check this file before continue or create new one using --init-build option" 2
	fi
}

function read_test_settings ()
{
	if ! [[ -f "$MutTestConfig" ]]; then init_test;	fi
	
	if bash -n "$MutTestConfig"; then
		# shellcheck source=./.shellcheck/test.cfg
		source "$MutTestConfig"
	else
		die "$MutTestConfig broken! Check this file before continue or create new one using --init-test option" 2
		return 1
	fi
}

function merge_package () # $1: What, $2: Where
{
	local ModificationTime=""
	local ModificationTimeNew=""
	local PID=""
	
	msg "merge $1 into $2"
	
	if is_true "$ArgWarnings"; then
		CMD //C "cd /D $(cygpath -w "$KFWin64") && $(basename "$KFEditorMergePackages") make $1 $2"
	else
		ModificationTime=$(stat -c %y "$KFWin64/$2")
		CMD //C "cd /D $(cygpath -w "$KFWin64") && $(basename "$KFEditorMergePackages") make $1 $2" &
		PID="$!"
		while ps -p "$PID" &> /dev/null
		do
			ModificationTimeNew="$(stat -c %y "$KFWin64/$2")"
			if [[ "$ModificationTime" != "$ModificationTimeNew" ]]; then # wait for write
				while ps -p "$PID" &> /dev/null
				do
					ModificationTime="$ModificationTimeNew"
					sleep 1
					ModificationTimeNew="$(stat -c %y "$KFWin64/$2")"
					if [[ "$ModificationTime" == "$ModificationTimeNew" ]]; then # wait for write finish
						kill "$PID"
						rm -f "$KFWin64/$1" # cleanup (auto)
						return 0
					fi
				done
			fi
			sleep 1
		done
	fi
	
	rm -f "$KFWin64/$1" # cleanup (manual)
}

function merge_packages () # $1: Mutator name
{
	msg "merge packages for $1.u"
	
	cp -f "$KFUnpublishScript/$1.u" "$KFWin64"
	
	while read -r Upk
	do
		cp -f "$MutSource/$1/$Upk" "$KFWin64"
		merge_package "$Upk" "$1.u"
	done < <(find "$MutSource/$1" -type f -name '*.upk' -printf "%f\n")
}

function compiled ()
{
	for Package in $PackageBuildOrder
	do
		if ! test -f "$KFUnpublishScript/$Package.u"; then
			return 1
		fi
	done
}

function compile ()
{
	local StripSourceArg=""
	local PID=""
	
	read_build_settings

	if ! command -v multini &> /dev/null; then
		get_latest_multini "$ThirdPartyBin/multini.exe"
	fi
	
	backup_kfeditorconf
	
	multini --del "$KFEditorConf" 'ModPackages' 'ModPackages'
	for Package in $PackageBuildOrder
	do
		multini --add "$KFEditorConf" 'ModPackages' 'ModPackages' "$Package"
	done
	multini --set "$KFEditorConf" 'ModPackages' 'ModPackagesInPath' "$(cygpath -w "$MutSource")"
	
	rm -rf "$KFUnpublish" "$KFPublish"
	
	mkdir -p "$KFUnpublishPackages" "$KFUnpublishScript"
	
	for Package in $PackageBuildOrder
	do
		find "$MutSource/$Package" -type f -name '*.upk' -exec cp -f {} "$KFUnpublishPackages" \;
	done
	
	if [[ -d "$MutLocalization" ]]; then
		mkdir -p "$KFUnpublishLocalization"
		cp -rf "$MutLocalization"/* "$KFUnpublishLocalization"
	fi
	
	if [[ -d "$MutConfig" ]]; then
		mkdir -p "$KFUnpublishConfig"
		cp -rf "$MutConfig"/* "$KFUnpublishConfig"
	fi
	
	if is_true "$StripSource"; then StripSourceArg="-stripsource"; fi
	
	msg "compilation"
	
	if is_true "$ArgWarnings"; then
		CMD //C "$(cygpath -w "$KFEditor") make $StripSourceArg -useunpublished"
		if ! compiled; then
			die "compilation failed"
		fi
		msg "${GRN}successfully compiled${DEF}"
	else
		CMD //C "$(cygpath -w "$KFEditor") make $StripSourceArg -useunpublished" &
		PID="$!"
		while ps -p "$PID" &> /dev/null
		do
			if compiled; then
				kill "$PID"
				msg "${GRN}successfully compiled${DEF}"
				break
			fi
			sleep 1
		done
	fi
	
	find "$KFUnpublish" -type d -empty -delete
	
	restore_kfeditorconf
}

function publish_common ()
{
	if [[ -d "$MutLocalization" ]]; then
		mkdir -p "$KFPublishLocalization"
		cp -rf "$MutLocalization"/* "$KFPublishLocalization"
	fi
	
	if [[ -d "$MutConfig" ]]; then
		mkdir -p "$KFPublishConfig"
		cp -rf "$MutConfig"/* "$KFPublishConfig"
	fi
}

function brewed ()
{
	for Package in $PackageUpload
	do
		if ! test -f "$KFPublishBrewedPC/$Package.u"; then
			return 1
		fi
	done
}

function brew_cleanup ()
{
	for Package in $PackageBuildOrder
	do
		if ! echo "$PackageUpload" | grep -Pq "(^|\s+)$Package(\s+|$)"; then
			find "$KFPublishBrewedPC" -type f -name "$Package.u" -delete
			find "$MutSource/$Package" -type f -name '*.upk' -printf "%f\n" | xargs -I{} find "$KFPublishBrewedPC" -type f -name {} -delete
		fi
	done
	
	rm -f "$KFPublishBrewedPC"/*.tmp
}

function brew ()
{
	local PID=""
	
	msg "brewing"
	
	read_build_settings
	
	if ! compiled ; then
		die "You must compile packages before brewing. Use --compile option for this." 2
	fi
	
	rm -rf "$KFPublish"
	
	mkdir -p "$KFPublishBrewedPC"
	
	if is_true "$ArgWarnings"; then
		CMD //C "cd /D $(cygpath -w "$KFWin64") && $(basename "$KFEditor") brewcontent -platform=PC $PackageUpload -useunpublished"
		if ! brewed; then
			brew_cleanup
			die "brewing failed"
		fi
		msg "${GRN}successfully brewed${DEF}"
	else
		CMD //C "cd /D $(cygpath -w "$KFWin64") && $(basename "$KFEditor") brewcontent -platform=PC $PackageUpload -useunpublished" &
		PID="$!"
		while ps -p "$PID" &> /dev/null
		do
			if brewed; then
				kill "$PID"
				msg "${GRN}successfully brewed${DEF}"
				break
			fi
			sleep 1
		done
	fi
	
	publish_common
	brew_cleanup
	
	find "$KFPublish" -type d -empty -delete
}

function brew_manual ()
{
	msg "manual brewing"

	read_build_settings
	
	if ! compiled ; then
		die "You must compile packages before brewing. Use --compile option for this." 2
	fi
	
	rm -rf "$KFPublish"
	
	mkdir -p "$KFPublishBrewedPC"

	if ! [[ -x "$KFEditorPatcher" ]]; then
		get_latest_kfeditor_patcher "$KFEditorPatcher"
	fi
	
	msg "patching $(basename "$KFEditor")"
	CMD //C "cd /D $(cygpath -w "$KFWin64") && $(basename "$KFEditorPatcher")"
	msg "${GRN}successfully patched${DEF}"
	
	for Package in $PackageUpload
	do
		merge_packages "$Package"
		mv "$KFWin64/$Package.u" "$KFPublishBrewedPC"
	done
	
	msg "${GRN}successfully brewed${DEF}"
	
	publish_common
	
	find "$KFPublish" -type d -empty -delete
}

function publish_unpublished ()
{
	msg "${YLW}warn: uploading without brewing${DEF}"
	
	mkdir -p "$KFPublishBrewedPC" "$KFPublishScript" "$KFPublishPackages"
		
	for Package in $PackageUpload
	do
		cp -f "$KFUnpublishScript/$Package.u" "$KFPublishScript"
		find "$MutSource/$Package" -type f -name '*.upk' -exec cp -f {} "$KFPublishPackages" \;
	done
	
	publish_common
	
	find "$KFPublish" -type d -empty -delete
}

function upload ()
{
	local PreparedWsDir=""
	
	read_build_settings
	
	if ! compiled ; then
		die "You must compile packages before uploading. Use --compile option for this." 2
	fi
	
	if ! [[ -d "$KFPublish" ]]; then
		publish_unpublished
	fi
	
	find "$KFPublish" -type d -empty -delete
	
	PreparedWsDir=$(mktemp -d -u -p "$KFDoc")

	cat > "$MutWsInfo" <<EOF
\$Description "$(cat "$MutPubContent/description.txt")"
\$Title "$(cat "$MutPubContent/title.txt")"
\$PreviewFile "$(cygpath -w "$MutPubContent/preview.png")"
\$Tags "$(cat "$MutPubContent/tags.txt")"
\$MicroTxItem "false"
\$PackageDirectory "$(cygpath -w "$PreparedWsDir")"
EOF
	
	cp -rf "$KFPublish" "$PreparedWsDir"
	
	msg "upload to steam workshop"
	if is_true "$ArgQuiet"; then
		CMD //C "$(cygpath -w "$KFWorkshop") $(basename "$MutWsInfo")" &>/dev/null
	else
		CMD //C "$(cygpath -w "$KFWorkshop") $(basename "$MutWsInfo")"
	fi
	msg "${GRN}successfully uploaded to steam workshop${DEF}"
	
	rm -rf "$PreparedWsDir"
	rm -f "$MutWsInfo"
}

function init_test ()
{
	local AviableMutators=""
	local AviableGamemodes=""
	
	msg "creating new test config"
	
	read_build_settings
	
	for Package in $PackageUpload
	do
		# find available mutators
		while read -r MutClass
		do
			if [[ -z "$AviableMutators" ]]; then
				AviableMutators="$Package.$MutClass"
			else
				AviableMutators="$AviableMutators,$Package.$MutClass"
			fi
		done < <(grep -rihPo '\s.+extends\s(KF)?Mutator' "$MutSource/$Package" | awk '{ print $1 }')
		
		# find available gamemodes
		while read -r GamemodeClass
		do
			if [[ -z "$AviableGamemodes" ]]; then
				AviableGamemodes="$Package.$GamemodeClass"
			else
				AviableGamemodes="$AviableGamemodes,$Package.$GamemodeClass"
			fi
		done < <(grep -rihPo '\s.+extends\sKFGameInfo_' "$MutSource/$Package" | awk '{ print $1 }')
	done
	
	if [[ -n "$AviableMutators" ]]; then
		msg "mutators found: $AviableMutators"
	fi
	
	if [[ -z "$AviableGamemodes" ]]; then
		AviableGamemodes="KFGameContent.KFGameInfo_Survival"
	else
		msg "custom gamemodes found: $AviableGamemodes"
	fi
	
	cat > "$MutTestConfig" <<EOF
# Test parameters 

# Map:
Map="KF-Nuked"

# Game:
# Survival:       KFGameContent.KFGameInfo_Survival
# WeeklyOutbreak: KFGameContent.KFGameInfo_WeeklySurvival
# Endless:        KFGameContent.KFGameInfo_Endless
# Objective:      KFGameContent.KFGameInfo_Objective
# Versus:         KFGameContent.KFGameInfo_VersusSurvival
Game="$AviableGamemodes"

# Difficulty:
# Normal:         0
# Hard:           1
# Suicide:        2
# Hell:           3
Difficulty="0"

# GameLength:
# 4  waves:       0
# 7  waves:       1
# 10 waves:       2
GameLength="0"

# Mutators
Mutators="$AviableMutators"

# Additional parameters
Args=""
EOF

	msg "${GRN}$(basename "$MutTestConfig") created${DEF}"
}

function run_test ()
{
	local UseUnpublished=""
	
	read_build_settings
	read_test_settings
	
	if ! brewed; then
		UseUnpublished="-useunpublished"
		msg "run test (unpublished)"
	else
		msg "run test (brewed)"
	fi
	
	CMD //C "$(cygpath -w "$KFGame") $Map?Difficulty=$Difficulty?GameLength=$GameLength?Game=$Game?Mutator=$Mutators?$Args $UseUnpublished" -log
}

function parse_combined_params () # $1: Combined short parameters
{
	local Param="${1}"
	local Length="${#Param}"
	local Position=1
	
	while true
	do
		if [[ "$Position" -ge "$Length" ]]; then break; fi
		case "${Param:$Position:2}" in
			ib ) ((Position+=2)); ArgInitBuild="true"                      ;;
			it ) ((Position+=2)); ArgInitTest="true"                       ;;
			bm ) ((Position+=2)); ArgBrewManual="true"                     ;;
			nc ) ((Position+=2)); ArgNoColors="true"                       ;;
		esac
		
		if [[ "$Position" -ge "$Length" ]]; then break; fi
		case "${Param:$Position:1}" in
			h  ) ((Position+=1)); ArgHelp="true"                           ;;
			v  ) ((Position+=1)); ArgVersion="true"                        ;;
			i  ) ((Position+=1)); ArgInitBuild="true"; ArgInitTest="true"  ;;
			c  ) ((Position+=1)); ArgCompile="true"                        ;;
			b  ) ((Position+=1)); ArgBrew="true"                           ;;
			u  ) ((Position+=1)); ArgUpload="true"                         ;;
			t  ) ((Position+=1)); ArgTest="true"                           ;;
			d  ) ((Position+=1)); ArgDebug="true"                          ;;
			q  ) ((Position+=1)); ArgQuiet="true"                          ;;
			w  ) ((Position+=1)); ArgWarnings="true"                       ;;
			*  ) die "Unknown short option: -${Param:$Position:1}" 1       ;;
		esac
	done
}

function parse_params () # $@: Args
{
	while true
	do
		case "${1-}" in
			  -h | --help        ) ArgHelp="true"                          ;;
			  -v | --version     ) ArgVersion="true"                       ;;
			 -ib | --init-build  ) ArgInitBuild="true"                     ;;
			 -it | --init-test   ) ArgInitTest="true"                      ;;
			  -i | --init        ) ArgInitBuild="true"; ArgInitTest="true" ;;
			  -c | --compile     ) ArgCompile="true"                       ;;
			  -b | --brew        ) ArgBrew="true"                          ;;
			 -bm | --brew-manual ) ArgBrewManual="true"                    ;;
			  -u | --upload      ) ArgUpload="true"                        ;;
			  -t | --test        ) ArgTest="true"                          ;;
			  -d | --debug       ) ArgDebug="true"                         ;;
			  -q | --quiet       ) ArgQuiet="true"                         ;;
			  -w | --warnings    ) ArgWarnings="true"                      ;;
			 -nc | --no-color    ) ArgNoColors="true"                      ;;
			       --*           ) die "Unknown option: ${1}" 1            ;;
			  -*                 ) parse_combined_params "${1}"            ;;
			     *               ) if [[ -n "${1-}" ]]; then die "Unknown option: ${1-}" 1; fi; break ;;
		esac
		shift
	done
}

function main ()
{
	if [[ $# -eq 0 ]]; then usage; die "" 0; fi
	parse_params "$@"
	setup_colors
	export PATH="$PATH:$ThirdPartyBin"
	
	# Modifiers
	if is_true "$ArgDebug";      then set -o xtrace;	 fi
	
	# Actions
	if is_true "$ArgVersion";    then version; die "" 0; fi
	if is_true "$ArgHelp";       then usage;   die "" 0; fi
	if is_true "$ArgInitBuild";  then init_build;        fi
	if is_true "$ArgInitTest";   then init_test;         fi
	if is_true "$ArgCompile";    then compile;           fi
	if is_true "$ArgBrew";       then brew;              fi
	if is_true "$ArgBrewManual"; then brew_manual;       fi
	if is_true "$ArgUpload";     then upload;            fi
	if is_true "$ArgTest";       then run_test;          fi
}

main "$@"
