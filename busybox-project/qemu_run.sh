qemu-system-aarch64 -M virt -cpu cortex-a57 -m 1024M \
  -kernel out/Image \
  -initrd out/initramfs.cpio.gz \
  -nographic -append "rdinit=/init console=ttyAMA0"
