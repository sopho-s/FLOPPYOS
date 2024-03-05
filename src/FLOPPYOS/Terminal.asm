bits 16

org 0x9000
startup:
    mov bx, startmessage
    mov ah, 2
    int 0x42
    mov ah, 5
    int 0x42
bootTerminal:
    ; starts terminal and intitialses the terminal memory store
    mov cx, 0
    mov bx, terminalstartline
    mov ah, 2
    int 0x42
inputwait:
    ; waits for user input from the keyboard
    mov ah, 0
    int 0x16
    cmp al, 0x0D
    je inputend
    ; prints the entered character and stores it in memory
    mov ah, 1
    int 0x42
    cmp al, 0x08
    je backspace
    mov di, cx
    add di, [terminalcmdmem]
    mov [di], al
    mov [endpointer], di
    inc cx
    ; checks if the user has run out of memory
    mov ax, [terminalcmdsize]
    inc ax
    cmp cx, ax
    jne inputwait
    push ax
    mov ah, 5
    int 0x42
    mov bx, memerror
    mov ah, 2
    int 0x42
    pop ax
    ; makes new terminal line
    jmp bootTerminal
backspace:
    ; performs a backspace
    cmp cx, 0
    je inputwait
    mov al, 0x20
    mov ah, 1
    int 0x42
    mov al, 0x08
    mov ah, 1
    int 0x42
    dec cx
    jmp inputwait
inputend:
    mov ah, 5
    int 0x42
    cmp cx, 0
    je new
    call checkcmd
    mov ah, 5
    int 0x42
new:
    jmp bootTerminal

checkcmd:
    mov ax, 0
    mov [i], ax
    mov cx, 0
    mov ax, [cmds]
    mov ax, cmds
    push ax ; stack {cmds}
command:
    ; currently if one command shares all the first letters of another, if the smaller command is first then that one will be executed
    ;   _____ _    _          _   _  _____ ______ 
    ;  / ____| |  | |   /\   | \ | |/ ____|  ____|
    ; | |    | |__| |  /  \  |  \| | |  __| |__   
    ; | |    |  __  | / /\ \ | . - | | |_ |  __|  
    ; | |____| |  | |/ ____ \| |\  | |__| | |____ 
    ;  \_____|_|  |_/_/    \_\_| \_|\_____|______|    
    ;              
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
    ; checks if there are more commands left to search through
    mov dx, [i]
    inc dx
    mov [i], dx
    mov ax, [cmdam]
    cmp dl, al
    je notfound
    ; if there are more commands then check the next command
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
    dec cx
    mov di, [terminalcmdmem]
    add di, cx
    cmp di, [endpointer]
    jl parameterdecodestart
    pop ax
    jmp parameterdone
    ; if the command is found go to the func table and find which command to execute
parameterdone:
    jmp functable
notfound:
    ; if the command was not found reset the i value
    mov bx, cmdnotfounderror
    mov ah, 2
    int 0x42
    ret
parameterdecodestart:
    ; pops the unused var off the stack
    pop ax
    ; increments the parameter count
    mov bx, [parametercount]
    inc bx
    mov [parametercount], bx
    ; sets up di for reading
    inc di
    inc di
    ; pushes di to parameter
    push di
parameterdecode:
    ; checks if the end has been reached
    inc di
    cmp di, [endpointer]
    je parameterdone
    ; checks if there is a new variable
    mov dx, [di]
    cmp dx, 0x20
    je addnewparam
    jmp parameterdecode
addnewparam:
    ; increments the new parameter count
    mov bx, [parametercount]
    inc bx
    mov [parametercount], bx
    ; adds the new parameter
    inc di
    push di
    jmp parameterdecode


functable:
    ; choose which function to excecute
    mov cx, [i]
    cmp cx, 0
    je shutdown
    cmp cx, 1
    je clear
    cmp cx, 2
    je find
    

clear:
    ; clears the screen
    mov al, 0x03
    mov ah, 0x00
    int 0x10
    ret

