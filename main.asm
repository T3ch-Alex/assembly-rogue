; stdcalls não precisam de add esp, <qtde de parametros> pois elas ja fazem isso por padrão 
; também, não há necessidade de add esp depois de usar call, se especificar quantos parametros (params * 4 bytes) foram chamados nos ret de cada função
extern _ExitProcess@4   ; Usa-se os decoradores no final indicando quantos parametros essas funções recebe, cada 1 parametro corresponde a 4 bytes
extern _WriteFile@20    ; 5 parametros
extern _GetStdHandle@4  ; 1 parametro
extern _SetConsoleCursorPosition@8
extern _ReadConsoleInputA@16
extern _Sleep@4

STD_OUT_HANDLE      equ -11 ; -11 é basicamente um ID do windows que representa o output no console (stdin)
STD_INPUT_HANDLE    equ -10 ; -10 é o input no console (stdout)
                            ; -12 é erro padrão (stderr)

MAX_MONSTERS        equ 12

MONSTER             equ 0      ; dword (bytes offset 0)
MONSTER_HP          equ 4
MONSTER_ATK         equ 8
MONSTER_GOLD        equ 12
MONSTER_X           equ 16
MONSTER_Y           equ 20
MONSTER_TRIGGER_X   equ 24
MONSTER_TRIGGER_Y   equ 28
MONSTER_DEAD        equ 32
MONSTER_SPAWNED     equ 36
MONSTER_CHAR        equ 40
MONSTER_SIZE        equ 44

global _main

section .bss
    num_buffer resb 1

    monsters resb MONSTER_SIZE * MAX_MONSTERS

section .data
    output_handle dd 0
    input_handle dd 0
    input_record times 32 db 0
    events_read dd 0

    num_divider dd 10

    end_of_line db 13, 10

    map_data db \
    "########                    #####                                                                 ", 13,10, \
    "#......######################...#                                                                 ", 13,10, \
    "#...............................#                                                                 ", 13,10, \
    "#....f.######################...#                                                                 ", 13,10, \
    "########                    #...#                                                                 ", 13,10, \
    "                            ##-##                                                                 ", 13,10, \
    "                                                                                                  ", 13,10, \
    "                                                                                                  ", 13,10, \
    "                                                                                                  ", 13,10, \
    "                                                                                                  ", 13,10, \
    "                                                                                                  ", 13,10, \
    "                                                                                                  ", 13,10, \
    "                                                                                                  ", 13,10, \
    "                                                                                                  ", 13,10, \
    "                                                                                                  ", 13,10, \
    "                                                                                                  ", 13,10, \
    "                                                                                                  ", 13,10, \
    "                                                                                                  ", 13,10, 0
    map_length equ $-map_data        ; Extraimos o tamanho da mensagem
    map_line equ 100
    map_space db " "

    player_pos dd 102
    player_hp dd 15
    player_atk dd 1
    player_food dd 50
    player_gold dd 0
    player_view dd 5

    monster_found db "Found!"
    monster_found_length equ $-monster_found

    monster_nfound db "Not Found!"
    monster_nfound_length equ $-monster_nfound

    hud_hp db "HP:"
    hud_hp_len equ $-hud_hp
    hud_atk db " ATK:"
    hud_atk_len equ $-hud_atk
    hud_food db " FOOD:"
    hud_food_len equ $-hud_food
    hud_gold db " GOLD:"
    hud_gold_len equ $-hud_gold

    game_over_msg db \
    "                                                                                                  ", 13,10, \
    "                                       ------GAME OVER-----                                       ", 13,10, \
    "                                       --------/   )-------                                       ", 13,10, \
    "                                       -------(#  #/-------                                       ", 13,10, \
    "                                       --------||||--------                                       ", 13,10, \
    "                                                                                                  ", 13,10, 13,10, 0
    game_over_msg_len equ $-game_over_msg

