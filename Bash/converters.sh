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
    local seconds
    seconds=$(convert_to_seconds "$1")
    if [[ "$seconds" == "$2" ]]; then
        echo -e "Test ${green}passed${reset} expected: $2 \t actual: $seconds"
    else
        echo -e "Test ${red}failed${reset} expected: $2 \t actual: ${red}$seconds${reset}"
        return 1
    fi
    return 0
}

test_convert_to_seconds "1d1h1m1s" 90061
test_convert_to_seconds "1d 1h 1m 1s" 90061
test_convert_to_seconds "1d-1h-1m-1s" 90061
test_convert_to_seconds "1d:1h:1m:1s" 90061
test_convert_to_seconds "1d " 86400
test_convert_to_seconds " 1h" 3600
test_convert_to_seconds "120m" 7200
test_convert_to_seconds "10000s" 10000
