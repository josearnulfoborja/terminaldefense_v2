Title NombreDelPrograma   <NombreArchivo.Asm>
;@Author : Jose Borja
;@Country: El Salvador, Centro America
;@eMail  : 2538362015@mail.utec.edu.sv

Include Irvine32.Inc  ; <- Inclusion de definiciones de Procedimientos
Include Macros.Inc    ; <- Inclusion de Macros a travez de la directiva INCLUDE

.data


notas sword 5 dup(0)
reprobArr sword 5 dup(0)

suma sdword 0
promedio sdword 0
mayor sdword 0
menor sdword 100

aprobados dword 0
reprobados dword 0
bonus dword 0
puntajeExtra dword 0

msgError BYTE "Nota invalida, ingrese entre 0 y 100",0
msgSuma BYTE "Suma de nootas: ",0
msgProm BYTE "Promedio: ",0
msgMayor BYTE "Mayor: ",0
msgMenor BYTE "Menor: ",0
msgAprob BYTE "Aprobado: ",0
msgReprob BYTE "Reprobado: ",0
msgBonus BYTE "Bono total por aprobados: ",0
msgFaltan BYTE "le faltan ",0
msgPts BYTE "pts ",0
msgFaltan2 BYTE " puntos para aprobar ",0
msgArrow BYTE "--> ",0
msgTitulo BYTE "== SISTEMA DE NOTAS ==",0
msgPedir BYTE "Ingrese nota: ",0
msgDosp BYTE ": ",0
msgRep BYTE "--  REPORTE ---",0
msgExtra BYTE "Puntaje extra total necesario: ",0
msgAprobC BYTE "Aprobados: ",0
msgReprobC BYTE "Reprobados: ",0

.code
Main Proc
     Call ClrScr  ; Limpia la Pantalla
	 mwritestring msgTitulo
	 call ClrScr
	 call ClrScr
	 
	 call leerNotas
	 call calcularStats
	 call clasificar
	 Call calcularBonus
	 call mostrarReporte
	 call mostrarBonus	 
	 
Salir:
     Call CrLf     ; Hace un Salto de linea
     Call WaitMsg  ; Espera a que presionen <ENTER>
     Exit          ; Termina el programa (Alias de Invoke ExitProcess,0)
Main EndP
	
leerNotas proc uses eax ebx ecx edx esi
	mov ecx , 5 
	lea esi, notas
	mov ebx, 1
LoopNotas:
	mwritestring msgPedir
	mov eax, ebx
	call writedec
	mwritestring msgDosp
	
	call readint
	
	cmp eax, 0
	jl InvalidNota
	cmp eax,100
	jg InvalidNota
	
	mov [esi], eax
	add esi , type notas
	inc ebx
	loop LoopNotas
	jmp EndLeer
	
InvalidNota:
	mwritestring msgError
	call CrLf
	jmp LoopNotas
EndLeer:
ret
leerNotas endp

calcularStats     proc uses eax ebx ecx esi
	mov ecx, 5
	lea esi, notas
	mov suma,0
	mov mayor,0
	mov menor ,100
	
LoopStats:
	mov eax, [esi]
	add suma , eax
	
	cmp eax, mayor
	jle SkipMayor
	mov mayor, eax
SkipMayor:
	cmp eax, menor
	jge SkipMenor
	mov menor, eax
SkipMenor:
	add esi, type notas
	loop LoopStats
	
	mov eax, suma
	cdq
	mov ebx, 5
	idiv ebx
	mov promedio, eax
	ret	
calcularStats EndP


clasificar       proc  uses eax ebx ecx esi
	mov ecx, 5
	lea esi, notas
	lea ebx, reprobArr
LoopClasif:
	mov eax, [esi]
	cmp eax, 60
	jl EsReprob
	inc aprobados
	jmp NextNota
EsReprob:
	INC reprobados
	mov [ebx], eax
	add ebx , type reprobArr
NextNota:
	add esi, type notas
	loop LoopClasif
	ret
clasificar  EndP

calcularBonus    proc  uses eax ebx ecx esi
	mov eax, aprobados
	mov ebx, 5
	mul ebx
	mov bonus, eax
	
	mov puntajeExtra, 0
	mov ecx, reprobados
	jecxz SkipBonus
	lea esi, reprobArr
LoopBonus:
	mov eax, 60
	sub eax, [esi]
	add puntajeExtra, eax
	add esi , type reprobArr
	loop LoopBonus
SkipBonus:
ret
calcularBonus EndP

mostrarReporte   proc  uses eax ebx ecx esi
	call CrLf
	mwritestring msgRep
	Call CrLf
	
	mwritestring msgAprobC
	mov eax, aprobados
	call writedec
	Call CrLf
	
	mwritestring msgReprobC
	mov eax, reprobados
	call writedec
	Call CrLf
	
	mwritestring msgSuma
	mov eax, suma
	call writeint
	call CrLf
	
	mwritestring msgMayor
	mov eax, mayor
	call writeint
	Call CrLf
	
	mwritestring  msgMenor
	mov eax, menor
	call writeint
	call CrLf
	
	mov ecx, 5
	lea esi, notas
LoopRep:
	mov eax, [esi]
	call writeint
	mwritestring msgArrow
	cmp eax, 60
	jl MostrarReprob
	mwritestring msgAprob
	jmp MostrarFin
MostrarReprob:
	mwritestring msgReprob
MostrarFin:
	Call CrLf
	ADD ESI, TYPE notas
	loop LoopRep
	ret
mostrarReporte EndP

mostrarBonus	proc    uses eax ebx ecx esi
	mwritestring msgBonus
	mov eax, bonus
	call writedec
	mwritestring msgPts
	Call CrLf
	
	mwritestring msgExtra
	mov eax , puntajeExtra
	call writedec
	call CrLf

mov ecx , reprobados
jecxz SkipShowBonus
lea esi , reprobArr
LoopShowBonus:
	mov eax, 60
	sub eax, [esi]
	mwritestring msgFaltan
	call writeint
	mwritestring  msgFaltan2
	call CrLf
	add esi, type reprobArr
SkipShowBonus:
ret
mostrarBonus EndP	

End Main