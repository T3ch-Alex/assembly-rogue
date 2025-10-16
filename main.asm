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
MONSTER_NAME        equ 44
MONSTER_NAME_LEN    equ 48
MONSTER_DROP        equ 52
MONSTER_SIZE        equ 56

MAX_ITEMS           equ 10
ITEM                equ 0
ITEM_CHAR           equ 4
ITEM_ATK            equ 8
ITEM_WPN            equ 12
ITEM_KEY            equ 16
ITEM_NAME           equ 20
ITEM_NAME_LEN       equ 24
ITEM_SIZE           equ 28

global _main

section .bss
    num_buffer          resb 1

    monsters            resb MONSTER_SIZE * MAX_MONSTERS
    items               resb MAX_ITEMS * ITEM_SIZE
    inventory           resb 2 * ITEM_SIZE

section .data
    output_handle       dd 0
    input_handle        dd 0
    input_record        times 32 db 0
    events_read         dd 0

    num_divider         dd 10

    map_data            db \
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
    map_length          equ $-map_data        ; Extraimos o tamanho da mensagem
    map_line            equ 100

    player_pos          dd 102
    player_hp           dd 15
    player_atk          dd 1
    player_food         dd 50
    player_gold         dd 0
    player_view         dd 5

    name_snake          db "a Snake!       ", 0
    name_snake_len      equ $-name_snake
    name_goblin         db "a Goblin!      ", 0
    name_goblin_len     equ $-name_goblin

    key                 db "a key!         ", 0
    key_len             equ $-key

    weapon              db "a weapon!      ", 0
    weapon_len          equ $-weapon

    found_msg           db "You found "
    found_msg_len       equ $-found_msg
    killed_msg          db "You killed "
    killed_msg_len      equ $-killed_msg

    line_end            db 13, 10
    line_end_len        equ $-line_end
    line_clean          db "                                                                                "
    line_clean_len      equ $-line_clean
    line_space          db " "
    line_space_len      equ $-line_space

    hud_hp              db "HP:"
    hud_hp_len          equ $-hud_hp
    hud_atk             db " ATK:"
    hud_atk_len         equ $-hud_atk
    hud_food            db " FOOD:"
    hud_food_len        equ $-hud_food
    hud_gold            db " GOLD:"
    hud_gold_len        equ $-hud_gold
    hud_output          db "INFO: "
    hud_output_len      equ $-hud_output

    game_over_msg       db \
    "                                                                                                  ", 13,10, \
    "                                       ------GAME OVER-----                                       ", 13,10, \
    "                                       --------/   )-------                                       ", 13,10, \
    "                                       -------(#  #/-------                                       ", 13,10, \
    "                                       --------||||--------                                       ", 13,10, \
    "                                                                                                  ", 13,10, 13,10, 0
    game_over_msg_len   equ $-game_over_msg

section .text
_main:
    call monsters_init
    call items_init

    push STD_OUT_HANDLE     
    call _GetStdHandle@4    
    mov [output_handle], eax        

    push STD_INPUT_HANDLE
    call _GetStdHandle@4
    mov [input_handle], eax

    .update:
        xor edx, edx
        push edx
        push dword [output_handle]
        call _SetConsoleCursorPosition@8

        cmp dword [player_food], 0
        jle .game_over

        mov esi, map_data       ; Ponteiro para o começo do mapa

    .draw:
        mov al, [esi]    
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

        push line_end_len
        push line_end
        call print_char

        push hud_output_len
        push hud_output
        call print_char

        

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
        call items_search
        pop eax ; restore eax

        push eax ; preserve eax
        push eax
        call monsters_search
        pop eax ; restore eax

        cmp byte [map_data + eax], '.'
        jne .update

        mov byte [map_data + eax + map_line], '.'
        mov byte [map_data + eax], 'o'
        
        mov [player_pos], eax

        dec dword [player_food]

        jmp .update

    .key_down:
        mov eax, [player_pos]
        add eax, map_line

        push eax ; preserve eax
        push eax
        call items_search
        pop eax ; restore eax

        push eax ; preserve eax
        push eax
        call monsters_search
        pop eax ; restore eax

        cmp byte [map_data + eax], '.'
        jne .update

        mov byte [map_data + eax - map_line], '.'
        mov byte [map_data + eax], 'o'

        mov [player_pos], eax

        dec dword [player_food]

        jmp .update

    .key_right:
        mov eax, [player_pos]
        add eax, 1

        push eax ; preserve eax
        push eax
        call items_search
        pop eax ; restore eax

        push eax ; preserve eax
        push eax
        call monsters_search
        pop eax ; restore eax

        cmp byte [map_data + eax], '.'
        jne .update

        mov byte [map_data + eax - 1], '.'
        mov byte [map_data + eax], 'o'

        mov [player_pos], eax

        dec dword [player_food]

        jmp .update

    .key_left:
        mov eax, [player_pos]
        sub eax, 1

        push eax ; preserve eax
        push eax
        call items_search
        pop eax ; restore eax

        push eax ; preserve eax
        push eax
        call monsters_search
        pop eax ; restore eax

        cmp byte [map_data + eax], '.'
        jne .update

        mov byte [map_data + eax + 1], '.'
        mov byte [map_data + eax], 'o'

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
            push line_space
            call print_char

            pop ebp
            ret 4

            .map_view_print_new_line:
                push 2
                push line_end
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
;;;;;;;;;;;;;;;;;;;;;;;;;;; #Items
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

