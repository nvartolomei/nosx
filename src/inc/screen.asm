; =============================================================================
; The NOSX OS
; =============================================================================

%INCLUDE "defines.asm"

; ------------------------------------------------------------------
; nx_print_string -- Displays text
; IN: SI = message location (zero-terminated string)
; OUT: Nothing (registers preserved)

nx_print_string:
    pusha

    mov ah, 0Eh         ; int 10h teletype function

.repeat:
    lodsb               ; Get char from string
    cmp al, 0
    je .done            ; If char is zero, end of string

    int 10h             ; Otherwise, print it
    jmp .repeat         ; And move on to next char

.done:
    popa
    ret

; ------------------------------------------------------------------
; nx_scan_string -- Take string from keyboard entry
; IN/OUT: AX = location of string, other regs preserved
; (Location will contain up to 255 characters, zero-terminated)

nx_scan_string:
    pusha

    mov di, ax          ; DI is where we'll store input (buffer)

.scan:                  ; Main loop
    call nx_wait_for_key

    cmp al, 13
    je .done            ; If Enter key pressed we are done

    cmp al, 8
    je .backspace       ; If backspace pressed

    cmp al, ' '         ; Ignore most non-printing characters
    jb .scan

    cmp al, '~'
    ja .scan

    jmp .accept

.backspace:
    cmp cx, 0
    je .scan

    pusha
    mov ah, 0Eh
    mov al, 8
    int 10h
    mov al, 32
    int 10h
    mov al, 8
    int 10h
    popa

    dec di
    dec cx

    jmp .scan

.accept:
    pusha
    mov ah, 0Eh
    int 10h             ; Print entered character
    popa

    stosb               ; Store input character into buffer
    inc cx
    cmp cx, 254         ; Make sure we still have empty space where to read
    jae .done

    jmp .scan

.done:
    mov ax, 0
    stosb

    popa
    ret

; ------------------------------------------------------------------
; nx_print_string_cbc -- Displays text
; IN: SI = message location (zero-terminated string)
; OUT: Nothing (registers preserved)

nx_print_string_cbc:
    pusha

.repeat:
    lodsb               ; Get char from string
    cmp al, 0
    je .done            ; If char is zero, end of string

    mov ah, 86h         ; int 15h delay function
    xor cx, cx
    mov dx, 0F000h      ; Short delay between characters

    cmp al, 0Dh
    jne .start_delay    ; If last character is new line, set longer delay

    mov cx, 10h

.start_delay:
    int 15h             ; Start delay

    mov ah, 0Eh         ; int 10h teletype function
    int 10h             ; Otherwise, print it
    jmp .repeat         ; And move on to next char

.done:
    popa
    ret

; ------------------------------------------------------------------
; nx_print_nl -- Displays a new line
; IN/OUT: Nothing (registers preserved)

nx_print_nl:
    pusha

    mov ah, 0Eh         ; int 10h teletype function

    mov al, 0Dh
    int 10h
    mov al, 0Ah
    int 10h

    popa
    ret

; ------------------------------------------------------------------
; nx_clear_screen -- Clears the screen to background
; IN/OUT: Nothing (registers preserved)

nx_clear_screen:
    pusha

    mov dx, 0           ; Position cursor at top-left
    call nx_move_cursor

    mov ah, 6           ; Scroll full-screen
    mov al, 0           ; Normal white on black
    mov bh, 7           ;
    mov cx, 0           ; Top-left
    mov dh, 24          ; Bottom-right
    mov dl, 79
    int 10h

    popa
    ret

; ------------------------------------------------------------------
; nx_get_cursor_pos -- Return position of text cursor
; OUT: DH, DL = row, column

nx_get_cursor_pos:
    pusha

    mov bh, 0
    mov ah, 3
    int 10h             ; BIOS interrupt to get cursor position

    mov [.tmp], dx
    popa
    mov dx, [.tmp]
    ret


    .tmp dw 0

; ------------------------------------------------------------------
; nx_move_cursor -- Moves cursor in text mode
; IN: DH, DL = row, column; OUT: Nothing (registers preserved)

nx_move_cursor:
    pusha

    mov bh, 0
    mov ah, 2
    int 10h             ; BIOS interrupt to move cursor

    popa
    ret
