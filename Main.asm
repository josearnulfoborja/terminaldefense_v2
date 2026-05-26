; =============================================================================
;  Main.asm - SecureGame: Terminal Defense (version monolitica)
; -----------------------------------------------------------------------------
;  Proyecto Lenguaje Maquina - Ensamblador x86 + Irvine32
;  Este archivo unifica todos los modulos del proyecto en un solo .asm para que
;  pueda ensamblarse con el script de Irvine:
;       asm32 main
;
;  Modulos logicos contenidos (los .asm individuales se conservan en la carpeta
;  como referencia de la arquitectura modular del documento tecnico):
;     - Main      : orquestacion / menu principal
;     - Input     : lectura y validacion de entrada
;     - Game      : motor del juego y flujo de preguntas
;     - Security  : autenticacion y control de intentos
;     - Score     : administracion de puntaje
;     - FileIO    : persistencia y log de eventos
;     - Utils     : rutinas auxiliares
;     - Questions : banco de preguntas y seleccion
; =============================================================================

.386
.model flat, stdcall
.stack 4096

INCLUDE Irvine32.inc

; PROTOs para Win32 APIs no expuestas por Irvine32/SmallWin
FindFirstFileA   PROTO STDCALL :DWORD, :DWORD
FindNextFileA    PROTO STDCALL :DWORD, :DWORD
FindClose        PROTO STDCALL :DWORD
GetFullPathNameA PROTO STDCALL :DWORD, :DWORD, :DWORD, :DWORD
DeleteFileA      PROTO STDCALL :DWORD

; =============================================================================
;                                  DATOS
; =============================================================================
.data
; --- Mensajes y buffers generales (Main) ---
msgWelcome    BYTE "== SecureGame - Demostracion en ensamblador x86 ==",0Dh,0Ah,0
msgPressKey   BYTE "Presione una tecla para continuar...",0
msgGoodbye    BYTE 0Dh,0Ah,"Sesion finalizada. Gracias por jugar.",0Dh,0Ah,0
msgAuthAbort  BYTE "Saliendo del programa por fallo de autenticacion.",0Dh,0Ah,0
buffer        BYTE 64 DUP(0)
namePrompt    BYTE 'Ingrese nombre de jugador: ',0
PLAYER_LABEL  BYTE 'PLAYER: ',0
LOG_CRLF      BYTE 0Dh,0Ah,0
LOG_SESSION_START BYTE 'SESSION_START',0Dh,0Ah,0
LOG_SESSION_END   BYTE 'SESSION_END',0Dh,0Ah,0

; --- Input ---
inputBuffer   BYTE 64 DUP(0)
MAX_INPUT_LEN DWORD 63
MSG_EMPTY     BYTE 'Entrada vacia. Intente de nuevo.',0Dh,0Ah,0
MSG_TOO_LONG  BYTE 'Entrada demasiado larga.',0Dh,0Ah,0
MENU_TEXT     BYTE 0Dh,0Ah, '1 - Jugar',0Dh,0Ah, '2 - Ver puntaje',0Dh,0Ah, '3 - Borrar guardado',0Dh,0Ah, '0 - Salir',0Dh,0Ah,'Ingrese opcion: ',0

; --- Security ---
maxAttempts      DWORD 3
attempts         DWORD 0
expectedPassword BYTE 'admin123',0
authBuffer       BYTE 64 DUP(0)
maxAuthTries     DWORD 3
AUTH_PROMPT      BYTE 0Dh,0Ah,'== Autenticacion requerida ==',0Dh,0Ah,'Ingrese contrasena: ',0
AUTH_OK_MSG      BYTE 'Acceso concedido.',0Dh,0Ah,0
AUTH_FAIL_MSG    BYTE 'Contrasena incorrecta.',0Dh,0Ah,0
AUTH_LOCKED_MSG  BYTE 'Acceso denegado: se agotaron los intentos.',0Dh,0Ah,0
LOG_AUTH_OK      BYTE 'AUTH: SUCCESS',0Dh,0Ah,0
LOG_AUTH_FAIL    BYTE 'AUTH: FAIL',0Dh,0Ah,0
LOG_AUTH_LOCKED  BYTE 'AUTH: LOCKED',0Dh,0Ah,0
LOG_BLOCK_INC    BYTE 'SECURITY: ATTEMPT_INCREMENT',0Dh,0Ah,0

