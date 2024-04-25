      title   DOS FIND  Utility
; 0
;********************************************************************
;*
;*   UTILITY NAME:         find.exe
;*
;*   SOURCE FILE NAME:     find.asm
;*
;*   STATUS:               Find utility, DOS Version 4.0
;*
;*   SYNTAX (Command line)
;*
;*         FIND [/V][/C][/N] "string" [[d:][path]filename[.ext]...]
;*
;*         where:
;*
;*           /V - Display all lines NOT containing the string
;*           /C - Display only a count of lines containing string
;*           /N - Display number of line containing string
;*
;*
;*   UTILITY FUNCTION:
;*
;*     Searches the specified file(s) looking for the string the user
;*     entered from the command line.  If file name(s) are specifeied,
;*     those names are displayed, and if the string is found, then the
;*     entire line containing that string will be displayed.  Optional
;*     parameters modify that behavior and are described above.  String
;*     arguments have to be enclosed in double quotes.  (Two double quotes
;*     if a double quote is to be included).  Only one string argument is
;*     presently allowed.  The maximum line size is determined by buffer
;*     size.  Bigger lines will bomb the program.  If no file name is given
;*     then it will asssume the input is coming from the standard Input.
;*     No errors are reported when reading from standard Input.
;*
;*
;*   EXIT:
;*    The program returns errorlevel:
;*      0 - OK, and some matches
;*      1 -
;*      2 - Some Error
;*
;*
;*   Revision History:
;*
;*    V1.1    8/23/82         M.A.U.  (Microsoft)
;*
;*    V1.2    9/22/82         M.A.U.  (Microsoft)
;*              Added the -c and -n options
;*
;*            9/23/82         M.A.U.  (Microsoft)
;*              Added DOS version number control
;*
;*            10/07/82  Rev.2         M.A.U.  (Microsoft)
;*              Changed quote for double quotes, and added
;*            file name printing
;*
;*            10/20/82  Rev.3         M.A.U.  (Microsoft)
;*              Modified IBM name to FIND, and changed the text
;*            of some messages.
;*
;*            10/25/82  Rev.4         M.A.U.  (Microsoft)
;*              Changed name to FIND and all messages to the
;*            IBM form.
;*
;*            10/27/82  Rev.5         M.A.U.  (Microsoft)
;*              Made the correct exit on version check in case
;*            of a 1.x DOS.
;*
;*            11/4/82 Rev. 5          A.R. Reynolds  (Microsoft)
;*               Messages moved to external module
;*
;*            11/10/82  Rev. 6        M.A. U.  (Microsoft)
;*              Corrected problem with line numbers, and a problem
;*            with seeking for 0 chars.
;*
;*            03/30/83  Rev. 7        M.A. U.  (Microsoft)
;*              Added patch area for bug fixing.
;*
;*            04/14/83  Rev. 8        M.A. U.  (Microsoft)
;*              Made changes for Kanji characters. (ugh!)
;*
;*            12/17/84  Rev. 9        Zibo  (Microsoft)
;*              Fix boundary case for buffer containing exact line
;*
;*    V4.0 :  6/29/87                 Russ W (IBM)
;*           Lines commented with ;AN000;
;*              Add support for IBM Parse service routines
;*              Add support for IBM Message Retriever Service Routines
;*              Add support for Code Page File Tags
;*              Made PROCs out of all labels that were targets of a call (not commented with AN000)
;*              Removed patch area for "bug fixing"
;*
;*    V4.0 :  9/15/87                 Bill L, (IBM)
;*           ;AN001; = DCR 201, changes to extended attributes support
;*           ;AN002; = PTM 1090
;*           ;AN003; = DCR 191
;*           ;AN004; = PTM 1630
;*           ;AN005; = PTM 1643, PTM 1675, PTM 1754
;*           ;AN006; = DBCS support
;*           ;AN007; = Optimizations to save disk space on ship diskettes
;*
;**********************************************************************

;--------------------------
;-      MACRO DEFINITIONS
;--------------------------
BREAK   MACRO   subtitle
        SUBTTL  subtitle
        PAGE
ENDM


;---------------------------;
;-      INCLUDE FILES       ;
;---------------------------;
.xlist                      ;
.xcref                      ;
        INCLUDE SYSCALL.INC ;
        INCLUDE sysmsg.inc  ;   ;AN000; Include message equates and MACROS
        INCLUDE find.inc    ;   ;AN000; Include find equates and MACROS
.list                       ;
.cref                       ;
;---------------------------;

MSG_UTILNAME <FIND>             ;AN000;

;--------------------------
;-      EQUATES
;--------------------------
FALSE           equ     0
TRUE            equ     NOT FALSE

CR              equ     0dh             ;A Carriage Return
LF              equ     0ah             ;A Line Feed
quote_char      equ     22h             ;A double quote character


buffer_size     equ     4096            ;file buffer size
st_buf_size     equ     128             ;string arg. buffer size
fname_buf_size  equ     64              ;file name buffer size


;----- DOS EQUATES -----;
STDIN   equ     0                       ;AN000; Handle
STDOUT  equ     1                       ;AN000; Handle
STDERR  equ     2                       ;AN000; Handle

GetCPSW    equ  03303h                  ;AN000; Int 021h function call
GetExtAttr equ  05702h                  ;AN000; Int 021h function call
SetExtAttr equ  05704h                  ;AN000; Int 021h function call

ERROR_ACCESS_DENIED     equ     5       ;AN000; Int 021h error return

CPSWActive      equ     1               ;AN000; Indicates Code Page support is active
CPSWNotActive   equ     0               ;AN000; Just the opposite

ERRORLEVEL_ZERO equ     0               ;AN000; Termination error level
ERRORLEVEL_ONE  equ     1               ;AN000; Termination error level
ERRORLEVEL_TWO  equ     2               ;AN000; Termination error level

;------------------------
;-      MESSAGE EQUATES
;------------------------

msg_file_not_found      equ     2       ;AN000; File not found %s
msg_access_denied       equ     5       ;AN000; Access denied %s
msg_read_error          equ    30       ;AN000; Read error in %s
msg_inv_num_parm        equ     2       ;AN000; Invalid number of parameters
msg_inv_parm            equ    10       ;AN000; Invalid Parameter %s
msg_required_missing    equ     2       ;AN005; Required parameter missing
msg_find                equ     4       ;AN000; FIND:
msg_code_page_mismatch  equ    37       ;AN005; Code Page mismatch
msg_switch              equ     3       ;AN005; Invalid switch

;-----------------------
;--     Parser equates
;-----------------------
 
FarSW   equ     0                       ;AN000;
DateSW  equ     0                       ;AN000;
TimeSW  equ     0                       ;AN000;
FileSW  equ     1                       ;AN000;
CAPSW   equ     1                       ;AN000;
CmpxSW  equ     0                       ;AN000;
DrvSW   equ     0                       ;AN000;
QusSW   equ     1                       ;AN000;
NumSW   equ     0                       ;AN000;
KeySW   equ     0                       ;AN000;
SwSW    equ     1                       ;AN000;
Val1SW  equ     0                       ;AN000;
Val2SW  equ     0                       ;AN000;
Val3SW  equ     0                       ;AN000;

;------------------------
; SUBLIST Equates
;------------------------
Left_Align            equ     0      ;AN000; 00xxxxxx
Right_Align           equ     80h    ;AN000; 10xxxxxx

