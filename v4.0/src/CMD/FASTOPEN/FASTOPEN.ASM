	Page 84,132 ;
Title	FASTOPEN
;Date: May 13,1988
;==============================================================================
;		 EQUATES
;==============================================================================
Is_drive_head	   EQU	   00000001b								   ;AN000;
Is_delete	   EQU	   00000010b								   ;AN000;
Is_insert	   EQU	   00000100b								   ;AN000;
Not_drive_head	   EQU	   11111110b								   ;AN000;
Not_delete	   EQU	   11111101b								   ;AN000;
Not_insert	   EQU	   11111011b

EMS_SAVE_STATE	   EQU	   4FH									   ;AN000;
EMS_RESTORE_STATE  EQU	   4FH									   ;AN000;
EMS_INT 	   EQU	   67H									   ;AN000;
DOS_PAGE1	   EQU	   0FEH 								   ;AN000;


;==============================================================================
;		   INCLUDE  FILES
;==============================================================================
.xcref
.xlist
debug=0 		   ; an equate only for DOSMAC.inc				     ;AN000;
INCLUDE  DOSMAC.inc										    ;AN000;
.list
.cref
INCLUDE  dirent.inc										    ;AN000;
INCLUDE  fastsegs.inc	   ; this cannot include in Fastopen.inc
INCLUDE  fastopen.inc	   ; this include file also contains DOS equates			    ;AN000;
include  version.inc

;==============================================================================



EXTRN	FK_OPEN:FAR										   ;AN000;
EXTRN	FK_CLOSE:FAR										   ;AN000;
EXTRN	FK_INSERT:FAR										   ;AN000;
EXTRN	FK_DELETE:FAR										   ;AN000;
EXTRN	FK_LOOKUP:FAR										   ;AN000;
EXTRN	FK_TRUNCATE:FAR 									   ;AN000;
EXTRN	FK_PURGE:FAR										;AN000;


;============================================================================

CSEG_MAIN   SEGMENT   PARA   PUBLIC 'code'
	ASSUME	cs:cseg_main, ds:nothing,es:nothing,ss:nothing
;============================================================================

PUBLIC	MAIN											   ;AN000;

IF	BUFFERFLAG
PUBLIC	SAVE_EMS_PAGE_STATE
PUBLIC	EMS_PAGE_NUMBER
ENDIF

PUBLIC	RESTORE_PAGE_STATE
PUBLIC	EMS_SAVE_HANDLE1

PUBLIC	Main_name_cache_seg									   ;AN000;
PUBLIC	Main_Num_Of_drives									   ;AN000;
PUBLIC	Main_Ext_Count										   ;AN000;
PUBLIC	Main_extent_drive_Buff									   ;AN000;
PUBLIC	Main_ext_cache_size									   ;AN000;
PUBLIC	Main_name_cache_Buff									   ;AN000;
PUBLIC	Main_EMS_FLAG										   ;AN000;
PUBLIC	Main_Res_Segs										   ;AN000;
PUBLIC	Main_EMS_PAGE_SIZE									   ;AN000;
PUBLIC	Main_EMS_PAGE_SEG									   ;AN000;
PUBLIC	Main_Total_Ext_Count									   ;AN000;
PUBLIC	Main_Total_Name_Count									   ;AN000;
PUBLIC	Main_Name_Drive_Buff									   ;AN000;
PUBLIC	Main_ParamBuff										   ;AN000;

PUBLIC	FOPEN_Insert										   ;AN000;
PUBLIC	FOPEN_Update										   ;AN000;
PUBLIC	FOPEN_Delete										   ;AN000;
PUBLIC	FOPEN_Lookup										   ;AN000;
PUBLIC	FOPEN_PURGE										  ;AN000;

PUBLIC	FSEEK_Open										   ;AN000;
PUBLIC	FSEEK_Close										   ;AN000;
PUBLIC	FSEEK_Insert										   ;AN000;
PUBLIC	FSEEK_Delete										   ;AN000;
PUBLIC	FSEEK_Lookup										   ;AN000;
PUBLIC	FSEEK_Truncate										   ;AN000;
PUBLIC	FSEEK_Purge										   ;AN000;

PUBLIC	 VECTOR_LookUp										  ;AN000;
PUBLIC	 VECTOR_Delete										  ;AN000;


; Following data variables are accessed by all other segments
call_cnt	       DW    0									;AN000;
Purge_Flag	       DW    0		   ; =1 if last call is PURGE function
Prev_drv_id	       DB    -1 	   ; previous request drive id
Main_name_cache_seg    DW    Cseg_Init	   ; default to Init1 seg				;AN000;
Main_Num_Of_drives     DW    0		   ; number of drives					;AN000;
Main_Ext_Count	       DW    0		   ; total name extent entries				;AN000;
Main_extent_drive_Buff DW    0		   ; addrs to extent drive				  ;AN000;
Main_name_cache_Buff   DW    0		   ; address of Name cache buffer			;AN000;
Main_ext_cache_size    DW    0		   ; extent cache size
Main_EMS_FLAG	       DW    0		   ; EMI flag  1= if EMI is enabled			;AN000;
Main_Res_Segs	       DW    0		   ; number of segs to be stay resident 		;AN000;
Main_Total_Ext_Count   DW    0		   ; Total extent count entries 			;AN000;
Main_Total_Name_Count  DW    0		   ; Total name count entries				;AN000;
Main_Name_Drive_Buff   DW    0		   ; EMS data page segment ID				;AN000;
Main_ParamBuff	       DW    50  dup (0)   ; Drive ID/extent count buffer			;AN000;

; The following structure is for saving and restoring EMS page state
EMS_PAGE_MAP	     LABEL    WORD
Main_EMS_SEG_COUNT     DW    1		   ; EMS segment count
Main_EMS_PAGE_SEG      DW    0		   ; EMS page segment ID				;AN000;


Main_EMS_PAGE_SIZE     DW    0		   ; EMS page size					;AN000;
EMS_PAGE_ARRAY	       DW  30	dup  (0)   ; EMS state save array

; The following data values are used by MAIN segment
EMS_SAVE_LOG_PAGE1     DW    ?		   ;HOLDS PREVIOUS PAGE1				    ;AN000;
EMS_SAVE_HANDLE1       DW    ?		   ;HOLDS PREVIOUS handle1				    ;AN000;

IF	BUFFERFLAG
;----------------------------------------------------------HKN 8/26/88

EMS_PAGE_NUMBER		DW	?			; holds the ems 
							; physical page no.

ENDIF
;
;-----------------------------------------------------------------------------
;	  Fastopen/Fastseek function jump vectors
; Inititally the jump vectors have default offset and segment values.
; If the modules are relocated, the offset and the segID in the jump vectors
; may be changed to the new segID of the new location.
;-----------------------------------------------------------------------------
FOPEN_Insert	 DD   Insert									 ;AN000;
FOPEN_Update	 DD   Update									 ;AN000;
FOPEN_Delete	 DD   delete									 ;AN000;
FOPEN_Lookup	 DD   lookup									 ;AN000;
FOPEN_Purge	 DD   FP_purge									 ;AN000;

FSEEK_Open	 DD   Fk_Open									 ;AN000;
FSEEK_Close	 DD   Fk_Close									 ;AN000;
FSEEK_Insert	 DD   Fk_Insert 								 ;AN000;
FSEEK_Delete	 DD   Fk_Delete 								 ;AN000;
FSEEK_Lookup	 DD   Fk_Lookup 								 ;AN000;
FSEEK_Truncate	 DD   Fk_Truncate								 ;AN000;
FSEEK_Purge	 DD   Fk_Purge									 ;AN000;

VECTOR_LookUp	 DD   LookUp	      ; jump vector to LookUp used by Insert call
VECTOR_Delete	 DD   Fk_Delete       ; jump vector to Delete used by Free_buffer routine





;==============================================================================

MAIN	PROC	FAR			  ; FAR procedure for FAR call from DOS
	push	cx			  ; save DOS registers				     ;AN000;
	push	dx			  ; makesure to restore the necessary			   ;AN000;
	push	ds			  ; ones on return					  ;AN000;
	push	es										   ;AN000;
	push	bp										   ;AN000;
	push	di										   ;AN000;
	push	bx										   ;AN000;

;-----------------------------------------------------------------------------
; The cache buffers are maintained in a seperate segement whose segment ID is
; in Name_Cache_Seg.  The ES will be used as the seg register during the access
; of data in the cache buffers, while DS will be used to access the Fastopen
; resident and non-resident data area.
;-----------------------------------------------------------------------------
	cmp	cs:Main_EMS_flag,1	  ; EMS enabled ??					     ;AN000;
	jne	dispatch_funcs		  ; no - dispatch functions			   ;AN000;
					  ; yes - save EMS page state
IF	NOT BUFFERFLAG

