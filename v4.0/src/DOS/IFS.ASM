


.xlist									  ;AN000;
include    dosseg.asm							  ;AN000;

CODE	SEGMENT BYTE PUBLIC  'CODE'                                       ;AN000;
	ASSUME	CS:DOSGROUP,  SS:DOSGROUP				  ;AN000;
.xcref									  ;AN000;
include    dossym.inc							  ;AN000;
include    devsym.inc							  ;AN000;
include    doscntry.inc 						  ;AN000;
.cref									  ;AN000;
.list
StackSize   =	180h			; gross but effective

	i_need	VERFLG		       ; verify status flag		  ;AN000;
	i_need	CNTCFLAG	       ; break status flag		  ;AN000;
	i_need	CPSWFLAG	       ; CP switch logic ON/OFF 	  ;AN000;
	I_need	CURRENTPDB,WORD        ; Current process identifier	  ;AN000;
	I_need	HIGH_SECTOR,WORD					  ;AN000;
	I_need	BUF_HASH_COUNT,WORD					  ;AN000;
	I_need	FAILERR,WORD						  ;AN000;
	I_need	USER_ID,WORD						  ;AN000;
	I_need	CALLDEVAD,DWORD       ; 				  ;AN000;
	I_need	SYSINITVAR,WORD 					  ;AN000;
	I_need	MYNAME,16	      ; NetBIOS name			  ;AN000;
	I_need	RETRYCOUNT,WORD       ; retry count			  ;AN000;
	I_need	COUNTRY_CDPG,BYTE					  ;AN000;
	i_need	DAY,BYTE	      ; date				  ;AN000;
	i_need	MONTH,BYTE						  ;AN000;
	i_need	YEAR,WORD						  ;AN000;
	i_need	CURBUF,DWORD						  ;AN000;
	i_need	IFS_DRIVER_ERR,WORD					  ;AN000;
	i_need	DOS34_FLAG,WORD       ; IFS function Read/Write flag	  ;AN000;
	i_need	Callback_SS,WORD      ; 				  ;AN000;
	i_need	Callback_SP,WORD					  ;AN000;
	i_need	SaveBX,WORD						  ;AN000;
	i_need	Temp_Var,WORD						  ;AN000;
	i_need	INDOS,BYTE						  ;AN000;
	i_need	DskStack,BYTE						  ;AN000;
	i_need	IOStack,BYTE						  ;AN000;
	i_need	Callback_flag,BYTE					  ;AN000;

DOSINFO     STRUC							  ;AN000;
bsize	  dw	0							  ;AN000;
files	  dw	0							  ;AN000;
fcbs1	  dw	0							  ;AN000;
fcbs2	  dw	0							  ;AN000;
buffers   dw	0							  ;AN000;
	  dw	0							  ;AN000;
lastdrv   dw	0							  ;AN000;
secsize   dw	0							  ;AN000;
DosInfo       ENDS							  ;AN000;



	extrn	ABSDRD:NEAR		 ;AN000;
	extrn	ABSDWRT:NEAR		 ;AN000;
	extrn	READTIME:NEAR		 ;AN000;
	extrn	CHECKFLUSH:NEAR 	 ;AN000;
	extrn	GETCURHEAD:NEAR 	 ;AN000;


;******************************************************************************
; *
; *	 MODULE: IFS_DOSCALL
; *
; *	 FUNCTION: IFS to DOS function request dispatcher
; *
; *	 FUNCTION: This procedure dispatches the IFS DOS service requests
; *		   by calling various DOS service routines
; *
; *	 CALLING SEQUENCE:
; *
; *		   CALL  DWORD PTR IFS_DOSCALL@
; *
; *
; *	 RETURN SEQUENCE:
; *
; *		   If AX = 0	No error
; *
; *		   If AX <> 0	Error
; *		      AX = Error Code:
; *
; *
; *	 INTERNAL REFERENCES:	None
; *
; *
; *	 EXTERNAL REFERENCES:	STRATEGY, INTERRUPT, ABSDRD, ABSDWRT,
; *				FIND_SECTOR, MARK_SECTOR, WRITE_BUFFR,
; *				READ_BUFFR, WRITE_BUFFR, FREE_BUFFR,
; *				GET_DOS_INFO, FLUSH_BUFF
; *
; *	 NOTES:  None
; *
; *	 REVISION HISTORY:  New
; *
; *	 COPYRIGHT:  "MS DOS IFS Function"
; *		     "Version 1.00 (C) Copyright 1988 Microsoft Corporation"
; *		     "Licensed Material - Program Property of Microsoft"
; *
; *************************************************************************





