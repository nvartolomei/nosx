; =============================================================================
; The NOSX OS Keyboard handling.
; =============================================================================

; ------------------------------------------------------------------
; nx_wait_for_key -- Waits for keypress and returns key
; IN: Nothing; OUT: AX = key pressed, other regs preserved

nx_wait_for_key:
    pusha

    mov ax, 0
    mov ah, 10h         ; BIOS call to wait for key
    int 16h

    mov [.tmp_buf], ax  ; Store resulting keypress

    popa                ; But restore all other regs
    mov ax, [.tmp_buf]
    ret

    .tmp_buf    dw 0
