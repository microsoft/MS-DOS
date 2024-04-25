COMMENT #
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*                                                                             *
* MODULE NAME     : INDEDAT                                                   *
*                                                                             *
*                                                                             *
*                    5669-196 (C) COPYRIGHT 1988 Microsoft Corporation        *
*                                                                             *
* DESCRIPTIVE NAME: Sytem data structures and equates for 386 XMA emulator    *
*                                                                             *
* STATUS (LEVEL)  : Version (0) Level (1.0)                                   *
*                                                                             *
* FUNCTION        : This file defines the overlays and constants for most of  *
*                   the system data.  The following structures are defined    *
*                   here:                                                     *
*                          The resister save area on our stack                *
*                          80386 Task State Segment (TSS)                     *
*                          The Global Descriptor Table (GDT)                  *
*                          80286 Segment Descriptor                           *
*                          80286 Gate Descriptor                              *
*                          80286 Task State Segment (TSS)                     *
*                                                                             *
* MODULE TYPE     : INC                                                       *
*                                                                             *
* REGISTER USAGE  : 80386 Standard                                            *
*                                                                             *
* RESTRICTIONS    : None                                                      *
*                                                                             *
* DEPENDENCIES    : None                                                      *
*                                                                             *
* EXTERNAL                                                                    *
* REFERENCES      : None                                                      *
*                                                                             *
* CHANGE ACTIVITY :                                                           *
*                                                                             *
* $MAC(INDEDAT) COMP(LOAD) PROD(3270PC) :                                     *
*                                                                             *
* $D0=D0004700 410 870529 D : NEW FOR WSP RELEASE 1.1                         *
* $P1=P0000311 410 870804 D : RENAME MODULES'S LIBRARY FILE TYPE TO "INC"     *
* $P2=P0000410 410 870918 D : RELOCATE DATA TO MAKE ROOM FOR I/O BIT MAP      *
*                                                                             *
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
#

; BPSTACK is an overlay for our stack when we receive control from an
; interrupt that we want to handle.  The entry points for these interrupts
; push a 32 but error  code and the interrupt number (16 bits) onto the stack.
; Then control goes to INDEEXC which saves the current register values on the
; stack.  BP is set to point to the beginning of the register save area.  This
; is the mapping of the resulting stack.

BPSTACK STRUC

BP_ES   DW      0             ; Interrptee's ES
BP_DI   DW      0             ; Interruptee's EDI (32 bit DI)
        DW      0             ;
BP_SI   DW      0             ; Interruptee's ESI (32 bit SI)
        DW      0             ;
BP_BP   DW      0             ; Interruptee's EBP (32 bit BP)
        DW      0             ;
BP_PASP DW      0             ; Interruptee's ESP (32 bit SP)
BP_PSP2 DW      0             ;   (ESP as it was before the PUSHA)
BP_BX   DW      0             ; Interruptee's EBX (32 bit BX)
        DW      0             ;
BP_DX   DW      0             ; Interruptee's EDX (32 bit DX)
        DW      0             ;
BP_CX   DW      0             ; Interruptee's ECX (32 bit CX)
        DW      0             ;
BP_AX   DW      0             ; Interruptee's EAX (32 bit AX)
        DW      0             ;
BP_DS   DW      0             ; Interruptee's DS
BP_EX   DW      0             ; Exception ID
BP_EC   DW      0             ; Error Code
        DW      0

; The following values are placed on our stack by the 80386

BP_IP   DW      0             ; Interruptee's EIP (32 bit IP)
BP_IP2  DW      0
BP_CS   DW      0             ; Interruptee's CS (16 bit CS plus 16 bit trash)
BP_CS2  DW      0
BP_FL   DW      0             ; Interruptee's flags (32 bits)
BP_FL2  DW      0
BP_SP   DW      0             ; Interruptee's ESP - saved on an inter-level
BP_SP2  DW      0             ;   interrupt
BP_SS   DW      0             ; Interruptee's SSP - also saved on inter-level
BP_SS2  DW      0             ;   interrupt
BP_VMES DW      0             ; Virtual mode ES
BP_VME2 DW      0
BP_VMDS DW      0             ; Virtual mode DS
        DW      0
BP_VMFS DW      0             ; Virtual mode FS
        DW      0
BP_VMGS DW      0             ; Virtual mode GS
        DW      0
