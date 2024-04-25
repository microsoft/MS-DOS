PAGE    60,132
TITLE   INDEGDT - 386 XMA Emulator - Build Global Descriptor Table

COMMENT #
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*                                                                             *
* MODULE NAME     : INDEGDT                                                   *
*                                                                             *
*                                                                             *
*                    5669-196 (C) COPYRIGHT 1988 Microsoft Corp.              *
*                                                                             *
* DESCRIPTIVE NAME: Build the Global Descriptor Table (GDT)                   *
*                                                                             *
* STATUS (LEVEL)  : Version (0) Level (1.0)                                   *
*                                                                             *
* FUNCTION        : Build the Global Descriptor Table (GDT) for the 80386     *
*                   XMA emulator                                              *
*                                                                             *
* MODULE TYPE     : ASM                                                       *
*                                                                             *
* REGISTER USAGE  : 80386 Standard                                            *
*                                                                             *
* RESTRICTIONS    : None                                                      *
*                                                                             *
* DEPENDENCIES    : None                                                      *
*                                                                             *
* ENTRY POINT     : GDT_BLD                                                   *
*                                                                             *
* LINKAGE         : Called NEAR from INDEINI                                  *
*                                                                             *
* INPUT PARMS     : None                                                      *
*                                                                             *
* RETURN PARMS    : None                                                      *
*                                                                             *
* OTHER EFFECTS   : None                                                      *
*                                                                             *
* EXIT NORMAL     : Return to INDEINI                                         *
*                                                                             *
* EXIT ERROR      : None                                                      *
*                                                                             *
* EXTERNAL                                                                    *
* REFERENCES      : None                                                      *
*                                                                             *
* SUB-ROUTINES    : SREG_2_24BITS - Convert the 16 bit value in AX to a 24    *
*                                   bit value in DH and AX.                   *
*                   ADDOFF - Add the 16 bit offset in AX to the 24 bit value  *
*                            in DH and BX.                                    *
*                                                                             *
* MACROS          : DESCR_DEF  - Declare a descriptor entry                   *
*                   DESCR_INIT - Initialize a descriptor                      *
*                                                                             *
* CONTROL BLOCKS  : INDEDAT - System data structures                          *
*                                                                             *
* CHANGE ACTIVITY :                                                           *
*                                                                             *
* $MOD(INDEGDT) COMP(LOAD) PROD(3270PC) :                                     *
*                                                                             *
* $D0=D0004700 410 870530 D : NEW FOR RELEASE 1.1                             *
* $P1=P0000293 410 870731 D : LIMIT LINES TO 80 CHARACTERS                    *
* $P2=P0000312 410 870804 D : CHANGE COMPONENT FROM MISC TO LOAD              *
* $P3=P0000410 410 870918 D : RELOCATE DATA AREAS TO MAKE ROOM FOR BIT MAP    *
*                                                                             *
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
#

        .286P                 ; Enable recognition of 286 privileged instructs.

        .XLIST                ; Turn off the listing
        INCLUDE INDEDAT.INC   ; Include system data structures
        INCLUDE INDEACC.INC   ; Include access byte definitions

        IF1                   ; Only include macros on the first pass
        INCLUDE INDEDES.MAC   ; Descriptor macros
        ENDIF
        .LIST                 ; Turn on the listing

PROG    SEGMENT PARA    PUBLIC  'PROG'

        ASSUME  CS:PROG
        ASSUME  SS:NOTHING
        ASSUME  DS:PROG
        ASSUME  ES:NOTHING

INDEGDT LABEL   NEAR

        PUBLIC  INDEGDT
        PUBLIC  GDT_BLD
        PUBLIC  GDT_DATA_START
        PUBLIC  SREG_2_24BITS

;       The following data define a pre-initialized GDT.  They represent
;       all structures which will exist when the emulator comes up.
;       THESE MUST BE INITIALIZED IN THE ORDER IN WHICH THEY APPEAR IN THE
;       GDT_DEF STRUCTURE DEFINITION AS IT APPEARS IN INDEDAT.INC.  This data
;       area will be copied from the code segment to the final GDT resting
;       place during initialization.

GDT_DATA_START  LABEL   WORD

;               First entry is unusable

       DESCR_DEF   SEG, 0, 0, 0, 0

;               The descriptor for GDT itself

       DESCR_DEF   SEG, GDT_LEN, GDT_LOC, 3, CPL0_DATA_ACCESS
PAGE

;               The system IDT descriptor

       DESCR_DEF   SEG, SIDT_LEN, SIDT_LOC, 3, CPL0_DATA_ACCESS

;               The real system data area descriptor (XMA pages)

       DESCR_DEF   SEG, 0FFFFH, 0000H, 11H, CPL0_DATA_ACCESS

;               The virtual IDT descriptor  (not needed so use for all memory)

       DESCR_DEF   SEG, MAX_SEG_LEN, NSEG@_LO, NSEG@_HI, CPL0_DATA_ACCESS