PROCEDURE   IFS_DOSCALL,FAR						  ;AN000;
 assume DS:NOTHING,ES:NOTHING						  ;AN000;

	 CLI			;					  ;AN000;
	 CMP	 AH,39		;					  ;AN000;
	 JNZ	 others 	;					  ;AN000;
	 INC	 CS:[INDOS]	; in DOS				  ;AN000;
	 JMP	 Dosend 	;					  ;AN000;
others:
	 CMP	 AH,40		;					  ;AN000;
	 JNZ	 others2	;					  ;AN000;
	 DEC	 CS:[INDOS]	; out DOS				  ;AN000;
	 JMP	 Dosend 	;					  ;AN000;
others2:
	 CMP	 AH,38		;					  ;AN000;
	 JNZ	 not_stack	;					  ;AN000;
	 PUSH	 CS		;					  ;AN000;
	 POP	 DS		;					  ;AN000;
	 MOV	 SI,OFFSET DOSGROUP:IOSTACK				  ;AN000;
	 MOV	 CX,stacksize						  ;AN000;
	 JMP	 Dosend 	;					  ;AN000;
				;					  ;AN000;
not_stack:			;					  ;AN000;
	 MOV	 CS:[Temp_Var],DS; save ds for strcmp strcpy		  ;AN000;
	 PUSH	 CS		;					  ;AN000;
	 POP	 DS		;					  ;AN000;
 assume DS:DOSGROUP							  ;AN000;
	 INC	 [INDOS]	; in DOS				  ;AN000;
	 PUSH	 CX		; save cx				  ;AN000;
	 PUSH	 DX		; save cx				  ;AN000;
	 MOV	 CX,SS		; cx=stack				  ;AN000;
	 MOV	 DX,CS		; cx=stack				  ;AN000;
	 CMP	 CX,DX		; dosgroup stack ?			  ;AN000;
	 POP	 DX		; save cx				  ;AN000;
	 POP	 CX		; restore cx				  ;AN000;
	 JZ	 withSS_SP	; yes					  ;AN000;
	 MOV	 [Callback_SS],SS ;save SS:SP				  ;AN000;
	 MOV	 [Callback_SP],SP					  ;AN000;
	 MOV	 [SaveBX],BX	;					  ;AN000;
	 MOV	 BX,CS		; prepare system stack			  ;AN000;
	 MOV	 SS,BX		;					  ;AN000;
	 MOV	 SP,OFFSET DOSGROUP:DSKSTACK				  ;AN000;
	 MOV	 BX,[SaveBX]	;					  ;AN000;
	 MOV	 [Callback_flag],1  ;set flag				  ;AN000;
withSS_SP:			;					  ;AN000;
	 STI								  ;AN000;
 ASSUME DS:NOTHING							  ;AN000;
;	 OR	 [DOS34_FLAG],Force_I24_Fail				  ;AN000;
;									  ;AN000;
;	 cmp	 ah,0		 ; call Strategy routine ??		  ;AN000;
;	 jne	 dos_chk_ah1	 ; jump if not				  ;AN000;
;	 CALL	 STRATEGY	 ; else call strategy routine		  ;AN000;
;	 jmp	 dos_exit	 ; then exit				  ;AN000;
									  ;AN000;
;Dos_Chk_Ah1:								   ;AN000;
;	 cmp	 ah,1		 ; call interrupt routine		  ;AN000;
;	 jne	 dos_chk_ah2	 ; jump if not				  ;AN000;
;	 CALL	 INTERRUPT	 ; else call interrupt routine		  ;AN000;
;	 jmp	 dos_exit	 ; then exit				  ;AN000;
									  ;AN000;
;Dos_Chk_Ah2:								   ;AN000;
;	 cmp	 ah,4					  ;AN000;
;	 jae	 Dos_Chk_Ah8				  ;AN000;
;	 mov	 High_Sector,si  ; save HI sector word	  ;AN000;
;	 mov	 dx,di		 ; save low sector	  ;AN000;
;	 push	 es					  ;AN000;
;	 invoke  FIND_DPB	 ; ds:si -> DPB 	  ;AN000;
;	 mov	 bp,si					  ;AN000;
;	 push	 ds					  ;AN000;
;	 pop	 es		 ; es:bp -> DPB 	  ;AN000;
;	 pop	 ds		 ; DS:BX-->Input buffer   ;AN000;
;
;	 cmp	 ah,2		 ; absolute read ??			  ;AN000;
;	 jne	 dos_chk_ah3	 ; jump if not				  ;AN000;
;
;	 invoke  DSKREAD	 ; else do absolute read		  ;AN000;
;	 jmp	 dos_exit	 ; then return				  ;AN000;

