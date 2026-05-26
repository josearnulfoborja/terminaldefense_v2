; Score.asm - Administración de puntaje y progreso
.386
.model flat, stdcall

INCLUDE Irvine32.inc

ListSavedPlayers PROTO STDCALL

PUBLIC ScoreProc, ViewScore, playerScore, playerName

.data
    playerScore DWORD 0
    playerName BYTE 32 DUP(0)
    NAME_PROMPT BYTE 'Ingrese nombre de jugador: ',0

.code
ScoreProc PROC
    ; Sumar 10 puntos por acierto
    mov eax, DWORD PTR playerScore
    add eax, 10
    mov DWORD PTR playerScore, eax
    ret
ScoreProc ENDP

ViewScore PROC
    mov edx, OFFSET SCORE_TEXT
    call WriteString
    mov eax, DWORD PTR playerScore
    call WriteInt
    mov edx, OFFSET CRLF_MSG
    call WriteString
    ; mostrar lista de archivos de guardado y rutas
    call ListSavedPlayers
    ret
ViewScore ENDP

; SetPlayerName: pide y guarda el nombre del jugador en playerName
SetPlayerName PROC
    mov edx, OFFSET NAME_PROMPT
    call WriteString
    mov edx, OFFSET playerName
    mov ecx, 31
    call ReadString
    ret
SetPlayerName ENDP

.data
SCORE_TEXT BYTE 'Puntaje actual: ',0
CRLF_MSG BYTE 0Dh,0Ah,0

END