; --- Score ---
playerScore   DWORD 0
playerName    BYTE 32 DUP(0)
NAME_PROMPT   BYTE 'Ingrese nombre de jugador: ',0
SCORE_TEXT    BYTE 'Puntaje actual: ',0
CRLF_MSG      BYTE 0Dh,0Ah,0

; --- FileIO ---
filebuf          BYTE 64 DUP(0)
prefixName       BYTE 'scores_',0
suffixName       BYTE '.bin',0
bytesTransferred DWORD 0
fileScore        DWORD 0
searchPattern    BYTE 'scores_*.bin',0
findData         BYTE 320 DUP(0)
fullpathBuf      BYTE 512 DUP(0)
logname          BYTE 'run.log',0
LIST_HEADER      BYTE 0Dh,0Ah,'Saved score files:',0Dh,0Ah,0
PATH_LABEL       BYTE 'Full path: ',0
NO_FILES_MSG     BYTE 'No saved player files found.',0Dh,0Ah,0
SCORE_LABEL      BYTE ' Score: ',0
DEL_PROMPT       BYTE 'Ingrese nombre de jugador a borrar: ',0
DEL_OK           BYTE 'Archivo eliminado correctamente.',0Dh,0Ah,0
DEL_FAIL         BYTE 'No se pudo eliminar (archivo no existe o error).',0Dh,0Ah,0
CONFIRM_LABEL    BYTE 'Archivo a borrar: ',0
CONFIRM_PROMPT   BYTE 'Confirmar borrado? (1=Si, 0=No): ',0
DEL_CANCEL       BYTE 'Operacion cancelada.',0Dh,0Ah,0
SaveFailMsg      BYTE "Unable to save score to file.",0Dh,0Ah,0
LoadFailMsg      BYTE "No saved score for this player.",0Dh,0Ah,0

; --- Game ---
CATEGORY_PROMPT    BYTE 'Elija categoria (1-Facil, 2-Medio, 3-Dificil): ',0
DIFFICULTY_PROMPT  BYTE 'Elija dificultad (1-Facil, 2-Medio, 3-Dificil): ',0
NOT_ENOUGH         BYTE 'No hay suficientes preguntas en esa categoria/dificultad. Usando facil/1.',0Dh,0Ah,0
INVALID_CAT        BYTE 'Categoria invalida. Usando Facil.',0Dh,0Ah,0
MSG_CORRECT        BYTE 'Respuesta correcta!',0Dh,0Ah,0
MSG_INCORRECT      BYTE 'Respuesta incorrecta.',0Dh,0Ah,0
MSG_BLOCKED        BYTE 'Acceso bloqueado: excedio intentos.',0Dh,0Ah,0
LOG_START_GAME     BYTE 'START_GAME',0Dh,0Ah,0
LOG_ASK_CATEGORY   BYTE 'ASK_CATEGORY',0Dh,0Ah,0
LOG_ASK_DIFFICULTY BYTE 'ASK_DIFFICULTY',0Dh,0Ah,0
LOG_QUESTION_SHOWN BYTE 'QUESTION_SHOWN',0Dh,0Ah,0
LOG_USER_ANSWERED  BYTE 'USER_ANSWERED',0Dh,0Ah,0
LOG_CORRECT        BYTE 'RESULT: CORRECT',0Dh,0Ah,0
LOG_INCORRECT      BYTE 'RESULT: INCORRECT',0Dh,0Ah,0
LOG_BLOCKED        BYTE 'RESULT: BLOCKED',0Dh,0Ah,0
selectedDifficulty BYTE 0
FINAL_MSG          BYTE 'Puntaje final: ',0
SLASH_MSG          BYTE '/',0

