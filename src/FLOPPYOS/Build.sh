export PATH=$PATH:/usr/local/i386elfgcc/bin
sudo apt install nasm
sudo apt install qemu-system-x86
fallocate -l 1474560 test.img

nasm "Boot.asm" -f bin -o "Boot.bin"
nasm "Kernel.asm" -f bin -o "Kernel.bin"
nasm "Terminal.asm" -f bin -o "Terminal.bin"
nasm "Adder.asm" -f bin -o "Adder"

cat "Boot.bin"  > "OS.bin"

mkfs.vfat -F 12 test.img
sudo rm -r /media/floppy1
sudo mkdir /media/floppy1
sudo mount -o loop test.img /media/floppy1/
sudo cp ./Kernel.bin /media/floppy1/
sudo cp ./Terminal.bin /media/floppy1/
sudo cp ./Adder /media/floppy1/
sudo umount /media/floppy1/
dd status=noxfer conv=notrunc if=OS.bin of=test.img
qemu-system-i386 -m 1 -fda test.img
