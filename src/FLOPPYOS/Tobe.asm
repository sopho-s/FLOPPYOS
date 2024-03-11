bits 16

org 0x9000

start:
    mov cx, 1
    mov ah, 6
    int 0x69
    xor dh, dh
    mov dl, [0x5400]
    mov ax, dx
    push dx
    push dx
    ; gets and writes file descriptor
    mov bx, filename
    mov word [0xf000], 0x0000
    mov dx, [size]
    mov word [0xf002], dx
    mov cx, 0xf000
    mov al, 0
    mov ah, 7
    pop dx
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
    mov di, 0x6100
    mov si, line1
    ; stores the lines into the file buffer
repline1:
    cmp byte [si], 0
    je startline2
    mov dh, [si]
    mov [di], dh
    inc di
    inc si
    jmp repline1
startline2:
    mov si, line2
repline2:
    cmp byte [si], 0
    je startline3
    mov dh, [si]
    mov [di], dh
    inc di
    inc si
    jmp repline2
startline3:
    mov si, line3
repline3:
    cmp byte [si], 0
    je writefile
    mov dh, [si]
    mov [di], dh
    inc di
    inc si
    jmp repline3
writefile:
    pop bx
    add bx, 31
    mov cx, 1
    mov dx, 0x6100
    mov ah, 8
    int 0x69
    mov ah, 2
    int 0x96




filename db "TOBE    TXT"
line1 db "To be, or not to be, that is the question:", 0x0A, 0x0D, 0
line2 db "Whether 'tis nobler in the mind to suffer", 0x0A, 0x0D, 0
line3 db "The slings and arrows of outrageous fortune,", 0x0A, 0x0D, 0
size dw 133