items_init:
    push ebp
    mov ebp, esp

    mov esi, 0

    mov eax, esi
    imul eax, ITEM_SIZE

    mov dword [items + eax + ITEM_ATK], 0
    mov byte [items + eax + ITEM_CHAR], 'f'
    mov dword [items + eax + ITEM_KEY], 1
    mov dword [items + eax + ITEM_WPN], 0
    mov ecx, key
    mov ebx, key_len
    mov [items + eax + MONSTER_NAME], ecx
    mov dword [items + eax + MONSTER_NAME_LEN], ebx

    inc esi

    mov eax, esi
    imul eax, ITEM_SIZE

    mov dword [items + eax + ITEM_ATK], 5
    mov byte [items + eax + ITEM_CHAR], '!'
    mov dword [items + eax + ITEM_KEY], 0
    mov dword [items + eax + ITEM_WPN], 1
    mov ecx, weapon
    mov ebx, weapon_len
    mov [items + eax + MONSTER_NAME], ecx
    mov dword [items + eax + MONSTER_NAME_LEN], ebx

    inc esi

    mov eax, esi
    imul eax, ITEM_SIZE

    mov dword [items + eax + ITEM_ATK], 10
    mov byte [items + eax + ITEM_CHAR], '/'
    mov dword [items + eax + ITEM_KEY], 0
    mov dword [items + eax + ITEM_WPN], 1
    mov ecx, weapon
    mov ebx, weapon_len
    mov [items + eax + MONSTER_NAME], ecx
    mov dword [items + eax + MONSTER_NAME_LEN], ebx

    inc esi

    mov eax, esi
    imul eax, ITEM_SIZE

    mov dword [items + eax + ITEM_ATK], 10
    mov byte [items + eax + ITEM_CHAR], 'i'
    mov dword [items + eax + ITEM_KEY], 0
    mov dword [items + eax + ITEM_WPN], 1
    mov ecx, weapon
    mov ebx, weapon_len
    mov [items + eax + MONSTER_NAME], ecx
    mov dword [items + eax + MONSTER_NAME_LEN], ebx

    pop ebp
    ret

items_search:
    push ebp,
    mov ebp, esp
    mov eax, [ebp + 8]

    push eax            ; save index

    add eax, map_data

    push eax            ; item character in map
    call items_find

    cmp eax, -1         ; item index in items
    jne .items_collect

    pop eax             ; restore index

    pop ebp
    ret 4

    .items_collect:
        cmp dword [items + eax + ITEM_WPN], 1
        je .items_collect_wpn

        cmp dword [items + eax + ITEM_KEY], 1
        je .items_collect_key

        pop ebp
        ret 4
    .items_collect_wpn:
        mov ebx, [items + eax + ITEM_ATK]
        mov dword [inventory + 0 + ITEM_ATK], ebx

        mov al, [items + eax + ITEM_CHAR]
        mov byte [inventory + 0 + ITEM_CHAR], al

        mov ebx, [items + eax + ITEM_KEY]
        mov dword [inventory + 0 + ITEM_KEY], ebx

        mov ebx, [items + eax + ITEM_WPN]
        mov dword [inventory + 0 + ITEM_WPN], ebx

        push found_msg_len
        push found_msg
        call print_char

        push weapon_len
        push weapon
        call print_char

        pop eax
        mov byte [map_data + eax], '.'

        pop ebp
        ret 4

    .items_collect_key:
        mov ebx, [items + eax + ITEM_ATK]
        mov dword [inventory + 1 + ITEM_ATK], ebx

        mov al, [items + eax + ITEM_CHAR]
        mov byte [inventory + 1 + ITEM_CHAR], al

        mov ebx, [items + eax + ITEM_KEY]
        mov dword [inventory + 1 + ITEM_KEY], ebx

        mov ebx, [items + eax + ITEM_WPN]
        mov dword [inventory + 1 + ITEM_WPN], ebx

        push found_msg_len
        push found_msg
        call print_char

        push key_len
        push key
        call print_char

        pop eax
        mov byte [map_data + eax], '.'

        pop ebp
        ret 4


