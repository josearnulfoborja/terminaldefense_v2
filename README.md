# SecureGame: Terminal Defense

Proyecto de Lenguaje Máquina desarrollado en **ensamblador x86 (MASM)** sobre la
biblioteca **Irvine32**. El programa implementa un juego de preguntas y
respuestas con un módulo de seguridad (autenticación, bloqueo por intentos),
persistencia binaria por jugador y un registro (log) de eventos.

---

## 1. Descripción general

`SecureGame` es una aplicación de consola para Windows de 32 bits que simula la
defensa de una "terminal": antes de poder jugar, el usuario debe autenticarse;
luego elige categoría y dificultad, responde un cuestionario y obtiene un
puntaje que se guarda en disco. Si falla demasiadas veces el acceso queda
bloqueado.

Funcionalidades principales:

- Autenticación con contraseña y límite de intentos (`AuthProc`).
- Menú principal con opciones: jugar, ver puntaje, borrar guardado, salir.
- Banco de 18 preguntas clasificadas por **categoría** y **dificultad**
  (Fácil / Medio / Difícil).
- Selección pseudo-aleatoria de preguntas sin repetición (`PickQuestion` +
  `UsedFlags`).
- Cálculo de puntaje y guardado en archivo binario por jugador
  (`scores_<nombre>.bin`).
- Listado de jugadores guardados con ruta absoluta y puntaje
  (`ListSavedPlayers`).
- Borrado de archivos de puntaje (`DeleteSavedPlayer`) con confirmación.
- Log de eventos en `run.log` (inicio/fin de sesión, autenticación, preguntas,
  respuestas, bloqueos).

---

## 2. Arquitectura del proyecto

Aunque el proyecto se entrega como un **único archivo monolítico**
([Main.asm](Main.asm)) que se ensambla con el script de Irvine
([asm32.bat](asm32.bat)), internamente está organizado en **módulos lógicos**
correspondientes a los archivos `.asm` que se conservan en la carpeta como
referencia de la arquitectura modular del documento técnico:

| Módulo      | Archivo               | Responsabilidad |
|-------------|-----------------------|-----------------|
| Main        | [Main.asm](Main.asm)         | Orquestación, menú principal, ciclo de vida de la sesión. |
| Input       | [Input.asm](Input.asm)       | Lectura, *trim* y validación de entrada por consola. |
| Game        | [Game.asm](Game.asm)         | Motor del juego: flujo de preguntas, puntaje y final de ronda. |
| Security    | [Security.asm](Security.asm) | Autenticación, conteo de intentos y bloqueo. |
| Score       | [Score.asm](Score.asm)       | Administración del puntaje del jugador. |
| FileIO      | [FileIO.asm](FileIO.asm)     | Persistencia binaria, listado, borrado y *append* de logs. |
| Utils       | [Utils.asm](Utils.asm)       | Rutinas auxiliares (`StrLen`, `TrimString`, `AsciiToInt`, `CompareString`). |
| Questions   | [Questions.asm](Questions.asm) | Banco de preguntas, tablas de categoría/dificultad y selección. |

### 2.1. Diagrama de flujo de alto nivel

```
            ┌──────────────┐
            │   MainProc   │
            └──────┬───────┘
                   │
            ClrScr + Welcome
                   │
            AppendLog(SESSION_START)
                   │
            ┌──────▼───────┐
            │   AuthProc   │── fail x3 ─► AUTH_LOCKED ─► exit
            └──────┬───────┘
                   │ OK
            ReadString(playerName)
                   │
            LoadScore (si existe)
                   │
            ┌──────▼───────┐
   ┌────────►   MenuProc   │◄──────────┐
   │        └──┬─────┬─────┴──┬────────┘
   │           │1    │2       │3        │0
   │           │     │        │         ▼
   │           ▼     ▼        ▼      SESSION_END
   │       GameProc ViewScore DeleteSavedPlayer
   │           │     │        │
   └───────────┴─────┴────────┘
```

### 2.2. Convenciones internas

- **Modelo de memoria:** `flat, stdcall`, segmento de pila de 4 KB.
- **Registros de paso de parámetros** (estilo Irvine):
  - `EDX` → puntero a cadena de entrada/salida.
  - `EAX` → valor numérico de retorno (o índice/resultado).
  - `EBX` → respuesta correcta en `PickQuestion`; manejador (`HANDLE`) en
    operaciones de archivo.
  - `ECX` → longitud máxima para `ReadString`, contadores de bucle.
