TITLE   SORT FILTER FOR DOS
        PAGE    ,132                    ;
;**********************************************************
;*
;*   UTILITY NAME:         sort
;*
;*   SOURCE FILE NAME:     sort.asm
;*
;*   UTILITY FUNCTION:
;*
;*         External non-resident utility, written in Assembler.
;*         Reads from the standard input device until end-of-file,
;*         sorts the data (up to 64k) and writes the results to
;*         the standard output device.  Input and output can be
;*         redirected.
;*
;*   INPUT (Command line)
;*
;*           SORT [/R] [/+ n]
;*
;*          /R   - Sort in reverse order
;*          /+n  - Start sorting in column "n" , default 1
;*
;*   OUTPUT:
;*         Sorted data will be written to the standard output device.
;*
;*   ERROR CONDITIONS:
;*         Incorrect DOS version
;*         Insufficient disk space on target
;*         Insufficient memory to allocate SORT buffer
;*         Invalid parameter
;*
;*   INTERNAL REFERENCES:
;*         Main
;*
;*   SOURCE HISTORY:
;*         Modification History:
;*         3-18-83 MZ   (Microsoft)
;*                      Fix CR-LF at end of buffer
;*                      Fix small file sorting
;*                      Fix CR-LF line termination bug
;*                      Comment the Damn source
;*
;*         6-23-86 RW (IBM)
;*                      Add DOS 3.30 support for multiple languages
;*                      Inclusion of common DOS VERSION check equate
;*
;*  ;AN000; Code added in DOS 4.0
;*         5-19-87 RW (IBM) (DOS 4.0)
;*                      Addition of IBM Parser Service Routines
;*                      Addition of DOS Message Retriever Service Routines
;*                      Add code page file tag support
;*
;*  ;AN001; Code added in DOS 4.0
;*  ;AN002; DCR 191
;*         9-18-87 BL (IBM) (DOS 4.0)
;*                      Added Extended Attribute support for code page checking
;*                       and file type checking.
;*  ;AN003; PTM 1805
;*         10-19-87 BL (IBM) (DOS 4.0)
;*
;*  ;AN004; PTM
;*         01-29-87 BL (IBM) (DOS 4.0)
;*                      Ran tool INSPECT on .lst file for optimizations
;**********************************************************

        PAGE   ;
;-------------------------
;---    Macro definitions
;-------------------------
BREAK   MACRO   subtitle
        SUBTTL  subtitle
        PAGE
ENDM



sys     MACRO   name            ;system call macro
        MOV     AH,name
        INT     21h
        ENDM



save    MACRO   reglist         ;push those registers
IRP reg,<reglist>
        PUSH    reg
ENDM
ENDM



restore MACRO   reglist         ;pop those registers
IRP reg,<reglist>
        POP     reg
ENDM
ENDM


        PAGE   ;
;-------------------------------
;---    Equates
;-------------------------------
FALSE   EQU     0
TRUE    EQU     NOT FALSE
MAXREC  EQU     256                     ;MAXIMUM NUL RECORD SIZE

SPACE   EQU     0                       ;Offset zero in the allocated block
BUFFER  EQU     MAXREC                  ;Offset MAXREC in the allocated block

RETCODE_NOERROR equ 0                   ;AN000; DOS return code (errorlevel)
RETCODE_ERROR   equ 1                   ;AN000; DOS return code (errorlevel)

NO_CODEPAGE     equ 0                   ;AN000; Tag for files with no codepage

GetCPSW         equ  3303h              ;AN000; Int 021h function calls
GetExtAttr      equ  5702h              ;AN000;
SetExtAttr      equ  5704h              ;AN000;
;-----------------------
;--     Parser equates
;-----------------------
EOL     EQU    -1                       ;AN000; Indicator for End-Of-Line
NOERROR EQU     0                       ;AN000; Return Indicator for No Errors
 
FarSW   equ     0                       ;AN000;
DateSW  equ     0                       ;AN000;
TimeSW  equ     0                       ;AN000;
FileSW  equ     0                       ;AN000;
CAPSW   equ     0                       ;AN000;
CmpxSW  equ     0                       ;AN000;
NumSW   equ     1                       ;AN000;
KeySW   equ     0                       ;AN000;
SwSW    equ     1                       ;AN000;
Val1SW  equ     1                       ;AN000;
Val2SW  equ     0                       ;AN000;
Val3SW  equ     0                       ;AN000;
DrvSW   equ     0                       ;AN000;
QusSW   equ     0                       ;AN000;

;-----------------------
;--     Message equates
;-----------------------
STDIN   equ     0
STDOUT  equ     1
STDERR  equ     2

Msg_NoMem       equ     2               ;AC003;
Msg_NoDisk      equ     4               ;AC003;
Msg_sort        equ     5               ;AN003;
Msg_switch      equ     3               ;AN003;