;-----------------------------------------------------------------------------
; SAVE EMS PAGE STATE
;-----------------------------------------------------------------------------
	PUSH	AX			  ; save registers
	PUSH	CX
	PUSH	DX										   ;AN000;
	PUSH	DS										   ;AN000;
	PUSH	ES										   ;AN000;
	PUSH	BP										   ;AN000;
	PUSH	SI										   ;AN000;
	PUSH	DI										   ;AN000;
	PUSH	BX										   ;AN000;
	MOV	AX, SEG EMS_PAGE_MAP	  ; get segid
	MOV	DS,AX
	LEA	SI,EMS_PAGE_MAP 	  ; DS:SI-->page map struc
	MOV	AX, SEG EMS_PAGE_ARRAY	  ; get segid
	MOV	ES,AX
	LEA	DI,EMS_PAGE_ARRAY	  ; ES:DI-->Page ARRAY
	MOV	AH,EMS_SAVE_STATE	  ;
	MOV	AL,0			  ; subfunction code
	INT	EMS_INT 		  ; save page state							    ;AN000;

	POP	BX										   ;AN000;
	POP	DI										   ;AN000;
	POP	SI										   ;AN000;
	POP	BP										   ;AN000;
	POP	ES										   ;AN000;
	POP	DS										   ;AN000;
	POP	DX										   ;AN000;
	POP	CX										   ;AN000;

	CMP	AH,0			 ; save ok??
	JNE	SAVE_FAILED		 ; no, error
	POP	AX			 ; clear stack

ELSE


;------------------------------------------------------------HKN 8/26/88--
;	Before dispatching off the fastopen functions we must do the 
;	following:
;		1. save the map for this page
;		2. map this page to log. page 0 with the fastopen handle in
;		   ems_save_handle1.
;		3. dispatch
;

;	int	3

	push	ax
	push	cx
	push	dx
	push	ds
	push	es
	push	bp
	push	si
	push	di
	push	bx

	call	far ptr	save_ems_page_state
	jc	ems_failed

	call	map_page
	jc	ems_failed

	pop	bx
	pop	di
	pop	si
	pop	bp
	pop	es
	pop	ds
	pop	dx
	pop	cx
	POP	AX			 ; restore registers

	JMP	DISPATCH_FUNCS		 ; yes, dispatch functions

EMS_FAILED:
	pop	bx
	pop	di
	pop	si
	pop	bp
	pop	es
	pop	ds
	pop	dx
	pop	cx

ENDIF

IF	NOT BUFFERFLAG
SAVE_FAILED:
ENDIF

	POP	AX			 ; restore registers

	POP	BX			 ; no, restore DOS registers 				   ;AN000;
	POP	DI										   ;AN000;
	POP	BP										   ;AN000;
	POP	ES										   ;AN000;
	POP	DS										   ;AN000;
	POP	DX										   ;AN000;
	POP	CX										   ;AN000;
	STC
	JMP	ERROR_RET		 ; error return


;-----------------------------------------------------------------------------
; FASTOPEN/FASTSEEK DISPATCHER
;-----------------------------------------------------------------------------
DISPATCH_FUNCS:
	cmp	al,5		      ; buffer purge ??
	je	Check_Drive_id	      ; yes - check drive id
	cmp	al,11		      ; Fastopen function call ??				   ;AN000;
	jge	Check_drive_id	      ; no - dispatch Fastseek functions
	jmp	Dispatch_fopen	      ; yes - dispatch Fastopen functions						 ;AN000;


;-----------------------------------------------------------------------------
; Check to see the Drive ID in DL is the valid. If not error and return DI=1
; if Fastseek LookUp function. Makesure to preserve AL, DS, SI and DI
;-----------------------------------------------------------------------------
CHECK_DRIVE_ID:
	cmp	cs:Prev_drv_id, dl	    ; current id same as previous valid
	je	Dispatch_Fseek		    ; yes - dont check drive ID

	push	si										   ;AN000;
	push	bx			    ;DS=addressability to Cseg_Main			   ;AN000;
	push	cx										   ;AN000;
	lea	si,cs:Main_ParamBuff	    ; DS:SI-->drive ID buffer				   ;AN000;
	mov	cx,cs:Main_Num_Of_Drives    ; number of drives					   ;AN000;

Get_Drive_Id:											   ;AN000;
	mov	bx,cs:[si]									   ;AN000;
	cmp	bl,dl			    ; drive ID match ?? 				   ;AN000;
	je	drive_found		    ; yes, drive ID found				   ;AN000;
	add	si,4			    ; (2/11) no, move pointer to next ID			  ;AN000;
	LOOP	get_drive_id		    ; check next drive id				   ;AN000;

Drive_Not_Found:			    ; drive id not found
	pop	cx			    ; restore registers 			       ;AN000;
	pop	bx										   ;AN000;
	pop	si										   ;AN000;
	jmp	Error_Exit		    ; return

Drive_Found:				    ; drive ID found
	mov	cs:Prev_drv_id,dl	    ; save drive id as prev drive id
	pop	cx			    ; restore registers 				   ;AN000;
	pop	bx			    ; and do the specified function		      ;AN000;
	pop	si										   ;AN000;

;-----------------------------------------------------------------------------
;     FASTSEEK FUNCTION DISPATCHER
;-----------------------------------------------------------------------------
DISPATCH_FSEEK:
	cmp	al,010H
	jle	Fsk_Cont
	inc	cs:call_cnt									   ;AN000;
;	cmp	cs:call_cnt,0efffH	   ; for debugging
;	jne	 fsk_cont		   ; for debugging


Fsk_Cont:
	push	cs			   ; set addressability
	pop	ds			   ; CS = DS = Cseg_Main segment
	ASSUME	ds:Cseg_Main
	cmp	al,FONC_Purge		   ; PURGE call ??					       ;AN000;
	je	chk_05			   ; yes - continue						;AN000;

	mov	cs:Purge_Flag, 0	   ; reset purge flag
	cmp	al,FSK_Open		   ; OPEN call							;AN000;
	jne	chk_12			   ; jump if not						;AN000;
	CALL	FSEEK_OPEN										;AN000;
	jmp	exit											;AN000;
Chk_12:
	cmp	al,FSK_Close		   ; CLOSE ??							;AN000;
	jne	chk_14											;AN000;
	CALL	FSEEK_CLOSE		   ; process close function					;AN000;
	jmp	exit											;AN000;
Chk_14:
	cmp	al,FSK_Lookup		   ; LOOKUP ??							;AN000;
	jne	chk_15											;AN000;
	CALL	FSEEK_LOOKUP		   ; process lookup						;AN000;
	CALL	RESTORE_PAGE_STATE	   ; restore EMS page						;AN000;
	pop	dx			   ; dont restore original BX and DI				;AN000;
	pop	dx			   ; from DOS since BX and DI contins return values	   ;AN000;
	jmp	exit_1			   ; exit

Chk_15:
	cmp	al,FSK_Insert		   ; INSERT ??							;AN000;
	jne	chk_13											;AN000;
	CALL	FSEEK_INSERT		   ; Process insert						;AN000;
	jmp	exit											;AN000;
Chk_13:
	cmp	al,FSK_DELETE		   ; DELETE ??							;AN000;
	jne	chk_16											;AN000;
	CALL	FSEEK_DELETE		   ; process delete						;AN000;
	jmp	short  exit										       ;AN000;
Chk_16:
	cmp	al,FSK_Trunc		   ; TRUNCATE ??						;AN000;
	jne	Chk_05			   ;
	CALL	FSEEK_TRUNCATE		   ; process truncate						;AN000;
	jmp	short exit										      ;AN000;

Chk_05:
	cmp	cs:Purge_Flag, 1	   ; previous call is purge ??				    ;AN000;
	jne	Purge_buffs		   ; no - purge the buffers
	clc				   ; yes - exit
	jmp	short exit										      ;AN000;

Purge_Buffs:
	mov	cs:Purge_Flag,1 	   ; set purge flag
	cmp	CS:Main_Total_Ext_Count,0	    ; reset fseek buffs??
	je	reset_fopen		   ; no - reset fopen
	CALL	FSEEK_PURGE		   ; reset extent cache 			    ;AN000;

Reset_Fopen:
	cmp	CS:Main_Total_Name_Count,0	    ; reset fopen buffs??
	je	Reset_Exit		   ; no - reset f
	CALL	CS:FOPEN_PURGE		      ; reset extent cache			       ;AN000;

Reset_Exit:
	clc
	jmp	short exit										 ;AN000;


; NOTE: Carry Flag state from Function calls must be correctly returned
;	to the DOS, especially from Fastseek Lookup function


;-----------------------------------------------------------------------------
;	FASTOPEN FUNCTION DISPATCHER
;-----------------------------------------------------------------------------
DISPATCH_FOPEN: 		      ; dispatch FOPEN functions
	cld											   ;AN000;
	mov	cs:Purge_Flag, 0      ; reset purge flag
	cmp	al, FONC_update 								   ;AN000;
	jne	Chk_02										   ;AN000;
	CALL	CS:Fopen_Update       ; UPDATE							   ;AN000;
	jmp	short exit										 ;AN000;

Chk_02:
	cmp	al, FONC_insert 								   ;AN000;
	jne	Chk_01										   ;AN000;
	CALL	CS:Fopen_Insert       ; INSERT							   ;AN000;
	jmp	short exit										 ;AN000;
Chk_01:
	cmp	al, FONC_look_up								   ;AN000;
	jne	chk_03										   ;AN000;
	CALL	CS:Fopen_lookup       ; LOOKUP							   ;AN000;
	jmp	short exit										 ;AN000;
Chk_03:
	cmp	al, FONC_delete 								   ;AN000;
	jne	Error_Exit									   ;AN000;
	CALL	CS:Fopen_delete       ; DELETE							   ;AN000;
	jmp	short exit										 ;AN000;



;-----------------------------------------------------------------------------
;  EXIT TO DOS FROM FUNCTIONS
;-----------------------------------------------------------------------------