- **APIs Win32 invocadas directamente** (no expuestas por Irvine32/SmallWin):
  `FindFirstFileA`, `FindNextFileA`, `FindClose`, `GetFullPathNameA`,
  `DeleteFileA`. El resto (`CreateFileA`, `ReadFile`, `WriteFile`,
  `SetFilePointer`, `CloseHandle`, `GetTickCount`) se obtienen vía Irvine32.

---

## 3. Estructuras de datos

Definidas en la sección `.data` de [Main.asm](Main.asm):

### 3.1. Banco de preguntas (`Questions`)

- `numQuestions DWORD 18` — cantidad total de preguntas.
- `Q1..Q18 BYTE ...,0` — texto de cada pregunta (cadenas ASCII terminadas
  en 0).
- `QuestionTable DWORD OFFSET Q1, ...` — tabla de punteros a las cadenas.
- `AnswerTable   DWORD 4, 8, 3, ...` — respuesta correcta (entero) en el
  mismo índice.
- `CategoryTable   DWORD 1,1,1,...,2,2,...,3,3,...` — categoría por índice.
- `DifficultyTable DWORD 1,1,1,...,2,2,...,3,3,...` — dificultad por índice.
- `UsedFlags DWORD 18 DUP(0)` — bitmap de preguntas ya usadas en la partida.

El acceso por índice se hace con direccionamiento escalado:
`mov eax, DWORD PTR [tabla + ebx*4]`.

### 3.2. Estado de seguridad (`Security`)

- `attempts DWORD 0` / `maxAttempts DWORD 3` — intentos fallidos en juego.
- `expectedPassword BYTE 'admin123',0` — contraseña esperada.
- `maxAuthTries DWORD 3` — intentos de autenticación.
- `authBuffer BYTE 64 DUP(0)` — buffer de lectura.

### 3.3. Estado de jugador (`Score`)

- `playerName BYTE 32 DUP(0)`
- `playerScore DWORD 0`

### 3.4. Buffers de archivo (`FileIO`)

- `filebuf BYTE 64 DUP(0)` — nombre `scores_<player>.bin` construido en
  `BuildFilename`.
- `searchPattern BYTE 'scores_*.bin',0` y `findData BYTE 320 DUP(0)` —
  estructura `WIN32_FIND_DATAA` (el nombre comienza en *offset* `+44`).
- `fullpathBuf BYTE 512 DUP(0)` — buffer para `GetFullPathNameA`.
- `logname BYTE 'run.log',0` — archivo de log append-only.

---

## 4. Descripción de procedimientos

### 4.1. Utilidades (`Utils`)

| PROC            | Entrada           | Salida             | Descripción |
|-----------------|-------------------|--------------------|-------------|
| `StrLen`        | `EDX` = cadena    | `EAX` = longitud   | Recorre hasta el `0`. |
| `TrimString`    | `EDX` = cadena    | (in-place)         | Recorta espacios, TAB, CR, LF al final. |
| `AsciiToInt`    | `EDX` = cadena    | `EAX` = entero     | Soporta signo `+/-`, omite espacios iniciales. |
| `CompareString` | `EDX`, `ESI`      | `EAX` = 1/0        | Compara dos cadenas terminadas en 0. |
| `ClearScreenProc` / `DelayProc` | — | — | Wrappers sobre Irvine. |

### 4.2. File I/O y logging (`FileIO`)

- `BuildFilename` — concatena `"scores_" + playerName + ".bin"` en `filebuf`.
- `SaveScore` — `CreateFileA` (modo crear/sobreescribir) + `WriteFile` de un
  `DWORD` con `playerScore`.
- `LoadScore` — `CreateFileA` (`OPEN_EXISTING`) + `ReadFile` de 4 bytes a
  `playerScore`. Si falla, muestra `LoadFailMsg`.
- `ListSavedPlayers` — recorre `scores_*.bin` con `FindFirstFileA` /
  `FindNextFileA`, resuelve la ruta absoluta con `GetFullPathNameA` y muestra
  el puntaje leído de cada archivo.
- `DeleteSavedPlayer` — pide nombre, arma el filename, pide confirmación y
  llama `DeleteFileA`.
- `AppendLog` — abre `run.log` con `OPEN_ALWAYS` (`dwCreationDisposition = 4`),
  posiciona el puntero al final (`SetFilePointer ... 2` = `FILE_END`) y
  escribe la cadena apuntada por `EDX`.

> **Nota técnica importante:** Las llamadas `INVOKE` con convención `stdcall`
> destruyen `EAX/ECX/EDX`. Por eso `AppendLog` **guarda el puntero al mensaje
> en la pila antes de cualquier `INVOKE`** y lo recupera con `mov esi, [esp+8]`
> antes de calcular su longitud y pasarlo a `WriteFile`. De lo contrario el
> proceso muere por *access violation*.