;------------------------------
; EXTENDED ATTRIBUTE Equates
;------------------------------
EAISBINARY            equ     02h        ;AN001;  ea_type
EASYSTEM              equ     8000h      ;AN001;  ea_flags

        PAGE   ;
;---------------------;
.xlist                ;
.xcref                ;
INCLUDE syscall.inc   ;
INCLUDE sysmsg.inc    ;                 ;AN000; Include message equates and MACROS
.cref                 ;
.list                 ;
;---------------------;

MSG_UTILNAME <SORT>                     ;AN000;

SUBTTL  Segments used in load order


CODE    SEGMENT
CODE    ENDS

CONST   SEGMENT PUBLIC BYTE
CONST   ENDS


;-----------------------
;---    Stack Segment
;-----------------------
CSTACK  SEGMENT STACK
        db 128 DUP (0)          ;initial stack to be clear

CSTACK  ENDS



;-------------------------------
;---    Group
;-------------------------------
DG      GROUP   CODE,CONST,CSTACK


;-------------------------------
;---    Code Segment
;-------------------------------
CODE    SEGMENT
ASSUME  CS:DG,DS:DG,ES:NOTHING,SS:CSTACK

;-------------------------------
;---    Data Definition
;-------------------------------
COLUMN          dw      0               ;COLUMN TO USE FOR KEY + 1
cp_reset        db      FALSE           ;AN000;Flag indicating if Code Page was reset on target file

;------------------------------------------DOS 3.30 - Russ Whitehead
CTRY_INFO       db      ?
CTRY_TABLE_OFF  dw      ?
CTRY_TABLE_SEG  dw      ?
;------------------------------------------

MSG_SERVICES <MSGDATA>                  ;AN000;
ASSUME   ds:nothing

;----------------------------------------
;- STRUCTURE TO QUERY EXTENDED ATTRIBUTES
;----------------------------------------
querylist      struc                    ;AN001; ;query general list
qea_num        dw      1                ;AN001;
qea_type       db      EAISBINARY       ;AN001;
qea_flags      dw      EASYSTEM         ;AN001;
qea_namelen    db      ?                ;AN001;
qea_name       db      "        "       ;AN001;
querylist      ends                     ;AN001;

cp_qlist       querylist <1,EAISBINARY,EASYSTEM,2,"CP">   ;AN001; ;query code page attr.

cp_list        label   word             ;AN001; ;code page attr. get/set list
               dw      1                ;AN001; ; # of list entries
               db      EAISBINARY       ;AN001; ; ea type
               dw      EASYSTEM         ;AN001; ; ea flags
               db      ?                ;AN001; ; ea return code
               db      2                ;AN001; ; ea name length
               dw      2                ;AN001; ; ea value length
               db      "CP"             ;AN001; ; ea name
cp             dw      ?                ;AN001; ; ea value (code page)
cp_len         equ     ($ - cp_list)    ;AN001;

;-------Save area for Code Pages
src_cp         dw      ?                ;AN000; Save area for current code page
tgt_cp         dw      ?                ;AN000; Save area for current code page
endlist label  word                     ;AN000;

        PAGE   ;
;******************************************************************************
;*                                               PARSER DATA STRUCTURES FOLLOW
;******************************************************************************

;------------------------------
;- STRUCTURE TO DEFINE ADDITIONAL COMMAND LINE DELIMITERS
;------------------------------
parms   label   word                    ;AN000;
        dw      parmsx                  ;AN000; POINTER TO PARMS STRUCTURE
        db      1                       ;AN000; DELIMITER LIST FOLLOWS
        db      1                       ;AN000; NUMBER OF ADDITIONAL DELIMITERS
        db      ";"                     ;AN000; ADDITIONAL DELIMITER

;------------------------------
;- STRUCTURE TO DEFINE SORT SYNTAX REQUIREMENTS
;------------------------------
parmsx  label   word                    ;AN000;
        db      0,0                     ;AN000; THERE ARE NO POSITIONAL PARAMETERS
        db      2                       ;AN000; THERE ARE 2 SWITCHES (/R AND /+n)
        dw      sw1                     ;AN000; POINTER TO FIRST SWITCH DEFINITION AREA
        dw      sw2                     ;AN000; POINTER TO SECOND SWITCH DEFINITION AREA
        dw      0                       ;AN000; THERE ARE NO KEYWORDS IN SORT SYNTAX

;------------------------------
;- STRUCTURE TO DEFINE THE /R SWITCH
;------------------------------
sw1     label   word                    ;AN000;
        dw      0                       ;AN000; NO MATCH FLAGS
        dw      0                       ;AN000; NO FUNCTION FLAGS
        dw      switchbuff              ;AN000; PLACE RESULT IN switchbufF
        dw      novals                  ;AN000; NO VALUE LIST
        db      1                       ;AN000; ONLY ONE SWITCH IN FOLLOWING LIST