; --- Questions ---
numQuestions DWORD 18
Q1  BYTE 'Facil: Cuanto es 2 + 2 ? ',0
Q2  BYTE 'Facil: Cuanto es 3 + 5 ? ',0
Q3  BYTE 'Facil: Cuanto es 7 - 4 ? ',0
Q4  BYTE 'Facil: Cuanto es 6 * 3 ? ',0
Q5  BYTE 'Facil: Cuanto es 12 / 3 ? ',0
Q6  BYTE 'Facil: Cuanto es 9 + 1 ? ',0
Q7  BYTE 'Medio: Cuanto es 15 - 7 ? ',0
Q8  BYTE 'Medio: Cuanto es 4 * 5 ? ',0
Q9  BYTE 'Medio: Cuanto es 36 / 6 ? ',0
Q10 BYTE 'Medio: Cuanto es 9 * 9 ? ',0
Q11 BYTE 'Medio: Cuanto es 14 + 6 ? ',0
Q12 BYTE 'Medio: Cuanto es 20 - 3 ? ',0
Q13 BYTE 'Dificil: Cuanto es 13 * 7 ? ',0
Q14 BYTE 'Dificil: Cuanto es 144 / 12 ? ',0
Q15 BYTE 'Dificil: Cuanto es 2^5 ? (potencia) ',0
Q16 BYTE 'Dificil: Cuanto es 81 / 9 ? ',0
Q17 BYTE 'Dificil: Cuanto es 17 + 25 ? ',0
Q18 BYTE 'Dificil: Cuanto es 100 - 37 ? ',0

QuestionTable DWORD OFFSET Q1, OFFSET Q2, OFFSET Q3, OFFSET Q4, OFFSET Q5, OFFSET Q6,
              OFFSET Q7, OFFSET Q8, OFFSET Q9, OFFSET Q10, OFFSET Q11, OFFSET Q12,
              OFFSET Q13, OFFSET Q14, OFFSET Q15, OFFSET Q16, OFFSET Q17, OFFSET Q18

AnswerTable DWORD 4, 8, 3, 18, 4, 10,
            8, 20, 6, 81, 20, 17,
            91, 12, 32, 9, 42, 63

CategoryTable   DWORD 1,1,1,1,1,1, 2,2,2,2,2,2, 3,3,3,3,3,3
DifficultyTable DWORD 1,1,1,1,1,1, 2,2,2,2,2,2, 3,3,3,3,3,3

currentCategory   DWORD 1
currentDifficulty DWORD 1
UsedFlags         DWORD 18 DUP(0)
quizCounter       DWORD 0          ; contador de preguntas restantes en GameProc

; =============================================================================
;                                  CODIGO
; =============================================================================
.code

; -----------------------------------------------------------------------------
;                         UTILIDADES (Utils)
; -----------------------------------------------------------------------------

; StrLen: EDX = puntero a cadena -> EAX = longitud
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

; TrimString: recorta CR/LF/espacio/TAB al final. EDX = puntero a cadena
TrimString PROC
    push esi
    push ecx
    call StrLen
    cmp eax, 0
    je  TS_End
    mov esi, edx
    mov ecx, eax
TS_Loop:
    dec ecx
    mov al, [esi+ecx]
    cmp al, 20h
    je  TS_Cut
    cmp al, 09h
    je  TS_Cut
    cmp al, 0Dh
    je  TS_Cut
    cmp al, 0Ah
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

; AsciiToInt: EDX = puntero a cadena -> EAX = entero
AsciiToInt PROC
    push esi
    push ebx
    push ecx
    mov esi, edx
    xor eax, eax
    xor ebx, ebx
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

; CompareString: EDX = A, ESI = B -> EAX = 1 si iguales, 0 si distintas
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

ClearScreenProc PROC
    call Clrscr
    ret
ClearScreenProc ENDP

DelayProc PROC
    call Delay
    ret
DelayProc ENDP

; -----------------------------------------------------------------------------
;                       FILE I/O y LOGGING (FileIO)
; -----------------------------------------------------------------------------

; BuildFilename: arma "scores_<playerName>.bin" en filebuf
BuildFilename PROC
    lea esi, prefixName
    lea edi, filebuf
CopyPref:
    mov al, [esi]
    cmp al, 0
    je PrefDone
    mov [edi], al
    inc esi
    inc edi
    jmp CopyPref
PrefDone:
    lea esi, playerName
CopyName:
    mov al, [esi]
    cmp al, 0
    je NameDone
    mov [edi], al
    inc esi
    inc edi
    jmp CopyName
NameDone:
    lea esi, suffixName
CopySuf:
    mov al, [esi]
    mov [edi], al
    inc esi
    inc edi
    cmp al, 0
    jne CopySuf
    ret
BuildFilename ENDP

; SaveScore: graba playerScore (DWORD) en scores_<playerName>.bin
SaveScore PROC
    call BuildFilename
    INVOKE CreateFileA, ADDR filebuf, 40000000h, 0, 0, 2, 80h, 0
    mov ebx, eax
    cmp ebx, -1
    je SaveFail
    lea eax, playerScore
    INVOKE WriteFile, ebx, eax, 4, ADDR bytesTransferred, 0
    INVOKE CloseHandle, ebx
    ret
