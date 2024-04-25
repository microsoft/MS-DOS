COMMENT #
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*                                                                             *
* MODULE NAME     : INDEACC                                                   *
*                                                                             *
*                                                                             *
*                    5669-196 (C) COPYRIGHT 1988 Microsoft Corporation 	      *
*                                                                             *
* DESCRIPTIVE NAME: Access rights byte definitions for 80386 XMA emulator     *
*                                                                             *
* STATUS (LEVEL)  : Version (0) Level (1.0)                                   *
*                                                                             *
* FUNCTION        : This file defines the access rights bytes used in         *
*                   descriptors that define the code and data segments.       *
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
* $MAC(INDEACC) COMP(LOAD) PROD(3270PC) :                                     *
*                                                                             *
* $D0=D0004700 410 870530 D : NEW FOR WSP RELEASE 1.1                         *
* $P1=P0000311 410 870804 D : RENAME MODULE'S LIBRARY FILE TYPE TO "INC"      *
*                                                                             *
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
#

PAGE
;       RECORD DEFINITIONS FOR ACCESS RIGHTS BYTES
;       ====== =========== === ====== ====== =====
;
;       Data Segments - Interpretation of access rights for DS/ES/SS


;       Define the bit fields for the access rights byte

DATA_ACC RECORD PRESENT:1,DPL:2,SEG_TYPE:1,XQTBLE:1,EXPDIR:1,WRTBLE:1,ACCESSED:1

              ; PRESENT  (1 bit)   0 = segment not present in memory
              ;                    1 = segment present in memory
              ;
              ; DPL      (2 bits)  Descriptor privilege level -- 0 to 3
              ;
              ; SEG_TYPE (1 bit)   0 = system segment
              ;                    1 = application segment
              ;
              ; XQTBL    (1 bit)   0 = segment is not executable (i.e., data)
              ;                    1 = segment is executable     (i.e., code)
              ;
              ; EXPDIR   (1 bit)   0 = expand up, i.e., normal data segment
              ;                    1 = expand down, i.e., stack segment
              ;
              ; WRTBLE   (1 bit)   0 = data segment is read only
              ;                    1 = data segment is read/write
              ;
              ; ACCESSED (1 bit)   0 = segment has not been accessed
              ;                    1 = segment has been accessed


; Privilege level 3 read/write data segment access rights byte

CPL3_DATA_ACCESS        EQU     11110011B     ; Present
                                              ; DPL = 3
                                              ; Application segment
                                              ; Not executable (i.e. data)
                                              ; Expand up
                                              ; Readable/Writable
                                              ; Accessed

; Privilege level 0 read/write data segment access rights byte

CPL0_DATA_ACCESS        EQU     10010011B     ; Present
                                              ; DPL = 0
                                              ; Application segment
                                              ; Not executable (i.e. data)
                                              ; Expand up
                                              ; Readable/Writable
                                              ; Accessed


NULL_ACCESS             EQU     00000000B     ; Null (Not present)


; Descriptor privilege levels.  These can be ANDed or ORed with the access
; rights byte to get the desired DPL for the descriptor.

DPL3                    EQU     01100000B
DPL2                    EQU     01000000B
DPL1                    EQU     00100000B
DPL0                    EQU     00000000B

PAGE
;       Code Segments - Interpretation of access rights for CS.
;                       Identical to data segments except for two fields.


CODE_ACC        RECORD  DATA_HI:5,CONFORM:1,READABLE:1,DATA_LO:1

              ; DATA_HI  (5 bits)  Same five bits as described for data segments
              ;                    PPRESENT (1), DPL (2), SEG_TYPE (1) and
              ;                    XQTBL (1)
              ;
              ; CONFORM  (1 bit)   0 = Non-conforming - cannot be called by
              ;                        someone with a different CPL
              ;                    1 = Conforming - can be called by anyone
              ;                        regardless of CPL.  CPL remains the same
              ;
              ; READABLE (1 bit)   0 = code segment is execute only
              ;                    1 = data segment is executable and readable
              ;
              ; DATA_LO  (1 bit)   Same bit as described for data segments
              ;                    ACCESSED (1)