ERROR_EXIT:	     ; EXIT from invalid drive id search loop
	CALL	RESTORE_PAGE_STATE     ; restore frame buff status				   ;AN000;
				       ; on return AX should have function code
	pop	bx		       ; restore first two regs of DOS
	pop	di										   ;AN000;
	cmp	al,FSK_Lookup									   ;AN000;
	jne	exit_2										   ;AN000;
	mov	di,1		       ; set error flag - invalid drive id			   ;AN000;
	stc											   ;AN000;
	jmp	short Exit_1									   ;AN000;

EXIT_2:
	clc											   ;AN000;
	jmp	short Exit_1									   ;AN000;


; Normal Exit from Fastopen Functions except Fastseek Lookup function
EXIT:
	CALL	RESTORE_PAGE_STATE     ; restore EMS page state 				   ;AN000;;AN000;
	pop	bx		       ; restore BX						   ;AN000;
	pop	di		       ; restore DI						   ;AN000;


; Exit from FastSeek Lookup function. Dont restore BX and DI
EXIT_1:
	pop	bp		       ; restore remaining DOS registers
	pop	es		       ; except BX and DI since they contain								;AN000;
	pop	ds		       ; return values. 					    ;AN000;
	pop	dx										   ;AN000;
	pop	cx										   ;AN000;

ERROR_RET:
	ret											   ;AN000;

MAIN	ENDP

IF	BUFFERFLAG
;---------------------------------------------------------------------------
;	Procedure name	:	save_ems_page_state
;	
;	Description:
;		Saves the state of the page whose physical segment value is
;	specified in Main_EMS_PAGE_SEG. 
;---------------------------------------------------------------------------

SAVE_EMS_PAGE_STATE	PROC	FAR

	PUSH	AX			  ; save registers
	PUSH	CX
	PUSH	DX										   ;AN000;
	PUSH	DS										   ;AN000;
	PUSH	ES										   ;AN000;
	PUSH	BP										   ;AN000;
	PUSH	SI										   ;AN000;
	PUSH	DI										   ;AN000;
	PUSH	BX										   ;AN000;

	MOV	AX, SEG EMS_PAGE_MAP	  ; get segid
	MOV	DS,AX
	LEA	SI,EMS_PAGE_MAP 	  ; DS:SI-->page map struc
	MOV	AX, SEG EMS_PAGE_ARRAY	  ; get segid
	MOV	ES,AX
	LEA	DI,EMS_PAGE_ARRAY	  ; ES:DI-->Page ARRAY
	MOV	AH,EMS_SAVE_STATE	  ;
	MOV	AL,0			  ; subfunction code
	INT	EMS_INT 		  ; save page state							    ;AN000;

	POP	BX										   ;AN000;
	POP	DI										   ;AN000;
	POP	SI										   ;AN000;
	POP	BP										   ;AN000;
	POP	ES										   ;AN000;
	POP	DS										   ;AN000;
	POP	DX										   ;AN000;
	POP	CX										   ;AN000;

	CMP	AH,0			 ; save ok??
	JE	SAVE_OK			 ; 
	STC
	JMP	SHORT DONE
SAVE_OK:
	CLC
DONE:
	POP	AX
	RET

SAVE_EMS_PAGE_STATE	ENDP

ENDIF


;-----------------------------------------------------------------------------
; PROCERDURE:  RESTORE_PAGE_STATE
;
; Function:    Restore state of EMS page
;
; Input:       None
; Output:      Page is restored
;
;-----------------------------------------------------------------------------

RESTORE_PAGE_STATE    PROC  NEAR	;RESTORE EMS PAGE STATE
	PUSHF				;save flag					     ;AN000;
	CMP	CS:MAIN_EMS_FLAG, 0	;EMS enabled ?? 					   ;AN000;
	JNE	REST_PUSH_REGS		;yes, restore registers
	JMP	SHORT RESTORE_EXIT	;no, exit						   ;AN000;
					;yes, restore page registers
REST_PUSH_REGS:
	PUSH	AX			; save function code
	PUSH	CX			; save caller registers 				    ;AN000;
	PUSH	DX										   ;AN000;
	PUSH	DS										   ;AN000;
	PUSH	ES										   ;AN000;
	PUSH	BP										   ;AN000;
	PUSH	SI										   ;AN000;
	PUSH	DI										   ;AN000;
	PUSH	BX										   ;AN000;

	MOV	AX, SEG EMS_PAGE_ARRAY
	MOV	DS,AX
	LEA	SI,EMS_PAGE_ARRAY	; DS:SI-->Page array
	MOV	AH,EMS_RESTORE_STATE	;
	MOV	AL,1			;
	INT	EMS_INT 		; restre page state							      ;AN000;
	CMP	AH,0			; restore OK ??
	JE	REST_POP_REGS		; yes
	STC				; set carry

REST_POP_REGS:
	POP	BX			; RESTORE REGISTERS					   ;AN000;
	POP	DI										   ;AN000;
	POP	SI										   ;AN000;
	POP	BP										   ;AN000;
	POP	ES										   ;AN000;
	POP	DS										   ;AN000;
	POP	DX										   ;AN000;
	POP	CX										   ;AN000;
	POP	AX			; restore function code

RESTORE_EXIT:
	POPF
	RET											   ;AN000;

RESTORE_PAGE_STATE    ENDP


IF	BUFFERFLAG

;---------------------------------------------------------HKN 8/26/88-------
;	procedure name		:	map_page
;	Inputs			: 	ems_page_number = physical page frame
;							  number.
;					ems_save_handle1 = emm_handle.
;	Output			: 	CY - error
;					NC - page is mapped to logical page 0
;----------------------------------------------------------------------------
map_page	proc	near

	push	ax
	push	bx
	push	dx

	xor	bx, bx
	mov	ax, cs:ems_page_number	; contains the page number obtained 
					; during fastopen intialization.
	mov	ah, 44h
	mov	dx, cs:ems_save_handle1	; contains the emm handle that was
					; obtained during fast init.
	int	ems_int
	or	ah, ah
	jnz	err_map_page
	clc
	jmp	short map_page_done

err_map_page:
	stc

map_page_done:
	pop	dx
	pop	bx
	pop	ax
	ret

map_page	endp

ENDIF
	
	
					 ; NOTE:
CSEG_MAIN   ENDS			 ; End of the first portion of the
					 ; Cseg_Main segment.  Remaining
					 ; portion is in Fastinit.asm

;-----------------------------------------------------------------------------





;==============================================================================
; All Fastopen functions are kept in a seperate segment.  These are accessed
; by a FAR indirect call from the MAIN routine.
; ADDRESSABILTY: CS is used for accessing local data in Cseg_Open segment
;		 DS is used for accessing data in the drive cache buffer
;					  in the Cseg_Init segment
;		 ES is used for accessing data in the name cache buffer
;					  in the Cseg_Init segment
;
;*****************************************************************************
CSEG_OPEN   SEGMENT   PARA   PUBLIC 'code'
  ASSUME  cs:cseg_open,ds:nothing,es:nothing,ss:nothing
;*****************************************************************************

PUBLIC	 Open_name_cache_seg									   ;AN000;
PUBLIC	 Open_name_Drive_Buff									   ;AN000;
PUBLIC	 End_Open										   ;AN000;
PUBLIC	 Chk_Flag										   ;AN000;

;---- FastOpen Functions Local Variables --------------

Current_Node	     DW    ?	     ;address of current node entry buffer		     ;AN000;
Current_Sibling      DW    ?	     ;address of current sibling node entry buffer		;AN000;
Current_Drive	     DW    ?	     ;address of current drive header			     ;AN000;
Matching_Node	     DW    -1	     ;flag						       ;AN000;
From_Delete	     DW    0	     ;= 1 if call is from DELETE function		    ;AN000;
Old_SI		     DW    0	     ;SI save area				     ;AN000;
Flag		     DB    0									;AN000;
Level		     DB    0	     ;depth level of the path					;AN000;
Dir_Info_Buffer      DD    ?	     ;Dir_Info buffer inside DOS				;AN000;
Extended_Info_Buffer DD    ?	     ;Extended Info buffer inside DOS			;AN000;
New_FEI_clusnum      DW    0									;AN000;
Packed_Name	     DB    11 dup (0)	   ;Space for packed dir name				;AN000;
Top		     DW    0									;AN000;
Temp		     DW    0									;AN000;
Bottom		     DW    0									;AN000;
Depth		     DB    0									;AN000;

Chk_Flag	     dw    0	     ; flag used by the analyser
func_cod	     db    0	     ; function code for analyser

;Following data area is filled during initialization
Open_name_cache_seg	   DW	 Cseg_Init     ; address of name cache buffer
Open_name_Drive_Buff	   DW	 0	       ; address of first drive buffer




;
;==============================================================================
;		    Pathname Tree Search
;
;  Element of each path name is represented by a node in the tree.  First
;  node is connected to the the Drive header through first child pointer
;  (DCH_Child_Ptr).  The first node may have one or more nodes underneath.
;  The first one is called the Child of this node and the others are the siblings
;  of the child node.  Previous node is connected to the first node through
;  the child pointer (nChild_Ptr) and the siblings are connected through the
;  sibling pointer (nSibling_Ptr).  Each node is connected to the previous
;  node through a backward pointer (nBackward_Ptr).  For example, to go to the
;  previous node from any of the siblings. It is necessary to go to the
;  child through previous siblings (if any) and then to the previous from the
;  child.  All this backward movement is using nBackward_Ptr.
;  Similarly to go to a child or sibling, nChild_ptr or nSibling_Ptr should be
;  used.  The strucure of drive header and the node are defined in Fastopen.inc
;