section .text
_main:
    call monsters_init

    push STD_OUT_HANDLE     ; Empurramos a constante pra pilha
    call _GetStdHandle@4    ; Chamamos a função
    mov [output_handle], eax            ; Guardamos o resultado temporariamente

    push STD_INPUT_HANDLE
    call _GetStdHandle@4
    mov [input_handle], eax

    .update:
        xor edx, edx
        push edx
        push dword [output_handle]
        call _SetConsoleCursorPosition@8

        cmp dword [player_food], 0
        je .game_over

        mov esi, map_data       ; Ponteiro para o começo do mapa

    .draw:
        mov al, [esi]           ; Valor do caractere atual
        cmp al, 0
        je .draw_hud

        push esi

        push esi
        call map_view

        pop esi  

        inc esi
        jmp .draw

    .draw_hud:
        push hud_hp_len
        push hud_hp                   
        call print_char      

        push dword [player_hp]
        call print_num

        push hud_atk_len
        push hud_atk                   
        call print_char      
        add esp, 8

        push dword [player_atk]
        call print_num

        push hud_food_len
        push hud_food                   
        call print_char      

        push dword [player_food]
        call print_num

        push hud_gold_len
        push hud_gold                   
        call print_char      

        push dword [player_gold]
        call print_num

    .input:
        push events_read
        push 1
        push input_record
        push dword [input_handle]
        call _ReadConsoleInputA@16   

        mov ax, [input_record]        
        cmp ax, 1
        jne .input

        mov eax, [input_record + 4]
        cmp eax, 0
        je .input

        mov ax, [input_record + 10]
        cmp ax, 0x26              ; VK_UP
        je .key_up
        
        cmp ax, 0x28              ; VK_DOWN
        je .key_down

        cmp ax, 0x27              ; VK_RIGHT
        je .key_right

        cmp ax, 0x25              ; VK_LEFT
        je .key_left

        jmp .input

    .key_up:
        mov eax, [player_pos]
        sub eax, map_line

        push eax ; preserve eax
        push eax
        call monsters_search
        pop eax ; restore eax

        cmp byte [map_data + eax], '.'
        jne .update

        mov byte [map_data + eax + map_line], '.'
        mov byte [map_data + eax], '@'
        
        mov [player_pos], eax

        dec dword [player_food]

        jmp .update

    .key_down:
        mov eax, [player_pos]
        add eax, map_line

        push eax ; preserve eax
        push eax
        call monsters_search
        pop eax ; restore eax

        cmp byte [map_data + eax], '.'
        jne .update

        mov byte [map_data + eax - map_line], '.'
        mov byte [map_data + eax], '@'

        mov [player_pos], eax

        dec dword [player_food]

        jmp .update

    .key_right:
        mov eax, [player_pos]
        add eax, 1

        push eax ; preserve eax
        push eax
        call monsters_search
        pop eax ; restore eax

        cmp byte [map_data + eax], '.'
        jne .update

        mov byte [map_data + eax - 1], '.'
        mov byte [map_data + eax], '@'

        mov [player_pos], eax

        dec dword [player_food]

        jmp .update

    .key_left:
        mov eax, [player_pos]
        sub eax, 1

        push eax ; preserve eax
        push eax
        call monsters_search
        pop eax ; restore eax

        cmp byte [map_data + eax], '.'
        jne .update

        mov byte [map_data + eax + 1], '.'
        mov byte [map_data + eax], '@'

        mov [player_pos], eax

        dec dword [player_food]

        jmp .update

    .game_over:
        push 0
        push 0
        push game_over_msg_len
        push game_over_msg
        push dword [output_handle]
        call _WriteFile@20

        push 1
        call _ExitProcess@4

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;; Map
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

map_view:
    push ebp
    mov ebp, esp
    mov eax, [ebp + 8]          ; map index pointer

    push eax                    ; preserve map index pointer
    sub eax, map_data
    push eax                    ; preserve map index

    push eax                    ; current map index
    call map_index_coord        ; edx = X, eax = Y

    mov edi, edx
    mov esi, eax
        
    push dword [player_pos]     ; current player map index
    call map_index_coord        ; edx = X, eax = Y

    mov ebx, edx,
    mov ecx, eax

    .map_view_check_coords:
        sub ebx, edi            ; checking for X
        push ebx
        call absolute_value
        cmp eax, [player_view]  ; if difference > player_view
        jg .map_view_check_g

        sub ecx, esi            ; checking for Y
        push ecx
        call absolute_value
        cmp eax, [player_view]  ; if difference > player_view
        jg .map_view_check_g

        pop eax                 ; restore map index
        pop eax                 ; restore map index pointer

        push 1
        push eax
        call print_char

        pop ebp
        ret 4

        .map_view_check_g:
            pop eax             ; restore map index
            pop eax             ; restore map index pointer

            mov al, [eax]

            cmp al, 13
            je .map_view_print_new_line

            cmp al, 10
            je .map_view_print_line_end

            push 1
            push map_space
            call print_char

            pop ebp
            ret 4

            .map_view_print_new_line:
                push 2
                push end_of_line
                call print_char

                pop ebp
                ret 4
            
            .map_view_print_line_end:
                pop ebp
                ret 4