rev_sw  db      "/R",0                  ;AN000; /R INDICATES REVERSE SORT

;------------------------------
;- STRUCTURE TO DEFINE THE /+n SWITCH
;------------------------------
NUMERIC equ     08000h                  ;AN000; Control flag for numeric value
NO_COLON equ    0020h                   ;AN000;

sw2     label   word                    ;AN000;
        dw      NUMERIC                 ;AN000; MATCH_FLAGS
        dw      NO_COLON                ;AN000; NO FUNCTION FLAGS
        dw      switchbuff              ;AN000; PLACE RESULT IN switchbufF
        dw      valuelist               ;AN000; NEED VALUE LIST FOR n
        db      1                       ;AN000; ONLY 1 SWITCH ON FOLLOWING LIST
col_sw  db      "/+",0                  ;AN000; /+n INDICATES BEGIN SORT IN COLUMN n

;------------------------------
;- VALUE LIST DEFINITION FOR NO VALUES
;------------------------------
novals  label   word                    ;AN000;
        DB      0                       ;AN000;  VALUE LIST

;------------------------------
;- VALUE LIST DEFINITION FOR /+n
;------------------------------
valuelist       label   word            ;AN000;
                db      1               ;AN000; ONE VALUE ALLOWED
                db      1               ;AN000; ONLY ONE RANGE
                db      1               ;AN000; IDENTIFY THE RANGE
                dd      1,65535         ;AN000; USER CAN SPECIFY /+1 THROUGH /+65535

;------------------------------
;- RETURN BUFFER FOR SWITCH INFORMATION
;------------------------------
switchbuff      label   word            ;AN000;
sb_type         db      ?               ;AN000; TYPE RETURNED
sb_item_tag     db      ?               ;AN000; SPACE FOR ITEM TAG
sb_synonym      dw      ?               ;AN000; ES:sb_synonym points to synonym

sb_value        dw      ?               ;AN000; SPACE FOR VALUE
sb_value_extra  dw      ?               ;AN000; UNUSED SPACE FOR VALUE

        PAGE   ;
;**************************************************************
;*
;*   SUBROUTINE NAME:      main
;*
;*   SUBROUTINE FUNCTION:
;*         Mainline routine, performs SYSLODMSG, calls routines to
;*         parse command line, performs the SORT and writes the
;*         results.
;*
;*   INPUT:
;*         Command Line.
;*
;*         File to be sorted will be read from Standard Input
;*         device handle 0.
;*
;*   OUTPUT:
;*         Sorted data will be written to the Standard Output
;*         device handle 1.
;*
;*   NORMAL EXIT:
;*         SORT will normally exit when data was successfully read
;*         in up to 64k or EOF, sorted, and displayed to the
;*         standard output device.
;*
;*   ERROR EXIT:
;*         If any of the following errors, SORT will display the
;*         corresponding error message and terminate.
;*
;*           Insufficient disk space on target device
;*           Incorrect DOS version
;*           Insufficient memory to sort
;*
;************************************************************

;-------------------------
; Preload messages
;-------------------------
        MSG_SERVICES <SORT.ctl,SORT.cla,SORT.cl1,SORT.cl2>      ;AN000;
        MSG_SERVICES <DISPLAYmsg,LOADmsg,CHARmsg,NOCHECKSTDIN>          ;AN002; Make retriever services available

        mov     ax,cs                   ;AN003; ;load ES to the right area,
        mov     es,ax                   ;AN003;
        mov     ds,ax                   ;AN003;
SORT:
        call    sysloadmsg              ;AN000;  Preload messages, Check DOS Version.
                                        ;If Inc DOS Ver or error loading messages,
                                        ;SYSLOADMSG will show msg and terminate for us
        jnc     parser                  ;AN000; If no error, parse command line
        call    sysdispmsg              ;AN000; There was error.  Let SYSDISPMSG Display
        cmp     bx,-1                   ;AN000; Is this DOS 1.0 or 1.1 ?
        je      OLD_ABORT               ;AN000;  Yes, terminate old way

        mov     ah,Exit                 ;AN000; No, terminate new way
        mov     al,0                    ;AN000; Errorlevel 0 (Compatible!)
        int     021h                    ;AN000; Bye bye!

OLD_ABORT:                              ;AN000; CS should point to PSP
        mov     ah,Abort                ;AN000; Terminate program (AH=0)
        int     021h                    ;AN000; Bye bye!
;-----------------------------------
;- DOS version is ok. Parse cmd line
;-----------------------------------
PARSER:                                 ;AN000;   message and terminate
        call    parse                   ;AN000;  Parse command line

;-----------------------------------
; set up column for proper sort offset
;-----------------------------------

        ADD     COLUMN,2
        CMP     COLUMN,2
        JZ      GOT_COL
        DEC     COLUMN