BP_STK  DW      0             ; The rest of the stack

BPSTACK ENDS

BP_START EQU    0             ; Offset from BP of the start of the stack info

SUBTTL   80386 TSS - Task State Segment
PAGE
;*************************************************
;                                                *
;         Start of Debugger's 386 TSS            *
;                                                *
;*************************************************

TSS386          STRUC
                DW      0     ; Intel reserved
ETSS_BACK_LINK  DW      0     ; Back link to previous TSS
ETSS_SP0        DW      0     ; ESP for privilege level 0
                DW      0
ETSS_SS0        DW      0     ; SS for privilege level 0
                DW      0     ; Intel reserved
ETSS_SP1        DD      0     ; ESP for privilege level 1
ETSS_SS1        DW      0     ; SS for privilege level 1
                DW      0     ; Intel reserved
ETSS_SP2        DD      0     ; ESP for privilege level 2
ETSS_SS2        DW      0     ; SS for privilege level 2
                DW      0     ; Intel reserved
ETSS_CR3        DD      0     ; CR3 - Page directory base register
ETSS_IP         DW      0     ; Task's EIP
                DW      0
ETSS_FL         DW      0     ; Task's Eflags
ETSS_FL2        DW      0
ETSS_AX         DD      0     ; Task's EAX
ETSS_CX         DD      0     ; Task's ECX
ETSS_DX         DD      0     ; Task's EDX
ETSS_BX         DD      0     ; Task's EBX
ETSS_SP         DW      0     ; Task's ESP
                DW      0
ETSS_BP         DD      0     ; Task's EBP
ETSS_SI         DD      0     ; Task's ESI
ETSS_DI         DD      0     ; Task's EDI
ETSS_ES         DW      0     ; Task's ES
                DW      0     ; Intel reserved
ETSS_CS         DW      0     ; Task's CS
                DW      0     ; Intel reserved
ETSS_SS         DW      0     ; Task's SS
                DW      0     ; Intel reserved
ETSS_DS         DW      0     ; Task's DS
                DW      0     ; Intel reserved
ETSS_FS         DW      0     ; Task's FS
                DW      0     ; Intel reserved
ETSS_GS         DW      0     ; Task's GS
                DW      0     ; Intel reserved
ETSS_LDT        DW      0     ; Selector for task's LDT
                DW      0     ; Intel reserved
ETSS_TRAP       DW      0     ; Trap bit - bit 0 (IBM bit 15)
ETSS_BM_OFFSET  DW      0     ; I/O bit map base
ETSS_AVL        DD      0
TSS386          ENDS
TSS_386_LEN     EQU     68H   ; Length of the TSS
TSS_BM_LEN      EQU     0FFFH-TSS_386_LEN  ; Length of the I/O bit map
                              ; The bit map is in the same segment as the TSS
                              ;   therefore the descriptor fot the TSS segment
                              ;   must have enough room to include the bit map.

SUBTTL  GDT - Global Descriptor Table
PAGE

SUBTTL  GDT - GLOBAL DESCRIPTOR TABLE

;       THE GLOBAL DESCRIPTOR TABLE DEFINITION
;       === ====== ========== ===== ==========
;

GDT_LEN         EQU     512 * 8       ; 512 entries total

GDT_DEF         STRUC

UNUSED_ENTRY    DQ      0             ; Seg reg = 0 illegal - this entry is
                                      ; not accessible
