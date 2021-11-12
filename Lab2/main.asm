%include "yasmmac.inc"

org 0x100

;;8+3+(1)
%define MAX_FILENAME_SIZE 12 
;;5*10+4(;)+1($)
%define MAX_FILE_READ_BUFFER 55 

section .text

main:

;;;BEGIN;;;

macPutString "Liudas Kasperavicius", crlf, "1 kursas, 3 grupe", crlf, "$"

;;;GET COMMAND LINE ARG;;;

mov si, 0x81
mov di, inFile
mov cx, 0
mov cl, [0x80]

mov ax, 0
mov al, cl ;;Actual filename length

cmp cl, 0
jle ..whileEnd
.while:
    cmp byte [si], ' '
    je ..ignore
    
    movsb
    loop .while
    jmp ..whileEnd

    ..ignore:
    inc si
    dec al
    loop .while
    ..whileEnd:

cmp al, MAX_FILENAME_SIZE
jg errors.inputFileTooLong

cmp al, 0
jle errors.inputFileNotSpecified

;;;GET OUTPUT FILE;;;

macPutString "Enter output file", crlf, "$"
mov dx, outFile
mov ax, MAX_FILENAME_SIZE
call procGetStr
jc errors.readOutFile

;;;OPEN READ FILE ;;;
mov dx, inFile
call procFOpenForReading ;bx-> file descriptor
jc errors.openingReadFile
mov [reading], bx

;;;OPEN WRITE FILE;;;
mov dx, outFile
call procFCreateOrTruncate
jc errors.openingWriteFile

mov [writing], bx

;;; READ FILE DATA ;;;
mov cx, MAX_FILE_READ_BUFFER
mov dx, inBuffer

; Read first line
mov bx, [reading]
call procFReadLine

; Write first line
mov bx, [writing]
mov cx, ax ;ax is the length (see procFReadLine)
call procFWrite

; Read data
.readData:
    mov bx, [reading]
    call procFReadLine
    mov si, inBuffer
    ..firstBlock:
        lodsb
        cmp al, 'Y'
        je ..finalize

        cmp al, 0x3b
        jne ..firstBlock

    ..secondBlock:
        lodsb
        cmp al, 0x3b ;';'
        jne ..secondBlock ; Ignore second column

    ..thirdBlock:
        push dx
        mov dx, si
        call procParseInt16 ;;bx returns pointer to next address
        mov [intArray], ax
        mov si, bx
        pop dx

        ...while3:
        lodsb
        cmp al, 0x3b
        jne ...while3

    ..fourthBlock:
        push dx
        mov dx, si
        call procParseInt16 ;;bx returns pointer to next address
        mov [intArray+2], ax
        mov si, bx
        pop dx

        ...while4:
        lodsb
        cmp al, 0x3b
        jne ...while4

    ..fifthBlock:
        push dx
        mov dx, si
        call procParseInt16
        mov [intArray+4], ax
        mov si, bx
        sub bx, inBuffer
        mov [length], bx ;;Save line length
        pop dx

    ..doMath:
        cmp [intArray], word 0
        jle ..finalize

        cmp [intArray+2], word 0
        jle ..finalize

        mov ax, [intArray+2]
        add ax, [intArray+4]

        cwd
        mov cx, 17
        idiv cx

        cmp dx, 0
        jne ..finalize

    ..print:
        mov bx, [writing]
        mov cx, [length]
        inc cx
        mov dx, inBuffer
        call procFWrite
        jc errors.writeFile

    ..finalize:
        jmp .readData


.closeFiles:
mov bx, [reading]
call procFClose
jc errors.closingReadFile

mov bx, [writing]
call procFClose
jc errors.closingWriteFile

;;; END ;;;
macNewLine
macPutString "All data written successfully", crlf, "$"
exiter:
exit

errors:

.readOutFile:
macPutString "Input read error", crlf, "$"
jmp exiter

.inputFileTooLong:
macPutString "The input filename is too long", crlf, "$"
jmp exiter

.inputFileNotSpecified:
macPutString "The input file was not specified", crlf, "$"
jmp exiter

.openingReadFile:
macPutString "Error opening file for reading.", crlf, "$"
call procPutHexWord
jmp exiter

.openingWriteFile:
macPutString "Error opening file for writing.", crlf, "$"
call procPutHexWord
jmp exiter

.readingFile:
macPutString "Error reading file.", crlf, "$"
call procPutHexWord
jmp exiter

.closingReadFile:
macPutString "Error closing the input file.", crlf, "$"
jmp exiter


.closingWriteFile:
macPutString "Error closing the output file.", crlf, "$"
jmp exiter

.writeFile:
macPutString "Error writing to file.", crlf, "$"
jmp exiter



%include "yasmlib.asm"
;;;;;Procedures

procFReadLine:
push cx
push dx
push di
push si

mov di, inBuffer
mov si, charBuffer

.while:
    mov cx, 1
    mov dx, charBuffer
    call procFRead
    jc errors.readingFile
    
    cmp ax, 0 ;;EOF = STOP EVERYTHING
    jne ..cont
    jmp main.closeFiles
    ..cont:

    movsb
    dec si

    mov al, [si]

    cmp al, 0xa ;\n
    jne .while

    mov ax, di
    sub ax, inBuffer ;;return length over ax
    

    pop si
    pop di
    pop dx
    pop cx
    ret
section .data

length:
    dw 0

section .bss
outFile: resb MAX_FILENAME_SIZE
inFile: resb MAX_FILENAME_SIZE
reading: resw 1
writing: resw 1
inBuffer: resb MAX_FILE_READ_BUFFER
charBuffer: resb 1
intArray: resw 3