Char_Field_Char       equ     0      ;AN000; a0000000
Char_Field_ASCIIZ     equ     10h    ;AN000; a0010000

Unsgn_Bin_Byte        equ     11h    ;AN000; a0010001 - Unsigned Binary to Decimal character
Unsgn_Bin_Word        equ     21h    ;AN000; a0100001
Unsgn_Bin_DWord       equ     31h    ;AN000; a0110001

Sgn_Bin_Byte          equ     12h    ;AN000; a0010010 - Signed Binary to Decimal character
Sgn_Bin_Word          equ     22h    ;AN000; a0100010
Sgn_Bin_DWord         equ     32h    ;AN000; a0110010

Bin_Hex_Byte          equ     13h    ;AN000; a0010011 - Unsigned Binary to Hexidecimal character
Bin_Hex_Word          equ     23h    ;AN000; a0100011
Bin_Hex_DWord         equ     33h    ;AN000; a0110011

;------------------------------
; EXTENDED ATTRIBUTE Equates
;------------------------------
File_Type_None        equ     00000000b  ;AN001;  unspecified file type
File_Type_Text        equ     00100000b  ;AN001;  ASCII text file
File_Type_Rtl         equ     00100001b  ;AN001;  ASCII text file in RTL

EAISBINARY            equ     02h        ;AN001;  ea_type
EASYSTEM              equ     8000h      ;AN001;  ea_flags

;---------------------------------------
;-------------- CODE SEGMENT -----------
;---------------------------------------

code    segment public
            assume   cs:code
            assume   ds:nothing
            assume   es:nothing
            assume   ss:stack

        jmp start

;
;--------------------
.xlist
.xcref
INCLUDE parse.asm
.list
.cref
;--------------------

        EXTRN   heading:byte,heading_len:byte

;*********************************
;* Extended Attribute Structures *
;*********************************
querylist   struc                    ;AN001; ;query general list
qea_num     dw      1                ;AN001;
qea_type    db      EAISBINARY       ;AN001;
qea_flags   dw      EASYSTEM         ;AN001;
qea_namelen db      ?                ;AN001;
qea_name    db      "        "       ;AN001;
querylist   ends                     ;AN001;

cp_qlist    querylist <1,EAISBINARY,EASYSTEM,2,"CP">        ;AN001; ;query code page attr.

cp_list     label   word             ;AN001; ;code page attr. get/set list
            dw      1                ;AN001; ; # of list entries
            db      EAISBINARY       ;AN001; ; ea type
            dw      EASYSTEM         ;AN001; ; ea flags
            db      ?                ;AN001; ; ea return code
            db      2                ;AN001; ; ea name length
            dw      2                ;AN001; ; ea value length
            db      "CP"             ;AN001; ; ea name
cp          dw      ?                ;AN001; ; ea value (code page)
cp_len      equ     ($ - cp_list)    ;AN001;

;-------Save area for Code Pages
src_cp  dw      ?               ;AN000; Save area for source code page
tgt_cp  dw      ?               ;AN000; Save area for target code page
str_cp  dw      ?               ;AN005; Save area for search string code page



;-----------------------
;----- Misc  Data ------
bufferDB db     6 dup(0)        ;AN006;
dbcs_off dw     0               ;AN006;
dbcs_seg dw     0               ;AN006;
dbcs_len dw     0               ;AN006;

ccolon  db      ": "
n1_buf  db      "["
n2_buf  db      8 dup(0)                ;buffer for number conversion

errlevel        db      ERRORLEVEL_ZERO ;AN000; Errrorlevel save area

;----- OPTION FLAGS ----
; If a flag is set (0ffh) then the option has been selected, if
;reset (0) then it has been not. All options are reset initially.
; NOTE: the order of this table has to remain consistent with the
;options dispatch code. If any changes are made they have to
;correspond with the code.

opt_tbl:

v_flag   db      FALSE           ;AN000; Set to FALSE
c_flag   db      FALSE           ;AN000; Set to FALSE
n_flag   db      FALSE           ;AN000; Set to FALSE


;----- LINE COUNTERS
mtch_cntr dw    0                       ;matched lines counter
line_cntr dw    0                       ;line counter

;-------------------------------------------
;-      MESSAGE RETRIEVER SUBSTITUTION LIST
;-------------------------------------------

MSG_SERVICES <MSGDATA>          ;AN000;

sublist label dword             ;AN000;
sl_size db      11              ;AN000; SUBLIST Size, in bytes
sl_res  db      0               ;AN000; reserved
sl_ptr_o dw     ?               ;AN000; Offset  PTR to data item
sl_ptr_s dw     ?               ;AN000; Segment PTR to data item
sl_n    db      0               ;AN000; n of %n
sl_flag db      ?               ;AN000; Data-Type flags
sl_maxw db      0               ;AN000; Max width
sl_minw db      0               ;AN000; Min width
sl_pad  db      ' '             ;AN000; Pad character


parm         db ?               ;AN000; Save area for invalid parm
cpsw_state   db CPSWNotActive   ;AN000; Save area indicating state of Code Page Support

;******************************************************************************
;*                                               PARSER DATA STRUCTURES FOLLOW
;******************************************************************************

parms   label   byte            ;AN000;
        dw      parmsx          ;AN000; POINTER TO PARMS STRUCURE
        db      1               ;AN000; DELIMITER LIST FOLLOWS
        db      1               ;AN000; NUMBER OF ADDITIONAL DELIMITERS
        db      ";"             ;AN000; ADDITIONAL DELIMITER

parms1  label   byte            ;AN005;
        dw      parmsx1         ;AN005; POINTER TO PARMS STRUCURE
        db      1               ;AN005; DELIMITER LIST FOLLOWS
        db      1               ;AN005; NUMBER OF ADDITIONAL DELIMITERS
        db      ";"             ;AN005; ADDITIONAL DELIMITER

;------------------------------
;- STRUCTURE TO DEFINE FIND SYNTAX REQUIREMENTS
;------------------------------
parmsx  label   word            ;AN000;
        db      1,2             ;AN000; THERE ARE BETWEEN 1 AND 2 POSITIONAL PARMS
        dw      pos1            ;AN000; POINTER TO POSITIONAL DEFINITION AREA
        dw      pos2            ;AN000; POINTER TO POSITIONAL DEFINITION AREA
        db      1               ;AN000; THERE IS 1 SWITCH DEF AREA FOR "/V, /C, AND /N"
        dw      sw1             ;AN000; POINTER TO FIRST SWITCH DEFINITION AREA
        dw      0               ;AN000; THERE ARE NO KEYWORDS IN FIND SYNTAX

parmsx1 label   word            ;AN005;
        db      0,0             ;AN005; THERE ARE BETWEEN 1 AND 2 POSITIONAL PARMS
        db      1               ;AN005; THERE IS 1 SWITCH DEF AREA FOR "/V, /C, AND /N"
        dw      sw1             ;AN005; POINTER TO FIRST SWITCH DEFINITION AREA
        dw      0               ;AN005; THERE ARE NO KEYWORDS IN FIND SYNTAX

        ;------------------------------
        ;- STRUCTURE TO DEFINE POSITIONAL PARM
        ;------------------------------
pos1    label   word            ;AN000;
        dw      0080h           ;AN000; QUOTED STRING, REQUIRED
        dw      0000h           ;AN000; NO CAPITALIZE
        dw      ret_buff        ;AN000; PLACE RESULT IN RET_BUFF
        dw      novals          ;AN000; NO VALUE LIST
        db      0               ;AN000; NO KEYWORDS

        ;------------------------------
        ;- STRUCTURE TO DEFINE POSITIONAL PARM
        ;------------------------------
