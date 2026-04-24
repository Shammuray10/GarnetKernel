#!/system/bin/sh
# ═══════════════════════════════════════════════════════════
#  GarnetKernel — perf_profile Module
#  customize.sh — Compatibility check on install
#  Ejecutado por KernelSU Next durante la instalación
# ═══════════════════════════════════════════════════════════

SKIPUNZIP=1  # No extraemos nada extra, solo verificamos

# ── Colores para el log de instalación ──
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

ui_print() { echo "$1"; }
ok()   { ui_print "  ✅ $1"; }
warn() { ui_print "  ⚠️  $1"; }
fail() { ui_print "  ❌ $1"; }
info() { ui_print "  ℹ️  $1"; }

ui_print ""
ui_print "════════════════════════════════════"
ui_print "   GarnetKernel — perf_profile"
ui_print "   v2.0.0 by Shammuray10"
ui_print "════════════════════════════════════"
ui_print ""

# ────────────────────────────────────────────────────────────
# 1. Verificar dispositivo
# ────────────────────────────────────────────────────────────
ui_print "[ 1/6 ] Verificando dispositivo..."

DEVICE=$(getprop ro.product.device)
MODEL=$(getprop ro.product.model)
SKU=$(getprop ro.boot.hardware.sku 2>/dev/null || \
      getprop ro.product.marketname 2>/dev/null || echo "unknown")

info "Dispositivo: $DEVICE ($MODEL)"
info "SKU: $SKU"

SUPPORTED_DEVICES="garnet parrot"
DEVICE_OK=false
for d in $SUPPORTED_DEVICES; do
  [ "$DEVICE" = "$d" ] && DEVICE_OK=true && break
done

if $DEVICE_OK; then
  ok "Dispositivo compatible: $DEVICE"
else
  warn "Dispositivo no reconocido: $DEVICE"
  warn "Soportados: garnet, parrot (Redmi Note 13 Pro 5G)"
  warn "Continuando de todas formas — puede funcionar en dispositivos similares"
fi

# ────────────────────────────────────────────────────────────
# 2. Verificar kernel — GarnetKernel
# ────────────────────────────────────────────────────────────
ui_print ""
ui_print "[ 2/6 ] Verificando kernel..."

KERNEL_VER=$(uname -r)
info "Kernel: $KERNEL_VER"

# Verificar que es nuestro kernel
if echo "$KERNEL_VER" | grep -qi "GarnetKernel"; then
  ok "GarnetKernel detectado"
else
  warn "GarnetKernel NO detectado en uname -r"
  warn "Este módulo está optimizado para GarnetKernel"
  warn "Puede funcionar con otros kernels pero sin garantías"
fi

# Verificar versión 5.10
if echo "$KERNEL_VER" | grep -q "^5\.10"; then
  ok "Kernel 5.10.x — compatible"
else
  fail "Kernel version inesperada: $KERNEL_VER"
  fail "Este módulo requiere kernel 5.10.x"
  abort "Instalación abortada — kernel incompatible"
fi

# ────────────────────────────────────────────────────────────
# 3. Verificar KernelSU Next v3.2.0
# ────────────────────────────────────────────────────────────
ui_print ""
ui_print "[ 3/6 ] Verificando KernelSU Next..."

KSU_VERSION=$(getprop ro.boot.flash.locked 2>/dev/null)
KSU_VER_CODE=""

# Leer versión desde KSU
if [ -f /data/adb/ksu/version ]; then
  KSU_VER_CODE=$(cat /data/adb/ksu/version)
elif [ -f /proc/sys/kernel/ksu_version ]; then
  KSU_VER_CODE=$(cat /proc/sys/kernel/ksu_version)
fi

if [ -n "$KSU_VER_CODE" ]; then
  info "KSU version code: $KSU_VER_CODE"
  # v3.2.0 = code >= 11900 (aproximado)
  if [ "$KSU_VER_CODE" -ge 11900 ] 2>/dev/null; then
    ok "KernelSU Next v3.x detectado — compatible"
  else
    warn "KSU version code $KSU_VER_CODE — puede ser anterior a v3.2.0"
  fi
else
  # Verificar por presencia de KSU
  if [ -d /data/adb/ksu ] || [ -f /data/adb/ksud ]; then
    ok "KernelSU Next detectado"
  else
    fail "KernelSU Next NO detectado"
    abort "Instalación abortada — requiere KernelSU Next"
  fi
fi

# ────────────────────────────────────────────────────────────
# 4. Verificar SUSFS v2.0.0
# ────────────────────────────────────────────────────────────
ui_print ""
ui_print "[ 4/6 ] Verificando SUSFS v2.0.0..."

SUSFS_OK=false

