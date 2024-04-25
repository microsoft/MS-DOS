        PAGE    ,132                            ; 
;       SCCSID = @(#)SHARELNK.asm 1.0 87/05/11
TITLE   SHARELNK LINK FIX ROUTINES - Routines to resolve SHARE externals
NAME    SHARELNK

.xlist
.xcref
INCLUDE DOSSYM.INC
INCLUDE DEVSYM.INC
.cref
.list

CODE    SEGMENT BYTE PUBLIC 'CODE'
code    ENDS

include dosseg.asm


code    SEGMENT BYTE PUBLIC 'code'
        ASSUME  CS:dosgroup

        PUBLIC  IRETT, SWAP_AREA_LEN, Hash_Temp
IRETT   DW      0
SWAP_AREA_LEN  DW  0
Hash_Temp   DW  0

procedure   LCRITDEVICE,FAR
        NOP
Endproc LCRITDEVICE,FAR

procedure   SETMEM,FAR
        NOP
endproc SETMEM,FAR

procedure   SKIPONE,FAR
        NOP
endproc SKIPONE,FAR

procedure   TWOESC,FAR
        NOP
endproc TWOESC,FAR

procedure   $STD_CON_STRING_INPUT_NO_ECHO,FAR
        NOP
endproc $STD_CON_STRING_INPUT_NO_ECHO,FAR

procedure   $STD_CON_INPUT_NO_ECHO,FAR
        NOP
endproc $STD_CON_INPUT_NO_ECHO,FAR

procedure   INT2F,FAR
        NOP
endproc   INT2F,FAR

procedure   $dup_pdb,FAR
        NOP
endproc   $dup_pdb,FAR

procedure   LEAVEDOS,FAR
        NOP
endproc   LEAVEDOS,FAR

procedure   GETCH,FAR
        NOP
endproc   GETCH,FAR

procedure   COPYONE,FAR
        NOP
endproc   COPYONE,FAR

procedure   $SETDPB,FAR
        NOP
endproc     $SETDPB,FAR

procedure   CALL_ENTRY,FAR
        NOP
endproc     CALL_ENTRY,FAR

procedure   ECRITDISK,FAR
        NOP
endproc     ECRITDISK,FAR

procedure   COPYLIN,FAR
        NOP
endproc     COPYLIN,FAR

procedure   LCRITDISK,FAR
        NOP
endproc     LCRITDISK,FAR

procedure   QUIT,FAR
        NOP
endproc     QUIT,FAR

procedure   BACKSP,FAR
        NOP
endproc     BACKSP,FAR

procedure   DIVOV,FAR
        NOP
endproc     DIVOV,FAR

procedure   STAY_RESIDENT,FAR
        NOP
endproc     STAY_RESIDENT,FAR

procedure   CTRLZ,FAR
        NOP
endproc     CTRLZ,FAR

procedure   EXITINS,FAR
        NOP
endproc     EXITINS,FAR

procedure   OKCALL,FAR
        NOP
endproc     OKCALL,FAR

procedure   SKIPSTR,FAR
        NOP
endproc     SKIPSTR,FAR

procedure   ABSDWRT,FAR
        NOP
endproc     ABSDWRT,FAR

procedure   BADCALL,FAR
        NOP
endproc     BADCALL,FAR

procedure   REEDIT,FAR
        NOP
endproc     REEDIT,FAR


procedure   INULDEV,FAR
        NOP
endproc     INULDEV,FAR

procedure   ABSDRD,FAR
        NOP
endproc     ABSDRD,FAR

procedure   SNULDEV,FAR
        NOP
endproc     SNULDEV,FAR

procedure   COPYSTR,FAR
        NOP
endproc     COPYSTR,FAR

procedure   ECRITDEVICE,FAR
        NOP
endproc     ECRITDEVICE,FAR

procedure   COMMAND,FAR
        NOP
endproc     COMMAND,FAR

procedure   ENTERINS,FAR
        NOP
endproc     ENTERINS,FAR

procedure   DEVIOCALL2,FAR
        NOP
endproc     DEVIOCALL2,FAR

procedure   FASTOPENTABLE,FAR
        NOP
endproc     FASTOPENTABLE,FAR

procedure   HEADER,FAR
        NOP
endproc     HEADER,FAR

procedure   SYSINITTABLE,FAR
        NOP
endproc     SYSINITTABLE,FAR

procedure   FETCHI_TAG,FAR
        NOP
endproc     FETCHI_TAG,FAR

procedure   IFS_DOSCALL,FAR
        NOP
endproc     IFS_DOSCALL,FAR

procedure   KILNEW,FAR
        NOP
endproc     KILNEW,FAR

procedure   PACKET_TEMP,FAR
        NOP
endproc     PACKET_TEMP,FAR

procedure   Swap_in_DOS_Len,FAR
        NOP
endproc     Swap_in_DOS_Len,FAR

procedure   swap_always_area,far
        NOP
endproc     swap_always_area,FAR

procedure   swap_always_area_len,FAR
        NOP
endproc     swap_always_area_len,FAR

procedure   swap_in_dos,FAR
        NOP
endproc     swap_in_dos,FAR

code    ENDS
    END