pos2    label   word            ;AN000;
        dw      0203h           ;AN000; FILE NAME, OPTIONAL, REPEATS ALLOWED
        dw      0001h           ;AN000; CAPITALIZE BY FILE TABLE
        dw      ret_buff        ;AN000; PLACE RESULT IN RET_BUFF
        dw      novals          ;AN000; NO VALUE LIST
        db      0               ;AN000; NO KEYWORDS


        ;------------------------------
        ;- STRUCTURE TO DEFINE THE SWITCHES
        ;------------------------------
sw1     label   word            ;AN000;
        dw      0               ;AN000; NO MATCH FLAGS
        dw      2               ;AN005; capitalize
        dw      ret_buff        ;AN000; PLACE RESULT IN RET_BUFF
        dw      novals          ;AN000; NO VALUE LIST
        db      3               ;AN000; THREE SWITCHES IN FOLLOWING LIST
n_swch  db      "/N",0          ;AN000;
v_swch  db      "/V",0          ;AN000;
c_swch  db      "/C",0          ;AN000;


        ;------------------------------
        ;- VALUE LIST DEFINITION FOR NO VALUES
        ;------------------------------
novals  label   word            ;AN000;
        db      0               ;AN000;  VALUE LIST


        ;------------------------------
        ;- RETURN BUFFER FOR POSITIONAL PARAMETERS
        ;------------------------------
ret_buff        label   word    ;AN000;
rb_type         db      ?       ;AN000; TYPE RETURNED
rb_item_tag     db      ?       ;AN000; SPACE FOR ITEM TAG
rb_synonym      dw      ?       ;AN000; ES:rb_synonym points to synonym
rb_value_lo     dw      ?       ;AN000; SPACE FOR VALUE
rb_value_hi     dw      ?       ;AN000; SPACE FOR VALUE




did_file        db      FALSE   ;AN004;  if true then already processed a file
got_eol         db      FALSE   ;AN004;  if false then possibly more filenames on command line
got_filename    db      FALSE   ;AN004;  if true then parser found a filename on command line
got_srch_str    db      FALSE   ;AN000;  if true then parser found search string on command line
ordinal         dw      0       ;AN000; parser ordinal
crlf            db      CR,LF   ;AN000;


;
;************************************************************
;*
;*   SUBROUTINE NAME:      main
;*
;*   SUBROUTINE FUNCTION:
;*         Process the command line.  If there are no errors, then open
;*         the specified files, search for string, display it to the
;*         standard output device.
;*
;*   INPUT: Command line (described in program header)
;*
;*   OUTPUT:
;*         Files will be opened and read in.  Regardless of the command
;*         line parameters entered by the user, output will be written
;*         to the standard output device handle 1.
;*
;*   NORMAL EXIT:
;*         File(s) opened (if not STDIN), read successfully, and closed.
;*         Display requested information.
;*
;*   ERROR CONDITIONS:
;*         Incorrect DOS version
;*         Invalid number of parameters
;*         Syntax error
;*         Access denied
;*         File not found
;*         Invalid Parameter
;*         Read error in
;*
;*   INTERNAL REFERENCES:
;*         bin2asc
;*         clr_cntrs
;*         is_prefix
;*         next_kchar
;*         print_count
;*         prout
;*         prt_err
;*         prt_err_2
;*         prt_file_name
;*         prt_lcntr
;*
;**************************************************************************

        MSG_SERVICES <FIND.ctl,FIND.cla,FIND.cl1,FIND.cl2>      ;AN000;
        MSG_SERVICES <DISPLAYmsg,LOADmsg,CHARmsg,NOCHECKSTDIN>  ;AN003; Make retriever services available
START:

        mov     ax,cs                   ;load ES to the right area,
        mov     es,ax                   ;
        mov     ds,ax                   ;

        call    sysloadmsg              ;AN000; Preload messages, Check DOS Version.
        jnc     Set_for_parse           ;AN000; If no error, parse command line

        call    prt_find                ;AN005;
        call    sysdispmsg              ;AN005;

        mov     ah,Exit                 ;AN000; Terminate new way
        mov     al,0                    ;AN000; Errorlevel 0 (Compatible!)
        int     021h                    ;AN000; Bye bye!

;-----------------------------------
;- DOS version is ok. Parse cmd line
;-----------------------------------
Set_for_parse:
        call    get_dbcs_vector                         ;AN006; ;Get DOS dbcs table vector
;
        mov     ah,GetCurrentPSP                        ;AN000; Get PSP address, returned in BX
        int     021h                                    ;AN000;
        mov     ds,bx                                   ;AN000; Put PSP Seg in DS
        mov     si,081h                                 ;AN000; Offset of command line in PSP
        xor     cx,cx                                   ;AN000; Number of args processed so far = 0
        mov     cs:ordinal,cx                           ;AN000; init parser ordinal

;--------------------------------------
; See if there was nothing entered
;--------------------------------------
        cmp     byte ptr ds:080h,0                      ;AN000; Check length of command line,
        jne     p_parse                                 ;AN005; Go process the parameters
        mov     ax,msg_inv_num_parm                     ;AN000; No parms, too bad!
        mov     dh,2                                    ;AN005; message class
        call    display_and_die                         ;AN000; Tell the unfortunate user
p_parse:
        mov     cs:got_filename,FALSE        ;AN004; input file default is STDIN

        push    cs                      ;A0005; ensure es is correct
        pop     es                      ;AN005;

        call    clr_cntrs               ;AN005; set all counters to zero
        mov     cx,cs:ordinal           ;AN005; init parser ordinal
        call    pre_parse               ;AN005;
PARSER:
        push    cs                      ;A0000; ensure es is correct
        pop     es

        call    clr_cntrs               ; set all counters to zero
        mov     cx,cs:ordinal           ;AN000; init parser ordinal
        call    parse                   ;AN000; Parse command line

        push    si                      ;AN000; Save ptr to remaining command line
        push    ds

        push    cs                      ;Load new DS with CS
        pop     ds
        mov     cs:ordinal,cx           ;AN000; Save parser ordinal

;---------------------
; get filespec size
;---------------------
        mov     cs:file_name_buf,di     ;save buffer offset from parser
        xor     bx,bx                   ;AN000;indicate no save again
        call    get_length              ;AN000;get filespec length
        mov     es:file_name_len,ax     ;save the name length

;---------------------
;- Check current state of CPSW
;---------------------
save_src_cp:
        mov     ax,GetCPSW              ;AN000; Get CPSW state, assume support is OFF
        int     021h                    ;AN000; DL: 0=NotSupported,1=Supported
        jc      open_read               ;AN000; If error, assume CPSW inactive
        mov     cs:cpsw_state,dl        ;AN000; Save current state
        and     dl,dl                   ;AN007; ;AN000; If inactive,   (same as CMP dl,0)
        je      open_read               ;AN000;   do nothing

;-------Code Page Switching is loaded and active!
;-------Save codepage of target handle ----------
        mov     bx,STDOUT               ;AN000; For Standard output device
        call    get_cp                  ;AN000; Get the current codepage
        jc      open_read               ;AN000; Error condition
        mov     ax,cs:cp                ;AN000; Save target code page
        mov     cs:tgt_cp,ax            ;AN000;   for later reference
        xor     bx,bx                   ;AN007; ;AN005; bx=STDIN. For search string
        call    get_cp                  ;AN005; Get the code page
        jc      open_read               ;AN005; Error condition
        mov     ax,cs:cp                ;AN005; Save code page value
        mov     cs:str_cp,ax            ;AN005;  ..

