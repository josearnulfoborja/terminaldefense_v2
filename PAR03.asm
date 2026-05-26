INCLUDE Irvine32.inc

MAX_OPS = 20                        ; maximo de operaciones permitidas

; =====================================================================
; Seccion de datos
; =====================================================================
.data
; ----- Arreglos paralelos e historial --------------------------------
histResultados DWORD MAX_OPS DUP(0) ; arreglo de resultados
histFiguras    DWORD MAX_OPS DUP(0) ; arreglo de IDs de figura (1..6)
contadorOps    DWORD 0              ; operaciones realizadas
savedRet       DWORD 0              ; direccion de retorno de mostrarHistorial

; ----- Variables temporales para figuras con dos o mas datos --------
valBase        DWORD 0
valAltura      DWORD 0
valBaseMayor   DWORD 0

; ----- Mensajes ------------------------------------------------------
tituloApp      BYTE "==== CALCULADORA DE AREAS ====",0Dh,0Ah,0
menuTxt        BYTE 0Dh,0Ah,"0.Ver historial y salir",0Dh,0Ah,
                    "1.Cuadrado",0Dh,0Ah,
                    "2.Rectangulo",0Dh,0Ah,
                    "3.Triangulo",0Dh,0Ah,
                    "4.Trapecio",0Dh,0Ah,
                    "5.Rombo",0Dh,0Ah,
                    "6.Circulo",0Dh,0Ah,
                    "Seleccione una opcion: ",0
msgInvalido    BYTE "Valor invalido. Ingrese un entero positivo: ",0

msgLado        BYTE "[Cuadrado] Ingrese el lado: ",0
msgBaseR       BYTE "[Rectangulo] Ingrese la base: ",0
msgAltR        BYTE "[Rectangulo] Ingrese la altura: ",0
msgBaseT       BYTE "[Triangulo] Ingrese la base : ",0
msgAltT        BYTE "[Triangulo] Ingrese la altura: ",0
msgBMay        BYTE "[Trapecio] Ingrese la base mayor: ",0
msgBMen        BYTE "[Trapecio] Ingrese la base menor: ",0
msgAltTra      BYTE "[Trapecio] Ingrese la altura: ",0
msgDMay        BYTE "[Rombo] Ingrese la diagonal mayor: ",0
msgDMen        BYTE "[Rombo] Ingrese la diagonal menor: ",0
msgRadio       BYTE "[Circulo] Ingrese el radio: ",0

msgAreaCuad    BYTE "Area del cuadrado   : ",0
msgAreaRect    BYTE "Area del rectangulo : ",0
msgAreaTri     BYTE "Area del triangulo  : ",0
msgAreaTra     BYTE "Area del trapecio   : ",0
msgAreaRom     BYTE "Area del rombo      : ",0
msgAreaCir     BYTE "Area del circulo    : ",0

msgGuardado    BYTE "(Resultado guardado en historial)",0Dh,0Ah,0
msgPausa       BYTE 0Dh,0Ah,"Presione una tecla para volver al menu...",0

msgHistHead    BYTE 0Dh,0Ah,"===== HISTORIAL DE CALCULOS =====",0Dh,0Ah,0
msgHistVacio   BYTE "(Historial vacio)",0Dh,0Ah,0
msgHistFin     BYTE "=================================",0Dh,0Ah,0
msgOp          BYTE " Op. ",0
msgSep         BYTE " | ",0
msgArea        BYTE " | Area: ",0

nomCuadrado    BYTE "Cuadrado  ",0
nomRectangulo BYTE "Rectangulo",0
nomTriangulo   BYTE "Triangulo ",0
nomTrapecio    BYTE "Trapecio  ",0
nomRombo       BYTE "Rombo     ",0
nomCirculo     BYTE "Circulo   ",0

; =====================================================================
; Seccion de codigo
; =====================================================================
.code


configurarConsola PROC USES EAX EDX
    call  ClrScr
    mov   eax, white + (blue * 16)
    call  SetTextColor
    call  ClrScr
    mov   edx, OFFSET tituloApp
    call  WriteString
    ret
configurarConsola ENDP


mostrarMenu PROC USES EDX
    mov   edx, OFFSET menuTxt
    call  WriteString
    ret
mostrarMenu ENDP


leerValorPositivo PROC USES EBX EDX
leerOtraVez:
    call  ReadInt                   ; EAX = valor ingresado
    .IF eax > 0                     ; validacion con .IF (no CMP)
        jmp   fin_lvp
    .ENDIF
    mov   edx, OFFSET msgInvalido
    call  WriteString
    jmp   leerOtraVez               ; reintento obligatorio con JMP
fin_lvp:
    ret
leerValorPositivo ENDP


