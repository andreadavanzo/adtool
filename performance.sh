#!/bin/sh
#
# performance: Sets all Intel CPU cores to 'performance'
# https://github.com/andreadavanzo/adtool
# SPDX-License-Identifier: MPL-2.0
# Copyright (c) Andrea Davanzo and contributors

VERSION="0.1"

# --- Check and set performance governor ---
echo "performance (adtool) - Version $VERSION"

AVAILABLE=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors 2>/dev/null)
if [ -z "$AVAILABLE" ]; then
  echo "Error: Cannot read available governors"
  exit 1
fi

if echo "$AVAILABLE" | grep -qw performance; then
  echo "Setting all CPU cores to 'performance'..."
  for CPU in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
    echo "performance" > "$CPU"
  done
  echo "All CPU cores set to 'performance'."
else
  echo "Error: 'performance' governor not available. Available: $AVAILABLE"
  exit 1
fi

echo "CPU performance mode set."