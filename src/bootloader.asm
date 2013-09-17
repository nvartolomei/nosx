; =============================================================================
; The NOSX OS Bootloader.
; =============================================================================

    BITS 16

    %INCLUDE 'defines.asm'

    jmp short bootloader_start ; jump past disk description section
    nop ; pad out before disk description

; ------------------------------------------------------------------
; Disk description table, to make it a valid floppy

OEMLabel            db "NOSX OS"     ; Disk label
BytesPerSector      dw 512           ; Bytes per sector
SectorsPerCluster   db 1             ; Sectors per cluster
ReservedForBoot     dw 1             ; Reserved sectors for boot record
NumberOfFats        db 2             ; Number of copies of the FAT
RootDirEntries      dw 224           ; Number of entries in root dir
                                     ; (224 * 32 = 7168 = 14 sectors to read)
LogicalSectors      dw 2880          ; Number of logical sectors
MediumByte          db 0F0h          ; Medium descriptor byte
SectorsPerFat       dw 9             ; Sectors per FAT
SectorsPerTrack     dw 18            ; Sectors per track (36/cylinder)
Sides               dw 2             ; Number of sides/heads
HiddenSectors       dd 0             ; Number of hidden sectors
LargeSectors        dd 0             ; Number of LBA sectors
DriveNo             dw 0             ; Drive No: 0
Signature           db 41            ; Drive signature: 41 for floppy
VolumeID            dd 00000000h     ; Volume ID: any number
VolumeLabel         db "NOSX OS    " ; Volume Label: any 11 chars
FileSystem          db "FAT12   "    ; File system type: don't change!

; ------------------------------------------------------------------
; Main bootloader code

bootloader_start:
    ; Set data segment to match where we're loaded
    mov ax, 07C0h
    mov ds, ax

    ; Print bootloader welcome message
    mov si, bootloader_welcome
    call print_string

    ; Reset floppy
    call reset_floppy
    jc fatal_disk_error

    mov word [sector], 33

load_file_sector:
    ; Set segment where to write kernel binary
    mov ax, kernel_seg
    mov es, ax
    mov bx, word [pointer]

    ; Now we want to read 128 sectors (one 16bit segment, 64K) from floppy,
    ; starting with logical 33rd sector.
    mov ax, word [sector]
    call l2hts

    mov al, 01h
    mov ah, 02h

    int 13h

    ; If there is an error
    jc read_disk_error

    ; Dipplay progress indicator
    call progress

    ; Stop if we have already read 128 sectors
    cmp word [sector], 33 + 128 - 1
    je end

    ; If not, read further
    add word [pointer], 512
    add word [sector],  1

    jmp load_file_sector

; ------------------------------------------------------------------
; Handle read error

read_disk_error:
    mov si, read_disk_error_msg
    call print_string

    ; wait for user input
    mov ah, 0h
    int 16h

    call reset_floppy

    ; try to read again
    jmp load_file_sector


; ------------------------------------------------------------------
; Handle fatal disk error
; Displays message and reboots

fatal_disk_error:
    mov si, fatal_disk_error_msg
    call print_string

    ; wait for user input
    mov ah, 0h
    int 16h

    call reboot

; ------------------------------------------------------------------
; Kernel is loaded into RAM and ready

end:
    mov si, kernel_delay
    call print_string

    ; Set up 2s delay
    mov ah, 86h
    mov cx, 20
    int 15h

    ; Jump to entry point of loaded kernel
    jmp kernel_seg:0000h


; =============================================================================
; Bootloader subroutines.
; =============================================================================

progress:
    pusha

    cmp dh, 0h ; only God know why
    je .done

    mov ah, 86h
    mov cx, 1
    int 15h

    mov ah, 0Eh
    mov al, 0B0h
    int 10h

.done:
    popa

    ret

; ------------------------------------------------------------------
; Displays text
; IN: SI = message location; OUT: Nothing

print_string:       ; Routine: output string in SI to screen
    mov ah, 0Eh     ; int 10h 'print char' function

.repeat:
    lodsb           ; Get character from string
    cmp al, 0
    je .done        ; If char is zero, end of string
    int 10h         ; Otherwise, print it
    jmp .repeat

.done:
    ret


; ------------------------------------------------------------------
; Reboot system

reboot:
    mov ax, 0
    int 19h             ; Reboot the system


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


; =============================================================================
; Strings and variables
; =============================================================================

    kernel_seg           equ   1000h

    boot_device          dw    0
    sector               dw    0
    pointer              dw    0

    bootloader_welcome   db    'Bootloader is running...!', NL, NL, 0
    kernel_delay         db    NL, NL, 'Starting Kernel in 2 seconds...', NL, 0

    fatal_disk_error_msg db    NL, 'Fatal disk error! Press any key to reboot...', 0
    read_disk_error_msg  db    NL, 'Could not read sector! Press any key to try again...', NL, 0


; =============================================================================
; End of boot sector
; =============================================================================

    times 510-($-$$) db 0 ; Pad remainder of boot sector with zeros
    dw 0AA55h ; Boot signature
