; =============================================================================
; The NOSX OS String manipulation library.
; =============================================================================

; ------------------------------------------------------------------
; nx_string_cmp -- See if two strings match
; IN: SI = string one, DI = string two
; OUT: carry set if same, clear if different

nx_string_cmp:
    pusha

.more:
    mov al, [si]        ; Retrieve string contents
    mov bl, [di]

    cmp al, bl          ; Compare characters at current location
    jne .not_same

    cmp al, 0           ; End of first string? Must also be end of second
    je .terminated

    inc si
    inc di
    jmp .more


.not_same:              ; If unequal lengths with same beginning, the byte
    popa                ; comparison fails at shortest string terminator
    clc                 ; Clear carry flag

    ret


.terminated:            ; Both strings terminated at the same position
    popa
    stc                 ; Set carry flag

    ret

; ------------------------------------------------------------------
; nx_int_to_string -- Convert unsigned integer to string
; IN: AX = signed int
; OUT: AX = string location

nx_int_to_string:
    pusha

    mov cx, 0
    mov bx, 10          ; Set BX 10, for division and mod
    mov di, .t          ; Get our pointer ready

.push:
    mov dx, 0
    div bx              ; Remainder in DX, quotient in AX
    inc cx              ; Increase pop loop counter
    push dx             ; Push remainder, so as to reverse order when popping
    test ax, ax         ; Is quotient zero?
    jnz .push           ; If not, loop again
.pop:
    pop dx              ; Pop off values in reverse order, and add 48 to make them digits
    add dl, '0'         ; And save them in the string, increasing the pointer each time
    mov [di], dl
    inc di
    dec cx
    jnz .pop

    mov byte [di], 0    ; Zero-terminate string

    popa
    mov ax, .t          ; Return location of string
    ret


    .t times 7 db 0
