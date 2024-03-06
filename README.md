# FLOPPYOS

FLOPPYOS is an operating system built to run on a floppy disk using the FAT12 filesystem

## Current features

Not much currently just a terminal with 4 commands

### Terminal

Currently supported commands:

- Clear: clears the terminal
- Shutdown: shuts the machine down
- Find: finds a file on the computer and prints its logical and physical address/sector
- Open: opens the file specified and runs it

### That's it, currently
## Plans

- A large array of commands for my terminal
- Support for other connected disks to allow more programs to be loaded
- Networking
- GUI
- And more

## How to run
### WARNING

Please do not run this on your main PC, as of current it has only been tested on a VM with only access to the floppy image

### For Linux

#### Using the pre-built image

Install qemu using 

```
sudo apt install qemu-system-x86
```

And then run the operating system using

```
qemu-system-i386 -m 1 -fda FLOPPYOS.img
```

#### Building it yourself

Run the build script using

```
bash Build.sh
```

And this will install, build, and launch FLOPPYOS

### For Windows

Make sure you have qemu-system-x86 by installing it through this [link](https://qemu.weilnetz.de/w64/)

Make sure to add qemu to your environment variables

Run the following command

```
qemu-system-i386 -m 1 -fda FLOPPYOS.img
```
