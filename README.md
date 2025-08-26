# Compiler Design 

[cite_start]This project is a three-stage compiler built with **Flex** and **Bison** that translates **MiniC** (a subset of C) into 32-bit x86 assembly code[cite: 252].

## 🚀 Project Stages

### Assignment 1: Syntax Checker
- [cite_start]**Goal**: Used Flex and Bison to create a parser that validates the syntax of a C-like language[cite: 732].
- [cite_start]**Features**: Handled data types (`int`, `char`, `float`, arrays) [cite: 739][cite_start], expressions [cite: 743][cite_start], control flow (`if`, `while`, `for`) [cite: 757, 762][cite_start], and function definitions[cite: 736].
- [cite_start]**Error Handling**: Reported the line number of the first syntax error and exited[cite: 773, 774].

### Assignment 2: Intermediate Code Generation
- [cite_start]**Goal**: Extended the parser to generate **Three-Address Code (TAC)**, an intermediate representation[cite: 5].
- [cite_start]**Features**: Translated expressions, control structures, and function calls into TAC[cite: 5, 22]. [cite_start]Implemented short-circuiting for logical operators [cite: 26] [cite_start]and performed semantic checks for undefined variables[cite: 41].

### Assignment 3: x86 Code Generation
- [cite_start]**Goal**: Translated the TAC into 32-bit x86 assembly (GAS syntax)[cite: 252, 310].
- [cite_start]**MiniC Language**: A simplified C with only `int` and `char[]` types, `if-else` and `while` loops, and no `for` loops or `**` operator[cite: 269, 286, 288].
- [cite_start]**Implementation**: Mapped TAC to x86 instructions, managing a stack frame for local variables and function calls (cdecl convention)[cite: 495, 533, 538]. [cite_start]Global variables are handled in the `.data` and `.bss` sections[cite: 339, 352].

## 🛠️ How to Compile and Run

1.  **Build the Compiler**:
    ```bash
    make
    ```
    This creates two executables:
    - [cite_start]`tac`: Converts MiniC source (`.c`) to TAC[cite: 553].
    - [cite_start]`a.out`: Converts TAC to x86 assembly (`.s`)[cite: 553].

2.  **Generate Assembly Code**:
    ```bash
    # Step 1: Generate Three-Address Code
    ./tac < input.c > intermediate.tac
    
    # Step 2: Generate x86 Assembly
    ./a.out < intermediate.tac > output.s
    ```

3.  **Assemble and Run the Output**:
    ```bash
    # Assemble the .s file using GCC for a 32-bit executable
    gcc -m32 output.s -o executable
    
    # Run the final program
    ./executable
    ```
    [cite_start]*(Note: The commands to assemble and run assume a compatible 32-bit environment) [cite: 597]*