# Método 1: procfs
if [ -f /proc/susfs_version ]; then
  SUSFS_VER=$(cat /proc/susfs_version)
  info "SUSFS versión: $SUSFS_VER"
  if echo "$SUSFS_VER" | grep -q "2\.0"; then
    ok "SUSFS v2.0.0 confirmado"
    SUSFS_OK=true
  else
    warn "SUSFS versión detectada: $SUSFS_VER (esperada v2.0.0)"
    SUSFS_OK=true  # Continuar aunque sea versión distinta
  fi
fi

# Método 2: syscall probe
if ! $SUSFS_OK; then
  if [ -f /sys/kernel/susfs/version ] 2>/dev/null; then
    SUSFS_VER=$(cat /sys/kernel/susfs/version)
    info "SUSFS (sysfs): $SUSFS_VER"
    SUSFS_OK=true
    ok "SUSFS detectado via sysfs"
  fi
fi

# Método 3: existencia de sus_su
if ! $SUSFS_OK; then
  if [ -f /proc/sus_su ] || [ -e /sys/susfs ]; then
    ok "SUSFS detectado (sus_su presente)"
    SUSFS_OK=true
  fi
fi

if ! $SUSFS_OK; then
  warn "SUSFS no detectado directamente"
  warn "Puede que el kernel no tenga SUSFS compilado"
  warn "El módulo funcionará pero sin las ventajas de SUSFS"
fi

# ────────────────────────────────────────────────────────────
# 5. Verificar hardware esperado
# ────────────────────────────────────────────────────────────
ui_print ""
ui_print "[ 5/6 ] Verificando hardware..."

# CPU — SM7435 / Snapdragon 7s Gen 2
SOC=$(getprop ro.board.platform)
info "SoC platform: $SOC"
if echo "$SOC" | grep -qi "sm7435\|crow\|parrot"; then
  ok "SoC compatible: $SOC"
else
  warn "SoC no reconocido: $SOC (esperado sm7435)"
fi

# RAM
MEMTOTAL=$(grep MemTotal /proc/meminfo | awk '{print $2}')
MEMGB=$((MEMTOTAL / 1024 / 1024))
info "RAM detectada: ~${MEMGB}GB"
if [ "$MEMGB" -ge 7 ]; then
  ok "RAM suficiente para zRAM 4GB (${MEMGB}GB físicos)"
else
  warn "RAM baja: ${MEMGB}GB — reduciendo zRAM a 2GB en service.sh"
  # Parchear service.sh para usar 2GB en lugar de 4GB
  sed -i 's/4294967296/2147483648/g' "$MODPATH/service.sh"
  info "service.sh ajustado a zRAM 2GB"
fi

# zRAM disponible
if [ -b /dev/block/zram0 ]; then
  ok "zRAM device disponible (/dev/block/zram0)"
else
  warn "zRAM no disponible — setup de memoria omitido"
  # Deshabilitar la sección zRAM del service.sh
  sed -i 's/setup_zram$/# setup_zram # disabled: no zram device/' \
    "$MODPATH/service.sh" 2>/dev/null || true
fi

# Verificar Kyber disponible
if cat /sys/block/sda/queue/scheduler 2>/dev/null | grep -q "kyber"; then
  ok "Kyber I/O scheduler disponible"
elif cat /sys/block/sdf/queue/scheduler 2>/dev/null | grep -q "kyber"; then
  ok "Kyber I/O scheduler disponible (sdf)"
else
  warn "Kyber no disponible — usando mq-deadline como fallback"
  sed -i 's/echo kyber/echo mq-deadline/g' "$MODPATH/service.sh"
fi

# ────────────────────────────────────────────────────────────
# 6. Instalar archivos del módulo
# ────────────────────────────────────────────────────────────
ui_print ""
ui_print "[ 6/6 ] Instalando archivos..."

# Extraer archivos del ZIP al MODPATH
unzip -o "$ZIPFILE" \
  'service.sh' \
  'benchmark_mode.sh' \
  'module.prop' \
  'customize.sh' \
  -d "$MODPATH" 2>/dev/null

# Permisos correctos
set_perm "$MODPATH/service.sh"      root root 0755
set_perm "$MODPATH/benchmark_mode.sh" root root 0755
set_perm "$MODPATH/customize.sh"    root root 0755

# Copiar benchmark_mode.sh a /data/local/tmp para acceso fácil
cp "$MODPATH/benchmark_mode.sh" /data/local/tmp/benchmark_mode.sh 2>/dev/null
chmod 755 /data/local/tmp/benchmark_mode.sh 2>/dev/null
info "benchmark_mode.sh copiado a /data/local/tmp/"

ui_print ""
ui_print "════════════════════════════════════"
ui_print "   ✅ Instalación completada"
ui_print "════════════════════════════════════"
ui_print ""
ui_print "El perfil se activará automáticamente al reiniciar."
ui_print ""
ui_print "Para benchmark Antutu:"
ui_print "  su -c 'sh /data/local/tmp/benchmark_mode.sh on'"
ui_print ""
ui_print "Log de arranque:"
ui_print "  cat /data/local/tmp/garnet_perf.log"
ui_print ""
