
matlab_main:
    ; Print help
    mov si, ml_welcome
    call nx_print_string
    call ml_read_data
    jmp matlab_cli

matlab_cli:

    ; Clear input buffer
    mov di, ml_input
    mov al, 0x0000
    mov cx, 0x0100
    rep stosb

    ; Show CLI prompt
    mov si, ml_prompt
    call nx_print_string

    ; Read from CLI
    mov ax, ml_input
    call nx_scan_string

    call nx_print_nl

    ; If command is emtpy prompt again
    mov si, ml_input
    cmp byte [si], 0x0
    je matlab_cli

    ; Check if command is 'EXIT'
    mov di, ml_exit_cmd
    call nx_string_cmp
    jc ml_cmd_exit

    ; Check if command is 'SCAN'
    mov di, ml_scan_cmd
    call nx_string_cmp
    jc ml_cmd_scan

    ; Check if command is 'PRINT'
    mov di, ml_print_cmd
    call nx_string_cmp
    jc ml_cmd_print

    ; Check if command is 'SUM'
    mov di, ml_sum_cmd
    call nx_string_cmp
    jc ml_cmd_sum

    jmp matlab_cli

; ------------------------------------------------------------------
; Code for 'SCAN' command.

ml_cmd_scan:
    ; print help
    mov si, ml_matrix_tpl_help
    call nx_print_string

.choose_slot:
    mov si, ml_choose_slot
    call nx_print_string
    call nx_scan_string
    call nx_print_nl
    mov si, ax
    call nx_string_to_int
    cmp ax, 1
    jb .choose_slot
    cmp ax, 2
    ja .choose_slot

    mov di, ml_memory
    mov bx, 32
    dec ax
    mul bl
    add di, ax

    ; print matrix template
    mov si, ml_matrix_tpl
    call nx_print_string

    mov word [.lines], 0

    call nx_get_cursor_pos
    sub dh, 6
    mov dl, 0

.read_line:
    add dh, 1
    mov dl, 0
    sub dl, 2
    mov word [.per_line], 0

.read_elem:
    add dl, 5
    call nx_move_cursor

    mov ax, .num_buf
    call ml_scan_number           ; read number
    mov si, ax
    call nx_string_to_int         ; convert number from string to int
    stosw

    add word [.per_line], 1

    cmp word [.per_line], 4
    jne .read_elem

    add word [.lines], 1

    cmp word [.lines], 4
    jne .read_line

.done:
    add dh, 2
    mov dl, 0
    call nx_move_cursor
    call ml_save_data
    jmp matlab_cli

    .per_line           dw 0
    .lines              dw 0
    .num_buf            times 10 db 0

; ------------------------------------------------------------------
; Code for 'SUM' command.

ml_cmd_sum:

    ; Copy first buffer to destination first
    mov si, ml_memory
    mov di, ml_memory
    add di, 64
    mov cx, 16

.copy_f_d:
    lodsw
    stosw
    dec cx
    jnz .copy_f_d

    mov cx, 16

    mov word [.source], ml_memory
    add word [.source], 32
    mov word [.dest], ml_memory
    add word [.dest], 64
    mov di, word [.dest]

.sum_s_d:
    mov si, word [.source]
    lodsw
    mov bx, ax          ; Read first number

    mov si, word [.dest]
    lodsw
    add ax, bx          ; Sum with results

    stosw

    add word [.source], 2
    add word [.dest], 2

    dec cx

    jnz .sum_s_d



.finish:
    call ml_save_data
    jmp matlab_cli

    .source dw 0
    .dest   dw 0

; ------------------------------------------------------------------
; Code for 'PRINT' command.

ml_cmd_print:
.choose_slot:
    mov si, ml_choose_slot_ext
    call nx_print_string
    call nx_scan_string
    call nx_print_nl
    mov si, ax
    call nx_string_to_int
    cmp ax, 1
    jb .choose_slot
    cmp ax, 3
    ja .choose_slot
    call ml_print_matrix

    jmp matlab_cli


; ------------------------------------------------------------------
; Code for 'EXIT' command.

ml_cmd_exit:

    jmp nx_cli


; ------------------------------------------------------------------
; ml_save_slot -- Saves data from buffer to a sector to disk
; IN: AX = slot number, BX = buffer offset

ml_save_data:
    pusha

    mov ax, 1
    call l2hts

    mov ax, 0x1000      ; Kernel segment
    mov es, ax
    mov bx, ml_memory       ; Write from temporary buffer to disk

    mov ah, 0x3         ; Write function
    mov al, 0x1         ; Number of sectors to write

    int 13h

    jc .err             ; Error on write

    mov si, ml_slot_write
    call nx_print_string

    jmp .done

