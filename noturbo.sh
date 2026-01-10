#!/bin/sh
#
# noturbo: Disable Intel Turbo Boost
# https://github.com/andreadavanzo/adtool
# SPDX-License-Identifier: MPL-2.0
# Copyright (c) Andrea Davanzo and contributors

VERSION="0.1"

echo "noturbo (adtool) - Version $VERSION"

if [ -f /sys/devices/system/cpu/intel_pstate/no_turbo ]; then
  # Setting no_turbo to 1 disables Turbo Boost
  echo 1 > /sys/devices/system/cpu/intel_pstate/no_turbo
  echo "Intel Turbo Boost disabled."
else
  echo "Error: Intel P-State driver not detected or Turbo Boost control not found."
  exit 1
fi