;------------------------------------
; Get sorting area, no more than 64K
;------------------------------------
GOT_COL:
        MOV     BX,1000H                ;64K worth of paragraphs
GET_MEM:
        mov     bp,bx                   ;AN003; save buffer length
        sys     ALLOC                   ;allocate them from somewhere
        JNC     GOT_MEM                 ;if error, BX has amount free, try to get it
        OR      BX,BX                   ;but, is BX = 0?
        JNZ     GET_MEM                 ;nope, try to allocate it
        JMP     short SIZERR            ;AN004; ;complain

GOT_MEM:
;------------------------------------RussW:--Following add in DOS 3.3 for Nat Lang Support
        push    ax                      ;Save AX
        push    ds                      ;Save DS
        push    es                      ;Save ES
        mov     al,6                    ;Function for Get collating sequence
        mov     bx,-1                   ;Get active code page
        mov     dx,-1                   ;Get info from active country
        mov     cx,5                    ;Number of bytes to be returned
        push    cs                      ;Place code segment
        pop     es                      ;in ES
        mov     di,offset ctry_info     ;Return area for 5 byte requested information
        sys     GetExtCntry             ;Get extended country information
                                        ;Ok, now copy the table in DOS to our segment
        lds     si,dword ptr cs:ctry_table_off
        mov     di,seg dg
        mov     es,di
        mov     di,offset dg:table
        mov     cx,word ptr [si]
        add     si,2
        mov     ax,256
        sub     ax,cx
        add     di,ax
        cld
        rep     movsb
                                        ;Done copying, so restore regs and cont
        pop     es                      ;Restore ES
        pop     ds                      ;Restore DS
        pop     ax                      ;Restore AX
;------------------------------------RussW:--End 3.3 addition
        MOV     DS,AX                   ;Point DS to buffer
        MOV     ES,AX                   ;and point ES to buffer
        MOV     CL,4                    ;2^4 bytes per paragraph
        MOV     BX,BP                   ;AN003; restore buffer length
        SHL     BX,CL                   ;Find out how many bytes we have
        MOV     BP,BX                   ;AN003; save buffer length in bytes

;---------------------------
; Clear out temporary record area
;---------------------------
        MOV     CX,MAXREC/2             ;Size of temporary buffer (words)
        MOV     AX,'  '                 ;Character to fill with
        XOR     DI,DI                   ;AN004; ;Beginning of temp buffer
        REP     STOSW                   ;Blam.
;-----------------------------------
; Make sure source and target code pages are the same
;-----------------------------------
        call    match_codepages         ;AN000;  Make sure codepages are the same
;---------------------------
; read in file from standard input
;---------------------------
        MOV     DX,BUFFER + 2           ;DX = place to begin reading
        MOV     CX,BP                   ;AN003; ;CX is the max number to read
        SUB     CX,MAXREC + 2           ;remember offset of temp buffer
SORTL:
        XOR     BX,BX                   ;Standard input
        sys     READ                    ;Read it in
        ADD     DX,AX                   ;Bump pointer by count read
        SUB     CX,AX                   ;subtract from remaining the count read
        JZ      SIZERR                  ;if buffer is full then error
        OR      AX,AX                   ;no chars read -> end of file
        JNZ     SORTL                   ;there were chars read. go read again
        JMP     SHORT SIZOK             ;trim last ^Z terminated record
SIZERR:
        mov     ax,msg_NoMem            ;AN000;  not enough memory error
        mov     dh,-1                   ;AN003;  class: utility error
        call    error_exit              ;AN000;  and write it out

;---------------------------
; Look for a ^Z. Terminate buffer at 1st ^Z.
;---------------------------
SIZOK:
        MOV     BX,DX                   ;save end pointer
        MOV     CX,DX                   ;get pointer to end of text
        SUB     CX,BUFFER+2             ;dif in pointers is count
        MOV     AL,1AH                  ;char is ^Z
        MOV     DI,BUFFER+2             ;point to beginning of text
        REPNZ   SCASB                   ;find one
        JNZ     NoBack                  ;nope, try to find CRLF
        DEC     BX                      ;pretend that we didn't see ^Z
NoBack:
        SUB     BX,CX                   ;sub from endpointer the number left
        SUB     BX,2                    ;Hope for a CR LF at end
        CMP     WORD PTR [BX],0A0Dh     ;Was there one there?
        JZ      GOTEND                  ;yep, here is the end
        ADD     BX,2                    ;nope, bump back to SCASB spot
        CMP     BYTE PTR [BX],AL        ;Was there ^Z there?
        JZ      GOTEND                  ;yep, chop it
        INC     BX                      ;Nope, skip last char
GOTEND:
        MOV     BP,BX                   ;BP = filesize-2(CRLF)+temp buffer+2
        MOV     WORD PTR DS:[BP],0      ;0 at end of the file

