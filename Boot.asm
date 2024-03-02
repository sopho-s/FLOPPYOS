bits 16

org		0x7c00	

start:
    ; sets variables to their error state
    mov bl, 0
    mov [0x0000], bl

    ; print startup message
    mov ah, 0x0e 
    mov bx, startmsg
    call printString
    call printNewline

    ; checks if there is enough memory for the kernel
    xor ax, ax
    mov ss, sp
    int 0x12
    cmp ax, [kernalsize]
    jl lowmemory

    ; checks the APM is supported
    mov ah, 0x53
    mov al, 0x00
    xor bx, bx
    int 0x15
    jc apmerror

    ; connect to APM interface
    mov ah, 0x53
    mov al, 0x01
    xor bx, bx
    int 0x15
    jc apmerror
    mov bl, 0
    mov [0x0000], bl

    ; load in kernel and hand over control
    mov ah, 0
    mov dl, 0
    int 0x13
    xor ax, ax                          
    mov es, ax
    mov ds, ax
    mov bp, 0x8000
    mov sp, 0x0000
    mov bx, 0x7e00
    
    mov ah, 2
    mov al, 2
    mov ch, 0
    mov cl, 2
    mov dh, 0
    mov dl, 0
    int 0x13

    
    jmp 0x7e00


lowmemory:
    mov ah, 0x0e
    mov bx, lowmemfail
    call printString
    jmp $

apmerror:
    mov ah, 0x0e
    mov bx, apmerr
    call printString
    jmp $


    kernalsize dw 1
    apmerr db "An error occured with your APM", 0
    lowmemfail db "Low memory", 0
    startmsg db "Loading kernel...", 0

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

times 510-($-$$) db 0              
dw 0xaa55