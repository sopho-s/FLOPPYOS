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
    int 0x69
    ; boots terminal
    mov ax, 0x9000
    mov [memorystart], ax
    mov ax, 0x60
    mov [sectorread], ax
    mov ax, 2
    mov [numbertoread], ax
    call readsect
    jmp 0x9000

setupint:
    XOR AX,AX
    MOV ES,AX
    CLI ; Disable interrupts, might not be needed if seting up a software-only interrupt
    mov di, INT69
    MOV ES:[0x69*4], di  ; setups offset of handler 22h
    MOV ES:[0x69*4+2], CS            ; Here I'm assuming segment of handler is current CS
    STI
    ret

INT69:
    cmp ah, 0
    je endint69
    cmp ah, 1
    jne endint69
    ; sets all the preconditions
    push ax
    xor ah, ah
    mov [sectorread], ax
    pop ax
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
endint69:
    iret

printmdigit:
    mov cx, 0
    mov ax, [tempnum]
    mov [quot], ax
repeat:
    xor ax, ax
    xor bx, bx
    xor dx, dx
    mov ax, [quot]
    mov bx, 10
    div bx
    mov [quot], ax
    cmp ax, 0
    je divend
    mov ax, dx
    push ax
    inc cx
    jmp repeat
divend:
    mov ax, dx
    push ax
    inc cx
repeatprint:
    dec cx
    pop ax
    mov [tempnum], ax
    push cx
    call printdigit
    pop cx
    cmp cx, 0
    jne repeatprint
    ret

printdigit:
    mov ax, 0x30
    add [tempnum], ax
    mov ax, [tempnum]
    call printChar
    ret

printChar:
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
terminalpostion db 0x
kernelstartmsg db "Kernel loaded", 0
startmsg db "Welcome to FLOPPYOS", 0
terminalerror db "Error loading terminal", 0
totalsectors dw 2880
sectorspertrack dw 18
tracksperside dw 80
headspercylinder dw 2
sectorread dw 0
sectortoread db 0
tracktoread db 0
headtoread db 0
numbertoread db 0
tempnum dw 0
quot dw 0
memorystart dw 0

times 7680-($-$$) db 0x00        
dw 0x08