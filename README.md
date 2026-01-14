# adtool (Andrea Davanzo Tool)

A collection of lightweight shell scripts for (Alpine) Linux.

---

## raplog.sh

A robust **Intel RAPL (Running Average Power Limit) logger**. It collects high-precision energy data and system metadata, outputting it in a CSV-ready format.

* **Monitors:** Raw energy (µJ), Power consumption (W), per-core frequency (MHz), CPU governor, Turbo Boost status, and package temperature.
* **Process Attribution:** Identifies the top process (by CPU usage) for each interval.

Usage:
```bash
./raplog.sh [-o outfile.csv] [-i interval_seconds] [-t tag]

```

## performance.sh

A utility to quickly set the scaling governor for all CPU cores to **performance** mode. This ensures the CPU stays at its maximum clock speed for demanding workloads.

Usage:
```bash
 sudo ./performance.sh
```

## noturbo.sh

A script to disable **Intel Turbo Boost** by interacting with the `intel_pstate` driver. This is useful for thermal management or achieving consistent benchmarking results.

Usage:

```
sudo ./noturbo.sh
```


Remember to make scripts executable!
```bash
chmod +x *.sh

```


## License

This project is licensed under the Mozilla Public License 2.0 (MPL-2.0).
Copyright (c) Andrea Davanzo and contributors.
