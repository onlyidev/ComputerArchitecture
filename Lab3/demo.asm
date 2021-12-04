%include "yasmmac.inc"

org 0x100

section .text
macPutString "I AM FINE", crlf, "$"

macPutString "i am not fine", crlf, "$"

macPutString "I am HALF FinE", crlf, "$"

mov cx, 26
mov di, Alphabet
add di, 25
std

Alpha:

.loop:
    mov ax, 64 ;;a-1
    ; mov ax, 96 ;;a-1
    add ax, cx
    stosb
    loop .loop

mov dx, Alphabet

mov ax, 0
mov ah, 0x09

int 0x21

mov cx, 26
mov di, alphabet
add di, 25
std

alpha:

.loop:
    mov ax, 96 ;;a-1
    add ax, cx
    stosb
    loop .loop

mov dx, alphabet

mov ax, 0
mov ah, 0x09

int 0x21

exit
%include "yasmlib.asm"

section .data
Alphabet:
    times 26 db 0
    db crlf, '$'

alphabet:
    times 26 db 0
    db crlf, '$'