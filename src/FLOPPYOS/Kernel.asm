bits 16

org 0x7e00
kernelstart:
    ; sets up interupts
    call setupint
    ; print startup message
    mov ah, 2
    mov bx, kernelstartmsg
    int 0x42
    mov ah, 5
    int 0x42
    ; prints os name
    mov ah, 2
    mov bx, startmsg
    int 0x42
    mov ah, 5
    int 0x42
    ; boots terminal
    mov ah, 2
    mov bx, terminalname
    mov cx, 0x9000
    int 0x69
    jmp 0x9000

setupint:
    xor ax,ax
    mov es,ax
    cli 
    mov di, INT69
    mov ES:[0x69*4], di  
    mov ES:[0x69*4+2], CS
    mov di, INT42
    mov ES:[0x42*4], di  
    mov ES:[0x42*4+2], CS
    mov di, INT83
    mov ES:[0x83*4], di  
    mov ES:[0x83*4+2], CS
    mov di, INT96
    mov ES:[0x96*4], di  
    mov ES:[0x96*4+2], CS
    sti
    ret

; ********************************* ;
; INT 69                            ;
; READ AND WRITING                  ;
; ********************************* ;

INT69:
    cmp ah, 0
    je endint69
; ********************************* ;
; READ SECTOR|AH=1|INT69            ;
;                                   ;
; INPUTS:                           ;
; BX = SECTOR START NUMBER          ;
; CX = NUMBER OF SECTORS TO READ    ;
; DX = RESULTANT MEMORY LOCATION    ;
;                                   ;
; OUTPUTS:                          ;
; AL = FAIL STATE                   ;
;                                   ;
; FAILSTATES:                       ;
; 0 = SUCCESS                       ;
; 1 = FAILED TO READ SECTOR         ;
; ********************************* ;
    cmp ah, 1
    jne INT69check2
    push bx
    push cx
    push dx
    ; sets all the preconditions
    mov [sectorread], bx
    push cx
    xor ch, ch
    mov [numbertoread], cx
    pop cx
    mov [memorystart], dx
    mov ax, [sectorread]
    ; calculates the CHS
    xor dx, dx
    div word [sectorspertrack]
    inc dl
    mov byte [sectortoread], dl
    xor dx, dx
    div word [headspercylinder]
    mov byte [headtoread], dl
    mov byte [tracktoread], al
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
    setc al
    pop dx
    pop cx
    pop bx
    iret
; ********************************* ;
; READ FILE|AH=2|INT69              ;
;                                   ;
; INPUTS:                           ;
; BX = FILE NAME                    ;
; CX = RESULTANT MEMORY LOCATION    ;
;                                   ;
; OUTPUTS:                          ;
; AL = FAIL STATE                   ;
;                                   ;
; FAILSTATES:                       ;
; 0 = SUCCESS                       ;
; 1 = FAILED TO READ SECTOR         ;
; 2 = FAILED TO FIND FILE           ;
; ********************************* ;
INT69check2:
    cmp ah, 2
    jne INT69check3
    push ax
    push bx
    push cx
    push dx
    mov ah, 3
    int 0x69
    ; currently will not read the right amount of sectors
    ;   _____ _    _          _   _  _____ ______ 
    ;  / ____| |  | |   /\   | \ | |/ ____|  ____|
    ; | |    | |__| |  /  \  |  \| | |  __| |__   
    ; | |    |  __  | / /\ \ | . - | | |_ |  __|  
    ; | |____| |  | |/ ____ \| |\  | |__| | |____ 
    ;  \_____|_|  |_/_/    \_\_| \_|\_____|______|    
    ;  
    mov dx, cx
    mov cx, 3
    mov ah, 1
    int 0x69
    pop dx
    pop cx
    pop bx
    pop ax
    iret
; ********************************* ;
; FIND FILE|AH=3|INT69              ;
;                                   ;
; INPUTS:                           ;
; BX = FILE NAME                    ;
;                                   ;
; OUTPUTS:                          ;
; AL = FAIL STATE                   ;
; BX = SECTOR NUMBER                ;
;                                   ;
; FAILSTATES:                       ;
; 0 = SUCCESS                       ;
; 1 = FAILED TO READ SECTOR         ;
; 2 = FAILED TO FIND FILE           ;
; ********************************* ;
INT69check3:
    cmp ah, 3
    jne endint69
    push cx
    push dx
    ; reads the root directory
    push cx
    push bx
    mov ah, 1
    mov bx, 19
    mov cx, 1
    mov dx, 0x4200
    int 0x69
    setc al
    cmp al, 1
    je endint69dc
    ; finds where the file is located
    mov ax, 0
    mov [count], ax
    mov [totalexp], ax
    pop bx
    mov cx, bx
    mov ax, 0x4200
    jmp INT69next3