;Dos_Chk_Ah3:								   ;AN000;
;	 invoke  DSKWRITE	 ; do absolute write			  ;AN000;
;	 jmp	 dos_exit	 ; then exit				  ;AN000;



Dos_chk_ah32:								  ;AN000;
	 cmp	 ah,32
	 jne	 str_cmp				    ;AN000;
	 CALL	 GET_DOS_INFO	 ; else get DOS information ;AN000;
	 jmp	 SHORT dos_exit 			    ;AN000;		 ;AN000;
str_cmp:								  ;AN000;
	 mov	 DS,[Temp_Var]	  ; restore DS				  ;AN000;
	 cmp	 ah,36					    ;AN000;
	 jne	 str_cpy				    ;AN000;
	 invoke  strcmp 	 ; string compare	    ;AN000;
	 jmp	 SHORT dos_exit 					  ;AN000;
str_cpy:								  ;AN000;
	 cmp	 ah,37					    ;AN000;
	 jne	 dos_error				    ;AN000;
	 invoke  strcpy 	 ; string copy		    ;AN000;
	 jmp	 SHORT dos_exit 					  ;AN000;

Dos_Error:								  ;AN000;
	 stc
							    ;AN000;
Dos_Exit:								  ;AN000;
	 CLI								  ;AN000;
	 PUSHF								  ;AN000;
	 AND	 [DOS34_FLAG],No_Force_I24_Fail 			  ;AN000;
	 DEC	 [INDOS]	 ; exit DOS				  ;AN000;
	 CMP	 [Callback_flag],0  ;from dosgroup
	 JZ	 noSS_SP	    ;yes				  ;AN000;
	 MOV	 [Callback_flag],0  ;					  ;AN000;
	 POPF						    ;AN000;
	 MOV	 SP,CS:[Callback_SP];					     ;AN000;
	 MOV	 SS,CS:[Callback_SS]; restore user's SS:SP                   ;AN000;
	 JMP	 SHORT DOSend				    ;AN000;
noSS_SP:						    ;AN000;
	 POPF
Dosend:
	 STI			 ;					  ;AN000;

	 ret			 ;return				  ;AN000;


ENDPROC   IFS_DOSCALL					    ;AN000;





; ****************************************************************************
; *
; *	 MODULE: STRATEGY
; *
; *	 FUNCTION: Call Strategy Routine
; *
; *	 FUNCTION: This procedure dispatches the IFS DOS service requests
; *		   by calling various DOS service functions
; *
; *	 INPUT:    ES:BX ---> Device Request Header
; *		   AL  = Drive #
; *
; *		   CALL STRATEGY
; *
; *	 OUTPUT:   output of driver
; *
; *	 INTERNAL REFERENCES:	None
; *
; *
; *	 EXTERNAL REFERENCES:	GETTHISDRV
; *
; *	 NOTES:  None
; *
; *	 REVISION HISTORY:  New
; *
; *************************************************************************

;PROCEDURE   STRATEGY,NEAR						   ;AN000;

;	 INVOKE  FIND_DPB		 ; get DPB from drive number	   ;AN000;
;					 ; DS:SI-->DPB for drive	   ;AN000;
;	 LDS	 DI,DS:[SI.DPB_Driver_Addr]   ; get driver addres from DPB ;AN000;
;	 MOV	 DX,WORD PTR [DI.SDEVSTRAT]    ;get strategy routine address;AN000;
;Driver_Call:								   ;AN000;
;	 MOV	 WORD PTR [CALLDEVAD],DX	; save it		   ;AN000;
;	 MOV	 WORD PTR [CALLDEVAD+2],DS	;			   ;AN000;
;	 CALL	 DWORD	PTR  [CALLDEVAD]	; call strategy routine    ;AN000;
;STRAT_Exit:								   ;AN000;
;	 RET					; return		   ;AN000;

;ENDPROC   STRATEGY							   ;AN000;








