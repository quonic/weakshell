#!/usr/bin/env bash

# Description:
#  This script changes the default padding alignment for Unreal Engine Pak files to 1048576 bytes.
#  This is required to Steamworks uploads to work properly.

# Reference:
# https://partner.steamgames.com/doc/sdk/uploading

# Search for WinPlatform.Automation.cs
found=$(find . -name WinPlatform.Automation.cs)
readarray -t paths <<<"$found"

# Prompt the user to select the path from the array WinPlatformAutomationPath
PS3="Select the path: "
select path in "${paths[@]}"; do
    echo "[Info] ${path}"
    break
done

echo "Selected Path: ${paths[(($REPLY - 1))]}"
WinPlatformAutomationPath=${paths[(($REPLY - 1))]}

# Check if path contains Engine/Source/Programs/AutomationTool/Win/WinPlatform.Automation.cs
if [ -f "${WinPlatformAutomationPath}" ] && [ -r "${WinPlatformAutomationPath}" ] && [ -w "${WinPlatformAutomationPath}" ]; then

    _from='string PakParams = " -patchpaddingalign=2048";'
    _to='string PakParams = " -patchpaddingalign=1048576 -blocksize=1048576";'

    echo "[Info] Found (${WinPlatformAutomationPath})"

    if ! sed -i "s/${_from}/${_to}/g" "${WinPlatformAutomationPath}"; then
        echo "[Warn] Failed to update (${WinPlatformAutomationPath}). Exiting..."
        exit 1
    fi

    echo "[Info] Updated (${WinPlatformAutomationPath})"
else
    echo "[Error] Cannot find, read, or write to ${WinPlatformAutomationPath}. Exiting..."
    exit 1
fi