;---------------------------
;  We now turn the entire buffer into a linked list of chains by
;  replacing CRLFs with the length of the following line (with 2 for CRLF)
;---------------------------
        MOV     BX,BUFFER               ;pointer to line head (length)
        MOV     DI,BUFFER+2             ;pointer to line text
REPLACE_LOOP:
        MOV     AL,13                   ;char to look for is CR
        MOV     CX,BP                   ;count = end pointer
        SUB     CX,DI                   ;chop off start point to get length
        INC     CX                      ;add 1???
REPLACE_SCAN:
        REPNZ   SCASB                   ;look for CR
        JNZ     REPLACE_SKIP            ;count exhausted
        CMP     BYTE PTR [DI],10        ;LF there?
        JNZ     REPLACE_SCAN            ;nope, continue scanning
REPLACE_SKIP:
        MOV     AX,DI                   ;AX to point after CR
        DEC     AX                      ;AX to point to CR
        save    <AX>                    ;save pointer
        SUB     AX,BX                   ;AX is length of line found
        MOV     [BX],AX                 ;stuff it in previous link
        restore <BX>                    ;get pointer to next
        INC     DI                      ;skip LF???
        JCXZ    END_REPLACE_LOOP        ;no more to scan -> go sort
        JMP     REPLACE_LOOP            ;look for next

END_REPLACE_LOOP:
        MOV     WORD PTR [BX],0         ;terminate file with nul
        LEA     BP,[BX+2]               ;remember the null line at end
        MOV     DI,BUFFER               ;DI is start of unsorted section

;---------------------------
; begin sort. Outer loop steps over all unsorted lines
;---------------------------
OUTER_SORT_LOOP:
        MOV     BX,DI                   ;BX is start of unsorted section
        MOV     SI,BX                   ;SI is scanning place link
        CMP     WORD PTR [BX],0         ;are we at the end of the buffer?
        JNZ     INNER_SORT_LOOP         ;No, do inner process
        JMP     END_OUTER_SORT_LOOP     ;yes, go dump out

;---------------------------
; BX points to best guy found so far. We scan through the sorted section
; to find an appropriate insertion point
;---------------------------
INNER_SORT_LOOP:
        ADD     SI,[SI]                 ;link to next fellow
        MOV     AX,[SI]                 ;get length of comparison guy
        OR      AX,AX                   ;test for end of buffer
        JZ      END_INNER_SORT_LOOP     ;if zero then figure out insertion
        save    <SI,DI>                 ;save SI,DI
        MOV     DI,BX                   ;DI = pointer to tester link
        SUB     AX,COLUMN               ;adjust length for column
        JA      AXOK                    ;more chars in tester than column?
        XOR     SI,SI                   ;AN004; ;point SI to blank area
        MOV     AX,MAXREC               ;make AX be max length
AXOK:
        MOV     DX,[DI]                 ;get length of best guy
        SUB     DX,COLUMN               ;adjust length for column
        JA      DXOK                    ;there are more chars after column
        XOR     DI,DI                   ;AN004; ;point air to a space
        MOV     DX,MAXREC               ;really big record
DXOK:
        MOV     CX,AX                   ;AX is shortest record
        CMP     AX,DX                   ;perhaps DX is shorter
        JB      SMALL                   ;nope, leace CX alone
        MOV     CX,DX                   ;DX is shorter, put length in CX
SMALL:
        ADD     DI,COLUMN               ;offset into record
        ADD     SI,COLUMN               ;offset into other record
        push    bx
        push    ax
        mov     bx,offset dg:table
tloop:  lodsb
        xlat    byte ptr cs:[bx]
        mov     ah,al
        mov     al,es:[di]
        inc     di
        xlat    byte ptr cs:[bx]
        cmp     ah,al
        loopz   tloop
        pop     ax
        pop     bx
        restore <DI,SI>                 ;get head pointers back
        JNZ     TESTED_NOT_EQUAL        ;didn't exhaust counter, conditions set
        CMP     AX,DX                   ;check string lengths
TESTED_NOT_EQUAL:

;---------------------------
; NOTE! jae is patched to a jbe if file is to be sorted in reverse!
;---------------------------
CODE_PATCH label byte
        JAE     INNER_SORT_LOOP         ;if this one wasn't better then go again
        MOV     BX,SI                   ;it was better, save header
        JMP     INNER_SORT_LOOP         ;and scan again

END_INNER_SORT_LOOP:
        MOV     SI,BX                   ;SI is now the best person
        CMP     SI,DI                   ;check best for current
        JZ      END_INSERT              ;best equals current, all done

