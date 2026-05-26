.386
.model flat, stdcall

INCLUDE Irvine32.inc

PUBLIC PickQuestion
PUBLIC ResetUsedFlags
PUBLIC SetCategory
PUBLIC SetDifficulty
PUBLIC RemainingCount

.data
; 3 categorias x 3 dificultades x 10 preguntas por nivel = 30 preguntas
; Cat 1=Matematicas | Cat 2=Computacion | Cat 3=Logica
; Diff 1=Facil      | Diff 2=Medio     | Diff 3=Dificil
numQuestions DWORD 30

; Facil (10 preguntas: 4 Matematicas, 3 Computacion, 3 Logica)
Q1  BYTE 'Matematicas Facil: Cuanto es 2 + 2 ? ',0
Q2  BYTE 'Matematicas Facil: Cuanto es 3 + 5 ? ',0
Q3  BYTE 'Matematicas Facil: Cuanto es 10 - 4 ? ',0
Q4  BYTE 'Matematicas Facil: Cuanto es 12 / 3 ? ',0
Q5  BYTE 'Computacion Facil: Cuantos bits tiene un byte ? ',0
Q6  BYTE 'Computacion Facil: Cuanto es 2^3 ? ',0
Q7  BYTE 'Computacion Facil: Cuantos nibbles tiene un byte ? ',0
Q8  BYTE 'Logica Facil: Cuanto es 1 AND 1 ? ',0
Q9  BYTE 'Logica Facil: Si A=2 y B=3, cuanto es A+B ? ',0
Q10 BYTE 'Logica Facil: Cuanto es 1 OR 0 ? ',0

; Medio (10 preguntas: 3 Matematicas, 4 Computacion, 3 Logica)
Q11 BYTE 'Matematicas Medio: Cuanto es 6 * 7 ? ',0
Q12 BYTE 'Matematicas Medio: Cuanto es 81 / 9 ? ',0
Q13 BYTE 'Matematicas Medio: Cuanto es 25 - 13 ? ',0
Q14 BYTE 'Computacion Medio: Cuanto es 1010 en decimal (base 2) ? ',0
Q15 BYTE 'Computacion Medio: Cuantos bits hay en 2 bytes ? ',0
Q16 BYTE 'Computacion Medio: Cuanto es 0x0F en decimal ? ',0
Q17 BYTE 'Computacion Medio: Cuanto es 3 bytes en bits ? ',0
Q18 BYTE 'Logica Medio: Cuanto es 1 XOR 1 ? ',0
Q19 BYTE 'Logica Medio: Si X=5, cuanto es X*X-X ? ',0
Q20 BYTE 'Logica Medio: Cuantos numeros primos hay entre 1 y 10 ? ',0

; Dificil (10 preguntas: 3 Matematicas, 3 Computacion, 4 Logica)
Q21 BYTE 'Matematicas Dificil: Cuanto es 13 * 7 ? ',0
Q22 BYTE 'Matematicas Dificil: Cuanto es 17 + 25 ? ',0
Q23 BYTE 'Matematicas Dificil: Cuanto es 2^5 (potencia de 2)? ',0
Q24 BYTE 'Computacion Dificil: Cuanto es 0xFF en decimal ? ',0
Q25 BYTE 'Computacion Dificil: Cuantos KB tiene 1 MB ? ',0
Q26 BYTE 'Computacion Dificil: Cuanto es 2^8 ? ',0
Q27 BYTE 'Logica Dificil: Si f(x)=2x+3, cuanto es f(5) ? ',0
Q28 BYTE 'Logica Dificil: Cuanto es 100 mod 7 ? ',0
Q29 BYTE 'Logica Dificil: Cuantos numeros primos hay entre 1 y 20 ? ',0
Q30 BYTE 'Logica Dificil: Cuanto es (1 XOR 0) AND (1 OR 0) ? ',0

QuestionTable DWORD OFFSET Q1,  OFFSET Q2,  OFFSET Q3,  OFFSET Q4,  OFFSET Q5,  OFFSET Q6,
              OFFSET Q7,  OFFSET Q8,  OFFSET Q9,  OFFSET Q10, OFFSET Q11, OFFSET Q12,
              OFFSET Q13, OFFSET Q14, OFFSET Q15, OFFSET Q16, OFFSET Q17, OFFSET Q18,
              OFFSET Q19, OFFSET Q20, OFFSET Q21, OFFSET Q22, OFFSET Q23, OFFSET Q24,
              OFFSET Q25, OFFSET Q26, OFFSET Q27, OFFSET Q28, OFFSET Q29, OFFSET Q30

AnswerTable DWORD 4,  8,  6,  4,  8,  8,  2,  1,  5,  1,
            42, 9,  12, 10, 16, 15, 24, 0,  20, 4,
            91, 42, 32, 255, 1024, 256, 13, 2,  8, 1

; Categoria: 1=Matematicas(Q1-Q4,Q11-Q13,Q21-Q23), 2=Computacion(Q5-Q7,Q14-Q17,Q24-Q26), 3=Logica(resto)
CategoryTable   DWORD 1,1,1,1,2,2,2,3,3,3, 1,1,1,2,2,2,2,3,3,3, 1,1,1,2,2,2,3,3,3,3
; Dificultad: 10 Facil, 10 Medio, 10 Dificil
DifficultyTable DWORD 1,1,1,1,1,1,1,1,1,1, 2,2,2,2,2,2,2,2,2,2, 3,3,3,3,3,3,3,3,3,3

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
