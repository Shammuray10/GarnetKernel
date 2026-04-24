#!/system/bin/sh
# ═══════════════════════════════════════════════════════════
#  GarnetKernel — Performance Profile Module
#  KernelSU Next module: perf_profile
#  Device: Redmi Note 13 Pro 5G (garnet / 2312DRA50G)
#  Author: Shammuray10
# ═══════════════════════════════════════════════════════════

MODDIR=${0%/*}
LOG=/data/local/tmp/garnet_perf.log

log_msg() {
    echo "[GarnetKernel] $(date '+%H:%M:%S') $1" >> $LOG
}

wait_for_boot() {
    # Esperar a que el sistema esté completamente arrancado
    while [ "$(getprop sys.boot_completed)" != "1" ]; do
        sleep 2
    done
    sleep 10
}

write_if_exists() {
    local path="$1"
    local value="$2"
    if [ -f "$path" ]; then
        echo "$value" > "$path" 2>/dev/null && \
            log_msg "OK: $path = $value" || \
            log_msg "FAIL: $path"
    fi
}

# ─────────────────────────────────────────────────────────────
# CPU Governor — schedutil con parámetros optimizados
# ─────────────────────────────────────────────────────────────
setup_cpu() {
    log_msg "=== CPU Setup ==="

    for cpu in /sys/devices/system/cpu/cpu*/cpufreq; do
        [ -d "$cpu" ] || continue
        write_if_exists "$cpu/scaling_governor" "schedutil"
        # Rate limit bajo = respuesta más rápida
        write_if_exists "$cpu/schedutil/rate_limit_us" "500"
        write_if_exists "$cpu/schedutil/hispeed_load" "85"
        write_if_exists "$cpu/schedutil/hispeed_freq" "1497600"
    done

    # CPU Boost en input (toques de pantalla)
    write_if_exists "/sys/module/cpu_boost/parameters/input_boost_enabled" "1"
    write_if_exists "/sys/module/cpu_boost/parameters/input_boost_ms" "40"

    # Performance cores (cpu4-7): boost a 1.8 GHz en input
    # Efficiency cores (cpu0-3): boost a 1.4 GHz en input
    write_if_exists "/sys/module/cpu_boost/parameters/input_boost_freq" \
        "0:1401600 1:1401600 2:1401600 3:1401600 4:1804800 5:1804800 6:1804800 7:1804800"

    log_msg "CPU setup complete"
}

# ─────────────────────────────────────────────────────────────
# GPU Adreno 710 — msm-adreno-tz governor
# ─────────────────────────────────────────────────────────────
setup_gpu() {
    log_msg "=== GPU Setup ==="

    KGSL=/sys/class/kgsl/kgsl-3d0

    write_if_exists "$KGSL/devfreq/governor" "msm-adreno-tz"
    write_if_exists "$KGSL/devfreq/adrenoboost" "2"       # 0-3, 2=moderate boost
    write_if_exists "$KGSL/throttling" "1"                 # Mantener thermal activo
    write_if_exists "$KGSL/force_clk_on" "0"               # Solo forzar en benchmark
    write_if_exists "$KGSL/idle_timer" "58"                # ms antes de bajar freq

    log_msg "GPU setup complete"
}

# ─────────────────────────────────────────────────────────────
# I/O — Kyber scheduler para UFS 3.1
# ─────────────────────────────────────────────────────────────
setup_io() {
    log_msg "=== I/O Setup ==="

    for dev in /sys/block/sd* /sys/block/mmcblk*; do
        [ -d "$dev" ] || continue
        QUEUE="$dev/queue"
        write_if_exists "$QUEUE/scheduler" "kyber"
        write_if_exists "$QUEUE/read_ahead_kb" "128"
        write_if_exists "$QUEUE/nr_requests" "64"
        write_if_exists "$QUEUE/rq_affinity" "1"
        write_if_exists "$QUEUE/add_random" "0"
        write_if_exists "$QUEUE/rotational" "0"
    done

    log_msg "I/O setup complete"
}

# ─────────────────────────────────────────────────────────────
# zRAM — 4 GB con zstd
# ─────────────────────────────────────────────────────────────
setup_zram() {
    log_msg "=== zRAM Setup ==="

    ZRAM=/sys/block/zram0

    if [ -b /dev/block/zram0 ]; then
        # Reset si estaba activo
        swapoff /dev/block/zram0 2>/dev/null
        write_if_exists "$ZRAM/reset" "1"
        sleep 1

        # Configurar
        write_if_exists "$ZRAM/comp_algorithm" "zstd"
        write_if_exists "$ZRAM/disksize" "4294967296"   # 4 GB

        mkswap /dev/block/zram0 >> $LOG 2>&1
        swapon /dev/block/zram0 -p 32768 >> $LOG 2>&1

        log_msg "zRAM 4GB zstd active"
    else
        log_msg "zRAM device not found"
    fi
}

# ─────────────────────────────────────────────────────────────
# VM — Memory management tuning
# ─────────────────────────────────────────────────────────────
setup_vm() {
    log_msg "=== VM Setup ==="

    # Con 8GB RAM: swappiness moderado para uso normal
    write_if_exists "/proc/sys/vm/swappiness" "60"
    write_if_exists "/proc/sys/vm/page-cluster" "0"
    write_if_exists "/proc/sys/vm/dirty_ratio" "20"
    write_if_exists "/proc/sys/vm/dirty_background_ratio" "5"
    write_if_exists "/proc/sys/vm/dirty_expire_centisecs" "3000"
    write_if_exists "/proc/sys/vm/dirty_writeback_centisecs" "500"
    write_if_exists "/proc/sys/vm/vfs_cache_pressure" "50"
    write_if_exists "/proc/sys/vm/oom_kill_allocating_task" "0"

    log_msg "VM setup complete"
}

# ─────────────────────────────────────────────────────────────
# TCP — BBR + FQ para mejor rendimiento de red
# ─────────────────────────────────────────────────────────────
setup_tcp() {
    log_msg "=== TCP Setup ==="

    write_if_exists "/proc/sys/net/ipv4/tcp_congestion_control" "bbr"
    write_if_exists "/proc/sys/net/core/default_qdisc" "fq"
    write_if_exists "/proc/sys/net/ipv4/tcp_low_latency" "1"
    write_if_exists "/proc/sys/net/ipv4/tcp_fastopen" "3"
    write_if_exists "/proc/sys/net/ipv4/tcp_ecn" "1"

    log_msg "TCP setup complete"
}

# ─────────────────────────────────────────────────────────────
# Wakelocks — Prevenir drain en reposo
# ─────────────────────────────────────────────────────────────
setup_wakelocks() {
    log_msg "=== Wakelock Setup ==="

    # Bloquear wakelocks conocidos problemáticos en HyperOS
    for wl in "wlan" "IPA_WS" "qcom_rx_wakelock"; do
        write_if_exists "/sys/class/wakeup/$wl/enabled" "0" 2>/dev/null || true
    done

    log_msg "Wakelock setup complete"
}

# ─────────────────────────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────────────────────────
echo "" > $LOG
log_msg "GarnetKernel Performance Profile starting..."
log_msg "Device: $(getprop ro.product.model) | $(getprop ro.build.version.release)"

wait_for_boot

setup_cpu
setup_gpu
setup_io
setup_zram
setup_vm
setup_tcp
setup_wakelocks

log_msg "=== All done. GarnetKernel profile active ==="
