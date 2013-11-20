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
; nx_string_length -- Return length of a string
; IN: AX = string location
; OUT AX = length (other regs preserved)

nx_string_length:
    pusha

    mov bx, ax          ; Move location of string to BX

    mov cx, 0           ; Counter

.more:
    cmp byte [bx], 0        ; Zero (end of string) yet?
    je .done
    inc bx              ; If not, keep adding
    inc cx
    jmp .more


.done:
    mov word [.tmp_counter], cx ; Store count before restoring other registers
    popa

    mov ax, [.tmp_counter]      ; Put count back into AX before returning
    ret


    .tmp_counter    dw 0

; ------------------------------------------------------------------
; nx_string_to_int -- Convert decimal string to integer value
; IN: SI = string location (max 5 chars, up to '65536')
; OUT: AX = number

nx_string_to_int:
    pusha

    mov ax, si          ; First, get length of string
    call nx_string_length

    mov bx, 0           ; Don't do anything for empty strings
    cmp ax, 0
    je .finish

    add si, ax          ; Work from rightmost char in string
    dec si

    mov cx, ax          ; Use string length as counter

    mov bx, 0           ; BX will be the final number
    mov ax, 0


    ; As we move left in the string, each char is a bigger multiple. The
    ; right-most character is a multiple of 1, then next (a char to the
    ; left) a multiple of 10, then 100, then 1,000, and the final (and
    ; leftmost char) in a five-char number would be a multiple of 10,000

    mov word [.multiplier], 1   ; Start with multiples of 1

.loop:
    mov ax, 0
    mov byte al, [si]       ; Get character
    sub al, 48          ; Convert from ASCII to real number

    mul word [.multiplier]      ; Multiply by our multiplier

    add bx, ax          ; Add it to BX

    push ax             ; Multiply our multiplier by 10 for next char
    mov word ax, [.multiplier]
    mov dx, 10
    mul dx
    mov word [.multiplier], ax
    pop ax

    dec cx              ; Any more chars?
    cmp cx, 0
    je .finish
    dec si              ; Move back a char in the string
    jmp .loop

.finish:
    mov word [.tmp], bx
    popa
    mov word ax, [.tmp]

    ret


    .multiplier dw 0
    .tmp        dw 0

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

; ------------------------------------------------------------------
; nx_sint_to_string -- Convert signed integer to string
; IN: AX = signed int
; OUT: AX = string location

nx_sint_to_string:
    pusha

    mov cx, 0
    mov bx, 10          ; Set BX 10, for division and mod
    mov di, .t          ; Get our pointer ready

    test ax, ax         ; Find out if X > 0 or not, force a sign
    js .neg             ; If negative...
    jmp .push           ; ...or if positive
.neg:
    neg ax              ; Make AX positive
    mov byte [.t], '-'      ; Add a minus sign to our string
    inc di              ; Update the index
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

    mov byte [di], 0        ; Zero-terminate string

    popa
    mov ax, .t          ; Return location of string
    ret


    .t times 7 db 0