;==============================================================================
;Subroutine:  LOOKUP
;
;INPUT:
;    DS:SI -> path  (drive letter D: will be validated by Find_Drive_Cache_hdr)
;    ES:DI -> DIR_INFO buffer to be returned inside DOS
;    ES:CX -> FASTOPEN_Extended_Info buffer inside DOS
;    ES:BP -> Drive_Cache_Heade
;
;
;OUTPUT:
;     If the whole path is found,
;	 DS:SI--> 0
;	 ES:DI--> DIR_INFO buffer is filled with directory info
;	 ES:CX--> EXT_INFO buffer is filled with extended info
;
;     If partially found the path,
;	 DS:SI--> '\' after the matching directory name
;	 ES:DI--> DIR_INFO buffer is filled with directory info
;	 ES:CX--> EXT_INFO buffer is filled with extended info
;
;     If the Name_cache tree is empty, i.e.,no root directory name,
;	 DS:SI--> '\' after ':'
;	 ES:DI--> DIR_INFO buffer is undetermined
;	 ES:CX--> EXT_INFO buffer is undetermined
;
;==============================================================================

LOOKUP	PROC   FAR

	mov	cs:func_cod,al		   ; save function code
	cmp	From_Delete, 0		   ;call from DELETE function ??
	je	Look_Pack_Dir		   ;no, dont restore DS
	mov	DS,bx			   ;yes, restore DS
	ASSUME	DS:Cseg_Init
	jmp	short Look_save_regs	   ;save registers

Look_Pack_Dir:
	CALL	PACK_DIR_NAME		   ;on return drive letter => DL,

	CALL	FIND_DRIVE_CACHE_HEADER    ;find drive header address
					   ;on return ES:BP-->drive header
	jnc	look_save_regs		   ;drive buffer found
	jmp	lookup_error		   ;drive buffer not found

Look_Save_Regs:
	push	es
	push	di
	push	cx
	mov	ax, cs:Open_Name_Cache_Seg							   ;AN000;
	mov	es, ax			   ;ES = Name_Cache_Seg 				      ;AN000;
	ASSUME	es:Cseg_Init									   ;AN000;
	CALL	SET_LRU 		   ;set the Real LRU, if any.

	or	cs:Flag,Is_drive_head	   ;level of the tree. Drive header
	mov	cs:Matching_Node, -1	   ;Nothing found yet.
	mov	cs:Current_Drive, BP	   ;drive header
	mov	cs:Level, 0		   ;path level is 0

Lookup_Path:
	mov	cs:Current_Node, BP	   ;save current node address
	mov	cs:Current_Sibling,0fffeh  ;set no sibligs yet.
	mov	cs:Old_SI, si		   ;save current path address

	CALL	PACK_DIR_NAME		   ;get the next dir name from the path
	jc	Lookup_Done		   ;yes, found the whole path.

	test	cs:Flag, Is_drive_head	   ;dir name = drive header ?
	jz	Lp_Path1		   ;no-

	push	ds			   ;yes-drive header
	mov	ds,cs:Open_Name_Cache_Seg
	ASSUME	ds:Cseg_Init
	mov	BP, DS:[BP.DCH_Child_ptr]  ;BP-->first child node under drive hdr
	pop	ds
	ASSUME	ds:nothing
	jmp	short Lp_Path2

Lp_Path1:
	mov	BP, ES:[BP.nChild_ptr]	   ;BP--> child of current node

Lp_Path2:
	cmp	BP, -1			   ;no child?
	je	Lookup_Done		   ;Not found or partially found
	mov	cs:Current_Node, BP	   ;current_node = found node
	and	cs:Flag, Not_drive_head    ;reset the flag.

Lp_Cmpare:
	CALL	CMPARE			   ;look for path in current node
	je	Lookup_Found		   ;Yes, found a match. Next level for
					   ;possible remianing path

	mov	BP, ES:[BP.nSibling_ptr]   ;not found. Any siblings?
	mov	cs:Current_Sibling,BP
	cmp	BP, -1			   ;any more sibling?
	je	Lookup_Done		   ;no - done

	mov	cs:Current_Node, BP	   ;yes- make the found sibling as a current
	jmp	short Lp_Cmpare 	   ;node and search path in this node

Lookup_Found:
	inc	cs:Level
	mov	cs:Matching_Node,BP	   ;Used by Unfold_Name_Record

	CALL	PRE_LRU_STACK		   ;set the TEMP_LRU_Stack
	jmp	Lookup_Path		   ;continue to the next dir

Lookup_Done:
	mov	si, cs:Old_SI
	pop	cx			   ;restore Extended_Info buffer
	pop	di			   ;restore Dir_Info buffer
	pop	es			   ;the segment for the above buffers

	cmp	ax, -1
	je	Lookup_ERR		   ;error occured in Pack_Dir_Name.
	clc				   ;clear carry.
	jmp	short Lookup_Done1

Lookup_ERR:				   ;error exit
	stc

Lookup_Done1:
	test	cs:Flag, is_delete	   ;called by delete?
	jnz	Lookup_Return
	jc	Lookup_Exit		   ;If it was an error, don't change the carry flag

	CALL	UNFOLD_NAME_RECORD	   ;unfold the current node's record
Lookup_Exit:
	jmp	short Lookup_Return	   ;return to DOS.

Lookup_Error:				   ;error exit
	stc
	mov    ax,-1

Lookup_Return:				   ;return to Delete routine.
	CALL	Check_It		   ;check tree structure
	ret

LOOKUP	 ENDP





;==============================================================================
;SUBROUTINE: INSERT
;
;INPUT:    DS:DI -> Dir_Info in DOS
;	   ES:BX -> Fastopen_Extended_Info in DOS
;	   Current_Node, Current_Sibling, Current_Drive, Flag
;
;OUTPUT:   Information inserted into Name_cache_tree.
;
;   Any Sequential Insert operation should be preceded by a Look_up
;   operation. For ex., if the DOS wants to insert C:\DIR1\DIR2\File1
;   and suppose there is no matching name cache record for DIR1 in the tree.
;   Firstly DOS will try to look up C:\DIR1\DIR2\File1.  FASTOPEN will
;   return to DOS with DS:SI points to "\" after the drive letter.
;   Then, DOS will simply ask an insert operation with DS:DI, ES:BX
;   points to the information on "DIR1".  FASTOPEN will insert DIR1
;   onto the tree.  After that DOS will ask another insert
;   operation for DIR2.  FASTOPEN will insert DIR2.  Finally DOS will
;   ask to insert File1.
;
;   Suppose when DOS try to look up C:\DIR1\DIR2\File2 at this moment.
;   FASTOPEN will return to DOS with DS:SI points to "\" after DIR2 (since
;   DIR2 information is already in the name cache tree).  Then DOS will ask
;   to insert File2.
;
;   Any Insert operation of subdirectory name which is deeper than (Number_
;   of_Entries - 1) will not be inserted but will just return.
;   Also, for the safety reason, if the would be freed node (=LRU node) is
;   the same as the Current_Node, there will be no insertion. (This is a simple
;   safety valve.  A more smart logic can look for the next **legitimately
;   available** LRU node to use, or sometimes, simply replace the contents of the
;   entry if adequate. But this will increase the complexity greatly, and I
;   think the current logic is still practical enough to use despite of the
;   possible small window of performance degradation in a very special cases. J.K.)
;
;==============================================================================

INSERT	PROC   FAR
	mov	cs:func_cod,al			; save function code
	inc	cs:Level			;increment directory level
	xor	ax,ax
	mov	al, cs:Level
	inc	al
	mov	bp, cs:Current_Drive		;BP-->address of current drive header
	push	ds
	mov	ds,cs:Open_Name_Cache_Seg	;DS=name cache segment

	ASSUME	ds:Cseg_Init									   ;AN000;
	cmp	ax, ds:[bp.DCH_Num_Entries]	;Level > (Num_Entries - 1) ?
	pop	ds
	ASSUME	ds:nothing
	jbe	Insert_it			;no- insert it
	jmp	short Insert_return		;yes return

Insert_it:
	or	cs:Flag, is_insert

	CALL	GET_FREE_NODE		   ;AX = offset value of the available
					   ;name_record in Name_Cache_Seg.
	jc	I_Exit			   ;Current node = would-be freed node.

	CALL	MAKE_NAME_RECORD	   ;Fill the above name record entry.
					   ;ES was changed to Name_Cache_Seg.

	mov	bp, cs:Current_Node	   ;set BP to current_node
	mov	bx, bp			   ;save it into bx
	cmp	cs:Current_Sibling,0fffeh  ;current node sibling node ??
	je	I_Child 		   ;no-child of preceding node
	mov	es:[bp.nSibling_ptr], ax   ;yes-make new node sibling of
	jmp	short I_Done		   ;current node

I_Child:				   ;set nChild_ptr
	test	cs:Flag,Is_drive_head	   ;drive level?
	jnz	I_Child_first		   ;Yes, must be the first child
	mov	es:[bp.nChild_ptr], ax	   ;no-make ndew node child of
	jmp	short I_Done		   ;current node

