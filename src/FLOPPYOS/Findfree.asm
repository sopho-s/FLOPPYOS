bits 16

org 0x9000
start:
    mov cx, 3
    mov ah, 6
    int 0x69
    push bx
    mov bx, msg
    mov ah, 2
    int 0x42
    pop bx
    mov si, 0x5400
next:
    mov bx, [si]
    mov ah, 4
    int 0x42
    dec cx
    mov al, 0x20
    mov ah, 1
    int 0x42
    add si, 2
    cmp cx, 0
    jne next
    mov ah, 5
    int 0x42
    mov ah, 2
    int 0x96

msg db "The next free sectors are: ", 0