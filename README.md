# 🧠 Assembly Rogue (x86, Windows) - English

A game that resembles "Rogue" written in raw x86 Assembly using NASM and GCC.  

## 🛠️ Requirements

1. **[NASM (Netwide Assembler)]**  
   Download and install the appropriate version for Windows:  
   - win32: https://www.nasm.us/pub/nasm/stable/win32/  
   - win64: https://www.nasm.us/pub/nasm/stable/win64/

2. **MinGW-w64 or MSYS2 with GCC (32-bit support)**
   - You need GCC that can build 32-bit binaries (-m32 flag).
   - On MSYS2, install with:
```cmd
pacman -S mingw-w64-i686-gcc
```
   - On MinGW-w64, make sure you selected the i686 target when installing.

3. **Standard Windows libraries** (`kernel32.lib`, `user32.lib`)  
   - Already included with Windows and linked automatically via GCC flags.

## 📁 Project Structure
assembly-rogue/

├── main.asm ; Your assembly code

├── build.bat ; Script to compile and link

└── README.md ; (this file)


## ▶️ How to Run

1. Open MSYS2 MinGW32 shell (or a terminal with GCC + NASM on PATH).

2. Run the build script:
```cmd
.\build.bat
```

3. Then run the compiled .exe:
```cmd
.\main.exe
```
------------------------------------------------------------------------------------------------------------

# 🧠 Assembly Rogue (x86, Windows) - Portuguese

Um jogo que lembra "Rogue" escrito em Assembly x86, usando NASM e GCC.

## 🛠️ Requisitos

1. **[NASM (Netwide Assembler)]**  
   Baixe e instale a versão para o seu Windows.
   win32: https://www.nasm.us/pub/nasm/stable/win32/
   win64: https://www.nasm.us/pub/nasm/stable/win64/

2. **[MinGW-w64 ou MSYS2 com GCC (32-bit)]**
   - Precisa do GCC que consiga compilar em 32 bits (-m32).
   - No MSYS2, instale com:
```cmd
pacman -S mingw-w64-i686-gcc
```
   - No MinGW-w64, escolha o i686 na instalação.

3. **Bibliotecas padrões do Windows** (`kernel32.lib`, `user32.lib`)
   - Já vêm no sistema, o GCC linka direto com elas.


## 📁 Estrutura do projeto
assembly-rogue/

├── main.asm ; Seu código Assembly

├── build.bat ; Script de build

└── README.md ; (este arquivo)


## ▶️ Como rodar

1. Abra o MSYS2 MinGW32 shell (ou um terminal que tenha NASM + GCC configurados no PATH).

2. Execute o script de build:
```cmd
.\build.bat
```

3. Execute no terminal o .exe:
```cmd
.\main.exe
```