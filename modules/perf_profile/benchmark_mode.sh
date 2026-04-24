#!/system/bin/sh
# ═══════════════════════════════════════════════════════════
#  GarnetKernel — Benchmark Mode (Antutu / 3DMark)
#  Uso: sh benchmark_mode.sh [on|off]
#  Requiere: root (KSU Next)
# ═══════════════════════════════════════════════════════════

LOG=/data/local/tmp/garnet_bench.log
MODE="${1:-on}"

log_msg() { echo "[BenchMode] $1" | tee -a $LOG; }

write_if_exists() {
    [ -f "$1" ] && echo "$2" > "$1" 2>/dev/null && log_msg "✓ $1 = $2"
}

benchmark_on() {
    log_msg "=== BENCHMARK MODE ON ==="

    # ── CPU: performance governor, frecuencia máxima ──
    log_msg "--- CPU max performance ---"
    for cpu in /sys/devices/system/cpu/cpu*/cpufreq; do
        write_if_exists "$cpu/scaling_governor" "performance"
        # Forzar frecuencia máxima
        MAX=$(cat "$cpu/cpuinfo_max_freq" 2>/dev/null)
        write_if_exists "$cpu/scaling_min_freq" "$MAX"
    done

    # ── GPU: forzar máxima frecuencia ──
    log_msg "--- GPU max frequency ---"
    KGSL=/sys/class/kgsl/kgsl-3d0
    write_if_exists "$KGSL/devfreq/governor" "performance"
    write_if_exists "$KGSL/force_clk_on" "1"
    write_if_exists "$KGSL/force_bus_on" "1"
    write_if_exists "$KGSL/force_rail_on" "1"
    write_if_exists "$KGSL/devfreq/adrenoboost" "3"

    GPU_MAX=$(cat "$KGSL/devfreq/max_freq" 2>/dev/null)
    write_if_exists "$KGSL/devfreq/min_freq" "$GPU_MAX"

    # ── VM: swappiness máximo para benchmark de memoria ──
    log_msg "--- VM benchmark tuning ---"
    write_if_exists "/proc/sys/vm/swappiness" "100"
    write_if_exists "/proc/sys/vm/vfs_cache_pressure" "100"

    # ── Thermal: subir umbrales (no deshabilitar) ──
    log_msg "--- Thermal tuning ---"
    # Nota: no deshabilitamos thermal — puede causar throttling aún peor
    # En su lugar, aseguramos que el perfil sea "balanced" y no "powersave"
    for tz in /sys/class/thermal/thermal_zone*/mode; do
        # Solo activar, nunca deshabilitar
        write_if_exists "$tz" "enabled"
    done

    log_msg "=== Benchmark mode ACTIVE — run Antutu now ==="
    log_msg "=== Run: sh benchmark_mode.sh off  cuando termines ==="
}

benchmark_off() {
    log_msg "=== BENCHMARK MODE OFF — restoring normal profile ==="

    # ── CPU: volver a schedutil ──
    for cpu in /sys/devices/system/cpu/cpu*/cpufreq; do
        write_if_exists "$cpu/scaling_governor" "schedutil"
        MIN=$(cat "$cpu/cpuinfo_min_freq" 2>/dev/null)
        write_if_exists "$cpu/scaling_min_freq" "$MIN"
    done

    # ── GPU: volver a msm-adreno-tz ──
    KGSL=/sys/class/kgsl/kgsl-3d0
    write_if_exists "$KGSL/devfreq/governor" "msm-adreno-tz"
    write_if_exists "$KGSL/force_clk_on" "0"
    write_if_exists "$KGSL/force_bus_on" "0"
    write_if_exists "$KGSL/force_rail_on" "0"
    write_if_exists "$KGSL/devfreq/adrenoboost" "2"

    MIN_GPU=$(cat "$KGSL/devfreq/min_freq_limit" 2>/dev/null || echo "0")
    write_if_exists "$KGSL/devfreq/min_freq" "$MIN_GPU"

    # ── VM: volver a normal ──
    write_if_exists "/proc/sys/vm/swappiness" "60"
    write_if_exists "/proc/sys/vm/vfs_cache_pressure" "50"

    log_msg "=== Normal profile restored ==="
}

case "$MODE" in
    on)  benchmark_on  ;;
    off) benchmark_off ;;
    *)
        echo "Usage: sh benchmark_mode.sh [on|off]"
        echo "  on  — maximize everything for Antutu"
        echo "  off — restore normal GarnetKernel profile"
        exit 1
        ;;
esac
