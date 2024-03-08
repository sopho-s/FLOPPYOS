bits 16

org 0x9000
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
    mov cx, 0
    mov [i], cx
    mov [parametercount], cx
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
    ; finds the size checked so far
    cmp word [di], cx
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
    pop ax 
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
    mov word [parametercount], 1
    ; sets up di for reading
    add di, 2
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
    mov word [parametercount], 1
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
    cmp cx, 3
    je open
    cmp cx, 4
    je restart
    cmp cx, 5
    je datetime
    cmp cx, 6
    je colour
    cmp cx, 7
    je help

clear:
    ; clears the screen
    mov al, 0x12
    mov ah, 0x00
    int 0x10
    mov ax, [parametercount]
    mov dx, 2
    mul dx
    add sp, ax
    ret

shutdown:
    ; shutsdown the computer
    mov ah, 0x53
    mov al, 0x07
    mov bx, 0x01
    mov cx, 0x03
    int 0x15
    mov ax, [parametercount]
    mov dx, 2
    mul dx
    add sp, ax
    ret

find:
    ; checks the parameter count
    mov cx, 1
    cmp cx, [parametercount]
    jne badparam
    pop si
    call formatfile
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
    mov ah, 5
    int 0x42
    ; currently here for test purposes
    mov bx, findname
    mov ah, 4
    int 0x69
    push cx
    mov bx, foundfilep3
    mov ah, 2
    int 0x42
    mov ah, 4
    pop cx
    mov bx, cx
    int 0x42
    mov ah, 5
    int 0x42
    ret
failfind:
    ; displays the error message
    cmp al, 1
    jne failfind2
    mov bx, failedfind1
    mov ah, 2
    int 0x42
    ret
failfind2:
    mov bx, failedfind2
    mov ah, 2
    int 0x42
    mov ah, 5
    int 0x42
    mov bx, findname
    mov ah, 2
    int 0x42
    ret


formatfile:
    ; gets the parameter and sets the count to 8
    mov cx, 8
nextname:
    ; checks if the file name has ended
    cmp cx, 0
    je extension
    ; checks if file has no extension
    mov ax, [endpointer]
    add ax, 1
    cmp si, ax
    jge endfilename
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
    je endformat
    mov al, [si]
    push ax
    ; checks if the end of the extension has been reached
    mov ax, [endpointer]
    add ax, 1
    cmp si, ax
    jge pushendextension
    pop ax
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
pushendextension:
    pop ax
endextension:
    ; buffs the name up with spaces to fit the FAT12 file system
    cmp cx, 0
    je endformat
    mov di, findname
    mov bx, 11
    sub bx, cx
    add di, bx
    mov dl, 0x20
    mov [di], dl
    dec cx
    jmp endextension
endformat:
    ret
    
open:
    ; checks the parameter count
    mov cx, 1
    cmp cx, [parametercount]
    jne badparam
    pop si
    call formatfile
    ; finds the file
    dec cx
    mov ah, 3
    mov bx, findname
    int 0x69
    ; if the file was not found or the read was not sucessful then it will display as such
    cmp al, 0
    jne failfind
    mov ah, 1
    mov cx, 1
    sub sp, 2
    int 0x96


restart:
    ; checks the parameter count
    mov cx, 0
    cmp cx, [parametercount]
    jne badparam
    mov sp, ss
    jmp 0xffff:0


datetime:
    ; checks parameter count
    mov cx, 0
    cmp cx, [parametercount]
    jne badparam
    mov ah, 4
    int 0x1a
    jc faileddatetime
    xor bl, bl
    ; gets date
    mov cl, dl
    call printbcd
    mov al, 0x2d
    mov ah, 1
    int 0x42


    mov ah, 4
    int 0x1a
    mov cl, dh
    xor bl, bl
    call printbcd
    mov al, 0x2d
    mov ah, 1
    int 0x42


    mov ah, 4
    int 0x1a
    mov cl, ch
    xor bl, bl
    call printbcd
    mov ah, 4
    int 0x1a
    mov bl, 1
    call printbcd

    mov al, 0x20
    mov ah, 1
    int 0x42
    mov al, 0x20
    mov ah, 1
    int 0x42

    ; gets time
    mov ah, 2
    int 0x1a
    mov cl, ch
    xor bl, bl
    call printbcd
    mov al, 0x3a
    mov ah, 1
    int 0x42

    mov ah, 2
    int 0x1a
    mov bl, 1
    call printbcd
    ret
