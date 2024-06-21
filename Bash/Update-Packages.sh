#!/usr/bin/env bash

# Description:
#  Update all packages on the system.
#  This script checks for updates using the package manager of the system and updates all packages.

# Supported package managers:
# - apt (Debian/Ubuntu)
# - dnf (Fedora/CentOS/RHEL)

# Exit code 100 indicates that there are updates available
# Exit code 0 indicates that there are no updates available
# Exit code 127 indicates that the script failed to find a supported package manager

count=0
if [ "$(command -v apt)" ]; then
    # Update all packages using apt
    echo "[Info] Checking for updates using apt"
    apt update
    count=$(apt list --upgradable 2>/dev/null | grep -c -E '[0-9]\.[0-9]')
    if [[ "${count}" == "0" ]]; then
        # No updates available
        exit 0
    else
        echo "[Info] Updating ${count} packages using apt"
        apt upgrade -y
        exitcode=$?
        if [[ "${exitcode}" != "0" ]]; then
            echo "[Error] apt update failed with exit code ${exitcode}"
            exit 1
        fi
    fi
elif [ "$(command -v dnf)" ]; then
    # Update all packages using dnf
    echo "[Info] Checking for updates using dnf"
    count=$(dnf check-update 2>/dev/null | grep -c -E '[0-9]\.[0-9]')
    if [[ "${count}" == "0" ]]; then
        # No updates available
        exit 0
    else
        echo "[Info] Updating ${count} packages using dnf"
        dnf update -y
        exitcode=$?
        if [[ "${exitcode}" != "0" ]]; then
            echo "[Error] dnf update failed with exit code ${exitcode}"
            exit 1
        fi
    fi
else
    echo "Unsupported package manager"
    # Exit with the error code 127 to indicate that the script failed to find a supported package manager
    exit 127
fi

echo "All packages updated"
exit 0
