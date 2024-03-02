export PATH=$PATH:/usr/local/i386elfgcc/bin

nasm "Boot.asm" -f bin -o "Boot.bin"
nasm "Kernel.asm" -f bin -o "Kernel.bin"
nasm "zeroes.asm" -f bin -o "zeroes.bin"

cat "Boot.bin" "Kernel.bin" "zeroes.bin"  > "OS.bin"

dd status=noxfer conv=notrunc if=OS.bin of=myflp.flp
qemu-system-i386 -m 1 -fda myflp.flp