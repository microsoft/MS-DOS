TITLE	EXTATTR- Extended Attributes
NAME	EXTATTR
;
; Get or Set Extended Attributes by handle
;
;
;   GetSetEA
;   Set_Output
;   Search_EA
;   Copy_QEA
;   Set_one_EA
;   Get_one_EA
;   Get_Value
;   GSetDevCdpg
;   Get_max_EA_size
;
;   Revision history
;
;	   A000   version 4.00  Jan. 1988
;
;
;
;
;
;
;

.xlist
;
;
; get the appropriate segment definitions
;
include dosseg.asm			     ;AN000;

CODE	SEGMENT BYTE PUBLIC  'CODE'          ;AN000;
	ASSUME	SS:DOSGROUP,CS:DOSGROUP      ;AN000;

.xcref
INCLUDE DOSSYM.INC			     ;AN000;
INCLUDE DEVSYM.INC			     ;AN000;
include EA.inc				     ;AN000;
.cref
.list
.sall


;	I_need	XA_from,BYTE		;AN000;

;	I_need	XA_TABLE,BYTE		;AN000;
;	I_need	XA_TEMP,WORD		;AN000;
;	I_need	XA_COUNT,WORD		;AN000;
;	I_need	XA_DEVICE,BYTE		;AN000;
	I_need	XA_TYPE,BYTE		;AN000;
	I_need	SAVE_ES,WORD		;AN000;
	I_need	SAVE_DI,WORD		;AN000;
	I_need	SAVE_DS,WORD		;AN000;
	I_need	SAVE_SI,WORD		;AN000;
	I_need	SAVE_CX,WORD		;AN000;
	I_need	SAVE_BX,WORD		;AN000;
;	I_need	XA_handle,WORD		;AN000;
;	I_need	CPSWFLAG,BYTE		;AN000;
;	I_need	XA_PACKET,BYTE		;AN000;
;	I_need	MAX_EA_SIZE,WORD	;AN000;
;	I_need	MAX_EANAME_SIZE,WORD	;AN000;
;	I_need	THISSFT,DWORD		;AN000;
;IF DBCS				;AN000;
;	I_need	DBCS_PACKET,BYTE	;AN000; 				;AN000;
;ENDIF					;AN000; 				;AN000;
										;AN000;
										;AN000;
										;AN000;
										;AN000;
										;AN000;
BREAK <GetSet_EA get or set extended attributes by handle>			;AN000;
										;AN000;
;      Input: [XA_type] = function code, (e.g., get,set)			;AN000;
;	      [ThisSFT] points to SFT						;AN000;
;	      ES:BP points to drive parameter block				;AN000;
;	      [XA_from] = By_Create or By_EA					;AN000;
;	      [SAVE_ES]:[SAVE_DI]  points to get/set list			;AN000;
;	      [SAVE_DS]:[SAVE_SI]  points to get query list			;AN000;
;	      [SAVE_CX] = size of buffer
;	      [XA_device]= 1 device, 0 file					;AN000;
;	      [XA_handle] for device						;AN000;
;	Function: Get or Set extended attributes by handle			;AN000;
;	Output: carry set: error						;AN000;
;		carry clear: extended attributes are successfully get/set	;AN000;
;			     extended attribute cluster may be created		;AN000;
;										;AN000;
;										;AN000;
;										;AN000;
										;AN000;
										;AN000;
procedure   GetSet_XA,near					   ;AN000;
	ASSUME	CS:DOSGROUP,DS:NOTHING,ES:NOTHING,SS:DOSGROUP	   ;AN000;


	LES    DI,DWORD PTR [SAVE_DI]  ;AN000;;FT. ES:DI -> query list
;;	MOV    [SAVE_BX],2	       ;AN000;;FT. size returned
;;	XOR    DX,DX		       ;AN000;;FT. dx=0, codepage id

	CMP    [XA_type],2	       ;AN000;;FT. get EA  ?
	JNZ    eaname		       ;AN000;;FT. no
getEAs: 			       ;AN000;
	CMP    [SAVE_CX],0	       ;AN000;;FT. get max data size
	JNZ    notmax		       ;AN000;;FT. no
;;	CALL   Get_max_EA_size	       ;AN000;;FT.

	MOV    CX,2		       ;AN000;;FT. FAKE FAKE..............
	JNC    set_user_cx	       ;AN000;;FT.
	JMP    OKexit		       ;AN000;;FT. error
notmax:
	CMP    [SAVE_CX],1	       ;AN000;;FT. buffer size =1   ?
	JNZ    goodsiz		       ;AN000;;FT. no
errout: 			       ;AN000;
	JMP    insuff_space	       ;AN000;;FT. no error