;               The LOADALL descriptor

       DESCR_DEF   SEG, 0, 0, 0, 0
PAGE

;               Compatible monochrome display

       DESCR_DEF   SEG, MCRT_SIZE, MCRT@_LO, MCRT@_HI, CPL0_DATA_ACCESS

;               Compatible color display

       DESCR_DEF   SEG, CCRT_SIZE, CCRT@_LO, CCRT@_HI, CPL0_DATA_ACCESS

;               Enhanced color display - one entry for each 64K              P1C

       DESCR_DEF   SEG, ECCRT_SIZE, ECCRT@_LO_LO, ECCRT@_LO_HI, CPL0_DATA_ACCESS

;               Second part of enhanced display                              P1C

       DESCR_DEF   SEG, ECCRT_SIZE, ECCRT@_HI_LO, ECCRT@_HI_HI, CPL0_DATA_ACCESS
PAGE

;               Code segment for ROM code, system IDT

       DESCR_DEF   SEG, MAX_SEG_LEN, CSEG@_LO, CSEG@_HI, CPL0_CODE_ACCESS

;               Data segment for ROM code, system IDT

       DESCR_DEF   SEG, MAX_SEG_LEN, CSEG@_LO, CSEG@_HI, CPL0_CODE_ACCESS

;               Temporarily, the monitor is installed using the patch
;                segment descriptors in the GDT

MSEG@_LO        EQU     00000H
MSEG@_HI        EQU     008H


;               Code segment for patch code, system IDT

       DESCR_DEF   SEG, MAX_SEG_LEN, MSEG@_LO, MSEG@_HI, CPL0_CODE_ACCESS

;               Data segment for patch code, system IDT

       DESCR_DEF   SEG, MAX_SEG_LEN, MSEG@_LO, MSEG@_HI, CPL0_DATA_ACCESS
PAGE

;               Code segment for ROM code, virtual IDT

       DESCR_DEF   SEG, MAX_SEG_LEN, CSEG@_LO, CSEG@_HI, CPL0_CODE_ACCESS

;               Data segment for ROM code, virtual IDT

       DESCR_DEF   SEG, MAX_SEG_LEN, CSEG@_LO, CSEG@_HI, CPL0_CODE_ACCESS

;               Code segment for patch code, virtual IDT

       DESCR_DEF   SEG, NULL_SEG_LEN, NSEG@_LO, NSEG@_HI, NULL_ACCESS

;               Data segment for patch code, virtual IDT

       DESCR_DEF   SEG, NULL_SEG_LEN, NSEG@_LO, NSEG@_HI, NULL_ACCESS
PAGE

;               Temporary descriptors for ES, CS, SS, and DS

       DESCR_DEF   SEG, MAX_SEG_LEN, NSEG@_LO, NSEG@_HI, CPL0_DATA_ACCESS

       DESCR_DEF   SEG, MAX_SEG_LEN, NSEG@_LO, NSEG@_HI, CPL0_CODE_ACCESS

       DESCR_DEF   SEG, MAX_SEG_LEN, NSEG@_LO, NSEG@_HI, CPL0_DATA_ACCESS

       DESCR_DEF   SEG, MAX_SEG_LEN, NSEG@_LO, NSEG@_HI, CPL0_DATA_ACCESS
PAGE

; These DQ's pad out the space between the last MultiPC descriptor and the
; PMVM descriptors.  They don't need initialization.

       DQ      9 DUP (0)     ; These 9 are for the Monitor descriptors

;               This is for the keyboard owner (not used)

       DQ       0

;               These 16 are for the virtual timer support

       DQ      16 DUP (0)

; The following 32 descriptors are for exception condition task gates.

       REPT    32
       DQ       0
       ENDM

; The following 16 pairs are for the hardware interrupt handling tasks.

       REPT    16
       DQ       0
       DQ       0
       ENDM

; The following pair is for the DISPATCH task

       DESCR_DEF   SEG, TSS_LEN, DISPATCH_LOC, 3, <TSS_ACCESS OR FREE_TSS>
       DESCR_DEF   SEG, TSS_LEN, DISPATCH_LOC, 3, CPL0_DATA_ACCESS

       DESCR_DEF   SEG, 0, 0, 0,LDT_DESC

; BASIC's segment

       DESCR_DEF   SEG, 07FFFH, 06000H, 0FH, CPL0_DATA_ACCESS

; BIOS's segment

       DESCR_DEF   SEG, 01FFFH, 00000H, 0FH, CPL0_DATA_ACCESS

       DQ      13 DUP (0)      ; Reserved guys

; The following guys are junk !  Used before the first TSS allocated. These
;  have to be in the PMVM location in the GDT.

       DESCR_DEF   SEG, TSS_LEN, 0C000H, 0, FREE_TSS         ; For the TR

       DESCR_DEF   SEG, TSS_LEN, 0C000H, 0, CPL0_DATA_ACCESS ; TSS as data

       DESCR_DEF   SEG, GDT_LEN, 0D000H, 0, LDT_DESC         ; For the LDTR

       DESCR_DEF   SEG, GDT_LEN, 0D000H, 0, CPL0_DATA_ACCESS ; LDT as data