.err:
    mov si, ml_slot_write_err
    call nx_print_string

.done:
    popa

    ret

; ------------------------------------------------------------------
; ml_read_slot -- Read data from disk to buffer
; OUT: AX = slot number (int)

ml_read_data:
    pusha

    mov bx, ml_memory

.next:
    mov ax, 1
    call l2hts

    mov ax, 0x1000      ; Kernel segment
    mov es, ax

    mov ah, 0x2         ; Read function
    mov al, 0x1         ; Number of sectors to write

    int 13h

    jc .err             ; Error on write

    mov si, ml_slot_read
    call nx_print_string

    jmp .done

.err:
    mov si, ml_slot_read_err
    call nx_print_string

.done:
    popa
    ret

; ------------------------------------------------------------------
; ml_scan_number -- Take string from keyboard entry
; IN/OUT: AX = location of string, other regs preserved
; (Location will contain up to 255 characters, zero-terminated)

ml_scan_number:
    pusha

    mov di, ax          ; DI is where we'll store input (buffer)

.scan:                  ; Main loop
    call nx_wait_for_key

    cmp al, 13
    je .done            ; If Enter key pressed we are done

    cmp al, '0'         ; Ignore most non-printing characters
    jb .scan

    cmp al, '9'
    ja .scan

    jmp .accept

.accept:
    pusha
    mov ah, 0Eh
    int 10h             ; Print entered character
    popa

    stosb               ; Store input character into buffer
    inc cx
    cmp cx, 2         ; Make sure we still have empty space where to read
    jae .done

    jmp .scan

.done:
    mov ax, 0
    stosb

    popa
    ret

; --------------------------------------------------------------------
; Print matrix
; IN: AX = slot number
ml_print_matrix:
    pusha
    mov si, ml_matrix_tpl
    call nx_print_string

    mov si, ml_memory
    mov bx, 32
    dec ax
    mul bl
    add si, ax

.next:
    mov word [.per_line], 0
    mov word [.lines],    0
    call nx_get_cursor_pos
    sub dh, 6
    call nx_move_cursor

.print_line:
    add dh, 1
    mov dl, 0
    sub dl, 2
    call nx_move_cursor
    add word [.lines], 1
    mov word [.per_line], 0

.print_el:
    add dl, 5
    call nx_move_cursor

    ; Printing characters (actually numbers)
    xor ax, ax
    lodsw
    call nx_sint_to_string

    pusha
    mov si, ax
    call nx_print_string
    popa

    add word [.per_line], 1

    cmp word [.per_line], 4
    jne .print_el

    cmp word [.lines], 4
    jne .print_line

.done:
    add dh, 2
    mov dl, 0
    call nx_move_cursor

    popa
    ret

    .per_line           dw 0
    .lines              dw 0

; =============================================================================
; Strings and variables
; =============================================================================

    ml_prompt           db ' ML > ', 0
    ml_input            times 256 db 0

    ml_welcome          db 'Welcome to NOSX Matrix Laboratory.', NL, NL, \
                           'Have fun!', NL, NL, 0

    ml_scan_cmd         db 'scan', 0  ; scan data to a slot
    ml_clear_cmd        db 'clear', 0 ; used for clearing a slot

    ml_print_cmd        db 'print', 0

    ml_sum_cmd          db 'sum', 0

    ml_choose_slot      db 'Choose slot [1/2]: ', 0
    ml_choose_slot_ext  db 'Choose slot [1/2/3]: ', 0

    ml_slot_write       db 'Data flushed to disk!', NL, 0
    ml_slot_write_err   db 'Error writing data!', NL, 0

    ml_slot_read        db 'Data read succesful!', NL, 0
    ml_slot_read_err    db 'Error reading data!', NL, 0

    ml_exit_cmd         db 'exit', 0  ; return back to kernel cli

    ml_matrix_tpl_help  db 'Insert 4x4 matrix data between -99 and +99', NL, \
                           'Empty cells are considered to be equal to 0.', NL, 0

    ml_matrix_tpl       db 0xC9, 0xCD, '                    ', 0xCD, 0xBB, NL, \
                           0xBA, '                      ', 0xBA, NL, \
                           0xBA, '                      ', 0xBA, NL, \
                           0xBA, '                      ', 0xBA, NL, \
                           0xBA, '                      ', 0xBA, NL, \
                           0xC8, 0xCD, '                    ', 0xCD, 0xBC, NL, \
                           0

    ml_memory           times 256 dw 0