guardarEnHistorial PROC USES ECX EDX ESI
    mov   ecx, eax                  ; ECX = area (temporal)
    ; Calcular desplazamiento en bytes: contadorOps * 4
    mov   eax, contadorOps
    mov   edx, 4
    mul   edx                       ; EAX = contadorOps * 4 (MUL)
    ; (b) histResultados[i] = area  (via ESI indirecto)
    mov   esi, OFFSET histResultados
    add   esi, eax
    mov   [esi], ecx                ; [ESI] indirecto
    ; (b) histFiguras[i] = id       (via ESI indirecto)
    mov   esi, OFFSET histFiguras
    add   esi, eax
    mov   [esi], ebx                ; [ESI] indirecto
    ; (c) contador global con ADD
    add   contadorOps, 1
    mov   eax, ecx                  ; restaurar EAX = area para caller
    ret
guardarEnHistorial ENDP


calcCuadrado PROC USES EBX EDX ESI
    mov   edx, OFFSET msgLado
    call  WriteString
    call  leerValorPositivo         ; EAX = lado
    mov   valBase, eax              ; direccionamiento directo
    mov   eax, valBase
    mul   eax                       ; EAX = lado * lado   (MUL)

    mov   edx, OFFSET msgAreaCuad
    call  WriteString
    call  WriteDec
    call  Crlf

    mov   ebx, 1                    ; id figura = 1 (Cuadrado)
    call  guardarEnHistorial        ; EAX preservada tras el call
    mov   edx, OFFSET msgGuardado
    call  WriteString
    ret                             ; EAX = area para el caller
calcCuadrado ENDP


calcRectangulo PROC USES EBX EDX ESI
    mov   edx, OFFSET msgBaseR
    call  WriteString
    call  leerValorPositivo
    mov   valBase, eax              ; almacenar base

    mov   edx, OFFSET msgAltR
    call  WriteString
    call  leerValorPositivo
    mov   valAltura, eax            ; almacenar altura

    ; Leer base y altura via [ESI] indirecto y multiplicar
    mov   esi, OFFSET valBase
    mov   eax, [esi]                ; [ESI] indirecto -> base
    mov   esi, OFFSET valAltura
    mov   ebx, [esi]                ; [ESI] indirecto -> altura
    mul   ebx                       ; EAX = base * altura  (MUL)

    mov   edx, OFFSET msgAreaRect
    call  WriteString
    call  WriteDec
    call  Crlf

    mov   ebx, 2
    call  guardarEnHistorial
    mov   edx, OFFSET msgGuardado
    call  WriteString
    ret
calcRectangulo ENDP

calcTriangulo PROC USES EBX EDX ESI
    mov   edx, OFFSET msgBaseT
    call  WriteString
    call  leerValorPositivo
    mov   ebx, eax                  ; EBX = base

    mov   edx, OFFSET msgAltT
    call  WriteString
    call  leerValorPositivo         ; EAX = altura
    mul   ebx                       ; EAX = altura * base  (MUL)

    sub   edx, edx                  ; limpiar EDX para DIV sin signo
    mov   ebx, 2
    div   ebx                       ; EAX = EAX / 2        (DIV)

    mov   edx, OFFSET msgAreaTri
    call  WriteString
    call  WriteDec
    call  Crlf

    mov   ebx, 3
    call  guardarEnHistorial
    mov   edx, OFFSET msgGuardado
    call  WriteString
    ret
calcTriangulo ENDP


calcTrapecio PROC USES EBX EDX ESI
    mov   edx, OFFSET msgBMay
    call  WriteString
    call  leerValorPositivo
    mov   valBaseMayor, eax
    mov   ebx, eax                  ; EBX = bMayor

    mov   edx, OFFSET msgBMen
    call  WriteString
    call  leerValorPositivo         ; EAX = bMenor
    add   ebx, eax                  ; EBX = bMayor + bMenor   (ADD)

    mov   edx, OFFSET msgAltTra
    call  WriteString
    call  leerValorPositivo         ; EAX = altura
    mul   ebx                       ; EAX = (suma) * altura   (MUL)

    sub   edx, edx
    mov   ebx, 2
    div   ebx                       ; EAX = EAX / 2           (DIV)

    mov   edx, OFFSET msgAreaTra
    call  WriteString
    call  WriteDec
    call  Crlf

    mov   ebx, 4
    call  guardarEnHistorial
    mov   edx, OFFSET msgGuardado
    call  WriteString
    ret
calcTrapecio ENDP


calcRombo PROC USES EBX EDX ESI
    mov   edx, OFFSET msgDMay
    call  WriteString
    call  leerValorPositivo
    mov   ebx, eax                  ; EBX = dMayor

    mov   edx, OFFSET msgDMen
    call  WriteString
    call  leerValorPositivo         ; EAX = dMenor
    mul   ebx                       ; EAX = dMayor * dMenor   (MUL)

    sub   edx, edx
    mov   ebx, 2
    div   ebx                       ; EAX = EAX / 2           (DIV)

    mov   edx, OFFSET msgAreaRom
    call  WriteString
    call  WriteDec
    call  Crlf

    mov   ebx, 5
    call  guardarEnHistorial
    mov   edx, OFFSET msgGuardado
    call  WriteString
    ret