INT69next3:
    ; checks if the two characters match
    mov di, ax
    mov dx, [di]
    mov di, cx
    cmp [di], dx
    jne INT69fail3
    ; increments both pointers
    inc ax
    ; checks if the value was found
    cmp word [count], 9
    je INT69pass3
    ; increments the count
    add word [count], 1                              
    add word [totalexp], 1
    ; increments the name of the directory
    mov cx, bx
    add cx, [count]
    jmp INT69next3
INT69fail3:
    ; increments the currently compared character
    inc ax
    mov cx, bx
    ; resets count
    mov word [count], 0
    ; increments the count of the total searched
    add word [totalexp], 1
    cmp word [totalexp], 0x1c00
    jl INT69next3
    sub sp, 4
    mov al, 2
    pop dx
    pop cx
    iret
INT69pass3:
    ; finds the physical sector and loads it into memory at the specified location
    pop bx
    add ax, 16
    mov di, ax
    mov bx, [di]
    add bx, 31
    mov al, 0
    pop dx
    pop cx
    iret
endint69dc:
    pop dx
    pop cx
endint69:
    iret


; ********************************* ;
; INT 42                            ;
; BASIC VIDEO FUNCTIONS             ;
; ********************************* ;

INT42:
    cmp ah, 0
    je endint42
; ********************************* ;
; PRINT CHAR|AH=1|INT42             ;
;                                   ;
; INPUTS:                           ;
; AL = CHAR                         ;
;                                   ;
; OUTPUTS:                          ;
; NONE                              ;
; ********************************* ;
    cmp ah, 1
    jne INT42check2
    mov ah, 0x0e 
    int 0x10
    iret
; ********************************* ;
; PRINT STRING|AH=2|INT42           ;
;                                   ;
; INPUTS:                           ;
; BX = STRING POINTER, ENDS WITH 0  ;
;                                   ;
; OUTPUTS:                          ;
; NONE                              ;
; ********************************* ;
INT42check2:
    cmp ah, 2
    jne INT42check3
    push ax
printString:
    ; move current character in al to print
    mov al, [bx]
    ; check if there is a character to print
    cmp al, 0
    je end
    mov ah, 1
    int 0x42
    ; increments to the next character and calls itself
    inc bx
    jmp printString
end:
    pop ax
    iret
; ********************************* ;
; PRINT DIGIT|AH=3|INT42            ;
;                                   ;
; INPUTS:                           ;
; AL = DIGIT                        ;
;                                   ;
; OUTPUTS:                          ;
; NONE                              ;
; ********************************* ;
INT42check3:
    cmp ah, 3
    jne INT42check4
    push ax
    ; adds 0x30 to the number to get its ASCII equivalent
    add al, 0x30
    ; prints number
    mov ah, 0x01
    int 0x42
    pop ax
    iret
; ********************************* ;
; PRINT MULTIPLE DIGITS|AH=4|INT42  ;
;                                   ;
; INPUTS:                           ;
; BX = DIGITS                       ;
;                                   ;
; OUTPUTS:                          ;
; NONE                              ;
; ********************************* ;
INT42check4:
    cmp ah, 4
    jne INT42check5
    push ax
    push cx
    push dx
    ; sets all parameters 
    mov cx, 0
    mov ax, bx
    mov [quot], ax
repeat:
    ; clears all not used registers
    xor ax, ax
    xor bx, bx
    xor dx, dx
    ; divides the number by ten to get the digit to put on the stack
    mov ax, [quot]
    mov bx, 10
    div bx
    mov [quot], ax
    ; checks if the devision is finished
    cmp ax, 0
    je divend
    mov ax, dx
    push ax
    ; increments the digit count
    inc cx
    jmp repeat
divend:
    mov ax, dx
    push ax
    inc cx
repeatprint:
    ; decrements the digit counter and gets the next digit to print from the stack
    dec cx
    pop ax
    push cx
    ; prints the digit
    mov ah, 3
    int 0x42
    pop cx
    ; checks if there are any more digits, if not finish
    cmp cx, 0
    jne repeatprint
    pop dx
    pop cx
    pop ax
    iret
