Title NombreDelPrograma   <NombreArchivo.Asm>
;@Author : Ing. Juan José Santos
;@Country: El Salvador, Centro America
;@eMail  : juan.santos@mail.utec.edu.sv

Include Irvine32.Inc  ; <- Inclusion de definiciones de Procedimientos
Include Macros.Inc    ; <- Inclusion de Macros a travez de la directiva INCLUDE

; Poner aqui las definiciones de simbolos o constantes y estructuras

; Definir la macro con los parametros necesarios
; :REQ     para los obligatorios
; :=<val>  para las predefinidas

.data

.code
Main Proc
     Call ClrScr  ; Limpia la Pantalla
	 Mov EAX, 0   ; Inicializar los registros a CERO
	 Mov EBX, 0   ; Inicializar los registros a CERO
	 Mov ECX, 0   ; Inicializar los registros a CERO
	 Mov EDX, 0   ; Inicializar los registros a CERO

     ; poner aqui codigo del programa
	 
	 
Salir:
     Call CrLf     ; Hace un Salto de linea
     Call WaitMsg  ; Espera a que presionen <ENTER>
     Exit          ; Termina el programa (Alias de Invoke ExitProcess,0)
Main EndP

;Aqui pueden ir mas procedimientos
;<Nombre> Proc USES Reg32/16/8
;	Ret
;<Nombre> EndP

End Main