shutdown:
    ; shutsdown the computer
    mov ah, 0x53
    mov al, 0x07
    mov bx, 0x01
    mov cx, 0x03
    int 0x15
    ret

find:
    ; checks the parameter count
    mov cx, 1
    cmp cx, [parametercount]
    jne badparam
    ; gets the parameter and sets the count to 8
    pop si
    mov cx, 8
nextname:
    ; checks if the file name has ended
    cmp cx, 0
    je extension
    ; checks if there is a "." delimeter and handles it
    mov al, [si]
    cmp al, 0x2e
    je endfilename
    ; converts the value to its uppercase equivelent if possible
    mov ah, 1
    int 0x83
    ; puts the new letter in the variable that will store the filename
    mov di, findname
    mov bx, 8
    sub bx, cx
    add di, bx
    mov [di], al
    inc si
    dec cx
    jmp nextname
endfilename:
    ; buffs the name up with spaces to fit the FAT12 file system
    cmp cx, 0
    je extension
    mov di, findname
    mov bx, 8
    sub bx, cx
    add di, bx
    mov dl, 0x20
    mov [di], dl
    dec cx
    jmp endfilename
extension:
    mov cx, 3
    inc si
nextextension:
    ; checks if the file name has ended
    cmp cx, 0
    je endfind
    ; checks if there is a "." delimeter and handles it
    mov al, [si]
    cmp al, 0x2e
    je endextension
    ; converts the value to its uppercase equivelent if possible
    mov ah, 1
    int 0x83
    mov di, findname
    ; puts the new letter in the variable that will store the filename
    mov bx, 11
    sub bx, cx
    add di, bx
    mov [di], al
    inc si
    dec cx
    jmp nextextension
endextension:
    ; buffs the name up with spaces to fit the FAT12 file system
    cmp cx, 0
    je endfind
    mov di, findname
    mov bx, 11
    sub bx, cx
    add di, bx
    mov dl, 0x20
    mov [di], dl
    dec cx
    jmp endextension
endfind:
    ; finds the file
    dec cx
    mov ah, 3
    mov bx, findname
    int 0x69
    ; if the file was not found or the read was not sucessful then it will display as such
    cmp al, 0
    jne failfind
    ; display the logical and physical sector of the file
    push bx
    mov bx, foundfilep1
    mov ah, 2
    int 0x42
    pop bx
    sub bx, 31
    push bx
    mov ah, 4
    int 0x42
    mov ah, 5
    int 0x42
    mov bx, foundfilep2
    mov ah, 2
    int 0x42
    pop bx
    mov ah, 4
    add bx, 31
    int 0x42
    ret
failfind:
    ; displays the error message
    mov bx, failedfind
    mov ah, 2
    int 0x42
    mov ah, 5
    int 0x42
    mov bx, findname
    mov ah, 2
    int 0x42
    ret


badparam:
    ; displays that the wrong amount of parameters were given
    mov bx, badparameters
    mov ah, 2
    int 0x42
    ;
    ; clean up stack here
    ;
    ret


; data
startmessage db "Terminal started", 0
terminalcmdmem dw 0x8800
terminalcmdsize dw 0x199
generalmem dw 0x9900
generalmemsize dw 0x6fff
terminalstartline db ">", 0
memerror db "Out of memory", 0
cmdnotfounderror db "Command not found", 0
badparameters db "Bad parameters for entered function", 0
failedfind db "Failed to find specified file", 0
foundfilep1 db "Found file, it is located at the logical sector: ", 0
foundfilep2 db "And is located at the physical sector: ", 0
testmsg db "Test", 0
findname db "TERMINALBIN"
parameterpoint dw 0
endpointer dw 0
parametercount dw 0
cmdam db 3
cmds db "shutdown", "clear", "find"
cmdsize dw 8, 5, 4
cmdcumsize dw 8, 13, 17
i dw 0
count dw 0
address dw 0
testval dw 0
tempnum dw 0
quot dw 0