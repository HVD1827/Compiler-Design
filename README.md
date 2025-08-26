# Compiler Design 

This project is a three-stage compiler built with **Flex** and **Bison** that translates **MiniC** (a subset of C) into 32-bit x86 assembly code.

## Stages

### Assignment 1: Syntax Checker
- **Goal**: Used Flex and Bison to create a parser that validates the syntax of a C-like language.
- **Features**: Handled data types (`int`, `char`, `float`, arrays), expressions, control flow (`if`, `while`, `for`), and function definitions.
- **Error Handling**: Reported the line number of the first syntax error and exited.

### Assignment 2: Intermediate Code Generation
- **Goal**: Extended the parser to generate **Three-Address Code (TAC)**, an intermediate representation.
- **Features**: Translated expressions, control structures, and function calls into TAC. Implemented short-circuiting for logical operators and performed semantic checks for undefined variables.

### Assignment 3: x86 Code Generation
- **Goal**: Translated the TAC into 32-bit x86 assembly (GAS syntax).
- **MiniC Language**: A simplified C with only `int` and `char[]` types, `if-else` and `while` loops, and no `for` loops or `**` operator.
- **Implementation**: Mapped TAC to x86 instructions, managing a stack frame for local variables and function calls. Global variables are handled in the `.data` and `.bss` sections.
