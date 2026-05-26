Title SistemaNotas   SistemaNotas.asm
;@Author : Ing. Juan José Santos
;@Country: El Salvador, Centro America
;@eMail  : juan.santos@mail.utec.edu.sv

INCLUDE Irvine32.inc
INCLUDE Macros.inc

.data
notas       SDWORD 5 DUP(0)
reprobArr   SDWORD 5 DUP(0)

suma        SDWORD 0
promedio    SDWORD 0
mayor       SDWORD 0
menor       SDWORD 100

aprobados   DWORD 0
reprobados  DWORD 0
bonus       DWORD 0
puntajeExtra DWORD 0

msgError    BYTE "Nota invalida, ingrese entre 0 y 100",0
msgSuma     BYTE "Suma de notas: ",0
msgProm     BYTE "Promedio: ",0
msgMayor    BYTE "Mayor: ",0
msgMenor    BYTE "Menor: ",0
msgAprob    BYTE "Aprobado",0
msgReprob   BYTE "Reprobado",0
msgBonus    BYTE "Bono total por aprobados: ",0
msgFaltan   BYTE "Le faltan ",0
msgPts      BYTE " pts",0
msgFaltan2  BYTE " puntos para aprobar",0
msgArrow    BYTE " -> ",0
msgTitulo   BYTE "=== SISTEMA DE NOTAS ===",0
msgPedir    BYTE "Ingrese nota ",0
msgDosP     BYTE ": ",0
msgRep      BYTE "--- REPORTE ---",0
msgExtra    BYTE "Puntaje extra total necesario: ",0
msgAprobC   BYTE "Aprobados: ",0
msgReprobC  BYTE "Reprobados: ",0

.code
Main PROC
    CALL ClrScr
    mWriteString msgTitulo
    CALL CrLf
    CALL CrLf

    ; flujo de llamadas
    CALL leerNotas
    CALL calcularStats
    CALL clasificar
    CALL calcularBonus
    CALL mostrarReporte
    CALL mostrarBonus

Salir:
    CALL CrLf
    CALL WaitMsg
    Exit
Main ENDP

; ============================
; PROC 1: leerNotas
; ============================
leerNotas PROC USES EAX EBX ECX EDX ESI
    mov ECX, 5
    lea ESI, notas
    mov EBX, 1              ; contador visible (1..5)
LoopNotas:
    ; imprimir: "Ingrese nota N: "
    mWriteString msgPedir
    mov EAX, EBX
    CALL WriteDec
    mWriteString msgDosP

    CALL ReadInt
    ; validar rango 0-100
    CMP EAX, 0
    JL  InvalidNota
    CMP EAX, 100
    JG  InvalidNota

    ; si es válida
    mov [ESI], EAX
    add ESI, TYPE notas
    inc EBX
    loop LoopNotas
    jmp EndLeer

InvalidNota:
    mWriteString msgError
    CALL CrLf
    jmp LoopNotas

EndLeer:
    ret
leerNotas ENDP

; ============================
; PROC 2: calcularStats
; ============================
calcularStats PROC USES EAX EBX ECX ESI
    mov ECX, 5
    lea ESI, notas
    mov suma, 0
    mov mayor, 0
    mov menor, 100
LoopStats:
    mov EAX, [ESI]
    add suma, EAX

    CMP EAX, mayor
    JLE SkipMayor
    mov mayor, EAX
SkipMayor:

    CMP EAX, menor
    JGE SkipMenor
    mov menor, EAX
SkipMenor:

    add ESI, TYPE notas
    loop LoopStats

    ; promedio = suma / 5
    mov EAX, suma
    cdq
    mov EBX, 5
    idiv EBX
    mov promedio, EAX
    ret
calcularStats ENDP

; ============================
; PROC 3: clasificar
; ============================
clasificar PROC USES EAX EBX ECX ESI
    mov ECX, 5
    lea ESI, notas
    lea EBX, reprobArr
LoopClasif:
    mov EAX, [ESI]
    CMP EAX, 60
    JL  EsReprob
    ; aprobado
    inc aprobados
    jmp NextNota
EsReprob:
    inc reprobados
    mov [EBX], EAX
    add EBX, TYPE reprobArr
NextNota:
    add ESI, TYPE notas
    loop LoopClasif
    ret
clasificar ENDP

; ============================
; PROC 4: calcularBonus
; ============================
calcularBonus PROC USES EAX EBX ECX ESI
    ; bono = aprobados * 5
    mov EAX, aprobados
    mov EBX, 5
    mul EBX
    mov bonus, EAX

    ; puntos faltantes acumulados
    mov puntajeExtra, 0
    mov ECX, reprobados
    jecxz SkipBonus         ; si no hay reprobados, no sumar
    lea ESI, reprobArr
LoopBonus:
    mov EAX, 60
    sub EAX, [ESI]
    add puntajeExtra, EAX
    add ESI, TYPE reprobArr
    loop LoopBonus
SkipBonus:
    ret
calcularBonus ENDP

; ============================
; PROC 5: mostrarReporte
; ============================
mostrarReporte PROC USES EAX EBX ECX ESI
    CALL CrLf
    mWriteString msgRep
    CALL CrLf

    mWriteString msgAprobC
    mov EAX, aprobados
    CALL WriteDec
    CALL CrLf

    mWriteString msgReprobC
    mov EAX, reprobados
    CALL WriteDec
    CALL CrLf

    ; mostrar suma, promedio, mayor, menor
    mWriteString msgSuma
    mov EAX, suma
    CALL WriteInt
    CALL CrLf

    mWriteString msgProm
    mov EAX, promedio
    CALL WriteInt
    CALL CrLf

    mWriteString msgMayor
    mov EAX, mayor
    CALL WriteInt
    CALL CrLf

    mWriteString msgMenor
    mov EAX, menor
    CALL WriteInt
    CALL CrLf

    ; mostrar cada nota con estado
    mov ECX, 5
    lea ESI, notas
LoopRep:
    mov EAX, [ESI]
    CALL WriteInt
    mWriteString msgArrow
    CMP EAX, 60
    JL  MostrarReprob
    mWriteString msgAprob
    jmp MostrarFin
MostrarReprob:
    mWriteString msgReprob
MostrarFin:
    CALL CrLf
    add ESI, TYPE notas
    loop LoopRep
    ret
mostrarReporte ENDP

; ============================
; PROC 6: mostrarBonus
; ============================
mostrarBonus PROC USES EAX EBX ECX ESI
    mWriteString msgBonus
    mov EAX, bonus
    CALL WriteDec
    mWriteString msgPts
    CALL CrLf

    mWriteString msgExtra
    mov EAX, puntajeExtra
    CALL WriteDec
    CALL CrLf

    mov ECX, reprobados
    jecxz SkipShowBonus
    lea ESI, reprobArr
LoopShowBonus:
    mov EAX, 60
    sub EAX, [ESI]
    mWriteString msgFaltan
    CALL WriteInt
    mWriteString msgFaltan2
    CALL CrLf
    add ESI, TYPE reprobArr
    loop LoopShowBonus
SkipShowBonus:
    ret
mostrarBonus ENDP

End Main
