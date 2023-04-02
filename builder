#!/bin/bash

# Copyright (C) 2022-2023 GenZmeY
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
	if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
		cygpath -u "$(
		reg query "$1" //v "$2"      | \
		grep -F "$2"                 | \
		awk '{ $1=$2=""; print $0 }' | \
		sed -r 's|^\s*(.+)\s*|\1|g')"
	fi
}

# Whoami
ScriptFullname="$(readlink -e "$0")"
ScriptName="$(basename "$0")"
ScriptDir="$(dirname "$ScriptFullname")"

# Common
SteamPath="$(reg_readkey "HKCU\Software\Valve\Steam" "SteamPath")"
DocumentsPath="$(reg_readkey "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" "Personal")"
ThirdPartyBin="$ScriptDir/3rd-party-bin"
DummyPreview="$ScriptDir/dummy_preview.png"

# Usefull KF2 executables / Paths / Configs
KFDoc="$DocumentsPath/My Games/KillingFloor2"
KFPath="$SteamPath/steamapps/common/killingfloor2"
KFDev="$KFPath/Development/Src"
KFWin64="$KFPath/Binaries/Win64"
KFEditor="$KFWin64/KFEditor.exe"
KFEditorPatcher="$KFWin64/kfeditor_patcher.exe"
KFEditorMergePackages="$KFWin64/KFEditor_mergepackages.exe"
KFGame="$KFWin64/KFGame.exe"
KFWorkshop="$KFPath/Binaries/WorkshopUserTool.exe"
KFUnpublish="$KFDoc/KFGame/Unpublished"
KFPublish="$KFDoc/KFGame/Published"
KFEditorConf="$KFDoc/KFGame/Config/KFEditor.ini"
KFLogs="$KFDoc/KFGame/Logs"

# Source filesystem
MutSource="$(readlink -e "$ScriptDir/..")"
MutConfig="$MutSource/Config"
MutLocalization="$MutSource/Localization"
MutBrewedPCAddon="$MutSource/BrewedPC"
MutBuilderConfig="$MutSource/builder.cfg"
MutPubContent="$MutSource/PublicationContent"
MutPubContentDescription="$MutPubContent/description.txt"
MutPubContentTitle="$MutPubContent/title.txt"
MutPubContentPreview="$MutPubContent/preview"
MutPubContentTags="$MutPubContent/tags.txt"

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
ArgInit="false"
ArgCompile="false"
ArgBrew="false"
ArgUpload="false"
ArgTest="false"
ArgVersion="false"
ArgHelp="false"
ArgDebug="false"
ArgQuiet="false"
ArgHoldEditor="false"
ArgNoColors="false"
ArgForce="false"

# Colors
RED=''
GRN=''
YLW=''
BLU=''
DEF=''
BLD=''

# PNG
DummyPreviewRaw='\x89\x50\x4e\x47\x0d\x0a\x1a\x0a\x00\x00\x00\x0d\x49\x48\x44\x52\x00\x00\x00\x20\x00\x00\x00\x20\x01\x03\x00\x00\x00\x49\xb4\xe8\xb7\x00\x00\x00\x01\x73\x52\x47\x42\x00\xae\xce\x1c\xe9\x00\x00\x00\x04\x67\x41\x4d\x41\x00\x00\xb1\x8f\x0b\xfc\x61\x05\x00\x00\x00\x06\x50\x4c\x54\x45\x00\x00\x00\xff\xff\xff\xa5\xd9\x9f\xdd\x00\x00\x00\x09\x70\x48\x59\x73\x00\x00\x0e\xc4\x00\x00\x0e\xc4\x01\x95\x2b\x0e\x1b\x00\x00\x00\x14\x49\x44\x41\x54\x18\xd3\x63\x60\x60\xf8\xff\x9f\x9a\x04\x55\x4d\x63\x60\x00\x00\xed\xbd\x3f\xc1\xbb\x2a\xd9\x62\x00\x00\x00\x00\x49\x45\x4e\x44\xae\x42\x60\x82'

function is_true () # $1: Bool arg to check
{
	echo "$1" | grep -Piq '^true$'
}

