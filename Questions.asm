.386
.model flat, stdcall

INCLUDE Irvine32.inc

PUBLIC PickQuestion
PUBLIC ResetUsedFlags
PUBLIC SetCategory
PUBLIC SetDifficulty
PUBLIC RemainingCount

.data
; 3 categorias x 3 dificultades x 10 preguntas por combinacion = 90 preguntas
; Cat 1=Matematicas | Cat 2=Computacion | Cat 3=Logica
; Diff 1=Facil      | Diff 2=Medio     | Diff 3=Dificil
numQuestions DWORD 90

; Matematicas - Facil
Q1  BYTE 'Matematicas Facil: Cuanto es 2 + 2 ? ',0
Q2  BYTE 'Matematicas Facil: Cuanto es 3 + 5 ? ',0
Q3  BYTE 'Matematicas Facil: Cuanto es 10 - 4 ? ',0
Q4  BYTE 'Matematicas Facil: Cuanto es 12 / 3 ? ',0
Q5  BYTE 'Matematicas Facil: Cuanto es 7 + 1 ? ',0
Q6  BYTE 'Matematicas Facil: Cuanto es 9 - 2 ? ',0
Q7  BYTE 'Matematicas Facil: Cuanto es 5 * 2 ? ',0
Q8  BYTE 'Matematicas Facil: Cuanto es 6 + 3 ? ',0
Q9  BYTE 'Matematicas Facil: Cuanto es 14 / 2 ? ',0
Q10 BYTE 'Matematicas Facil: Cuanto es 1 + 9 ? ',0

; Matematicas - Medio
Q11 BYTE 'Matematicas Medio: Cuanto es 6 * 7 ? ',0
Q12 BYTE 'Matematicas Medio: Cuanto es 81 / 9 ? ',0
Q13 BYTE 'Matematicas Medio: Cuanto es 25 - 13 ? ',0
Q14 BYTE 'Matematicas Medio: Cuanto es 8 * 8 ? ',0
Q15 BYTE 'Matematicas Medio: Cuanto es 7 * 6 ? ',0
Q16 BYTE 'Matematicas Medio: Cuanto es 100 / 4 ? ',0
Q17 BYTE 'Matematicas Medio: Cuanto es 3 * 9 ? ',0
Q18 BYTE 'Matematicas Medio: Cuanto es 15 + 17 ? ',0
Q19 BYTE 'Matematicas Medio: Cuanto es 48 / 6 ? ',0
Q20 BYTE 'Matematicas Medio: Cuanto es 11 * 3 ? ',0

; Matematicas - Dificil
Q21 BYTE 'Matematicas Dificil: Cuanto es 13 * 7 ? ',0
Q22 BYTE 'Matematicas Dificil: Cuanto es 17 + 25 ? ',0
Q23 BYTE 'Matematicas Dificil: Cuanto es 2^5 (potencia de 2)? ',0
Q24 BYTE 'Matematicas Dificil: Cuanto es 144 / 12 ? ',0
Q25 BYTE 'Matematicas Dificil: Cuanto es 19 * 4 ? ',0
Q26 BYTE 'Matematicas Dificil: Cuanto es 99 - 37 ? ',0
Q27 BYTE 'Matematicas Dificil: Cuanto es 18 * 5 ? ',0
Q28 BYTE 'Matematicas Dificil: Cuanto es 121 / 11 ? ',0
Q29 BYTE 'Matematicas Dificil: Cuanto es 16^2 ? ',0
Q30 BYTE 'Matematicas Dificil: Cuanto es 7 * 13 ? ',0

; Computacion - Facil
Q31 BYTE 'Computacion Facil: Cuantos bits tiene un byte ? ',0
Q32 BYTE 'Computacion Facil: Cuanto es 2^3 ? ',0
Q33 BYTE 'Computacion Facil: Cuantos nibbles tiene un byte ? ',0
Q34 BYTE 'Computacion Facil: Cuantos bits hay en 2 bytes ? ',0
Q35 BYTE 'Computacion Facil: Cuanto es 1 byte en bits ? ',0
Q36 BYTE 'Computacion Facil: Cuantos bits tiene un nibble ? ',0
Q37 BYTE 'Computacion Facil: Cuanto es 2 bytes en bits ? ',0
Q38 BYTE 'Computacion Facil: Cuanto es 0x0A en decimal ? ',0
Q39 BYTE 'Computacion Facil: Cuanto es 0x0F en decimal ? ',0
Q40 BYTE 'Computacion Facil: Cuantos bits tiene 1 byte ? ',0

