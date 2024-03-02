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
    ; boots terminal
    call bootTerminal

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

bootTerminal:
    ; starts terminal and intitialses the terminal memory store
    mov ah, 0x0e 
    mov cx, 0
    mov bx, terminalstartline
    call printString
inputwait:
    ; waits for user input from the keyboard
    mov ah, 0
    int 0x16
    cmp al, 0x0D
    je inputend
    ; prints the entered character and stores it in memory
    call printChar
    mov di, cx
    add di, [terminalcmdmem]
    mov [di], al
    ; sets a pointer to the last character in the command
    mov [generalpoint], di
    inc cx
    ; checks if the user has run out of memory
    mov ax, [terminalcmdsize]
    inc ax
    cmp cx, ax
    jne inputwait
    call printNewline
    mov bx, memerror
    call printString
    ; makes new terminal line
    jmp bootTerminal
inputend:
    call printNewline
    cmp cx, 0
    je new
    call checkcmd
    call printNewline
new:
    jmp bootTerminal

checkcmd:
    mov cx, 0
    mov ax, [cmds]
    mov ax, cmds
    push ax ; stack {cmds}
command:
    ; finds current command size
    mov ax, [i]
    mov bx, 2
    mul bx
    mov di, cmdsize
    add di, ax
    mov bx, [di]
    ; finds the size checked so far
    cmp bx, cx
    jle found
    ; checks that the currently compared char matched
    mov di, 0
    ; loads in the current checked value
    mov di, [terminalcmdmem]
    add di, cx
    mov al, [di]
    ; loads in the command char
    pop bx ; stack {}
    push ax ; stack {current letter entered}
    pop ax ; stact {}
    mov ah, [bx]
    inc bx
    push bx ; stack {cmds}
    inc cx
    cmp ah, al
    je command
    jmp next
next:
    ; pops command
    pop ax
    mov dx, [i]
    inc dx
    mov [i], dx
    mov ax, [cmdam]
    cmp dl, al
    je notfound
    mov cx, 0
    mov bx, [i]
    add bx, [i]
    mov di, cmdcumsize
    add di, bx
    sub di, 2
    mov ax, [di]
    mov di, cmds
    add di, ax
    mov ax, di
    mov cx, 0
    push ax
    jmp command
found:
    pop ax
    mov ah, 0x0e 
    mov bx, cmdfound
    call printString
    call functable
    mov ax, 0
    mov [i], ax
    ret
notfound:
    mov ah, 0x0e 
    mov bx, cmdnotfounderror
    call printString
    mov ax, 0
    mov [i], ax
    ret

functable:
    mov cx, [i]
    cmp cx, 0
    je shutdown
    cmp cx, 1
    je clear
    ret
    

clear:
    mov al, 0x03
    mov ah, 0x00
    int 0x10
    ret

shutdown:
    mov ah, 0x53
    mov al, 0x07
    mov bx, 0x01
    mov cx, 0x03
    int 0x15
    ret

test:
    mov bx, testmsg
    mov ah, 0x0e 
    call printString
    ret

; data
terminalcmdmem dw 0x8800
terminalcmdsize dw 0x199
generalmem dw 0x9000
generalmemsize dw 0x6fff
terminalstartline db ">", 0
kernelstartmsg db "Kernel loaded", 0
startmsg db "Welcome to FLOPPYOS", 0
memerror db "Out of memory", 0
cmdnotfounderror db "Command not found", 0
cmdfound db "Command found", 0
testmsg db "Test", 0
generalpoint dw 0
cmdam db 2
cmds db "shutdown", "clear"
cmdsize dw 8, 5
cmdcumsize dw 8, 13
i dw 0
count dw 0
address dw 0
testval dw 0
tempnum dw 0
quot dw 0

times 1022-($-$$) db 0          
dw 0xaa55