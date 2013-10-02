; =============================================================================
; The NOSX OS Disk library.
; =============================================================================

; ------------------------------------------------------------------
; Reset floppy
; IN: [boot_device] = boot device; OUT: carry set on error

reset_floppy:
    push ax
    push dx
    mov ax, 0
    mov dl, byte [boot_device]
    stc
    int 13h
    pop dx
    pop ax
    ret

; ------------------------------------------------------------------
; Calculate head, track and sector settings for int 13h
; IN: logical sector in AX, OUT: correct registers for int 13h

l2hts:
    push bx
    push ax

    mov bx, ax          ; Save logical sector

    mov dx, 0           ; First the sector
    div word [SectorsPerTrack]
    add dl, 01h         ; Physical sectors start at 1
    mov cl, dl          ; Sectors belong in CL for int 13h
    mov ax, bx

    mov dx, 0           ; Now calculate the head
    div word [SectorsPerTrack]
    mov dx, 0
    div word [Sides]
    mov dh, dl          ; Head/side
    mov ch, al          ; Track

    pop ax
    pop bx

    ; Set correct device
    mov dl, byte [boot_device]

    ret

    Sides dw 2
    SectorsPerTrack dw 18

    boot_device dw 0