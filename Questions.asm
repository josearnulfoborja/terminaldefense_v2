.386
.model flat, stdcall

INCLUDE Irvine32.inc

PUBLIC PickQuestion
PUBLIC ResetUsedFlags
PUBLIC SetCategory
PUBLIC SetDifficulty
PUBLIC RemainingCount

.data

numQuestions DWORD 18
; Preguntas - 3 categorias: 1=Facil, 2=Medio, 3=Dificil
Q1 BYTE 'Facil: Cuanto es 2 + 2 ? ',0
Q2 BYTE 'Facil: Cuanto es 3 + 5 ? ',0
Q3 BYTE 'Facil: Cuanto es 7 - 4 ? ',0
Q4 BYTE 'Facil: Cuanto es 6 * 3 ? ',0
Q5 BYTE 'Facil: Cuanto es 12 / 3 ? ',0
Q6 BYTE 'Facil: Cuanto es 9 + 1 ? ',0

Q7 BYTE 'Medio: Cuanto es 15 - 7 ? ',0
Q8 BYTE 'Medio: Cuanto es 4 * 5 ? ',0
Q9 BYTE 'Medio: Cuanto es 36 / 6 ? ',0
Q10 BYTE 'Medio: Cuanto es 9 * 9 ? ',0
Q11 BYTE 'Medio: Cuanto es 14 + 6 ? ',0
Q12 BYTE 'Medio: Cuanto es 20 - 3 ? ',0

Q13 BYTE 'Dificil: Cuanto es 13 * 7 ? ',0
Q14 BYTE 'Dificil: Cuanto es 144 / 12 ? ',0
Q15 BYTE 'Dificil: Cuanto es 2^5 ? (potencia) ',0
Q16 BYTE 'Dificil: Cuanto es 81 / 9 ? ',0
Q17 BYTE 'Dificil: Cuanto es 17 + 25 ? ',0
Q18 BYTE 'Dificil: Cuanto es 100 - 37 ? ',0

; Tables of pointers and answers
QuestionTable DWORD OFFSET Q1, OFFSET Q2, OFFSET Q3, OFFSET Q4, OFFSET Q5, OFFSET Q6,
              OFFSET Q7, OFFSET Q8, OFFSET Q9, OFFSET Q10, OFFSET Q11, OFFSET Q12,
              OFFSET Q13, OFFSET Q14, OFFSET Q15, OFFSET Q16, OFFSET Q17, OFFSET Q18

AnswerTable DWORD 4, 8, 3, 18, 4, 10,
            8, 20, 6, 81, 20, 17,
            91, 12, 32, 9, 42, 63

CategoryTable DWORD 1,1,1,1,1,1, 2,2,2,2,2,2, 3,3,3,3,3,3
DifficultyTable DWORD 1,1,1,1,1,1, 2,2,2,2,2,2, 3,3,3,3,3,3

; Runtime state
currentCategory DWORD 1
UsedFlags DWORD 18 DUP(0)
currentDifficulty DWORD 1

.code
; PickQuestion: devuelve en EAX la dirección del texto de la pregunta y en EBX la respuesta correcta
PickQuestion PROC
    ; Selecciona un índice aleatorio que pertenezca a la categoria actual y que no haya sido usado
    INVOKE GetTickCount
    mov ecx, DWORD PTR numQuestions
    xor edx, edx
    div ecx            ; EAX = quotient, EDX = remainder (start index)
    mov esi, edx       ; start index

    xor edi, edi        ; loop counter
FindLoop:
    ; candidate = (start + edi) % numQuestions
    mov eax, esi
    add eax, edi
    mov ebp, DWORD PTR numQuestions
    xor edx, edx
    div ebp
    mov ebx, edx      ; candidate index

    ; comprobar categoria
    lea eax, CategoryTable
    mov eax, DWORD PTR [eax + ebx*4]
    cmp eax, currentCategory
    jne NotMatch
    ; comprobar dificultad
    lea eax, DifficultyTable
    mov eax, DWORD PTR [eax + ebx*4]
    cmp eax, currentDifficulty
    jne NotMatch

    ; comprobar usado
    lea eax, UsedFlags
    mov eax, DWORD PTR [eax + ebx*4]
    cmp eax, 0
    jne NotMatch

    ; marcar como usado (guardar indice en edx para usar despues)
    mov edx, ebx

    ; devolver pregunta y respuesta
    lea eax, QuestionTable
    mov eax, DWORD PTR [eax + ebx*4]
    lea ecx, AnswerTable
    mov ecx, DWORD PTR [ecx + ebx*4]
    mov ebx, ecx        ; respuesta en EBX
    lea ecx, UsedFlags
    mov DWORD PTR [ecx + edx*4], 1
    ret

NotMatch:
    inc edi
    cmp edi, DWORD PTR numQuestions
    jl FindLoop

    ; si no encontró sin usar, devolver la primera que coincida (aunque ya usada)
    mov ebx, 0
ScanAgain:
    lea eax, CategoryTable
    mov eax, DWORD PTR [eax + ebx*4]
    cmp eax, currentCategory
    jne SkipScan
    ; tambien verificar dificultad
    lea eax, DifficultyTable
    mov eax, DWORD PTR [eax + ebx*4]
    cmp eax, currentDifficulty
    je ReturnThis
SkipScan:
    inc ebx
    cmp ebx, DWORD PTR numQuestions
    jl ScanAgain

    ; fallback, devolver indice 0
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

; ResetUsedFlags: pone a cero el array UsedFlags
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

; SetCategory: espera categoria en EAX, la guarda y resetea flags
SetCategory PROC
    mov DWORD PTR currentCategory, eax
    call ResetUsedFlags
    ret
SetCategory ENDP

; SetDifficulty: espera dificultad en EAX, la guarda y resetea flags
SetDifficulty PROC
    mov DWORD PTR currentDifficulty, eax
    call ResetUsedFlags
    ret
SetDifficulty ENDP

; RemainingCount: devuelve en EAX la cantidad de preguntas NO usadas para la categoria/dificultad actuales
RemainingCount PROC
    mov ecx, DWORD PTR numQuestions
    xor ebx, ebx
    xor eax, eax        ; contador
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

END