; Privilege level 3 conforming readable code segment access rights byte
; BUT...
; We switched the DPL to 0.  Why?  Because the DPL of the current code segment
; determines the current privilege level (CPL).  Whatever is running at the
; time can only access data with a DPL >= CPL.  So if the DPL for the code
; segment were 3 and we tried to access data with a DPL of 0 we would get a
; fault. By setting the DPL of the code segment to 0 we can access all data
; and will never be bothered by faults.

CPL3_CODE_ACCESS        EQU     10011111B     ; Present
                                              ; DPL = 0
                                              ; Application segment
                                              ; Executable (i.e. code)
                                              ; Conforming
                                              ; Readable
                                              ; Accessed

; Access rights to be able to read and write to a code segment.  Code segments
; may not be written to.  So this access byte will define the segment as a
; read/write data segment.  It is the same as CPL3_DATA_ACCESS.

COMP_CODE_ACCESS        EQU     CPL3_DATA_ACCESS

; Privilege level 0 non-conforming readable code segment access rights byte

CPL0_CODE_ACCESS        EQU     10011011B     ; Present
                                              ; DPL = 0
                                              ; Application segment
                                              ; Executable (i.e. code)
                                              ; Non-conforming
                                              ; Readable
                                              ; Accessed

PAGE
;       System Segments - Interpretation of access rights for TR/LDTR as well as
;                         the four gate types.  The access rights byte for the
;                         GDTR and IDTR is undefined, meaning anyone can access
;                         the table (although not necessarily the segments
;                         defined in the table). The uppermost 4 bits are
;                         identical to those for data segments; the type field
;                         occupies the lowermost 4 bits.


SYSTEM_ACC      RECORD  DATA_H:4,DESC_TYPE:4

              ; DATA_H   (4 bits)  Same four bits as described for data segments
              ;                    PPRESENT (1), DPL (2) and SEG_TYPE (1)
              ;
              ; DESC_TYPE(4 bits)  0000  Intel Reserved
              ;                    0001  Available 286 TSS
              ;                    0010  LDT
              ;                    0011  Busy 286 TSS
              ;                    0100  Call Gate
              ;                    0101  Task Gate
              ;                    0110  286 Interrupt Gate
              ;                    0111  286 Trap Gate
              ;                    1000  Intel Reserved
              ;                    1001  Available 386 TSS
              ;                    1010  Intel Reserved
              ;                    1011  Busy 386 TSS
              ;                    1100  386 Call Gate
              ;                    1101  Intel Reserved
              ;                    1110  386 Interrupt Gate
              ;                    1111  386 Trap Gate
              ;


;       These equates cover the topmost 4 bits for system segment access
;       rights bytes.  They define the privilege level.

LDT_ACCESS      EQU     11100000B     ; Present, DPL = 3 for LDTs

TSS_ACCESS      EQU     10000000B     ; Present, DPL = 0 for TSSs

GATE_ACCESS     EQU     10000000B     ; Present, DPL = 0 for Gates


;       These are for the type field.  When "OR"ed with one of the above,
;       you have a complete access rights byte.

LDT_DESC        EQU     00000010B OR LDT_ACCESS

FREE_TSS        EQU     00000001B OR TSS_ACCESS
FREE_TSS_386    EQU     00001001B OR TSS_ACCESS

BUSY_TSS        EQU     00000011B OR TSS_ACCESS

CALL_GATE       EQU     00000100B OR GATE_ACCESS

TASK_GATE       EQU     00000101B OR GATE_ACCESS

INT_GATE        EQU     00000110B OR GATE_ACCESS

TRAP_GATE       EQU     00000111B OR GATE_ACCESS

