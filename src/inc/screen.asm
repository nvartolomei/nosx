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
; nx_print_nl -- Displays a new line
; IN: Nothing
; OUT: Nothing (registers preserved)

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
; nx_move_cursor -- Moves cursor in text mode
; IN: DH, DL = row, column; OUT: Nothing (registers preserved)

nx_move_cursor:
    pusha

    mov bh, 0
    mov ah, 2
    int 10h             ; BIOS interrupt to move cursor

    popa
    ret