function get_latest () # $1: Reponame, $2: filename, $3: output filename
{
	local ApiUrl="https://api.github.com/repos/$1/releases/latest"
	local LatestTag=""
	LatestTag="$(curl --silent "$ApiUrl" | grep -Po '"tag_name": "\K.*?(?=")')"
	local DownloadUrl="https://github.com/$1/releases/download/$LatestTag/$2"
	
	msg "download $2 ($LatestTag)"
	mkdir -p "$(dirname "$3")/"
	curl -LJs "$DownloadUrl" -o "$3"
	msg "successfully downloaded" "${GRN}"
}

function get_latest_multini () # $1: file to save
{
	get_latest "GenZmeY/multini" "multini-windows-amd64.exe" "$1"
}

function get_latest_kfeditor_patcher () # $1: file to save
{
	get_latest "notpeelz/kfeditor-patcher" "kfeditor_patcher.exe" "$1"
}

function repo_url () # $1: remote.origin.url
{
	if echo "$1" | grep -qoP '^https?://'; then
		echo "$1" | sed -r 's|\.git||'
	else
		echo "$1" | sed -r 's|^.+:(.+)\.git$|https://github.com/\1|' 
	fi
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

function msg () # $1: String, $2: Color code (global)
{
	if ! is_true "$ArgQuiet"; then
		if is_true "$ArgDebug"; then
			echo -e "${BLU}${2-}${1-}${DEF}" >&1
		else
			echo -e "${DEF}${2-}${1-}${DEF}" >&1
		fi
	fi
}

function die () # $1: String, $2: Exit code
{
	err  "${1-}"
	exit "${2-3}"
}

function warn () # $1: String
{
	msg "${1-}" "${YLW}"
}

function usage ()
{
	local HelpMessage=""
	
	HelpMessage="$(cat <<EOF
${BLD}Usage:${DEF} $0 OPTIONS

Compile, brew, test and upload your kf2 packages to the Steam Workshop.

${BLD}Available options:${DEF}
    -i, --init         generate $(basename "$MutBuilderConfig") and $(basename "$MutPubContent")
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

${BLD}Short options can be combined, examples:${DEF}
   -if                 recreate build.cfg and PublicationContent, replace old ones
  -cbu                 compile, brew, upload
 -cbhe                 compile and brew without closing kf2editor
                       etc...
EOF
)"
	msg "$HelpMessage"
}

function version ()
{
	local Version=""
	
	Version="$(git describe 2> /dev/null)"
	if [[ -z "$Version" ]]; then
		Version="(standalone)"
	fi

	msg "$ScriptName $Version" "${BLD}"
}

function cleanup()
{
	trap - SIGINT SIGTERM ERR EXIT
	restore_kfeditorconf
}

function backup_kfeditorconf ()
{
	if [[ -e "$KFEditorConf" ]]; then
		msg "backup $(basename "$KFEditorConf") to $(basename "$KFEditorConfBackup")"
		cp -f "$KFEditorConf" "$KFEditorConfBackup"
	else
		die "$(basename "$KFEditorConf") not found! Run KF2 Editor to generate the config" 2
	fi
}

function restore_kfeditorconf ()
{
	if [[ -f "$KFEditorConfBackup" ]]; then
		msg "restore $(basename "$KFEditorConf") from backup"
		mv -f "$KFEditorConfBackup" "$KFEditorConf"
	fi
}

function print_list () # $1: List with spaces, $2: New separator
{
	echo "${1// /$2}"
}

function init ()
{
	local PackageList=""
	local AviableMutators=""
	local AviableGamemodes=""
	local AviableMaps=""
	local ProjectName=""
	local GitUsername=""
	local GitRemoteUrl=""
	local PublicationTags=""
	local DefGamemode=""
	local DefMap=""
	local BaseList=""
	local BaseListNext=""
	
	if [[ -e "$MutBuilderConfig" ]]; then
		if is_true "$ArgForce"; then
			msg "rewriting $(basename "$MutBuilderConfig")"
		fi
	else
		msg "creating new $(basename "$MutBuilderConfig")"
	fi
	
	if [[ -d "$MutBrewedPCAddon" ]]; then
		while read -r Map
		do
			if [[ -z "$AviableMaps" ]]; then
				DefMap="$Map"
				AviableMaps="$Map"
			else
				AviableMaps="$AviableMaps $Map"
			fi
		done < <(find "$MutBrewedPCAddon" -type f -iname '*.kfm' -printf "%f\n" | sort)
	fi

	while read -r Package
	do
		if [[ -z "$PackageList" ]]; then
			PackageList="$Package"
		else
			PackageList="$PackageList $Package"
		fi
	done < <(find "$MutSource" -mindepth 2 -maxdepth 2 -type d -ipath '*/Classes' | sed -r 's|.+/([^/]+)/[^/]+|\1|' | sort)
	
	if [[ -n "$PackageList" ]]; then
		msg "packages found: $(print_list "$PackageList" ", ")"
	fi
	
	# DISCLAMER: BigO nightmare (*)
	# Remove seniors with a weak psyche from the screen
	# 
	# (*) As planned though:
	# Initialized once and quickly even on large projects,
	# There is no point in optimizing this
	if [[ -n "$PackageList" ]]; then
		# find available mutators
		BaseList='(KF)?Mutator'
		BaseListNext=''
		while [[ -n "$BaseList" ]]
		do
			for Base in $BaseList
			do
				for Package in $PackageList
				do
					while read -r Class
					do
						if [[ -z "$AviableMutators" ]]; then
							AviableMutators="$Package.$Class"
						else
							AviableMutators="$AviableMutators $Package.$Class"
						fi
						if [[ -z "$BaseListNext" ]]; then
							BaseListNext="$Class"
						else
							BaseListNext="$BaseListNext $Class"
						fi
					done < <(grep -rihPo "\s.+extends\s${Base}(\W|$)" "${MutSource}/${Package}" | awk '{ print $1 }')
				done
			done
			BaseList="$BaseListNext"
			BaseListNext=""
		done
		
		# find available gamemodes
		BaseList='KFGameInfo_'
		BaseListNext=''
		while [[ -n "$BaseList" ]]
		do
			for Base in $BaseList
			do
				for Package in $PackageList
				do
					while read -r Class
					do
						if [[ -z "$AviableGamemodes" ]]; then
							AviableGamemodes="$Package.$Class"
							if [[ -z "$DefGamemode" ]]; then
								DefGamemode="$Package.$Class"
							fi
						else
							AviableGamemodes="$AviableGamemodes $Package.$Class"
						fi
						if [[ -z "$BaseListNext" ]]; then
							BaseListNext="$Class"
						else
							BaseListNext="$BaseListNext $Class"
						fi
					done < <(grep -rihPo "\s.+extends\s${Base}(\W|$)" "${MutSource}/${Package}" | awk '{ print $1 }')
				done
			done
			BaseList="$BaseListNext"
			BaseListNext=""
		done
	fi
	
	if [[ -n "$AviableMutators" ]]; then
		msg "mutators found: $(print_list "$AviableMutators" ", ")"
	fi
	
	if [[ -z "$AviableGamemodes" ]]; then
		DefGamemode="KFGameContent.KFGameInfo_Survival"
	else
		msg "custom gamemodes found: $(print_list "$AviableGamemodes" ", ")"
	fi
	
	if [[ -z "$AviableMaps" ]]; then
		DefMap="KF-Nuked"
	else
		msg "maps found: $(print_list "$AviableMaps" ", ")"
	fi
	
	if is_true "$ArgForce" || ! [[ -e "$MutBuilderConfig" ]]; then
		cat > "$MutBuilderConfig" <<EOF
### Build parameters ###

# If True - compresses the mutator when compiling
# Scripts will be stored in binary form
# (reduces the size of the output file)
StripSource="True"

# Mutators to be compiled
# Specify them with a space as a separator,
# Mutators will be compiled in the specified order 
PackageBuildOrder="$PackageList"


### Brew parameters ###

# Packages you want to brew using @peelz's patched KFEditor.
# Useful for cases where regular brew doesn't put *.upk inside the package.
# Specify them with a space as a separator,
# The order doesn't matter 
PackagePeelzBrew=""


### Steam Workshop upload parameters ###

# Mutators that will be uploaded to the workshop
# Specify them with a space as a separator,
# The order doesn't matter 
PackageUpload="$PackageList"


### Test parameters ###

# Map:
Map="$DefMap"

# Game:
# Survival:       KFGameContent.KFGameInfo_Survival
# WeeklyOutbreak: KFGameContent.KFGameInfo_WeeklySurvival
# Endless:        KFGameContent.KFGameInfo_Endless
# Objective:      KFGameContent.KFGameInfo_Objective
# Versus:         KFGameContent.KFGameInfo_VersusSurvival
Game="$DefGamemode"

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
Mutators="$(print_list "$AviableMutators" ",")"

# Additional parameters
Args=""
EOF
		msg "$(basename "$MutBuilderConfig") created" "${GRN}"
	fi
	
	if ! [[ -d "$MutPubContent" ]]; then mkdir -p "$MutPubContent"; fi
	
	ProjectName="$(basename "$(readlink -e "$MutSource")")"
	
	if is_true "$ArgForce" || ! [[ -e "$MutPubContentTitle" ]]; then
		echo "$ProjectName" > "$MutPubContentTitle"
		msg "$(basename "$MutPubContentTitle") created" "${GRN}"
	fi
	
	if is_true "$ArgForce" || ! [[ -e "$MutPubContentDescription" ]]; then
		:> "$MutPubContentDescription"
		if [[ -n "$AviableGamemodes" ]] || [[ -n "$AviableMutators" ]] || [[ -n "$AviableMaps" ]]; then
			echo "[h1]Description[/h1]" >> "$MutPubContentDescription"
			if [[ -n "$AviableMaps" ]]; then
				echo "[b]Maps:[/b][list][*]$(print_list "$AviableMaps" '[*]')[/list]" >> "$MutPubContentDescription"
			fi
			if [[ -n "$AviableGamemodes" ]]; then
				echo "[b]Gamemodes:[/b][list][*]$(print_list "$AviableGamemodes" '[*]')[/list]" >> "$MutPubContentDescription"
			fi
			if [[ -n "$AviableMutators" ]]; then
				echo "[b]Mutators:[/b][list][*]$(print_list "$AviableMutators" '[*]')[/list]" >> "$MutPubContentDescription"
			fi
			echo "" >> "$MutPubContentDescription"
		fi
		
		GitRemoteUrl="$(repo_url "$(git config --get remote.origin.url)")"
		if [[ -n "$GitRemoteUrl" ]]; then
		{
			echo "[h1]Sources[/h1]"
			echo "[url=${GitRemoteUrl}]${GitRemoteUrl}[/url]"
			echo ""
		} >> "$MutPubContentDescription"
		fi
		
		GitUsername="$(git config --get user.name)"
		if [[ -n "$GitUsername" ]]; then
		{
			echo "[h1]Author[/h1]"
			echo "[url=https://github.com/${GitUsername}]${GitUsername}[/url]"
			echo ""
		} >> "$MutPubContentDescription"
		fi
		
		msg "$(basename "$MutPubContentDescription") created" "${GRN}"
	fi
	
	if is_true "$ArgForce" || [[ "$(preview_extension)" == "None" ]]; then
		if [[ -e "$DummyPreview" ]]; then
			cp -f "$DummyPreview" "${MutPubContentPreview}.png"
		else
			printf '%b' "$DummyPreviewRaw" > "${MutPubContentPreview}.png"
		fi
		msg "$(basename "${MutPubContentPreview}.png") created" "${GRN}"
	fi
	
	if is_true "$ArgForce" || ! [[ -e "$MutPubContentTags" ]]; then
		:> "$MutPubContentTags"
		if [[ -n "$AviableGamemodes" ]]; then
			PublicationTags="Gamemodes"
		fi
		if [[ -n "$AviableMutators" ]]; then
			if [[ -n "$PublicationTags" ]]; then
				PublicationTags="$PublicationTags,Mutators"
			else
				PublicationTags="Mutators"
			fi
			echo "$PublicationTags" >> "$MutPubContentTags"
		fi
		msg "$(basename "$MutPubContentTags") created" "${GRN}"
	fi
}

function preview_extension ()
{
	for Ext in gif png jpg jpeg
	do
		if [[ -e "${MutPubContentPreview}.${Ext}" ]]; then
			echo "$Ext"
			return 0
		fi
	done
	
	echo "None"
}

function read_settings ()
{
	if ! [[ -f "$MutBuilderConfig" ]]; then init; fi
	
	if bash -n "$MutBuilderConfig"; then
		# shellcheck source=./.shellcheck/builder.cfg
		source "$MutBuilderConfig"
	else
		die "$MutBuilderConfig broken! Check this file before continue or create new one using --force --init" 2
	fi
}

function merge_package () # $1: What, $2: Where
{
	local ModificationTime=""
	local ModificationTimeNew=""
	local PID=""
	
	msg "merge $1 into $2"
	
	if is_true "$ArgHoldEditor"; then
		pushd "$KFWin64" &> /dev/null
		CMD //C "$(basename "$KFEditorMergePackages")" make "$1" "$2"
		popd &> /dev/null
	else
		ModificationTime="$(stat -c %y "$KFWin64/$2")"
		pushd "$KFWin64" &> /dev/null
		CMD //C "$(basename "$KFEditorMergePackages")" make "$1" "$2" &
		popd &> /dev/null
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
		cp -f "$Upk" "$KFWin64"
		merge_package "$(basename "$Upk")" "$1.u"
	done < <(find "$MutSource/$1" -type f -iname '*.upk' -not -ipath "*/Weapons/*")
}

function parse_log () # $1: Logfile
{
	local File=''
	local FileUnix=''
	local FileCompact=''
	local Line=''
	local Message=''

	local I=1
	if grep -qP ' Error:(.+:)? Error, ' "$1"; then # check to prevent a very strange crash 
		while read -r Error
		do
			if [[ -z "$Error" ]]; then break; fi
			Message="$(echo "$Error" | sed -r 's|^.+Error:.+Error, (.+)$|\1|')"
			File="$(echo "$Error" | sed -r 's|^.+Error: ((.+)\(([0-9]+)\) : )?Error,(.+)$|\2|')"
			if [[ -n "$File" ]]; then
				FileUnix="$(cygpath -u "$File")"
				FileCompact="$(echo "$FileUnix" | sed -r "s|^$KFDev(.+)$|\1|")"
				Line="$(echo "$Error" | sed -r 's|^.+Error: ((.+)\(([0-9]+)\) : )?Error,(.+)$|\3|')"
				err "[$I] $FileCompact($Line): $Message"
			else
				err "[$I] $Message"
			fi
			((I+=1))
		done < <(grep -P ' Error:(.+:)? Error, ' "$1")
	fi
	
	if grep -qP ' Warning:(.+:)? Warning, ' "$1"; then # and here too
		while read -r Warning
		do
			if [[ -z "$Warning" ]]; then break; fi
			Message="$(echo "$Warning" | sed -r 's|^.+Warning:.+Warning, (.+)$|\1|')"
			if echo "$Message" | grep -qF 'Unknown language extension . Defaulting to INT'; then continue; fi
			File="$(echo "$Warning" | sed -r 's|^.+Warning: ((.+)\(([0-9]+)\) : )?Warning,(.+)$|\2|')"
			if [[ -n "$File" ]]; then
				FileUnix="$(cygpath -u "$File")"
				FileCompact="$(echo "$FileUnix" | sed -r "s|^$KFDev(.+)$|\1|")"
				Line="$(echo "$Warning" | sed -r 's|^.+Warning: ((.+)\(([0-9]+)\) : )?Warning,(.+)$|\3|')"
				warn "[$I] $FileCompact($Line): $Message"
			else
				warn "[$I] $Message"
			fi
			((I+=1))
		done < <(grep -P ' Warning:(.+:)? Warning, ' "$1")
	fi
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

function find_log ()
{
	find "$KFLogs" -type f -iname '*.log' -printf '%T+ %p\n' | sort -r | head -n1 | cut -f2- -d" "
}

function compile ()
{
	local StripSourceArg=""
	local PID=""
	local Logfile=""
	
	read_settings

	if ! command -v multini &> /dev/null; then
		get_latest_multini "$ThirdPartyBin/multini.exe"
	fi
	
	if [[ -z "$PackageBuildOrder" ]]; then
		die "No packages found! Check project filesystem, fix config and try again"
	fi
	
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
		find "$MutSource/$Package" -type f -iname '*.upk' -not -ipath "*/Weapons/*" -exec cp -f {} "$KFUnpublishPackages" \;
		find "$MutSource/$Package" -type d -iname 'WwiseAudio' -exec cp -rf {} "$KFUnpublishBrewedPC" \;
		find "$MutSource/$Package" -type d -iname 'Weapons' -exec cp -rf {} "$KFUnpublishPackages" \;
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
	
	if is_true "$ArgHoldEditor"; then
		CMD //C "$(cygpath -w "$KFEditor")" make $StripSourceArg -useunpublished
		parse_log "$(find_log)"
		if ! compiled; then
			die "compilation failed"
		fi
		msg "successfully compiled" "${GRN}"
	else
		CMD //C "$(cygpath -w "$KFEditor")" make $StripSourceArg -useunpublished &
		PID="$!"
		while ps -p "$PID" &> /dev/null
		do
			sleep 1
			Logfile="$(find_log)"
			if compiled; then
				msg "successfully compiled" "${GRN}"
				
				msg "wait for the log"
				while ! grep -qF 'Log file closed' "$Logfile"
				do
					sleep 1
				done
				kill "$PID"
				parse_log "$Logfile"
				break
			elif grep -qF 'Log file closed' "$Logfile"; then
				kill "$PID"
				parse_log "$Logfile"
				die "compilation failed"
			fi
		done
	fi
	
	find "$KFUnpublish" -type d -empty -delete
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
	
	if [[ -d "$MutBrewedPCAddon" ]]; then
		mkdir -p "$KFPublishBrewedPC"
		cp -rf "$MutBrewedPCAddon"/* "$KFPublishBrewedPC"
	fi
}

function brewed () # $1: Wait for packages
{
	for Package in $1
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
			find "$KFPublishBrewedPC" -type f -iname "$Package.u" -delete
			find "$MutSource/$Package" -type f -iname '*.upk' -printf "%f\n" | xargs -I{} find "$KFPublishBrewedPC" -type f -iname {} -delete
		fi
	done
}

function brew ()
{
	local PackageBrew=""
	local PID=""
	
	msg "brewing"
	
	read_settings
	
	if ! compiled; then
		die "You must compile packages before brewing. Use --compile option for this." 2
	fi
	
	if [[ -z "$PackagePeelzBrew" ]]; then
		PackageBrew="$PackageBuildOrder"
	else
		for Package in $PackageBuildOrder
		do
			if ! echo "$PackagePeelzBrew" | grep -Pq "(^|\s+)$Package(\s+|$)"; then
				PackageBrew="$Package "
			fi
		done
	fi
	
	rm -rf "$KFPublish"
	
	mkdir -p "$KFPublishBrewedPC" "$KFPublishPackages"
	
	for Package in $PackageBuildOrder
	do
		find "$MutSource/$Package" -type d -iname 'WwiseAudio' -exec cp -rf {} "$KFPublishBrewedPC" \;
		find "$MutSource/$Package" -type d -iname 'Weapons' -exec cp -rf {} "$KFPublishPackages" \;
	done
	
	if [[ -n "$PackageBrew" ]]; then
		if is_true "$ArgHoldEditor"; then
			pushd "$KFWin64" &> /dev/null
			CMD //C "$(basename "$KFEditor")" brewcontent -platform=PC "$PackageBrew" -useunpublished
			popd &> /dev/null
		else
			pushd "$KFWin64" &> /dev/null
			CMD //C "$(basename "$KFEditor")" brewcontent -platform=PC "$PackageBrew" -useunpublished &
			PID="$!"
			popd &> /dev/null
			while ps -p "$PID" &> /dev/null
			do
				if brewed "$PackageBrew"; then
					kill "$PID"
					break
				fi
				sleep 1
			done
		fi
		if ! brewed "$PackageBrew"; then
			brew_cleanup
			die "brewing failed"
		fi
	fi
	
	if [[ -n "$PackagePeelzBrew" ]]; then
		msg "peelz brewing"
		
		if ! [[ -x "$KFEditorPatcher" ]]; then
			get_latest_kfeditor_patcher "$KFEditorPatcher"
		fi
		
		msg "patching $(basename "$KFEditor")"
		pushd "$KFWin64" &> /dev/null
		CMD //C "$(basename "$KFEditorPatcher")"
		popd &> /dev/null
		msg "successfully patched" "${GRN}"
		
		for Package in $PackagePeelzBrew
		do
			merge_packages "$Package"
			mv "$KFWin64/$Package.u" "$KFPublishBrewedPC"
			find "$MutSource/$Package" -type f -iname '*.upk' -not -ipath '*/Weapons/*' -printf "%f\n" | xargs -I{} find "$KFPublishBrewedPC" -type f -iname {} -delete
		done
	fi
	
	msg "successfully brewed" "${GRN}"
	
	rm -f "$KFPublishBrewedPC"/*.tmp
	
	find "$KFPublish" -type d -empty -delete
}

function publish_unpublished ()
{
	warn "uploading without brewing${DEF}"
	
	mkdir -p "$KFPublishBrewedPC" "$KFPublishScript" "$KFPublishPackages"
		
	for Package in $PackageUpload
	do
		cp -f "$KFUnpublishScript/$Package.u" "$KFPublishScript"
		find "$MutSource/$Package" -type f -iname '*.upk' -not -ipath '*/Weapons/*' -exec cp -f {} "$KFPublishPackages" \;
		find "$MutSource/$Package" -type d -iname 'WwiseAudio' -exec cp -rf {} "$KFPublishBrewedPC" \;
		find "$MutSource/$Package" -type d -iname 'Weapons' -exec cp -rf {} "$KFPublishPackages" \;
	done
	
	find "$KFPublish" -type d -empty -delete
}

function upload ()
{
	local PreparedWsDir=""
	local Preview=""
	local Success="False"
	
	read_settings
	
	if ! compiled && ! test -d "$MutBrewedPCAddon"; then
		die "You must compile packages before uploading. Use --compile option for this." 2
	fi
	
	if [[ -d "$KFPublish" ]]; then
		brew_cleanup
	elif [[ -d "$KFUnpublish" ]]; then
		publish_unpublished
	fi
	
	publish_common
	
	Preview="${MutPubContentPreview}.$(preview_extension)"
	
	if ! [[ -e "$Preview" ]]; then
		die "No preview image in PublicationContent" 2
	elif [[ $(stat --printf="%s" "$Preview") -ge 1048576 ]]; then
		warn "The size of $(basename "$Preview") is greater than 1mb. Steam may prevent you from loading content with this image. if you get an error while loading - try using a smaller preview."
	fi
	
	find "$KFPublish" -type d -empty -delete
	
	# it's a bad idea to use the $KFPublish folder for upload
	# because in that case some files won't get uploaded to the workshop for some reason
	# so create a temporary folder to get around this
	PreparedWsDir="$(mktemp -d -u -p "$KFDoc")"

	cat > "$MutWsInfo" <<EOF
\$Description "$(cat "$MutPubContentDescription")"
\$Title "$(cat "$MutPubContentTitle")"
\$PreviewFile "$(cygpath -w "$Preview")"
\$Tags "$(cat "$MutPubContentTags")"
\$MicroTxItem "false"
\$PackageDirectory "$(cygpath -w "$PreparedWsDir")"
EOF
	
	cp -rf "$KFPublish" "$PreparedWsDir"
	
	msg "upload to steam workshop"
	while read -r Output
	do
		if echo "$Output" | grep -qiF 'Successfully uploaded workshop file to Steam'; then
			Success="True"
			break
		elif echo "$Output" | grep -qiF 'error'; then
			err "UploadTool: $Output"
		fi
	done < <("$KFWorkshop" "$(basename "$MutWsInfo")" 2>&1)
	
	rm -rf "$PreparedWsDir"
	rm -f "$MutWsInfo"
	
	if is_true "$Success"; then
		msg "successfully uploaded to steam workshop" "${GRN}"
	else
		die "upload to steam workshop failed" 2
	fi
}

function run_test ()
{
	local UseUnpublished=""
	
	read_settings
	
	if brewed "$PackageBuildOrder"; then
		msg "run test (brewed)"
	else
		UseUnpublished="-useunpublished"
		msg "run test (unpublished)"
	fi
	
	CMD //C "$(cygpath -w "$KFGame")" "$Map?Difficulty=$Difficulty?GameLength=$GameLength?Game=$Game?Mutator=$Mutators?$Args" "$UseUnpublished" -log
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
			he ) ((Position+=2)); ArgHoldEditor="true"               ;;
			nc ) ((Position+=2)); ArgNoColors="true"                 ;;
		esac
		
		if [[ "$Position" -ge "$Length" ]]; then break; fi
		case "${Param:$Position:1}" in
			h  ) ((Position+=1)); ArgHelp="true"                     ;;
			v  ) ((Position+=1)); ArgVersion="true"                  ;;
			i  ) ((Position+=1)); ArgInit="true"                     ;;
			c  ) ((Position+=1)); ArgCompile="true"                  ;;
			b  ) ((Position+=1)); ArgBrew="true"                     ;;
			u  ) ((Position+=1)); ArgUpload="true"                   ;;
			t  ) ((Position+=1)); ArgTest="true"                     ;;
			d  ) ((Position+=1)); ArgDebug="true"                    ;;
			q  ) ((Position+=1)); ArgQuiet="true"                    ;;
			f  ) ((Position+=1)); ArgForce="true"                    ;;
			*  ) die "Unknown short option: -${Param:$Position:1}" 1 ;;
		esac
	done
}

function parse_params () # $@: Args
{
	while true
	do
		case "${1-}" in
			  -h | --help        ) ArgHelp="true"                    ;;
			  -v | --version     ) ArgVersion="true"                 ;;
			  -i | --init        ) ArgInit="true"                    ;;
			  -c | --compile     ) ArgCompile="true"                 ;;
			  -b | --brew        ) ArgBrew="true"                    ;;
			  -u | --upload      ) ArgUpload="true"                  ;;
			  -t | --test        ) ArgTest="true"                    ;;
			  -d | --debug       ) ArgDebug="true"                   ;;
			  -q | --quiet       ) ArgQuiet="true"                   ;;
			 -he | --hold-editor ) ArgHoldEditor="true"              ;;
			 -nc | --no-color    ) ArgNoColors="true"                ;;
			  -f | --force       ) ArgForce="true"                   ;;
			       --*           ) die "Unknown option: ${1}" 1      ;;
			  -*                 ) parse_combined_params "${1}"      ;;
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
	if is_true "$ArgDebug";                         then set -o xtrace;            fi
	
	# Help
	if is_true "$ArgVersion" && is_true "$ArgHelp"; then version; usage; die "" 0; fi
	if is_true "$ArgVersion";                       then version;        die "" 0; fi
	if is_true "$ArgHelp";                          then usage;          die "" 0; fi
	
	# Backup
	if is_true "$ArgCompile" || is_true "$ArgBrew"; then backup_kfeditorconf;      fi
	
	# Actions
	if is_true "$ArgInit";                          then init;                     fi
	if is_true "$ArgCompile";                       then compile;                  fi
	if is_true "$ArgBrew";                          then brew;                     fi
	if is_true "$ArgUpload";                        then upload;                   fi
	if is_true "$ArgTest";                          then run_test;                 fi
	
	# Restore
	if is_true "$ArgCompile" || is_true "$ArgBrew"; then restore_kfeditorconf;     fi
}

main "$@"
