; Input.asm - Rutinas de lectura y validación de entrada
.386
.model flat, stdcall

INCLUDE Irvine32.inc

TrimString PROTO
StrLen     PROTO

PUBLIC MenuProc, InputProc, inputBuffer

.data
    inputBuffer    BYTE 64 DUP(0)
    MAX_INPUT_LEN  DWORD 63
    MSG_EMPTY      BYTE 'Entrada vacia. Intente de nuevo.',0Dh,0Ah,0
    MSG_TOO_LONG   BYTE 'Entrada demasiado larga.',0Dh,0Ah,0

.code

; InputProc: lee una cadena, la limpia (trim) y valida.
;   Salida: EAX = 0 si OK, 1 si vacía, 2 si demasiado larga
;   La cadena queda en inputBuffer.
InputProc PROC
    ; limpiar buffer
    push edi
    push ecx
    mov edi, OFFSET inputBuffer
    mov ecx, 64
    xor eax, eax
    rep stosb
    pop ecx
    pop edi

    mov edx, OFFSET inputBuffer
    mov ecx, 64
    call ReadString
    ; Trim de blancos al final
    mov edx, OFFSET inputBuffer
    call TrimString
    ; medir longitud
    mov edx, OFFSET inputBuffer
    call StrLen           ; EAX = len

    cmp eax, 0
    je  InErrEmpty
    cmp eax, DWORD PTR MAX_INPUT_LEN
    jg  InErrTooLong
    mov eax, 0
    ret
InErrEmpty:
    mov edx, OFFSET MSG_EMPTY
    call WriteString
    mov eax, 1
    ret
InErrTooLong:
    mov edx, OFFSET MSG_TOO_LONG
    call WriteString
    mov eax, 2
    ret
InputProc ENDP

; MenuProc: muestra menú y devuelve selección en EAX
MenuProc PROC
    mov edx, OFFSET MENU_TEXT
    call WriteString
    call ReadInt
    ret
MenuProc ENDP

; Mensaje del menú
.data
MENU_TEXT BYTE 0Dh,0Ah, '1 - Jugar',0Dh,0Ah, '2 - Ver puntaje',0Dh,0Ah, '3 - Borrar guardado',0Dh,0Ah, '0 - Salir',0Dh,0Ah,'Ingrese opcion: ',0

END