calcRombo ENDP


calcCirculo PROC USES EBX EDX ESI
    mov   edx, OFFSET msgRadio
    call  WriteString
    call  leerValorPositivo         ; EAX = radio
    mul   eax                       ; EAX = radio * radio     (MUL 1)
    mov   ebx, 314
    mul   ebx                       ; EAX = (r*r) * 314       (MUL 2)
    sub   edx, edx                  ; limpiar EDX para DIV sin signo
    mov   ebx, 100
    div   ebx                       ; EAX = EAX / 100         (DIV)

    mov   edx, OFFSET msgAreaCir
    call  WriteString
    call  WriteDec
    call  Crlf

    mov   ebx, 6
    call  guardarEnHistorial
    mov   edx, OFFSET msgGuardado
    call  WriteString
    ret
calcCirculo ENDP


mostrarHistorial PROC
    pop   savedRet                  ; sacar dir. de retorno para que los
                                    ; POP posteriores recuperen los
                                    ; resultados empujados por main
    mov   edx, OFFSET msgHistHead
    call  WriteString

    mov   ecx, contadorOps
    .IF ecx == 0
        mov   edx, OFFSET msgHistVacio
        call  WriteString
        mov   edx, OFFSET msgHistFin
        call  WriteString
        push  savedRet              ; restaurar dir. de retorno
        ret
    .ENDIF

    ; ESI = direccion del ultimo elemento de histFiguras
    ;       = histFiguras + (contadorOps - 1) * 4
    mov   eax, ecx
    sub   eax, 1                    ; (SUB)
    mov   ebx, 4
    mul   ebx                       ; EAX = (contadorOps - 1) * 4   (MUL)
    mov   esi, OFFSET histFiguras
    add   esi, eax                  ; ESI apunta al ultimo slot

    .WHILE ecx > 0
        ; Encabezado de la fila
        mov   edx, OFFSET msgOp
        call  WriteString
        mov   eax, ecx              ; numero de operacion actual
        call  WriteDec
        mov   edx, OFFSET msgSep
        call  WriteString

        ; Leer id de figura via [ESI] indirecto
        mov   eax, [esi]
        .IF eax == 1
            mov   edx, OFFSET nomCuadrado
        .ELSEIF eax == 2
            mov   edx, OFFSET nomRectangulo
        .ELSEIF eax == 3
            mov   edx, OFFSET nomTriangulo
        .ELSEIF eax == 4
            mov   edx, OFFSET nomTrapecio
        .ELSEIF eax == 5
            mov   edx, OFFSET nomRombo
        .ELSE
            mov   edx, OFFSET nomCirculo
        .ENDIF
        call  WriteString

        mov   edx, OFFSET msgArea
        call  WriteString
        pop   eax                   ; POP del resultado desde la pila
        call  WriteDec
        call  Crlf

        sub   esi, 4                ; retroceder al elemento anterior
        sub   ecx, 1                ; decrementar contador (SUB)
    .ENDW

    mov   edx, OFFSET msgHistFin
    call  WriteString
    push  savedRet                  ; restaurar dir. de retorno
    ret
mostrarHistorial ENDP


main PROC
    call  configurarConsola

menuLoop:                           ; ciclo principal con JMP (sin .WHILE)
    call  mostrarMenu
    call  ReadInt                   ; EAX = opcion seleccionada

    .IF eax == 1
        call  calcCuadrado
        push  eax                   ; (a) PUSH del resultado a la pila
    .ELSEIF eax == 2
        call  calcRectangulo
        push  eax                   ; (a) PUSH del resultado a la pila
    .ELSEIF eax == 3
        call  calcTriangulo
        push  eax                   ; (a) PUSH del resultado a la pila
    .ELSEIF eax == 4
        call  calcTrapecio
        push  eax                   ; (a) PUSH del resultado a la pila
    .ELSEIF eax == 5
        call  calcRombo
        push  eax                   ; (a) PUSH del resultado a la pila
    .ELSEIF eax == 6
        call  calcCirculo
        push  eax                   ; (a) PUSH del resultado a la pila
    .ELSEIF eax == 0
        call  mostrarHistorial
        jmp   finPrograma
    .ENDIF

    ; --- Pausa para que el usuario vea el resultado, luego volver al menu
    mov   edx, OFFSET msgPausa
    call  WriteString
    call  ReadChar                  ; espera una tecla
    call  ClrScr                    ; limpiar pantalla
    mov   edx, OFFSET tituloApp
    call  WriteString               ; reimprimir titulo
    jmp   menuLoop                  ; JMP obligatorio para repetir menu

finPrograma:
    call  WaitMsg
    exit
main ENDP

END main
