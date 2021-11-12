%include 'yasmmac.inc'

org 100h
section .text

%define MAX_BUF 80
%define MIN_BUF 10

start:
    ;;;Lab 1)

    macPutString "Liudas Kasperavicius, 1-as kursas, 3 grupe", crlf, "$"

    macNewLine

    macPutString "Iveskite eilute nuo 10 iki 80 simboliu", crlf, "$"

    mov dx, firstUserInput
    mov ax, MAX_BUF

    call procGetStrAndLength ;;Defined at the end of this file
    macNewLine

    mov [inputLength], al ;;Save length


    ;;; 2) dalis

    macPutString "Iveskite 3 teigiamus sveikuosius skaicius (kiekvienas naujoje eiluteje)", crlf, "$"

    cld ;DIR = UP
    mov di, intArray
    mov cx, 3
    getNums:
        call procGetUInt16
        macNewLine
        stosw ; ax -> [di]; di += 2
        loop getNums ;; cx--; cmp cx, 0; jne getNums;


    ; 3) dalis --> A3 (Switch 1 and 6 and insert '%' between 7 and 8)

    ;;;Make a copy
    cld
    mov si, firstUserInput
    mov di, inputCopy
    mov ch, 0
    mov cl, [inputLength] ;;inputLength is a byte
    inc cl ;;Copy the "$" symbol 
    rep movsb ;; while --cl > 0: [si] -> [di]; di++; si++



    ;Change 1 and 6
    mov al, [inputCopy]
    mov ah, [inputCopy+5]
    mov [inputCopy], ah
    mov [inputCopy+5], al

    mov ah, 0
    mov al, [inputLength] ;; inputLength is a byte
    ; inc al ;;Would be used in case of int 0x21 0x09 function to include "$" symbol added by procGetStrAndLength, but procPutStr uses NUL as terminator

    ;Insertion algorithm
    std ;; DIR = DOWN
    mov si, inputCopy
    add si, ax ;;Start at end of array
    mov di, si
    dec si
    mov cx, ax
    sub cx, 7 ;; Iteration count
    rep movsb
    mov byte [di], "%"

    ;; Print results: (Not in task description)

    macNewLine
    mov dx, inputCopy
    call procPutStr
    macNewLine

    ; 3) dalis --> B4
    macNewLine

    cld
    mov si, firstUserInput
    mov ch, 0
    mov cl, [inputLength]  

    macPutString "Ijungtu 1 3 ir 7 bitu sumos ivestai eilutei: ", "$"

    calcBits:
        mov bh, 0
        mov bl, 0
        lodsb

        mov dl, al
        macNewLine
        call procPutChar
        macPutString ": ", "$"

        ;;;First bit
        shr al, 1
        call procIsLowestBitOn
        add bh, bl

        ; ;;;Third bit
        shr al, 2
        call procIsLowestBitOn
        add bh, bl

        ; ;;;Last (Seventh) bit
        shr al, 4
        call procIsLowestBitOn
        add bh, bl

        ;;Print result
        mov ax, 0
        mov al, bh
        call procPutUInt16
        macPutChar " "
        loop calcBits
    
    ; 3) dalis -> C1
    ;;; Pastaba max(a / b + 3, b % 2, min(c, 123)) rezultatas NIEKADA nebus b % 2, nes a / b + 3 visada bus >= 3, o 0 <= b % 2 <= 1

    macNewLine
    macNewLine
    macPutString "max(a / b + 3, b % 2, min(c, 123)) = ", "$"

    mov dx, 0
    mov ax, [intArray] ;a
    mov bx, [intArray+2] ;b
    div bx
    add ax, 3

    push ax ; Save a / b + 3

    mov ax, bx ;;get b to ax
    mov bx, 2

    mov dx, 0
    div bx ;;result of b % 2 is in dx

    pop ax
    cmp ax, dx 

    jae para3 ;;ax is max(para1, para2)
    mov ax, dx

    para3:
    push ax ; Save max(para1, para2)

    mov ax, [intArray+4] ;;c
    mov bx, 123

    cmp ax, bx

    jae lastPart ;;bx is min(c, 123)
    mov bx, ax

    lastPart:
    pop ax

    cmp ax, bx 

    jae printResult ; ax is final result
    mov ax, bx

    printResult:
    call procPutUInt16
    macNewLine


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    exit



%include 'yasmlib.asm'


procGetStrAndLength:
   ; skaito  eilutę iš klaviatūros ir padaro ją ASCIIZ
   ; įvestis:  dx - buferio adresas; al - ilgiausios galimos sekos ilgis; 
   ; išvestis: dx - asciiz sekos adresas; 
   ;;; Papildoma išvestis: al -> nuskaitytos sekos ilgis.
   ; CF yra 1, jeigu buvo klaidų
   push bx
   push cx
   push dx
   mov bx, dx
   mov [bx], al
   mov ah, 0x0a
   int 0x21
   inc bx
   mov ch, 0
   mov cl, [bx]
;    inc bx
   ; .loopBySymbols:
   ;     mov al, [bx]
   ;     mov [bx-2], al
   ;     inc bx
   ;     loop .loopBySymbols 
   ; mov [bx-2], byte 0
   
   cld
   mov si, bx
   inc si
   mov di, si
   sub di, 2
   mov ah, 0
   mov al, [bx]
   rep movsb
   mov byte [di], "$"


   pop dx
   pop cx
   pop bx
   ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

procIsLowestBitOn:
    ;;Input al - litrally anything
    ;;Output bl - Either 1 or 0
    mov bl, 1
    and bl, al
    ret

procPutChar:
    ;; Input dl - char
    mov ah, 0x02
    int 0x21
    ret

section .data

section .bss
    firstUserInput: resb MAX_BUF+1 ;;For "$" symbol
    inputCopy: resb MAX_BUF+1
    inputLength: resb 1
    intArray: resw 3

; TESTS: 
; 3B ::::::: 3 ir matosi: ALT+254 (black square) ::::::: 2: J ::::::::::::::::: 1: skaicius 9 :::::::::::::::: 0: u
; 3C ::::: min skaicius: 3 :::::::::::: max skaicius: 2 ^ 16 - 1 = 65535 (ivestis 65532 1 2) 