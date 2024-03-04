bits 16
org 0x7e00
kernelstart:
; print startup message
mov ah, 0x0e
mov bx, kernelstartmsg
call printString
call printNewline
; prints os name
mov bx, startmsg
call printString
call printNewline
; sets up interupts
call setupint
; boots terminal
mov ah, 2
mov bx, terminalname
mov cx, 0x9000
int 0x69
jmp 0x9000
setupint:
xor ax,ax
mov es,ax
cli
mov di, INT69
mov ES:[0x69*4], di
mov ES:[0x69*4+2], CS
sti
ret
INT69:
cmp ah, 0
je endint69
; ********************************* ;
; READ SECTOR|AH=1|INT69 ;
; ;
; INPUTS: ;
; BX = SECTOR START NUMBER ;
; CX = NUMBER OF SECTORS TO READ ;
; DX = RESULTANT MEMORY LOCATION ;
; ;
; OUTPUTS: ;
; AL = FAIL STATE ;
; ;
; FAILSTATES: ;
; 0 = SUCCESS ;
; 1 = FAILED TO READ SECTOR ;
; ********************************* ;
cmp ah, 1
jne INT69check2
; sets all the preconditions
mov [sectorread], bx
push cx
xor ch, ch
mov [numbertoread], cx
pop cx
mov [memorystart], dx
mov ax, [sectorread]
; calculates the CHS
xor dx, dx
div WORD [sectorspertrack]
inc dl
mov BYTE [sectortoread], dl
xor dx, dx
div WORD [headspercylinder]
mov BYTE [headtoread], dl
mov BYTE [tracktoread], al
; resets the disk
mov ah, 0
mov dl, 0
int 0x13
; reads the data
xor ax, ax
mov es, ax
mov ds, ax
mov bx, [memorystart]
mov ah, 0x02
mov al, [numbertoread]
mov ch, [tracktoread]
mov cl, [sectortoread]
mov dh, [headtoread]
mov dl, 0
int 0x13
setc al
iret
; ********************************* ;
; READ FILE|AH=2|INT69 ;
; ;
; INPUTS: ;
; BX = FILE NAME ;
; CX = RESULTANT MEMORY LOCATION ;
; ;
; OUTPUTS: ;
; AL = FAIL STATE ;
; ;
; FAILSTATES: ;
; 0 = SUCCESS ;
; 1 = FAILED TO READ SECTOR ;
; 2 = FAILED TO FIND FILE ;
; ********************************* ;
INT69check2:
cmp ah, 2
jne endint69
; reads the root directory
push cx
push bx
mov ah, 1
mov bx, 19
mov cx, 1
mov dx, 0x4200
int 0x69
; finds where the file is located
mov ax, 0
mov [count], ax
pop bx
mov cx, bx
mov ax, 0x4200
jmp INT69next2
INT69next2frompush:
pop ax
INT69next2:
; checks if the two characters match
mov di, ax
mov dx, [di]
mov di, cx
cmp [di], dx
jne INT69fail2
; increments both pointers
inc ax
push cx
mov cx, [count]
; checks if the value was found
cmp cx, 9
je INT69pass2
; increments the count
inc cx
mov [count], cx
; needs to change so it can do all the directories but holds the current amount of
directories explored
; _____ _ _ _ _ _____ ______
; / ____| | | | /\ | \ | |/ ____| ____|
; | | | |__| | / \ | \| | | __| |__
; | | | __ | / /\ \ | . ` | | |_ | __|
; | |____| | | |/ ____ \| |\ | |__| | |____
; \_____|_| |_/_/ \_\_| \_|\_____|______|
;
mov cx, [totalexp]
inc cx
mov [totalexp], cx
pop cx
; increments the name of the directory
mov cx, bx
add cx, [count]
jmp INT69next2
INT69fail2:
; increments the currently compared character
inc ax
mov cx, bx
push cx
; resets count
xor cx, cx
mov [count], cx
pop cx
push ax
; increments the count of the total searched
mov ax, [totalexp]
inc ax
mov [totalexp], ax
cmp ax, 0x200
jl INT69next2frompush
pop ax
pop ax
mov al, 2
iret
INT69pass2:
; finds the physical sector and loads it into memory at the specified location
pop cx
add ax, 16
mov di, ax
mov bx, [di]
add bx, 31
mov cx, 2
pop dx
mov ah, 1
int 0x69
iret
endint69:
iret
printmdigit:
; sets all parameters
mov cx, 0
mov ax, [tempnum]
mov [quot], ax
repeat:
; clears all not used registers
xor ax, ax
xor bx, bx
xor dx, dx
; divides the number by ten to get the digit to put on the stack
mov ax, [quot]
mov bx, 10
div bx
mov [quot], ax
; checks if the devision is finished
cmp ax, 0
je divend
mov ax, dx
push ax
; increments the digit count
inc cx
jmp repeat
divend:
mov ax, dx
push ax
inc cx
repeatprint:
; decrements the digit counter and gets the next digit to print from the stack
dec cx
pop ax
mov [tempnum], ax
push cx
; prints the digit
call printdigit
pop cx
; checks if there are any more digits, if not finish
cmp cx, 0
jne repeatprint
ret
printdigit:
; adds 0x30 to the number to get its ASCII equivalent
mov ax, 0x30
; prints the number
add [tempnum], ax
mov ax, [tempnum]
call printChar
ret
printChar:
; sets the bios function to display the ASCII value in the al
mov ah, 0x0e
int 0x10
ret
printString:
mov al, [bx]
cmp al, 0
je end
int 0x10
inc bx
jmp printString
end:
ret
printNewline:
mov ah, 0x0e
mov al, 0x0A
int 0x10
mov al, 0x0D
int 0x10
ret
readsect:
mov ax, [sectorread]
call LBACHS
mov ah, 0
mov dl, 0
int 0x13
xor ax, ax
mov es, ax
mov ds, ax
mov bx, 0x9000
mov ah, 0x02
mov al, [numbertoread]
mov ch, [tracktoread]
mov cl, [sectortoread]
mov dh, [headtoread]
mov dl, 0
int 0x13
jc Terminalerr
ret
Terminalerr:
mov ah, 0x0e
mov bx, terminalerror
call printString
ret
LBACHS:
xor dx, dx
div WORD [sectorspertrack]
inc dl
mov BYTE [sectortoread], dl
xor dx, dx
div WORD [headspercylinder]
mov BYTE [headtoread], dl
mov BYTE [tracktoread],al
ret
; data
terminalname db "TERMINALBIN", 0
kernelstartmsg db "Kernel loaded", 0
startmsg db "Welcome to FLOPPYOS", 0
terminalerror db "Error loading terminal", 0
testmsg db "TEST", 0
totalsectors dw 2880
sectorspertrack dw 18
tracksperside dw 80
headspercylinder dw 2
reservedsectors dw 1
numberoffats db 2
rootentries dw 224
sectorsperfat dw 9
sectorread dw 0
sectortoread db 0
tracktoread db 0
headtoread db 0
numbertoread db 0
tempnum dw 0
quot dw 0
memorystart dw 0
count dw 0
totalexp dw 0
times 7680-($-$$) db 0x00
dw 0x88
