section .data   ; mutable
    board           db 10,"+---+---+---+",10, \
                          "|   |   |   |",10, \
                          "+---+---+---+",10, \
                          "|   |   |   |",10, \
                          "+---+---+---+",10, \
                          "|   |   |   |",10, \
                          "+---+---+---+",10, 0
section .bss    ; mutable pre-nulled 
    input           resb 5 ; row + colon + col + newline + null
    current_player  resb 1 ; bool. false = X, true = O
    is_game_over    resb 1 ; bool. false = in game play, true = !in game play
section .rodata ; immutable
    wining_patterns:
                    db 17, 21, 25,  ; Row 1
                    db 45, 49, 53,  ; Row 2
                    db 73, 77, 81,  ; Row 3

                    db 17, 45, 73,  ; Column 1
                    db 21, 49, 77,  ; Column 2
                    db 25, 53, 81,  ; Column 3

                    db 17, 49, 81,  ; Diagonal 1
                    db 25, 49, 73   ; Diagonal 2
    ;board_position: 
                   ;db 17, 21, 25,
                   ;db 45, 49, 53,
                   ;db 73, 77, 81,    
    board_position  equ wining_patterns
    intro           db "TicTacToe Game Starts Now", 10, 10, 0 
    rules           db "Enter your selected row and colomn by doing <row>:<col>", 10, 0
    read_mode       db "r", 0
    players         db "XO", 0
    colon           db ":", 0
    error_pos       db "The requested position is taken by %c", 10, 0
    row_col_error   db "The requested %s is out of range", 10, 0
    row             db "row",0
    col             db "column",0
    winner_display  db "The winner is %c", 10, 0
    colon_error     db "Must be a : in the middle", 10, 0
    game_over       db "Quiting Game...", 0
    replay_game     db "Would you like to replay: Y or n", 10, 0
section .text
    global  main
    extern  printf
    extern  getchar
; void(void)
rest_board:
    ; board_position | wining_patterns 
    lea     rsi, [rel board_position]
    lea     rdi, [rel board]
    xor     rcx, rcx                     ; i = 0
    
.rest_row:
    mov     rdx, rcx
    lea     rdx, [rdx + rdx*2]           ; rdx = rcx * 3

    movzx   eax, byte [rsi + rdx + 0]    ; a
    movzx   ebx, byte [rsi + rdx + 1]    ; b
    movzx   edx, byte [rsi + rdx + 2]    ; c

    mov     [rdi + rax], byte ' '             ; board[a] = ' ' 
    mov     [rdi + rbx], byte ' '             ; board[b] = ' '
    mov     [rdi + rdx], byte ' ',            ; board[c] = ' '

    inc     rcx
    cmp     rcx, 3
    jl      .rest_row

    xor     rcx, rcx
    ret
; void(void)
switch_turns:
    xor     byte [rel current_player], 1
    ret
; @param [rel current_player]
get_current_player:
    lea     rax, [rel players]
    movzx   rcx, byte [rel current_player]
    mov     al, [rax + rcx]
    ret
; void(int, int, char)
set_board_position:
    ; Calculate linear index: row * 3 + col
    imul    ecx, ecx, 3
    add     ecx, edx
    
    ; Get screen offset for this position
    lea     rax, [rel board_position]
    movzx   ecx, byte [rax + rcx]
    
    ; Get board address and save values
    lea     rax, [rel board]
    mov     r10, rcx           ; Save screen offset
    mov     r11, rax           ; Save board address
    
    ; Check if position is available
    cmp     byte [r11 + r10], ' '
    jne     .position_taken
    
    ; Get current player and place on board
    call    get_current_player
    mov     [r11 + r10], al
    
    xor     rax, rax           ; Return success
    ret

.position_taken:
    ; Display error message
    sub     rsp, 40
    movzx   rdx, byte [r11 + r10]
    lea     rcx, [rel error_pos]
    call    printf
    add     rsp, 40
    
    mov     rax, 1             ; Return error
    ret
; void(void)
check_for_winner:
    ; board_position | wining_patterns 
    lea     rsi, [rel wining_patterns]
    lea     rdi, [rel board]
    xor     rcx, rcx                     ; i = 0
    
.check_pattern:
    mov     rdx, rcx
    lea     rdx, [rdx + rdx*2]           ; rdx = rcx * 3

    movzx   eax, byte [rsi + rdx + 0]    ; a
    movzx   ebx, byte [rsi + rdx + 1]    ; b
    movzx   edx, byte [rsi + rdx + 2]    ; c

    mov     r8b, [rdi + rax]             ; r8b = board[a]
    mov     r9b, [rdi + rbx]             ; r9b = board[b]
    mov     r10b,[rdi + rdx]             ; r10b = board[c]

    ; If board[a] == ' '
    cmp     r8b, ' '
    je      .next_pattern

    ; if board[a] != board[b]
    cmp     r8b, r9b
    jne     .next_pattern

    ; if board[b] != board[c]
    cmp     r9b, r10b
    jne     .next_pattern
    
    mov     byte [rel is_game_over], 1
    mov     al, r8b                      ; Winner
    ret
.next_pattern:
    inc     rcx
    cmp     rcx, 8
    jl      .check_pattern

    ; No winner
    mov     al, ' '
    ret
