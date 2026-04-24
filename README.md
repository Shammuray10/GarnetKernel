# GarnetKernel 🔥

**High-performance custom kernel for Redmi Note 13 Pro 5G**

[![Build](https://github.com/Shammuray10/GarnetKernel/actions/workflows/build.yml/badge.svg)](https://github.com/Shammuray10/GarnetKernel/actions/workflows/build.yml)

---

## Device
| Field | Value |
|-------|-------|
| Device | Redmi Note 13 Pro 5G |
| Model | 2312DRA50G (Global) |
| Codename | garnet / parrot |
| SoC | Snapdragon 7s Gen 2 (SM7435-AB) |
| GPU | Adreno 710 |
| RAM | 8 GB LPDDR5 |
| Storage | 256 GB UFS 3.1 |

---

## Features

- ✅ **KernelSU Next** — Root solution with latest Next branch
- ✅ **SUSFS** — Kernel-level root hiding (5.10 compatible)
- ✅ **Thin LTO** — Link Time Optimization via Clang 18
- ✅ **WALT Scheduler** — Qualcomm native workload-aware scheduler
- ✅ **Kyber I/O** — Low-latency scheduler optimized for UFS 3.1
- ✅ **TCP BBR** — Better network throughput and latency
- ✅ **Schedutil governor** — EAS-aware CPU frequency scaling
- ✅ **Performance profile module** — KSU module with zRAM 4GB zstd
- ✅ **Benchmark mode script** — One-command Antutu boost

---

## Build

### Automatic (GitHub Actions)
1. Fork this repo
2. Go to **Actions → GarnetKernel Build → Run workflow**
3. Download the ZIP from Artifacts

### Manual triggers
```
workflow_dispatch inputs:
  KERNEL_VERSION   — custom version string
  ENABLE_LTO       — true/false (default: true)
  ENABLE_SUSFS     — true/false (default: true)
```

---

## Installation

### Prerequisites
- Unlocked bootloader
- KernelSU Next recovery or TWRP
- Backup your current boot.img first!

### Steps
```
1. Download GarnetKernel-garnet-YYYYMMDD-HHMM-KSU-SUSFS.zip
2. Flash via KernelSU Manager → Modules OR via recovery
3. Reboot
4. Flash perf_profile module via KernelSU Manager
5. Reboot
```

---

## KSU Module — perf_profile

Located in `modules/perf_profile/`

**What it does on boot:**
- CPU: schedutil governor + input boost
- GPU: msm-adreno-tz + adrenoboost level 2
- I/O: Kyber scheduler + 128KB readahead
- zRAM: 4 GB with zstd compression
- VM: optimized dirty ratios + swappiness 60
- TCP: BBR congestion control + FQ qdisc

### Install
```
Flash modules/perf_profile/ via KernelSU Manager
```

---

## Benchmark Mode

For maximum Antutu score:

```bash
# Enable before running Antutu
su -c "sh /data/adb/modules/perf_profile/benchmark_mode.sh on"

# Run Antutu...

# Restore after benchmark
su -c "sh /data/adb/modules/perf_profile/benchmark_mode.sh off"
```

**What benchmark mode does:**
- CPU → `performance` governor, locked to max freq (2.4 GHz)
- GPU → `performance` governor, force clk/bus/rail on, max freq
- GPU → adrenoboost level 3
- VM → swappiness 100 for memory score
- Thermal → stays enabled (disabling causes worse throttle)

---

## Build config highlights

```
Compiler:    Clang 18 (ZyCromerZ)
KCFLAGS:     -O3 -march=armv8.2-a -mtune=cortex-a55 -ffast-math
LTO:         Thin LTO
Scheduler:   WALT
I/O:         Kyber
TCP:         BBR + FQ
zRAM:        zstd
```

---

## Expected Antutu improvement vs stock

| Subscore | Improvement |
|----------|-------------|
| CPU | +8-12% |
| GPU | +5-8% |
| MEM | +10-15% |
| UX | +3-5% |
| **Total** | **~+7-12%** |

---

## Source

Based on [Xiaomi OSS kernel](https://github.com/MiCode/Xiaomi_Kernel_OpenSource) — `garnet-s-oss` branch

---

## Author

**Shammuray10** — [GitHub](https://github.com/Shammuray10)

---

## Disclaimer

Flashing custom kernels may void your warranty and can brick your device if done incorrectly. Always backup before flashing. I am not responsible for any damage.