GDT_PTR         DQ      0             ; This entry points to this GDT table
MON_IDT_PTR     DQ      0             ; System interrupt descriptor table
RSDA_PTR        DQ      0             ; The real system data area (as opposed
                                      ; to the virtual SDA's).  XMA pages
                                      ; start here
HUGE_PTR        DQ      0             ; Used to address 0-1M as data

LA_PTR          DQ      0             ; Pointer to the LOADALL area (000800H)

C_BWCRT_PTR     DQ      0             ; Compatible blanck and white display
C_CCRT_PTR      DQ      0             ; Compatible color display
E_CCRT_PTR      DQ      0             ; Enhanced color display (16 bytes)
E_CCRT_PTR2     DQ      0

SYS_ROM_CS      DQ      0             ; CS for system IDT, ROM resident
SYS_ROM_DS      DQ      0             ; DS selector to access above as data
SYS_PATCH_CS    DQ      0             ; CS for system IDT, RAM patch area
SYS_PATCH_DS    DQ      0             ; DS selector to access above as data

V_ROM_CS        DQ      0             ; CS - virtual IDT, ROM resident
V_ROM_DS        DQ      0             ; DS selector to access above as data
V_PATCH_CS      DQ      0             ; CS - virtual IDT, RAM patch area
V_PATCH_DS      DQ      0             ; DS selector to access above as data

ES_TEMP         DQ      0             ; Dynamic pointer for ES
CS_TEMP         DQ      0             ; Dynamic pointer for CS
SS_TEMP         DQ      0             ; Dynamic pointer for SS
DS_TEMP         DQ      0             ; Dynamic pointer for DS

;       Monitor descriptors

MON_LDTR        DQ      0
MON_DS          DQ      0
MON_ES          DQ      0
MON_SS          DQ      0
MON_CS          DQ      0
MON_TR_SS       DQ      0             ; Task register value for single step
MON_TR_BP       DQ      0             ;  "      "       "    "  breakpoint
MON_TR_HWI      DQ      0             ; Read/write (needs special hardware)
MON_TR_OI       DQ      0             ;  "      "       "    "  control-break

KBD_OWNER_SDA   DQ      0             ; Fast path to keyboard owner's SDA

VTIMER_VECTOR   DB     16 DUP (8 DUP(0))      ; 16 VM timer-related descriptors

;       Below are the 32 system exception service routine descriptors.

SEX_TSS         DB      32 DUP (8 DUP(0))

;       Below are the 16 hardware interrupt service routine TSS descriptor
;       pairs.  The first is suitable for TR loading (i.e. target selector
;       in the corresponding task gate) and the other is a TSS-as-data
;       descriptor.

HWI_TSS         DB      16 DUP (16 DUP(0))

;       This is the descriptor pair for the dispatcher (same format as HWI).

DISPATCH_TASK   DQ      0
                DQ      0

HWI_LDT         DQ      0

BASICS_SEG      DQ      0             ; BASIC's segment (F600)

BIOSS_SEG       DQ      0             ; BIOS's segment (F000)

;
;
;       Any other GDT things go here.  There are around 300 slots left.
;
;

RSVD_GDT        DQ      0
                DB     (GDT_LEN - (RSVD_GDT + 8) - (18 * 32)) DUP (0)

                                      ; The above leaves space for the
                                      ; descriptors needed for 18 VMs

PM_VM           DB     32 DUP (0)     ; Program Manager's virtual machine
                                      ; entries.  This will function as
                                      ; the highest priority machine.
USER_CS         DQ      0             ; Debugee's code segment
USER_SS         DQ      0             ; Debugee's stack segment
USER_DS         DQ      0             ; Debugee's data segment
USER_ES         DQ      0             ; Debugee's extra segment
USER_TSS        DQ      0             ; Debugee's Task State Segment
USER_TSS_DAT    DQ      0             ; Debugee's TSS as a data segment
USER_LDT        DQ      0             ; Debugee's LDT definition
USER_LDT_DAT    DQ      0             ; Debugee's LDT as a data segment

USER_VMS        DB     14 DUP (32 DUP(0))     ; 16 user VMs

SCRUBBER        DB     32 DUP (0)     ; RAM scrubber - dispatched when no other
                                      ; machine has work to do
last_gdt_byte   db     0              ; marker for last GDT byte + 1
GDT_DEF         ENDS

SUBTTL  Virtual Machine Entry
PAGE
;       Virtual Machine Entry Definition - consists of 4 descriptors
;
;               - Pointer to TSS, loadable into the Task Register
;               - Pointer to TSS, loadable into a regular segment register
;               - Pointer to the LDT, loadable into the LDT Register
;               - Pointer to the LDT, loadable into a regular segment register
;
;       The first of each pair is for loading into the associated special
;       system registers,  TR and LDTR.  The second allows dynamic access
;       and modification of descriptors by the system.

VM_GDT_ENTRY    STRUC

VM_TR           DQ      0             ; TR value for this machine's TSS
TSS_PTR         DQ      0             ; Data pointer to this machine's TSS
VM_LDTR         DQ      0             ; LDTR value for this machine's LDT
LDT_PTR         DQ      0             ; Data pointer to this machine's LDT

VM_GDT_ENTRY    ENDS

SUBTTL  80286 Segment Descriptor
PAGE
;       DESCRIPTOR TABLE ENTRY STRUCTURES
;       ========== ===== ===== ==========
;
;       Segment Descriptor
;
;       The following type of descriptor applies to data segments, code
;       segments, local, global, and interrupt descriptor table segments,
;       and task state segments.

DATA_DESC       STRUC

SEG_LIMIT       DW      0             ; Segment limit (1 - 65535 bytes)
BASE_LO_WORD    DW      0             ; 24 bit segment physical address
BASE_HI_BYTE    DB      0             ;   (0 - (16M-1))
DATA_ACC_RIGHTS DB      0             ; Access rights byte
DATA_RESERVED   DW      0             ; Intel reserved

DATA_DESC       ENDS

SHADOW_ID       EQU     DATA_RESERVED ; For garbage collection

SUBTTL  80286 Gate Descriptor
PAGE
;       80286 Gate Descriptor

;       The following type of descriptor applies to task gates, call gates,
;       interrupt gates, and trap gates.

GATE_DESC       STRUC

ENTRY_POINT     DW      0             ; Destination routine entry point
                                      ;   within the target segment.
                                      ;   This is unused for task gates.
CS_SELECTOR     DW      0             ; Selector for destination segment.
                                      ;   For task gates, this must point
                                      ;   to a valid task state segment
                                      ;   descriptor.  For call, trap, and
                                      ;   interrupt gates, this must point
                                      ;   to a valid code segment descriptor.
                                      ;   The segment defined in that
                                      ;   descriptor plus the aforementioned
                                      ;   entry-point defines the actual
                                      ;   routine address.
WORD_COUNT      DB      0             ; For call gates only - number of
                                      ;   words to copy from caller's
                                      ;   stack to callee's stack
GATE_ACC_RIGHTS DB      0             ; Access rights byte
GATE_RESERVED   DW      0             ; Intel reserved

GATE_DESC       ENDS

;       Record for the fields in a selector

SELECTOR        RECORD  INDEX:13,TI:1,RPL:2   ; Standard 286 selector format

SUBTTL  TSS - Task State Segment
PAGE
;       TASK STATE SEGMENT
;       ==== ===== =======
;
;       There are currently two styles of task state segment (TSS) - one for
;       VMs and one for the hardware interrupt service routines.  There may
;       be more later, depending on the needs and/or whims of the Authors
;       of this and follow-on products.  They will all have one thing in
;       common - they begin with a 44 byte 286-required machine state data
;       area.  The first structure below is that area's definition.  All
;       subsequent colors of TSS will start with space for that data, defined
;       like so:
;
; first_field_name        DB      (TYPE TASK_STATE_286)   DUP     (0)
;
;       As a convenience, we use the highest part of the TSS for that
;       particular task's stack (or in some cases, stacks - for privilege
;       levels 0, 1, and 2).  The intermediate area is used for task-specific
;       data.