SaveFail:
    mov edx, OFFSET SaveFailMsg
    call WriteString
    ret
SaveScore ENDP

; LoadScore: lee 4 bytes desde scores_<playerName>.bin a playerScore
LoadScore PROC
    call BuildFilename
    INVOKE CreateFileA, ADDR filebuf, 80000000h, 1, 0, 3, 80h, 0
    mov ebx, eax
    cmp ebx, -1
    je LoadFail
    INVOKE ReadFile, ebx, ADDR playerScore, 4, ADDR bytesTransferred, 0
    INVOKE CloseHandle, ebx
    ret
LoadFail:
    mov edx, OFFSET LoadFailMsg
    call WriteString
    ret
LoadScore ENDP

; ListSavedPlayers: muestra scores_*.bin con su ruta y puntaje
ListSavedPlayers PROC
    mov edx, OFFSET LIST_HEADER
    call WriteString
    INVOKE FindFirstFileA, ADDR searchPattern, ADDR findData
    mov esi, eax
    cmp esi, -1
    je NoFiles
F_FindLoop:
    lea edx, [findData + 44]
    call WriteString
    lea edx, [findData + 44]
    INVOKE GetFullPathNameA, edx, 512, ADDR fullpathBuf, 0
    mov edx, OFFSET PATH_LABEL
    call WriteString
    mov edx, OFFSET fullpathBuf
    call WriteString
    INVOKE CreateFileA, ADDR fullpathBuf, 80000000h, 1, 0, 3, 80h, 0
    mov ebx, eax
    cmp ebx, -1
    je SkipRead
    INVOKE ReadFile, ebx, ADDR fileScore, 4, ADDR bytesTransferred, 0
    INVOKE CloseHandle, ebx
    mov eax, DWORD PTR fileScore
    mov edx, OFFSET SCORE_LABEL
    call WriteString
    call WriteInt
    mov edx, OFFSET CRLF_MSG
    call WriteString
SkipRead:
    INVOKE FindNextFileA, esi, ADDR findData
    cmp eax, 0
    jne F_FindLoop
    INVOKE FindClose, esi
    ret
NoFiles:
    mov edx, OFFSET NO_FILES_MSG
    call WriteString
    ret
ListSavedPlayers ENDP

; DeleteSavedPlayer: pide nombre y elimina scores_<nombre>.bin
DeleteSavedPlayer PROC
    mov edx, OFFSET DEL_PROMPT
    call WriteString
    mov edx, OFFSET playerName
    mov ecx, 31
    call ReadString
    call BuildFilename
    mov edx, OFFSET CONFIRM_LABEL
    call WriteString
    mov edx, OFFSET filebuf
    call WriteString
    mov edx, OFFSET CONFIRM_PROMPT
    call WriteString
    call ReadInt
    cmp eax, 1
    jne DelCanceled
    INVOKE DeleteFileA, ADDR filebuf
    cmp eax, 0
    je DelFail
    mov edx, OFFSET DEL_OK
    call WriteString
    ret
DelFail:
    mov edx, OFFSET DEL_FAIL
    call WriteString
    ret
DelCanceled:
    mov edx, OFFSET DEL_CANCEL
    call WriteString
    ret
DeleteSavedPlayer ENDP

; AppendLog: escribe la cadena en EDX al final de run.log
; FIX: las llamadas INVOKE (stdcall) destruyen EAX/ECX/EDX, por lo que
; debemos guardar EDX (puntero al mensaje) ANTES de cualquier INVOKE,
; o de lo contrario se hace WriteFile con un puntero basura y el proceso
; muere por access violation.
AppendLog PROC
    push edx                                     ; preservar puntero al mensaje
    push ebx                                     ; preservar EBX (lo usa el caller, p.ej. AuthProc)
    push esi
    INVOKE CreateFileA, ADDR logname, 40000000h, 0, 0, 4, 80h, 0
    mov ebx, eax
    cmp ebx, -1
    je LogFail
    INVOKE SetFilePointer, ebx, 0, 0, 2
    mov esi, [esp+8]                             ; recuperar puntero salvado (EDX original)
    xor ecx, ecx
LenLoop2:
    mov al, [esi+ecx]
    cmp al, 0
    je LenDone2
    inc ecx
    jmp LenLoop2