I_Child_first:				   ;this is the first child in this drive.
	push	ds
	mov	ds,cs:Open_Name_Cache_Seg							   ;AN000;
	ASSUME	ds:Cseg_Init									   ;AN000;
	mov	ds:[bp.DCH_Child_ptr],ax   ;make new node 1st child current drive
	pop	ds
	ASSUME	ds:nothing
	mov	bx, cs:Current_Drive	   ;change bx to Current_Drive
	and	cs:Flag, Not_drive_head    ;reset the flag

I_Done:
	mov	bp, ax
	mov	es:[bp.nBackward_ptr],bx ;set the backward ptr of the inserted node.

	CALL	PRE_LRU_STACK		   ;save this inserted record temporarily.

	mov	cs:Current_Node,bp	   ;make new node current node
					   ;any subsequent insert operation
	mov	cs:Current_Sibling,0fffeh  ;should be installed as a child

I_Exit:
	and	cs:Flag, not_insert	   ;set not insert flag

Insert_return:
	CALL	Check_It		   ;check tree structure
	ret				   ;return

INSERT	ENDP






;==============================================================================
;Subroutine: DELETE
;
;INPUT:   DS:SI -> path
;	  ES:BP -> drive_cache_header (for Look_Up operation)
;
;OUTPUT:  if found, then remove the matching Name_Record will be removed from
;	  the tree and from the LRU chain.  The freed entry will be placed
;	  on top of the LRU chain.
;
;==============================================================================

DELETE	 PROC	FAR

	mov	cs:func_cod,al		   ; save function code
	CALL	PACK_DIR_NAME		   ;drive letter => DL, 				      ;AN000;

	CALL	FIND_DRIVE_CACHE_HEADER    ;find drive header address
					   ;on return ES:BP-->drive header
	jc	d_err_exit		   ;error exit

	or	cs:Flag, is_delete	   ;set the flag for Look_up.
	push	ds			   ;save DS in BX since it is going to be
	pop	bx			   ;changed for jumping to other segment
	push	ds
	mov	ax,cseg_Main
	mov	ds,ax			   ;DS=Main segment ID
	assume	ds:Cseg_Main
	mov	cs:From_Delete, 1	   ;set flag indicate that the call
					   ;is from DELETE function
	CALL	VECTOR_LOOKUP		   ;FAR call to Lookup function

	mov	cs:From_Delete, 0	   ;reset from delete flag
	pop	ds
	ASSUME	ds:nothing
	jc	D_err_Exit		   ;indirectly in the same segment

	cmp	byte ptr ds:[si], 0	   ;found the whole path?
	jne	D_err_Exit		   ;No.

;At this point, Current_Node = BP.
	mov	bx, cs:Open_Name_Cache_Seg
	mov	es, bx			   ;set ES to name_cache_seg.
	ASSUME	es:Cseg_Init

Delete_Node:
	cmp	es:[bp.nChild_ptr], -1	   ;No children?
	jne	D_err_Exit
	CALL	REMOVEFROMTREE		   ;remove the node while maintaing the
					   ;integrity of the tree.

	mov	es:[bp.nCmpct_Dir_Info], ' ' ;mark that this entry is free!!!

D_LRU_MRU:
	CALL	REMOVEFROMLRUCHAIN	   ;Remove BP from the LRU,MRU chain

	mov	si, cs:Current_Drive	   ;Now let the deleted node to be the
	push	ds			   ; LRU node
	mov	ds,cs:Open_Name_Cache_Seg
	ASSUME	ds:Cseg_Init									   ;AN000;

	mov	bx, ds:[si.DCH_LRU_ROOT]   ;es:bx -> first node
	mov	es:[bp.nLRU_ptr],bx	   ;Target.nLRU_ptr -> first node
	mov	es:[bx.nMRU_ptr],bp	   ;First_node.nMRU_ptr -> target
	mov	ds:[si.DCH_LRU_ROOT],bp    ;LRU_ROOT -> target
	mov	es:[bp.nMRU_ptr],-1
	pop	ds
	ASSUME	ds:nothing
	jmp	short	D_Exit		   ;exit

D_err_Exit:				   ;error exit
	stc
	mov	ax, -1

D_Exit:
	and	cs:Flag, not_delete	   ;reset the flag
	CALL	Check_It		   ;check tree structure
	ret				   ;return

DELETE	 ENDP





;==============================================================================
;Subroutine:  UPDATE
;
;INPUT:  If AH = 0, then update Dir_Entry area.
;	     ES:DI -> Dir_entry ("dir_first" is the key to search).
;	     DL = Logical Drive number (0 = A, 1 = B, ...).
;
;	 If AH = 1, then update "Fastopen_extended_info.FEI_clusnum".
;	     DL = Logical Drive number (0 = A, 1 = B, ...)
;	     CX = The value of "dir_first" to search.
;	     BP = new value of FEI_clusnum in the extended_info area.
;
;	If AH = 2, then delete the entry. Same effect as Delete function
;	     except this time the keys used to delete are;
;	     DL = logical drive number
;	     CX = the value of "dir_first" to search.
;
;	If AH = 3, then delete the entry. Same effect as Delete function
;	     except this time the keys used to delete are;
;	     DL = logical drive number
;	     DH = directory position
;	     DI = directory sector (low value)
;	     CX = directory sector (high value)
;
;
;OUT:  if found, then data is updated
;      else CY and AX = -1.
;
;    This routine use "starting cluster number" and "drive letter"
;    as a key to find the name record.	Usually the reason is DOS
;    does not have any "full path" information about the file when
;    it has to call this routine to update the information.
;    It follows the MRU chain until it finds the name record or
;    until it reaches the free name record (identified by the
;    Directory name starting with ' '), or until the end of
;    the MRU chain.
;
;==============================================================================

UPDATE	PROC	FAR

	mov	cs:func_cod,al		 ; save function code
	cmp	ah, 0			 ;update directory entry ?
	je	Update_Dir_Entry	 ;yes-
	cmp	ah, 1			 ;update extended info ?
	je	Update_Extended_clusnum  ;yes-
	cmp	ah, 2			 ;delete based on first clus num ?
	je	Update_Delete		 ;yes-
	cmp	ah, 3			 ;delete based directory sector ?
	je	Update_Delete1		 ;yes-

U_ERROR:				 ;no - error exit
	stc
	jmp	short  Update_Exit

Update_Delete:				; same as delete
	CALL	FIND_CLUSTER_NUMBER	; find name entry using first cluster
	jc	U_ERROR
	jmp	Delete_Node		; if found, delete entry

Update_Delete1: 			; same as delete (PTR P3718  3/10/88)
	CALL	FIND_DIR_SECTOR 	; find name entry using directory
	jc	U_ERROR 		; sector and directory position
	jmp	Delete_Node		; if found, delete node

Update_Dir_Entry:
	mov	cx, es:[di.dir_first]
	push	es			;save Dir_Info pointer ES:DI
	push	di
	CALL	FIND_CLUSTER_NUMBER
	pop	si			;restore Dir_Info pointer in DS:SI
	pop	ds
	jc	U_ERROR 		;error-if not found

	push	bp			;found the entry
	pop	di
	add	di, nCmpct_Dir_Info	;ES:DI->Name_Record.nCmpct_Dir_Info
	mov	cx, ODI_head_leng
	REP	MOVSB			;update Cmpct_dir_info head section
	add	si, ODI_skip_leng
	mov	cx, ODI_tail_leng
	REP	MOVSB			;update tail section
	jmp	short  Update_Exit	;exit

Update_Extended_clusnum:		;update extended info field
	mov	cs:New_FEI_clusnum,bp
	CALL	FIND_CLUSTER_NUMBER	;Find entry based first cluster number
	jc	U_ERROR

	add	bp, nExtended_Info	;es:bp -> Name_record.nExtended_Info
	mov	bx, cs:New_FEI_clusnum
	mov	es:[bp.FEI_clusnum],bx

Update_Exit:
	CALL	Check_It		   ;check tree structure
	ret				;return

UPDATE	 ENDP






;==============================================================================
;Subroutine:  FP_PURGE	  Rest Name Cache Buffers
;
;INPUT:  Main_Name_Drive_Buff  -  Offset to Name cache buffer
;	 Main_Name_Cache_Seg   -  Name cache seg id
;	 DL = Drive ID
;
;OUT:	 Buffer is purged
;
;==============================================================================

FP_PURGE   PROC    FAR

	mov	si,Open_Name_Drive_Buff        ; SI-->first Name drive cache buff
	mov	es,Open_Name_Cache_Seg	       ; ES = name cache seg ID
	mov	bx,es:[si].DCH_Name_Buff       ; BX-->Name cache buffer
	inc	dl			       ; DL=drive number
	add	dl,040H 		       ; convert drive num to drive letter

; Search for the name drive header corresponds to the drive letter
Purge_Drv_Loop:
	cmp	es:[si].DCH_Drive_Letter,dl    ; drive letter match ??
	je	Purge_drive_cache	       ; yes - set drive cache
	add	si, size Drive_Cache_Header    ; no - get address of next drive cache
	jmp	purge_drv_loop		       ; try next name drive header

Purge_Drive_Cache:			       ; SI-->drive header
	mov	bx,es:[si].DCH_Name_Buff       ; BX-->Name cache buffer
	mov	cx,es:[si].DCH_num_entries     ; get number of name records
	mov	ax,bx			       ; save last name record address
	mov	es:[bx].nMRU_ptr, -1	       ; make first MRU -1
	jmp	short set_start