GDT_DATA_END    LABEL   WORD

COPY_LEN        EQU     GDT_DATA_END-GDT_DATA_START

;
;       End of pre-allocated GDT
;

PAGE

GDT_BLD         PROC    NEAR

; Copy the pre-initialized GDT into its proper location in memory

        CLI                             ; All string operations go forward

        MOV     SI,OFFSET GDT_DATA_START ; DS:SI points to the pre-initialized
                                        ;   GDT above
        MOV     CX,COPY_LEN/2           ; CX = number of words to copy
        MOV     DI,GDT_LOC              ; ES:DI points to the GDT location
        REP     MOVSW                   ; Copy GDT into its final resting place

; Now let's initialize some of the GDT entries

; Set up the descriptors for our code segment and data segment

        MOV     AX,CS                   ; Get our CS
        CALL    SREG_2_24BITS           ; And convert it to a 24 bit offset
        MOV     BX,AX                   ; Get the monitor offset

ALLSET:
        DESCR_INIT  SEG, SYS_PATCH_CS, 07FFFH, BX, DH, CPL0_CODE_ACCESS
        DESCR_INIT  SEG, SYS_PATCH_DS, 0FFFFH, BX, DH, CPL0_DATA_ACCESS

; Initialize the descriptor for the GDT

        MOV     AX,ES                   ; Get the segment of the GDT
        CALL    SREG_2_24BITS           ; Convert to a 24 bit offset
        MOV     DL,DH                   ; Save a copy of the hi byte
        MOV     BX,GDT_LOC              ; Add on the offset of the GDT
        CALL    ADDOFF

        DESCR_INIT  SEG, GDT_PTR, GDT_LEN, BX, DH, CPL0_DATA_ACCESS

; Initialize the descriptor for the IDT

        MOV     BX,SIDT_LOC             ; DH,AX already contains the segment
                                        ;   converted to 24 bits so all we
        CALL    ADDOFF                  ;   have to do is add on the offset

        DESCR_INIT  SEG, MON_IDT_PTR, SIDT_LEN, BX, DH, CPL0_DATA_ACCESS

; Initialize the descriptor that accesses all of memory as data

        DESCR_INIT  BSEG, HUGE_PTR, 0FFFFH, 0, 0, CPL0_DATA_ACCESS

; Initialize the descriptors for the V86 task's LDT

        MOV     BX,DISPATCH_LOC                                           ; @P3C
        CALL    ADDOFF

        DESCR_INIT  SEG,SCRUBBER.VM_LDTR,00FFFH,BX,DH,LDT_DESC
        DESCR_INIT  SEG,SCRUBBER.LDT_PTR,00FFFH,BX,DH,CPL0_DATA_ACCESS

; Initialize the descriptors for the V86 task's TR

        MOV     BX,DISPATCH_LOC                                           ; @P3C
        CALL    ADDOFF

        DESCR_INIT  SEG,SCRUBBER.VM_TR,TSS_LEN,BX,DH,FREE_TSS_386         ; @P3C
        DESCR_INIT  SEG,SCRUBBER.TSS_PTR,TSS_LEN,BX,DH,CPL0_DATA_ACCESS; @P3C

        RET

GDT_BLD         ENDP

PAGE
; SREG_2_24BITS converts the segment register 16 bit value in the AX register
; into a 24 bit value in DH and AX
;
;       Input :    AX = segment register value
;
;       Output:    AX = 24 bit low word
;                  DH = 24 bit high byte


SREG_2_24BITS PROC    NEAR

; Put the high four bits of AH into the low four bits of DH

        MOV     DH,AH                   ; Get the high byte of the segment value
                                        ;   into DH
        AND     DH,0F0H                 ; Strip off the low nibble
        SHR     DH,4                    ; Shift right four bits

; Now shift AX left four bits

        AND     AH,00FH                 ; Strip high nibble from AH
                                        ;   This keeps the carry flag from being
                                        ;   set which could effect later ADDs.
        SHL     AX,4                    ; Shift AX

        RET

SREG_2_24BITS ENDP

PAGE
; ADDOFF adds the 16 bit offset in BX to the 24 bit value in DL and AX.  The
; result is left in DH and BX.
;
;       Input :    DL = 24 bit high byte
;                  AX = 24 bit low word
;                  BX = offset to be added
;
;       Output:    DH = 24 bit high byte
;                  BX = 24 bit low word

ADDOFF  PROC    NEAR

        MOV     DH,DL                   ; Restore the high byte that was saved
                                        ;   in DL
        ADD     BX,AX                   ; Add on the offset
        ADC     DH,0                    ; Add the carry, if any, to the high
                                        ;   byte
        RET

ADDOFF  ENDP

PROG    ENDS

        END