LenDone2:
    INVOKE WriteFile, ebx, esi, ecx, ADDR bytesTransferred, 0
    INVOKE CloseHandle, ebx
    pop esi
    pop ebx
    pop edx
    ret
LogFail:
    pop esi
    pop ebx
    pop edx
    ret
AppendLog ENDP

; -----------------------------------------------------------------------------
;                         SEGURIDAD (Security)
; -----------------------------------------------------------------------------

IncAttempt PROC
    mov eax, DWORD PTR attempts
    inc eax
    mov DWORD PTR attempts, eax
    push eax
    mov edx, OFFSET LOG_BLOCK_INC
    call AppendLog
    pop eax
    ret
IncAttempt ENDP

CheckBlocked PROC
    mov eax, DWORD PTR attempts
    cmp eax, DWORD PTR maxAttempts
    jb NotBlocked
    mov eax, 1
    ret
NotBlocked:
    mov eax, 0
    ret
CheckBlocked ENDP

ResetAttempts PROC
    mov DWORD PTR attempts, 0
    ret
ResetAttempts ENDP

; AuthProc: autenticacion con 3 intentos. EAX = 1 OK, 0 bloqueado
AuthProc PROC
    push ebx
    push esi
    mov ebx, DWORD PTR maxAuthTries
AuthLoop:
    mov edx, OFFSET AUTH_PROMPT
    call WriteString
    mov edx, OFFSET authBuffer
    mov ecx, 63
    call ReadString
    mov edx, OFFSET authBuffer
    call TrimString
    mov edx, OFFSET authBuffer
    mov esi, OFFSET expectedPassword
    call CompareString
    cmp eax, 1
    je  AuthSuccess
    mov edx, OFFSET AUTH_FAIL_MSG
    call WriteString
    mov edx, OFFSET LOG_AUTH_FAIL
    call AppendLog
    dec ebx
    cmp ebx, 0
    jg  AuthLoop
    mov edx, OFFSET AUTH_LOCKED_MSG
    call WriteString
    mov edx, OFFSET LOG_AUTH_LOCKED
    call AppendLog
    mov eax, 0
    jmp AuthDone
AuthSuccess:
    mov edx, OFFSET AUTH_OK_MSG
    call WriteString
    mov edx, OFFSET LOG_AUTH_OK
    call AppendLog
    mov eax, 1
AuthDone:
    pop esi
    pop ebx
    ret
AuthProc ENDP

; -----------------------------------------------------------------------------
;                          PUNTAJE (Score)
; -----------------------------------------------------------------------------

ScoreProc PROC
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
    call ListSavedPlayers
    ret
ViewScore ENDP

; -----------------------------------------------------------------------------
;                          PREGUNTAS (Questions)
; -----------------------------------------------------------------------------

; PickQuestion: EAX = ptr pregunta, EBX = respuesta correcta
PickQuestion PROC
    INVOKE GetTickCount
    mov ecx, DWORD PTR numQuestions
    xor edx, edx
    div ecx
    mov esi, edx

    xor edi, edi
Q_FindLoop:
    mov eax, esi
    add eax, edi
    mov ebp, DWORD PTR numQuestions
    xor edx, edx
    div ebp
    mov ebx, edx

    lea eax, CategoryTable
    mov eax, DWORD PTR [eax + ebx*4]
    cmp eax, currentCategory
    jne NotMatch
    lea eax, DifficultyTable
    mov eax, DWORD PTR [eax + ebx*4]
    cmp eax, currentDifficulty
    jne NotMatch

    lea eax, UsedFlags
    mov eax, DWORD PTR [eax + ebx*4]
    cmp eax, 0
    jne NotMatch

    mov edx, ebx
    lea eax, QuestionTable
    mov eax, DWORD PTR [eax + ebx*4]
    lea ecx, AnswerTable
    mov ecx, DWORD PTR [ecx + ebx*4]
    mov ebx, ecx
    lea ecx, UsedFlags
    mov DWORD PTR [ecx + edx*4], 1
    ret

NotMatch:
    inc edi
    cmp edi, DWORD PTR numQuestions
    jl Q_FindLoop

    mov ebx, 0
ScanAgain:
    lea eax, CategoryTable
    mov eax, DWORD PTR [eax + ebx*4]
    cmp eax, currentCategory
    jne SkipScan
    lea eax, DifficultyTable
    mov eax, DWORD PTR [eax + ebx*4]
    cmp eax, currentDifficulty
    je ReturnThis