;---------------------------
; SI points to best line found so far
; DI points to a place to insert this line
; DI is guaranteed to be < SI
; make room for line at destination
;---------------------------
        MOV     DX,[SI]                 ;get length of line
        save    <SI,DI>                 ;save positions of people
        STD                             ;go right to left
        MOV     CX,BP                   ;get end of file pointer
        SUB     CX,DI                   ;get length from destination to end
        MOV     SI,BP                   ;start from end
        DEC     SI                      ;SI points to end of file
        MOV     DI,SI                   ;destination is end of file
        ADD     DI,DX                   ;DI points to new end of file
        REP     MOVSB                   ;blam. Move every one up
        CLD                             ;back left to right
        restore <DI,SI>                 ;get old source and destination
;---------------------------
;  MOVE NEW LINE INTO PLACE
;---------------------------
        save    <DI>                    ;save destination
        ADD     SI,DX                   ;adjust for previous movement
        save    <SI>                    ;save this value
        MOV     CX,DX                   ;get number to move
        REP     MOVSB                   ;blam. move the new line in
        restore <SI,DI>                 ;get back destination and new source
;---------------------------
;  DELETE LINE FROM OLD PLACE
;---------------------------
        save    <DI>                    ;save destination
        MOV     CX,BP                   ;pointer to end
        ADD     CX,DX                   ;remember bump
        SUB     CX,SI                   ;get count of bytes to move
        INC     CX                      ;turn it into a word
        SHR     CX,1                    ;or a count of words
        MOV     DI,SI                   ;new destination of move
        ADD     SI,DX                   ;offset of block
        REP     MOVSW                   ;blam, squeeze out the space
        restore <DI>                    ;get back original destination
        MOV     WORD PTR DS:[BP-2],0    ;remake the end of file mark

END_INSERT:
        ADD     DI,[DI]                 ;link to next guy
        JMP     OUTER_SORT_LOOP         ;and continue
;------------------------------
;       PUT BACK IN THE CR-LF
;------------------------------
END_OUTER_SORT_LOOP:
        MOV     DI,BUFFER               ;start at beginning (where else)
        MOV     CX,[DI]                 ;count of butes

INSERT_LOOP:
        ADD     DI,CX                   ;point to next length
        MOV     CX,[DI]                 ;get length
        MOV     WORD PTR [DI],0A0DH     ;replace length with CRLF
        AND     CX,CX                   ;AN004; ;check for end of file
        JNZ     INSERT_LOOP             ;nope, try again

WRITE_FILE:
        MOV     DX,BUFFER+2             ;get starting point
        MOV     CX,BP                   ;pointer to end of buffer
        SUB     CX,DX                   ;dif in pointers is number of bytes
        MOV     BX,1                    ;to standard output
        sys     WRITE                   ;write 'em out
        JC      BADWRT                  ;some bizarre error -> flag it
        CMP     AX,CX                   ;did we write what was expected?
        JZ      WRTOK                   ;yes, say bye bye
BADWRT:

;;;;;   mov     ax,msg_NoDisk           ;AN000; Strange write error
;;;;;   mov     dh,-1                   ;AN003; class: extended error
;;;;;   call    error_exit              ;AN000; Bye bye
        mov     al,RETCODE_ERROR        ;AN000; return an error code (errorlevel)
        sys     EXIT                    ;AN000;
WRTOK:
        MOV     AL,RETCODE_NOERROR      ;AN000; Errorlevel 0 (No error!)
        sys     EXIT                    ;bye!

        PAGE   ;
;************************************************************
;*
;*   SUBROUTINE NAME:      display_msg
;*
;*   SUBROUTINE FUNCTION:
;*         Display the requested message to the specified handle
;*
;*   INPUT:
;*      1)   AX = Number of the message to be displayed.
;*      2)   BX = Handle to be written to.
;*
;*   OUTPUT:
;*      The message corresponding to the requested msg number will
;*      be written to the requested handle. There is no substitution
;*      text in SORT.
;*
;*   NORMAL EXIT:
;*      Message will be successfully written to requested handle.
;*
;*   ERROR EXIT:
;*      None.  Note that theoretically an error can be returned from
;*      SYSDISPMSG, but there is nothing that the application can do.
;*
;*   INTERNAL REFERENCES:
;*      System Display Message service routines
;*
;*   EXTERNAL REFERENCES:
;*      None
;*
;************************************************************

display_msg     proc    near            ;AN000;
        push    ds                      ;AN000; save DS value
        push    cs                      ;AN000; get DS addressability
        pop     ds                      ;AN000;

        xor     cx,cx                   ;AN004; ;AN000;  No substitution text
;;      mov     dh,-1                   ;AN003;  Message class
                                        ; 1=DOS Extended error
                                        ; 2=DOS Parse error
                                        ; -1=Utility message
        mov     dl,0                    ;AN000;  DOS INT 21H function number to use for input
                                        ; 00H=No input, 01H=Keyboard input,
                                        ; 07H=Direct Console Input Without Echo,
                                        ; 08H=Console Input Without Echo, 0AH=Buffered Keyboard Input
        call    SYSDISPMSG              ;AN000;

        pop     ds                      ;AN000;  restore DS
        ret                             ;AN000;