items_find:
    push ebp
    mov ebp, esp
    mov eax, [ebp + 8]

    mov esi, 0

    mov al, byte [eax]

    .items_find_loop:
        cmp esi, MAX_ITEMS
        jge .items_not_found

        mov ebx, esi
        imul ebx, ITEM_SIZE

        mov bl, [items + ebx + ITEM_CHAR]
        cmp bl, al
        je .items_found

        inc esi
        jmp .items_find_loop

    .items_found:
        mov eax, esi
        pop ebp
        ret 4
    .items_not_found:
        mov eax, -1
        pop ebp
        ret 4

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;; #Monsters
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

monsters_init:
    push ebp,
    mov ebp, esp

    mov esi, 0

    mov edi, esi
    imul edi, MONSTER_SIZE

    mov eax, name_snake
    mov ebx, name_snake_len
    mov [monsters + edi + MONSTER_NAME], eax
    mov dword [monsters + edi + MONSTER_NAME_LEN], ebx
    mov byte [monsters + edi + MONSTER_CHAR], '~'
    mov dword [monsters + edi + MONSTER_HP], 4
    mov dword [monsters + edi + MONSTER_ATK], 1
    mov dword [monsters + edi + MONSTER_GOLD], 1
    mov dword [monsters + edi + MONSTER_DEAD], 0
    mov dword [monsters + edi + MONSTER_SPAWNED], 0
    mov dword [monsters + edi + MONSTER_TRIGGER_X], 6
    mov dword [monsters + edi + MONSTER_TRIGGER_Y], 2
    mov dword [monsters + edi + MONSTER_X], 1
    mov dword [monsters + edi + MONSTER_Y], 1

    inc esi
    mov edi, esi
    imul edi, MONSTER_SIZE
    
    mov eax, name_goblin
    mov ebx, name_goblin_len
    mov [monsters + edi + MONSTER_NAME], eax
    mov dword [monsters + edi + MONSTER_NAME_LEN], ebx
    mov byte [monsters + edi + MONSTER_CHAR], 'g'
    mov dword [monsters + edi + MONSTER_HP], 10
    mov dword [monsters + edi + MONSTER_ATK], 1
    mov dword [monsters + edi + MONSTER_GOLD], 1
    mov dword [monsters + edi + MONSTER_DEAD], 0
    mov dword [monsters + edi + MONSTER_SPAWNED], 0
    mov dword [monsters + edi + MONSTER_TRIGGER_X], 18
    mov dword [monsters + edi + MONSTER_TRIGGER_Y], 2
    mov dword [monsters + edi + MONSTER_X], 28
    mov dword [monsters + edi + MONSTER_Y], 2

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

    push edx
    push eax
    call monsters_find

    cmp eax, -1
    jne .monster_fight

    push line_clean_len
    push line_clean
    call print_char

    pop ebp
    ret 4

    .monster_fight:
        push dword [player_atk]
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

    push found_msg_len
    push found_msg
    call print_char

    mov eax, [monsters + esi + MONSTER_NAME]
    mov ebx, [monsters + esi + MONSTER_NAME_LEN]

    push ebx
    push eax
    call print_char

    pop ebp
    ret 4

monsters_take_damage:
    push ebp
    mov ebp, esp
    mov edi, [ebp + 8]
    mov esi, [ebp + 12]

    mov ebx, [player_food]
    sub ebx, 1
    mov dword [player_food], ebx

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

        push killed_msg_len
        push killed_msg
        call print_char

        mov eax, [monsters + edi + MONSTER_NAME]
        mov ebx, [monsters + edi + MONSTER_NAME_LEN]

        push ebx
        push eax
        call print_char

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

strlen:
    push ebp
    mov ebp, esp
    mov esi, [ebp + 8]   ; ponteiro pra string
    xor eax, eax         ; contador = 0
    .strlen_loop:
        cmp byte [esi], 0
        je .strlen_done
        inc esi
        inc eax
        jmp .strlen_loop
    .strlen_done:
        pop ebp
        ret 4