SkipScan:
    inc ebx
    cmp ebx, DWORD PTR numQuestions
    jl ScanAgain

    mov ebx, 0
ReturnThis:
    mov edx, ebx
    lea eax, QuestionTable
    mov eax, DWORD PTR [eax + ebx*4]
    lea ecx, AnswerTable
    mov ecx, DWORD PTR [ecx + ebx*4]
    mov ebx, ecx
    lea ecx, UsedFlags
    mov DWORD PTR [ecx + edx*4], 1
    ret
PickQuestion ENDP

ResetUsedFlags PROC
    mov ecx, DWORD PTR numQuestions
    xor ebx, ebx
    lea edi, UsedFlags
ClearLoop:
    mov DWORD PTR [edi + ebx*4], 0
    inc ebx
    cmp ebx, ecx
    jl ClearLoop
    ret
ResetUsedFlags ENDP

SetCategory PROC
    mov DWORD PTR currentCategory, eax
    call ResetUsedFlags
    ret
SetCategory ENDP

SetDifficulty PROC
    mov DWORD PTR currentDifficulty, eax
    call ResetUsedFlags
    ret
SetDifficulty ENDP

RemainingCount PROC
    mov ecx, DWORD PTR numQuestions
    xor ebx, ebx
    xor eax, eax
CountLoop:
    lea edx, CategoryTable
    mov edx, DWORD PTR [edx + ebx*4]
    cmp edx, currentCategory
    jne NextIdx
    lea edx, DifficultyTable
    mov edx, DWORD PTR [edx + ebx*4]
    cmp edx, currentDifficulty
    jne NextIdx
    lea edx, UsedFlags
    mov edx, DWORD PTR [edx + ebx*4]
    cmp edx, 0
    jne NextIdx
    inc eax
NextIdx:
    inc ebx
    cmp ebx, ecx
    jl CountLoop
    ret
RemainingCount ENDP

; -----------------------------------------------------------------------------
;                         ENTRADA (Input)
; -----------------------------------------------------------------------------

; InputProc: lee, hace trim y valida. EAX=0 OK, 1 vacia, 2 demasiado larga
InputProc PROC
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
    mov edx, OFFSET inputBuffer
    call TrimString
    mov edx, OFFSET inputBuffer
    call StrLen

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

MenuProc PROC
    mov edx, OFFSET MENU_TEXT
    call WriteString
    call ReadInt
    ret
MenuProc ENDP

; -----------------------------------------------------------------------------
;                         MOTOR DEL JUEGO (Game)
; -----------------------------------------------------------------------------

GameProc PROC
    ; Reset por partida
    call ResetAttempts
    mov DWORD PTR playerScore, 0
    call ResetUsedFlags

    call CheckBlocked
    cmp eax, 1
    je Q_Blocked

    mov edx, OFFSET LOG_START_GAME
    call AppendLog

    ; Pedir categoria
    mov edx, OFFSET LOG_ASK_CATEGORY
    call AppendLog
    mov edx, OFFSET CATEGORY_PROMPT
    call WriteString
    call ReadInt
    cmp eax, 1
    jl UseDefaultCat
    cmp eax, 3
    jg UseDefaultCat
    call SetCategory

    ; Pedir dificultad
    mov edx, OFFSET LOG_ASK_DIFFICULTY
    call AppendLog
    mov edx, OFFSET DIFFICULTY_PROMPT
    call WriteString
    call ReadInt
    mov [selectedDifficulty], al
    cmp eax, 1
    jl UseDefaultDiff
    cmp eax, 3
    jg UseDefaultDiff
    call SetDifficulty
    jmp CheckRemaining

UseDefaultDiff:
    mov eax, 1
    call SetDifficulty
    jmp CheckRemaining

UseDefaultCat:
    mov eax, 1
    mov edx, OFFSET INVALID_CAT
    call WriteString
    call SetCategory
    mov eax, 1
    call SetDifficulty

CheckRemaining:
    call RemainingCount
    cmp eax, 1
    je NotEnough
    mov ecx, 3
    cmp eax, ecx
    jge StartQuiz
    mov ecx, eax
    jmp StartQuiz

NotEnough:
    mov edx, OFFSET NOT_ENOUGH
    call WriteString
    mov eax, 1
    call SetCategory
    mov eax, 1
    call SetDifficulty
    mov ecx, 3

