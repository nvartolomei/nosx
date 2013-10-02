; =============================================================================
; The NOSX OS Command Line Interpreter.
; =============================================================================

; Available functionality:
;   * Authentification                      LOGIN/LOGOUT
;   * Date                                  DATE
;   * Time                                  TIME
;   * SYS/CPU Info                          SYSINFO
;   * Exiting to bootloader                 EXIT
;   * Restart                               RESTART
;   * Destroy everything                    DESTROY
;   * Beep a sound                          BEEP

; ------------------------------------------------------------------
; Main Command Line Interpreter loop.

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

    ; Check if current command is 'EXIT'
    mov di, exit_cmd
    call nx_string_cmp
    jc command_exit

    ; Check if current command is 'HELP'
    mov di, help_cmd
    call nx_string_cmp
    jc command_help

    ; Check if current command is 'LOGIN'
    mov di, login_cmd
    call nx_string_cmp
    jc cli_log_in

    ; Check if current commnand is 'CLS'
    mov di, cls_cmd
    call nx_string_cmp
    jc command_cls

    ; Check if user is logged in
;    cmp byte [user_logged_in], 1
;    je .authorized
;
;    mov si, cli_auth_err
;    call nx_print_string
;    jmp nx_cli

.authorized:
    ; Check if current command is 'LOGOUT'
    mov di, logout_cmd
    call nx_string_cmp
    jc cli_log_out

    ; Check if current command is 'TIME'
    mov di, time_cmd
    call nx_string_cmp
    jc command_time

    ; Check if current command is 'DATE'
    mov di, date_cmd
    call nx_string_cmp
    jc command_date

    ; Check if current command is 'BEEP'
    mov di, beep_cmd
    call nx_string_cmp
    jc command_beep

    ; Check if current command is 'SYSINFO'
    mov di, sysinfo_cmd
    call nx_string_cmp
    jc command_sysinfo

    ; Check if current command is 'RESTART'
    mov di, restart_cmd
    call nx_string_cmp
    jc command_restart

    ; Check if current command is 'DESTROY'
    mov di, destroy_cmd
    call nx_string_cmp
    jc command_destroy

    ; No command matched
    mov si, cli_invalid_cmd
    call nx_print_string
    jmp nx_cli

; ------------------------------------------------------------------
; Code for 'TIME' command.

command_time:
    ; Get time from BIOS using 1Ah interrupt call
    mov ah, 2h
    int 1Ah

    ; Get Hours and store to string
    mov di, .time_str
    mov al, ch
    shr al, 4
    add al, '0'
    stosb

    mov al, ch
    and al, 0Fh
    add al, '0'
    stosb

    ; Skip delimiter
    add di, 1

    ; Get minutes
    mov al, cl
    shr al, 4
    add al, '0'
    stosb

    mov al, cl
    and al, 0Fh
    add al, '0'
    stosb

    ; Display time
    mov si, .time_str
    call nx_print_string

    call nx_print_nl

    jmp nx_cli

    .time_str db 'HH:MM', 0

; ------------------------------------------------------------------
; Code for 'DATE' command.

command_date:
    ; Get time from BIOS using 1Ah interrupt call
    mov ah, 4h
    int 1Ah

    ; Store day number to string
    mov di, .date_str
    mov al, dl
    shr al, 4
    add al, '0'
    stosb

    mov al, dl
    and al, 0Fh
    add al, '0'
    stosb

    add di, 1

    ; Store month number
    mov al, dh
    shr al, 4
    add al, '0'
    stosb

    mov al, dh
    and al, 0Fh
    add al, '0'
    stosb

    add di, 1

    ; Store year
    mov al, ch
    shr al, 4
    add al, '0'
    stosb

    mov al, ch
    and al, 0Fh
    add al, '0'
    stosb

    mov al, cl
    shr al, 4
    add al, '0'
    stosb

    mov al, cl
    and al, 0Fh
    add al, '0'
    stosb


    add di, 1

    ; Display time
    mov si, .date_str
    call nx_print_string

    call nx_print_nl

    jmp nx_cli

    .date_str db 'DD/MM/YYYY', 0