faileddatetime:
    mov bx, faileddt
    mov ah, 2
    int 0x42
    ret

printbcd:
    push bx
    mov al, cl
    xor ah, ah
    push ax
    shr al, 4
    mov bx, 10
    mul bx
    mov bx, ax
    pop ax
    and ax, 00001111b
    add bx, ax
    pop cx
    cmp cl, 1
    jne double
    cmp bx, 10
    jge double
    mov al, 0x30
    mov ah, 1
    int 0x42
double:
    mov ah, 4
    int 0x42
    ret


colour:
    mov cx, 1
    cmp cx, [parametercount]
    jne badparam
    pop bx
    mov si, colours
    mov di, bx
    mov cx, 0
repeatcolour:
    mov al, [di]
    mov ah, 1
    int 0x83
    mov ah, [si]
    cmp ah, al
    jne failcolour
    inc si
    inc di
    cmp byte [si], 2
    jl foundcolour
    jmp repeatcolour
failcolour:
    mov di, bx
    inc cx
failcolourrep:
    inc si
    cmp byte [si], 0
    je nofoundcolour
    cmp byte [si], 1
    jne failcolourrep
    inc si
    jmp repeatcolour
nofoundcolour:
    mov bx, nocolour
    mov ah, 2
    int 0x42
    ret
foundcolour:
    mov bx, cx
    mov ah, 6
    int 0x42
    ret

help:
    mov bx, helptext1
    mov ah, 2
    int 0x42
    mov bx, helptext2
    mov ah, 2
    int 0x42
    mov bx, helptext3
    mov ah, 2
    int 0x42
    mov bx, helptext4
    mov ah, 2
    int 0x42
    mov bx, helptext5
    mov ah, 2
    int 0x42
    ret


badparam:
    ; displays that the wrong amount of parameters were given
    mov bx, badparameters
    mov ah, 2
    int 0x42
    mov ax, [parametercount]
    mov dx, 2
    mul dx
    add sp, ax
    ret


; data
terminalcmdmem dw 0x8800
terminalcmdsize dw 0x199
generalmem dw 0x9900
generalmemsize dw 0x6fff
terminalstartline db ">", 0
memerror db "Out of memory", 0
cmdnotfounderror db "Command not found", 0
badparameters db "Bad parameters for entered function", 0
failedfind2 db "Failed to find specified file", 0
failedfind1 db "Failed to read sector", 0
faileddt db "Failed to get date and time", 0
foundfilep1 db "Found file, it is located at the logical sector: ", 0
foundfilep2 db "And is located at the physical sector: ", 0
foundfilep3 db "The amount of sectors in the file is: ", 0
foundfilep4 db "The sectors are: ", 0
testmsg db "Test", 0
findname db "TERMINALBIN"
nocolour db "Failed to find specified colour", 0
parameterpoint dw 0
endpointer dw 0
parametercount dw 0
cmdam db 8
cmds db "shutdown", "clear", "find", "open", "restart", "datetime", "colour", "help"
cmdsize dw 8, 5, 4, 4, 7, 8, 6, 4
cmdcumsize dw 8, 13, 17, 21, 28, 36, 42, 46
colours db "BLACK", 1, "BLUE", 1, "GREEN", 1, "CYAN", 1, "RED", 1, "MAGENTA", 1, "BROWN", 1, "LIGHTGREY", 1, "DARKGREY", 1, "LIGHTBLUE", 1, "LIGHTGREEN", 1, "LIGHTCYAN", 1, "LIGHTRED", 1, "LIGHTMAGENTA", 1, "YELLOW", 1, "WHITE", 0 
i dw 0
count dw 0
address dw 0
testval dw 0
tempnum dw 0
quot dw 0
helptext1 db "clear: clears the terminal", 0x0A, 0x0D, "shutdown: shuts the computer down", 0x0A, 0x0D, 0
helptext2 db "find {filename}: finds a file on the computer and prints its logical and physical sector", 0x0A, 0x0D, 0
helptext3 db "open {filename}: opens the file specified and runs it", 0x0A, 0x0D, "restart: performs a warm restart", 0x0A, 0x0D, 0
helptext4 db "datetime: outputs the date time in a 'D-M-Y H:M' format", 0x0A, 0x0D, 0
helptext5 db "colour {colour}: changes all future text specified colour", 0