StartQuiz:
    mov al, [selectedDifficulty]
    cmp al, 1
    je UseEasyCount
    cmp al, 2
    je UseMedCount
    mov ecx, 5
    jmp SetCountDone
UseEasyCount:
    mov ecx, 3
    jmp SetCountDone
UseMedCount:
    mov ecx, 4
SetCountDone:
    mov DWORD PTR quizCounter, ecx               ; FIX: guardar contador en memoria,
                                                 ; porque ECX se destruye en los call
NextQ:
    call PickQuestion
    push ebx
    push eax
    mov edx, OFFSET LOG_QUESTION_SHOWN
    call AppendLog
    pop edx
    push edx
    call AppendLog
    mov edx, OFFSET LOG_CRLF
    call AppendLog
    pop edx
    call WriteString
    mov edx, OFFSET LOG_USER_ANSWERED
    call AppendLog
    call ReadInt
    pop ebx
    mov esi, eax
    cmp esi, ebx
    je Q_Correct
    call IncAttempt
    mov edx, OFFSET MSG_INCORRECT
    call WriteString
    mov edx, OFFSET LOG_INCORRECT
    call AppendLog
    call CheckBlocked
    cmp eax, 1
    je Q_Blocked
    dec DWORD PTR quizCounter                    ; FIX: usar contador en memoria
    cmp DWORD PTR quizCounter, 0
    jg  NextQ
    jmp EndQuiz

Q_Correct:
    call ScoreProc
    mov edx, OFFSET MSG_CORRECT
    call WriteString
    mov edx, OFFSET LOG_CORRECT
    call AppendLog
    dec DWORD PTR quizCounter                    ; FIX: usar contador en memoria
    cmp DWORD PTR quizCounter, 0
    jg  NextQ
    jmp EndQuiz

EndQuiz:
    mov edx, OFFSET FINAL_MSG
    call WriteString
    mov eax, DWORD PTR playerScore
    call WriteInt
    mov edx, OFFSET SLASH_MSG
    call WriteString
    mov al, [selectedDifficulty]
    cmp al, 1
    je CalcEasy
    cmp al, 2
    je CalcMed
    mov eax, 5
    jmp CalcDone
CalcEasy:
    mov eax, 3
    jmp CalcDone
CalcMed:
    mov eax, 4
CalcDone:
    imul eax, 10
    call WriteInt
    call SaveScore
    mov edx, OFFSET LOG_CRLF
    call AppendLog
    ret

Q_Blocked:
    mov edx, OFFSET MSG_BLOCKED
    call WriteString
    mov edx, OFFSET LOG_BLOCKED
    call AppendLog
    ret
GameProc ENDP

; -----------------------------------------------------------------------------
;                       PUNTO DE ENTRADA (Main)
; -----------------------------------------------------------------------------

Main PROC
    call MainProc
    exit
Main ENDP

MainProc PROC
    call ClearScreenProc
    mov edx, OFFSET msgWelcome
    call WriteString
    mov edx, OFFSET LOG_SESSION_START
    call AppendLog

    ; Autenticacion
    call AuthProc
    cmp eax, 1
    je  AuthOk
    mov edx, OFFSET msgAuthAbort
    call WriteString
    ret
AuthOk:

    ; Nombre de jugador
    mov edx, OFFSET namePrompt
    call WriteString
    mov edx, OFFSET playerName
    mov ecx, 31
    call ReadString
    mov edx, OFFSET playerName
    call TrimString

    ; Log player
    mov edx, OFFSET PLAYER_LABEL
    call AppendLog
    mov edx, OFFSET playerName
    call AppendLog
    mov edx, OFFSET LOG_CRLF
    call AppendLog

    ; Cargar puntaje previo si existe
    call LoadScore

MainLoop:
    call MenuProc
    cmp eax, 0
    je ExitProg
    cmp eax, 1
    je DoPlay
    cmp eax, 2
    je ShowScore
    cmp eax, 3
    je DeleteSaved
    jmp MainLoop

DoPlay:
    call GameProc
    jmp MainLoop

ShowScore:
    call ViewScore
    jmp MainLoop

DeleteSaved:
    call DeleteSavedPlayer
    jmp MainLoop

ExitProg:
    mov edx, OFFSET LOG_SESSION_END
    call AppendLog
    mov edx, OFFSET msgGoodbye
    call WriteString
    mov edx, OFFSET msgPressKey
    call WriteString
    call ReadChar
    ret
MainProc ENDP

END Main
