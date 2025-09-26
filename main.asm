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
MONSTER_DEAD        equ 24
MONSTER_PAD1        equ 28
MONSTER_SIZE        equ 32

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

    map_data db \
    "########                    #####                                                                 ", 13,10, \
    "#......######################...#                                                                 ", 13,10, \
    "#......|....................|...#                                                                 ", 13,10, \
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

        push 100
        call _Sleep@4

    .draw:
        mov al, [esi]           ; Valor do caractere atual
        cmp al, 0
        je .draw_hud

        ; push 1
        ; push esi
        ; call print_char

        mov eax, esi
        sub eax, map_data   ; eax = index = ponteiro - base
        push eax            ; push index (map_view espera índice)
        call map_view

        ; push esi

        ; push esi
        ; call map_view

        ; pop esi  

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
        call monster_search

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
        call monster_search

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
        call monster_search

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
        call monster_search

        pop eax ; restore eax

        cmp byte [map_data + eax], '.'
        jne .update

        mov byte [map_data + eax + 1], '.'
        mov byte [map_data + eax], '@'

        mov [player_pos], eax

        dec dword [player_food]

        push 0
        call monster_spawn

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

    mov eax, [ebp + 8]      ; eax = index
    mov edi, eax            ; edi = index (vamos usar edi sempre para o index)

    ; pegar o caractere original naquele índice
    mov al, [map_data + edi] ; al = caractere

    ; se for CR (13) ou LF (10) -> imprimir o caractere original (manter quebras)
    cmp al, 13
    je .print_original_char
    cmp al, 10
    je .print_original_char

    ; converter index -> (tile_x, tile_y)
    push edi
    call map_index_coord     ; returns: edx = x, eax = y
    mov ebx, edx             ; ebx = tile_x
    mov ecx, eax             ; ecx = tile_y

    ; converter player_pos -> (player_x, player_y)
    mov eax, [player_pos]
    push eax
    call map_index_coord     ; returns: edx = player_x, eax = player_y
    mov esi, edx             ; esi = player_x
    mov edx, eax             ; edx = player_y

    ; abs(tile_x - player_x) <= player_view ?
    mov eax, ebx             ; eax = tile_x
    sub eax, esi             ; eax = tile_x - player_x
    push eax
    call absolute_value      ; eax = abs diff x
    cmp eax, [player_view]
    jg .print_space

    ; abs(tile_y - player_y) <= player_view ?
    mov eax, ecx             ; eax = tile_y
    sub eax, edx             ; eax = tile_y - player_y
    push eax
    call absolute_value      ; eax = abs diff y
    cmp eax, [player_view]
    jg .print_space

    ; dentro da visão -> imprimir o caractere original
    .print_original_char:
        lea eax, [map_data + edi] ; eax = &map_data[index]
        push 1
        push eax
        call print_char
        pop ebp
        ret 4

    .print_space:
        push 1
        push map_space
        call print_char
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

monster_search:
    push ebp,
    mov ebp, esp
    mov eax, [ebp + 8]

    push eax
    call map_index_coord

    push eax
    push edx
    call monster_find

    cmp eax, -1
    jne .monster_fight

    pop ebp
    ret 4

    .monster_fight:
        push 5
        push eax
        call monster_take_damage

        pop ebp
        ret 4

monster_spawn:
    push ebp
    mov ebp, esp
    mov eax, [ebp + 8]

    imul eax, MONSTER_SIZE
    mov esi, eax
    mov dword [monsters + esi + MONSTER_HP], 10
    mov dword [monsters + esi + MONSTER_ATK], 2
    mov dword [monsters + esi + MONSTER_GOLD], 5
    mov dword [monsters + esi + MONSTER_X], 3
    mov dword [monsters + esi + MONSTER_Y], 2
    mov dword [monsters + esi + MONSTER_DEAD], 0

    push dword [monsters + esi + MONSTER_Y]
    push dword [monsters + esi + MONSTER_X]
    call map_coord_index
    
    mov byte [map_data + eax], 'M'

    pop ebp
    ret 4

monster_take_damage:
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
    

monster_find:
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