; ****************************************************************************
; *
; *	 MODULE: INTERRUPT
; *
; *	 FUNCTION: This procedure calls the interrupt routine of the drive
; *		   specified in the drive#.
; *
; *	 INPUT:    AL = Drive #
; *
; *
; *	 OUTPUT:   output of driver
; *
; *
; *	 INTERNAL REFERENCES:	None
; *
; *
; *	 EXTERNAL REFERENCES:	FIND_DPB
; *
; *	 NOTES:  None
; *
; *	 REVISION HISTORY:  New
; *
; *************************************************************************

;PROCEDURE    INTERRUPT,NEAR						   ;AN000;

;	 INVOKE  FIND_DPB		 ; get DPB from drive number	   ;AN000;
;	 LDS	 DI,DS:[SI.DPB_Driver_Addr]   ; get driver addres from DPB ;AN000;
;	 MOV	 DX,WORD PTR [DI.SDEVINT]     ; get interrupt routine addrs;AN000;
;	 JMP	 Driver_Call						   ;AN000;

;ENDPROC  INTERRUPT							   ;AN000;








; ************************************************************************* *
; *
; *	 MODULE: Get_Dos_Info
; *
; *	 FUNCTION: Get DOS information
; *
; *	 INPUT:    AL = Dos info code
; *
; *	 OUTPUT:   Dos Information  in registers
; *
; *	 INTERNAL REFERENCES:	None
; *
; *
; *	 EXTERNAL REFERENCES:	READTIME, $GETEXTCNTRY
; *
; *	 NOTES:  None
; *
; *	 REVISION HISTORY:  New
; *
; *************************************************************************

PROCEDURE  GET_DOS_INFO,NEAR						   ;AN000;

	cmp    al,0			; TIME and DATE ??		   ;AN000;
	jne    chk_al1							   ;AN000;

	Invoke	ReadTime		; get time in CX:DX		   ;AN000;

	push	cx			; save time			   ;AN000;
	push	dx							   ;AN000;

	MOV	CX,[YEAR]						   ;AN000;
	ADD	CX,1980 						   ;AN000;
	MOV	DX,WORD PTR [DAY]	; fetch both day and month	   ;AN000;

	pop	bx			; bh = seconds	bl = hundredths    ;AN000;
	pop	ax			; ah = hour  al = minutes	   ;AN000;
					; cx = year  dh = month 	   ;AN000;
	jmp	get_info_exit						   ;AN000;


chk_al1:				; Active process info ??	   ;AN000;
	cmp    al,1							   ;AN000;
	jne    chk_al2			; no, try next			   ;AN000;
	MOV	BX,[CurrentPDB]        ; BX = active process ID 	   ;AN000;
	mov	DX,[User_ID]	       ; User ID			   ;AN000;
	jmp	get_info_exit	       ; exit				   ;AN000;


chk_al2:								   ;AN000;
;	cmp    al,2		       ; get CPSW info ??		   ;AN000;
;	jne    chk_al3		       ; jump if not			   ;AN000;
;	MOV	SI,OFFSET DOSGROUP:COUNTRY_CDPG 			   ;AN000;
;	MOV	BX,[SI.ccDosCodePage]  ; get dos code page id in BX	   ;AN000;
;	MOV	DL,CPSWFLAG	       ; get CP Switch status		   ;AN000;
;	jmp	get_info_exit	       ; exit				   ;AN000;


chk_al3:
;	cmp    al,3		       ; get CTRL BRK status ?? 	   ;AN000;
;	jne    chk_al4							   ;AN000;
;	mov    dl,CNTCFLAG	       ; DL = break status flag 	   ;AN000;
;	jmp    get_info_exit	       ; exit				   ;AN000;


chk_al4:
;	cmp    al,4		       ; get Verify status ??		   ;AN000;
;	jne    chk_al5
;	mov    dl,VERFLG	       ; DL = verify status flag	   ;AN000;
;	jmp    get_info_exit	       ; exit				   ;AN000;


chk_al5:
	cmp    al,5		      ; Config.sys info ??		   ;AN000;
	jne    chk_al6							   ;AN000;

	mov	si,OFFSET DOSGROUP:SYSINITVAR	 ; DS:SI-->SysInitVar	   ;AN000;
	push	ds							   ;AN000;
	push	si							   ;AN000;
	lds	si,[si].Sysi_SFT      ; get SFT address 		   ;AN000;
	mov	ax,[si].SFCount       ; get number of files		   ;AN000;
	lds	si,[si].SFlink	      ; get next SFT table		   ;AN000;
	cmp	si,-1		      ; end of table			   ;AN000;
	jz	nomore		      ; 				   ;AN000;
	add	ax,[si].SFCount       ; 				   ;AN000;