; ------------------------------------------------------------------
; Code for 'BEEP' command.

command_beep:
    mov ax, 0E07h
    xor bx, bx
    int 10h

    jmp nx_cli

; ------------------------------------------------------------------
; Code for 'SYSINFO' command.

command_sysinfo:
    ; Print command header
    mov si, .sysinfo_str
    call nx_print_string
    call nx_print_nl
    call nx_print_nl

.vendor:                ; Get CPU Vendor
    mov eax, 0
    cpuid
    mov dword [.buffer + 0], ebx
    mov dword [.buffer + 4], edx
    mov dword [.buffer + 8], ecx

    mov si, .buffer
    mov di, .vendor_intel
    call nx_string_cmp
    jnc .is_amd_cpu

.is_intel_cpu:
    mov si, .cpu_intel_str
    call nx_print_string

    jmp .details

.is_amd_cpu:
    mov si, .cpu_amd_str
    call nx_print_string

.details:               ; Get CPU Detail String
    call nx_print_nl

    mov eax, 0x80000002
    cpuid

    mov dword [.buffer + 0], eax
    mov dword [.buffer + 4], ebx
    mov dword [.buffer + 8], ecx
    mov dword [.buffer +12], edx

    mov eax, 0x80000003
    cpuid

    mov dword [.buffer +16], eax
    mov dword [.buffer +20], ebx
    mov dword [.buffer +24], ecx
    mov dword [.buffer +28], edx

    mov eax, 0x80000004
    cpuid

    mov dword [.buffer +32], eax
    mov dword [.buffer +36], ebx
    mov dword [.buffer +40], ecx
    mov dword [.buffer +44], edx

    mov si, .processor_str
    call nx_print_string

    mov si, .buffer
    call nx_print_string

    call nx_print_nl

.kernel_location:
    call nx_print_nl

    mov si, .kernel_location_str
    call nx_print_string
    call nx_print_nl

    jmp nx_cli

    .buffer times 100 db 0

    .vendor_intel   db 'GenuineIntel', 0
    .vendor_amd     db 'AuthenticAMD', 0

    .sysinfo_str    db 'NOSX ', NOSX_VERSION, ': System information', 0
    .cpu_intel_str  db 'Vendor: Intel (R)', 0
    .cpu_amd_str    db 'Vendor: AMD', 0
    .processor_str  db 'Processor: ', 0

    .kernel_location_str db 'Kernel loaded at address: 0x1000', 0

; ------------------------------------------------------------------
; Code for 'DESTROY' command.

command_destroy:
    mov si, .destroy_str3
    call nx_print_string
    mov ah, 86h         ; Delay
    mov cx, 10
    int 15h

    mov si, .destroy_str2
    call nx_print_string
    mov ah, 86h         ; Delay
    mov cx, 10
    int 15h

    mov si, .destroy_str1
    call nx_print_string
    mov ah, 86h         ; Delay
    mov cx, 10
    int 15h

    call reset_floppy

.destroy_file_sector:
    mov ax, .buffer
    mov es, ax
    xor bx, bx

    mov ax, word [.sector]
    call l2hts

    mov ah, 03h
    mov al, 01h
    int 13h

    jc .done ; If error we are done

    add word [.sector], 1

    jmp .destroy_file_sector

.done:

    mov ax, 0
    int 19h             ; Reboot the system

    call nx_cli

    .sector dw 0
    .buffer times 512 db 0

    .destroy_str3 db 'The World And Everything You Know Will Destroy In 3', 0Dh, 0
    .destroy_str2 db 'The World And Everything You Know Will Destroy In 2', 0Dh, 0
    .destroy_str1 db 'The World And Everything You Know Will Destroy In 1', 0Dh, 0

; ------------------------------------------------------------------
; Code for 'CLS' command.

command_cls:
    call nx_clear_screen

    jmp nx_cli

; ------------------------------------------------------------------
; Code for 'HELP' command.