; ********************************* ;
; PRINT NEW LINE|AH=5|INT42         ;
;                                   ;
; INPUTS:                           ;
; NONE                              ;
;                                   ;
; OUTPUTS:                          ;
; NONE                              ;
; ********************************* ;
INT42check5:
    cmp ah, 5
    jne endint42
    push ax
    ; prints new line
    mov ah, 0x0e
    mov al, 0x0A
    int 0x10
    mov al, 0x0D
    int 0x10
    pop ax
    iret
endint42:
    iret


; ********************************* ;
; INT 83                            ;
; STRING AND CHAR                   ;
; ********************************* ;

INT83:
    cmp ah, 0
    je endint83
; ********************************* ;
; CAPITALISE CHAR|AH=1|INT42        ;
;                                   ;
; INPUTS:                           ;
; AL = CHAR                         ;
;                                   ;
; OUTPUTS:                          ;
; AL = CAPITALISED CHAR             ;
; CF = FAIL STATE                   ;
;                                   ;
; FAIL STATES:                      ;
; 0 = SUCCESS                       ;
; 1 = ALREADY UPPERCASE OR INVALID  ;
; ********************************* ;
    cmp ah, 1
    jne INT83check2
    cmp al, 0x61
    jl endint83cf
    cmp al, 0x7A
    jg endint83cf
    sub al, 0x20
    clc
    iret
; ********************************* ;
; ********************************* ;
INT83check2:
    cmp ah, 2
    jne endint83
endint83cf:
    stc
endint83:
    iret

INT96:
    cmp ah, 0
    je endint96
; ***************************************** ;
; LOAD EXTERNAL PROGRAM FROM FILE|AH=1|INT96;
;                                           ;
; INPUTS:                                   ;
; BX = PHISICAL SECTOR                      ;
; CX = SECTOR AMOUNT                        ;
;                                           ;
; OUTPUTS:                                  ;
; AL = FAIL STATE                           ;
;                                           ;
; FAILSTATES:                               ;
; 0 = SUCCESS                               ;
; 1 = FAILED TO READ SECTOR                 ;
; ***************************************** ;
    cmp ah, 1
    jne INT96check2
    push dx
    mov dx, 0x9000
    mov ah, 1
    int 0x69
    mov sp, ss
    pop dx
    jmp 0x9000
; ***************************** ;
; EXIT TO TERMINAL|AH=2|INT96   ;
;                               ;
; INPUTS:                       ;
; NONE                          ;
;                               ;
; OUTPUTS:                      ;
; AL = FAIL STATE               ;
;                               ;
; FAILSTATES:                   ;
; 0 = SUCCESS                   ;
; 1 = FAILED TO READ SECTOR     ;
; ***************************** ;
INT96check2:
    cmp ah, 2
    jne endint96
    push bx
    push cx
    mov bx, terminalname
    mov cx, 0x9000
    int 0x69
    mov sp, ss
    pop cx
    pop bx
    jmp 0x9000
endint96:
    iret

INT80:
    cmp ah, 0
    je endint80
; ***************************** ;
; PROTECT MEMORY|AH=1|INT96     ;
;                               ;
; INPUTS:                       ;
; BX = MEMORY LOCATION START    ;
; CX = MEMORY SIZE              ;
;                               ;
; OUTPUTS:                      ;
; CX = MEMORY KEY               ;
; AL = FAIL STATE               ;
;                               ;
; FAILSTATES:                   ;
; 0 = SUCCESS                   ;
; 1 = FAILED TO PROTECT MEMORY  ;
; ***************************** ;
    cmp ah, 1
    jne endint80
    ; currently does nothing, i did not mean to add this
endint80:
    iret


Terminalerr:
    ; shows terminal error
    mov ah, 0x0e 
    mov bx, terminalerror
    call printString
    ret


; data
terminalname db "TERMINALBIN", 0
kernelstartmsg db "Kernel loaded", 0
startmsg db "Welcome to FLOPPYOS", 0
terminalerror db "Error loading terminal", 0
testmsg db "TEST", 0
totalsectors dw 2880
sectorspertrack dw 18
tracksperside dw 80
headspercylinder dw 2
reservedsectors dw 1
numberoffats db 2
rootentries dw 224
sectorsperfat dw 9

sectorread dw 0
sectortoread db 0
tracktoread db 0
headtoread db 0
numbertoread db 0
tempnum dw 0
quot dw 0
memorystart dw 0
count dw 0
totalexp dw 0

times 7680-($-$$) db 0x00
dw 0x88
