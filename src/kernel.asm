; =============================================================================
; The NOSX OS Kernel.
; =============================================================================

    BITS 16

    %INCLUDE 'defines.asm'

; ------------------------------------------------------------------
; Kernel entry point, called by loader.

kernel_start:
    ; Set all segments to match where  kernel is loaded
    mov ax, 1000h
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    ; Jump to OS entry point
    jmp start

start:
    call nx_clear_screen

    mov si, k_init_msg
    call nx_print_string

    jmp $

    k_init_msg    db 'NOSX Operating System v', NOSX_VERSION, NL, 0


; ------------------------------------------------------------------
; Includes -- Code to pull into the kernel
; nasm include path must be set to ./src/inc/

    %INCLUDE 'screen.asm'