;---------------------
;-      OPEN FILE FOR READING
;---------------------
open_read:
        push    cs                      ;Load new DS with CS
        pop     ds
        cmp     cs:got_filename,TRUE    ;AN004; using STDIN
        je      o_cont                  ;AN004; no, open the file
        xor     ax,ax                   ;AN007; ;AN004; file handle (ax) = STDIN
        jmp     short cp_check          ;AN007; ;AN004; skip open of file
o_cont:                                 ;AN004;
        mov     dx,cs:file_name_buf     ;AC000;addrss. of the file name
openit:
        mov     ah,open
        mov     al,0                    ;file open for reading
        int     021h                    ;call the DOS
        ljc      do_open_error           ;AN000;
;-------Open was successful. Make sure codepages are the same
cp_check:
        cmp     cs:cpsw_state,CPSWNotActive ;AN000; Is Code Page support active
        je      say_name                ;AN000; No, continue

        push    ax                      ;AN000; Save source handle
        mov     bx,ax                   ;AN000; Source handle in BX
        call    get_cp                  ;AN000; Get codepage of source file

        mov     ax,cs:cp                ;AN000; Place source CP in ax
        cmp     ax,cs:str_cp            ;AN005; search string code page = src file code page ?
        je      c_cont                  ;AN005; yes, they are the same, ok
        and     ax,ax                   ;AN007; ;AN005; src filename cp = 0
        je      c_cont                  ;AN005; yes, this cp=0 is ok.
        mov     ax,msg_code_page_mismatch ;AN005; Error, code page mismatch
        mov     dh,1                    ;AN005; message class
        call    display_and_die         ;AN005; bye!
c_cont:
        cmp     ax,cs:tgt_cp            ;AN000; Is same as target cp ?
        je      cp_match                ;AN000; Yes?  Do nothing

        mov     bx,STDOUT               ;AN000; Standard output device
        call    set_cp                  ;AN000; Set codepage to that of source
cp_match:
        pop     ax                      ;AN000; Restore handle
;---------------------
;-      PRINT FILE NAME
;---------------------
say_name:
        push    ax                      ;save file handle
        cmp     cs:got_filename,FALSE   ;AN004; using STDIN
        je      xx1                     ;AN004; yes, don't print a filename
        mov     dx,offset heading
        mov     cl,cs:heading_len
        xor     ch,ch
        call    prout

        mov     dx,cs:file_name_buf     ;AC000;
        mov     cx,cs:file_name_len
        call    prout

        cmp     cs:c_flag,TRUE          ;count only flag set?
        je      xx1

        mov     dx,offset crlf
        mov     cx,2
        call    prout
xx1:
        pop     ax

;---------------------
;-      Fill Buffer for Matching
;---------------------
fill:
        mov     bx,ax                   ;retrieve handle
refill:
        mov     dx,offset buffer        ;data buffer addrss.
        mov     cx,buffer_size
        mov     ah,read
        int     021h
        jnc     no_read_error           ;if carry then read error
        jmp     read_error
no_read_error:
        or      ax,ax                   ;if ax=0 then all done
        jnz     Truncate
DoNullRead:
        cmp     cs:c_flag,TRUE          ;count only flag set?
        jne     sj2
        call    print_count
sj2:
        and     bx,bx                  ;Using STD IN?
        jnz     regular
        jmp     foo                     ;if so: all done, exit
regular:
        mov     ah,close                ;otherwise close the file
        int     021h
        jmp     scan_rest               ;get another file

do_open_error:
        jmp     open_error              ;AN000;
;---------------------------
; We have read in an entire buffer.  Scan for a ^Z and terminate the buffer
; there.  Change only CX
;---------------------------
Truncate:
        push    di
        push    cx
        push    es
        mov     di,dx
        mov     cx,ax
        mov     ax,ds
        mov     es,ax
        mov     al,1Ah
        CLD
        repnz   scasb
;---------------------------
; If zero is set, the the previous character is a ^Z.  If it is reset then
; the previous character is the end of buffer.  With ^Z, we back up over the
; char.
;---------------------------
        jnz     chop
        dec     di
chop:
        mov     ax,di
        sub     ax,dx                   ; get true length of buffer
        pop     es
        pop     cx
        pop     di
        or      ax,ax
        jz      DoNullRead