goodsiz:			       ;AN000;
	MOV    WORD PTR ES:[DI],0      ;AN000;FT. FAKE FAKE ...............
	MOV    CX,2		       ;AN000;FT. FAKE FAKE ...............
	JMP    set_user_cx	       ;AN000;FT. FAKE FAKE ...............

;	SUB    [SAVE_CX],2	       ;AN000;;FT. minus count size
;	CMP    [SAVE_SI],-1	       ;AN000;;FT. get all ?
;	JNZ    getsome		       ;AN000;;FT. no
;	PUSH   CS		       ;AN000;;FT. ds:si-> EA entry addr
;	POP    DS		       ;AN000;;FT.
;	INC    DI		       ;AN000;;FT.
;	INC    DI		       ;AN000;;FT. es:di -> address after count
;	MOV    SI,OFFSET DOSGROUP:XA_TABLE  ;AN000;FT.
;	MOV    CX,XA_COUNT	       ;AN000;;FT. cx= number of EA entries
;;;;;;
;getone:
;	CALL   GET_ONE_EA	       ;AN000;;FT. get EA
;	JC     setout		       ;AN000;;FT. insufficient memory
;	INC    DX		       ;AN000;;FT. next EA ID
;	LOOP   getone		       ;AN000;;FT. next one
;setout:			       ;AN000;
;	CALL   Set_Output	       ;AN000;;FT.
;	OR     CX,CX		       ;AN000;;FT.
;	JNZ    errout		       ;AN000;;FT.
;
;	JMP    OKexit		       ;AN000;;FT.
eaname:
	CMP    [XA_type],3	       ;AN000;;FT. get EA name?`
	JZ     geteaname	       ;AN000;;FT. yes
	JMP    setea		       ;AN000;;FT.
geteaname:
;	MOV    [SAVE_SI],-1	       ;AN000;;FT. make get all
	CMP    [SAVE_CX],0	       ;AN000;;FT. get max data size
	JNZ    notmax		       ;AN000;;FT. no
	MOV    CX,2		       ;AN000;;FT. FAKE FAKE ......................
;;	MOV    CX,[MAX_EANAME_SIZE]    ;AN000;;FT. get name size
set_user_cx:			       ;AN000;
	invoke get_user_stack	       ;AN000;;FT. get user stack
	MOV    [SI.user_CX],CX	       ;AN000;;FT.
	JMP    OKexit		       ;AN000;;FT. exit

getsome:			       ;AN000;
;	LDS    SI,DWORD PTR [SAVE_SI]  ;AN000;;FT.
;	LODSW			       ;AN000;;FT.
;	MOV    CX,AX		       ;AN000;;FT. cx=number of query entries
;	JCXZ   setout		       ;AN000;;FT. yes
;	STOSW			       ;AN000;;FT. es:di -> EA
;get_next_EA:			       ;AN000;
;	PUSH   DS		       ;AN000;;FT. save ds:si
;	PUSH   SI		       ;AN000;;FT.	es:di
;	PUSH   ES		       ;AN000;;FT.
;	PUSH   DI		       ;AN000;;FT.
;	CALL   Search_EA	       ;AN000;;FT. search query EA from table
;	JC     EAnotFound	       ;AN000;;FT. EA not found
;	PUSH   ES		       ;AN000;;FT.
;	POP    DS		       ;AN000;;FT.
;	MOV    SI,DI		       ;AN000;;FT. ds:si -> found EA
;	POP    DI		       ;AN000;;FT. es:di -> buffer
;	POP    ES		       ;AN000;;FT.
;	CALL   GET_ONE_EA	       ;AN000;;FT. copy to buffer
;	POP    SI		       ;AN000;;FT.
;	POP    DS		       ;AN000;;FT.
;	JC     setfinal 	       ;AN000;;FT. memory not enough
;	MOV    AL,[SI.QEA_NAMELEN]     ;AN000;;FT.
;	XOR    AH,AH		       ;AN000;;FT.
;	ADD    AX,QEA_NAME	       ;AN000;;FT.
;	ADD    SI,AX		       ;AN000;;FT. ds:si -> next query entry
;testend:			       ;AN000;
;	LOOP   get_next_EA	       ;AN000;;FT. do next
;setfinal:			       ;AN000;
;	LDS    SI,DWORD PTR [SAVE_SI]  ;AN000;;FT.
;	MOV    DX,[SI]		       ;AN000;;FT.
;	SUB    DX,CX		       ;AN000;;FT. dx= returned count
;	JMP    setout		       ;AN000;;FT.
;EAnotFound:			       ;AN000;
;	POP    DI		       ;AN000;;FT. restore regs
;	POP    ES		       ;AN000;;FT.
;	POP    SI		       ;AN000;;FT.
;	POP    DS		       ;AN000;;FT.
;
;	CALL   COPY_QEA 	       ;AN000;;FT. copy query EA to buffer
;	JC     setfinal 	       ;AN000;;FT. not enough memory
;	JMP    testend		       ;AN000;;FT.
setea:				       ;AN000;
	JMP    OKexit		       ;AN000;;FT. FAKE FAKE ..........
;	LDS    SI,DWORD PTR [SAVE_DI]  ;AN000;;FT.
;	LODSW			       ;AN000;;FT.
;	MOV    CX,AX		       ;AN000;;FT. cx=number of query entries
;	OR     CX,CX		       ;AN000;;FT. cx=0 ?
;	JZ     OKexit		       ;AN000;;FT. yes
;set_next:			       ;AN000;
;	CALL   Search_EA	       ;AN000;;FT.
;	JNC    toset		       ;AN000;;FT.
;set_reason:			       ;AN000;
;	CLC			       ;AN000;;FT. clear acrry
;	MOV    [SI.EA_RC],AL	       ;AN000;;FT. set reason code
;	DEC    CX		       ;AN000;;FT. end of set ?
;	JZ     OKexit		       ;AN000;;FT. yes

;	MOV    AL,[SI.EA_NAMELEN]      ;AN000;;FT.
;	XOR    AH,AH		       ;AN000;;FT.
;	ADD    AX,[SI.EA_VALLEN]       ;AN000;;FT.
;	ADD    SI,EA_NAME	       ;AN000;;FT.
;	ADD    SI,AX		       ;AN000;;FT. es:di -> next EA entry
;	JMP    set_next 	       ;AN000;;FT.
;toset: 			       ;AN000;
;	CALL   SET_ONE_EA	       ;AN000;;FT. set it
;	JMP    set_reason	       ;AN000;;FT.
 insuff_space:			       ;AN000;;FT.
;	MOV    AX,error_not_enough_memory	 ;AN000;FT. insufficient memory err
;	STC					 ;AN000;
OKexit: 					 ;AN000;
	return					 ;AN000;

EndProc GetSet_XA				 ;AN000;


; Input: [SAVE_ES]:[SAVE_DI] points to buffer
;	 [SAVE_BX]= returned size
;	 DX= returned count
; Function: set returned size and count 					;AN000;
; Output: none
										;AN000;
;procedure   Set_Output,NEAR							 ;AN000;
;	ASSUME	CS:DOSGROUP,DS:NOTHING,ES:NOTHING,SS:DOSGROUP			;AN000;
;										;AN000;
;	LES    DI,DWORD PTR [SAVE_DI]  ;FT. es:di -> count			;AN000;
;	MOV    ES:[DI],DX	       ;FT.					;AN000;
;	MOV    BX,[SAVE_BX]	       ;FT. cx=size returned			;AN000;
;	invoke get_user_stack	       ;FT. get user stack			;AN000;
;	MOV    [SI.user_CX],BX	       ;FT.					;AN000;
;	return			       ;FT.					;AN000;
;										;AN000;
;EndProc Set_Output								 ;AN000;


; Input: DS:SI= query EA addr							;AN000;
; Function: search the EA							;AN000;
; Output: carry clear
;	 DX= EA ID (0 codpage, 1  Filetype, etc.)
;	 ES:DI points to found entry
;	  carry set, not found, AL= reason code 				;AN000;
										;AN000;
;procedure   Search_EA,NEAR							 ;AN000;
;	ASSUME	CS:DOSGROUP,DS:NOTHING,ES:NOTHING,SS:DOSGROUP			;AN000;
;										;AN000;
;	PUSH   CX				 ;FT. save entry count		;AN000;
;	MOV    AL,EARCNOTFOUND			 ;FT. preset error code 	;AN000;
;	MOV    BL,[SI.QEA_NAMELEN]		 ;FT.	     ?			;AN000;
;	CMP    [XA_TYPE],4			 ;FT. set    ?			;AN000;
;	JNZ    gettyp				 ;FT. no			;AN000;
;	MOV    BL,[SI.EA_NAMELEN]		 ;FT.	     ?			;AN000;
;gettyp:
;	OR     BL,BL				 ;FT.				;AN000;
;	JZ     not_found			 ;FT.				;AN000;
;	PUSH   CS				 ;FT. ds:si-> EA entry addr	;AN000;
;	POP    ES				 ;FT.				;AN000;
;	MOV    DI,OFFSET DOSGROUP:XA_TABLE	 ;FT.				;AN000;
;	MOV    CX,XA_COUNT			 ;FT. cx= number of EA entries	;AN000;
;	XOR    DX,DX				 ;FT. dx=0, codepage id 	;AN000;
;
;start_find:
;	PUSH   CX				 ;FT. save entry count		;AN000;
;	MOV    CL,BL				 ;FT.				;AN000;
;	XOR    CH,CH				 ;FT. get name len		;AN000;
;	PUSH   SI				 ;FT.				;AN000;
;	PUSH   DI				 ;FT.				;AN000;
;	CMP    [XA_TYPE],4			 ;FT. set    ?			;AN000;
;	JNZ    gettyp2				 ;FT. no			;AN000;
;	ADD    SI,EA_NAME			 ;FT.				;AN000;
;	JMP    short updi			 ;FT.				;AN000;
;gettyp2:
;	ADD    SI,QEA_NAME			 ;FT. compare EA names		;AN000;
;updi:
;	ADD    DI,EA_NAME			 ;FT.				;AN000;
;	REP    CMPSB				 ;FT.				;AN000;
;	POP    DI				 ;FT.				;AN000;
;	POP    SI				 ;FT.				;AN000;
;	POP    CX				 ;FT.				;AN000;
;	JNZ    not_matched			 ;FT. name not matched		;AN000;
;	MOV    AL,EARCDEFBAD			 ;FT. preset error code 	;AN000;
;	PUSH   SI				 ;FT.				;AN000;
;	PUSH   DI				 ;FT.				;AN000;
;	CMPSB					 ;FT. compare type		;AN000;
;	JNZ    not_matched2			 ;FT. type not matched		;AN000;
;	CMPSW					 ;FT. compare flags		;AN000;
;	JNZ    not_matched2			 ;FT. flag not matched		;AN000;
;	POP    DI				 ;FT.				;AN000;
;	POP    SI				 ;FT. found one 		;AN000;
;	JMP    SHORT found_one			 ;FT.				;AN000;
;not_matched:
;	DEC    CX				 ;FT. end of table		;AN000;
;	JZ     not_found			 ;FT. yes			;AN000;
;	MOV    AL,ES:[DI.EA_NAMELEN]		 ;FT.				;AN000;
;	XOR    AH,AH				 ;FT.				;AN000;
;
;	ADD    DI,EA_NAME			 ;FT.				;AN000;
;	ADD    DI,AX				 ;FT. es:di -> next EA entry	;AN000;
;	INC    DX				 ;FT. increment EA ID		;AN000;
;	JMP    start_find			 ;FT.				;AN000;
;not_matched2:
;	POP    DI				 ;FT.				;AN000;
;	POP    SI				 ;FT.				;AN000;
;	JMP    not_matched			 ;FT.				;AN000;
;not_found:
;	STC					 ;FT.				;AN000;
;found_one:
;	POP    CX				 ;FT.				;AN000;
;	return					 ;FT.				;AN000;
										;AN000;
;EndProc Search_EA								 ;AN000;
										;AN000;
; Input: ES:DI= buffer address							;AN000;
;	 DS:SI= EA entry address
;	 [SAVE_CX]= buffer size
;	 AL = reason code
; Function: move one query entry to buffer					;AN000;
; Output: carry clear
;	    DS:SI points to next entry
;	    ES:DI points to next entry
;	    [SAVE_CX],[SAVE_BX], updated					       ;AN000;
;	  carry set, insufficient memory error					;AN000;
										;AN000;
;procedure   COPY_QEA,NEAR							 ;AN000;
;	ASSUME	CS:DOSGROUP,DS:NOTHING,ES:NOTHING,SS:DOSGROUP			;AN000;
;										;AN000;
;	PUSH   CX				 ;FT.				;AN000;
;	MOV    DL,AL				 ;FT.				;AN000;
;	MOV    CX,EA_NAME -EA_TYPE		 ;FT.				;AN000;
;
;	MOV    BL,[SI.QEA_NAMELEN]		 ;FT.				;AN000;
;	XOR    BH,BH				 ;FT.				;AN000;
;	ADD    CX,BX				 ;FT. cx= query EA size 	;AN000;
;	CMP    CX,[SAVE_CX]			 ;FT. > buffer size		;AN000;
;	JA     sizeshort2			 ;FT. yes			;AN000;
;	PUSH   CX				 ;FT.				;AN000;
;	LODSB					 ;FT. move type 		;AN000;
;	STOSB					 ;FT.				;AN000;
;	LODSW					 ;FT.				;AN000;
;	STOSW					 ;FT. move flag 		;AN000;
;	MOV    AL,DL				 ;FT. move RC			;AN000;
;	STOSB					 ;FT.				;AN000;
;
;	LODSB					 ;FT. move name len		;AN000;
;	MOV    CL,AL				 ;FT.				;AN000;
;	STOSB					 ;FT.				;AN000;
;	XOR    AX,AX				 ;FT. zero value length 	;AN000;
;	STOSW					 ;FT.				;AN000;
;	OR     CL,CL				 ;FT.				;AN000;
;	JZ     zeroname 			 ;FT.				;AN000;
;	XOR    CH,CH				 ;FT.				;AN000;
;
;	REP    MOVSB				 ;FT. move EA to buffer 	;AN000;
;zeroname:
;	POP    CX				 ;FT.				;AN000;
;	ADD    [SAVE_BX],CX			 ;FT. bx=bx+entry size		;AN000;
;	SUB    [SAVE_CX],CX			 ;FT. update buffer size	;AN000;
;	CLC					 ;FT.				;AN000;
;	JMP    SHORT okget2			 ;FT.				;AN000;
;
;sizeshort2:
;	MOV    AX,error_not_enough_memory	 ;FT.  error			;AN000;
;	STC					 ;FT.				;AN000;
;okget2:
;	POP    CX				 ;FT.				;AN000;
;	return				    ;FT.				;AN000;
;										;AN000;
;EndProc COPY_QEA								 ;AN000;
										;AN000;
; Input: ES:DI= found EA entry addr						;AN000;
;	 DS:SI= source EA entry address
;	 DX= EA ID (0 codpage, 1  Filetype, etc.)
; Function: set one EA								;AN000;
; Output: carry clear
;	    EA set
;	  carry set, AL= reason code						;AN000;
										;AN000;
;procedure   SET_ONE_EA,NEAR							 ;AN000;
;	ASSUME	CS:DOSGROUP,DS:NOTHING,ES:NOTHING,SS:DOSGROUP			;AN000;
;										;AN000;
;	PUSH   CX				 ;FT.				;AN000;
;	MOV    AL,EARCDEFBAD			 ;FT.  prseet error code	;AN000;
;	MOV    BX,[SI.EA_VALLEN]		 ;FT.				;AN000;
;	CMP    BX,ES:[DI.EA_VALLEN]		 ;FT.  length equal ?		;AN000;
;	JNZ    notset				 ;FT.  no			;AN000;
;	PUSH   DS				 ;FT.				;AN000;
;	PUSH   SI				 ;FT.				;AN000;
;	MOV    AL,[SI.EA_NAMELEN]		 ;FT.				;AN000;
;	XOR    AH,AH				 ;FT.				;AN000;
;	ADD    SI,EA_NAME			 ;FT.				;AN000;
;	ADD    SI,AX				 ;FT.				;AN000;
;	CMP    DX,0				 ;FT.				;AN000;
;	JNZ    set_filetyp			 ;FT.				;AN000;
;	LODSW					 ;FT.				;AN000;
;	CMP    [XA_DEVICE],0			 ;FT. device ?			;AN000;
;	JZ     notdevice			 ;FT. no			;AN000;
;	OR     AX,AX				 ;FT. code page 0 ?		;AN000;
;	JZ     NORM0				 ;FT. yes			;AN000;
;
;	CALL   GSetDevCdPg			 ;FT.				;AN000;
;	JNC    welldone 			 ;FT.				;AN000;
;	CMP    [CPSWFLAG],0			 ;FT. code page matching on	;AN000;
;	JZ     NORM0				 ;FT. no			;AN000;
;	invoke SAVE_WORLD			 ;FT. save all regs		;AN000;
;	LDS    SI,[THISSFT]			 ;FT. ds:si -> sft		;AN000;
;	LDS    SI,[SI.sf_devptr]		 ;FT. ds:si -> device header	;AN000;
;	MOV    BP,DS				 ;FT. save all regs		;AN000;
;	invoke Code_Page_Mismatched_Error	 ;FT.				;AN000;
;	CMP    AL,0				 ;FT. ignore ?			;AN000;
;	JZ     NORM1				 ;FT.				;AN000;
;	invoke RESTORE_WORLD			 ;FT. save all regs		;AN000;
;NORM0:
;	MOV    AL,EARCDEVERROR			 ;FT.				;AN000;
;	STC					 ;FT.				;AN000;
;	JMP    SHORT sdone			 ;FT.				;AN000;
;NORM1:
;	invoke RESTORE_WORLD			 ;FT. save all regs		;AN000;
;	JMP    SHORT welldone			 ;FT.				;AN000;
;notdevice:
;	LDS    SI,[THISSFT]			 ;FT.				;AN000;
;	MOV    [SI.sf_CodePage],AX		 ;FT. set codepege		;AN000;
;	JMP    SHORT welldone			 ;FT.
;set_filetyp:
;	LODSB					 ;FT.				;AN000;
;	LDS    SI,[THISSFT]			 ;FT. set filtype		;AN000;
;	MOV    [SI.sf_ATTR_HI],AL		 ;FT.				;AN000;
;
;welldone:
;	XOR    AL,AL				 ;FT.  success			;AN000;
;sdone:
;	POP    SI				 ;FT.				;AN000;
;	POP    DS				 ;FT.				;AN000;
;notset:
;	POP    CX				 ;FT.				;AN000;
;	 return 				  ;FT.				 ;AN000;
										;AN000;
;EndProc SET_ONE_EA								 ;AN000;
										;AN000;
; Input: ES:DI= buffer address							;AN000;
;	 DS:SI= EA entry address
;	 [SAVE_CX]= buffer size available
;	 [SAVE_BX]= size returned
;	 DX= EA ID (0 codpage, 1  Filetype, etc.)
; Function: move one EA entry to the buffer					;AN000;
; Output: carry clear
;	    DS:SI points to next entry
;	    ES:DI points to next entry
;	    [SAVE_CX],BX, updated						;AN000;
;	  carry set, insufficient memory error					;AN000;
										;AN000;
;procedure   GET_ONE_EA,NEAR							 ;AN000;
;	ASSUME	CS:DOSGROUP,DS:NOTHING,ES:NOTHING,SS:DOSGROUP			;AN000;
;										;AN000;
;	PUSH   CX				 ;FT.				;AN000;
;	CMP    [XA_TYPE],2			 ;FT. type 2 ?			;AN000;
;	JZ     gtyp2				 ;FT. yes			;AN000;
;	MOV    CX,QEA_NAME - QEA_TYPE		 ;FT.				;AN000;
;	JMP    SHORT addnmlen			 ;FT.
;gtyp2:
;	MOV    CX,EA_NAME - EA_TYPE		 ;FT. cx = EA entry size	;AN000;
;	ADD    CX,[SI.EA_VALLEN]		 ;FT.				;AN000;
;addnmlen:
;	MOV    AL,[SI.EA_NAMELEN]		 ;FT.
;	XOR    AH,AH				 ;FT.				;AN000;
;	ADD    CX,AX				 ;FT.				;AN000;
;	CMP    CX,[SAVE_CX]			 ;FT. > buffer size		;AN000;
;	JA     sizeshort			 ;FT. yes			;AN000;
;	PUSH   CX				 ;FT.				;AN000;
;	LODSB					 ;FT. move type 		;AN000;
;	STOSB					 ;FT.				;AN000;
;	LODSW					 ;FT.				;AN000;
;	STOSW					 ;FT. move flag 		;AN000;
;	LODSB					 ;FT. EA list need RC		;AN000;
;	CMP    [XA_TYPE],2			 ;FT.				;AN000;
;	JNZ    norc				 ;FT.				;AN000;
;	STOSB					 ;FT.				;AN000;
;norc:
;	LODSB					 ;FT. move name len		;AN000;
;	STOSB					 ;FT.				;AN000;
;	MOV    CL,AL				 ;FT.				;AN000;
;	XOR    CH,CH				 ;FT.				;AN000;
;	LODSW					 ;FT. EA list need value len	;AN000;
;	CMP    [XA_TYPE],2			 ;FT.				;AN000;
;	JNZ    novalen				 ;FT.				;AN000;
;	STOSW					 ;FT.				;AN000;
;novalen:
;
;	REP    MOVSB				 ;FT. move EA to buffer 	;AN000;
;	CMP    [XA_TYPE],2			 ;FT.				;AN000;
;	JNZ    novalue				 ;FT.				;AN000;
;	CALL   GET_VALUE			 ;FT. get value for type 2	;AN000;
;novalue:
;	POP    CX				 ;FT.				;AN000;
;	ADD    [SAVE_BX],CX			 ;FT. add entry size		;AN000;
;	LES    DI,DWORD PTR [SAVE_DI]		 ;FT.				;AN000;
;	ADD    DI,[SAVE_BX]			 ;FT. es:di -> next entry	;AN000;
;	SUB    [SAVE_CX],CX			 ;FT. update buffer size	;AN000;
;	CLC					 ;FT.				;AN000;
;	JMP    SHORT okget			 ;FT.				;AN000;
;
;sizeshort:
;	MOV    AX,error_not_enough_memory	 ;FT.  error			;AN000;
;	STC					 ;FT.				;AN000;
;okget:
;	POP    CX				 ;FT.				;AN000;
;	return				    ;FT.				;AN000;
;										;AN000;
;EndProc GET_ONE_EA								 ;AN000;
										;AN000;
										;AN000;
; Input: DX= EA ID (0 codpage, 1 Filetype, etc.)
;	 [THISSFT]= points to SFT
;	 ES:DI= buffer address of EA value
;	 [XA_DEVICE]=0 file, 1 device
; Function: get attribute							;AN000;
; Output: none									;AN000;
;										;AN000;
										;AN000;
;procedure   GET_VALUE,NEAR							 ;AN000;
;	ASSUME	CS:DOSGROUP,DS:NOTHING,ES:NOTHING,SS:DOSGROUP			;AN000;
;										;AN000;
;	PUSH   DS			     ;FT. save ds:si			;AN000;
;	PUSH   SI			     ;FT.				;AN000;
;	LDS    SI,[ThisSFT]		     ;FT. ds:si -> SFT			;AN000;
;
;	CMP    DX,0			     ;FT. code page ?			;AN000;
;	JNZ    eafiltyp 		     ;FT. no				;AN000;
;	CMP    [XA_DEVICE],0		     ;FT. device ?			;AN000;
;	JZ     notdev			     ;FT. no				;AN000;
;	CALL   GSetDevCdPg		     ;FT. do ioctl invoke		;AN000;
;	JNC    okcdpg			     ;FT. error ?			;AN000;
;	PUSH   DI			     ;FT.				;AN000;
;	XOR    AX,AX			     ;FT. make code page 0		;AN000;
;	LES    DI,DWORD PTR [SAVE_DI]	     ;FT.				;AN000;
;	ADD    DI,[SAVE_BX]		     ;FT. es:di -> beginning of entry	;AN000;
;	MOV    ES:[DI.EA_RC],EARCNOTFOUND    ;FT.				;AN000;
;	POP    DI			     ;FT.				;AN000;
;	JMP    SHORT okcdpg		     ;FT.				;AN000;
;notdev:
;	MOV    AX,[SI.sf_CodePage]	     ;FT. get code page from  sft	;AN000;
;okcdpg:
;	STOSW				     ;FT. put in buffer 		;AN000;
;	JMP    SHORT gotea		     ;FT.				;AN000;
;eafiltyp:
;	MOV    AL,[SI.sf_ATTR_HI]	     ;FT. get high attribute		;AN000;
;	STOSB				     ;FT. put in buffer 		;AN000;
;
;gotea:
;	POP    SI			     ;FT. retore regs			;AN000;
;	POP    DS			     ;FT.				;AN000;
;	return				     ;FT.				;AN000;
;EndProc GET_VALUE								 ;AN000;
										;AN000;
										;AN000;
; Input:    [XA_handle] = device handle 					;AN000;
;	    [XA_type] = 4 , set 						;AN000;
;	    AX= code page (set)
;			2,3 get 						;AN000;
; Function: get or set device code page 					;AN000;
; Output:   carry clear, AX= device code page (get)				;AN000;
;	    carry set, error							;AN000;
										;AN000;
;procedure   GSetDevCdPg,near							 ;AN000;
;	ASSUME	CS:DOSGROUP,DS:NOTHING,ES:NOTHING,SS:DOSGROUP			;AN000;
;										;AN000;
;	invoke SAVE_WORLD	       ;FT. save all regs			;AN000;
;	CMP    [XA_type],4	       ;FT. set ?				;AN000;
;	JZ     setpg		       ;FT. yes 				;AN000;
;	MOV    CX,6AH		       ;FT. get selected code page		;AN000;
;	JMP    SHORT dogset	       ;FT.					;AN000;
;setpg: 									 ;AN000;
;	MOV    CX,4AH		       ;FT. set code page			;AN000;
;IF  DBCS
;
;	invoke Save_World	       ;FT. save all regs			;AN000;
;	MOV    BX,AX		       ;FT. bx= code page id			;AN000;
;	MOV    AL,7		       ;FT. get DBCS vectors			;AN000;
;	MOV    DX,-1		       ;FT. get current country 		;AN000;
;	MOV    CX,5		       ;FT. minimum size			;AN000;
;	MOV    DI,OFFSET DOSGROUP:DBCS_PACKET	;FT.				;AN000;
;	PUSH   CS		       ;FT.					;AN000;
;	POP    ES		       ;FT.					;AN000;
;	invoke $GetExtCntry	       ;FT. get DBCS vectors			;AN000;
;	JC     nlsfunc_err	       ;FT. error				;AN000;
;	LDS    SI,DWORD PTR DBCS_PACKET+1     ;FT.				;AN000;
;	LODSW				      ;FT. get vector length		;AN000;
;	MOV    CX,AX			      ;FT. cx=length			;AN000;
;
;	MOV    DI,OFFSET DOSGROUP:XA_PACKET+4	;FT.				;AN000;
;	PUSH   CS		       ;FT.					;AN000;
;	POP    ES		       ;FT.					;AN000;
;	REP    MOVSB			      ;FT.				;AN000;
;	CLC				      ;FT.				;AN000;
;nlsfunc_err:
;	invoke RESTORE_WORLD	       ;FT. restore all regs			;AN000;
;	JC     deverr		       ;FT.					;AN000;
;
;ENDIF
;	MOV    WORD PTR [XA_PACKET+2],AX  ;FT.					;AN000;
;dogset:									 ;AN000;
;	MOV    BX,[XA_handle]	       ;FT. set up handle			;AN000;
;	PUSH   CS		       ;FT. ds:dx -> packet			;AN000;
;	POP    DS		       ;FT.					;AN000;
;	MOV    DX,OFFSET DOSGROUP:XA_PACKET  ;FT.				;AN000;
;	MOV    AX,440CH 	       ;FT. IOCTL to char device by handle	;AN000;
;	invoke $IOCTL			     ;FT. issue get code page		;AN000;
;	JC     deverr			     ;FT. error 			;AN000;
;	invoke RESTORE_WORLD		     ;FT. restore all regs		;AN000;
;	MOV    AX,WORD PTR [XA_PACKET+2]     ;FT. get code page 		;AN000;
;	return				     ;FT.				;AN000;
;deverr:									 ;AN000;
;	invoke RESTORE_WORLD		     ;FT. restore all regs		;AN000;
;	return				     ;FT. exit				;AN000;
;										;AN000;
;EndProc GSetDevCdPg								 ;AN000;
										;AN000;

; Input:    DS:SI -> query list
;
; Function: get max size							;AN000;
; Output:   CX= size
;	    carry set error
										;AN000;
;procedure   Get_max_EA_size,NEAR						 ;AN000;
;	ASSUME	CS:DOSGROUP,DS:NOTHING,ES:NOTHING,SS:DOSGROUP			;AN000;
;										;AN000;
;	CMP    [SAVE_SI],0FFFFH 	     ;FT. get all ?			;AN000;
;	JNZ    scan_query		     ;FT. no				;AN000;
;	MOV    CX,[MAX_EA_SIZE] 	     ;FT. get max EA size		      ;AN000;
;	JMP    SHORT gotit		     ;FT.
;scan_query:
;	LDS    SI,DWORD PTR [SAVE_SI]	     ;FT. ds:si -> query list		;AN000;
;	LODSW				     ;FT. ax= number of entries 	;AN000;
;	MOV    [SAVE_CX],AX		     ;FT.				;AN000;
;	XOR    CX,CX			     ;FT. set initial size to 0 	;AN000;
;	OR     AX,AX			     ;FT. if no entris			;AN000;
;	JZ     gotit			     ;FT.    then return		;AN000;
;	MOV    CX,2			     ;FT. at lesat 2			;AN000;
;NEXT_QEA:
;	CALL   Search_EA		     ;FT. search EA			;AN000;
;	JC     serror			     ;FT. wrong EA			;AN000;
;	ADD    CX,size EA		     ;FT. get EA size			;AN000;
;	ADD    CL,ES:[DI.EA_NAMELEN]	     ;FT.				;AN000;
;	ADC    CH,0			     ;FT.				;AN000;
;	ADD    CX,ES:[DI.EA_VALLEN]	     ;FT.				;AN000;
;	DEC    CX			     ;FT.				;AN000;
;	DEC    [SAVE_CX]		     ;FT. end of entris 		;AN000;
;	JZ     gotit			     ;FT. no				;AN000;
;	MOV    AL,[SI.QEA_NAMELEN]	     ;FT. update to next QEA		;AN000;
;	XOR    AH,AH			     ;FT. update to next QEA		;AN000;
;	ADD    SI,AX			     ;FT. update to next QEA		;AN000;
;	ADD    SI,size QEA		     ;FT.				;AN000;
;	DEC    SI			     ;FT.				;AN000;
;	JMP    next_QEA 		     ;FT. do next			;AN000;
;serror:
;	MOV    AX,error_invalid_data	     ;FT. set initial size to 0 	;AN000;
;gotit: 				      ;FT.				 ;AN000;
;	return				     ;FT. exit				;AN000;;FT. exit			  ;AN000;
;
;EndProc Get_max_EA_size		      ;FT. exit 			 ;AN000;				   ;AN000;
										;AN000;
CODE	ENDS									;AN000;
END										;AN000;
