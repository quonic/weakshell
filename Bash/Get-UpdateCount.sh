#!/usr/bin/env bash

# Description:
#  Get the number of updates available.
#  This script checks for updates using the package manager of the system and returns the number of available updates.

# Supported package managers:
# - apt (Debian/Ubuntu)
# - dnf (Fedora/CentOS/RHEL)

# Exit code 100 indicates that there are updates available
# Exit code 0 indicates that there are no updates available
# Exit code 127 indicates that the script failed to find a supported package manager

count=0
if [ "$(command -v apt)" ]; then
    # Check for updates using apt
    apt update
    # Get the number of available updates
    count=$(apt list --upgradable 2>/dev/null | grep -c -E '[0-9]\.[0-9]')
elif [ "$(command -v dnf)" ]; then
    # Check for updates using dnf and get the number of available updates
    count=$(dnf check-update 2>/dev/null | grep -c -E '[0-9]\.[0-9]')
else
    echo "Unsupported package manager"
    # Exit with the error code 127 to indicate that the script failed to find a supported package manager
    exit 127
fi

echo "$count"
if [[ "${count}" == "0" ]]; then
    # No updates available
    exit 0
else
    # Use exit code 100 to indicate that there are updates available
    exit 100
fi
