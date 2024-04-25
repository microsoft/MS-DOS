;
page 80,132
;
title CP/DOS DosSelectDisk mapper
;
dosxxx  segment byte public 'dos'
        assume  cs:dosxxx,ds:nothing,es:nothing,ss:nothing
;
;**********************************************************************
;*
;*   MODULE:   dosselectdisk
;*
;*   FILE NAME: dos048.asm
;*
;*   CALLING SEQUENCE:
;*
;*       push      word  drive          drive number
;*       call      dosselectdisk
;*
;*   MODULES CALLED:  PC-DOS Int 21h, ah=0eh, select disk
;*
;*********************************************************************

            public   dosselectdisk
            .sall
            .xlist
            include  macros.inc
            .list

str         struc
old_bp      dw       ?
Return      dd       ?
Drive       dw       ?       ; drive number
str         ends

dosselectdisk  proc  far
        Enter   Dosselectdisk         ; push registers

        mov     dx,[bp].drive         ; load drive number
        dec     dx                    ; adjust for cp/dos incompatibility

        mov     ah,0eh
        int     21h                   ; select the drive

        sub     ax,ax                 ; set good return code

        mexit                         ; pop registers
        ret     size str - 6          ; return

dosselectdisk endp

dosxxx      ends

            end
