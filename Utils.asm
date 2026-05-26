; Utils.asm - Rutinas auxiliares reutilizables
.386
.model flat, stdcall

INCLUDE Irvine32.inc

PUBLIC TrimString, AsciiToInt, CompareString, ClearScreenProc, DelayProc, StrLen

.data

.code

; -----------------------------------------------------------------------------
; StrLen: calcula la longitud de una cadena terminada en NUL.
;   Entrada: EDX = puntero a cadena
;   Salida : EAX = longitud (sin contar el NUL)
;   Preserva: EBX, ECX, EDX, ESI, EDI
; -----------------------------------------------------------------------------
StrLen PROC
    push esi
    mov esi, edx
    xor eax, eax
SL_Loop:
    cmp BYTE PTR [esi+eax], 0
    je  SL_Done
    inc eax
    jmp SL_Loop
SL_Done:
    pop esi
    ret
StrLen ENDP

; -----------------------------------------------------------------------------
; TrimString: elimina espacios/CR/LF/TAB al final de la cadena (in-place).
;   Entrada: EDX = puntero a cadena terminada en NUL
;   Salida : cadena modificada in-place
;   Preserva: EBX, ECX, EDX, ESI, EDI
; -----------------------------------------------------------------------------
TrimString PROC
    push esi
    push ecx
    ; longitud actual
    call StrLen           ; EAX = len
    cmp eax, 0
    je  TS_End
    mov esi, edx
    mov ecx, eax
TS_Loop:
    dec ecx
    mov al, [esi+ecx]
    cmp al, 20h           ; espacio
    je  TS_Cut
    cmp al, 09h           ; TAB
    je  TS_Cut
    cmp al, 0Dh           ; CR
    je  TS_Cut
    cmp al, 0Ah           ; LF
    je  TS_Cut
    jmp TS_End
TS_Cut:
    mov BYTE PTR [esi+ecx], 0
    cmp ecx, 0
    jg  TS_Loop
TS_End:
    pop ecx
    pop esi
    ret
TrimString ENDP

; -----------------------------------------------------------------------------
; AsciiToInt: convierte cadena ASCII a entero (soporta signo y dígitos 0-9).
;   Entrada: EDX = puntero a cadena terminada en NUL
;   Salida : EAX = valor entero (con signo)
;   Preserva: EBX, ECX, EDX, ESI, EDI
; -----------------------------------------------------------------------------
AsciiToInt PROC
    push esi
    push ebx
    push ecx
    mov esi, edx
    xor eax, eax
    xor ebx, ebx          ; flag de signo (0 = +, 1 = -)
    ; saltar espacios iniciales
A2I_Skip:
    mov cl, [esi]
    cmp cl, 20h
    jne A2I_CheckSign
    inc esi
    jmp A2I_Skip
A2I_CheckSign:
    cmp cl, '-'
    jne A2I_CheckPlus
    mov ebx, 1
    inc esi
    jmp A2I_Loop
A2I_CheckPlus:
    cmp cl, '+'
    jne A2I_Loop
    inc esi
A2I_Loop:
    mov cl, [esi]
    cmp cl, '0'
    jl  A2I_Done
    cmp cl, '9'
    jg  A2I_Done
    imul eax, 10
    sub cl, '0'
    movzx ecx, cl
    add eax, ecx
    inc esi
    jmp A2I_Loop
A2I_Done:
    cmp ebx, 0
    je  A2I_End
    neg eax
A2I_End:
    pop ecx
    pop ebx
    pop esi
    ret
AsciiToInt ENDP

; -----------------------------------------------------------------------------
; CompareString: compara dos cadenas NUL-terminadas.
;   Entrada: EDX = cadena A, ESI = cadena B
;   Salida : EAX = 1 si son iguales, 0 si difieren
;   Preserva: EBX, ECX, EDX, ESI, EDI
; -----------------------------------------------------------------------------
CompareString PROC
    push esi
    push edi
    push ecx
    mov edi, edx
CS_Loop:
    mov al, [edi]
    mov cl, [esi]
    cmp al, cl
    jne CS_NotEqual
    cmp al, 0
    je  CS_Equal
    inc edi
    inc esi
    jmp CS_Loop
CS_Equal:
    mov eax, 1
    jmp CS_End
CS_NotEqual:
    mov eax, 0
CS_End:
    pop ecx
    pop edi
    pop esi
    ret
CompareString ENDP

; -----------------------------------------------------------------------------
; ClearScreenProc: limpia la pantalla de consola (wrapper de Irvine Clrscr).
; -----------------------------------------------------------------------------
ClearScreenProc PROC
    call Clrscr
    ret
ClearScreenProc ENDP

; -----------------------------------------------------------------------------
; DelayProc: pausa la ejecución.
;   Entrada: EAX = milisegundos
; -----------------------------------------------------------------------------
DelayProc PROC
    call Delay
    ret
DelayProc ENDP

END
