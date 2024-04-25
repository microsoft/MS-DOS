;       BOOT - IBM hard disk boot record             6/8/82
;
;
; This is the standard boot record that will be shipped on all hard disks. It contains:
;
; 1. Code to load (and give control to) the boot record for 1 of 4 possible
;    operating systems.
;
; 2. A partition table at the end of the boot record, followed by the required signature.
;
;
_data   segment public
        assume  cs:_data,ds:_data

        org 600h

        cli             ;no interrupts for now
        xor ax,ax
        mov ss,ax
        mov sp,7c00h    ;new stack at 0:7c00
        mov si,sp       ;where this boot record starts - 0:7c00
        push ax
        pop es          ;seg regs the same
        push ax
        pop ds
        sti             ;interrupts ok now
        cld
        mov di,0600h    ;where to relocate this boot record to
        mov cx,100h
        repnz movsw     ;relocate to 0:0600
;       jmp entry2
        db   0eah
        dw   $+4,0
entry2:
        mov si,offset tab      ;partition table
        mov bl,4        ;number of table entries
next:
        cmp byte ptr[si],80h  ;is this a bootable entry?
        je boot         ;yes
        cmp byte ptr[si],0    ;no, is boot indicator zero?
        jne bad         ;no, it must be x"00" or x"80" to be valid
        add si,16       ;yes, go to next entry
        dec bl
        jnz next
        int 18h         ;no bootable entries - go to rom basic
boot:
        mov dx,[si]     ;head and drive to boot from
        mov cx,[si+2]   ;cyl, sector to boot from
        mov bp,si       ;save table entry address to pass to partition boot record
next1:
        add si,16       ;next table entry
        dec bl          ;# entries left
        jz tabok        ;all entries look ok
        cmp byte ptr[si],0    ;all remaining entries should begin with zero
        je next1        ;this one is ok
bad:
        mov si,offset m1 ;oops - found a non-zero entry - the table is bad
msg:
        lodsb           ;get a message character
        cmp al,0
        je  hold
        push si
        mov bx,7
        mov ah,14
        int 10h         ;and display it
        pop si
        jmp msg         ;do the entire message
;
hold:   jmp hold        ;spin here - nothing more to do
tabok:
        mov di,5        ;retry count
rdboot:
        mov bx,7c00h    ;where to read system boot record
        mov ax,0201h    ;read 1 sector
        push di
        int 13h         ;get the boot record
        pop di
        jnc goboot      ;successful - now give it control
        xor ax,ax       ;had an error, so
        int 13h         ;recalibrate
        dec di          ;reduce retry count
        jnz rdboot      ;if retry count above zero, go retry
        mov si,offset m2 ;all retries done - permanent error - point to message,
        jmp msg          ;go display message and loop
goboot:
        mov si,offset m3 ;prepare for invalid boot record
        mov di,07dfeh
        cmp word ptr [di],0aa55h ;does the boot record have the
                                   ;    required signature?
        jne msg         ;no, display invalid system boot record message
        mov si,bp       ;yes, pass partition table entry address
        db 0eah
        dw 7c00h,0

include fdisk5.cl1

        org 7beh
tab:                    ;partition table
        dw 0,0          ;partition 1 begin
        dw 0,0          ;partition 1 end
        dw 0,0          ;partition 1 relative sector (low, high parts)
        dw 0,0          ;partition 1 # of sectors (low, high parts)
        dw 0,0          ;partition 2 begin
        dw 0,0          ;partition 2 end
        dw 0,0          ;partition 2 relative sector
        dw 0,0          ;partition 2 # of sectors
        dw 0,0          ;partition 3 begin
        dw 0,0          ;partition 3 end
        dw 0,0          ;partition 3 relative sector
        dw 0,0          ;partition 3 # of sectors
        dw 0,0          ;partition 4 begin
        dw 0,0          ;partition 4 end
        dw 0,0          ;partition 4 relative sector
        dw 0,0          ;partition 4 # of sectors
signa   db 55h,0aah     ;signature

_data   ends
        end