command_help:
    mov si, cli_help_text
    call nx_print_string

    jmp nx_cli

; ------------------------------------------------------------------
; Code for 'EXIT' command.

command_exit:
    ret

; ------------------------------------------------------------------
; Code for 'RESTART' command.

command_restart:
    mov ax, 0
    int 19h             ; Reboot the system

    ret

; ------------------------------------------------------------------
; Code for 'LOGIN' command, auth module.

cli_log_in:
    ; Check if user is authorized already
    cmp byte [user_logged_in], 1
    jne .do_auth

    mov si, cli_auth_already
    call nx_print_string

    jmp .done

.do_auth:
    mov si, cli_auth_up
    call nx_print_string

    ; Read suplied username
    mov ax, cli_input
    call nx_scan_string

    call nx_print_nl

    ; Check if username matches
    mov si, cli_input
    mov di, nx_username
    call nx_string_cmp
    jnc .do_auth

    mov si, cli_auth_pp
    call nx_print_string

    ; Clear input buffer
    mov di, cli_input
    mov al, 0
    mov cx, 256
    rep stosb

    ; Read suplied password
    mov ax, cli_input
    call nx_scan_string

    call nx_print_nl

    ; Check if password matches
    mov si, cli_input
    mov di, nx_password
    call nx_string_cmp
    jnc .do_auth

    call nx_print_nl

    mov byte [user_logged_in], 1

    ; Print greeting (first part)
    mov si, cli_auth_welcome1
    call nx_print_string

    ; Print username
    mov si, nx_username
    call nx_print_string

    call nx_print_nl

    ; Print greeting (second part)
    mov si, cli_auth_welcome2
    call nx_print_string

.done:

    ; Go back to CLI
    jmp nx_cli

; ------------------------------------------------------------------
; Code for 'LOGOUT' command, auth module.

cli_log_out:
    mov byte [user_logged_in], 0

    ; Print Goodbye msg
    mov si, cli_auth_goodbye
    call nx_print_string

    ; Back to CLI
    jmp nx_cli

; =============================================================================
; Strings and variables
; =============================================================================

    cli_prompt          db ' > ', 0

    cli_help_text       db 'NOSX ', NOSX_VERSION, ' Command Line Interpreter',      NL, NL,  \
                           'CLI/OS related: EXIT, RESTART, SYSINFO, BEEP',     NL, NL,  \
                           'For auth module available commands are: LOGIN, LOGOUT', NL,      \
                           'For clock/calendar: TIME, DATE' ,                       NL, NL,  \
                           'For this text run HELP, also you can EXIT cli.',        NL,      0

    cli_invalid_cmd     db 'ERROR: No such command!', NL, 0

; ------------------------------------------------------------------
; CLI Auth module related defines.

    cli_auth_up         db 'Username: ', 0
    cli_auth_pp         db 'Password: ', 0
    cli_auth_err        db 'ERROR: To interact with OS please LOGIN first', NL, 0
    cli_auth_welcome1   db 'Welcome, ', 0
    cli_auth_welcome2   db 'Now you can run any command! See HELP', NL, 0
    cli_auth_goodbye    db 'Goodbye...', NL, 0
    cli_auth_already    db 'ERR: LOGOUT first so you can LOGIN with another account.', NL, 0

; ------------------------------------------------------------------
; CLI available commands list.

    login_cmd           db 'LOGIN',  0
    logout_cmd          db 'LOGOUT', 0

    help_cmd            db 'HELP', 0
    exit_cmd            db 'EXIT', 0

    time_cmd            db 'TIME',    0
    date_cmd            db 'DATE',    0
    cls_cmd             db 'CLS',     0
    beep_cmd            db 'BEEP',    0
    sysinfo_cmd         db 'SYSINFO', 0
    restart_cmd         db 'RESTART', 0
    destroy_cmd         db 'DESTROY', 0

    nx_username         db 'nv', 0
    nx_password         db '',   0

    user_logged_in      db 0
    cli_input           times 256 db 0