TASK_STATE_286  STRUC

BACK_LINK       DW      0               ; TSS selector from whence we came
VM_SP0          DW      0               ; SS:SP for CPL 0
VM_SS0          DW      0
VM_SP1          DW      0               ; SS:SP for CPL 1
VM_SS1          DW      0
VM_SP2          DW      0               ; SS:SP for CPL 2
VM_SS2          DW      0
VM_IP           DW      0               ; IP - next instruction to execute
VM_FL           DW      0               ; Flag word
VM_AX           DW      0               ;
VM_CX           DW      0               ; General
VM_DX           DW      0               ;
VM_BX           DW      0               ;
VM_SP           DW      0               ;         Purpose
VM_BP           DW      0               ;
VM_SI           DW      0               ;
VM_DI           DW      0               ;                 Registers
VM_ES           DW      0               ;
VM_CS           DW      0               ; Segment
VM_SS           DW      0               ;          Selectors
VM_DS           DW      0               ;
VM_LDT          DW      0               ; Selector for this task's LDT

TASK_STATE_286  ENDS

;       Note that the actual stacks for CPLs 2, 1, and 0 are part of the
;       task state segment.  CPL 3's stack is in its own address space.

SUBTTL  Length Equates
PAGE
;       Length equates

LA_LEN          EQU     GDT_LEN         ; For new monitor

SIDT_LEN        EQU     256*8           ; Length of the IDT -- 256 interrupt
                                        ;   entries, 8 bytes each

