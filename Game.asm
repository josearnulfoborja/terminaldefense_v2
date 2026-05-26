; Game.asm - Lógica principal del videojuego (stubs)
.386
.model flat, stdcall

INCLUDE Irvine32.inc

AppendLog PROTO
CheckBlocked PROTO
IncAttempt PROTO
ResetAttempts PROTO
PickQuestion PROTO
ScoreProc PROTO
SetCategory PROTO
SetDifficulty PROTO
RemainingCount PROTO
SaveScore PROTO
ResetUsedFlags PROTO
EXTERN playerScore:DWORD

.data
CATEGORY_PROMPT BYTE 'Elija categoria (1-Facil, 2-Medio, 3-Dificil): ',0
DIFFICULTY_PROMPT BYTE 'Elija dificultad (1-Facil, 2-Medio, 3-Dificil): ',0
NOT_ENOUGH BYTE 'No hay suficientes preguntas en esa categoria/dificultad. Usando facil/1.',0Dh,0Ah,0
INVALID_CAT BYTE 'Categoria invalida. Usando Facil.',0Dh,0Ah,0
MSG_CORRECT BYTE 'Respuesta correcta!',0Dh,0Ah,0
MSG_INCORRECT BYTE 'Respuesta incorrecta.',0Dh,0Ah,0
MSG_BLOCKED BYTE 'Acceso bloqueado: excedio intentos.',0Dh,0Ah,0
LOG_START_GAME BYTE 'INICIO_JUEGO',0Dh,0Ah,0
LOG_ASK_CATEGORY BYTE 'PEDIR_CATEGORIA',0Dh,0Ah,0
LOG_ASK_DIFFICULTY BYTE 'PEDIR_DIFICULTAD',0Dh,0Ah,0
LOG_QUESTION_SHOWN BYTE 'PREGUNTA_MOSTRADA',0Dh,0Ah,0
LOG_USER_ANSWERED BYTE 'USUARIO_RESPONDIO',0Dh,0Ah,0
LOG_CORRECT BYTE 'RESULTADO: CORRECTO',0Dh,0Ah,0
LOG_INCORRECT BYTE 'RESULTADO: INCORRECTO',0Dh,0Ah,0
LOG_BLOCKED BYTE 'RESULTADO: BLOQUEADO',0Dh,0Ah,0
LOG_CRLF BYTE 0Dh,0Ah,0
selectedDifficulty BYTE 0
FINAL_MSG BYTE 'Puntaje final: ',0
SLASH_MSG BYTE '/',0

.code
GameProc PROC
    ; Reset por partida: intentos, puntaje y flags de preguntas usadas
    call ResetAttempts
    mov DWORD PTR playerScore, 0
    call ResetUsedFlags

    ; Verificar si bloqueado antes de iniciar (no debería tras reset)
    call CheckBlocked
    cmp eax, 1
    je Q_Blocked

    ; Log inicio de partida
    mov edx, OFFSET LOG_START_GAME
    call AppendLog

    ; Pedir categoria
    mov edx, OFFSET LOG_ASK_CATEGORY
    call AppendLog
    mov edx, OFFSET CATEGORY_PROMPT
    call WriteString
    call ReadInt        ; categoria en EAX
    cmp eax, 1
    jl UseDefaultCat
    cmp eax, 3
    jg UseDefaultCat
    ; establecer categoria (SetCategory espera categoria en EAX)
    call SetCategory
    ; Pedir dificultad
    mov edx, OFFSET LOG_ASK_DIFFICULTY
    call AppendLog
    mov edx, OFFSET DIFFICULTY_PROMPT
    call WriteString
    call ReadInt        ; dificultad en EAX
    ; guardar dificultad seleccionada
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
    ; default difficulty
    mov eax, 1
    call SetDifficulty

CheckRemaining:
    call RemainingCount
    cmp eax, 1
    je NotEnough
    mov ecx, 3          ; numero de preguntas por partida
    cmp eax, ecx
    jge StartQuiz
    ; si quedan menos de 3, ajustar ecx a cantidad restante
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
    ; ECX = numero de preguntas por partida (segun dificultad): 1->3,2->4,3->5
    mov al, [selectedDifficulty]
    cmp al, 1
    je UseEasyCount
    cmp al, 2
    je UseMedCount
    ; hard
    mov ecx, 5
    jmp SetCountDone
UseEasyCount:
    mov ecx, 3
    jmp SetCountDone
UseMedCount:
    mov ecx, 4
SetCountDone:
NextQ:
    call PickQuestion     ; EAX=ptr pregunta, EBX=respuesta
    push ebx              ; guardar respuesta en pila
    push eax              ; guardar puntero a pregunta
    ; Log: marcar que se mostró pregunta
    mov edx, OFFSET LOG_QUESTION_SHOWN
    call AppendLog
    ; Log: texto de la pregunta + CRLF
    pop edx               ; edx = puntero a pregunta
    push edx
    call AppendLog
    mov edx, OFFSET LOG_CRLF
    call AppendLog
    ; Mostrar pregunta al usuario
    pop edx
    call WriteString
    ; Log: usuario responde
    mov edx, OFFSET LOG_USER_ANSWERED
    call AppendLog
    call ReadInt          ; resultado en EAX
    pop ebx               ; respuesta correcta en EBX
    mov esi, eax          ; usuario answer
    cmp esi, ebx
    je Q_Correct
    ; incorrecto
    call IncAttempt
    mov edx, OFFSET MSG_INCORRECT
    call WriteString
    mov edx, OFFSET LOG_INCORRECT
    call AppendLog
    ; verificar bloqueo
    call CheckBlocked
    cmp eax, 1
    je Q_Blocked
    loop NextQ
    jmp EndQuiz

Q_Correct:
    call ScoreProc
    mov edx, OFFSET MSG_CORRECT
    call WriteString
    mov edx, OFFSET LOG_CORRECT
    call AppendLog
    loop NextQ
    jmp EndQuiz
    ; fallthrough

EndQuiz:
    ; mostrar puntaje final y max
    mov edx, OFFSET FINAL_MSG
    call WriteString
    mov eax, DWORD PTR playerScore
    call WriteInt
    mov edx, OFFSET SLASH_MSG
    call WriteString
    ; calcular max = preguntas_por_partida * 10
    ; ecx may be 0 here, recompute from selectedDifficulty
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
    ; Save score to file
    call SaveScore
    ; Log final score
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

END