;---------------------------
;----- MATCH ROUTINE
;---------------------------
;Note: If input is being taken from a file the stack contains
; (from top to bottom):
;       - Pointer to the next command in the command line
;       - Pointer to the program segment prefix (to be loaded into
;         DS to access the command line.
; if the input is from the standard input then NONE of it will be
; in the stack.
;---------------------------

go_match:
        push    bx                      ;save the file handle
        mov     bp,offset buffer        ;ptr to first line of file
;---------------------------
; At this point we must check to make sure there is AT LEAST one LF in the
;  buffer. If there is not, then we must insert one at the end so we
;  don't get stuck trying to get one complete line in the buffer when
;  we can't cause the buffer ain't big enough.
;---------------------------
        push    ax                      ; Save true buffer size
        mov     cx,ax                   ; scan whole buffer
        mov     al,LF                   ; for a LF
        mov     di,bp                   ; start of buffer
        repnz   scasb
        pop     ax                      ; recover buffer size
        mov     di,ax                   ;displacement from beg of buffer
        jnz     last_line               ; No line feeds, must insert one
;---------------------------
; Check to see if we reached EOF (return from READ less than buffer_size).
;  If EOF we must make sure we end with a CRLF pair.
;---------------------------
        cmp     ax,buffer_size-1        ;last line of the file?
        jg      no_last_line            ;nope
last_line:                              ;if yes, add a CRLF just in case
        mov     bx,bp
        cmp     byte ptr[bx+di-1],LF    ;finished with a LF?
        je      no_last_line            ;yes, it's an OK line.
        mov     byte ptr[bx+di],CR      ;put a CR at the end of the data
        inc     di
        mov     byte ptr[bx+di],LF      ;put a LF ...
        inc     di

no_last_line:
        push    di                      ;save the # of chars. in the buffer
        push    bp
        mov     dx,cs:st_length         ;length of the string arg.
        dec     dx                      ;adjust for later use
        jmp     short try_again

more_stuff_o:
        jmp     more_stuff

;----- SCAN LINES IN THE BUFFER FOR A MATCH -------------------------;
;Note: at this point the stack contains (from top to bottom):
;       - Stuff mentioned before
;       - File Handle
;       - Number of chars. left in the buffer from the next line.
;       - Addrs. of the next line in the buffer.
;
; plus, DX has the adjusted length of the string argument.
;
; We are about to begin scanning a line.  We start by determining if there is
; a complete line in the buffer.  If so, we scan for the char.  If NOT, we go
; and grab new info.
;---------------------------
try_again:
        pop     bp                      ;addrs. of next line in the buffer
        mov     di,bp                   ;points to beg. of a line
        pop     cx                      ;get # of chars left in the buffer
        mov     bx,cx                   ;save in case a non-complete line
        mov     al,LF                   ;search for a Line Feed
        jcxz    more_stuff_o            ;no chars left in buffer
        repnz   scasb
        jnz     more_stuff_o            ;no full line left in buffer
        push    cx                      ;save chars left in buffer
        push    di                      ;points to beg. of next line
        mov     cx,di
        sub     cx,bp                   ;length of the current line
        mov     bx,cx                   ;save in case it has a match
        dec     cx                      ;Discount the LF we found
        cmp     byte ptr ES:[DI-2],CR   ; Is there a CR to discount too?
        jnz     NO_SECOND_DEC           ; No there is not.
        dec     cx                      ;CR character discounted
NO_SECOND_DEC:
        inc     cs:line_cntr            ;increment line counter
        jcxz    try_again_opt           ;if line empty go to next line
        mov     di,bp                   ;pointer to the beg. of current line
another_char:
;---------------------------
; On entry:
;       BX      line length
;       CX      adjusted line length
;       DX      adjusted string argument length
;       DI      points to beg. of line
;---------------------------
        push    dx                      ;save for next line
lop:
        pop     dx
        push    dx
        inc     dx                      ;different algorithm!
        mov     si,offset st_buffer     ;pointer to beg. of string argument

comp_next_char:
        push    di
        mov     di,si
        call    is_prefix               ;check for a prefix char
        pop     di
        jnc     nopre
        lodsw
        cmp     cx,1                    ; Can not compare a two byte char
        jbe     try_again_opt1          ; if there is only one available
        cmp     ax,word ptr [di]
        jz      kmatch1
        jmp     short back_up           ;AN007;

nopre:
        lodsb
        cmp     al,byte ptr [di]
        jz      kmatch
back_up:
        pop     ax                      ; Original length of comp string
        push    ax
        inc     ax
;---------------------------
    ; Our match failed IN THE MIDDLE of the string (partial match). We need
    ;  to back up in the line to the NEXT char after the one which matched
    ;  the first char of the search string and try again. The amount to
    ;  back up to where we started is ax-dx (the result MAY be 0, this is OK).
    ;  we then need to skip ONE char in the line.
;---------------------------
        sub     ax,dx                   ; AX = AX-DX
        sub     di,ax                   ; Do the back up.
        add     cx,ax                   ; restore count too!
        call    next_kchar              ;no match, advance di to next kanji
        jc      try_again_opt1          ;not enough chars left in line
        jmp     short lop               ;try another char in line

try_again_opt1:
        pop     dx
        jmp     short try_again_opt     ;AN007;


kmatch1:
        dec     dx                      ;last char had prefix so it was
                                        ; long.
kmatch:
        dec     dx
        jz      a_matchk                ; no chars left: a match!
        call    next_kchar
        jc      try_again_opt1
        jmp     comp_next_char          ; loop if chars left in arg.

a_matchk:
        pop     dx
        cmp     cs:v_flag,TRUE          ;is flag set?
        jne     prt_line                ;no, print the line
        jmp     try_again

;---------------------------
;-      NO MATCH: CHECK FOR THE v OPTION
;---------------------------
try_again_opt:
        cmp     cs:v_flag,TRUE          ;is flag set?
        jne     try_again               ;no goto next line

;---------------------------
;-      PRINT THE LINE WITH THE MATCH
;Note: at this point the stack contains (top to bottom)
;       - Stuff mentioned before
;
; plus, BP points to begginig of the current line, BX has the length
;of the current line including the CRLF, and DX the adjusted length of
;the string argument.
;---------------------------

prt_line:
        cmp     cs:c_flag,TRUE          ;is count only flag set?
        jne     no_c_flg
        inc     cs:mtch_cntr            ;yes, increment counter
        jmp     try_again

no_c_flg:
        push    dx                      ;save the adjusted string arg. length
        cmp     cs:n_flag,TRUE           ;is line number flag set?
        jne     no_n_flg
        call    prt_lcntr
no_n_flg:
        mov     dx,bp
        mov     cx,bx
        call    prout
        pop     dx                      ;restore
        jmp     try_again

;----- READ MORE TEXT LINES INTO THE BUFFER -------------------------;
; The scanning routines have detected that the buffer does not
;contain a full line any more. More lines have to be read into the
;buffer. But first perform a seek on the file in order to re-read
;the non-complete line into the begining of the buffer.
; Uppon entry BP contains points to the begining of the non-complete
;line, and BX has the number of characters left in the buffer.
; The Stack contains (top to bottom):
;       - Pointer to the next command in the command line
;       - Pointer to the program segment prefix (to be loaded into
;         DS to access the command line).
;       - File handle.

more_stuff:
        mov     dx,bx                   ;get chars left in buffer
        pop     bx                      ;get the handle
        or      dx,dx                   ;are there 0 left?
        jz      no_seek                 ;yes, do not seek
        neg     dx                      ;form two's complement
        mov     cx,-1
        mov     al,1                    ;seek from the current position
        mov     ah,lseek                ;seek on file
        int     021h
        jc      read_error
no_seek:
        jmp     refill                  ;no errors: refill the buffer
read_error:
        and     bx,bx                   ;AN007; ;Using STD IN?
        je      foo                     ;if so: all done, exit
        mov     ah,close                ;close the file
        int     021h
;---------------
;------ Set message number and go display it

        mov     ax,msg_read_error       ;AN000; Read error message
        jmp     short r_error           ;AN007;

;---------------------
;-      PRINT ERRORS
;---------------------
open_error:
        cmp     ax,ERROR_ACCESS_DENIED  ;AN000;
        jnz     DoNorm

        mov     ax,msg_access_denied    ;AN000; Message for Access Denied
        jmp     short r_error           ;AN007; ;AN000; Do the rest

DoNorm:                                 ;AN000;
        mov     ax,msg_file_not_found   ;AN000; Message for File Not Found

r_error:
        call    prt_find                ;AN005;
        mov     cs:sl_ptr_s,ds          ;AN000; Save segment of subst text
        mov     cx,cs:file_name_buf     ;AN000;
        mov     cs:sl_ptr_o,cx          ;AN000; Save offset  of subst text
        mov     cs:sl_flag,left_align+char_field_ASCIIZ ;AN000; Type of insertion text
        mov     bx,STDERR               ;AN000; Sent to STD OUT
        mov     cx,1                    ;AN000; One substitution string
        mov     dh,1                    ;AN000; Its a utility message

        call    display_msg             ;AN000; Display rror message

;---------------------
;-      SCAN THE REST OF THE COMMAND LINE
;---------------------
scan_rest:
        pop     ds                      ;restore pointer to comm. line
        pop     si                      ;restore pointer to next comm.
        mov     cs:did_file,TRUE        ;AN004; tell parser we did a file, so if it doesn't find another, ok!
        cmp     cs:got_eol,TRUE         ;AN004; Check if nothing left on command line
        je      foo                     ;AN004; no, nothing left on command line, exit
        jmp     parser

foo:
        mov     cs:errlevel,ERRORLEVEL_ZERO ;AN000; Proper code
        call    terminate               ;AN000; reset codepage and terminate


;--------------------------
;       Clear Counters
;--------------------------
clr_cntrs proc  near
        mov     byte ptr cs:mtch_cntr,0
        mov     byte ptr cs:line_cntr,0
        ret
clr_cntrs endp


;--------------------------
;       Print Count of Matched lines
;       Modifies: AX,CX,DX and DI
;--------------------------
print_count     proc    near
        push    bx                      ;save handle
        and     bx,bx                   ;AN007; ;using STDIN?
        jz      sj3                     ;if so do not print file name

        mov     dx,offset ccolon
        mov     cx,2
        call    prout                   ;print colon
sj3:
        mov     ax,cs:mtch_cntr
        mov     di,offset n2_buf        ;buffer for characters
        call    bin2asc                 ;convert to ascii
        mov     dx,offset n2_buf
        call    prout                   ;print the number
        mov     dx,offset crlf
        mov     cx,2
        call    prout                   ;print an end of line
        pop     bx
        ret
print_count     endp

;--------------------------
;       Print relative line number

;       Modifies: AX,CX and DI
;--------------------------
prt_lcntr       proc    near
        push    bx
        push    dx
        mov     ax,cs:line_cntr
        mov     di,offset n2_buf
        call    bin2asc
        mov     byte ptr[di],"]"
        inc     cx
        inc     cx
        mov     dx,offset n1_buf
        call    prout
        pop     dx
        pop     bx
        ret
prt_lcntr endp

;--------------------------
;       Print string to STDOUT
;--------------------------
prout   proc    near
        mov     bx,STDOUT
        mov     ah,write
        int     021h
        ret
prout   endp

;--------------------------
;       Binary to Ascii conversion routine
; Entry:
;       AX      Binary number
;       DI      Points to one past the last char in the
;             result buffer.
; Exit:
;       Result in the buffer MSD first
;       CX      Digit count
; Modifies:
;       AX,BX,CX,DX and DI
;--------------------------
bin2asc proc    near
        mov     bx,0ah
        xor     cx,cx
go_div:
        inc     cx
        cmp     ax,bx
        jb      div_done
        xor     dx,dx
        div     bx
        add     dl,'0'          ;convert to ASCII
        push    dx
        jmp     short go_div

div_done:
        add     al,'0'
        push    ax
        mov     bx,cx
deposit:
        pop     ax
        stosb
        loop    deposit
        mov     cx,bx
        ret
bin2asc endp

;--------------------------
;       CAPIALIZES THE CHARACTER IN AL
;       entry:
;               AL      has the character to Capitalize
;       exit:
;               AL      has the capitalized character
;       modifies:
;               AL
;--------------------------
;make_caps       proc    near
;        cmp     al,'a'
;        jb      no_cap
;        cmp     al,'z'
;        jg      no_cap
;        and     al,0dfh
;no_cap:
;        ret
;make_caps       endp
;


;--------------------------
;       ADVANCE POINTER TO NEXT KANJI CHARACTER
; entry:        DI  points to a Kanji string
;               CX  length in bytes of the string
; exit:         DI  points to next Kanji char
;               CX  has number of bytes left
; modifies:     AX
;--------------------------
next_kchar      proc    near
        jcxz    no_kleft
        call    is_prefix
        jnc     no_p
        inc     di
        dec     cx
        jcxz    no_kleft                ; for insurance
no_p:
        inc     di
        dec     cx
        clc
        ret

no_kleft:
        stc
        ret
next_kchar      endp

;--------------------------
;       Get DOS dbcs table vector
; entry:  none
; exit:   none
; modifies: none
;--------------------------
get_dbcs_vector proc near             ;AN006;
        push es                       ;AN006;
        push di                       ;AN006;
        push ax                       ;AN006;
        push bx                       ;AN006;
        push cx                       ;AN006;
        push dx                       ;AN006;
;
        mov  ax,cs                    ;AN006; ;segment of return buffer
        mov  es,ax                    ;AN006;
        mov  di,offset bufferDB       ;AN006; ;offset of return buffer
        mov  ah,65h                   ;AN006; ;get extended country info
        mov  al,07h                   ;AN006; ;get DBCS environment table
        mov  bx,0ffffh                ;AN006; ;use active code page
        mov  cx,5                     ;AN006; ;number of bytes returned
        mov  dx,0ffffh                ;AN006; ;default country ID
        int  21h                      ;AN006; ;DOS function call,vector returned
                                      ;AN006; ; in ES:DI
        inc  di                       ;AN006; ;skip over id byte returned
        mov  ax,word ptr es:[di]      ;AN006; ;get offset of DBCS table
        mov  cs:dbcs_off,ax           ;AN006; ;save it
;
        add  di,2                     ;AN006; ;skip over offset to get segment
        mov  bx,word ptr es:[di]      ;AN006; ;get segment of DBCS table
        mov  cs:dbcs_seg,bx           ;AN006; ;save it
;
        mov  di,ax                    ;AN006; ;Point to DBCS table to get length
        mov  es,bx                    ;AN006;
        mov  ax,word ptr es:[di]      ;AN006;
        mov  cs:dbcs_len,ax           ;AN006;
        add  cs:dbcs_off,2            ;AN006; ;change offset to point to table
;
        pop  dx                       ;AN006;
        pop  cx                       ;AN006;
        pop  bx                       ;AN006;
        pop  ax                       ;AN006;
        pop  di                       ;AN006;
        pop  es                       ;AN006;
;
        ret                           ;AN006;
get_dbcs_vector endp                  ;AN006;


;--------------------------
;       FIND OUT IS THE BYTE IS A KANJI PREFIX
; entry:  DI    points to a kanji string
; exit:   Carry set if it is a kanji prefix
; modifies:     AX
;--------------------------
is_prefix proc near                   ;AN006;
        push    es
        push    si
        push    ax
;
        mov     si,cs:dbcs_off        ;ES:SI -> DOS dbcs table
        mov     ax,cs:dbcs_seg
        mov     es,ax
;
        mov     al,byte ptr cs:[di]   ;get first byte of string
;
; Two consecutive 00 bytes signifies end of table
;

is_loop:
        cmp  word ptr es:[si],00h     ;Check for two consecutive 00 bytes
        jne  is_next1                 ;no, continue
        clc                           ;clear carry - byte is not lead byte of db char
        jmp  short is_exit            ;AN007; ;yes, found them, quit

;
; Check if byte is within range values of DOS dbcs table
;

is_next1:
        cmp  al,byte ptr es:[si]      ;is byte >= first byte in range?
        jae  is_next2                 ;yes, continue
        jmp  short is_again           ;AN007; ;no, loop again

is_next2:
        cmp  al,byte ptr es:[si+1]    ;is byte <= last byte in range?
        jbe  is_found                 ;yes, found a lead byte of db char

is_again:
        add  si,2                     ;no, increment ptr to next range
        jmp  is_loop

is_found:
        stc                           ;byte is lead byte of db char, set carry

is_exit:
        pop  ax
        pop  si
        pop  es
;
        ret
is_prefix       endp


;
;---------------------
;- Terminate process
;---------------------
terminate       proc    near          ;AN000;
        mov     ah,exit               ;AN000; Terminate function call
        mov     al,cs:errlevel        ;AN000; Errorlevel placed in AL
        int     021h                  ;AN000; Terminate
        ret                           ;AN000; Meaningless return
terminate       endp                  ;AN000;

;
;************************************************************
;*
;* SUBROUTINE NAME:     set_cp
;*
;* FUNCTION: Sets the cp of the handle in bx to the cp in LIST structure
;*
;* INPUT:
;*    BX         = handle
;*    cp_list.cp = code page to set for the file handle in BX
;*
;* OUTPUT:
;*    Codepage will be set to that requested, or an error will be
;*    returned in AX with carry flag set.
;*
;************************************************************
set_cp  proc    near                    ;AN000;
        mov     ax,SetExtAttr           ;AN000; Set target codepage to that of source
        mov     di,offset cp_list       ;AC001; Input buffer address
        int     021h                    ;AN000; Call DOS
        ret                             ;AN000; Return to caller
set_cp  endp                            ;AN000;



;************************************************************
;*
;* SUBROUTINE NAME:     get_cp
;*
;* FUNCTION: Gets the cp of the handle in bx
;*
;* INPUT:
;*    BX = handle
;*
;* OUTPUT:
;*    Codepage for the file handle in bx will be returned in
;*    the CP_LIST.CP structure, or an error will be returned in
;*    AX with carry flag set.
;*
;************************************************************
get_cp  proc    near                    ;AN000;
        push    ds                      ;AN005;

        push    cs                      ;AN005;
        pop     ds                      ;AN005;

        mov     ax,GetExtAttr           ;AN000; Get codepage
        mov     di,offset cp_list       ;AN000; Input buffer address
        mov     si,offset cp_qlist      ;AN001; which ea to select
        mov     cx,cp_len               ;AN001; buffer length
        int     021h                    ;AN000; Call to DOS

        pop     ds                      ;AN005;
        ret                             ;AN000; Return to caller
get_cp  endp                            ;AN000;


;
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
;*      3)   DH = Code indicating message class
;*
;*   OUTPUT:
;*      The message corresponding to the requested msg number will
;*      be written to the requested handle.
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
        push    ds                      ;AN000; Save DS
        push    cs                      ;AN000; Substitution list segment
        pop     ds                      ;AN000;
        mov     si,offset sublist       ;AN000; Substitution list offset
      ; mov     dh,-1                   ;AN000; Message class
                                        ; 1=DOS Extended error
                                        ; 2=DOS Parse error
                                        ; -1=Utility message
        mov     dl,0                    ;AN000;  DOS INT 21H function number to use for input
                                        ; 00H=No input, 01H=Keyboard input,
                                        ; 07H=Direct Console Input Without Echo,
                                        ; 08H=Console Input Without Echo, 0AH=Buffered Keyboard Input
        call    SYSDISPMSG              ;AN000; AX=Extended key value if wait for key
      ; jnc     disp_done               ;AN000; If CARRY SET then registers will contain extended error information
                                        ;       AX - Extended error Number
                                        ;       BH - Error Class
                                        ;       BL - Suggested action
                                        ;       CH - Locus
