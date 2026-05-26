Title NombreDelPrograma   <NombreArchivo.Asm>
;@Author : Ing. Juan José Santos
;@Country: El Salvador, Centro America
;@eMail  : juan.santos@mail.utec.edu.sv

Include Irvine32.Inc

.Data
; Poner aqui las variables a utilizar

.Code
Main Proc
     Call ClrScr   ; Limpia la Pantalla

     ; poner aqui codigo del programa

     Call CrLf     ; Hace un Salto de linea
     Call WaitMsg  ; Espera a que presionen <ENTER>
     Exit          ; Termina el programa
Main EndP

End Main