; Computacion - Medio
Q41 BYTE 'Computacion Medio: Cuanto es 1010 en decimal (base 2) ? ',0
Q42 BYTE 'Computacion Medio: Cuantos bits hay en 2 bytes ? ',0
Q43 BYTE 'Computacion Medio: Cuanto es 0x0F en decimal ? ',0
Q44 BYTE 'Computacion Medio: Cuanto es 3 bytes en bits ? ',0
Q45 BYTE 'Computacion Medio: Cuanto es 1011 en decimal (base 2) ? ',0
Q46 BYTE 'Computacion Medio: Cuantos bytes tiene 1 KB ? ',0
Q47 BYTE 'Computacion Medio: Cuanto es 2^4 ? ',0
Q48 BYTE 'Computacion Medio: Cuanto es 0x10 en decimal ? ',0
Q49 BYTE 'Computacion Medio: Cuantos bits tiene 1 byte ? ',0
Q50 BYTE 'Computacion Medio: Cuantos bytes son 4 KB ? ',0

; Computacion - Dificil
Q51 BYTE 'Computacion Dificil: Cuanto es 0xFF en decimal ? ',0
Q52 BYTE 'Computacion Dificil: Cuantos KB tiene 1 MB ? ',0
Q53 BYTE 'Computacion Dificil: Cuanto es 2^8 ? ',0
Q54 BYTE 'Computacion Dificil: Cuanto es 0xAB en decimal ? ',0
Q55 BYTE 'Computacion Dificil: Cuantos bits tiene 2 bytes ? ',0
Q56 BYTE 'Computacion Dificil: Cuantos MB tiene 1 GB ? ',0
Q57 BYTE 'Computacion Dificil: Cuanto es 0b11111111 en decimal ? ',0
Q58 BYTE 'Computacion Dificil: Cuanto es 0x1A en decimal ? ',0
Q59 BYTE 'Computacion Dificil: Cuanto es 2^10 ? ',0
Q60 BYTE 'Computacion Dificil: Cuanto es 0x100 en decimal ? ',0

; Logica - Facil
Q61 BYTE 'Logica Facil: Cuanto es 1 AND 1 ? ',0
Q62 BYTE 'Logica Facil: Si A=2 y B=3, cuanto es A+B ? ',0
Q63 BYTE 'Logica Facil: Cuanto es 1 OR 0 ? ',0
Q64 BYTE 'Logica Facil: Cuanto es 0 AND 1 ? ',0
Q65 BYTE 'Logica Facil: Cuanto es 1 XOR 0 ? ',0
Q66 BYTE 'Logica Facil: Si A=4 y B=1, cuanto es A+B ? ',0
Q67 BYTE 'Logica Facil: Cuanto es 0 OR 0 ? ',0
Q68 BYTE 'Logica Facil: Cuanto es 1 AND 0 ? ',0
Q69 BYTE 'Logica Facil: Si X=2, cuanto es X+X ? ',0
Q70 BYTE 'Logica Facil: Cuantos estados tiene un bit ? ',0

; Logica - Medio
Q71 BYTE 'Logica Medio: Cuanto es 1 XOR 1 ? ',0
Q72 BYTE 'Logica Medio: Si X=5, cuanto es X*X-X ? ',0
Q73 BYTE 'Logica Medio: Cuantos numeros primos hay entre 1 y 10 ? ',0
Q74 BYTE 'Logica Medio: Cuanto es 0 XOR 1 ? ',0
Q75 BYTE 'Logica Medio: Cuanto es (1 AND 1) OR 0 ? ',0
Q76 BYTE 'Logica Medio: Cuanto es 100 mod 7 ? ',0
Q77 BYTE 'Logica Medio: Si f(x)=x+3, cuanto es f(5) ? ',0
Q78 BYTE 'Logica Medio: Cuantos numeros primos hay entre 1 y 20 ? ',0
Q79 BYTE 'Logica Medio: Si A=3 y B=4, cuanto es A*B ? ',0
Q80 BYTE 'Logica Medio: Cuanto es 10 / 2 ? ',0