disp_done:                              ;AN000;
        pop     ds                      ;AN000; Restore DS
        ret                             ;AN000;
display_msg     ENDP                    ;AN000;

        PAGE
;************************************************************
;*
;*   SUBROUTINE NAME:      parse
;*
;*   SUBROUTINE FUNCTION:
;*      Call the DOS PARSE Service Routines to process the command
;*      line. Search for valid switches (/N, /V, and /C) and take
;*      appropriate action for each.  Extract the search string.
;*
;*   INPUT:        DS:SI points to string to parse
;*                 ES:DI parser parms
;*
;*   OUTPUT:       ES:DI points to filespec for text search
;*
;*   NORMAL EXIT:
;*
;*      If /V, /C, or /N entered, set appropriate flag.
;*      Save the search string.
;*
;*   ERROR EXIT:
;*
;*      If user enters any invalid parameter or switch, then this
;*      routine will display an error message and terminate with
;*      errorlevel 1.
;*
;************************************************************
EOL             equ    -1       ;AN000; Indicator for End-Of-Line
NOERROR         equ     0       ;AN000; Return Indicator for No Errors
SYNTAX          equ     9       ;AN000; Syntax error from parser

SWITCH          equ     3       ;AN000;
FILESPEC        equ     5       ;AN000;
QUOTED_STRING   equ     9       ;AN000;

