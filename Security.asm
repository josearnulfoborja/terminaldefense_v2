; Security.asm - Validaciones, autenticación y control de intentos
.386
.model flat, stdcall

INCLUDE Irvine32.inc

AppendLog PROTO
CompareString PROTO
TrimString PROTO

PUBLIC IncAttempt, CheckBlocked, SecurityProc, ResetAttempts, AuthProc

.data
    maxAttempts DWORD 3
    attempts    DWORD 0

    ; Credenciales (hardcoded para demo académica)
    expectedPassword BYTE 'admin123',0
    authBuffer       BYTE 64 DUP(0)
    maxAuthTries     DWORD 3

    AUTH_PROMPT      BYTE 0Dh,0Ah,'== Autenticacion requerida ==',0Dh,0Ah,'Ingrese contrasena: ',0
    AUTH_OK_MSG      BYTE 'Acceso concedido.',0Dh,0Ah,0
    AUTH_FAIL_MSG    BYTE 'Contrasena incorrecta.',0Dh,0Ah,0
    AUTH_LOCKED_MSG  BYTE 'Acceso denegado: se agotaron los intentos.',0Dh,0Ah,0
    LOG_AUTH_OK      BYTE 'AUTENTICACION: EXITO',0Dh,0Ah,0
    LOG_AUTH_FAIL    BYTE 'AUTENTICACION: FALLO',0Dh,0Ah,0
    LOG_AUTH_LOCKED  BYTE 'AUTENTICACION: BLOQUEADA',0Dh,0Ah,0
    LOG_BLOCK_INC    BYTE 'SEGURIDAD: INTENTO_INCREMENTADO',0Dh,0Ah,0

.code

; IncAttempt: incrementa contador de intentos, registra incidente y devuelve valor en EAX
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

; CheckBlocked: devuelve EAX=1 si attempts >= maxAttempts, 0 si permitido
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

; ResetAttempts: pone el contador de intentos en 0 (al iniciar nueva partida)
ResetAttempts PROC
    mov DWORD PTR attempts, 0
    ret
ResetAttempts ENDP

; SecurityProc legacy alias (mantener compatibilidad)
SecurityProc PROC
    call CheckBlocked
    ret
SecurityProc ENDP

; AuthProc: autenticación con password fijo y 3 intentos máximos.
;   Salida: EAX = 1 si autenticado, 0 si falló todos los intentos
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
    ; trim CR/LF/espacios
    mov edx, OFFSET authBuffer
    call TrimString
    ; comparar con expectedPassword
    mov edx, OFFSET authBuffer
    mov esi, OFFSET expectedPassword
    call CompareString    ; EAX = 1 si igual
    cmp eax, 1
    je  AuthSuccess
    ; fallo
    mov edx, OFFSET AUTH_FAIL_MSG
    call WriteString
    mov edx, OFFSET LOG_AUTH_FAIL
    call AppendLog
    dec ebx
    cmp ebx, 0
    jg  AuthLoop
    ; agotó intentos
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

END
