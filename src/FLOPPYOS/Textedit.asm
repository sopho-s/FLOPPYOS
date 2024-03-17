bits 16

org 0x9000

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
    mov ah, 2
    mov bx, filemsg
    int 0x42
    mov ah, 5
    int 0x42
    mov ah, 2
    int 0x96
    mov ah, 1
    mov al, 0x3e
    int 0x42
    

;data
startmsg db "please press n for new file", 0
filemsg db "please press escape to save and exit", 0