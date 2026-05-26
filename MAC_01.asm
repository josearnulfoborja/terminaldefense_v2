Title NombreDelPrograma   <NombreArchivo.Asm>
;@Author : Ing. Juan José Santos
;@Country: El Salvador, Centro America
;@eMail  : juan.santos@mail.utec.edu.sv

Include Irvine32.Inc  ; <- Inclusion de definiciones de Procedimientos
Include Macros.Inc    ; <- Inclusion de Macros a travez de la directiva INCLUDE

mRegistro Macro nombre:req , edad:req, genero:req
echo Expandiendo Macro
IFIDN <genero>,<masculino>
echo el sr. nombre ha sido registrado
echo ***** mostrar datos ******
echo el nombrre es: nombre

else
echo el genero no especificado en la comparacion
endif
endm
; Poner aqui las definiciones de simbolos o constantes y estructuras

; Definir la macro con los parametros necesarios
; :REQ     para los obligatorios
; :=<val>  para las predefinidas

.data

.code
Main Proc
	 

     ; poner aqui codigo del programa
	 
mwriteIn "Primer llamado a macro"
mRegistro juan,20, masculino



mwriteIn "segundo llamado a macro"
mRegistro pedro,20, masculino	 
	 
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