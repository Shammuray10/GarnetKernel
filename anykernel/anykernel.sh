### AnyKernel3 Ramdisk Mod Script
## osm0sis @ xda-developers

### AnyKernel setup
properties() { '
kernel.string=GarnetKernel by Shammuray10 | KSU Next + SUSFS | Neutron Clang 18
do.devicecheck=0
do.modules=0
do.systemless=0
do.cleanup=1
do.cleanuponabort=0
device.name1=
device.name2=
device.name3=
device.name4=
device.name5=
supported.versions=
supported.patchlevels=
supported.vendorpatchlevels=
'; } # end properties

### AnyKernel install
block=boot
is_slot_device=auto
ramdisk_compression=auto
patch_vbmeta_flag=auto
no_magisk_check=1

# import functions/variables and setup patching (DO NOT REMOVE)
. tools/ak3-core.sh

# Verificar que el kernel corriendo es GKI 5.10 (compatible con este flash)
kernel_version=$(cat /proc/version | awk -F '-' '{print $1}' | awk '{print $3}')
case $kernel_version in
    5.1*) ksu_supported=true ;;
    6.1*) ksu_supported=true ;;
    6.6*) ksu_supported=true ;;
    *) ksu_supported=false ;;
esac

ui_print " "
ui_print "  ╔════════════════════════════════════╗"
ui_print "  ║         GarnetKernel               ║"
ui_print "  ║      by Shammuray10                ║"
ui_print "  ╠════════════════════════════════════╣"
ui_print "  ║  KernelSU Next + SUSFS v2.0.0      ║"
ui_print "  ║  Neutron Clang 18 | -O3 | ARMv8.2  ║"
ui_print "  ║  WALT · uclamp · Kyber · BBR        ║"
ui_print "  ╚════════════════════════════════════╝"
ui_print " "
ui_print "  -> GKI 5.10 compatible: $ksu_supported"
$ksu_supported || abort "  -> Kernel no compatible, abortando."

# boot install
split_boot
if [ -f "split_img/ramdisk.cpio" ]; then
    unpack_ramdisk
    write_boot
else
    flash_boot
fi

ui_print " "
ui_print "  github.com/Shammuray10/GarnetKernel"
ui_print " "