Set_Up_Names:
	mov	es:[bx].nMRU_ptr,ax		;save last name record as MRU entry
	add	ax, size Name_Record		;AX = last name record = current name record

Set_Start:
	mov	es:[bx].nChild_ptr, -1		;no children or siblings
	mov	es:[bx].nsibling_ptr, -1	;right now
	mov	es:[bx].nBackward_ptr, -1

	push	di
	push	ax
	mov	ax, '  '                        ;AX = ' '
	mov	di, bx				;DI-->current name record
	add	di, nCmpct_Dir_Info		;blank out the Dir name area
	stosb					;in the name record
	stosw
	stosw
	stosw
	stosw
	stosw
	pop	ax				; AX = last name record address
	pop	di

	dec	cx				;update record count
	jcxz	purge_exit			;exit if last name record is done
	mov	dx,bx
	add	dx, size Name_Record		;DX-->next name record
	mov	es:[bx].nLRU_ptr,dx		   ;set LRU pointer - next name record
	add	bx, size Name_Record
	jmp	set_up_names			;set next name record

Purge_exit:
	clc
	ret

FP_PURGE    ENDP



;----------------------------------------------------------------------------
;		    FASTOPEN  SUPPORT ROUTINES
;----------------------------------------------------------------------------
;
; PROCEDURE:  Find_Drive_Cache_Header
;
; Function:  Validate drive ID and find address of drive cache header
;
;IN:   DL - drive letter
;      Drive_Header_Start ;label
;      Flag.
;
;OUT:  If CY = 0    Drive Header found
;	     ES:BP -> Drive_Cache_Header,
;
;      If CY = 1    Drive Header not found
;
;----------------------------------------------------------------------------

FIND_DRIVE_CACHE_HEADER   PROC	  NEAR

	mov	bp, cs:Open_name_drive_buff
	push	ds
	mov	ds,cs:Open_Name_Cache_Seg							   ;AN000;
	ASSUME	ds:Cseg_Init				;DS:BP-->first drive header    ;AN000;

FDCH_while:
	cmp	byte ptr ds:[bp.DCH_Drive_Letter], dl	; drive letter match
	jne	fdch_chk_end				; no - check next header
	clc						; yes - exit
	jmp	short FDCH_Exit

FDCH_Chk_End:
	cmp	byte ptr ds:[bp.DCH_Sibling_ptr], -1	; is this last header ?
	je	FDCH_Not_Found				; yes - header not found
	add	bp, size Drive_Cache_Header		; no - get next header
	jmp	short	FDCH_while			; look for match

FDCH_Not_Found:
	stc						;not found

FDCH_Exit:						;ES:BP-->header if found
	pop    ds
	ASSUME ds:nothing				;return
	ret

FIND_DRIVE_CACHE_HEADER     endp




;----------------------------------------------------------------------
; PROCEDURE:  GET_FREE_NODE
;
; called by Insert. The LRU node pointed DCH_LRU_ROOT is returned in AX
; and DCH_LRU_ROOT points to the following node in LRU chain.
; If the node is not an empty node, then it will be removed from the
; tree.
;
; IN:  Current_Drive, Current_Node
;
; OUT: AX = offset of the free node in Name_Cache_Seg
;     Other registers saved.
;----------------------------------------------------------------------

GET_FREE_NODE	PROC	NEAR

	push	es				 ;save registers
	push	di
	push	si
	push	bp

	mov	ax, cs:Open_Name_Cache_Seg							   ;AN000;
	mov	es, ax				;ES=Name cache segment				  ;AN000;
	ASSUME	es:Cseg_Init									   ;AN000;
	mov	si, cs:Current_Drive		;SI-->drive_cache_header
	push	ds
	mov	ds,cs:Open_Name_Cache_Seg
	ASSUME	ds:Cseg_Init
	mov	ax, ds:[si.DCH_LRU_ROOT]	;get the LRU node
	pop	ds
	ASSUME	ds:nothing

	cmp	ax, cs:current_Node		;LRU node=Current Node ??
	je	GFN_skip			;yes-

	mov	bp, ax				;BP=Current node
	mov	di, es:[bp.nLRU_ptr]		;DI= current LRU node's following node
	mov	es:[di.nMRU_ptr],-1		;set that node's MRU ptr
	push	ds
	mov	ds,cs:Open_Name_Cache_Seg	;DS=Name cache segment
	ASSUME	ds:Cseg_Init
	mov	ds:[si.DCH_LRU_ROOT],di 	;connect previous node to
	pop	ds				;next node
	ASSUME	ds:nothing

	cmp	byte ptr es:[bp.nCmpct_Dir_Info],' ';an empty node?
	je	GFN_OK			      ;then no problem.

	CALL	RemoveFromTree		    ;otherwise, it should be removed
					    ;from the tree.
GFN_OK:
	clc
	jmp	short	GFN_ret

GFN_Skip:
	stc

GFN_ret:
	pop	bp
	pop	si
	pop	di
	pop	es
	ret				    ;return

GET_FREE_NODE	endp




;
;----------------------------------------------------------------------
; PROCEDURE:   PRE_LRU_STACK
;
; When called by Look_up, Insert routine, the requested target node (BP)
; will be temporarily removed from LRU,MRU chain (until SET_LRU routine
; call), and will be pushed into a logical stack.  Actually, this routine
; will not use a stack, but try to get the effect of the use of stack
; to keep the history of target nodes in "REVERSE" LRU order as follows;
; {    inc Depth;
;      if Depth == 1 then Bottom = BP;
;			  Bottom.LRU_ptr = -1;
;			  Bottom.MRU_ptr = -1;
; else if Depth == 2 then Top = BP;
;			  Top.LRU_ptr = Bottom;
;			  Bottom.MRU_ptr = Top;
;			  Top.MRU_ptr = -1;
; else if Depth >= 3 then Temp = Top;
;			  Top = BP;
;			  Top.LRU_ptr = Temp;
;			  Temp.MRU_ptr = Top;
;			  Top.MRU_ptr = -1;
; }
;
;IN:  Depth, Top, Bottom, Temp,
;     Requested target node (BP)
;     ES = Name_Cache_Seg
;
;OUT: Target node removed from LRU,MRU chain.
;     Target node's history saved in reverse LRU order.
;     If called by "Delete" routine, then will just exit.
;     If called by "Insert" routine, then will not attempt
;     to remove the target node.
;----------------------------------------------------------------------

PRE_LRU_STACK	PROC	NEAR

	test	cs:Flag, is_delete	   ;invoked by Delete routine
	jnz	PLS_Exit
	test	cs:Flag, is_insert	   ;called by Insert routine
	jnz	PLS_Push

	CALL	RemoveFromLRUChain	;remove BP from the chain.

PLS_Push:
	push	di

	inc	cs:Depth
	cmp	cs:Depth, 1
	jne	PLS_Top
	mov	cs:Bottom, bp		   ;bottom = bp
	mov	es:[bp.nLRU_ptr], -1
	jmp	short PLS_Done

PLS_Top:
	cmp	cs:Depth, 2
	jne	PLS_Temp
	mov	cs:Top, bp		   ;Top = bp
	mov	di, cs:bottom		   ;di = bottom

PLS_com:
	mov	es:[bp.nLRU_ptr],di	;Top.LRU_ptr = bottom
	mov	es:[di.nMRU_ptr],bp	;Bottom.MRU_ptr = top
	jmp	short PLS_Done

PLS_Temp:
	mov	di, cs:Top		   ;di = Top
	mov	cs:Temp, di		   ;Temp = di
	mov	cs:Top, bp		   ;Top = bp
	jmp	short PLS_com

PLS_Done:
	mov	es:[bp.nMRU_ptr],-1
	pop	di

PLS_Exit:
	ret

PRE_LRU_STACK	endp
;





;----------------------------------------------------------------------
;PROCEDURE:  SET_LRU
;
;INPUT:  Depth, Top, Bottom, Current_Drive, ES = Name_Cache_Seg
;
;OUT: If Depth == 0 then exit
; Pre_LRU_Stack procedure already maintained a reverse order LRU
; mini chain.  Set_LRU will just put the top after the last node
; of the current LRU chain;
; { Get the last node of LRU chain.
;   if Depth == 0 then exit;
;   if Depth == 1 then Last_Node.LRU_ptr = Bottom;
;		       Bottom.MRU_ptr = Last_Node;
;		       MRU_ROOT = Bottom;
;   if Depth >= 2 then Last_Node.LRU_ptr = Top;
;		       Top.MRU_ptr = Last_Node;
;		       MRU_ROOT = Bottom;
;   Depth = 0;
; }
;----------------------------------------------------------------------

SET_LRU   PROC	  NEAR

	cmp	cs:Depth, 0		   ;nothing in the stack?
	je	SL_Exit

	push	si
	push	di
	push	bx
	mov	si, cs:Current_Drive	   ;cs:si -> Drive_Cache_Header
	push	ds
	mov	ds,cs:Open_Name_Cache_Seg							   ;AN000;
	ASSUME	ds:Cseg_Init									   ;AN000;
	mov	di, ds:[si.DCH_MRU_ROOT] ;es:di -> Last node in LRU chain

	cmp	cs:Depth, 1
	jne	SL_Other

	mov	bx, cs:Bottom
	mov	es:[di.nLRU_ptr],bx	;Last_Node.LRU_ptr = Bottom
	mov	es:[bx.nMRU_ptr],di	;Bottom.MRU_ptr = Last_Node
	mov	ds:[si.DCH_MRU_ROOT],bx ;MRU_ROOT = Bottom
	jmp	short SL_Done

