bits 16

org 0x9000
startup:
    mov bx, startmessage
    mov ah, 2
    int 0x42
    mov ah, 5
    int 0x42
    ; waits for a number
    mov ah, 0
    int 0x16
    ; stores first digit
    push ax
    mov ah, 1
    int 0x42
    mov ah, 5
    int 0x42
    ; waits for another number
    mov ah, 0
    int 0x16
    ; stores second digit
    push ax
    mov ah, 1
    int 0x42
    mov ah, 5
    int 0x42
    ; pops both digits
    pop ax
    pop bx
    ; converts the ascii values to numbers
    sub bl, 0x30
    sub al, 0x30
    ; adds numbers together
    add bl, al
    xor bh, bh
    ; prints them
    mov ah, 4
    int 0x42
    mov ah, 5
    int 0x42
    ; returns to terminal
    mov ah, 2
    int 0x96

;data
startmessage db "Please enter two numbers", 0
times 7680-($-$$) db 0x00