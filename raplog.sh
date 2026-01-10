#!/bin/sh
# -----------------------------------------
# raplog: RAPL logger for Intel CPUs
# SPDX-License-Identifier: MPL-2.0
# Copyright (c) Andrea Davanzo and contributors
#
# Logs:
#   - Raw energy (µJ) per domain
#   - Power (W) per domain, 9 decimal digits
#   - Per-core frequency (MHz)
#   - CPU governor
#   - Intel Turbo Status (1=Enabled, 0=Disabled)
#   - Package temperature (°C)
# Outputs CSV to stdout by default or optional file with -o <file>
# -----------------------------------------

VERSION="0.6"

# Handle arguments
while getopts "o:i:" opt; do
  case $opt in
    o) OUTFILE="$OPTARG" ;;
    i) INTERVAL="$OPTARG" ;;
    *) echo "Usage: $0 [-o outfile] [-i interval]"; exit 1 ;;
  esac
done

INTERVAL="${INTERVAL:-5}"
if [ "$INTERVAL" -le 0 ] 2>/dev/null; then
  INTERVAL=5
fi

echo "raplog (adtool) - Version $VERSION"

# Handle optional output file
if [ "$1" = "-o" ] && [ -n "$2" ]; then
  OUTFILE="$2"
  mkdir -p "$(dirname "$OUTFILE")"
else
  OUTFILE=""
fi

# Detect all readable RAPL domains
DOMAINS=""
for d in /sys/class/powercap/intel-rapl:0*; do
  if [ -f "$d/energy_uj" ]; then
    DOMAINS="$DOMAINS $d/energy_uj"
  fi
done

if [ -z "$DOMAINS" ]; then
  echo "No RAPL domains detected!"
  exit 1
fi

echo "Detected RAPL domains:"
for d in $DOMAINS; do
  echo "  $d"
done

# Get all CPU cores
CPUS=$(ls -d /sys/devices/system/cpu/cpu[0-9]*)

# Initialize previous RAPL values
for D in $DOMAINS; do
  NAME=$(basename "$(dirname "$D")")
  cat "$D" > "/tmp/${NAME}_prev"
done

# Build CSV header
HEADER="timestamp"
for D in $DOMAINS; do
  NAME=$(basename "$(dirname "$D")")
  HEADER="$HEADER,${NAME}_uj,${NAME}_W"
done

for cpu in $CPUS; do
  CPU_NAME=$(basename "$cpu")
  HEADER="$HEADER,${CPU_NAME}_MHz"
done

HEADER="$HEADER,cpu_governor,turbo_enabled,temp_C"

# Print header
echo "$HEADER"
[ -n "$OUTFILE" ] && echo "$HEADER" > "$OUTFILE"

# -----------------------------
# Measurement loop
# -----------------------------
while true; do
  TS=$(date +"%Y-%m-%d %H:%M:%S")
  LINE="$TS"

  # RAPL power per domain
  for D in $DOMAINS; do
    NAME=$(basename "$(dirname "$D")")
    ENERGY_RAW=$(cat "$D")            # raw energy in µJ
    PREV=$(cat "/tmp/${NAME}_prev")

    # Detect max range for this specific domain
    MAX_PATH="$(dirname "$D")/max_energy_range_uj"
    if [ -f "$MAX_PATH" ]; then
      MAX=$(cat "$MAX_PATH")
    else
      MAX=4294967296  # Fallback to 2^32 if system doesn't specify
    fi

    # Wraparound handling logic
    if [ "$ENERGY_RAW" -lt "$PREV" ]; then
      DELTA_UJ=$(awk -v cur="$ENERGY_RAW" -v prev="$PREV" -v max="$MAX" \
          'BEGIN { print (max - prev) + cur }')
    else
      DELTA_UJ=$(awk -v cur="$ENERGY_RAW" -v prev="$PREV" \
          'BEGIN { print cur - prev }')
    fi

    # Convert energy delta to Watts (W) with 9 decimal digits
    POWER=$(awk -v delta="$DELTA_UJ" -v interval="$INTERVAL" \
      'BEGIN {printf "%.9f", (delta/1000000)/interval}')

    LINE="$LINE,$ENERGY_RAW,$POWER"
    echo "$ENERGY_RAW" > "/tmp/${NAME}_prev"
  done

  # Per-core frequencies
  for cpu in $CPUS; do
    FREQ=$(cat "$cpu/cpufreq/scaling_cur_freq" 2>/dev/null)
    FREQ=$(awk -v f="$FREQ" 'BEGIN {print f/1000}')  # kHz → MHz
    LINE="$LINE,$FREQ"
  done

  # CPU governor (first core)
  GOV=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null)

  # Intel Turbo Boost status
  # /sys/.../no_turbo: 0 means Turbo is enabled, 1 means disabled.
  # Convert to CSV-friendly format: 1 (Enabled) or 0 (Disabled).
  TURBO_PATH="/sys/devices/system/cpu/intel_pstate/no_turbo"
  if [ -f "$TURBO_PATH" ]; then
    TURBO_RAW=$(cat "$TURBO_PATH")
    [ "$TURBO_RAW" = "0" ] && TURBO="on" || TURBO="off"
  else
    TURBO="n/a"
  fi

  # Temperature (package 0)
  TEMP=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null)
  TEMP=$(awk -v t="$TEMP" 'BEGIN {print t/1000}') # m°C → °C

  LINE="$LINE,$GOV,$TURBO,$TEMP"

  # Print to stdout
  echo "$LINE"

  # Save to file if requested
  [ -n "$OUTFILE" ] && echo "$LINE" >> "$OUTFILE"

  sleep "$INTERVAL"
done