parse   proc    near                                    ;AN000;
;--------------------------------------
; address of command line in DS:SI
;--------------------------------------
;------------------------------------------
;- Look for the search string and switches
;------------------------------------------
parse_loop:                                             ;AN000;
        mov     di,offset parms                         ;AN000; Address of parse control block at ES:DI
        xor     dx,dx                                   ;AN000; Reserved
        call    sysparse                                ;AN000; Parse parm at DS:SI
        cmp     ax,EOL                                  ;AN000; Are we at End Of Line ??
        jne     p_next                                  ;AN004; No eol found
        mov     cs:got_eol,TRUE                         ;AN004; no more filenames to get!
        cmp     cs:did_file,TRUE                        ;AN004; did we do a file already ?
        lje     doexit                                  ;AN004; yes, exit
        jmp     end_parse                               ;AN004; Yes, done here
p_next:                                                 ;AN004; continue
        and     ax,ax                                   ;AN007; ;AN000; Was there an error?
        je      CONT2                                   ;AN000; No, continue processing

        mov     dh,2                                    ;AN005; Its a PARSE message
        call    display_and_die                         ;AN005;
CONT2:                                                  ;AN000; Something valid was entered
        cmp     cs:rb_type,QUOTED_STRING                ;AN000; Is it a quoted string ?
        je      its_a_quoted_string                     ;AN000; Yes, go process it
        cmp     cs:rb_type,FILESPEC                     ;AN000; Is it a filespec?
        jne     cont3                                   ;AN000;
        mov     di,cs:rb_value_lo                       ;AN000;  Look for another
        mov     cs:got_filename,TRUE                    ;AN004;  got a filename
        jmp     short end_parse                         ;AN007; ;AN000;  Look for another
cont3:
        cmp     cs:rb_type,SWITCH                       ;AN000; Is it a switch ?
        je      its_a_switch                            ;AN000;  Yes, go process it
        mov     ax,msg_inv_parm                         ;AN000; None of above, too bad
        mov     dh,2                                    ;AN005; message class
        call    display_and_die                         ;AN000; Tell the poor user and terminate

;-----------------------------
;- The search string was entered
;-----------------------------
its_a_quoted_string:                                    ;AN000; Found a quoted string
        cmp     cs:got_srch_str,TRUE                    ;AN000; Do we already have one?
        jne     its_ok                                  ;AN000; No, it's ok
        mov     ax,msg_inv_parm                         ;AN000; Yes, Invalid parm!
        mov     dh,2                                    ;AN005; message class
        call    display_and_die                         ;AN000; Tell user and die gracefully
its_ok:                                                 ;AN000;
        mov     di,cs:rb_value_lo                       ;AN000; Get pointer to it
        mov     bx,offset st_buffer                     ;AN000; save buffer offset
        call    get_length                              ;AN000; get string length
        mov     cs:st_length,ax                         ;AN000; save length
        mov     cs:got_srch_str,TRUE                    ;AN000; Indicate that we have it
        jmp     parse_loop                              ;AN000;

;-----------------------------
;- A valid switch was entered
;-----------------------------
its_a_switch:                                           ;AN000;
        mov     bx,cs:rb_synonym                        ;AN000; Get offset of switch entered
        cmp     bx,offset n_swch                        ;AN000; Is it the /N switch?
        jne     chek_v                                  ;AN000:  Yes, process it.
        jmp     parse_loop                              ;AN000;  Look for another
chek_v:                                                 ;AN000;
        cmp     bx,offset v_swch                        ;AN000; Is it the /N switch?
        jne     chek_c                                  ;AN000:  Yes, process it.
        jmp     parse_loop                              ;AN000;  Look for another
chek_c:                                                 ;AN000;
        cmp     bx,offset c_swch                        ;AN000; Is it the /N switch?
        jne     whoops                                  ;AN000:  Yes, process it.
        jmp     parse_loop                              ;AN000;  Look for another
