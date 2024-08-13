#!/usr/bin/env bash
# -*- coding: utf-8 -*-

# Description:
#  A collection of bash functions for converting between different types of data.

# Converts a string to seconds
# Usage: convert_to_seconds <string>
# Example: convert_to_seconds "1d2h3m4s"
# Example: convert_to_seconds "1d 2h 3m 4s"
function convert_to_seconds() {
    local time_str="$1"
    local total_seconds=0

    if [[ -z "${time_str}" ]]; then
        return 1
    fi

    # Extract days
    if [[ "$time_str" =~ ([0-9]+)d ]]; then
        total_seconds=$((total_seconds + BASH_REMATCH[1] * 86400))
    fi

    # Extract hours
    if [[ "$time_str" =~ ([0-9]+)h ]]; then
        total_seconds=$((total_seconds + BASH_REMATCH[1] * 3600))
    fi

    # Extract minutes
    if [[ "$time_str" =~ ([0-9]+)m ]]; then
        total_seconds=$((total_seconds + BASH_REMATCH[1] * 60))
    fi

    # Extract seconds
    if [[ "$time_str" =~ ([0-9]+)s ]]; then
        total_seconds=$((total_seconds + BASH_REMATCH[1]))
    fi

    echo $total_seconds
}

function test_convert_to_seconds() {
    local red='\033[0;31m'
    local green='\033[0;32m'
    local reset='\033[0m'
    local should=$3
    local seconds
    if seconds=$(convert_to_seconds "$1"); then
        if [[ "$seconds" == "$2" ]]; then
            if [[ "$should" == "true" ]]; then
                echo -e "Should expect convert_to_seconds '$1' to return $2, returned ${green}$seconds${reset}"
            else
                echo -e "Should not expect convert_to_seconds '$1' to return $2, returned ${red}$seconds${reset}"
                return 1
            fi
        else
            if [[ "$should" == "true" ]]; then
                echo -e "Should expect convert_to_seconds '$1' to return $2, returned ${red}$seconds${reset}"
                return 1
            else
                echo -e "Should not expect convert_to_seconds '$1' to return $2, returned ${green}$seconds${reset}"
            fi
        fi
    else
        echo -e "Should not expect convert_to_seconds '$1' to return $2, returned ${red}null${reset}"
        return 1
    fi
    return 0
}

test_convert_to_seconds "10000s" 100 "false"
test_convert_to_seconds "1d1h1m1s" 90061 "true"
test_convert_to_seconds "1d 1h 1m 1s" 90061 "true"
test_convert_to_seconds "1d-1h-1m-1s" 90061 "true"
test_convert_to_seconds "1d:1h:1m:1s" 90061 "true"
test_convert_to_seconds "1d " 86400 "true"
test_convert_to_seconds " 1h" 3600 "true"
test_convert_to_seconds "120m" 7200 "true"
test_convert_to_seconds "10000s" 10000 "true"