display_msg     ENDP                    ;AN000;

        PAGE   ;
;************************************************************
;*
;*   SUBROUTINE NAME:      parse
;*
;*   SUBROUTINE FUNCTION:
;*         Call the DOS PARSE Service Routines to process the command
;*         line. Search for valid switches (/R and /+n) and take
;*         appropriate action for each. Display error message and
;*         terminate on error.
;*
;*   INPUT:        None
;*
;*   OUTPUT:       None
;*
;*   NORMAL EXIT:
;*
;*         If /R specified, then patches code to perform reverse sort
;*         by changing JAE to a JB.
;*
;*         If /+n entered, COLUMN will be set to "n," otherwise COLUMN
;*         will be set to 1.
;*
;*   ERROR EXIT:
;*
;*         If user enters any parameter or switch other than /R or /+n,
;*         or an invalid value for "n", then this routine will display
;*         the "Invalid Parameter" error message and terminate with
;*         errorlevel 1.
;*
;*   EXTERNAL REFERENCES:
;*         System parse service routines
;*         INT21 - GET PSP Function Call 062h
;*
;************************************************************

parse   proc    near                    ;AN000;

        sys     GetCurrentPSP           ;AN000; Get PSP address, returned in BX

        mov     ds,bx                   ;AN000; Put PSP Seg in DS
        mov     si,081h                 ;AN000; Offset of command line in PSP
        cmp     byte ptr ds:080h,0      ;AN000; Check length of command line
        je      end_parse               ;AN000; If 0 len, the we are done parsing
        xor     cx,cx                   ;AN000; Number of parms processed so far = 0
        push    cs                      ;AN000; Put CS
        pop     es                      ;AN000;  in ES
;---------------------------------
;- Loop for each operand at DS:SI (Initially PSP + 081h)
;---------------------------------
parse_loop:                             ;AN000;
        mov     di,offset parms         ;AN000; Address of parse control block
        xor     dx,dx                   ;AN000; Reserved
        call    sysparse                ;AN000; Parse parm at DS:SI
        cmp     ax,EOL                  ;AN000; Q: Are we at end of command line?
        je      end_parse               ;AN000;  YES: We are done
        and     ax,ax                   ;AN004; ;AN000;  NO:  Q: Any errors?
        jne     parse_error             ;AN000;   YES: Display msg and terminate
        mov     bx,sb_synonym           ;AN000; Get offset of switch entered
;----------------------------------
;- If user said /R, then patch code
;----------------------------------
        cmp     bx,offset rev_sw        ;AN000; If user specified /R
        jne     check_column            ;AN000;
        mov     cs:code_patch,072h      ;AN000; Sleazy patch to make reverse order sort
        jmp     parse_loop              ;AN000; Look for another parm

;---------------------------------------------
;- If user said /+n, then save COLUMN index
;---------------------------------------------
check_column:                           ;AN000;
        cmp     bx,offset col_sw        ;AN000; Q: Did user specified /+n ?
        jne     switch_error            ;AC003;  No:  Unrecognized parm
        mov     ax,sb_value             ;AN000;  Yes: Get number entered by user
        mov     column,ax               ;AN000;       Set up column to begin sort
        jmp     parse_loop              ;AN000;       Check for next parm

;------------------------------------------------------------
;- If any other parameter specified, display message and die
;------------------------------------------------------------
switch_error:                           ;AN003;
        mov     ax,Msg_switch           ;AN003;
parse_error:                            ;AN000;
        mov     dh,2                    ;AN003;  class: parse error
        call    error_exit              ;AN000;  Terminate utility

end_parse:                              ;AN000;
        ret                             ;AN000;
parse   endp                            ;AN000;

        PAGE   ;
;************************************************************
;*
;*   SUBROUTINE NAME:   error_exit
;*
;*   SUBROUTINE FUNCTION:
;*      Displays the message number in AX to the standard
;*      error device, then terminates with errorlevel 1.
;*
;*   INPUT:     AX = Message number
;*
;*   INTERNAL REFERENCES:
;*      display_msg
;*
;*   EXTERNAL REFERENCES:
;*      INT 021h - Terminate Function 043h
;*
;************************************************************
error_exit      proc    near            ;AN000;
        call    prt_sort                ;AN003;
        mov     bx,STDERR               ;AN000; output to standard error
        xor     cx,cx                   ;AN004; ;AN003;
        call    display_msg             ;AN000; and write it out
        mov     al,RETCODE_ERROR        ;AN000; return an error code (errorlevel)
        sys     EXIT                    ;AN000;
        ret                             ;AN000;  Meaningless RET
error_exit      endp                    ;AN000;


