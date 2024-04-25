        page    80,132
;******************* START OF SPECIFICATIONS ***********************************
;
; MODULE NAME:          SHARE.EXE     (a true EXE file)
;
; DESCRIPTIVE NAME:     SHARE resident service routines - part 1 - GSHARE.SAL
;                                                       - part 2 - GSHARE2.SAL
;                                                       - part 3 - SHARESR.SAL
;
; FUNCTION:             Provide file sharing services for DOS
;
; ENTRY POINT:          DOS Jump Table - installed by SHARE at initalization
;
;                             MFT_Enter          1
;                             MFTClose           2
;                             MFTClu             3
;                             MFTCloseP          4
;                             MFTCloN            5
;                             Set_Mult_Block     6
;                             Clr_Mult_Block     7
;                             Chk_Block          8
;                             MFT_Get            9
;
; INPUT:                See Prolog to individual entry points
;
; EXIT NORMAL:          CF = 0 and requested task performed.
;
; EXIT ERROR:           CF = 1 ans error code in AX
;
; INTERNAL REFERENCES:
;
;       ROUTINES:       Set_Block               BCS
;                       Clr_Block               CSL
;                       CLP                     CUC
;                       Load_Regs               CSI
;                       ASC                     GOM
;
;       DATA AREAS:
;
; EXTERNAL REFERENCES:  INT 21       INT 2F
;     together with:
;
;     fnm:near, rsc:near, rmn:near, cps:near, ofl:near, sle:near, interr:near
;
;       ROUTINES:
;
;       DATA AREAS:
;
; NOTES:                The second part of this utility is GSHARE2.ASM
;
; REVISION HISTORY:       Version 1.0  09/09/83 - first release              GL
;                                      09/13/83 - Installability             MZ
;                                      01/11/84 - FCB compatability changes  MZ
;                         PTM P000438  08/21/86 - SFT LCK FIELDS not 0 error DL
;                   Ax000 Ver 4.0      04/15/87 - changed:- Set_Block        FJG
;                                                         - Clr_Block        FJG
;                                                         - Chk_Block        FJG
;                                                         - CLP              FJG
;                                                  new:   - Set_Mult_Block   FJG
;                                                         - Clr_Mult_Block   FJG
;                                                         - Load_Regs        FJG
;                                                         - Clr_List         FJG
;                   Ax002  PTM P001658  10/15/87 - changed I/F to IBMDOS     FJG
;                   Ax003  PTM P002064  10/15/87 - ShSU SFT - IFS call error FJG
;                   Ax004  PTM P002121  10/29/87 - Clr_Mult_Block cx=-1 err  FJG
;                   Ax005  PTM P002322  11/06/87 - Call_IFS - 2F semaphore   FJG
;                   Ax006  DCR D000494  12/17/87 - DOS 4.00 function reductionFJG
;                   Ax007  PTM P003841  03/17/88 - access error for Turbo L  FJG
;                   Ax008  PTM P003880  03/17/88 - duped handle error        FJG
;                   Ax009  PTM P003910  03/17/88 - wrong parse error format  FJG
;                   Ax010  DCR D000526  04/27/88 - add /nc switch support    FJG
;                   Ax011  PTM P004546  05/03/88 - add /nc support to fShare FJG