TSS_LEN         EQU     68H + 2000H     ; TSS structure length -- 68H for regs
                                        ;   2000H for I/O bit map  @P2C

LDT_LEN         EQU     00800H          ; LDT structure length (2K)

VM_ENTRY_LENGTH EQU     TYPE VM_GDT_ENTRY ; Length of a VM entry

VM_ENTRY_WIDTH  EQU     5               ; Shift count for priority. Each
                                        ; VM entry = 32 bytes, and SHL 5
                                        ; is the same as MUL by 32.
NEXT_DESC       EQU     TYPE DATA_DESC  ; Length of a descriptor

DESC_LEN        EQU     TYPE DATA_DESC  ; Length of a descriptor

DESC_WIDTH      EQU     3               ; Shift count for desc len (8) is 3

PM_VM_SIZE      EQU     01000H          ; Virtual Manager's VM size

MCRT_SIZE       EQU     4*1024          ; Monochrome display size

CCRT_SIZE       EQU     16*1024         ; Compatible color display size

ECCRT_SIZE      EQU     0FFFFH          ; Size of each portion of the enhanced
                                        ;   color display buffer

MAX_SEG_LEN     EQU     0FFFFH          ; Maximum segment length = 64K

NULL_SEG_LEN    EQU     00000H          ; Null segment length = 0

THIRTY_TWO_K    EQU     08000H          ; Unit of virtual machine size


SUBTTL  Location Equates
PAGE


;       Location equates

;       These items are all pre-allocated, and have no SBDs.  After these,
;       storage structures are all obtained through the memory manager.

;-----------------------------------------------------------------------------

; From here to the end marker, these guys must stay in order as this is
;  how they are allocated.

GDT_LOC         EQU     0C100H          ; GDT location relative to CS       @P2C

SIDT_LOC        EQU     (GDT_LOC + GDT_LEN)  ; The system IDT is next

DISPATCH_LOC     EQU     (SIDT_LOC + SIDT_LEN)

; End marker

;   Monitor equate used in m_state to tell the estep routine that we're
;    single stepping from within ego.
GO_MODE         EQU     1               ;
;   Monitor equate used in m_state to tell the hwi_int routine that we're
;    breaking on a memory read address that's executed
MEMX            EQU     2               ;
;   Monitor equate used in m_state to tell mon_go that a breakpoint has been
;    set so enable the breakpoint card
CARD_ENABL      EQU     4               ;
S_MODE          EQU     2000H           ; Selector or segment mode flag

BOOT_IP         EQU     07C00H          ; PC1 IP value for boot

BOOT_CS         EQU     00000H          ; PC1 CS value for boot

BOOT_SS         EQU     00030H          ; PC1 SS value for boot

BOOT_SP         EQU     07FFH           ; PC1 SP value for boot

BOOT_FL         EQU     00200H          ; Interrupts enabled

CS_LO_CACHE     EQU     00000H          ; Code segment

CS_HI_CACHE     EQU     000H            ;   compatible cache

SS_LO_CACHE     EQU     00300H          ; Stack segment

SS_HI_CACHE     EQU     000H            ;   compatible cache

OTHER_CACHE     EQU     00000H          ; GP zero cache

SUBTTL  Display Equates
PAGE

;       The next equates are system definitions for display buffer addresses.


MCRT@_LO        EQU     0000H           ;
                                        ; Monochrome display address
MCRT@_HI        EQU     0BH             ; (0B0000H)

CCRT@_LO        EQU     8000H           ;
                                        ; Compatible color display address
CCRT@_HI        EQU     0BH             ; (0B8000H)

ECCRT@_LO_LO    EQU     0000H           ;
                                        ; Enhanced color display address -
ECCRT@_LO_HI    EQU     0AH             ;   lower 64K (0A0000H)

ECCRT@_HI_LO    EQU     0000H           ;
                                        ; Enhanced color display address -
ECCRT@_HI_HI    EQU     0CH             ;   upper 64K (0C0000H)


;       Code segment addresses


CSEG@_LO        EQU     0000H           ;
                                        ; ROM code segment address
CSEG@_HI        EQU     0EH             ; (0E0000H)

NSEG@_LO        EQU     0000H           ;
                                        ; Null segment address
NSEG@_HI        EQU     00H             ;

VIRTUAL_ENABLE  EQU     0000000000000001B

SUBTTL
