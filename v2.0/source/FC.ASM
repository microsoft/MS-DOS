        title   File Compare Routine for MSDOS 2.0

;-----------------------------------------------------------------------;
; Revision History:                                                     ;
;                                                                       ;
; V1.0  Rev. 0  10/27/82        M.A.Ulloa                               ;
;                                                                       ;
;       Rev. 1  10/28/82        M.A.Ulloa                               ;
;         Changed switch names and added binary compare using the       ;
;       -b switch.                                                      ;
;                                                                       ;
;       Rev. 1  11/4/82         A.R. Reynolds                           ;
;         Messages in separate module                                   ;
;       Also added header for MSVER                                     ;
;                                                                       ;
;       Rev. 2  11/29/82        M.A. Ulloa                              ;
;         Corrected sysntex problem with references to [base...]        ;
;                                                                       ;
;       Rev. 3  01/03/83        M.A. Ulloa                              ;
;         Stack is right size now.                                      ;
;                                                                       ;
;-----------------------------------------------------------------------;

FALSE   equ     0
TRUE    equ     0ffh


buf_size equ    4096                    ;buffer size


;-----------------------------------------------------------------------;
;               Description                                             ;
;                                                                       ;
;       FC [-# -b -w -c] <file1> <file2>                                ;
;                                                                       ;
; Options:                                                              ;
;                                                                       ;
;       -# were # is a number from 1 to 9, how many lines have to       ;
; before the end of an area of difference ends.                         ;
;                                                                       ;
;       -b will force a binary comparation of both files.               ;
;                                                                       ;
;       -w will cause all spaces and tabs to be compressed to a single  ;
; space before comparing. All leading and trailing spaces and/or tabs   ;
; in a line are ignored.                                                ;
;                                                                       ;
;       -c will cause FC to ignore the case of the letters.             ;
;                                                                       ;
; Algorithm for text compare: (The one for binary comp. is trivial)     ;
;                                                                       ;
;       The files are read into two separate buffers and the            ;
; comparation starts. If two lines are found to be different in the     ;
; two buffers, say line i of buffer A and line j of buffer B differ.    ;
; The program will try to match line i with line j+1, then with line    ;
; j+2 and so on, if the end of buffer is reached the program will       ;
; recompact the buffer and try to read more lines into the buffer, if   ;
; no more lines can be read because either the buffer is full, or the   ;
; end of file was reached, then it will revert and try to match line    ;
; j of buffer B to line i+1, i+2 and so on of buffer A. If an end of    ;
; buffer is found, it tries to refill it as before. If no matches are   ;
; found, then it will try to match line i+1 of buffer A to line j+1,    ;
; j+2, j+3, .... of buffer B, if still no matches are found, it reverts ;
; again and tries to match line j+1 of buffer B with lines i+2, i+3,... ;
; of buffer A. And so on till a match is found.                         ;
;                                                                       ;
;       Once a match is found it continues chcking pairs of lines till  ;
; the specified number are matched (option #, 3 by default), and then   ;
; it prints the differing area in both files, each followed by the      ;
; first line matched.                                                   ;
;                                                                       ;
;       If no match is found (the difference is bigger than the buffer) ;
; a "files different" message is printed.                               ;
;                                                                       ;
;       If one of the files finishes before another the remaining       ;
; portion of the file (plus any ongoing difference) is printed out.     ;
;                                                                       ;
;-----------------------------------------------------------------------;


        subttl  Debug Macros
        page

m_debug macro   str
        local   a,b
        jmp     short b
a       db      str,0dh,0ah,"$"
b:      pushf
        push    dx
        mov     dx,offset code:a
        push    ds
        push    cs
        pop     ds
        push    ax
        mov     ah,9h
        int     21h
        pop     ax
        pop     ds
        pop     dx
        popf
        endm


m_bname macro
        local   a0,a1,a2,b1,b2
        jmp     short a0
b1      db      "------ buffer 1",0dh,0ah,"$"
b2      db      "------ buffer 2",0dh,0ah,"$"
a0:     pushf
        push    dx
        cmp     bx,offset dg:buf1
        je      a1
        mov     dx,offset code:b2
        jmp     short a2
a1:     mov     dx,offset code:b1
a2:     push    ds
        push    cs
        pop     ds
        push    ax
        mov     ah,9h
        int     21h
        pop     ax
        pop     ds
        pop     dx
        popf
        endm


        page

        .SALL
        .XLIST
        include dossym.asm
        .LIST

        subttl  General Definitions
        page

CR      equ     0dh
LF      equ     0ah


;-----------------------------------------------------------------------;
;       Offsets to buffer structure
;       For text comparations:

fname      equ  0               ;file name ptr
fname_len  equ  2               ;file name length
handle     equ  4               ;handle
curr       equ  6               ;current line ptr
lst_curr   equ  8               ;last current line ptr
fst_sinc   equ  10              ;first line towards a sinc ptr
fst_nosinc equ  12              ;first line out of sinc ptr
dat_end    equ  14              ;ptr to last char of the buffer
buf_end    equ  16              ;pointer to the end of the buffer
buf        equ  18              ;pointer to the buffer

;       For binary comparations:

by_read    equ  6               ;bytes read into buffer

;-----------------------------------------------------------------------;


code    segment word
code    ends

const   segment public word
const   ends

data    segment word
data    ends

dg      group   code,const,data


        subttl  Constants Area
        page

const   segment public word

make    db      "MAUlloa/Microsoft/V10"
rev     db      "2"

;----- CAREFULL WITH PRESERVING THE ORDER OF THE TABLE -----
opt_tbl equ     $                       ;option table

flg_b   db      FALSE
flg_c   db      FALSE
flg_s   db      FALSE
flg_w   db      FALSE
;-----------------------------------------------------------

ib_first1 db    FALSE                   ;flags used when comparing lines
ib_first2 db    FALSE                   ; while in ignore white mode.

m_num   dw      3                       ;lines that have to match before
                                        ; reporting a match

mtch_cntr dw    0                       ;matches towards a sinc

mode    db      FALSE                   ;If false then trying to match a line
                                        ; from buf1 to lines in buf2. If true
                                        ; then viceversa.

sinc    db      TRUE                    ;Sinc flag, start IN SINC

bend    db      0                       ;binary end of file flag, 0= none yet,
                                        ; 1= file 1 ended, 2= file 2 ended

base    dd      0                       ;base address of files for binary
                                        ; comparations

bhead_flg db    false                   ;true if heading for binary comp.
                                        ; has been printed already.

;-----------------------------------------------------------
bp_buf  equ     $                       ;binary compare difference template

bp_buf1 db      8 dup(' ')              ;file address
        db      3 dup(' ')
bp_buf2 db      2 dup(' ')              ;byte of file 1
        db      3 dup(' ')
bp_buf3 db      2 dup(' ')              ;byte of file 1
        db      CR,LF

bp_buf_len equ  $ - bp_buf              ;length of template
;-----------------------------------------------------------

        EXTRN   vers_err:byte,opt_err:byte,opt_e:byte,crlf:byte,opt_err_len:byte
        EXTRN   bhead_len:byte
        EXTRN   found_err_pre:byte,found_err_pre_len:byte
        EXTRN   found_err_post:byte,found_err_post_len:byte
        EXTRN   read_err_pre:byte,read_err_pre_len:byte
        EXTRN   read_err_post:byte,read_err_post_len:byte
        EXTRN   file_err:byte,file_err_len:byte
        EXTRN   bf1ne:byte,bf1ne_len:byte,bf2ne:byte,bf2ne_len:byte,bhead:byte
        EXTRN   int_err:byte,int_err_len:byte,dif_err:byte,dif_err_len:byte
        EXTRN   args_err:byte,args_err_len:byte,fname_sep:byte,fname_sep_len:byte
        EXTRN   diff_sep:byte,diff_sep_len:byte

const   ends



        subttl  Data Area
        page

data    segment word

com_buf db      128 dup(?)      ;command line buffer

;----- Buffer structures
buf1    dw      11 dup(?)
buf2    dw      11 dup(?)

; two extra for guard in case of need to insert a CR,LF pair
b1      db      buf_size dup(?)
end_b1  db      2 dup(?)
b2      db      buf_size dup(?)
end_b2  db      2 dup(?)

data    ends



        subttl  MAIN Routine
        page

code    segment
assume  cs:dg,ds:nothing,es:nothing,ss:stack

start:
        jmp     short FCSTRT
;-----------------------------------------------------------------------;
;       Check version number

HEADER  DB      "Vers 1.00"

FCSTRT:
;Code to print header
;       PUSH    DS
;       push    cs
;       pop     ds
;       MOV     DX,OFFSET DG:HEADER
;       mov     ah,std_con_string_output
;       int     21h
;       POP     DS

        mov     ah,get_version
        int     21h
        cmp     al,2
        jge     vers_ok
        mov     dx,offset dg:vers_err
        mov     ah,std_con_string_output
        int     21h
        push    es                      ;bad vers, exit a la 1.x
        xor     ax,ax
        push    ax

badvex  proc    far
        ret
badvex  endp


vers_ok:
        push    cs
        pop     es

assume  es:dg

;-----------------------------------------------------------------------;
;       Copy command line

        mov     si,80h                  ;command line address
        cld
        lodsb                           ;get char count
        mov     cl,al
        xor     ch,ch
        inc     cx                      ;include the CR
        mov     di,offset dg:com_buf
        cld
        rep     movsb

        push    cs
        pop     ds

assume  ds:dg



;-----------------------------------------------------------------------;
;       Initialize buffer structures

        mov     bx,offset dg:buf1
        mov     word ptr [bx].buf,offset dg:b1
        mov     word ptr [bx].buf_end,offset dg:end_b1
        mov     bx,offset dg:buf2
        mov     word ptr [bx].buf,offset dg:b2
        mov     word ptr [bx].buf_end,offset dg:end_b2


;-----------------------------------------------------------------------;
;       Process options

        mov     ah,char_oper
        mov     al,0
        int     21h                     ;get switch character
        mov     si,offset dg:com_buf

cont_opt:
        call    kill_bl
        jc      bad_args                ;arguments missing
        cmp     al,dl                   ;switch character?
        jne     get_file                ;no, process file names
        cld
        lodsb                           ;get option
        call    make_caps               ;capitalize option
        mov     bx,offset dg:opt_tbl

        cmp     al,'B'
        je      b_opt
        cmp     al,'C'
        je      c_opt
        cmp     al,'S'
        je      s_opt
        cmp     al,'W'
        je      w_opt
        cmp     al,'1'                  ;a number option?
        jb      bad_opt
        cmp     al,'9'
        ja      bad_opt
        and     al,0fh                  ;a number option, convert to binary
        xor     ah,ah                   ;zero high nibble
        mov     [m_num],ax
        jmp     short cont_opt

bad_opt:                                ;a bad option:
        push    dx                      ; save switch character
        mov     [opt_e],al              ; option in error
        mov     dx,offset dg:opt_err
        mov     cl,opt_err_len
        call    prt_err                 ; print error message
        pop     dx
        jmp     short cont_opt          ; process rest of options

b_opt:
        mov     di,0
        jmp     short opt_dispatch

c_opt:
        mov     di,1
        jmp     short opt_dispatch

s_opt:
        mov     di,2
        jmp     short opt_dispatch

w_opt:
        mov     di,3

opt_dispatch:
        mov     byte ptr dg:[bx+di],TRUE        ;set the corresponding flag
        jmp     short cont_opt


bad_args:
        mov     dx,offset dg:args_err
        mov     cl,args_err_len
        jmp     an_err



;-----------------------------------------------------------------------;
;       Get the file names

get_file:
        dec     si                      ;adjust pointer
        call    find_nonb               ;find first non blank in com. buffer
        jc      bad_args                ;file (or files) missing
        mov     byte ptr [di],0         ;nul terminate
        mov     dx,si                   ;pointer to file name
        mov     bx,offset dg:buf1
        mov     word ptr [bx].fname,dx          ;save pointer to file name
        mov     word ptr [bx].fname_len,cx      ;file name length
        mov     ah,open
        mov     al,0                    ;open for reading
        int     21h
        jc      bad_file
        mov     word ptr [bx].handle,ax         ;save the handle

        mov     si,di
        inc     si                      ;point past the nul
        call    kill_bl                 ;find other file name
        jc      bad_args                ;a CR found: file name missing
        dec     si                      ;adjust pointer
        call    find_nonb
        mov     byte ptr [di],0         ;nul terminate the file name
        mov     dx,si
        mov     bx,offset dg:buf2
        mov     word ptr [bx].fname,dx          ;save pointer to file name
        mov     word ptr [bx].fname_len,cx      ;file name length
        mov     ah,open
        mov     al,0                    ;open for reading
        int     21h
        jc      bad_file
        mov     word ptr [bx].handle,ax         ;save the handle
        jmp     short go_compare

bad_file:
        cmp     ax,error_file_not_found
        je      sj01
        mov     dx,offset dg:int_err
        mov     cl,int_err_len
        jmp     short an_err
sj01:
        push    cx                      ;save file name length
        mov     dx,offset dg:found_err_pre
        mov     cl,found_err_pre_len
        call    prt_err
        pop     cx
        mov     dx,si                   ;pointer to file name length
        call    prt_err
        mov     dx,offset dg:found_err_post
        mov     cl,found_err_post_len
an_err:
        call    prt_err
        mov     al,-1                   ;return an error code
        mov     ah,exit
        int     21h



;-----------------------------------------------------------------------;
;               CHECK COMPARE MODE

go_compare:
        cmp     [flg_b],true            ;do we do a binary comparation?
        je      bin_compare
        jmp     txt_compare


        subttl  Binary Compare Routine
        page

;-----------------------------------------------------------------------;
;       COMPARE BUFFERS IN BINARY MODE

bin_compare:

;----- Fill in the buffers

        mov     bx,offset dg:buf1       ;pointer to buffer structure
        mov     dx,word ptr[bx].buf     ;pointer to buffer
        mov     si,dx                   ;save for latter comparation
        call    read_dat                ;read into buffer
        jc      bad_datj                ;an error
        mov     word ptr[bx].by_read,AX    ;save ammount read
        push    ax                      ;save for now

        mov     bx,offset dg:buf2       ;pointer to buffer structure
        mov     dx,word ptr[bx].buf     ;pointer to buffer
        mov     di,dx                   ;save for comparation
        call    read_dat                ;read into buffer
bad_datj: jc    bad_dat                 ;an error
        mov     word ptr[bx].by_read,AX    ;save ammount read

        pop     cx                      ;restore byte count of buffer1
        cmp     ax,cx                   ;compare byte counts
        ja      morein_b2
        jb      morein_b1
        or      ax,ax                   ;the same ammount, is it 0?
        jne     go_bcomp                ;no,compare
        jmp     go_quit                 ;yes, all done....

morein_b2:
        mov     [bend],1                ;file 1 ended
        jmp     short go_bcomp

morein_b1:
        mov     [bend],2                ;file 2 ended
        mov     cx,ax

;----- Compare data in buffers

go_bcomp:
        mov     ax,word ptr [base]      ;load base addrs. to AX,BX pair
        mov     bx,word ptr [base+2]
        add     bx,cx                   ;add to base num. of bytes to
        adc     ax,0                    ; compare.
        mov     word ptr [base],ax      ;save total
        mov     word ptr [base+2],bx

next_bcomp:
        cld
        jcxz    end_check
        repz    cmpsb                   ;compare both buffers
        jz      end_check               ;all bytes match
        push    cx                      ;save count so far
        push    ax
        push    bx
        inc     cx
        sub     bx,cx                   ;get file address of bytes that
        sbb     ax,0                    ; are different.
        call    prt_bdif                ;print difference
        pop     bx
        pop     ax
        pop     cx                      ;restore on-going comparation count
        jmp     short next_bcomp

bnot_yet:
        jmp     bin_compare

end_check:
        cmp     [bend],0                ;have any file ended yet?
        je      bnot_yet                ;no, read in more data
        cmp     [bend],1                ;yes, was it file 1?
        je      bf1_ended               ;yes, data left in file 2
        mov     dx,offset dg:bf1ne
        mov     cl,bf1ne_len
        jmp     short bend_mes

bf1_ended:
        mov     dx,offset dg:bf2ne
        mov     cl,bf2ne_len

bend_mes:
        xor     ch,ch
        call    prout
        jmp     go_quit



        subttl  Text Compare Routine
        page

;-----------------------------------------------------------------------;
;               Fill in the buffers

bad_dat:
        mov     dx,offset dg:file_err
        mov     cl,file_err_len
        jmp     an_err


txt_compare:

        mov     bx,offset dg:buf1
        mov     dx,word ptr [bx].buf
        mov     word ptr [bx].fst_nosinc,dx
        mov     word ptr [bx].curr,dx

        call    fill_buffer
        jc      bad_dat

        mov     bx,offset dg:buf2
        mov     dx,word ptr [bx].buf
        mov     word ptr [bx].fst_nosinc,dx
        mov     word ptr [bx].curr,dx

        call    fill_buffer
        jc      bad_dat


;-----------------------------------------------------------------------;
;       COMPARE BUFFERS IN TEXT MODE

another_line:
        call    go_match                ;try to match both current lines
        jc      sj02                    ;a match
        jmp     no_match                ;no match, continue....
sj02:
        cmp     byte ptr[sinc],true     ;are we in SINC?
        je      sj04
        mov     ax,[mtch_cntr]
        or      ax,ax                   ;first line of a possible SINC?
        jnz     sj03
        mov     bx,offset dg:buf1
        mov     word ptr [bx].fst_sinc,si       ;yes, save curr line buffer 1
        mov     bx,offset dg:buf2
        mov     word ptr [bx].fst_sinc,di       ;save curr line buffer 2
sj03:
        inc     ax                      ;increment match counter
        mov     [mtch_cntr],ax          ;save number of matches
        cmp     m_num,ax                ;enough lines matched for a SINC?
        jne     sj04                    ;not yet, match some more
        mov     [sinc],true             ;yes, flag we are now in sinc
        call    print_diff              ;print mismatched lines



;-----------------------------------------------------------------------;
;       Advance current line pointer in both buffers

sj04:
        mov     bx,offset dg:buf1
        call    adv_b
        jnc     sj05
        jmp     no_more1
sj05:
        mov     word ptr[bx].curr,si
        mov     bx,offset dg:buf2
        call    adv_b
        jnc     sj051
        jmp     no_more2
sj051:
        mov     word ptr[bx].curr,si
        jmp     another_line            ;continue matching



;-----------------------------------------------------------------------;
;               Process a mismatch

no_match:
        cmp     [sinc],true             ;are we in SINC?
        jne     sj06
        mov     [sinc],false            ;not any more....
        mov     bx,offset dg:buf1
        mov     word ptr [bx].fst_nosinc,si     ;save current lines
        mov     word ptr [bx].lst_curr,si
        mov     bx,offset dg:buf2
        mov     word ptr [bx].fst_nosinc,di
        mov     word ptr [bx].lst_curr,di
sj06:
        mov     [mtch_cntr],0           ;reset match counter
        cmp     [mode],true
        je      sj09

;----- MODE A -----
        mov     bx,offset dg:buf2
        call    adv_b                   ;get next line in buffer (or file)
        jc      sj08                    ;no more lines in buffer
sj07:
        mov     word ptr [bx].curr,si
        jmp     another_line
sj08:
        mov     [mode],true             ;change mode
        mov     si,word ptr [bx].lst_curr
        mov     word ptr [bx].curr,si
        mov     bx,offset dg:buf1
        mov     si,word ptr [bx].lst_curr
        mov     word ptr [bx].curr,si
        call    adv_b                   ;get next line
        jc      no_more1                ;no more lines fit in buffer 1
        mov     word ptr [bx].lst_curr,si
        jmp     short sj10

;----- MODE B -----
sj09:
        mov     bx,offset dg:buf1
        call    adv_b                   ;get next line in buffer (or file)
        jc      sj11                    ;no more lines in buffer
sj10:
        mov     word ptr [bx].curr,si
        jmp     another_line

sj11:
        mov     [mode],false
        mov     si,word ptr [bx].lst_curr
        mov     word ptr [bx].curr,si
        mov     bx,offset dg:buf2
        mov     si,word ptr [bx].lst_curr
        mov     word ptr [bx].curr,si
        call    adv_b                   ;get next line
        jc      no_more2                ;no more lines fit in buffer 2
        mov     word ptr [bx].lst_curr,si
        jmp     sj07



;-----------------------------------------------------------------------;
;               Process end of files

no_more1:
        cmp     ax,0                    ;end of file reached?
        jz      xj1
        jmp     dif_files               ;no, difference was too big
xj1:
        cmp     [sinc],true             ;file1 ended, are we in SINC?
        je      xj3
        jmp     no_sinc
xj3:
        mov     bx,offset dg:buf2
        call    adv_b                   ;advance current line in buf2
        jnc     xj5
        jmp     go_quit                 ;file2 ended too, terminate prog.
xj5:

;----- File 1 ended but NOT file 2
        mov     bx,offset dg:buf1
        call    print_head
        mov     bx,offset dg:buf2
        call    print_head
        call    print_all               ;print the rest of file2
        jmp     go_quit


no_more2:
        cmp     ax,0                    ;end of file reached?
        jz      xj2
        jmp     dif_files               ;no, difference was too big
xj2:
        cmp     [sinc],true             ;file1 ended, are we in SINC?
        je      xj4
        jmp     no_sinc
xj4:
        mov     bx,offset dg:buf1
        call    adv_b                   ;advance current line in buf2
        jnc     xj6
        jmp     go_quit                 ;file2 ended too, terminate prog.
xj6:

;----- File 2 ended but NOT file 1
        mov     bx,offset dg:buf1
        call    print_head
        call    print_all               ;print the rest of file1
        mov     bx,offset dg:buf2
        call    print_head
        jmp     go_quit



no_sinc:
        mov     bx,offset dg:buf1
        call    print_head
        call    print_all
        mov     bx,offset dg:buf2
        call    print_head
        call    print_all
        jmp     go_quit



dif_files:
        mov     dx,offset dg:dif_err
        mov     cl,dif_err_len
        jmp     an_err

go_quit:
        mov     al,0
        mov     ah,exit
        int     21h


        subttl  Subroutines: make caps
        page

;-----------------------------------------------------------------------;
;       CAPIALIZES THE CHARACTER IN AL                                  ;
;                                                                       ;
;       entry:                                                          ;
;               AL      has the character to Capitalize                 ;
;                                                                       ;
;       exit:                                                           ;
;               AL      has the capitalized character                   ;
;                                                                       ;
;       Called from MAIN and go_match                                   ;
;-----------------------------------------------------------------------;
make_caps:
        cmp     al,'a'
        jb      sa1
        cmp     al,'z'
        jg      sa1
        and     al,0dfh
sa1:    ret


        subttl  Subroutines: kill_bl
        page

;-----------------------------------------------------------------------;
;            Get rid of blanks in command line.                         ;
;                                                                       ;
; entry:                                                                ;
;       SI      points to the first character on the line to scan.      ;
;                                                                       ;
; exit:                                                                 ;
;       SI      points to the next char after the first non-blank       ;
;                 char found.                                           ;
;       Carry Set  if a CR found                                        ;
;                                                                       ;
; modifies:                                                             ;
;       SI and AX                                                       ;
;                                                                       ;
;       Called from MAIN                                                ;
;-----------------------------------------------------------------------;
kill_bl:
        cld                             ;increment
sb1:    lodsb                           ;get rid of blanks
        cmp     al,' '
        je      sb1
        cmp     al,9
        je      sb1
        cmp     al,CR
        clc                             ;assume not a CR
        jne     sb2
        stc                             ;a CR found, set carry
sb2:    ret


        subttl  Subroutines: find_nonb
        page

;-----------------------------------------------------------------------;
;       Find the first non-blank in a line                              ;
;                                                                       ;
; entry:                                                                ;
;       SI      points to the line buffer                               ;
;                                                                       ;
; exit:                                                                 ;
;       DI      pointer to the first blank found (incl. CR)             ;
;       CX      character count of non-blanks                           ;
;       Carry Set if a CR was found                                     ;
;                                                                       ;
; modifies:                                                             ;
;       AX                                                              ;
;                                                                       ;
;       Called from MAIN                                                ;
;-----------------------------------------------------------------------;
find_nonb:
        push    si              ;save pointer
        xor     cx,cx           ;zero character count
        cld
sc1:
        lodsb
        cmp     al,' '
        je      sc2
        cmp     al,9
        je      sc2
        cmp     al,CR
        je      sc2
        inc     cx              ;inc character count
        jmp     short sc1
sc2:
        dec     si
        mov     di,si
        pop     si
        cmp     al,CR
        jne     sc3
        stc
        ret
sc3:
        clc
        ret


        subttl  Subroutines: prt_bdif
        page

;-----------------------------------------------------------------------;
;       Print a binary difference                                       ;
;                                                                       ;
; entry:                                                                ;
;       AX,BX   file address of diference                               ;
;       SI      pointer to one past byte in buffer1                     ;
;       DI      pointer to one past byte in buffer2                     ;
;                                                                       ;
; modifies:                                                             ;
;       AX, DX and CX                                                   ;
;                                                                       ;
;       called from bin_compare                                         ;
;-----------------------------------------------------------------------;
prt_bdif:
        cmp     [bhead_flg],true        ;have we peinted head yet?
        je      bhead_ok
        mov     [bhead_flg],true        ;no, set flag
        push    ax                      ;print heading
        mov     dx,offset dg:bhead
        mov     cl,bhead_len
        xor     ch,ch
        call    prout
        pop     ax

bhead_ok:
        mov     dx,di                   ;conver file address
        mov     di,offset dg:bp_buf1
        push    ax
        mov     al,ah
        call    bin2hex
        pop     ax
        call    bin2hex
        mov     al,bh
        call    bin2hex
        mov     al,bl
        call    bin2hex

        mov     di,offset dg:bp_buf2    ;convert byte from file 1
        mov     al, byte ptr[si-1]
        call    bin2hex

        mov     di,offset dg:bp_buf3    ;convert byte from file 2
        push    si
        mov     si,dx
        mov     al, byte ptr[si-1]
        pop     si
        call    bin2hex

        mov     di,dx                   ;print result
        mov     dx,offset dg:bp_buf
        mov     cx,bp_buf_len
        call    prout
        ret


        subttl  Subroutines: bin2hex
        page

;-----------------------------------------------------------------------;
;               Binary to ASCII hex conversion                          ;
;                                                                       ;
; entry:                                                                ;
;       AL      byte to convert                                         ;
;       DI      pointer to were the two result ASCII bytes should go    ;
;                                                                       ;
; exit:                                                                 ;
;       DI      points to one past were the last result byte whent      ;
;                                                                       ;
; modifies:                                                             ;
;       AH and CL                                                       ;
;                                                                       ;
;       Called from prt_bdif                                            ;
;-----------------------------------------------------------------------;
bin2hex:
        mov     cl,4
        ror     ax,cl           ;get the high nibble
        and     al,0fh          ;mask of high nible
        call    pt_hex
        rol     ax,cl           ;get the low nibble
        and     al,0fh          ;mask....

pt_hex:
        cmp     al,0ah          ;is it past an A ?
        jae     pasta
        add     al,30h
        jmp     short put_hex
pasta:
        add     al,37h
put_hex:
        stosb                   ;place in buffer
        ret


        subttl  Subroutines: go_match
        page

;-----------------------------------------------------------------------;
;               Match current lines                                     ;
;                                                                       ;
; exit:                                                                 ;
;       Carry set if the match reset otherwise                          ;
;       SI      Current line of buff1                                   ;
;       DI      Current line of buff2                                   ;
;                                                                       ;
;                                                                       ;
; modifies:                                                             ;
;       AX,BX,CX,DX and BP                                              ;
;                                                                       ;
;       Called from txt_compare                                         ;
;-----------------------------------------------------------------------;
go_match:
        mov     bx,offset dg:buf1
        mov     si,word ptr[bx].curr
        push    si
        mov     bp,si                   ;save line pointer
        call    find_eol
        mov     dx,cx                   ;save length of line
        mov     bx,offset dg:buf2
        mov     si,word ptr[bx].curr
        push    si
        mov     di,si
        call    find_eol
        cmp     cx,dx                   ;compare lengths
        jne     sd1                     ;they do not match
        mov     si,bp                   ;restore line pointer
        jcxz    sd4                     ;both length = 0, they match
        push    cx                      ;save the length
        cld
        repz    cmpsb                   ;compare strings
        pop     cx                      ;restore the length
        jz      sd4                     ;they match
sd1:
        cmp     [flg_w],true            ;do we ignore multiple whites?
        je      ib_compare              ;yes, go compare
        cmp     [flg_c],true            ;do we ignore case differences?
        je      ic_compare              ;yes, go compare
sd3:
        clc                             ;they don't match
        jmp     short sd5
sd4:
        stc
sd5:
        pop     di                      ;curr2
        pop     si                      ;curr1
        ret


        page

;-----------------------------------------------------------------------;
;       Compare ignoring case differences.

ic_compare:
        pop     di                      ;get pointer to lines
        pop     si
        push    si                      ;re-save pointers
        push    di
sd8:
        mov     al,byte ptr [si]        ;get next char. of first line
        call    make_caps
        mov     bl,al                   ;save capitalized char
        mov     al,byte ptr [di]        ;get next chra. of second line
        call    make_caps
        cmp     al,bl
        jne     sd3                     ;they do not match....
        inc     si                      ;advance pointers
        inc     di
        loop    sd8                     ;loop for the line lengths
        jmp     short sd4               ;they match


        page

;-----------------------------------------------------------------------;
;       Compare compressing whites and ignoring case differences if
; desired too.

ib_compare:
        mov     [ib_first1],true        ;we start by the first char in the
        mov     [ib_first2],true        ; in the lines.
        pop     di                      ;get pointer to lines
        pop     si
        push    si                      ;re-save pointers
        push    di
sd9:
        mov     al,byte ptr [si]        ;get next char. of first line
        call    isa_white               ;is it a white?
        jnc     sd12                    ;no, compare....
sd10:
        mov     al,byte ptr [si+1]      ;peek to next,
        call    isa_white               ; it is a white too?
        jnc     sd11
        inc     si                      ; yes,
        jmp     short sd10              ; compress all whites to a blank
sd11:
        cmp     [ib_first1],true        ;is this the first char. of the line?
        jne     sd111                   ;no, it stays a white
        inc     si                      ;ignore the white
        jmp     short sd12
sd111:
        cmp     al,CR                   ;is this the last char. of the line
        jne     sd112                   ;no, it stays a white
        inc     si                      ;yes, ignore the whites
        jmp     short sd12
sd112:
        mov     al,' '                  ;no more whites found

sd12:
        cmp     [ib_first1],true        ;is this the first char. of the line?
        jne     sd121                   ;no, continue
        mov     [ib_first1],false       ;yes, reset the flag
sd121:
        cmp     [flg_c],true            ;do we ignore case?
        jne     sd122                   ;no,....
        call    make_caps
sd122:
        mov     bl,al                   ;save char
        mov     al,byte ptr [di]        ;get next chra. of second line
        call    isa_white
        jnc     sd15
sd13:
        mov     al,byte ptr [di+1]      ;peek to next as before
        call    isa_white
        jnc     sd14
        inc     di
        jmp     short sd13
sd14:
        cmp     [ib_first2],true        ;is this the first char. of the line?
        jne     sd141                   ;no, it stays a white
        inc     di                      ;ignore the white
        jmp     short sd15
sd141:
        cmp     al,CR                   ;is this the last char. of the line
        jne     sd142                   ;no, it stays a white
        inc     si                      ;yes, ignore the whites
        jmp     short sd15
sd142:
        mov     al,' '

sd15:
        cmp     [ib_first2],true        ;is this the first char. of the line?
        jne     sd151                   ;no, continue
        mov     [ib_first2],false       ;yes, reset the flag
sd151:
        cmp     [flg_c],true            ;do we ignore case?
        jne     sd152                   ;no,....
        call    make_caps
sd152:
        cmp     al,bl
        je      sd153
        jmp     sd3                     ;they do not match....
sd153:
        cmp     al,CR                   ;have we reached the end?
        jne     sd154                   ;no, continue....
        jmp     sd4                     ;yes, they match
sd154:
        inc     si                      ;no, advance pointers
        inc     di
        jmp     sd9                     ;loop for the line lengths


isa_white:
        cmp     al,' '                  ;is it a space?
        je      sdx1
        cmp     al,09h                  ;is it a tab?
        je      sdx1
        clc                             ;if not a white return with carry clear
        ret
sdx1:
        stc                             ;is a white return with carry set
        ret


        page

;-----------------------------------------------------------------------;
find_eol:
        xor     cx,cx                   ;zero count
        cld
sd6:
        lodsb
        cmp     al,CR
        je      sd7
        inc     cx
        jmp     short sd6
sd7:
        ret


        subttl  Subroutines: adv_b
        page

;-----------------------------------------------------------------------;
;               Get the next line in the buffer                         ;
;                                                                       ;
;       It will attempt to get the next current line from the buffer    ;
; if it fails, it will force a refill, and if some data is read in      ;
; then it will return the next current line.                            ;
;                                                                       ;
; entry:                                                                ;
;       BX      pointer to buffer structure                             ;
;                                                                       ;
; exit:                                                                 ;
;       SI      pointer to next line  (if any)                          ;
;       Carry set if no more lines available. If carry set then:        ;
;       AX      End Code: 0 = end of file reached                       ;
;                         1 = no room in buffer for a line              ;
;                                                                       ;
; modifies:                                                             ;
;       CX,DX and DI                                                    ;
;                                                                       ;
;       Called from txt_compare                                         ;
;-----------------------------------------------------------------------;
adv_b:
        call    get_nextl
        jc      se1
        ret
se1:
        call    refill
        jnc     se0
        ret
se0:
        call    get_nextl
        ret


        subttl  Subroutines: get_nextl
        page

;-----------------------------------------------------------------------;
;               Returns the next line in a buffer                       ;
;           (next from current or next from pointer)                    ;
;                                                                       ;
; entry:                                                                ;
;       BX      pointer to buffer structure                             ;
;      (SI      pointer to line, if calling get_next)                   ;
;                                                                       ;
; exit:                                                                 ;
;       SI      pointer to next line                                    ;
;       Carry set if no more lines available                            ;
;                                                                       ;
; modifies:                                                             ;
;       DI and CX                                                       ;
;                                                                       ;
;       Called from adv_b and print_diff (in the case of get_next)      ;
;-----------------------------------------------------------------------;
get_nextl:
        mov     si,word ptr [bx].curr
get_next:
        mov     cx,word ptr [bx].dat_end
        sub     cx,si
        mov     di,si
        mov     al,LF
        cld
        repnz   scasb
        mov     si,di                   ;pointer to next line
        jnz     se2                     ;not found
        clc
        ret
se2:
        inc     si                      ;point past the LF
        stc
        ret


        subttl  Subroutines: refill
        page

;-----------------------------------------------------------------------;
;               Refill a buffer                                         ;
;                                                                       ;
;       It will refill a buffer with data from the corresponding        ;
; file. It will first recompact the buffer to make room for the new     ;
; data. If in SINC then it will move the current line to the top of     ;
; the buffer, and read the data from the end of this line till the      ;
; end of the buffer.                                                    ;
;       If NOT in SINC then it will recompact the buffer by moving      ;
; all lines between the first to go out of SINC till the current line   ;
; to the top of the buffer, and then reading data after the current     ;
; line.                                                                 ;
;       When recompacting the buffer it relocates all pointers to       ;
; point to the new locations of the respective lines.                   ;
;       Some of the pointers may be pointing to meaningless locations   ;
; before the relocation, and consecuently they will be pointing to      ;
; even less meaningfull locations after relocation.                     ;
;       After reading the data it normalizes the buffer to make sure    ;
; that no partially full lines are present at the end of the buffer. If ;
; after recompacting and reading some character  it is found that the   ;
; characters read do not constitute a full line, then it will return    ;
; with an error code. It will also return with an error code if it      ;
; attempts to read past the end of file.                                ;
;                                                                       ;
; entry:                                                                ;
;       BX      pointer to buffer structure                             ;
;                                                                       ;
; exit:                                                                 ;
;       Carry set if no chars read into the buffer. If carry set then:  ;
;       AX      End Code: 0 = end of file reached                       ;
;                         1 = no room in the buffer for a line          ;
;                                                                       ;
; modifies:                                                             ;
;       CX,DX,SI and DI                                                 ;
;                                                                       ;
;       Called from adv_b                                               ;
;-----------------------------------------------------------------------;
refill:

;----- Calculate ammount to move & pointer relocation factor.

        cmp     [sinc],true
        jne     sf1
        mov     si,word ptr [bx].curr
        jmp     short sf2
sf1:
        mov     si,word ptr [bx].fst_nosinc
sf2:
        mov     di,word ptr [bx].buf
        mov     cx,word ptr [bx].dat_end

        mov     dx,si                   ;calculate pointer relocation factor
        sub     dx,di                   ;DX = factor
        jz      sf3                     ;no room in buffer
        sub     cx,si                   ;calculate ammount of data to move
        inc     cx                      ;CX = ammount

;----- Move data

        cld                             ;auto decrement
        rep     movsb

;----- Relocate pointers

        sub     word ptr [bx].curr,dx
        sub     word ptr [bx].lst_curr,dx
        sub     word ptr [bx].fst_sinc,dx
        sub     word ptr [bx].fst_nosinc,dx
        sub     word ptr [bx].dat_end,dx

sf3:
        mov     dx,word ptr [bx].dat_end
        inc     dx                              ;empty part starts here

;----- fill the buffer

        call    fill_buffer
        ret


        subttl  Subroutines: fill_buffer
        page

;-----------------------------------------------------------------------;
;               Fill the data buffers                                   ;
;                                                                       ;
;       It will fill the buffer from the pointer to the end of buffer   ;
; and normalize the buffer.                                             ;
;                                                                       ;
; entry:                                                                ;
;       BX      pointer to buffer structure                             ;
;       DX      pointer to buffer (or part of buffer)                   ;
;                                                                       ;
; exit:                                                                 ;
;       Carry set if no chars read into the buffer. If carry set then:  ;
;       AX      End Code: 0 = end of file reached                       ;
;                         1 = no room in the buffer for a line          ;
;                                                                       ;
; modifies:                                                             ;
;       AX,CX,DX and DI                                                 ;
;                                                                       ;
;       Called from txt_compare and refill                              ;
;-----------------------------------------------------------------------;
fill_buffer:
        push    bx
        call    read_dat                ;get data
        jc      bad_read
        or      ax,ax                   ;zero chars read?
        jz      rd_past_eof
        call    nor_buf
        mov     di,cx                   ;save normalized char. count
        mov     bp,dx                   ;save data end for now

;----- seek for old partial line

        or      ax,ax                   ;is the seek value = 0 ?
        jz      sg1                     ;yes, do not seek
        mov     dx,ax
        neg     dx
        mov     cx,-1
        mov     al,1                    ;seek from current position
        mov     ah,lseek
        int     21h
        jc      bad_read                ;error mesage (BX already in stack)

sg1:
        mov     cx,di                   ;restore normalized char count.
        or      cx,cx                   ;char count = 0 due to normalization?
        jz      no_room

        pop     bx
        mov     word ptr [bx].dat_end,bp
        clc
        ret

bad_read:
        mov     dx,offset dg:read_err_pre
        mov     cl,read_err_pre_len
        call    prt_err                 ;print error message
        pop     bx
        mov     dx,word ptr[bx].fname
        mov     cx,word ptr[bx].fname_len
        call    prt_err                 ;print file name
        mov     dx,offset dg:read_err_post
        mov     cl,read_err_post_len
        jmp     an_err

no_room:
        mov     ax,1
        jmp     short sg2

rd_past_eof:
        xor     ax,ax
sg2:
        pop     bx
        stc
        ret


        subttl  Subroutines: read_dat
        page

;-----------------------------------------------------------------------;
;                                                                       ;
; entry:                                                                ;
;       DX      pointer to data area (buffer or part of buffer)         ;
;                                                                       ;
; exit:                                                                 ;
;       AX      character count or error code (from DOS read)           ;
;       Carry set if error condition                                    ;
;                                                                       ;
; modifies:                                                             ;
;       BX and CX                                                       ;
;                                                                       ;
;       Called from fill_buffer, print_all and bin_compare              ;
;-----------------------------------------------------------------------;
read_dat:
        mov     cx,word ptr [bx].buf_end
        mov     bx,word ptr [bx].handle
        sub     cx,dx                   ;ammount to read to buff1
        mov     ah,read
        int     21h
        ret


        subttl  Subroutines: nor_buf
        page

;-----------------------------------------------------------------------;
;       Normalize buffers so they do not have partially full            ;
; lines at the end. If character count is less than the buffer size     ;
; then it checks that the last line is terminated by a CR,LF pair.      ;
; If it is not it inserts a CR,LF at the end. It returns a seek value   ;
; for the buffer corresponding to the number of characters in the       ;
; incomplete line at the end of the buffer (if any). This can be used   ;
; to start reading from the beggining of the incomplete line on next    ;
; time the buffer is loaded.                                            ;
;                                                                       ;
; ENTRY:                                                                ;
;       DX      buffer pointer                                          ;
;       AX      character count read                                    ;
;       CX      character count requested                               ;
;                                                                       ;
; EXIT:                                                                 ;
;       DX      pointer to last char in buffer (normalized)             ;
;       CX      character count (normalized)                            ;
;       AX      seek value                                              ;
;                                                                       ;
; MODIFIES:                                                             ;
;       DI                                                              ;
;                                                                       ;
;       Called from fill_buffer                                         ;
;-----------------------------------------------------------------------;
nor_buf:
        mov     di,dx
        add     di,ax
        dec     di                      ;points to last char in buffer
        cmp     ax,cx                   ;were all chars. requested read?
        je      sm7                     ;yes, buffer full
        cmp     byte ptr[di],1ah        ;terminated with a ^Z ?
        jne     sm1
        dec     di                      ;point to previous character
        dec     ax                      ;decrement character count
sm1:    cmp     byte ptr[di],lf         ;is last char a LF?
        je      sm6
        cmp     byte ptr[di],cr         ;is it a CR then?
        je      sm5
        add     ax,2                    ;two more chars in buffer
        inc     di
sm2:    mov     byte ptr[di],cr
sm3:    inc     di
        mov     byte ptr[di],lf
sm4:    mov     cx,ax                   ;new character count
        mov     dx,di                   ;pointer to last char
        xor     ax,ax                   ;seek = 0
        ret

sm5:
        inc     ax                      ;one more char in buffer
        jmp     short   sm3

sm6:
        cmp     byte ptr[di-1],cr       ;is previous char a CR?
        je      sm4
        inc     ax                      ;no, one more char in buffer
        jmp     short sm2

sm7:
        push    ax                      ;save char count
        mov     cx,ax
        mov     al,LF
        std
        repnz   scasb                   ;search for last LF
        pop     ax                      ;restore char count
        jnz     bad_line                ;none found, line too big
        inc     di                      ;point to last LF
        mov     dx,di
        inc     cx                      ;ammount of chars in buffer
        sub     ax,cx                   ;seek value
        ret

bad_line:                               ;full line not possible, return
        mov     dx,di                   ; with AX=count, CX=0 and DX=
        ret                             ; old last char in buffer pointer.



        subttl  Subroutines: print_diff
        page

;-----------------------------------------------------------------------;
;               print the difference between buffers                    ;
;                                                                       ;
;       It will print the mismatched lines. First it prints a heading   ;
; with the first file name, then the lines that differ from file 1,     ;
; then a heading with the second file name, and then the lines that     ;
; differ in file 2 .                                                    ;
;       The lines that differ are considered to start from fst_nosinc   ;
; till fst_sinc.                                                        ;
;                                                                       ;
;       Called from txt_compare                                         ;
;-----------------------------------------------------------------------;
print_diff:
        mov     bx,offset dg:buf1
        call    print_head              ;print heading for file 1
        mov     dx,word ptr [bx].fst_nosinc
        mov     si,word ptr [bx].fst_sinc
        call    get_next                ;get pointer to next line
        mov     cx,si
        sub     cx,dx                   ;get character count
        call    prout
        mov     bx,offset dg:buf2
        call    print_head              ;print heading for file 1
        mov     dx,word ptr [bx].fst_nosinc
        mov     si,word ptr [bx].fst_sinc
        call    get_next                ;get pointer to next line
        mov     cx,si
        sub     cx,dx                   ;get character count
        call    prout
        mov     dx,offset dg:diff_sep
        mov     cl,diff_sep_len
        xor     ch,ch
        call    prout                   ;print difference separator
        ret


        subttl  Subroutines: print_head
        page

;-----------------------------------------------------------------------;
;               Print heading for difference                            ;
;                                                                       ;
; entry:                                                                ;
;       BX      pointer to buffer structure                             ;
;                                                                       ;
; modifies:                                                             ;
;       AX,CX and DX                                                    ;
;                                                                       ;
;       Called from txt_compare and print_diff                          ;
;-----------------------------------------------------------------------;
print_head:
        mov     dx,offset dg:fname_sep
        mov     cl,fname_sep_len
        xor     ch,ch
        call    prout
        mov     dx,word ptr [bx].fname
        mov     cx,word ptr [bx].fname_len
        call    prout
        mov     dx,offset dg:CRLF
        mov     cx,2
        call    prout
        ret


        subttl  Subroutines: print_all
        page

;-----------------------------------------------------------------------;
;               Print the rest of a file                                ;
;                                                                       ;
;       If in SINC it will print the file from the fst_nosinc line      ;
; till the end of the file. If NOT in SINC then it will print from      ;
; the current line of the buffer to the end of the file.                ;
;                                                                       ;
; entry:                                                                ;
;       BX      pointer to buffer structure                             ;
;                                                                       ;
; modifies:                                                             ;
;       AX,CX and DX                                                    ;
;                                                                       ;
;       Called from txt_compare                                         ;
;-----------------------------------------------------------------------;
print_all:
        cmp     [sinc],true             ;are we in SINC?
        jne     so1
        mov     dx,word ptr [bx].curr
        jmp     short so2
so1:
        mov     dx,word ptr [bx].fst_nosinc
so2:
        mov     cx,word ptr [bx].dat_end
        inc     cx

prt_again:
        sub     cx,dx                   ;ammount of data to write
        call    prout                   ;write it out

;----- Read more data to the buffer
        push    bx                      ;save pointer to buffer struct
        mov     dx,word ptr [bx].buf
        call    read_dat
        jnc     so3
        jmp     bad_read                ;print error (BX in stack)
so3:
        or      ax,ax                   ;zero chars read?
        jne     so4
        pop     bx                      ;all done writting
        ret
so4:
        pop     bx
        mov     cx,word ptr [bx].buf_end
        jmp     short prt_again         ;print next buffer full


        subttl  Subroutines: prout and prt_err
        page

;-----------------------------------------------------------------------;
;                                                                       ;
;-----------------------------------------------------------------------;
prout:
        push    bx
        mov     bx,stdout
        mov     ah,write
        int     21h
        pop     bx
        ret


;-----------------------------------------------------------------------;
;                                                                       ;
;-----------------------------------------------------------------------;
prt_err:
        push    bx
        xor     ch,ch
        jcxz    retpbx
        mov     bx,stderr
        mov     ah,write
        int     21h
retpbx:
        pop     bx
        ret

code    ends

        page


stack   segment stack

        dw      128 dup(?)

stack   ends


        end     start
                                                           