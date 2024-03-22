bits 16

org 0x9000
%assign linestart 0x3e
%assign escape 0x1b
%assign newln 0x0d
start:
    ; clears screen
    mov al, 0x12
    mov ah, 0x00
    int 0x10
    ; asks the user if they want to make a new file
    mov ah, 2
    mov bx, startmsg
    int 0x42
    mov ah, 5
    int 0x42
    mov ah, 0
    int 0x16
    cmp al, 0x6e
    je new
    mov ah, 2
    int 0x96

new:
    ; tells the user that escape is to exit
    mov ah, 2
    mov bx, filemsg
    int 0x42
    mov ah, 5
    int 0x42
    ; assigns one block of memory to begin with
    mov cx, 1
    mov ah, 2
    mov bx, 0x0220
    int 0x80
    mov ax, [0x5400]
    ; clears the memory block
    push ax
    mov bl, 0x2
    mov dx, ax
    mov ah, 3
    int 0x80
    pop ax
    ; gets the memory location of the block
    mov bx, 0x200
    mul bx
    add ax, 0x9000
    mov [memstart], ax
    mov di, ax
    ; prints the line start
    mov al, linestart
    mov ah, 1
    int 0x42
    jmp prestartwrite

prestartwrite:
startwrite:
    mov ah, 0
    int 0x16
    ; checks if the user wishes to save and exit
    cmp al, escape
    je saveexit
    ; saves the character to memory
    mov [di], al
    ; increases the size of the file
    mov cx, [bytesize]
    inc cx
    mov [bytesize], cx
    ; checks if the user hit enter
    cmp al, newln
    jne nextlet
    mov byte [di], newln
    mov ax, [currentline]
    inc ax
    cmp ax, [lineam]
    jg newline
newline:
    mov [currentline], ax
    mov [lineam], ax
    mov ah, 5
    int 0x42
    mov al, linestart
nextlet:
    inc di
    mov ah, 1
    int 0x42
    jmp startwrite

saveexit:
    ; clears screen
    mov al, 0x12
    mov ah, 0x00
    int 0x10
    ; asks user for file name
    mov bx, askname
    mov ah, 2
    int 0x42
    mov ah, 5
    int 0x42
    mov al, linestart
    mov ah, 1
    int 0x42
    mov cx, 8
    mov di, filename
    ; switches the variables letters with the entered letters
nextletname:
    mov ah, 0
    int 0x16
    cmp al, newln
    je endname
    mov [di], al
    inc di
    mov ah, 1
    int 0x42
    dec cx
    jcxz endname
    jmp nextletname 
endname:
    ; tells the user the file is saving
    mov bx, saving
    mov ah, 2
    int 0x42
    ; gets sectors
    mov cx, 1
    mov ah, 6
    int 0x69
    mov cx, 1
    mov ah, 6
    int 0x69
    xor dh, dh
    mov dl, [0x5400]
    mov ax, dx
    push dx
    ; gets and writes file descriptor
    mov bx, filename
    mov word [0xf000], 0x0000
    mov dx, [size]
    mov word [0xf002], dx
    mov cx, 0xf000
    mov al, 0
    mov ah, 7
    push dx
    int 0x69
    mov bx, 19
    mov cx, 14
    mov dx, 0x3800
    mov ah, 1
    int 0x69
    ; finds the first free space in the root directory
    mov di, 0x37e0
    mov si, 0x5400
findfirstfree:
    add di, 0x40
    cmp byte [di], 0x0
    jne findfirstfree
    mov cx, 32
    ; adds the descriptor to the root directory
appenddescriptor:
    dec cx
    mov dh, [si]
    mov [di], dh
    inc di
    inc si
    cmp cx, 0
    jne appenddescriptor
    ; writes the new root directory
    mov bx, 19
    mov cx, 14
    mov dx, 0x3800
    mov ah, 8
    int 0x69
    ; reads current fat
    mov bx, 1
    mov cx, 9
    mov dx, 0x5e00
    mov ah, 1
    int 0x69
    pop bx
writenext:
    push bx
    ; calculates the relevant word index
    mov ax, bx
    shr ax, 1
    add ax, bx
    mov di, 0x5e00
    add di, ax
    mov dx, 0xffff
    shr bx, 1
    ; checks if the right or left 12 bits should be kept
    jc odd4
    and dx, 0x0fff
    jmp even4
odd4:
    shl dx, 4  
even4:
    add [di], dx
    ; writes new fat tables
    mov ah, 8
    mov bx, 1
    mov cx, 9
    mov dx, 0x5e00
    int 0x69
    mov ah, 8
    mov bx, 10
    mov cx, 9
    mov dx, 0x5e00
    int 0x69
    ; clears screen and exits to terminal
    mov al, 0x12
    mov ah, 0x00
    int 0x10
    mov ah, 2
    int 0x96


;data
filename db "        TXT"
startmsg db "Please press n for new file", 0
filemsg db "Please press escape to save and exit", 0
askname db "Please enter a name for the file", 0
saving db "Saving...", 0
memstart dw 0
lineam db 0
bytesize db 0
currentline db 0
currentchar db 0
memoryblockam db 0