; Logica - Dificil
Q81 BYTE 'Logica Dificil: Si f(x)=2x+3, cuanto es f(5) ? ',0
Q82 BYTE 'Logica Dificil: Cuanto es 100 mod 7 ? ',0
Q83 BYTE 'Logica Dificil: Cuantos numeros primos hay entre 1 y 20 ? ',0
Q84 BYTE 'Logica Dificil: Cuanto es (1 XOR 0) AND (1 OR 0) ? ',0
Q85 BYTE 'Logica Dificil: Si A=7 y B=2, cuanto es A*B-A ? ',0
Q86 BYTE 'Logica Dificil: Cuanto es 4^2 ? ',0
Q87 BYTE 'Logica Dificil: Cuanto es 1 XOR 0 ? ',0
Q88 BYTE 'Logica Dificil: Si A=9 y B=3, cuanto es A/B ? ',0
Q89 BYTE 'Logica Dificil: Cuanto es 1 AND (1 XOR 0) ? ',0
Q90 BYTE 'Logica Dificil: Cuanto es (1 OR 0) AND 1 ? ',0

QuestionTable DWORD OFFSET Q1,  OFFSET Q2,  OFFSET Q3,  OFFSET Q4,  OFFSET Q5,  OFFSET Q6,  OFFSET Q7,  OFFSET Q8,  OFFSET Q9,  OFFSET Q10
              DWORD OFFSET Q11, OFFSET Q12, OFFSET Q13, OFFSET Q14, OFFSET Q15, OFFSET Q16, OFFSET Q17, OFFSET Q18, OFFSET Q19, OFFSET Q20
              DWORD OFFSET Q21, OFFSET Q22, OFFSET Q23, OFFSET Q24, OFFSET Q25, OFFSET Q26, OFFSET Q27, OFFSET Q28, OFFSET Q29, OFFSET Q30
              DWORD OFFSET Q31, OFFSET Q32, OFFSET Q33, OFFSET Q34, OFFSET Q35, OFFSET Q36, OFFSET Q37, OFFSET Q38, OFFSET Q39, OFFSET Q40
              DWORD OFFSET Q41, OFFSET Q42, OFFSET Q43, OFFSET Q44, OFFSET Q45, OFFSET Q46, OFFSET Q47, OFFSET Q48, OFFSET Q49, OFFSET Q50
              DWORD OFFSET Q51, OFFSET Q52, OFFSET Q53, OFFSET Q54, OFFSET Q55, OFFSET Q56, OFFSET Q57, OFFSET Q58, OFFSET Q59, OFFSET Q60
              DWORD OFFSET Q61, OFFSET Q62, OFFSET Q63, OFFSET Q64, OFFSET Q65, OFFSET Q66, OFFSET Q67, OFFSET Q68, OFFSET Q69, OFFSET Q70
              DWORD OFFSET Q71, OFFSET Q72, OFFSET Q73, OFFSET Q74, OFFSET Q75, OFFSET Q76, OFFSET Q77, OFFSET Q78, OFFSET Q79, OFFSET Q80
              DWORD OFFSET Q81, OFFSET Q82, OFFSET Q83, OFFSET Q84, OFFSET Q85, OFFSET Q86, OFFSET Q87, OFFSET Q88, OFFSET Q89, OFFSET Q90

AnswerTable DWORD 4,8,6,4,8,7,10,9,7,10
            DWORD 42,9,12,64,42,25,27,32,8,33
            DWORD 91,42,32,12,76,62,90,11,256,91
            DWORD 8,8,2,16,8,4,16,10,15,8
            DWORD 10,16,15,24,11,1024,16,16,8,4096
            DWORD 255,1024,256,171,16,1024,255,26,1024,256
            DWORD 1,5,1,0,1,5,0,0,4,2
            DWORD 0,20,4,1,1,2,8,8,12,5
            DWORD 13,2,8,1,7,16,1,3,1,1

CategoryTable   DWORD 30 DUP(1), 30 DUP(2), 30 DUP(3)
DifficultyTable DWORD 10 DUP(1), 10 DUP(2), 10 DUP(3)
              DWORD 10 DUP(1), 10 DUP(2), 10 DUP(3)
              DWORD 10 DUP(1), 10 DUP(2), 10 DUP(3)

; Runtime state
currentCategory DWORD 1
UsedFlags DWORD 90 DUP(0)
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
    ; tambien verificar categoria y dificultad
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

; RemainingCount: devuelve en EAX la cantidad de preguntas NO usadas para la dificultad actual
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