SL_Other:				;Depth >= 2
	mov	bx, cs:Top
	mov	es:[di.nLRU_ptr],bx
	mov	es:[bx.nMRU_ptr],di
	mov	bx, cs:Bottom
	mov	ds:[si.DCH_MRU_ROOT],bx

SL_Done:
	pop	ds
	ASSUME	ds:nothing
	mov	cs:Depth, 0		   ;reset the Depth
	pop	bx
	pop	di
	pop	si

SL_Exit:
	ret

Set_LRU endp





;----------------------------------------------------------------------
; Procedure RemoveFromLRUChain
;
;IN:  Target node (BP) to be removed
;     Current_drive
;     ES - Name_Cache_Seg
;
;OUT:  Target node removed from the LRU,MRU chain. LRU,MRU chain
;     updated.
;
;----------------------------------------------------------------------

RemoveFromLRUChain     PROC    near

	push	bx
	push	di
	push	si

	mov	si, cs:Current_drive	   ;cs:si-> Drive_cache_header
	mov	bx, es:[bp.nMRU_ptr]	;es:bx-> Preceding node
	mov	di, es:[bp.nLRU_ptr]	;es:di-> Following node
	cmp	bx, -1			;Is target the first node?
	je	RFLC_first_node
	cmp	di, -1			;Is target the last node of LRU chain?
	je	RFLC_last_node
	mov	es:[bx.nLRU_ptr],di	;Preceding.LRU_ptr->following node
	mov	es:[di.nMRU_ptr],bx	;Following.MRU_ptr->preceding node
	jmp	short RFLC_done

RFLC_first_node:
	push	ds
	mov	ds,cs:Open_Name_Cache_Seg							   ;AN000;
	ASSUME	ds:Cseg_Init									   ;AN000;
	mov	ds:[si.DCH_LRU_ROOT],di ;LRU_ROOT-> following node
	pop	ds
	ASSUME	ds:nothing
	mov	es:[di.nMRU_ptr], -1	;Following node's MRU_ptr
	jmp	short RFLC_done

RFLC_last_node:
	push	ds
	mov	ds,cs:Open_Name_Cache_Seg
	ASSUME	ds:Cseg_Init
	mov	ds:[si.DCH_MRU_ROOT],bx ;MRU_ROOT-> preceding node
	mov	es:[bx.nLRU_ptr], -1	;Preceding node's LRU_ptr
	pop	ds
	ASSUME	ds:nothing

RFLC_done:
	pop	si
	pop	di
	pop	bx
	ret

RemoveFromLRUChain	endp
;



;----------------------------------------------------------------------
; Proceure  RemoveFromTree
;
;IN:  BP - offset of node to be removed from the tree
;	   This node shoud not be a subdirectory that is not empty!!!
;      ES - Name_Cache_Seg
;      Current_Drive
;
;OUT:  The node will be freed from the tree.
;     The neighbor's Child_ptr, Sibling_ptr, Backward_ptr are adjusted
;     accordingly.
;     The freed node's child_ptr, sibling_ptr, backward_ptr are reset to -1.
;----------------------------------------------------------------------

REMOVEFROMTREE	 PROC	 NEAR

	push	bx
	push	dx

	mov	bx, es:[bp.nBackward_ptr]	;get the preceding node
	mov	dx, es:[bp.nSibling_ptr]	;get the sibling node
	cmp	bx, cs:Current_Drive
	je	RFT_First_Child 	;bp is the first child
	cmp	es:[bx.nChild_ptr],bp
	je	RFT_Child		;bp is the child of the preceding node
	mov	es:[bx.nSibling_ptr],dx ;bp is the Sibling of the preceding node
					;Update the preceding node's Sibling ptr
	jmp	short RFT_Reset

RFT_First_Child:
	push	ds
	mov	ds,cs:Open_Name_Cache_Seg							   ;AN000;
	ASSUME	ds:Cseg_Init									   ;AN000;
	mov	ds:[bx.DCH_Child_ptr],dx
	pop	ds
	ASSUME	ds:nothing
	jmp	short RFT_Reset

RFT_Child:
	mov	es:[bx.nChild_ptr],dx

RFT_Reset:				;reset the deleted node's tree pointers
	mov	es:[bp.nChild_ptr],-1
	mov	es:[bp.nSibling_ptr],-1
	mov	es:[bp.nBackward_ptr],-1

	xchg	dx,bx			;now, dx=preceding node, bx=following node
	cmp	bx,-1			;end of sibling?
	je	RFT_ret
	mov	es:[bx.nBackward_ptr],dx;modify backward_ptr of the sibling node

RFT_ret:
	pop	dx
	pop	bx
	ret				;return

REMOVEFROMTREE	endp
;




;----------------------------------------------------------------------
; Procedure CMPARE
;
;IN: Packed name
;    BP = target node
;
;OUT: ZERO flag set when compare O.K.
;     DI destroyed.
;----------------------------------------------------------------------

CMPARE	PROC	near

	push	ds
	push	si
	mov	cx, 11
	push	cs
	pop	ds
	mov	si, offset cs:Packed_Name	   ;ds:si -> Packed_Name
	mov	di,bp
	add	di,nCmpct_Dir_Info		;es:di -> bp.nCmpact_Dir_Info
	REPE	CMPSB
	pop	si
	pop	ds
	ret
CMPARE	endp




;
;----------------------------------------------------------------------
; Procedure:  MAKE_NAME_RECORD
;
;IN:  DS:DI -> Dir_Info, ES:BX -> Extended_Info
;     AX = offset of the Name_Record entry in Name_Cache_Seg.
;
;OUT: Name_Record in Name_Cache_Seg filled.
;     nLRU_ptr, nChild_ptr, nSibling_ptr and nMRU_ptr are set to -1 for now.
;     ES, SI, DI destroyed.  ES will be Name_Cache_Seg.
;----------------------------------------------------------------------

MAKE_NAME_RECORD      PROC     NEAR

	push	ds			;save DS
	push	ax

	push	es			;save Extended_Info seg in DOS
	push	di
	pop	si			;DS:SI -> Dir_Info
	mov	di, cs:Open_Name_Cache_Seg							   ;AN000;
	mov	es, di										   ;AN000;
	ASSUME	es:Cseg_Init									   ;AN000;
	mov	di, ax			;ES:DI -> Name_Record
	mov	ax, -1
	mov	es:[di.nLRU_ptr],ax	;initialize pointers
	mov	es:[di.nChild_ptr],ax
	mov	es:[di.nSibling_ptr],ax
	mov	es:[di.nMRU_ptr],ax
	add	di, nCmpct_Dir_Info	;ES:DI -> Name_Record.nCmpct_Dir_Info
	mov	cx, ODI_head_leng	;currently 10.
	rep	movsb			;Move header part
	add	si, ODI_skip_leng	;DS:SI -> tail part of Dir_Info
	mov	cx, ODI_tail_leng
	REP	MOVSB			;move tail part.

	pop	ds			;restore Extended_Info seg in DS!!!
	mov	si, bx			;DS:SI -> Extended_Info
	mov	cx, size Fastopen_Extended_Info
	rep	movsb			;Move Extended_Info
	pop	ax
	pop	ds			;Restore DS

	ret				;return

MAKE_NAME_RECORD	ENDP
;




;----------------------------------------------------------------------
; Procedure Unfold_Name_Record
;
;IN:  Matching_Node, ES:DI -> Dir_Info buffer, ES:CX -> Extended_Info buffer
;
;OUT: if no matching node is found, then just return
;     else Dir_Info, Extended_Info buffer are filled.
;----------------------------------------------------------------------

Unfold_Name_Record     PROC	near

	cmp	cs:Matching_Node, -1
	je	UNR_Exit		;just exit
	push	ds
	push	si
	push	di
	push	cx			;save extended_info addr

	mov	si, cs:Open_Name_Cache_Seg							   ;AN000;
	mov	ds, si										   ;AN000;
	ASSUME	ds:Cseg_Init									   ;AN000;
	mov	si, cs:Matching_Node
	add	si, nCmpct_Dir_Info	;DS:SI -> Cmpct_Dir_Info

	mov	cx, ODI_head_leng	;Dir_Info header length
	REP	MOVSB			;Cmpct_Dir_Info.CDI_file_name -> ODI_head

	add	di, ODI_skip_leng	;length of Skiped part of Dir_Info
	mov	cx, ODI_tail_leng	;Dir_Info tail length
	REP	movsb			;Cmpct_Dir_Info.CDI_Time -> ODI_tail
					;At this moment, SI -> nExtended_Info

	pop	di			;ES:DI -> Extended_info
	push	di			;save di again for cx.
	mov	cx, size Fastopen_Extended_Info
	REP	movsb

	pop	cx			;restore extended_info addr
	pop	di
	pop	si
	pop	ds
	ASSUME	ds:nothing
UNR_Exit:
	ret				;return

Unfold_Name_Record	endp
;




