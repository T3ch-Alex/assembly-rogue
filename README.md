# 🧠 Assembly Hello World (x86, Windows) - English

A "Hello, World!" written by hand in raw x86 Assembly using NASM and Visual Studio's linker.  
Because `printf` is for the weak.

I made two versions, one using push instruction and other using only add / sub instructions, to test different types of stack manipulation.

## 🛠️ Requirements

1. **[NASM (Netwide Assembler)]**  
   Download and install the appropriate version for Windows:  
   - win32: https://www.nasm.us/pub/nasm/stable/win32/  
   - win64: https://www.nasm.us/pub/nasm/stable/win64/

2. **Visual Studio with C/C++ Desktop Development Tools**
   - During installation, check the box:  
     `Desktop development with C++`
   - This includes `link.exe` (the linker).
   - Use the pre-configured terminal:
     > Start Menu → "Developer Command Prompt for VS" or "x64 Native Tools Command Prompt"

3. **Standard Windows libraries** (`kernel32.lib`, `user32.lib`)  
   - Already included with Visual Studio.

## 📁 Project Structure
assembly-hello-world-x86/  
├── main.asm ; Your assembly code  
├── build.bat ; Script to compile and link  
└── README.md ; (this file)  


## ▶️ How to Run

1. Open the **Developer Command Prompt for VS**  
   (*not* your regular terminal, unless you want `link.exe` to throw a tantrum).

2. Run the build script:
```cmd
.\build.bat
```

3. Then run the compiled .exe:
```cmd
.\main.exe
```
------------------------------------------------------------------------------------------------------------

# 🧠 Assembly Hello World (x86, Windows) - Portuguese

Um "Hello, World!" escrito na unha usando Assembly x86, NASM e o linker do Visual Studio. Porque printf é para os fracos.

Eu fiz duas versões, uma usando a instrução push e outra usando apenas add / sub, para testar diferentes tipos de manipulação da pilha.

## 🛠️ Requisitos

1. **[NASM (Netwide Assembler)]**  
   Baixe e instale a versão para o seu Windows.
   win32: https://www.nasm.us/pub/nasm/stable/win32/
   win64: https://www.nasm.us/pub/nasm/stable/win64/

2. **Visual Studio com as ferramentas de desenvolvimento C/C++ para Windows Desktop**
   - Durante a instalação do VS, marque:  
     `Desenvolvimento para desktop com C++`
   - O linker (`link.exe`) vem com isso.
   - Acesse o terminal com o ambiente já configurado:
     > Menu Iniciar → "Developer Command Prompt for VS" ou "x64 Native Tools Command Prompt"

3. **Bibliotecas padrões do Windows** (`kernel32.lib`, `user32.lib`)
   - Já vêm com o Visual Studio.


## 📁 Estrutura do projeto
assembly-hello-world-x86/  
├── main.asm ; Your assembly code  
├── build.bat ; Script to compile and link  
└── README.md ; (this file)  


## ▶️ Como rodar

1. Abra o **Developer Command Prompt for VS** (não o terminal comum, senão o `link.exe` vai dar piti).

2. Execute o script de build:
```cmd
.\build.bat
```

3. Execute no terminal o .exe:
```cmd
.\main.exe
```