nomore: 			      ; 				   ;AN000;
	mov	es:[di].files,ax	 ; save files= value		   ;AN000;
	pop	si							   ;AN000;
	pop	ds							   ;AN000;
	mov	ax,[si].Sysi_MaxSec	 ; get maximum sector size	   ;AN000;
	mov	es:[di].secsize,ax	 ; save files= value		   ;AN000;
	mov	ax,[si].Sysi_Keep	 ;				   ;AN000;
	mov	es:[di].fcbs2,ax	 ;				   ;AN000;
	lds	si,[si].Sysi_FCB      ; get FCB address 		   ;AN000;
	mov	ax,[si].SFCount       ; get number of fcbs		   ;AN000;
	mov	es:[di].fcbs1,ax	 ; save fcbs=  value		   ;AN000;
	jmp	get_info_exit						   ;AN000;



chk_al6:								  ;AN000;
	cmp    al,6			; get machine name ??		  ;AN000;
	jne    chk_al7			; no, check next function	  ;AN000;
	context  DS							  ;AN000;
	mov	si,offset DOSGroup:MyName   ; DS:SI-->name string	  ;AN000;
					; ES:DI-->return buffer 	  ;AN000;
	add	di,2			; skip max return size		  ;AN000;
	mov	cx,15			; name size			  ;AN000;
Chk6_Loop:								  ;AN000;
	rep	movsb			; copy machine name to return buffer;AN000;
	xor	al,al			; set 16th byte is 0		   ;AN000;
	stosb								   ;AN000;
	jmp	get_info_exit		; return			   ;AN000;
									   ;AN000;
									   ;AN000;
Chk_Al7:								   ;AN000;
;	cmp	al,7			; get country information ??	   ;AN000;
;	jne	chk_al8 		; no, try next function 	   ;AN000;
;	mov	al,dl			; AL = info ID			   ;AN000;
;	mov	bx,-1			; select active code page	   ;AN000;
;	mov	dx,-1			; select active country 	   ;AN000;
;	mov	cx,-1			; get all			   ;AN000;
;	INVOKE	$getExtCntry		; get country info		   ;AN000;
;	jmp	SHORT Get_Info_Exit	; exit				   ;AN000;


Chk_Al8:								   ;AN000;
	cmp	al,8			; get share retry count ??	   ;AN000;
	jne	bad_param		; no, Bad parameter		   ;AN000;
	mov	bx,RetryCount		; BX = Share retry count	   ;AN000;
	jmp	SHORT Get_Info_Exit	      ; exit			   ;AN000;

Bad_Param:				; Bad parameter 		   ;AN000;
	stc				;				   ;AN000;

Get_Info_Exit:				; exit				   ;AN000;

	ret								   ;AN000;


ENDPROC   GET_DOS_INFO							   ;AN000;








; ************************************************************************* *
; *
; *	 MODULE: $IFS_IOCTL
; *
; *	 FUNCTION: Handle IFS Driver IOCTL calls
; *
; *	 INPUT:    AH = 6B  function code
; *		   AL = XX  00 = Drive IOCTL, 01 = Psudo device IOCTL
; *		   CX = 00  Reserved
; *		   BL = XX  Device Number
; *		   DS:DX    Pointer to Buffer
; *
; *	 OUTPUT:
; *		   IF CARRY = 0  No Error
; *		   IF CARRY = 1  Error
; *			 AX = ERROR CODE
; *
; *	 INTERNAL REFERENCES:	None
; *
; *
; *	 EXTERNAL REFERENCES:	INT 2F
; *
; *	 NOTES:  None
; *
; *	 REVISION HISTORY:  New
; *************************************************************************

PROCEDURE  $IFS_IOCTL,NEAR						   ;AN000;

	PUSH	AX							   ;AN000;
	MOV	AX,(multnet SHL 8) OR 47    ; pass control to IFS Func	   ;AN000;
	INT	2FH							   ;AN000;
	POP	BX							   ;AN000;
	JC	ABB_ERR 						   ;AN000;
	TRANSFER   SYS_RET_OK		      ; return			   ;AN000;

ABB_ERR:								   ;AN000;
	transfer SYS_RET_ERR		    ; error return		   ;AN000;

ENDPROC  $IFS_IOCTL							   ;AN000;



CODE	ENDS								   ;AN000;
    END 								   ;AN000;


