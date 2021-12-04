%include "yasmmac.inc"

%define interrupt 0x21

org 0x100

section .text

;;BEGIN VIRUS
jmp set

oldInterrupt:
    dw 0, 0

procModify:
;; DS:DX
    push si
    push ax
    mov si, dx

    cld

    .while:
        lodsb

        cmp al, byte 'a'
        jb .skip
        cmp al, byte 'z'
        ja .skip
        je .zcase

        inc al

        mov [si-1], al

        jmp .while

    .zcase:
        mov [si-1], byte 'a'
        jmp .while

    .skip:
        cmp al, byte '$'
        je .endWhile
        jmp .while
    .endWhile:

    pop ax
    pop si
ret

newInterrupt:
macPushAll
cmp ah, 9
jne .skip
call procModify
.skip:
macPopAll
jmp far [cs:oldInterrupt]



set:
push cs
pop ds

mov ah, 0x35
mov al, interrupt

int 0x21 ;ES:BX

mov [cs:oldInterrupt], bx
mov [cs:oldInterrupt+2], es

macPutString "Interrupt vector modified", crlf, "$"

mov ah, 0x25 ;DS:DX
mov dx, newInterrupt
int 0x21 ;


mov dx, set+1

int 0x27 ;Make resident

%include "yasmlib.asm"
