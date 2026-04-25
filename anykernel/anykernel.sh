### AnyKernel3 Ramdisk Mod Script
## GarnetKernel by Shammuray10

### AnyKernel setup
properties() { '
kernel.string=GarnetKernel by Shammuray10 | KSU Next v3.2.0 + SUSFS v2.0.0
do.devicecheck=0
do.modules=0
do.systemless=0
do.cleanup=1
do.cleanuponabort=0
device.name1=garnet
device.name2=parrot
device.name3=2312DRA50G
device.name4=Redmi Note 13 Pro 5G
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

. tools/ak3-core.sh

split_boot
if [ -f "split_img/ramdisk.cpio" ]; then
    unpack_ramdisk
    write_boot
else
    flash_boot
fi

ui_print " "
ui_print "GarnetKernel by Shammuray10"
ui_print "KernelSU Next v3.2.0 + SUSFS v2.0.0"
ui_print "github.com/Shammuray10/GarnetKernel"
ui_print " "