map_coord_index:
    push ebp
    mov ebp, esp
    mov eax, [ebp + 8]  ; X
    mov ebx, [ebp + 12] ; Y

    imul ebx, map_line  ; Y * map_line
    add eax, ebx        ; (Y * map_line) + X = index

    pop ebp
    ret 8

map_index_coord:
    push ebp
    mov ebp, esp
    mov eax, [ebp + 8]  ; index

    mov edx, 0
    mov ebx, map_line
    idiv ebx

    ; edx = x
    ; eax = y

    pop ebp
    ret 4

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;; Monsters
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

monsters_init:
    push ebp,
    mov ebp, esp

    mov esi, 0

    ; .monsters_init_loop:
    ;     cmp esi, MAX_MONSTERS
    ;     je .monsters_init_done

    imul esi, MONSTER_SIZE

    mov byte [monsters + esi + MONSTER_CHAR], '~'
    mov dword [monsters + esi + MONSTER_HP], 4
    mov dword [monsters + esi + MONSTER_ATK], 1
    mov dword [monsters + esi + MONSTER_GOLD], 1
    mov dword [monsters + esi + MONSTER_DEAD], 0
    mov dword [monsters + esi + MONSTER_SPAWNED], 0
    mov dword [monsters + esi + MONSTER_TRIGGER_X], 6
    mov dword [monsters + esi + MONSTER_TRIGGER_Y], 2
    mov dword [monsters + esi + MONSTER_X], 1
    mov dword [monsters + esi + MONSTER_Y], 1

    inc esi
    imul esi, MONSTER_SIZE
    
    mov byte [monsters + esi + MONSTER_CHAR], 'G'
    mov dword [monsters + esi + MONSTER_HP], 10
    mov dword [monsters + esi + MONSTER_ATK], 1
    mov dword [monsters + esi + MONSTER_GOLD], 1
    mov dword [monsters + esi + MONSTER_DEAD], 0
    mov dword [monsters + esi + MONSTER_SPAWNED], 0
    mov dword [monsters + esi + MONSTER_TRIGGER_X], 18
    mov dword [monsters + esi + MONSTER_TRIGGER_Y], 2
    mov dword [monsters + esi + MONSTER_X], 28
    mov dword [monsters + esi + MONSTER_Y], 2

    ; .monsters_init_done:
    pop ebp
    ret

monsters_search:
    push ebp,
    mov ebp, esp
    mov eax, [ebp + 8]

    push eax
    call map_index_coord

    push eax ;preserve
    push edx ;preserve

    push eax
    push edx
    call monsters_find_trigger

    pop eax ;restore
    pop edx ;restore

    push eax
    push edx
    call monsters_find

    cmp eax, -1
    jne .monster_fight

    pop ebp
    ret 4

    .monster_fight:
        push 5
        push eax
        call monsters_take_damage

        pop ebp
        ret 4

monsters_spawn:
    push ebp
    mov ebp, esp
    mov eax, [ebp + 8]

    imul eax, MONSTER_SIZE
    mov esi, eax

    push dword [monsters + esi + MONSTER_Y]
    push dword [monsters + esi + MONSTER_X]
    call map_coord_index    ; eax = map index
    
    mov dword [monsters + esi + MONSTER_SPAWNED], 1
    mov bl, [monsters + esi + MONSTER_CHAR]
    mov [map_data + eax], bl

    pop ebp
    ret 4