; Display current player prompt
display_current_player_prompt:
    sub     rsp, 40
    call    get_current_player
    
    mov     [rsp+32], byte '%'
    mov     [rsp+33], byte 'c'
    mov     [rsp+34], byte ':'
    mov     [rsp+35], byte ' '
    mov     [rsp+36], byte 10
    mov     [rsp+37], byte 0
    
    lea     rcx, [rsp+32]
    movzx   edx, al
    call    printf
    add     rsp, 40
    ret
; Display the game board
display_board:
    sub     rsp, 40
    lea     rcx, [rel board]
    call    printf
    add     rsp, 40
    ret

parse_user_input:
    sub     rsp, 40
    
    ; Check if we're in game over state
    cmp     byte [rel is_game_over], 1
    je      .handle_play_again
    
    ; Normal game input handling
    xor     edi, edi                     ; Input index = 0
    lea     rsi, [rel input]             ; Input buffer

.read_char:
    call    getchar
    cmp     al, 10                       ; Newline?
    je      .input_complete
    cmp     edi, 3                       ; Buffer limit
    jge     .discard_excess
    
    mov     [rsi + rdi], al              ; Store character
    inc     edi
    jmp     .read_char

.discard_excess:
    ; Remove remaining characters until newline
    call    getchar
    cmp     al, 10
    jne     .discard_excess
    jmp     .input_complete

.input_complete:
    mov     byte [rsi + rdi], 0          ; Null terminate
    
    ; Check for quit command
    movzx   eax, byte [rel input]
    cmp     eax, 'q'
    je      .quit
    cmp     eax, 'Q'
    je      .quit
    
    ; Check row
    sub     eax, '0'
    cmp     eax, 0
    jl      .invalid_row
    cmp     eax, 2
    jg      .invalid_row
    mov     ecx, eax                     ; Store row
    
    ; Check colon
    movzx   eax, byte [rel input + 1]
    cmp     eax, ':'
    jne     .invalid_colon
    
    ; Check column
    movzx   eax, byte [rel input + 2]
    sub     eax, '0'
    cmp     eax, 0
    jl      .invalid_col
    cmp     eax, 2
    jg      .invalid_col
    mov     edx, eax                     ; Store column
    
    add     rsp, 40
    xor     rax, rax                     ; Return success
    ret

.handle_play_again:
    ; Read single character for Y/N response
    call    getchar
    
    ; Check for restart
    cmp     al, 'Y'
    je      .restart_game
    cmp     al, 'y'
    je      .restart_game
    
    ; Check for quit
    cmp     al, 'N'
    je      .quit_after_game
    cmp     al, 'n'
    je      .quit_after_game
    
    cmp     al, 10                       ; Already newline?
    je      .handle_play_again
    
.discard_until_newline:
    call    getchar
    cmp     al, 10
    jne     .discard_until_newline
    jmp     .handle_play_again

.restart_game:
    ; Remove remaining input until newline
    cmp     al, 10
    je      .restart_confirmed
.discard_restart:
    call    getchar
    cmp     al, 10
    jne     .discard_restart
.restart_confirmed:
    add     rsp, 40
    mov     rax, 3
    ret

.quit_after_game:
    ; Remove remaining input until newline
    cmp     al, 10
    je      .quit_confirmed
.discard_quit:
    call    getchar
    cmp     al, 10
    jne     .discard_quit
.quit_confirmed:
    add     rsp, 40
    mov     rax, 2
    ret

.quit:
    add     rsp, 40
    mov     rax, 2
    ret

.invalid_row:
    lea     rcx, [rel row_col_error]
    lea     rdx, [rel row]
    call    printf
    add     rsp, 40
    mov     rax, 1
    ret

.invalid_colon:
    lea     rcx, [rel colon_error]
    call    printf
    add     rsp, 40
    mov     rax, 1
    ret

.invalid_col:
    lea     rcx, [rel row_col_error]
    lea     rdx, [rel col]
    call    printf
    add     rsp, 40
    mov     rax, 1
    ret

main:
    sub     rsp, 40
.new_game:
    ; Rest/Setup game 
    mov     byte [rel is_game_over], 0
    call    rest_board
    ; Intro
    lea     rcx, [rel intro]
    call    printf

    ; Display board
    call    display_board
    
    ; Display rules
    lea     rcx, [rel rules]
    call    printf
.game_loop:
    ; Show current player
    call    display_current_player_prompt
    
    ; Get and parse user input
    call    parse_user_input
    cmp     rax, 2                       ; Quit
    je      .quit_game
    cmp     rax, 1                       ; Input error
    je      .game_loop
    
    ; Try to make the move
    call    set_board_position
    cmp     rax, 0
    jne     .game_loop
    
    ; Switch to next player
    call    switch_turns
    
    ; Update display
    call    display_board
    
    ; Check for winner
    call    check_for_winner
    cmp     al, ' '                      ; No winner yet?
    je      .game_loop
    
    ; Display winner
    lea     rcx, [rel winner_display]
    movzx   edx, al
    call    printf
.replay_game:
    lea     rcx, [rel replay_game]
    call    printf
    call    parse_user_input
    cmp     rax, 3                       ; Input error?
    je      .new_game
.quit_game:
    lea     rcx, [rel game_over]
    call    printf
    ; fall through to .exit
.exit:
    add     rsp, 40
    xor     rax, rax
    ret
