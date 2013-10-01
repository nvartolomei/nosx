; =============================================================================
; The NOSX OS String manipulation library.
; =============================================================================

; ------------------------------------------------------------------
; os_string_compare -- See if two strings match
; IN: SI = string one, DI = string two
; OUT: carry set if same, clear if different

nx_string_compare:
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
