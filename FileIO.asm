.386
.model flat, stdcall

INCLUDE Irvine32.inc

; PROTOs para Win32 APIs no expuestas por Irvine32/SmallWin
FindFirstFileA   PROTO STDCALL :DWORD, :DWORD
FindNextFileA    PROTO STDCALL :DWORD, :DWORD
FindClose        PROTO STDCALL :DWORD
GetFullPathNameA PROTO STDCALL :DWORD, :DWORD, :DWORD, :DWORD
DeleteFileA      PROTO STDCALL :DWORD

EXTERN playerScore:DWORD
EXTERN playerName:BYTE
;
PUBLIC SaveScore, LoadScore, DeleteSavedPlayer, AppendLog, ListSavedPlayers

.data
    filebuf BYTE 64 DUP(0)
    prefixName BYTE 'scores_',0
    suffixName BYTE '.bin',0
    bytesTransferred DWORD 0
    fileScore DWORD 0
    searchPattern BYTE 'scores_*.bin',0
    findData BYTE 320 DUP(0)
    fullpathBuf BYTE 512 DUP(0)
    logname BYTE 'run.log',0
    logbuf BYTE 512 DUP(0)

.code
; Helper: build filename into filebuf = prefix + playerName + suffix
BuildFilename PROC
    ; copy prefix
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
    ; copy playerName (max 31)
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
    ; copy suffix
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

; SaveScore: escribe playerScore en archivo scores_<playerName>.bin (DWORD binary)
SaveScore PROC
    call BuildFilename
    ; INVOKE CreateFileA, lpFileName, dwDesiredAccess, dwShareMode, lpSecurityAttributes, dwCreationDisposition, dwFlagsAndAttributes, hTemplateFile
    INVOKE CreateFileA, ADDR filebuf, 40000000h, 0, 0, 2, 80h, 0    ; GENERIC_WRITE, CREATE_ALWAYS
    mov ebx, eax                 ; guardar handle
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

; LoadScore: lee 4 bytes desde scores_<playerName>.bin y los coloca en playerScore
LoadScore PROC
    call BuildFilename
    INVOKE CreateFileA, ADDR filebuf, 80000000h, 1, 0, 3, 80h, 0   ; GENERIC_READ, OPEN_EXISTING
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

; ListSavedPlayers: enumera archivos scores_*.bin y muestra nombre + ruta completa
ListSavedPlayers PROC
    mov edx, OFFSET LIST_HEADER
    call WriteString
    ; iniciar busqueda
    INVOKE FindFirstFileA, ADDR searchPattern, ADDR findData
    mov esi, eax
    cmp esi, -1
    je NoFiles
FindLoop:
    ; cFileName at offset 44 in WIN32_FIND_DATAA
    lea edx, [findData + 44]
    call WriteString
    ; obtener ruta completa
    lea edx, [findData + 44]
    INVOKE GetFullPathNameA, edx, 512, ADDR fullpathBuf, 0
    ; fullpath stored in fullpathBuf
    mov edx, OFFSET PATH_LABEL
    call WriteString
    mov edx, OFFSET fullpathBuf
    call WriteString
    ; intentar abrir y leer score (4 bytes)
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
    ; next
    INVOKE FindNextFileA, esi, ADDR findData
    cmp eax, 0
    jne FindLoop
    INVOKE FindClose, esi
    ret
NoFiles:
    mov edx, OFFSET NO_FILES_MSG
    call WriteString
    ret
ListSavedPlayers ENDP

; DeleteSavedPlayer: pide nombre de jugador (usa playerName), construye filename y borra el archivo
DeleteSavedPlayer PROC
    mov edx, OFFSET DEL_PROMPT
    call WriteString
    ; leer nombre en playerName (max 31)
    mov edx, OFFSET playerName
    mov ecx, 31
    call ReadString
    ; construir filename
    call BuildFilename
    ; mostrar filename y pedir confirmacion
    mov edx, OFFSET CONFIRM_LABEL
    call WriteString
    mov edx, OFFSET filebuf
    call WriteString
    mov edx, OFFSET CONFIRM_PROMPT
    call WriteString
    call ReadInt        ; devuelve 1=Si, 0=No en EAX
    cmp eax, 1
    jne DelCanceled
    ; intentar borrar
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

; AppendLog: escribe texto (null-terminated) apuntado por EDX al final de run.log
AppendLog PROC
    ; EDX = pointer a string a escribir (null-terminated)
    INVOKE CreateFileA, ADDR logname, 40000000h, 0, 0, 4, 80h, 0  ; OPEN_ALWAYS
    mov ebx, eax
    cmp ebx, -1
    je LogFail

    ; mover puntero al final
    INVOKE SetFilePointer, ebx, 0, 0, 2    ; FILE_END = 2

    ; calcular longitud de la cadena en EDX
    push esi
    mov esi, edx
    xor ecx, ecx
LenLoop2:
    mov al, [esi+ecx]
    cmp al, 0
    je LenDone2
    inc ecx
    jmp LenLoop2
LenDone2:

    ; escribir
    INVOKE WriteFile, ebx, edx, ecx, ADDR bytesTransferred, 0
    INVOKE CloseHandle, ebx
    pop esi
    ret
LogFail:
    ; no hacemos nada si falla
    ret
AppendLog ENDP

.data
LIST_HEADER BYTE 0Dh,0Ah,'Saved score files:',0Dh,0Ah,0
PATH_LABEL BYTE 'Full path: ',0
NO_FILES_MSG BYTE 'No saved player files found.',0Dh,0Ah,0
SCORE_LABEL BYTE ' Score: ',0
CRLF_MSG BYTE 0Dh,0Ah,0

DEL_PROMPT BYTE 'Ingrese nombre de jugador a borrar: ',0
DEL_OK BYTE 'Archivo eliminado correctamente.',0Dh,0Ah,0
DEL_FAIL BYTE 'No se pudo eliminar (archivo no existe o error).',0Dh,0Ah,0
CONFIRM_LABEL BYTE 'Archivo a borrar: ',0
CONFIRM_PROMPT BYTE 'Confirmar borrado? (1=Si, 0=No): ',0
DEL_CANCEL BYTE 'Operacion cancelada.',0Dh,0Ah,0

.data
SaveFailMsg BYTE "Unable to save score to file.",0Dh,0Ah,0
LoadFailMsg BYTE "No saved score for this player.",0Dh,0Ah,0

END
