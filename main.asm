section .data   ; mutable   
    board           db 10,"+---+---+---+",10, \
                          "|   |   |   |",10, \
                          "+---+---+---+",10, \
                          "|   |   |   |",10, \
                          "+---+---+---+",10, \
                          "|   |   |   |",10, \
                          "+---+---+---+",10, 0
section .rodata ; immutable
    intro           db "TicTacToe Game Starts Now", 10, 10, 0 
    rules           db "Enter your selected row and colomn by doing <row>:<col>", 10, 0
    players         db "XO", 0
    colon           db ":", 0
    error_pos       db "The requested position is taken by %c", 10, 0
    row_col_error   db "The requested %s is out of range", 10, 0
    colon_error     db "Must be a : in the middle", 10, 0
    read_mode       db "r", 0
    row             db "row",0
    col             db "column",0
section .bss    
    input           resb 5 ; row + colon + col + null
    WhoeseTurn      resb 1 ; bool. false = X, true = O
section .text
    global  main
    extern  printf
    extern  _fdopen
    extern  fgets
    extern  strcpy
    extern  exit
    extern  getchar

getPlayer:
    lea     rax, [rel players]
    mov     rdx, [rel WhoeseTurn]
    mov     al, byte [rax + rdx]
    ret     ; AL = 'X' or 'O'

setChar:
    lea     rcx, [rel board + 17] ; rcx = &board[17]
    call    getPlayer

    cmp     byte [rcx + r9], ' '
    jne     .error

    mov     byte [rcx + r9], al
    jmp     .end

.error:
    lea     rcx, [rel error_pos]
    mov     dl, al
    call    printf
    ; fall through to .end

.end:
    xor     rax, rax
    ret


main:
    sub     rsp, 40
    ; intro
    lea     rcx, [rel intro]
    call    printf

    ; draw game board
    lea     rcx, [rel board]
    call    printf
    
    ; how to play
    lea     rcx, [rel rules]
    call    printf

    ; FILE* in rax ← _fdopen(0, "r")
    mov     ecx, 0              ; int fd = 0 (stdin)
    lea     rdx, [rel read_mode]
    call    _fdopen
    mov     rbx, rax
    
.while:
    ; Tell users who is playing
    call    getPlayer
    mov     [rsp+32], byte '%'
    mov     [rsp+33], byte 'c'
    mov     [rsp+34], byte ':'
    mov     [rsp+35], byte ' '
    mov     [rsp+36], byte  10
    mov     [rsp+37], byte  0
    lea     rcx, [rsp+32]
    movzx   edx, al
    call    printf

    xor     edi, edi                 ; index = 0
    lea     rsi, [rel input]         ; rsi = &input

.read_loop:
    call    getchar
    cmp     al, 10                  ; newline?
    je      .done_reading
    cmp     edi, 3
    jge     .discard_rest

    mov     [rsi + rdi], al         ; input[edi] = AL
    inc     edi
    jmp     .read_loop

.discard_rest:
    call    getchar
    cmp     al, 10
    jne     .discard_rest
    jmp     .done_reading

.done_reading:
    mov     byte [rsi + rdi], 0      ; null terminate

    ; Check for colon
    movzx   ecx, byte [rel input + 1]
    cmp     cl, ':'          
    jne     .invalid_colon

    ; Convert row
    movzx   ecx, byte [rel input + 0]
    sub     ecx, '1'
    cmp     ecx, 0
    jl      .invalid_row
    cmp     ecx, 2
    jg      .invalid_row

    ; Convert column
    movzx   edx, byte [rel input + 2]
    sub     edx, '1'
    cmp     edx, 0
    jl      .invalid_col
    cmp     edx, 2
    jg      .invalid_col

    ; Calculate index = row * 3 + col
    imul    r9d,  ecx, 28
    imul    r10d, edx, 4
    add     r9d,  r10d

    ; Calculate where to display
    call setChar

    ; Then print the board
    lea     rcx, [rel board]
    call    printf

    add     rsp, 40
    xor     rax, rax
    ret
.invalid_row:
    lea     rcx, [rel row_col_error]
    lea     rdx, [rel row]
    call    printf
    jmp     .while
.invalid_colon:
    lea     rcx, [rel colon_error]
    call    printf
    jmp     .while
.invalid_col:
    lea     rcx, [rel row_col_error]
    lea     rdx, [rel col]
    call    printf
    jmp     .while