monsters_take_damage:
    push ebp
    mov ebp, esp
    mov edi, [ebp + 8]
    mov esi, [ebp + 12]

    imul edi, MONSTER_SIZE

    mov eax, dword [monsters + edi + MONSTER_HP]
    sub eax, esi
    mov dword [monsters + edi + MONSTER_HP], eax

    cmp eax, 0
    jle .monster_died

    pop ebp
    ret 8

    .monster_died:
        mov dword [monsters + edi + MONSTER_DEAD], 1
        
        push dword [monsters + edi + MONSTER_Y]
        push dword [monsters + edi + MONSTER_X]
        call map_coord_index

        mov byte [map_data + eax], '.'

        pop ebp
        ret 8

monsters_find_trigger:
    push ebp
    mov ebp, esp
    mov eax, [ebp + 8]  ; X
    mov ebx, [ebp + 12] ; Y

    mov ecx, 0

    .monster_find_loop:
        cmp ecx, MAX_MONSTERS
        je .monster_not_found

        mov edx, ecx
        imul edx, MONSTER_SIZE

        mov esi, [monsters + edx + MONSTER_TRIGGER_X]
        cmp eax, esi
        je .monster_x_eq

        inc ecx
        jmp .monster_find_loop
    
    .monster_x_eq:
        mov esi, [monsters + edx + MONSTER_TRIGGER_Y]
        cmp ebx, esi
        je .monster_found

        inc ecx
        jmp .monster_find_loop
    
    .monster_found:
        mov esi, ecx

        imul esi, MONSTER_SIZE
        ; mov eax, [monsters + esi + MONSTER_SPAWNED]
        ; cmp eax, 0
        ; je .monster_not_found

        mov eax, [monsters + esi + MONSTER_DEAD]
        cmp eax, 1
        je .monster_not_found

        push ecx
        push ecx
        call monsters_spawn
        pop ecx

        mov eax, ecx

        pop ebp
        ret 8

    .monster_not_found:
        mov eax, -1

        pop ebp
        ret 8

monsters_find:
    push ebp
    mov ebp, esp
    mov eax, [ebp + 8]  ; X
    mov ebx, [ebp + 12] ; Y

    mov ecx, 0

    .monster_find_loop:
        cmp ecx, MAX_MONSTERS
        je .monster_not_found

        mov edx, ecx
        imul edx, MONSTER_SIZE

        mov esi, [monsters + edx + MONSTER_X]
        cmp eax, esi
        je .monster_x_eq

        inc ecx
        jmp .monster_find_loop
    
    .monster_x_eq:
        mov esi, [monsters + edx + MONSTER_Y]
        cmp ebx, esi
        je .monster_found

        inc ecx
        jmp .monster_find_loop
    
    .monster_found:
        mov esi, ecx

        imul esi, MONSTER_SIZE
        mov eax, [monsters + esi + MONSTER_SPAWNED]
        cmp eax, 0
        je .monster_not_found

        mov eax, [monsters + esi + MONSTER_DEAD]
        cmp eax, 1
        je .monster_not_found

        mov eax, ecx

        pop ebp
        ret 8

    .monster_not_found:
        mov eax, -1

        pop ebp
        ret 8

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;; Utils
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

print_num:
    mov dword [num_divider], 10

    push ebp
    mov ebp, esp
    mov eax, [ebp + 8]

    .print_num_loop:
        mov edx, 0
        div dword [num_divider]

        add edx, 0x30
        push edx

        cmp eax, 0
        jne .print_num_loop

    .print_num_loop2:
        cmp esp, ebp
        je .print_num_done

        pop edx
        mov [num_buffer], edx

        push 1
        push num_buffer
        call print_char

        jmp .print_num_loop2

    .print_num_done:
        pop ebp
        ret 4

print_char:
    push ebp
    mov ebp, esp
    mov eax, [ebp + 8]
    mov edx, [ebp + 12]

    push 0
    push 0
    push edx ; strlen
    push eax ; str
    push dword [output_handle]
    call _WriteFile@20

    pop ebp
    ret 8

absolute_value:
    push ebp
    mov ebp, esp
    mov eax, [ebp + 8]

    cmp eax, 0
    jge .abs_done

    neg eax

    pop ebp
    ret 4

    .abs_done:
        pop ebp
        ret 4