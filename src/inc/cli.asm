; =============================================================================
; The NOSX OS Command Line Interpreter.
; =============================================================================

nx_cli:
    ; Clear input buffer
    mov di, cli_input
    mov al, 0
    mov cx, 256
    rep stosb

    ; Show CLI prompt
    mov si, cli_prompt
    call nx_print_string

    ; Read from CLI
    mov ax, cli_input
    call nx_scan_string

    call nx_print_nl

    ; If command is emtpy prompt again
    mov si, cli_input
    cmp byte [si], 0
    je nx_cli

    jmp nx_cli
.done


; =============================================================================
; Strings and variables
; =============================================================================

    cli_prompt  db ' > ', 0

    cli_input   times 256 db 0