@echo off
COLOR 1F
REM make16.bat
REM Created 06/01/2006
REM By: Kip R. Irvine

REM Assembles and links the current 16-bit ASM program.
REM Assumes you have installed Microsoft Visual Studio 2005,
REM or Visual C++ 2005 Express.
REM 
REM Command-line options (unless otherwise noted, they are case-sensitive):
REM 
REM -Cp         Enforce case-sensitivity for all identifiers
REM -Zi		Include source code line information for debugging
REM -Fl		Generate a listing file (see page 88)
REM /CODEVIEW   Generate CodeView debugging information (linker)
REM %1.asm      The name of the source file, passed on the command line
rem
rem  Update History: 
rem  -------------------------------------------------------------------
rem  25/06/2010: revised to display help if no arguments are given       
rem  25/06/2010: Make portable for fun, by Carlos Vásquez Espino
rem              run in any media (usb, cd, dvd), make you sure to unrar
rem              directly to "\Irvine" directory.
rem  --------------------------------------------------------------------
rem   El Salvador, Centro America
rem   13/09/2016: Make portable this section, by Carlos Vásquez Espino
rem               run in any media (usb, cd, dvd), in any directory.
rem  --------------------------------------------------------------------

rem -------------------- BEGIN ACTIVE COMMANDS -----------------------

rem The SETLOCAL command makes all subsequent settings of environment 
rem settings local to this batch file. The settings will disappear when 
rem the batch file reaches the ENDLOCAL command.
SETLOCAL

rem Check for the /H (help) command
 
if "%1"=="" goto HELP
if %1==/H   goto HELP
if %1==/h   goto HELP
if %1==-H   goto HELP
if %1==-h   goto HELP

rem -----------------------------------------------------------------
rem      Ubica la ruta desde donde se esta ejecutando el batch
rem         By: Carlos Edgardo Vásquez Espino, El Salvador   
rem -----------------------------------------------------------------
SET DRIVE=#
IF EXIST "%cd%\Irvine16.inc" SET DRIVE=%cd%
SET DRIVE=%cd%
If "%DRIVE%"=="#" goto WARNING

REM ************* The following lines can be customized:
SET MASM=%DRIVE%\Microsoft Visual Studio 8\VC\bin\
SET INCLUDE=%DRIVE%
SET LIB=%DRIVE%
REM **************************** End of customized lines

REM Invoke ML.EXE (the assembler):

"%MASM%"ML /nologo -c -omf -Fl -Zi %1.asm
if errorlevel 1 goto terminate

REM Run the 16-bit linker, modified for Visual Studio.Net:
%DRIVE%\LINK16 %1,,NUL,Irvine16 /CODEVIEW;

if errorlevel 1 goto terminate

REM Display all files related to this program:
DIR %1.exe
goto terminate


rem -----------------------------------------------------------------
rem                    SHOW HELP INFORMATION
rem -----------------------------------------------------------------
:HELP
cls
echo This file assembles, links, and debugs a single assembly language 
echo source file. Before using it, install Visual Studio 2005 in the following 
echo directory: C:\Program Files\Microsoft Visual Studio 8
echo.
echo Next, install the Irvine 5th edition link libraires and include files 
echo in the following directory: C:\Irvine
echo.
echo Finally, copy this batch file to a location on your system path. We recommend 
echo the following directory: C:\Program Files\Microsoft Visual Studio 8\VC\bin
echo.
echo Assembles and links the current 16-bit ASM program.
echo Assumes you have installed Microsoft Visual Studio 2005,
echo or Visual C++ 2005 Express.
echo. 
echo Command-line options (unless otherwise noted, they are case-sensitive):
echo. 
echo    make16 [/H ^| /h ^| -H ^| -h]  -- display this help information
echo    make16 -Cp                  -- Enforce case-sensitivity for all identifiers
echo    make16 -Zi                  -- Include source code line information for debugging
echo    make16 -Fl                  -- Generate a listing file (see page 88)
echo    make16 /CODEVIEW            -- Generate CodeView debugging information (linker)
echo    make16 filelist             -- The name of the source file, passed on the command line
echo.
echo ^<filelist^> is a filename (without extensions), 
echo The filenames are assumed to refer to files having .asm extensions.
echo Command-line switches are case-sensitive.
goto terminate

rem -----------------------------------------------------------------
rem                    SHOW WARNING INFORMATION
rem -----------------------------------------------------------------
:WARNING
COLOR 4F
cls
echo.
echo Debe copiar el Irvine completo dentro de "<UNIDAD>:\<DIRECTORIO>\" 
echo Antes de poder usarlo.
echo.
echo Esta version se puede descomprimir en cualquier unidad y en 
echo cualquier directorio.
echo.
echo AVISO: La ruta maxima no debe exceder mas de 255 caracteres.
echo.
echo.
echo You must copy this into "<DRIVE>:\<DIRECTORY>\" directory
echo Before using it.
echo.
echo.
echo Unrar directly to any directory.
echo.
echo.

goto terminate

:terminate

rem ENDLOCAL clears all local environment variable settings.
ENDLOCAL

Rem Eliminar Archivos Temporales de Compilacion
If Exist %1.lst Del %1.lst
If Exist %1.obj Del %1.obj

If Not Exist %1.exe Pause
COLOR 0A