;----------------------------------------------------------------------
; PROCEDURE:  PACK DIR_NAME
;
; Parse the name off of DS:SI into Packed_Name.  If called first time and
; DS:[SI+1] = ':' then it is ASSUMEd to be a drive letter and it will be
; returned in DL and SI will points to '\' after ':'.  If it was a directory
; name then Packed_Name will be set and SI points to '\' or 0 after the
; parsed directory name or filename.  This routine will check DS:[SI] when
; called to see if it points to '\' or 0.  If it points to '\' then
; it is ASSUMEd that the user want to skip the delimiter.  If it was 0,
; then this routine will set carry.  So, with a given drive,path string,
; the user is going to keep calling this routine until it returns
; with carry set that tells the end.
;----------------------------------------------------------------------

PACK_DIR_NAME	PROC	NEAR

	cmp	byte ptr ds:[si], 0	;end of path ??
	jne	PDN_Drive		;no-check for drive letter
	stc
	jmp	short PDN_Exit		;yes-exit

PDN_Drive:
	cmp	byte ptr ds:[si+1], ':' ;drive letter terminater?
	jnz	PDN_chk_skip		;no -
	mov	dl, byte ptr ds:[si]	;yes-set DL to the drive letter
	inc	si
	inc	si			;set SI -> '\' after ':'
	jmp	short PDN_Exit		;then exit

PDN_chk_skip:
	cmp	byte ptr ds:[si], '\'   ;delimeter?
	jne	PDN_Path		;no-
	inc	si			;yes-skip delimiter
	cmp	byte ptr ds:[si], 0	;end of path ??
	jne	PDN_Path		;no-pack path name
	stc				;yes-In fact, the input from DOS was
	mov	ax, -1			;D:\,0.  FASTOPEN will treate
	jmp	short PDN_Exit		;this as an error.

PDN_Path:				;pack path name
	push	es
	push	di
	push	ax

	push	cs
	pop	es
	mov	di, offset cs:Packed_Name   ;ES:DI-->pack buffer

	mov	ax,'  '
	STOSB				;blank out the Packed_Name
	STOSW
	STOSW
	STOSW
	STOSW
	STOSW
	mov	di, offset cs:Packed_Name

PDN_GetName:
	LODSB				;DS:SI => AL, SI++
	cmp	al,'.'
	jz	PDN_SetExt
	or	al,al
	jz	PDN_GetDone
	cmp	al,'\'
	jz	PDN_GetDone
	STOSB
	jmp	short PDN_GetName

PDN_SetExt:
	mov	di, offset cs:Packed_Name+8

PDN_GetExt:
	LODSB
	or	al,al
	jz	PDN_GetDone
	cmp	al,'\'
	jz	PDN_GetDone

PDN_StoExt:
	STOSB
	jmp	PDN_GetExt

PDN_GetDone:
	dec	si			;set SI back to the delimeter or 0.
	pop	ax
	pop	di
	pop	es

PDN_Exit:
	ret

PACK_DIR_NAME	endp





;----------------------------------------------------------------------
; PROCEDURE:  FIND_CLUSTER_NUMBER
;
;IN:  DL = driver # (0 = A, 1 = B,...)
;     CX = The value of Dir_First in Name_Record to search.
;     Search Name_Record entries to find the matching starting cluster number.
;     The search uses MRU chain for efficiency.
;
;OUT: ES = Name_Cache_Seg
;     BP = Name_Record
;     if not found, carry bit.
;     ES, BP register changed.
;----------------------------------------------------------------------

FIND_CLUSTER_NUMBER    PROC    NEAR

	push	ax
	push	cx
	push	dx
	add	dl, 'A'                 ;convert to a drive letter

	CALL	FIND_DRIVE_CACHE_HEADER ;ES:BP -> driver header if found
	jc	FCN_exit		;exit if not found

	mov	dx, cx			;save the key in DX					   ;AN000;
	mov	ax, cs:Open_Name_Cache_Seg							   ;AN000;
	mov	es, ax										   ;AN000;
	ASSUME	es:Cseg_Init

	CALL	SET_LRU 		;clean up the LRU stack

	mov	cs:Current_Drive,bp   ;set Current_Drive (You should not set
					;Current_Drive before SET_LRU at any time!!!
	push	ds
	mov	ds,cs:Open_Name_Cache_Seg
	ASSUME	ds:Cseg_Init
	mov	cx, ds:[bp.DCH_Num_Entries]	;Max number to try
	mov	bp, ds:[bp.DCH_MRU_ROOT]	;get the start of MRU chaing
	pop	ds
	ASSUME	ds:nothing

FCN_while:
	cmp	es:[bp.nCmpct_Dir_Info], ' ' ;Is it a free node ?
	je	FCN_not_found		;then no reason to continue search.

	cmp	dx, es:[bp.nCmpct_Dir_Info.CDI_cluster] ;matching starting cluster # ?
	je	FCN_exit		;found it!!!

	mov	bp, es:[bp.nMRU_ptr]	;next MRU entry address
	cmp	bp, -1			;It was the end of MRU chain?
	je	FCN_not_found		;not found. End of search
	LOOP	FCN_while		;else compare cluster and contine...

FCN_Not_found:
	stc

FCN_exit:
	pop	dx
	pop	cx
	pop	ax
	ret

FIND_CLUSTER_NUMBER	ENDP




;----------------------------------------------------------------------
; PROCEDURE:  FIND_DIR_SECTOR	 (PTR 3718  3/10/88)
;
;     Search Name_Record using directory sector and directory position
;     for the name entry.
;
;IN:  DL = driver # (0 = A, 1 = B,...)
;     DI = Dirctory sector Low	value
;     CX = Dirctory sector high value
;     DH = Dirctory position
;
;OUT: ES = Name_Cache_Seg
;     BP = Name_Record
;     if not found, carry bit.
;     ES, BP register changed.
;----------------------------------------------------------------------

FIND_DIR_SECTOR   PROC	  NEAR

	push	ax
	push	cx
	push	dx
	add	dl, 'A'                  ;convert to a drive letter

	CALL	FIND_DRIVE_CACHE_HEADER  ;ES:BP -> driver header if found
	jc	FDIR_exit		 ; error if not found

	mov	ax, cs:Open_Name_Cache_Seg							   ;AN000;
	mov	es, ax										   ;AN000;
	ASSUME	es:Cseg_Init

	CALL	SET_LRU 		;clean up the LRU stack

	mov	ax,cx			; save directory sector high value
	mov	cs:Current_Drive,bp	;set Current_Drive (You should not set
					;Current_Drive before SET_LRU at any time!!!
	push	ds
	mov	ds,cs:Open_Name_Cache_Seg
	ASSUME	ds:Cseg_Init
	mov	cx, ds:[bp.DCH_Num_Entries]	;Max number to try
	mov	bp, ds:[bp.DCH_MRU_ROOT]	;get the start of MRU chaing
	pop	ds
	ASSUME	ds:nothing

FDIR_while:
	cmp	es:[bp.nCmpct_Dir_Info], ' ' ;Is it a free node ?
	je	FDIR_NOT_FOUND		;then no reason to continue search.

	cmp	di, word ptr es:[bp.nExtended_Info.FEI_dirsec] ;matching directory sector hi?
	jne	FDIR_Next		;check next entry

	cmp	ax, word ptr es:[bp.nExtended_Info.FEI_dirsec+2] ;matching directory sector low ?
	jne	FDIR_Next		;check next entry

	cmp	dh, es:[bp.nExtended_Info.FEI_dirpos] ;matching directory postion ?
	je	FDIR_Exit		;check next entry

FDIR_Next:
	mov	bp, es:[bp.nMRU_ptr]	;next MRU entry address
	cmp	bp, -1			;It was the end of MRU chain?
	je	FDIR_not_found		;not found. End of search
	loop	FDIR_while		;else compare cluster and contine...

FDIR_Not_found: 			; no found
	stc

FDIR_exit:
	pop	dx
	pop	cx
	pop	ax
	ret

FIND_DIR_SECTOR     ENDP





;--------------------------------------------------------------------------
; Procedure: CHECK_IT	   Call Fastopen  Tree Analyser to check the
;			   consistency of the Directory/File Tree strucutre.
;--------------------------------------------------------------------------
CHECK_IT   PROC    NEAR

       pushf				      ; save all registers
       push   ax
       push   bx
       push   cx
       push   dx
       push   si
       push   di
       push   ds
       push   es
       cmp    cs:Chk_flag,0		      ;Fastopen analyser enabled ??
       je     Check_Exit		      ;no - exit

       mov    ax,cs:Open_Name_Cache_Seg       ;yes-set multiplex function call
       mov    es,ax
       mov    ah,091h			      ;load Multiplex ID
       xor    al,al
       xor    cx,cx
       mov    cl,cs:func_cod		      ;CL=Fastopen Function code
       mov    di,cs:Current_Drive	      ;ES:DI-->current drive header
       INT    2FH			      ;call the analyser

Check_Exit:
       pop    es			      ;restore all registers
       pop    ds
       pop    di
       pop    si
       pop    dx
       pop    cx
       pop    bx
       pop    ax
       popf				      ;return
       ret

CHECK_IT    ENDP





; Calculate the size of the CSEG_OPEN Module in bytes
	IF  ($-Cseg_Open) MOD 16								   ;AN000;
	   ORG ($-Cseg_Open)+16-(($-Cseg_Open) MOD 16)						   ;AN000;
	ENDIF											   ;AN000;

END_OPEN   label   word




CSEG_OPEN    ends
     end