whoops:                                                 ;AN000; None of the above (can we ever get here?)
        mov     ax,msg_switch                           ;AN000; Invalid parameter
        mov     dh,2                                    ;AN005; message class
        call    display_and_die                         ;AN000; Yes, tell the poor user and terminate

end_parse:                                              ;AN000; A filename should be next
        cmp     cs:got_srch_str,TRUE                    ;AN000; Do we already have one?
        je      rett                                    ;AN000;
        mov     ax,msg_required_missing                 ;AN005;
        mov     dh,-1                                   ;AN005; message class
        call    display_and_die                         ;AN000; Yes, tell the poor user and terminate
rett:                                                   ;AN000;
        ret                                             ;AN000;

doexit:
        mov     cs:errlevel,ERRORLEVEL_ZERO;AN000; Proper code
        call    terminate               ;AN000; reset codepage and terminate

parse   endp                                            ;AN000;


;------------------------------------
;-
;-  Procedure name: pre_parse
;-
;-  Purpose: parse for all switches now
;-      so that they can be applied for
;-      all filenames on command line.
;-
;-  INPUT: none
;-
;------------------------------------
pre_parse proc near                     ;AN005;
        push    ax                      ;AN005;
        push    bx                      ;AN005;
        push    cx                      ;AN005;
        push    dx                      ;AN005;
        push    di                      ;AN005;
        push    si                      ;AN005;
        push    es                      ;AN005;
        push    ds                      ;AN005;
;
pp_loop:                                ;AN005;
        mov     di,offset parms1        ;AN005; Address of parse control block at ES:DI
        xor     dx,dx                   ;AN005; Reserved
        call    sysparse                ;AN005; Parse parm at DS:SI

        cmp     ax,EOL                  ;AN005; Are we at End Of Line ??
        je      pp_end                  ;AN005; No eol found

        cmp     ax,SWITCH               ;AN005; invalid switch ?
        jne     pp_next                 ;AN005; no
; error
        mov     ax,msg_switch           ;AN005; Invalid switch
        mov     dh,2                    ;AN005; message class
        call    display_and_die         ;AN005; Yes, tell the poor user and terminate
pp_next:
        and     ax,ax                   ;AN007; ;AN005; Was there an error?
        jne     pp_loop                 ;AN005; No, continue processing

        cmp     cs:rb_type,SWITCH       ;AN005; Is it a switch ?
        jne     pp_loop                 ;AN005;

; got a switch
        mov     bx,cs:rb_synonym        ;AN005; Get offset of switch entered
        cmp     bx,offset n_swch        ;AN005; Is it the /N switch?
        jne     pp_chek_v               ;AN005:  Yes, process it.
        mov     cs:n_flag,TRUE          ;AN005;  Set the corresponding flag
        jmp     pp_loop                 ;AN005;  Look for another
pp_chek_v:                              ;AN005;
        cmp     bx,offset v_swch        ;AN005; Is it the /N switch?
        jne     pp_chek_c               ;AN005:  Yes, process it.
        mov     cs:v_flag,TRUE          ;AN005;  Set the corresponding flag
        jmp     pp_loop                 ;AN005;  Look for another
pp_chek_c:                              ;AN005;
        cmp     bx,offset c_swch        ;AN005; Is it the /N switch?
        jne     pp_error                ;AN005:  Yes, process it.
        mov     cs:c_flag,TRUE          ;AN005;  Set the corresponding flag
        jmp     pp_loop                 ;AN005;  Look for another

pp_error:                               ;AN005; None of the above (can we ever get here?)
        mov     ax,msg_switch           ;AN005; Invalid parameter
        mov     dh,2                    ;AN005; message class
        call    display_and_die         ;AN005; Yes, tell the poor user and terminate

pp_end:                                 ;AN005; A filename should be next
        pop     ds                      ;AN005;
        pop     es                      ;AN005;
        pop     si                      ;AN005;
        pop     di                      ;AN005;
        pop     dx                      ;AN005;
        pop     cx                      ;AN005;
        pop     bx                      ;AN005;
        pop     ax                      ;AN005;
;
        ret                             ;AN005;
pre_parse endp                          ;AN005;


;------------------------------------
;-
;-  Procedure name: prt_find
;-
;-  Purpose: When FIND is used as a filter,
;-      then display error messages with the
;-      prefix: "FIND: ".
;-
;-  INPUT: none
;-
;------------------------------------
prt_find proc near                      ;AN005;
        cmp     cs:got_filename,TRUE    ;AN005; Check if should print "FIND:"
        je      prt_ret                 ;AN005;
        push    ax                      ;AN005; Save error
        push    dx                      ;AN005;
        mov     dh,-1                   ;AN005; Display FIND:
        mov     ax,msg_find             ;AN005;
        xor     cx,cx                   ;AN007; ;AN005; No substitution text
        mov     bx,STDERR               ;AN005; Sent to STD OUT
        call    display_msg             ;AN005; Display the message
        pop     dx                      ;AN005;
        pop     ax                      ;AN005; Restore error
prt_ret:
        ret                             ;AN005;
prt_find endp                           ;AN005;


;------------------------------------
;-
;-  Procedure name: display_and_die
;-
;-  Purpose: Called when the parser finds that
;-      required arguments were not entered
;-      from the command line.
;-
;-  INPUT: AX = Error number
;-
;------------------------------------
display_and_die proc near
        call    prt_find                ;AN005;
        xor     cx,cx                   ;AN007; ;AN000; No substitution text
        mov     cs:errlevel,ERRORLEVEL_TWO ;AC005; Error code for exit

        mov     bx,STDERR               ;AN000; Sent to STD OUT
        call    display_msg             ;AN000; Display the message
        call    terminate               ;AN000; and Terminate
        ret                             ;AN000;
display_and_die endp

;------------------------------------
;-
;-  Procedure name: get_length
;-
;-  Purpose: determine the length of a null
;-      ending string.
;-
;-  INPUT: ES:DI = string address
;-         ES:BX = save address (0=no save)
;-
;-  OUTPUT: AX   = length of string
;------------------------------------
get_length      proc near
        push    di
        push    bx
        push    dx
        xor     ax,ax                   ;init string length
look_str:
        mov     dl,es:[di]              ;get character
        or      bx,bx                   ;save it?
        jz      no_save
        mov     es:[bx],dl              ;save character
        inc     bx                      ;save next character
no_save:                                ;AN007;
        and     dl,dl                   ;AN007; ;check for eol (asciiz string)
        je      done_look               ;if so, exit
        cmp     dl,0dh                  ;AN005; check for eol (carriage return)
        je      done_look               ;AN005;
        inc     ax                      ;increment length
        inc     di                      ;look at next character
        jmp     look_str
done_look:
        pop     dx
        pop     bx
        pop     di
        ret
get_length      endp




;
;----- BUFFER AREA --------
st_length dw    0                       ;String argument length
st_buffer db    st_buf_size dup(?)      ;String argument buffer

file_name_len dw 0                      ;File name length
file_name_buf dw 0                      ;File name buffer offset

buffer        db buffer_size+2 dup(?)   ;file data buffer

include msgdcl.inc

code    ends

;--------------------------
;---   STACK SEGMENT    ---
;--------------------------
stack   segment para stack 'STACK'
        dw      (362 - 80h) +64 dup(?,?)    ;(362 - 80h)  == New - old IBM ROM
stack_top equ   $
stack   ends

        end     start