;************************************************************
;*
;*   SUBROUTINE NAME:   match_codepages
;*
;*   SUBROUTINE FUNCTION:
;*      Check to see if Code Page Support is active. If so,
;*      check code page of input and output handles. If the
;*      source file has a code page file tag AND the target
;*      handles code page is different, then set code  page
;*      of the target to that of the source.
;*
;*   INTERNAL REFERENCES:
;*      none
;*
;*   EXTERNAL REFERENCES:
;*      INT 021h - Check CPSW
;*      INT 021h - Get Extended Attributes by Handle
;*      INT 021h - Set Extended Attributes by Handle
;*
;************************************************************

match_codepages proc    near            ;AN000;

;-----------------------------------
; Check status of Code page support
;-----------------------------------
        push    es                      ;AN000; Save ES register
        push    ds                      ;AN001; Save DS register
;
        mov     ax,cs                   ;AN001; ES, DS -> CS
        mov     ds,ax                   ;AN001;
        mov     es,ax                   ;AN001;
;
        mov     ax,GetCPSW              ;AN000; Get CPSW state, assume support is OFF
        int     021h                    ;AN000; DL: 0=NotSupported,1=Supported
        cmp     dl,1                    ;AN000; CPSW supported if DL=1
        jne     done_cpsw               ;AN000; If not supported, we're done
;-----------------------------------
; Get Code Pages of STDIN and STDOUT
;-----------------------------------
        mov     ax,GetExtAttr           ;AN000; Get Extended Attributes by Handle
        mov     bx,STDOUT               ;AN000; For Standard output device
        mov     di,offset cp_list       ;AC001; Return buffer address
        mov     si,offset cp_qlist      ;AN001; Query the code page attribute
        mov     cx,cp_len               ;AN001; return buffer length
        int     021h                    ;AN000;
        jc      done_cpsw               ;AN000; Error condition, let system handle
        mov     ax,cp                   ;AN000; Save target code page
        mov     tgt_cp,ax               ;AN000;  for later reference

        mov     ax,GetExtAttr           ;AN000; Get Extended Attributes by Handle
        xor     bx,bx                   ;AN004; ;AN000; bx = STDIN (0)  For Standard input device
        mov     di,offset cp_list       ;AC001; Return buffer address
        mov     si,offset cp_qlist      ;AN001; Query the code page attribute
        mov     cx,cp_len               ;AN001; return buffer length
        int     021h                    ;AN000;
        jc      done_cpsw               ;AN000; Error condition, let system handle
        mov     ax,cp                   ;AN000; Save source code page
        mov     src_cp,ax               ;AN000;  for later reference

        mov     ax,src_cp               ;AN000; Get source codepage
        and     ax,ax                   ;AN004; ;AN000; IF no codepage
        je      done_cpsw               ;AN000;   THEN no action required;
        cmp     ax,tgt_cp               ;AN000; IF src_cp = tgt_cp
        je      done_cpsw               ;AN000;   THEN no action required;
;-------------------------------------
;- Set CP of target to that of source
;-------------------------------------
        mov     cp_reset,TRUE           ;AN000; Set flag indicating change
        mov     ax,SetExtAttr           ;AN000; Set Extended Attributes by Handle
        mov     bx,STDOUT               ;AN000; For Standard output device
        mov     di,offset cp_list       ;AC001; Input buffer address
        int     021h                    ;AN000;

done_cpsw:                              ;AN000;
        pop     ds                      ;AN001; Restore DS register
        pop     es                      ;AN000; Restore ES register
        ret                             ;AN000;
match_codepages endp                    ;AN000;

        PAGE   ;
;************************************************************
;*
;*   SUBROUTINE NAME:   prt_sort
;*
;*   SUBROUTINE FUNCTION:
;*      Preceeds all error messages with "SORT: ".
;*
;*   INTERNAL REFERENCES:
;*         none
;*   EXTERNAL REFERENCES:
;*         none
;************************************************************
prt_sort proc near                      ;AN003;
        push    ax                      ;AN003;
        push    dx                      ;AN003;
;
        mov     dh,-1                   ;AN003;
        mov     ax,Msg_sort             ;AN003;
        xor     cx,cx                   ;AN004; ;AN003;
        mov     bx,STDERR               ;AN003;
        call    display_msg             ;AN003;
;
        pop     dx                      ;AN003;
        pop     ax                      ;AN003;
;
        ret                             ;AN003;
prt_sort endp                           ;AN003;


        PAGE   ;
;--------------------
.xlist
.xcref
INCLUDE parse.asm
include msgdcl.inc
.cref
.list
;--------------------

CODE    ENDS







CONST   SEGMENT PUBLIC BYTE

        extrn   table:byte

CONST   ENDS




SUBTTL  Initialized Data
;-------------------------------
;---    Stack Segment
;-------------------------------
CSTACK   SEGMENT STACK
         db      (362 - 80h) + 96 dup (0) ;(362 - 80h) == New - Old IBM
                                          ;interrupt reqs. == size of growth
CSTACK   ENDS

        END     SORT
