bits 16

org 0x9000
startup:
    mov bx, startmessage
    mov ah, 2
    int 0x42
    mov ah, 5
    int 0x42
    mov ah, 2
    int 0x96

;data
startmessage db "Test started", 0