### 4.3. Seguridad (`Security`)

- `IncAttempt` — incrementa `attempts` y registra `SECURITY: ATTEMPT_INCREMENT`.
- `CheckBlocked` — `EAX = 1` si `attempts >= maxAttempts`, `0` si no.
- `ResetAttempts` — pone `attempts = 0` (al inicio de cada partida).
- `AuthProc` — bucle de hasta `maxAuthTries` intentos. Lee la contraseña,
  hace `TrimString`, la compara con `expectedPassword` y registra
  `AUTH: SUCCESS`, `AUTH: FAIL` o `AUTH: LOCKED`. Devuelve `EAX = 1` si OK.

### 4.4. Puntaje (`Score`)

- `ScoreProc` — suma 10 puntos a `playerScore`.
- `ViewScore` — imprime el puntaje actual y lista los archivos guardados.

### 4.5. Preguntas (`Questions`)

- `PickQuestion` — usa `GetTickCount % numQuestions` como índice inicial y
  busca linealmente la primera pregunta que (1) coincida con la categoría y
  dificultad actuales y (2) no haya sido usada. Si no encuentra ninguna no
  usada, hace un segundo barrido ignorando `UsedFlags`. Marca la pregunta como
  usada y devuelve `EAX` = puntero al texto y `EBX` = respuesta correcta.
- `ResetUsedFlags` — pone todos los `UsedFlags` a 0.
- `SetCategory` / `SetDifficulty` — asignan la selección y resetean `UsedFlags`.
- `RemainingCount` — cuenta preguntas disponibles (no usadas) para la
  categoría y dificultad actuales.

### 4.6. Entrada (`Input`)

- `InputProc` — limpia `inputBuffer`, llama a `ReadString`, hace `TrimString`
  y valida longitud. Devuelve `EAX = 0` OK, `1` vacía, `2` demasiado larga.
- `MenuProc` — muestra `MENU_TEXT` y lee un entero con `ReadInt`.

### 4.7. Motor del juego (`Game`)

`GameProc` ejecuta una partida completa:

1. Reset: `ResetAttempts`, `playerScore = 0`, `ResetUsedFlags`.
2. Verifica bloqueo (`CheckBlocked`).
3. Pide categoría y dificultad; valida rango `[1..3]` y aplica
   `SetCategory` / `SetDifficulty`. Fuera de rango → fácil/1 con mensaje
   `INVALID_CAT`.
4. `RemainingCount`: si hay muy pocas preguntas, fuerza fácil/1
   (`NOT_ENOUGH`).
5. Define la cantidad de preguntas según dificultad:
   - Fácil → 3, Medio → 4, Difícil → 5.
   - El contador se guarda en `quizCounter` **en memoria**, porque `ECX`
     se destruye en los `call` intermedios.
6. Bucle por pregunta:
   - `PickQuestion` → muestra texto, registra `QUESTION_SHOWN`,
     `USER_ANSWERED`.
   - Lee respuesta con `ReadInt`.
   - Acierto → `ScoreProc` + log `RESULT: CORRECT`.
   - Fallo → `IncAttempt`, log `RESULT: INCORRECT`. Si `CheckBlocked` →
     fin con `MSG_BLOCKED`.
   - Decrementa `quizCounter` y repite.
7. `EndQuiz`: imprime `Puntaje final: X/Y` (donde `Y = preguntas * 10`),
   guarda con `SaveScore` y escribe `CRLF` al log.

### 4.8. Punto de entrada (`Main` / `MainProc`)

- `Main` llama a `MainProc` y termina con `exit`.
- `MainProc`:
  1. `Clrscr` y mensaje de bienvenida.
  2. `AppendLog(SESSION_START)`.
  3. `AuthProc`; si falla → `msgAuthAbort` y `ret`.
  4. Pide `playerName` con `ReadString` + `TrimString`.
  5. Registra `PLAYER: <nombre>` en el log.
  6. `LoadScore` (si existe un guardado previo).
  7. Bucle `MainLoop`:
     - `1` → `GameProc`
     - `2` → `ViewScore`
     - `3` → `DeleteSavedPlayer`
     - `0` → `SESSION_END`, despedida y `ReadChar`.

---

## 5. Formato de archivos

### 5.1. `scores_<player>.bin`

- Binario plano, **4 bytes** = `DWORD` little-endian con el `playerScore`
  final de la última partida guardada para ese jugador.
- Se crea con `CREATE_ALWAYS` (`dwCreationDisposition = 2`), por lo que se
  **sobreescribe** en cada partida.

### 5.2. `run.log`

- Texto plano, modo *append*.
- Eventos registrados (cada uno termina en `CRLF`):
  - `SESSION_START`, `SESSION_END`
  - `PLAYER: <nombre>`
  - `AUTH: SUCCESS | FAIL | LOCKED`
  - `SECURITY: ATTEMPT_INCREMENT`
  - `START_GAME`, `ASK_CATEGORY`, `ASK_DIFFICULTY`
  - `QUESTION_SHOWN` seguido del texto de la pregunta
  - `USER_ANSWERED`
  - `RESULT: CORRECT | INCORRECT | BLOCKED`

---

## 6. Requisitos y entorno

- **Sistema operativo:** Windows (consola).
- **Ensamblador:** MASM 32 bits (incluido en la distribución de Irvine).
- **Biblioteca:** [Irvine32.inc](Irvine32.inc) + `Irvine32.lib` (incluidos en
  la carpeta).
- **Headers adicionales:** [SmallWin.inc](SmallWin.inc),
  [Macros.inc](Macros.inc), [VirtualKeys.inc](VirtualKeys.inc).
- **Linker:** se utiliza el linker referenciado por
  [asm32.bat](asm32.bat) (típicamente `link.exe` de Visual Studio 8 que se
  incluye en la carpeta `Microsoft Visual Studio 8/Vc/Bin`).

---

## 7. Compilación y ejecución

Desde la raíz del proyecto, abrir una consola de Windows en la carpeta y
ejecutar:

```bat
asm32 Main
```

Esto produce `Main.obj` y `Main.exe`. Para correr el juego:

```bat
Main.exe
```

### Credenciales por defecto

- **Contraseña:** `admin123`
- **Intentos de autenticación:** 3
- **Intentos de respuesta antes de bloqueo:** 3

---

## 8. Estructura de archivos relevantes

```
terminaldefense/
├── Main.asm              ← Archivo monolítico que se ensambla
├── asm32.bat             ← Script de compilación (Irvine)
├── make16.bat            ← Script auxiliar para Irvine16
├── Input.asm             ← Módulos de referencia (arquitectura modular
├── Game.asm                 documentada). El build real usa Main.asm)
├── Security.asm
├── Score.asm
├── FileIO.asm
├── Utils.asm
├── Questions.asm
├── Irvine32.inc / .lib   ← Biblioteca Irvine de 32 bits
├── Irvine16.inc / .lib   ← Biblioteca Irvine de 16 bits (no usada por Main)
├── SmallWin.inc          ← PROTOs Win32 (Irvine)
├── Macros.inc            ← Macros de Irvine
├── VirtualKeys.inc
├── run.log               ← Log generado en tiempo de ejecución
└── scores_<player>.bin   ← Puntajes persistidos por jugador
```

---

## 9. Decisiones técnicas destacadas

1. **Monolítico vs. modular.** El documento técnico describe una arquitectura
   modular (un `.asm` por responsabilidad). Para simplificar el ensamblado con
   el script de Irvine se consolidó todo en [Main.asm](Main.asm). Los
   archivos individuales se conservan como documentación viva de la
   separación de responsabilidades.
2. **Preservación de `EDX` antes de `INVOKE`.** Documentado en `AppendLog`
   ([Main.asm](Main.asm#L308)). La convención `stdcall` no preserva
   `EAX/ECX/EDX`, por lo que el puntero al mensaje **debe** guardarse en la
   pila antes de cualquier `INVOKE` y recuperarse con `[esp+offset]`.
3. **Contador del cuestionario en memoria (`quizCounter`).** En `GameProc` el
   contador de preguntas restantes se guarda en memoria en lugar de mantenerse
   en `ECX`, porque los `call` intermedios destruyen el registro.
4. **Pseudo-aleatoriedad ligera.** Se usa `GetTickCount` módulo `numQuestions`
   como semilla inicial para `PickQuestion`. Suficiente para variar el orden
   sin depender de RNG externos.
5. **Filtrado por categoría/dificultad con tablas paralelas.** En lugar de
   estructuras (no triviales en MASM), se usan tres tablas `DWORD` indexadas
   por el mismo índice: `QuestionTable`, `CategoryTable`, `DifficultyTable`.

---

## 10. Limitaciones conocidas

- La contraseña está **hardcodeada** en `expectedPassword` (no apta para uso
  real; es un proyecto académico).
- `scores_<player>.bin` se **sobreescribe** en cada partida; no hay historial.
- La validación de longitud de `playerName` se limita a `ReadString ECX = 31`.
- `run.log` crece de forma indefinida (no hay rotación).
- El bucle "modo demo" depende de que el linker/Irvine32 incluidos en la
  carpeta sean compatibles con el Windows host.
