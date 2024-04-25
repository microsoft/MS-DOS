
	page
;=========================================================================
; This module contains all the EQU's, STRUC's, data, and routines necessary
; for LIMDMS.INC.
; This module is to be INCLUDE'd as part of LIMDMS.INC.
;
;=========================================================================

;=========================================================================
;========== Begin EQUate Definitions =====================================
;=========================================================================

AAJ_Option_Max		equ	1h			;max option value	;an000; dms;
AAJ_Segment		equ	1h			;segment request value	;an000; dms;
AAJ_No_Pages_To_Map	equ	0h			;0 page map request	;an000; dms;

MAC_Stack_Status_Request	equ	02h		;stack size request	;an000; dms;

ER_Conv_Memory		equ	00h			;conv. memory request	;an000; dms;
ER_EMS_Memory		equ	01h			;EMS memory request	;an000; dms;
EMS_Page_Size_In_Bytes	equ	(16*1024)-1		;page size in bytes	;an000; dms;
ER_Max_Type		equ	01h			;max type possible	;an000; dms;
ER_Max_Function 	equ	01h			;max function possible	;an000; dms;
ER_Move 		equ	00h			;move data		;an000; dms;
ER_Exchange		equ	01h			;exchange data		;an000; dms;
ER_EMS_Page_FE		equ	0FEh			;phys. page FEh 	;an000; dms;
ER_EMS_Page_FF		equ	0FFh			;phys. page FFh 	;an000; dms;
ER_Dest_EMS_Memory	equ	01h			;bit 0 set		;an000; dms;
ER_Source_EMS_Memory	equ	02h			;bit 1 set		;an000; dms;
ER_Up			equ	00h			;signal forward move	;an000; dms;
ER_Down 		equ	0ffh			;signal reverse move
ER_10H			equ	10h			;equ for 10h		;an000; dms;

AR_Sub_Max		equ	01h			;5ah max. sub functions ;an000; dms;

;=========================================================================
;========== End EQUate Definitions =======================================
;=========================================================================

	page
;=========================================================================
;========== Begin STRUC Definitions ======================================
;=========================================================================

Log_Phys_Map_Struc	struc				;page structure 	;an000; dms;

	Log_Page_Number 	dw	?		;logical page number	;an000; dms;
	Phys_Page_Number_Seg	dw	?		;physical page or seg	;an000; dms;
							;  determined by AL
Log_Phys_Map_Struc	ends


Map_And_Jump_Struc	struc				;carries jump info.	;an000; dms;

	Target_Address		dd	?		;jump address		;an000; dms;
	Log_Phys_Map_Len	db	?		;entry count in 	;an000; dms;
							;  Log_Phys_Map_Struct
	Log_Phys_Map_Ptr	dd	?		;Log_Phys_Map_Struct ptr;an000; dms;

Map_And_Jump_Struc	ends							;an000; dms;


Map_And_Call_Struc	struc				;carries jump info.	;an000; dms;

	MAC_Target_Address	dd	?		;jump address		;an000; dms;
	MAC_New_Page_Map_Len	db	?		;entry count in 	;an000; dms;
							;  Log_Phys_Map_Struct
							;  for new map scheme
	MAC_New_Page_Map_Ptr	dd	?		;Log_Phys_Map_Struc ptr ;an000; dms;
							;  for new map scheme
	MAC_Old_Page_Map_Len	db	?		;entry count in 	;an000; dms;
							;  Log_Phys_Map_Struc
							;  for old map scheme
	MAC_Old_Page_Map_Ptr	dd	?		;Log_Phys_Map_Struc ptr ;an000; dms;
							;  for old map scheme
	MAC_Reserved		dw	4	DUP (?) ;Used to restore map	;an000; dms;
							;  context

Map_And_Call_Struc	ends							;an000; dms;


Move_Source_Dest_Struc	struc				;structure for move	;an000; dms;

	Region_Length_Low_Word	dw	?		;
	Region_Length_High_Word dw	?		;length of region	;an000; dms;

	Source_Memory_Type	db	?		;conv/EMS		;an000; dms;
	Source_Handle		dw	?		;handle if EMS, else 0	;an000; dms;
	Source_Initial_Offset	dw	?		;offset of source region;an000; dms;
	Source_Initial_Seg_Page dw	?		;logical page if EMS	;an000; dms;
							;  seg if conv.
	Dest_Memory_Type	db	?		;conv/EMS		;an000; dms;
	Dest_Handle		dw	?		;handle if EMS, else 0	;an000; dms;
	Dest_Initial_Offset	dw	?		;offset of source region;an000; dms;
	Dest_Initial_Seg_Page	dw	?		;logical page if EMS	;an000; dms;
							;  seg if conv.
Move_Source_Dest_Struc	ends				;end structure		;an000; dms;

Realloc_Struc	Struc				;BP addressible struc		;an000; dms;

	Realloc_Reserved	db size Instance_Entry_Struc dup (?)		;an000; dms;
	Realloc_Alloc_Byte	db	?	;reserved			;an000; dms;
	Realloc_Reg_DI		dw	?	;reserved			;an000; dms;
	Realloc_Handle		dw	?	;handle 			;an000; dms;

	Realloc_Page_Count	dw	?	;new page count 		;an000; dms;
	Realloc_Page_Alloc	dw	?	;pages to be allocated		;an000; dms;
	Realloc_Page_Dealloc	dw	?	;pages to be deallocated	;an000; dms;

	Realloc_Handle_Xref_Index dw	?	;index to end of handle table	;an000; dms;
	Realloc_LookUp_Index	  dw	?	;index to applicable handle	;an000; dms;
	Realloc_Mult		  dw	?	;multiplier			;an000; dms;

Realloc_Struc	Ends				;end structure			;an000; dms;

AAJ_Struc	Struc				;BP addressible struc		;an000; dms;

	AAJ_Reserved		db size Instance_Entry_Struc dup (?)		;an000; dms;
	AAJ_Xref_Pages		dw	?	;save logical page count	;an000; dms;
	AAJ_Handle		dw	?	;saved handle			;an000; dms;
	AAJ_Option		db	?	;saved selector state		;an000; dms;
	AAJ_LookUp_Index	dw	?	;save index			;an000; dms;
	AAJ_Mult		dw	?	;multiplier			;an000; dms;

AAJ_Struc	Ends				;end structure			;an000; dms;

MAC_Struc	Struc				;BP addressible struc		;an000; dms;

	MAC_Reserved_Area	db size Instance_Entry_Struc dup (?)		;an000; dms;
	MAC_LookUp_Index	dw	?	;save index		;an000; dms;
	MAC_Xref_Pages		dw	?	;save logical page count	;an000; dms;
	MAC_Option		db	?	;saved selector state		;an000; dms;

	EMS_Reg_ES		dw	?		;ES reg 		;an000; dms;
	EMS_Reg_DS		dw	?		;DS reg 		;an000; dms;
	EMS_Reg_FL		dw	?		;FL reg 		;an000; dms;
	EMS_Reg_SI		dw	?		;SI reg 		;an000; dms;
	EMS_Reg_DI		dw	?		;DI reg 		;an000; dms;
	EMS_Reg_DX		dw	?		;DX reg 		;an000; dms;
	EMS_Reg_CX		dw	?		;CX reg 		;an000; dms;
	EMS_Reg_BX		dw	?		;BX reg 		;an000; dms;

	MAC_M_C_Data		db	size Map_And_Call_Struc dup (?) 	;an000; dms;
	MAC_M_C_Log		db	size Log_Phys_Map_Struc*Map_Count_Def dup (?)	;an000; dms;
	MAC_Map_Table		db	size Mappable_Phys_Page_Struct*Map_Count_Def dup (?)	;an000; dms;
	MAC_Mult		dw	?	;multiplier			;an000; dms;

MAC_Struc	Ends				;end structure			;an000; dms;


ER_Struc	Struc					;BP addressible struc		;an000; dms;

	ER_Reserved		db size Instance_Entry_Struc dup (?)		;an000; dms;
	ER_Direction_Flag	db	ER_Up		;default to forward move;an000; dms;

	ER_Sub_Function 	db	?		;save subfunction byte	;an000; dms;

	ER_Src_Abs_Beg_Low	dw	?		;abs add of src EMS page;an000; dms;
	ER_Src_Abs_Beg_High	dw	?		;  beginning of trf area;an000; dms;
	ER_Src_Abs_End_Low	dw	?		;abs add of src EMS page;an000; dms;
	ER_Src_Abs_End_High	dw	?		;  end of trf area	;an000; dms;

	ER_Dst_Abs_Beg_Low	dw	?		;abs add of src EMS page;an000; dms;
	ER_Dst_Abs_Beg_High	dw	?		;  beginning of trf area;an000; dms;
	ER_Dst_Abs_End_Low	dw	?		;abs add of src EMS page;an000; dms;
	ER_Dst_Abs_End_High	dw	?		;  end of trf area	;an000; dms;

	ER_Current_Move_Count	dw	?		;bytes moved this time	;an000; dms;

	ER_Move_Xchg_Buffer1	db	10h	dup (?) ;buffer for move/xchg	;an000; dms;
	ER_Move_Xchg_Buffer2	db	10h	dup (?) ;buffer for move/xchg	;an000; dms;

	ER_Move_Count_Low	dw	?		;low word of count	;an000; dms;
	ER_Move_Count_High	dw	?		;high word of count	;an000; dms;

	ER_Source_Phys_Page	dw	?		;page number of source	;an000; dms;
	ER_Dest_Phys_Page	dw	?		;page number of dest	;an000; dms;

	ER_Source_Page		dw	?		;active source page	;an000; dms;
	ER_Dest_Page		dw	?		;active dest page	;an000; dms;

	ER_Source_Handle	dw	?		;active handle		;an000; dms;
	ER_Dest_Handle		dw	?		;active handle		;an000; dms;
							;  10h byte moves

	ER_Save_Context_Buffer	dw	2*Type Mappable_Phys_Page_Struct  dup (0) ;room for 2 pgs;an000; dms;

	ER_Dest_Seg		dw	?		;seg value of dest	;an000; dms;
	ER_Source_Seg		dw	?		;seg value of source	;an000; dms;

	ER_Dest_Off		dw	?		;off value of dest	;an000; dms;
	ER_Source_Off		dw	?		;off value of source	;an000; dms;

	ER_Mem_Type		dw	?		;memory type		;an000; dms;


ER_Struc	Ends					;end structure		;an000; dms;

;=========================================================================
;========== End STRUC Definitions ========================================
;=========================================================================

	page
;=========================================================================
;========== Begin Macro Definitions ======================================
;=========================================================================


;=========================================================================
; MAC_Expand_Stack_And_Copy	: This routine will place data in the
;				  instance table by copying the data pointed
;				  at by ES:DI.
;
;	Inputs	: AX - Size of stack adjustment
;		  ES:DI - Pointer to data to be copied to stack
;
;	Outputs : BP - data place in instance table
;
;=========================================================================

MAC_Expand_Stack_And_Copy	proc

	mov	cx,ax					;get adjustment factor	;an000; dms;
	shr	cx,1					;convert to word move	;an000; dms;
	mov	ax,es					;get data source seg	;an000; dms;
	mov	ds,ax					;place in ds		;an000; dms;
	mov	si,di					;get data source off	;an000; dms;

	mov	ax,cs					;get dest. seg		;an000; dms;
	mov	es,ax					;place in es		;an000; dms;
	mov	di,bx					;get dest. off		;an000; dms;

	cli						;ints off		;an000; dms;
	rep	movsw					;move data to stack	;an000; dms;
	sti						;ints on		;an000; dms;

	ret						;end routine		;an000; dms;

MAC_Expand_Stack_And_Copy	endp

	page
;=========================================================================
; MAC_Shrink_Stack_And_Copy	: This routine move data from the instance
;				  table and place it at ES:DI.
;
;	Inputs	: AX - Size of stack adjustment
;		  ES:DI - Pointer to where data is to be copied
;
;	Outputs : BP - data removed from instance table
;
;=========================================================================

MAC_Shrink_Stack_And_Copy	proc

	mov	cx,ax					;get adjustment factor	;an000; dms;
	mov	ax,cs					;get data source seg	;an000; dms;
	mov	ds,ax					;place in ds		;an000; dms;
	mov	si,bx					;get data source off	;an000; dms;
	mov	ax,cx					;save count across move ;an000; dms;
	shr	cx,1					;convert to word move	;an000; dms;

	cli						;ints off		;an000; dms;
	rep	movsw					;move data from stack	;an000; dms;
	sti						;ints on		;an000; dms;

	ret						;end routine		;an000; dms;

MAC_Shrink_Stack_And_Copy	endp


;=========================================================================
;========== End Macro Definitions ========================================
;=========================================================================

	page
;=========================================================================
;========== Begin Generic PROC Definitions ===============================
;=========================================================================

;=========================================================================
; Map_Pages			: This routine will map the pages being
;				  requested in the struc pointed to by
;				  DS:SI.
;
;	Inputs	: ES:DI - Pointer to data in Log_Phys_Map_Struc format
;		  CX - Count of data iterations in ES:DI
;		  DX - handle
;		  BX - page count for handle
;		  AL - option
;
;	Outputs : Revised map
;		  AH - 0   = no error
;		       > 0 = error
;=========================================================================

Map_Pages	proc					;			;an000; dms;

	push	si					;save reg		;an000; dms;

	mov	si,ax					;save option		;an000; dms;
	cmp	cx,AAJ_No_Pages_To_Map			;no pages?		;an000; dms;
	je	Map_Error_Exit				;yes - exit loop	;an000; dms;

Map_Loop_Continue:

	cmp	[di].Log_Page_Number,bx 		;logical page out of	;an000; dms;
							;  range?
	jbe	Map_Get_Segment 			;no - in range		;an000; dms;
		mov	ah,EMS_Code8A			;yes - out of range	;an000; dms;
		jmp	Map_Error_Exit			;exit routine		;an000; dms;

Map_Get_Segment:

	cmp	si,AAJ_Segment				;segment request?	;an000; dms;
	mov	ax,[di].Phys_Page_Number_Seg		;get physical page	;an000; dms;
	jne	Map_Page_Request			;no - page request	;an000; dms;
		push	dx				;save handle
		mov	dx,[di].Phys_Page_Number_Seg	;get segment		;an000; dms;
		call	Get_Phys_Seg_Page		;get the associated	;an000; dms;
							;  page for the segment
		mov	ax,dx				;place page in ax	;an000; dms;
		pop	dx				;restore handle
		jnc	Map_Page_Request		;no error - continue	;an000; dms;
			mov	ah,EMS_Code8B		;phys page not found	;an000; dms;
			jmp	Map_Error_Exit		;exit routine		;an000; dms;

Map_Page_Request:

	push	bx					;save bx across call	;an000; dms;
	mov	bx,[di].Log_Page_Number 		;logical page to map	;an000; dms;
	call	Map_L_To_P				;map the page		;an000; dms;
	pop	bx					;restore bx		;an000; dms;
	or	ah,ah					;error? 		;an000; dms;
	jnz	Map_Error_Exit				;pass error on & exit	;an000; dms;
	add	di,Type Log_Phys_Map_Struc		;adjust pointer 	;an000; dms;
	loop	Map_Loop_Continue			;continue loop		;an000; dms;
	xor	ax,ax					;signal good finish	;an000; dms;

Map_Error_Exit:

	pop	si					;restore reg		;an000; dms;

	ret						;return to caller	;an000; dms;

Map_Pages	endp					;end proc		;an000; dms;


	page
;=========================================================================
; Get_Phys_Seg_Page	: This routine will obtain the physical page
;			  number for a given segment.
;
;	Inputs	: DX - Segment value
;	Outputs : DX - Physical page number
;		  CY - Error
;		  NC - No error
;=========================================================================

Get_Phys_Seg_Page	proc				;begin routine		;an000; dms;

	push	ax					;save regs		;an000; dms;
	push	cx					;			;an000; dms;
	push	di					;			;an000; dms;

	cli						;ints off		;an000; dms;
	mov	di,offset Map_Table			;point to table map	;an000; dms;
	mov	cx,Map_Count				;number of table entries;an000; dms;
	sti						;ints on		;an000; dms;

GPSP_Loop:

	cli						;ints off		;an000; dms;
	cmp	dx,cs:[di].Phys_Page_Segment		;segment match? 	;an000; dms;
	je	GPSP_Got_Segment			;yes			;an000; dms;
	add	di,Type Mappable_Phys_Page_Struct	;adjust pointer 	;an000; dms;
	loop	GPSP_Loop				;continue search	;an000; dms;

GPSP_Got_Segment:

	sti						;ints on		;an000; dms;
	cmp	cx,0					;data found?		;an000; dms;
	je	GPSP_Not_Found				;exit with error	;an000; dms;
	mov	dx,cs:[di].Phys_Page_Number		;exit with page number	;an000; dms;
	clc						;clear cy		;an000; dms;
	jmp	GPSP_Found				;exit			;an000; dms;

GPSP_Not_Found:

	stc						;signal error		;an000; dms;

GPSP_Found:						;exit			;an000; dms;

	pop	di					;restore regs		;an000; dms;
	pop	cx					;			;an000; dms;
	pop	ax					;			;an000; dms;

	ret						;return to caller	;an000; dms;

Get_Phys_Seg_Page	endp				;end proc		;an000; dms;


;=========================================================================
;========== End Generic PROC Definitions =================================
;=========================================================================



	page

;-------------------------------------------------------------------
; Reallocate Pages	- Function 18
;
;	Entry	- AX = 51??
;		  BX = count of new allocation pages
;		  DX = handle
;
;	Exit	- AH = status
;		  BX = new page count
;		       if error - original page count
;-------------------------------------------------------------------
reallocate	proc

	push	cx					;save affected regs	;an000; dms;
	push	dx					;			;an000; dms;
	push	di					;			;an000; dms;
	push	si					;			;an000; dms;

	push	ds					;save segments		;an000; dms;
	push	es					;			;an000; dms;

	mov	ax,cs					;get code segment	;an000; dms;
	mov	ds,ax					;put int ds and 	;an000; dms;
	mov	es,ax					;  es			;an000; dms;


	mov	cs:[bp].Realloc_Page_Count,bx		;new page count 	;an000; dms;
	mov	cs:[bp].Realloc_Handle,dx		;handle 		;an000; dms;



	mov	ax,cs:[bp].Realloc_Handle		;get handle for search	;an000; dms;
	mov	cs:[bp].Realloc_Mult,Type H_LookUp_Struc;handle lookup table	;an000; dms;
	mul	cs:[bp].Realloc_Mult			;obtain index position	;an000; dms;
	mov	cs:[bp].Realloc_LookUp_Index,ax 	;index to handle	;an000; dms;
	mov	di,ax					;place index in si	;an000; dms;
	mov	dx,cs:[bp].Realloc_Handle		;get handle number	;an000; dms;


	cmp	dx,Num_Handles-1			;dx > handle count?	;an000; dms;
	jbe	Realloc_Handle_Search			;handle within range	;an000; dms;
		mov	ah,EMS_Code83			;EMS handle non-existent;an000; dms;
		jmp	Realloc_Error_Exit		;exit program		;an000; dms;

Realloc_Handle_Search:

	cmp	Handle_LookUp_Table.H_Pages[di],Reusable_Handle ;handle allocated    ;an000; dms;
	jne	Realloc_Status_Of_Handle		;handle good		;an000; dms;
		mov	ah,EMS_Code83			;EMS handle not alloc	;an000; dms;
		jmp	Realloc_Error_Exit		;exit program		;an000; dms;

Realloc_Status_Of_Handle:


	mov	ax,Handle_LookUp_Table.H_Pages[di]	;get current page count ;an000; dms;
	sub	ax,cs:[bp].Realloc_Page_Count		;more or less pages?	;an000; dms;
	jc	Realloc_More_Pages			;more pages to alloc	;an000; dms;

Realloc_Less_Pages:

	mov	bx,ax					;pages to deallocate	;an000; dms;
	mov	cs:[bp].Realloc_Page_Dealloc,ax 	;save dealloc value	;an000; dms;

	mov	si,Handle_LookUp_Table.H_Pal_Ptr[di]	;get start of links	;an000; dms;
	mov	cx,Handle_LookUp_Table.H_Pages[di]	;current pages allocated;an000; dms;
	sub	cx,bx					;pages to remain alloc	;an000; dms;


Realloc_Dealloc_Loop1:

	cmp	cx,0					;pages? 		;an000; dms;
	je	Realloc_Dealloc_Loop1_Exit		;no - exit		;an000; dms;
	shl	si,1
	mov	si,Page_Alloc_List[si]			;get next pointer	;an000; dms;
	dec	cx					;dec loop count 	;an000; dms;
	jmp	Realloc_Dealloc_Loop1			;continue		;an000; dms;

Realloc_Dealloc_Loop1_Exit:

;***** Adjust pointers *****

	mov	cx,cs:[bp].Realloc_Page_Dealloc 	;get dealloc count	;an000; dms;
	mov	ax,cs:PAL_Free_Ptr			;get the free ptr	;an001; dms;
	cmp	cx,0					;0 pages to dealloc?	;an001; dms;
	je	Realloc_Dealloc_Loop2_Exit1		;yes - bypass dealloc	;an001; dms;
	mov	cs:PAL_Free_Ptr,si			;no - set new free ptr	;an001; dms;
	dec	cx					;don't loop past last pg;an001; dms;

Realloc_Dealloc_Loop2:

	cmp	cx,0					;end of deallocate?	;an000; dms;
	je	Realloc_Dealloc_Loop2_Exit		;yes - exit		;an000; dms;
	shl	si,1					;get index entry	;an001; dms;
	mov	si,Page_Alloc_List[si]			;get next ptr		;an001; dms;
	dec	cx					;decrement counter	;an000; dms;
	jmp	Realloc_Dealloc_Loop2

Realloc_Dealloc_Loop2_Exit:

	shl	si,1					;get index entry	;an001; dms;
	mov	Page_Alloc_List[si],ax			;pt. last page to orig. ;an001; dms;
							;  free ptr.

Realloc_Dealloc_Loop2_Exit1:

	mov	ax,cs:[bp].Realloc_Page_Count		;new page count 	;an000; dms;
	mov	Handle_LookUp_Table.H_Pages[di],ax	;			;an000; dms;

	mov	ax,cs:[bp].Realloc_Page_Dealloc 	;adj. value		;an000; dms;
	add	cs:Free_Pages,ax			;free up page		;an000; dms;

	mov	bx,cs:[bp].Realloc_Page_Count		;pass back page request ;an000; dms;
	xor	ah,ah					;clear error		;an000; dms;
	jmp	Realloc_Exit				;exit			;an000; dms;

Realloc_More_Pages:

	mov	cx,cs:[bp].Realloc_Page_Count		;get page request count ;an000; dms;
	mov	di,cs:[bp].Realloc_LookUp_Index 	;get LookUp Table ptr	;an000; dms;
	mov	ax,Handle_LookUp_Table.H_Pages[di]	;get current page count ;an000; dms;
	sub	cx,ax					;get additional pages	;an000; dms;
	mov	cs:[bp].Realloc_Page_Alloc,cx		;new pages to alloc	;an000; dms;
	cmp	cx,Free_Pages				;> pages remaining?	;an000; dms;
	jbe	Realloc_Pages				;reallocate pages	;an000; dms;
		mov	ah,EMS_Code87			;Too few pages avail	;an000; dms;
		jmp	Realloc_Error_Exit		;exit prog		;an000; dms;

Realloc_Pages:

	mov	cx,Handle_LookUp_Table.H_Pages[di]	;current pages allocated;an000; dms;
	cmp	cx,0					;any pages?		;an000; dms;
	jne	Realloc_More_Pages_Cont 		;yes			;an000; dms;
	cmp	cs:[bp].Realloc_Page_Alloc,0		;any pages requested?	;an000; dms;
	je	Realloc_Alloc_Loop1_Exit		;continue		;an000; dms;

	mov	cx,cs:[bp].Realloc_Page_Alloc		;get new page count	;an001; dms;
	cli						;ints off		;an001; dms;
	call	EMS_Page_Contig_Chk			;contig pages avail?	;an001; dms;
	jnc	Realloc_New_Pages
		mov	ah,EMS_Code87			;Too few pages avail	;an000; dms;
		sti					;ints on		;an001; dms;
		jmp	Realloc_Error_Exit		;exit prog		;an000; dms;

Realloc_New_Pages:

	call	EMS_Link_Set				;set up page list	;an001; dms;

	mov	Handle_LookUp_Table.H_Pal_Ptr[di],si	;set table to pointer	;an000; dms;
	mov	Handle_LookUp_Table.H_Pages[di],cx	;new page count 	;an000; dms;
	mov	bx,cs:[bp].Realloc_Page_Count		;return new page count	;an001; dms;
	sub	cs:Free_Pages,bx			;new free count 	;an000; dms;
	sti						;ints on		;an001; dms;
	xor	ax,ax					;clear error flag	;an001; dms;

	jmp	Realloc_Exit				;exit routine		;an001; dms;


Realloc_More_Pages_Cont:

	dec	cx
	mov	si,Handle_LookUp_Table.H_Pal_Ptr[di]	;get start of links	;an000; dms;

Realloc_Alloc_Loop1:
	cmp	cx,0					;at end 		;an000; dms;
	je	Realloc_Alloc_Loop1_Exit		;yes			;an000; dms;
	shl	si,1					;word entry		;an000; dms;
	mov	si,Page_Alloc_List[si]			;get next pointer	;an000; dms;
	dec	cx					;decrement loop count	;an000; dms;
	jmp	Realloc_Alloc_Loop1			;continue		;an000; dms;

Realloc_Alloc_Loop1_Exit:

	mov	cx,cs:[bp].Realloc_Page_Alloc		;new pages to alloc	;an000; dms;
	cmp	cx,0					;pages requested?	;an001; dms;
	je	Realloc_Alloc_Exit			;no - exit routine	;an001; dms;

	mov	bx,si					;save si		;an001; dms;
	cli						;ints off		;an001; dms;
	call	EMS_Page_Contig_Chk			;contig pages?		;an001; dms;
	jnc	Realloc_Next_Pages			;yes			;an001; dms;
		mov	ah,EMS_Code87			;Too few pages avail	;an000; dms;
		sti					;ints on		;an001; dms;
		jmp	Realloc_Error_Exit		;exit prog		;an000; dms;

Realloc_Next_Pages:

;;;;	mov	ax,si					;ptr to new list	;an001; dms;
;;;;	inc	ax					;contig to new links?	;an001; dms;
;;;;	cmp	ax,bx					;			;an001; dms;
;;;;	je	Realloc_Next_Pages1			;yes continue		;an001; dms;
;;;;		mov	ah,EMS_Code87			;Too few pages avail	;an000; dms;
;;;;		sti					;ints on		;an001; dms;
;;;;		jmp	Realloc_Error_Exit		;exit prog		;an000; dms;

Realloc_Next_Pages1:

	call	EMS_Link_Set				;set up page list	;an001; dms;
	mov	ax,si					;ptr to new list	;an001; dms;
	mov	si,bx					;end of old list	;an001; dms;
	shl	si,1					;index entry		;an001; dms;
	mov	Page_Alloc_List[si],ax			;pick up new links	;an001; dms;

Realloc_Alloc_Exit:

	mov	bx,cs:[bp].Realloc_Page_Alloc		;additional pages	;an001; dms;
	sub	cs:Free_Pages,bx			;new free count 	;an000; dms;
	mov	bx,cs:[bp].Realloc_Page_Count		;pass back page request ;an000; dms;
	mov	Handle_LookUp_Table.H_Pages[di],bx	;new page count 	;an000; dms;
	sti						;ints on		;an001; dms;
	xor	ah,ah					;clear ah		;an000; dms;
	jmp	Realloc_Exit				;exit			;an000; dms;


Realloc_Error_Exit:

	cli						;ints off		;an000; dms;
	mov	si,cs:[bp].Realloc_LookUp_Index 	;get handle index	;an000; dms;
	mov	bx,Handle_LookUp_Table.H_Pages[si]	;get orig. count	;an000; dms;
	mov	Handle_LookUp_Table.H_Pages[si],bx	;new page count 	;an000; dms;
	sti						;ints on		;an000; dms;

Realloc_Exit:

	pop	es					;restore segments	;an000; dms;
	pop	ds					;			;an000; dms;

	pop	si					;restore regs		;an000; dms;
	pop	di					;			;an000; dms;
	pop	dx					;			;an000; dms;
	pop	cx					;			;an000; dms;

	ret						;return to caller	;an000; dms;

reallocate	endp



	page
;=========================================================================
;=============== Function 55h Logic -  Alter Page Map & Jump =============
;=========================================================================
;=========================================================================
; Alter_And_Jump	- This routine alters the page map and jumps
;			  to the specified address.
;
;	Inputs	: AH - 55h (Alter page map & jump)
;		  AL - Physical page number/segment selector
;		       0 = Physical page numbers specified
;		       1 = Segment addresses specified in lieu of
;			   physical page numbers
;		  DX - handle number
;		  DS:SI - Pointer to map and jump structure
;		       (see Map_And_Jump_Struct above)
;
;	Outputs : Revised map
;		  AH - Non-zero if error
;
;=========================================================================
Alter_And_Jump	proc					;modify map		;an000; dms;

	push	bx					;save regs for jump	;an000; dms;
	push	cx					;			;an000; dms;
	push	di					;			;an000; dms;
	push	si					;			;an000; dms;

	pushf						;save flags		;an000; dms;
	push	ds					;save segments		;an000; dms;
	push	es					;			;an000; dms;

	mov	bx,cs					;get code segment	;an000; dms;
	mov	es,bx					;  es			;an000; dms;

	mov	cs:[bp].AAJ_Handle,dx			;save handle		;an000; dms;
	mov	cs:[bp].AAJ_Option,al			;save selector option	;an000; dms;



	cmp	dx,Num_Handles-1			;dx > handle count	;an000; dms;
	jbe	AAJ_Check_Reusable			;continue test		;an000; dms;
		mov	ah,EMS_Code83			;EMS handle bad 	;an000; dms;
		jmp	AAJ_Error_Exit			;exit routine		;an000; dms;

AAJ_Check_Reusable:

	mov	ax,dx					;get handle		;an000; dms;
	mov	cs:[bp].AAJ_Mult,Type H_LookUp_Struc	;handle lookup table	;an000; dms;
	mul	cs:[bp].AAJ_Mult			;obtain index position	;an000; dms;
	mov	cs:[bp].AAJ_LookUp_Index,ax		;index to handle	;an000; dms;
	mov	di,ax					;place index in di	;an000; dms;

	cli						;ints off		;an000; dms;
	mov	ax,Handle_LookUp_Table.H_Pages[di]	;get logical page count ;an000; dms;
	mov	cs:[bp].AAJ_Xref_Pages,ax		;save logical page count;an000; dms;
	sti						;ints on		;an000; dms;
	cmp	Handle_LookUp_Table.H_Pages[di],Reusable_Handle ;handle allocated    ;an000; dms;
	jne	AAJ_Good_Handle 			;handle good		;an000; dms;
		mov	ah,EMS_Code83			;EMS handle bad 	;an000; dms;
		jmp	AAJ_Error_Exit			;exit routine		;an000; dms;

AAJ_Good_Handle:

	cmp	cs:[bp].AAJ_Option,AAJ_Option_Max	;option in range?	;an000; dms;
	jbe	AAJ_Good_Option 			;option good		;an000; dms;
		mov	ah,EMS_Code8F			;bad option		;an000; dms;
		jmp	AAJ_Error_Exit			;exit routine		;an000; dms;

AAJ_Good_Option:

	les	di,[si].Log_Phys_Map_Ptr		;point to map data	;an000; dms;
	xor	cx,cx					;clear loop counter	;an000; dms;
	mov	cl,[si].Log_Phys_Map_Len		;get loop count 	;an000; dms;
	mov	dx,cs:[bp].AAJ_Handle			;get handle for call	;an000; dms;
	mov	bx,cs:[bp].AAJ_Xref_Pages		;logical page count	;an000; dms;
	xor	ah,ah					;clear high word	;an000; dms;
	mov	al,cs:[bp].AAJ_Option			;option selected	;an000; dms;
	call	Map_Pages				;map the pages requested;an000; dms;
	or	ah,ah					;error? 		;an000; dms;
	jnz	AAJ_Error_Exit				;exit with error cond.	;an000; dms;

AAJ_Loop_Exit:

	pop	es					;restore regs		;an000; dms;
	pop	ds					;			;an000; dms;
	popf						;			;an000; dms;
	pop	si					;			;an000; dms;
	pop	di					;			;an000; dms;
	pop	cx					;			;an000; dms;
	pop	bx					;			;an000; dms;

	mov	cs:[bp].IE_Alloc_Byte,Unallocated	;deallocate instance	;an000; dms;

	jmp	dword ptr [si].Target_Address		;jump to address & run	;an000; dms;

AAJ_Error_Exit:

	pop	es					;restore regs		;an000; dms;
	pop	ds					;			;an000; dms;
	popf						;			;an000; dms;
	pop	si					;			;an000; dms;
	pop	di					;			;an000; dms;
	pop	cx					;			;an000; dms;
	pop	bx					;			;an000; dms;


	ret						;return to caller	;an000; dms;

Alter_And_Jump	endp					;end proc		;an000; dms;



	page
;=========================================================================
;=============== Function 56h Logic -  Alter Page Map & Call =============
;=========================================================================



;=========================================================================
; Alter_And_Call	- This routine alters the page map and calls
;			  the specified address.  The mapping context
;			  is saved on entry to the routine and restored
;			  on exit from the routine.
;
;	Inputs	: AH - 56h (Alter page map & call)
;		  AL - Physical page number/segment selector
;		       0 = Physical page numbers specified
;		       1 = Segment addresses specified in lieu of
;			   physical page numbers
;		       2 = Give minimum required stack size
;		  DX - handle number
;		  DS:SI - Pointer to map and jump structure
;		       (see Map_And_Call_Struc above)
;
;	Outputs : Revised map
;		  AH - Non-zero if error
;		  BX - Function 2 = size in bytes needed for stack
;
;=========================================================================


Alter_And_Call	proc					;modify map & call	;an000; dms;

	cmp	al,MAC_Stack_Status_Request		;stack report?		;an000; dms;
	je	MAC_Calc_Stack_Status			;yes			;an000; dms;
	jb	MAC_Alter_And_Call			;no - new mapping	;an000; dms;
		mov	ah,EMS_Code8F			;error occurred 	;an000; dms;
		jmp	MAC_Stack_Exit			;exit routine		;an000; dms;

MAC_Calc_Stack_Status:

	mov	bx,8h					;room for call address	;an000; dms;
							;  and return address
	xor	ax,ax					;signal no error	;an000; dms;
	jmp	MAC_Stack_Exit				;exit routine		;an000; dms;

MAC_Alter_And_Call:

	cli						;ints off		;an000; dms;
	mov	cs:[bp].EMS_Reg_BX,bx			;			;an000; dms;
	mov	bx,ax					;save ax across flags	;an000; dms;
	lahf						;move flags to ah	;an000; dms;
	mov	cs:[bp].EMS_Reg_FL,ax			;save flags		;an000; dms;
	mov	ax,bx					;restore ax		;an000; dms;
	mov	cs:[bp].EMS_Reg_CX,cx			;			;an000; dms;
	mov	cs:[bp].EMS_Reg_DX,dx			;			;an000; dms;
	mov	cs:[bp].EMS_Reg_DI,di			;			;an000; dms;
	mov	cs:[bp].EMS_Reg_SI,si			;			;an000; dms;
	mov	cs:[bp].EMS_Reg_DS,ds			;			;an000; dms;
	mov	cs:[bp].EMS_Reg_ES,es			;			;an000; dms;

	mov	cs:[bp].MAC_Option,al			;save option		;an000; dms;
	sti						;ints on		;an000; dms;
	cmp	dx,Num_Handles-1			;dx > handle count	;an000; dms;
	jbe	MAC_Check_Reusable			;continue test		;an000; dms;
		mov	ah,EMS_Code83			;EMS handle bad 	;an000; dms;
		jmp	MAC_Error_Exit			;exit routine		;an000; dms;

MAC_Check_Reusable:

	mov	ax,dx					;get handle		;an000; dms;
	mov	cs:[bp].MAC_Mult,Type H_LookUp_Struc	;handle lookup table	;an000; dms;
	mul	cs:[bp].MAC_Mult			;obtain index position	;an000; dms;
	mov	cs:[bp].MAC_LookUp_Index,ax		;index to handle	;an000; dms;
	mov	di,ax					;place index in di	;an000; dms;

	cli						;ints off		;an000; dms;
	mov	ax,Handle_LookUp_Table.H_Pages[di]	;get logical page count ;an000; dms;
	mov	cs:[bp].MAC_Xref_Pages,ax		;save logical page count;an000; dms;
	cmp	Handle_LookUp_Table.H_Pages[di],Reusable_Handle ;handle allocated    ;an000; dms;
	sti						;ints on		;an000; dms;
	jne	MAC_Verify_New_Count			;handle good		;an000; dms;
		mov	ah,EMS_Code83			;EMS handle bad 	;an000; dms;
		jmp	MAC_Error_Exit			;exit routine		;an000; dms;

MAC_Verify_New_Count:

	cli						;ints off		;an000; dms;
	mov	ax,Map_Count				;get phys. page count	;an000; dms;
	sti						;ints on		;an000; dms;
	cmp	[si].MAC_New_Page_Map_Len,al		;> physical pages	;an000; dms;
	jbe	MAC_Verify_Old_Count			;no - continue		;an000; dms;
		mov	ah,EMS_Code8B			;out of range		;an000; dms;
		jmp	MAC_Error_Exit			;exit routine		;an000; dms;

MAC_Verify_Old_Count:

	cli						;ints off		;an000; dms;
	mov	ax,Map_Count				;get phys. page count	;an000; dms;
	sti						;ints on		;an000; dms;
	cmp	[si].MAC_Old_Page_Map_Len,al		;> physical pages	;an000; dms;
	jbe	MAC_Do_Alter_and_Call			;no - continue		;an000; dms;
		mov	ah,EMS_Code8B			;yes - error		;an000; dms;
		jmp	MAC_Error_Exit			;exit routine		;an000; dms;

MAC_Do_Alter_And_Call:

	jmp	MAC_Build_Stack_And_Map 		;build stack and map	;an000; dms;
							;  new pages
MAC_Return_Routine:

	jmp	MAC_Strip_Stack_And_Map 		;restore data strucs	;an000; dms;
							;  and map old pages

MAC_Exit:
MAC_Error_Exit:

	cli						;ints off		;an000; dms;
	mov	bx,ax					;save ax		;an000; dms;
	mov	ax,cs:[bp].EMS_Reg_FL			;obtain entry flag stat ;an000; dms;
	sahf						;put in flags reg	;an000; dms;
	mov	ax,bx					;restore ax		;an000; dms;
	mov	bx,cs:[bp].EMS_Reg_BX			;			;an000; dms;
	mov	cx,cs:[bp].EMS_Reg_CX			;			;an000; dms;
	mov	dx,cs:[bp].EMS_Reg_DX			;			;an000; dms;
	mov	di,cs:[bp].EMS_Reg_DI			;			;an000; dms;
	mov	si,cs:[bp].EMS_Reg_SI			;			;an000; dms;
	mov	ds,cs:[bp].EMS_Reg_DS			;			;an000; dms;
	mov	es,cs:[bp].EMS_Reg_ES			;			;an000; dms;
	sti						;ints on		;an000; dms;

MAC_Stack_Exit:

	ret						;return to caller	;an000; dms;


;=========================================================================
; MAC_Build_Stack_And_Map	: This routine will build the required
;				  stack structure for a re-entrant
;				  routine and map the new pages.
;
;	Inputs	: DS:SI - Pointer to data in Map_And_Call_Struc format
;
;	Outputs : BP - Instance table to reflect data copyied to it
;		  New mapped pages
;		  AH -	0 = no error
;		       >0 = error	(determined by Map_Pages)
;
;	Instance Table carries this data: Old Map Data
;					  New Map Data
;					  Map & Call Data
;					  Context
;=========================================================================

MAC_Build_Stack_And_Map:

	mov	cs:[bp].EMS_Reg_DS,ds			;save DS		;an000; dms;
	mov	cs:[bp].EMS_Reg_SI,si			;save SI		;an000; dms;

	mov	ax,word ptr [si].MAC_Old_Page_Map_Ptr[+2];get the segment	 ;an000; dms;
	mov	es,ax					;  of the old map	;an000; dms;
	mov	di,word ptr [si].MAC_Old_Page_Map_Ptr[+0];get its offset	 ;an000; dms;

	mov	al,[si].MAC_Old_Page_Map_Len		;get length of data	;an000; dms;
	cbw						;convert to word	;an000; dms;
	xor	dx,dx					;clear high word	;an000; dms;
	mov	bx,Type Log_Phys_Map_Struc		;struc size
	mul	bx					;get total byte count	;an000; dms;
	cli						;ints off		;an000; dms;
	mov	bx,offset MAC_M_C_Log			;offset in struc	;an000; dms;
	sti						;ints on		;an000; dms;
	add	bx,bp					;actual offset		;an000; dms;
	call	MAC_Expand_Stack_And_Copy		;set up stack for	;an000; dms;
							;  copy of data and
							;  copy the data
	mov	ds,cs:[bp].EMS_Reg_DS			;restore ds		;an000; dms;
	mov	si,cs:[bp].EMS_Reg_SI			;restore si		;an000; dms;

	mov	ax,word ptr [si].MAC_New_Page_Map_Ptr[+2];get the segment	 ;an000; dms;
	mov	es,ax					;  of the old map	;an000; dms;
	mov	di,word ptr [si].MAC_New_Page_Map_Ptr[+0];get its offset	 ;an000; dms;

	mov	al,[si].MAC_New_Page_Map_Len		;get length of data	;an000; dms;
	cbw						;conver to word 	;an000; dms;
	xor	dx,dx					;clear high word	;an000; dms;
	mov	bx,Type Log_Phys_Map_Struc		;struc size
	mul	bx					;get total byte count	;an000; dms;
	cli						;ints off		;an000; dms;
	mov	bx,offset MAC_M_C_Log			;Ptr in struc		;an000; dms;
	add	bx,size MAC_M_C_Log/2			;next entry		;an000; dms;
	sti						;ints on		;an000; dms;
	add	bx,bp					;offset BP relative	;an000; dms;
	call	MAC_Expand_Stack_And_Copy		;set up stack for	;an000; dms;
							;  copy of data and
							;  copy the data
	mov	ds,cs:[bp].EMS_Reg_DS			;restore ds		;an000; dms;
	mov	si,cs:[bp].EMS_Reg_SI			;restore si		;an000; dms;

	mov	ax,ds					;move seg of data to	;an000; dms;
	mov	es,ax					;  es			;an000; dms;
	mov	di,si					;move off of data	;an000; dms;
	mov	ax,Type Map_And_Call_Struc		;get size of structure	;an000; dms;
	cli						;ints off		;an000; dms;
	mov	bx,offset MAC_M_C_Data
	sti						;ints on		;an000; dms;
	add	bx,bp					;offset BP relative	;an000; dms;
	call	MAC_Expand_Stack_And_Copy		;set up stack for	;an000; dms;
							;  copy of data and
							;  copy the data
	mov	ds,cs:[bp].EMS_Reg_DS			;restore ds		;an000; dms;
	mov	si,cs:[bp].EMS_Reg_SI			;restore si		;an000; dms;

	mov	ax,cs					;get seg of context	;an000; dms;
	mov	es,ax					;  in es		;an000; dms;
	cli						;ints off		;an000; dms;
	mov	di,offset cs:Map_Table			;get offset of context	;an000; dms;
	mov	ax,Map_Count				;get context entry count;an000; dms;
	sti						;ints on		;an000; dms;
	xor	dx,dx					;clear dx		;an000; dms;
	mov	bx,Type Mappable_Phys_Page_Struct	;get struc size 	;an000; dms;
	mul	bx					;get size in bytes	;an000; dms;
	cli						;ints off		;an000; dms;
	mov	bx,offset cs:MAC_Map_Table
	sti						;ints on		;an000; dms;
	add	bx,bp					;offset BP relative	;an000; dms;
	call	MAC_Expand_Stack_And_Copy		;set up stack for	;an000; dms;
							;  copy of data and
							;  copy the data
	mov	ds,cs:[bp].EMS_Reg_DS			;restore ds		;an000; dms;
	mov	si,cs:[bp].EMS_Reg_SI			;restore si		;an000; dms;

	push	cs					;save return segment	;an000; dms;
	mov	ax,offset MAC_Return_Routine		;save return offset	;an000; dms;
	push	ax					;			;an000; dms;

	mov	ax,word ptr [si].MAC_Target_Address[+2] ;get seg of call far	;an000; dms;
	mov	bx,word ptr [si].MAC_Target_Address[+0] ;get offset of call far ;an000; dms;
	push	ax					;put on stack		;an000; dms;
	push	bx					;			;an000; dms;

	les	di,[si].MAC_New_Page_Map_Ptr		;set up for call	;an000; dms;
	xor	cx,cx					;clear cx		;an000; dms;
	mov	cl,[si].MAC_New_Page_Map_Len		;get array size 	;an000; dms;
	mov	dx,cs:[bp].EMS_Reg_DX			;get handle for call	;an000; dms;
	mov	bx,cs:[bp].MAC_Xref_Pages		;get handle page count	;an000; dms;
	xor	ah,ah					;clear high word	;an000; dms;
	mov	al,cs:[bp].MAC_Option			;get option		;an000; dms;

	call	Map_Pages				;map the new pages	;an000; dms;
	or	ah,ah					;error? 		;an000; dms;
	jnz	MAC_Error_Strip_Stack			;take data off stack	;an000; dms;

	cli						;ints off		;an000; dms;
	mov	ax,cs:[bp].EMS_Reg_FL			;obtain entry flag stat ;an000; dms;
	sahf						;put in flags reg	;an000; dms;
	mov	bx,cs:[bp].EMS_Reg_BX			;			;an000; dms;
	mov	cx,cs:[bp].EMS_Reg_CX			;			;an000; dms;
	mov	dx,cs:[bp].EMS_Reg_DX			;			;an000; dms;
	mov	di,cs:[bp].EMS_Reg_DI			;			;an000; dms;
	mov	si,cs:[bp].EMS_Reg_SI			;			;an000; dms;
	mov	ds,cs:[bp].EMS_Reg_DS			;			;an000; dms;
	mov	es,cs:[bp].EMS_Reg_ES			;			;an000; dms;
	sti						;ints on		;an000; dms;

Retf_Fake_Out	Proc	Far				;this proc is to	;an000; dms;
							;  simulate a RETF
							;  instruction
	ret						;performs a far return	;an000; dms;

Retf_Fake_Out	Endp					;end of retf fake out	;an000; dms;


MAC_Error_Strip_Stack:

	add	sp,8h					;adjust for return add. ;an000; dms;
							;  and target add. on
							;  error
	jmp	MAC_Error_Exit				;exit routine		;an000; dms;


;=========================================================================
; MAC_Strip_Stack_And_Map	: This routine will strip the stack of all
;				  the data placed on by MAC_Build_Stack_And_Map.
;
;	Inputs	: CS:BP - Pointer to data on the instance table
;
;	Outputs : All data area restored
;		  Pages remapped to original
;		  AH -	0 = no error
;		       >0 = error	(determined by Map_Pages)
;
;	Instance Table carries this data: Old Map Data
;					  New Map Data
;					  Map & Call Data
;					  Context
;=========================================================================

MAC_Strip_Stack_And_Map:							;an000; dms;

	mov	ax,cs					;seg of context 	;an000; dms;
	mov	es,ax					;place in es		;an000; dms;
	cli						;ints off		;an000; dms;
	mov	di,offset cs:Map_Table			;get off of context	;an000; dms;
	mov	ax,Map_Count				;get entries in context ;an000; dms;
	sti						;ints on		;an000; dms;
	xor	dx,dx					;clear dx		;an000; dms;
	mov	bx,Type Mappable_Phys_Page_Struct	;struc size		;an000; dms;
	mul	bx					;get byte count 	;an000; dms;
	cli						;ints off		;an000; dms;
	mov	bx,offset MAC_Map_Table
	sti						;ints on		;an000; dms;
	add	bx,bp					;offset BP relative	;an000; dms;
	call	MAC_Shrink_Stack_And_Copy		;restore context	;an000; dms;

	mov	si,cs:[bp].EMS_Reg_SI			;restore pointer	;an000; dms;
	mov	ds,cs:[bp].EMS_Reg_DS			;  to data struc	;an000; dms;

	mov	ax,ds					;transfer seg of struc	;an000; dms;
	mov	es,ax					;  to dest. segment	;an000; dms;
	mov	di,si					;di=dest. offset	;an000; dms;
	mov	ax,Type Map_And_Call_Struc		;get size to move	;an000; dms;
	cli						;ints off		;an000; dms;
	mov	bx,offset MAC_M_C_Data
	sti						;ints on		;an000; dms;
	add	bx,bp					;offset BP relative	;an000; dms;
	call	MAC_Shrink_Stack_And_Copy		;restore Map & Call buf ;an000; dms;

	mov	ds,cs:[bp].EMS_Reg_DS			;restore ds		;an000; dms;
	mov	si,cs:[bp].EMS_Reg_SI			;restore si		;an000; dms;

	mov	ax,word ptr [si].MAC_New_Page_Map_Ptr[+2];get the segment	 ;an000; dms;
	mov	es,ax					;  of the old map	;an000; dms;
	mov	di,word ptr [si].MAC_New_Page_Map_Ptr[+0];get its offset	 ;an000; dms;

	mov	al,[si].MAC_New_Page_Map_Len		;get length of data	;an000; dms;
	cbw						;convert to word	;an000; dms;
	xor	dx,dx					;clear high word	;an000; dms;
	mov	bx,Type Log_Phys_Map_Struc		;struc size		;an000; dms;
	mul	bx					;get total byte count	;an000; dms;
	cli						;ints off		;an000; dms;
	mov	bx,offset MAC_M_C_Log
	sti						;ints on		;an000; dms;
	add	bx,size MAC_M_C_Log/2
	add	bx,bp					;offset BP relative	;an000; dms;
	call	MAC_Shrink_Stack_And_Copy		;restore new page data	;an000; dms;

	mov	ds,cs:[bp].EMS_Reg_DS			;restore ds		;an000; dms;
	mov	si,cs:[bp].EMS_Reg_SI			;restore si		;an000; dms;

	mov	ax,word ptr [si].MAC_Old_Page_Map_Ptr[+2];get the segment	 ;an000; dms;
	mov	es,ax					;  of the old map	;an000; dms;
	mov	di,word ptr [si].MAC_Old_Page_Map_Ptr[+0];get its offset	 ;an000; dms;

	mov	al,[si].MAC_Old_Page_Map_Len		;get length of data	;an000; dms;
	cbw						;convert to word	;an000; dms;
	xor	dx,dx					;clear high word	;an000; dms;
	mov	bx,Type Log_Phys_Map_Struc		;struc size		;an000; dms;
	mul	bx					;get total byte count	;an000; dms;
	cli						;ints off		;an000; dms;
	mov	bx,offset MAC_M_C_Log
	sti						;ints on		;an000; dms;
	add	bx,bp					;offset BP relative	;an000; dms;
	call	MAC_Shrink_Stack_And_Copy		;set up stack for	;an000; dms;

	mov	ds,cs:[bp].EMS_Reg_DS			;restore ds		;an000; dms;
	mov	si,cs:[bp].EMS_Reg_SI			;restore si		;an000; dms;

	mov	dx,cs:[bp].EMS_Reg_DX			;get DX reg

	les	di,[si].MAC_Old_Page_Map_Ptr		;set up for call	;an000; dms;
	xor	cx,cx					;clear cx		;an000; dms;
	mov	cl,[si].MAC_Old_Page_Map_Len		;get array size 	;an000; dms;
	mov	bx,cs:[bp].MAC_Xref_Pages		;get handle page count	;an000; dms;
	xor	ah,ah					;clear high byte	;an000; dms;
	mov	al,cs:[bp].MAC_Option			;get option		;an000; dms;

	call	Map_Pages				;map the new pages	;an000; dms;

	jmp	MAC_Exit				;exit the program	;an000; dms;


Alter_And_Call	endp					;end proc		;an000; dms;


	page
;=========================================================================
;=============== Function 57h Logic -  Move/Exchange Memory Region =======
;=========================================================================

;=========================================================================
; Exchng_Region 	- This routine moves/exchanges memory regions
;			  specified by the user.  The following types of
;			  moves/exchanges are possible:
;
;			Source			Destination
;			-------------------	----------------------
;			Conventional Memory	Expanded Memory
;			Expanded Memory 	Conventional Memory
;			Expanded Memory 	Expanded Memory
;
;	Inputs	: AH - 57h (Move/Exchange Memory Region)
;		  AL - Type of transfer
;		       0 = Move memory
;		       1 = Exchange memory
;		  DS:SI - Pointer to Move_Source_Dest Structure
;
;	Outputs : Revised map
;		  AH - Non-zero if error
;=========================================================================


Exchng_Region	proc

	push	bx					;save regs		;an000; dms;
	push	cx					;			;an000; dms;
	push	dx					;			;an000; dms;
	push	di					;			;an000; dms;
	push	si					;			;an000; dms;
	push	ds					;			;an000; dms;
	push	es					;			;an000; dms;

	mov	cs:[bp].ER_Sub_Function,al		;save subfunction	;an000; dms;
	cmp	al,ER_Max_Function			;valid function?	;an000; dms;
	jbe	ER_Valid_Sub_Function			;yes - continue 	;an000; dms;
		mov	ah,EMS_Code8F			;no - error		;an000; dms;
		jmp	ER_Error_Exit			;exit routine		;an000; dms;

ER_Valid_Sub_Function:

	call	ER_Type_Check				;Proper types & 	;an000; dms;
	or	ah,ah					;  type combinations?	;an000; dms;
	jnz	ER_Error_Exit				;no - exit routine	;an000; dms;

	call	ER_Handle_Check 			;valid handles? 	;an000; dms;
	or	ah,ah					;			;an000; dms;
	jnz	ER_Error_Exit				;no - exit routine	;an000; dms;

	call	ER_Length_Check 			;Region fits in page	;an000; dms;
	or	ah,ah					;  and <= 1Mb?		;an000; dms;
	jnz	ER_Error_Exit				;no - exit routine	;an000; dms;

	call	ER_Wrap_Check				;> 1Mb wrap on move?	;an000; dms;
	or	ah,ah					;			;an000; dms;
	jnz	ER_Error_Exit				;yes - exit routine	;an000; dms;

	call	ER_Overlap_Check			;conv. memory overlaps	;an000; dms;
	or	ah,ah					;  EMS page frame?	;an000; dms;
	jnz	ER_Error_Exit				;yes - exit routine	;an000; dms;

	call	ER_Log_Page_Test			;offset valid for log.	;an000; dms;
	or	ah,ah					;  page?		;an000; dms;
	jnz	ER_Error_Exit				;no - exit routine	;an000; dms;

	cmp	cs:[bp].ER_Sub_Function,ER_Move 	;move?			;an000; dms;
	je	ER_Move_Call				;yes - perform move	;an000; dms;
		call	ER_EMS_Overlap_Check		;EMS pages overlap?	;an000; dms;
		or	ah,ah				;
		jz	ER_Exchange_No_Overlap		;no  - exit with error	;an000; dms;
			mov	ah,EMS_Code97		;signal error		;an000; dms;
			jmp	ER_Error_Exit		;exit with error code	;an000; dms;

ER_Exchange_No_Overlap:

		call	ER_Exchange_Data		;no  - perform exchange ;an000; dms;
		jmp	ER_Exit 			;exit the routine	;an000; dms;

ER_Move_Call:

		call	ER_EMS_Overlap_Check		;see if we had a move	;an000; dms;
							;  overlap
		push	ax				;save result across call;an000; dms;
		call	ER_Move_Data			;perform the move	;an000; dms;
		pop	ax				;restore result 	;an000; dms;

	ER_Exit:
	ER_Error_Exit:

	pop	es					;restore regs		;an000; dms;
	pop	ds					;			;an000; dms;
	pop	si					;			;an000; dms;
	pop	di					;			;an000; dms;
	pop	dx					;			;an000; dms;
	pop	cx					;			;an000; dms;
	pop	bx					;			;an000; dms;

	ret						;return to caller	;an000; dms;

Exchng_Region	endp


;=========================================================================
; ER_Handle_Check	: This routine checks to see if the EMS handles
;			  specified are valid.
;
;	Inputs	: DS:SI - Pointer to Move_Source_Dest_Struc data
;
;	Outputs : AH - Non-zero on error
;			Possible error codes: 83h
;=========================================================================

ER_Handle_Check 	proc				;check requested handles;an000; dms;

	push	dx					;save regs		;an000; dms;
	push	di					;			;an000; dms;

	cmp	[si].Source_Memory_Type,ER_Conv_Memory	;Conv memory for source?;an000; dms;
	je	ER_Handle_Check_Dest			;yes - ck dest. handle	;an000; dms;

	push	dx					;save dx		;an000; dms;
	xor	dx,dx					;clear it		;an000; dms;
	mov	ax,[si].Source_Handle			;get handle requested	;an000; dms;
	mov	dx,Type H_LookUp_Struc			;handle lookup table	;an000; dms;
	mul	dx					;obtain index position	;an000; dms;
	mov	di,ax					;place index in di	;an000; dms;
	pop	dx					;restore dx		;an000; dms;

	cmp	Handle_LookUp_Table.H_Pages[di],Reusable_Handle ;handle allocated    ;an000; dms;
	je	ER_Handle_Check_Error_Exit		;handle not allocated	;an000; dms;

ER_Handle_Check_Dest:

	cmp	[si].Dest_Memory_Type,ER_Conv_Memory	;Conv memory for dest?	;an000; dms;
	je	ER_Handle_Check_Good_Exit		;yes - exit routine	;an000; dms;

	push	dx					;save dx		;an000; dms;
	xor	dx,dx					;clear it		;an000; dms;
	mov	ax,[si].Dest_Handle			;get handle requested	;an000; dms;
	mov	dx,Type H_LookUp_Struc			;handle lookup table	;an000; dms;
	mul	dx					;obtain index position	;an000; dms;
	mov	di,ax					;place index in di	;an000; dms;
	pop	dx					;restore dx		;an000; dms;

	cmp	Handle_LookUp_Table.H_Pages[di],Reusable_Handle ;handle allocated    ;an000; dms;
	je	ER_Handle_Check_Error_Exit		;handle not allocated	;an000; dms;

ER_Handle_Check_Good_Exit:

	xor	ah,ah					;signal no error	;an000; dms;
	jmp	ER_Handle_Check_Exit			;exit program		;an000; dms;

ER_Handle_Check_Error_Exit:

	mov	ah,EMS_Code83				;signal error		;an000; dms;

ER_Handle_Check_Exit:

	pop	di					;restore regs		;an000; dms;
	pop	dx					;			;an000; dms;

	ret						;return to caller	;an000; dms;

ER_Handle_Check 	endp				;end proc		;an000; dms;



;=========================================================================
; ER_Length_Check	: This routine checks to see if the region length
;			  specified exceeds the page count of either the
;			  source or destination EMS handle pages allocated.
;			  It also checks to determine if the region length
;			  exceeds 1 Mb.
;
;	Inputs	: DS:SI - Pointer to Move_Source_Dest_Struc data
;
;	Outputs : AH - Non-zero on error
;			Possible error codes: 93h
;					      96h
;					      8Ah
;=========================================================================

ER_Length_Check 	proc				;check region length	;an000; dms;

	push	bx					;save regs		;an000; dms;
	push	cx					;			;an000; dms;
	push	dx					;			;an000; dms;
	push	di					;			;an000; dms;

	mov	cx,[si].Region_Length_High_Word 	;get size of the region ;an000; dms;
	mov	bx,[si].Region_Length_Low_Word		;  in CX:BX		;an000; dms;
	cmp	cx,ER_10H				;> 1Mb			;an000; dms;
	ja	ER_Length_Check_Error96 		;exit with error	;an000; dms;
	cmp	cx,ER_10H				;high word = 10h?	;an000; dms;
	jne	ER_Length_Check_Cont			;no - continue		;an000; dms;
	cmp	bx,0					;low word other than 0? ;an000; dms;
	je	ER_Length_Check_Cont			;no - good value	;an000; dms;

ER_Length_Check_Error96:

	mov	ah,EMS_Code96				;signal error		;an000; dms;
	jmp	ER_Length_Check_Exit			;exit routine

ER_Length_Check_Cont:

	cmp	[si].Source_Memory_Type,ER_Conv_Memory	;Conv memory for source?;an000; dms;
	je	ER_Length_Check_Dest			;yes - ck dest. length	;an000; dms;

	push	dx					;save dx		;an000; dms;
	xor	dx,dx					;clear it		;an000; dms;
	mov	ax,[si].Source_Handle			;get handle requested	;an000; dms;
	mov	dx,Type H_LookUp_Struc			;handle lookup table	;an000; dms;
	mul	dx					;obtain index position	;an000; dms;
	mov	di,ax					;place index in di	;an000; dms;
	pop	dx					;restore dx		;an000; dms;

	mov	ax,Handle_LookUp_Table.H_Pages[di]   ;get logical page count ;an000; dms;
							;  for source handle
	sub	ax,[si].Source_Initial_Seg_Page 	;pages in EMS to fill	;an000; dms;
	push	ax					;save ax		;an000; dms;
	dec	ax					;make it 0 based	;an000; dms;
	pop	ax					;restore ax		;an000; dms;
	js	ER_Length_Check_Error8A_Exit		;page out of range	;an000; dms;

	xor	dx,dx					;clear it		;an000; dms;
	mov	dx,EMS_Page_Size_In_Bytes+1		;page size in bytes	;an000; dms;
	mul	dx					;get total bytes to trf ;an000; dms;
	sub	ax,[si].Source_Initial_Offset		;get byte count in 1st	;an000; dms;
	sbb	dx,0

	mov	bx,ax					;prepare for DWORD comp ;an000; dms;
	mov	ax,dx					;			;an000; dms;

	mov	cx,[si].Region_Length_High_Word 	;get size of the region ;an000; dms;
	mov	dx,[si].Region_Length_Low_Word		;  in CX:BX		;an000; dms;

	call	ER_Dword_Compare			;region > target?	;an000; dms;
	jc	ER_Length_Check_Error93_Exit		;CY = region > target	;an000; dms;


ER_Length_Check_Dest:

	cmp	[si].Dest_Memory_Type,ER_Conv_Memory	;Conv memory for dest?	;an000; dms;
	je	ER_Length_Check_Good_Exit		;yes - exit routine	;an000; dms;

	push	dx					;save dx		;an000; dms;
	xor	dx,dx					;clear it		;an000; dms;
	mov	ax,[si].Dest_Handle			;get handle requested	;an000; dms;
	mov	dx,Type H_LookUp_Struc			;handle lookup table	;an000; dms;
	mul	dx					;obtain index position	;an000; dms;
	mov	di,ax					;place index in di	;an000; dms;
	pop	dx					;restore dx		;an000; dms;

	mov	ax,Handle_LookUp_Table.H_Pages[di]   ;get logical page count ;an000; dms;

	sub	ax,[si].Dest_Initial_Seg_Page		;pages in EMS to fill	;an000; dms;
	push	ax					;save ax		;an000; dms;
	dec	ax					;make it 0 based	;an000; dms;
	pop	ax					;restore ax		;an000; dms;
	js	ER_Length_Check_Error8A_Exit		;page out of range	;an000; dms;

	xor	dx,dx					;clear high word	;an000; dms;
	mov	dx,EMS_Page_Size_In_Bytes+1		;page size in bytes	;an000; dms;
	mul	dx					;get total bytes to trf ;an000; dms;
	sub	ax,[si].Dest_Initial_Offset		;get byte count in 1st	;an000; dms;
	sbb	dx,0

	mov	bx,ax					;prepare for DWORD comp ;an000; dms;
	mov	ax,dx					;			;an000; dms;

	mov	cx,[si].Region_Length_High_Word 	;get size of the region ;an000; dms;
	mov	dx,[si].Region_Length_Low_Word		;  in CX:BX		;an000; dms;

	call	ER_Dword_Compare			;region > target?	;an000; dms;
	jc	ER_Length_Check_Error93_Exit		;CY = region > target	;an000; dms;


ER_Length_Check_Good_Exit:

	xor	ah,ah					;signal no error	;an000; dms;
	jmp	ER_Length_Check_Exit			;exit routine		;an000; dms;

ER_Length_Check_Error93_Exit:

	mov	ah,EMS_Code93				;signal error		;an000; dms;
	jmp	ER_Length_Check_Exit			;exit routine		;an000; dms;

ER_Length_Check_Error8A_Exit:

	mov	ah,EMS_Code8A				;signal error		;an000; dms;

ER_Length_Check_Exit:					;main exit		;an000; dms;

	pop	di					;restore regs		;an000; dms;
	pop	dx					;			;an000; dms;
	pop	cx					;			;an000; dms;
	pop	bx					;			;an000; dms;

	ret						;return to caller	;an000; dms;

ER_Length_Check 	endp				;end proc		;an000; dms;


;=========================================================================
; ER_Type_Check 	: This routine checks the source/destination type
;			  specified to determine if they are within the
;			  proper range.
;
;	Inputs	: DS:SI - Pointer to Move_Source_Dest_Struc data
;
;	Outputs : AH - Non-zero on error
;			Possible error codes: 98h
;=========================================================================

ER_Type_Check		proc				;check type		;an000; dms;

	cmp	[si].Source_Memory_Type,ER_Max_Type	;type within range?	;an000; dms;
	ja	ER_Type_Check_Error_Exit		;no - error exit	;an000; dms;

	cmp	[si].Dest_Memory_Type,ER_Max_Type	;type within range?	;an000; dms;
	ja	ER_Type_Check_Error_Exit		;no - error exit	;an000; dms;


ER_Type_Check_Good_Exit:

	xor	ah,ah					;signal no error	;an000; dms;
	jmp	ER_Type_Check_Exit			;exit routine		;an000; dms;

ER_Type_Check_Error_Exit:

	mov	ah,EMS_Code98				;signal error		;an000; dms;

ER_Type_Check_Exit:

	ret						;return to caller	;an000; dms;

ER_Type_Check		endp				;end proc		;an000; dms;


;=========================================================================
; ER_Wrap_Check 	: This routine checks to determine if there will be
;			  a wrap of conventional memory beyond 1Mb.
;
;	Inputs	: DS:SI - Pointer to Move_Source_Dest_Struc data
;
;	Outputs : AH - Non-zero on error
;			Possible error codes: A2h
;=========================================================================

ER_Wrap_Check		proc				;cks. conv. mem. wrap	;an000; dms;

	push	dx					;save regs		;an000; dms;
	push	bx					;			;an000; dms;

	cmp	[si].Source_Memory_Type,ER_Conv_Memory	;conv. memory?		;an000; dms;
	jne	ER_Wrap_Check_Dest			;no -check dest.	;an000; dms;

	mov	ax,[si].Source_Initial_Seg_Page 	;get segment		;an000; dms;
	xor	dx,dx					;clear high word	;an000; dms;
	mov	bx,ER_10H				;adjust segment to	;an000; dms;
							;  absolute address
	mul	bx					;			;an000; dms;
	add	ax,[si].Source_Initial_Offset		;add in offset		;an000; dms;
	adc	dx,0					;pick up carry if any	;an000; dms;

	add	ax,[si].Region_Length_Low_Word		;add in low word of	;an000; dms;
							;  trf size
	adc	dx,[si].Region_Length_High_Word 	;add in high word of	;an000; dms;
							;  trf size
	cmp	dx,ER_10H				;> 1Mb? 		;an000; dms;
	jae	ER_Wrap_Check_Error_Exit		;yes - signal error	;an000; dms;
	jmp	ER_Wrap_Check_Good_Exit 		;no - signal no error	;an000; dms;

ER_Wrap_Check_Dest:

	cmp	[si].Dest_Memory_Type,ER_Conv_Memory	;conv. memory?		;an000; dms;
	jne	ER_Wrap_Check_Good_Exit 		;no - exit routine	;an000; dms;

	mov	ax,[si].Dest_Initial_Seg_Page		;get segment		;an000; dms;
	xor	dx,dx					;clear high word	;an000; dms;
	mov	bx,ER_10H				;adjust segment to	;an000; dms;
							;  absolute address
	mul	bx					;			;an000; dms;
	add	ax,[si].Dest_Initial_Offset		;add in offset		;an000; dms;
	adc	dx,0					;pick up carry if any	;an000; dms;

	add	ax,[si].Region_Length_Low_Word		;add in low word of	;an000; dms;
							;  trf size
	adc	dx,[si].Region_Length_High_Word 	;add in high word of	;an000; dms;
							;  trf size
	cmp	dx,ER_10H				;> 1Mb? 		;an000; dms;
	jae	ER_Wrap_Check_Error_Exit		;yes - signal error	;an000; dms;

ER_Wrap_Check_Good_Exit:

	xor	ah,ah					;signal no error	;an000; dms;
	jmp	ER_Wrap_Check_Exit			;exit routine		;an000; dms;

ER_Wrap_Check_Error_Exit:

	mov	ah,EMS_CodeA2				;signal error		;an000; dms;

ER_Wrap_Check_Exit:

	pop	bx					;restore regs		;an000; dms;
	pop	dx					;			;an000; dms;

	ret						;return to caller	;an000; dms;

ER_Wrap_Check		endp				;end proc		;an000; dms;


;=========================================================================
; ER_Overlap_Check	: This routine checks to determine if the conventional
;			  memory region and expanded memory region overlap.
;			  Specifically, does the conventional memory region
;			  overlap the physical page addresses used for
;			  expanded memory?
;
;	Inputs	: DS:SI - Pointer to Move_Source_Dest_Struc data
;
;	Outputs : AH - Non-zero on error
;			Possible error codes: 94h
;
;	Algorithm :
;
;	If Beg.Src.Add. < Beg.Dst.Add
;		If (End.Src.Add - Beg.Dst.Add) > 0
;			signal OVERLAP
;		Else
;			signal NO-OVERLAP
;		EndIf
;	Else
;		If (End.Dst.Add - Beg.Src.Add) > 0
;			signal OVERLAP
;		Else
;			signal NO-OVERLAP
;		EndIf
;	EndIf
;=========================================================================

ER_Overlap_Check	proc				;check for overlap	;an000; dms;

	push	dx					;save regs		;an000; dms;
	call	ER_Save_Context 			;save context		;an000; dms;

	cmp	[si].Source_Memory_Type,ER_Conv_Memory	;conventional memory?	;an000; dms;
	je	ER_Overlap_Check_Source 		;yes - check overlap	;an000; dms;
							;no - see if dest is
							;  conv. memory

	cmp	[si].Dest_Memory_Type,ER_Conv_Memory	;conventional memory?	;an000; dms;
	jne	ER_Overlap_Jump_Good			;no - exit routine	;an000; dms;

ER_Overlap_Check_Dest:

	mov	di,offset cs:ER_Save_Context_Buffer	;get addressibility to	;an000; dms;
							;  the page frame save
							;buffer
	add	di,bp					;offset BP relative	;an000; dms;
	cli						;ints off		;an000; dms;
	cmp	Map_Count,2				;>= 2 page frames	;an000; dms;
	sti						;ints on		;an000; dms;
	jb	ER_Overlap_Check_Dest_1_Frame		;no - use 1st. frame	;an000; dms;
	add	di,Type Mappable_Phys_Page_Struct	;yes - adjust ptr to	;an000; dms;
							;  next frame for dest.
ER_Overlap_Check_Dest_1_Frame:

		;**** calc abs address of the bottom of EMS transfer area

	mov	ax,cs:[di].Phys_Page_Segment		;get seg value		;an000; dms;
	xor	dx,dx					;clear high word	;an000; dms;
	mov	bx,ER_10H				;para size		;an000; dms;
	mul	bx					;make abs address	;an000; dms;
	mov	cs:[bp].ER_Src_Abs_Beg_Low,ax		;save abs. address of	;an000; dms;
	mov	cs:[bp].ER_Src_Abs_Beg_High,dx		;  phys page beg.	;an000; dms;

		;**** calc abs address of the top of EMS transfer area

	add	ax,EMS_Page_Size_In_Bytes		;make abs address	;an000; dms;
	adc	dx,0					;			;an000; dms;
	mov	cs:[bp].ER_Src_Abs_End_Low,ax		;save abs. address	;an000; dms;
	mov	cs:[bp].ER_Src_Abs_End_High,dx		;  of phys page end	;an000; dms;

		;**** calc abs address of the bottom of CONV transfer area

	mov	ax,[si].Dest_Initial_Seg_Page		;get segment		;an000; dms;
	xor	dx,dx					;clear high word	;an000; dms;
	mov	bx,ER_10H				;para size		;an000; dms;
	mul	bx					;make abs address	;an000; dms;
	add	ax,[si].Dest_Initial_Offset		;get offset		;an000; dms;
	adc	dx,0					;pick up carry		;an000; dms;
	mov	cs:[bp].ER_Dst_Abs_Beg_Low,ax		;save initial seg start ;an000; dms;
	mov	cs:[bp].ER_Dst_Abs_Beg_High,dx		;save initial off start ;an000; dms;

		;**** calc abs address of the top of CONV transfer area

	add	ax,[si].Region_Length_Low_Word		;add in low word of	;an000; dms;
							;  trf size
	adc	dx,[si].Region_Length_High_Word 	;add in high word of	;an000; dms;
	mov	cs:[bp].ER_Dst_Abs_End_Low,ax		;save initial seg start ;an000; dms;
	mov	cs:[bp].ER_Dst_Abs_End_High,dx		;save initial off start ;an000; dms;

	call	ER_General_Overlap_Test 		;test for overlap	;an000; dms;

	jc	ER_Overlap_Error_Exit			;exit with error	;an000; dms;

ER_Overlap_Jump_Good:

	jmp	ER_Overlap_Good_Exit			;exit good		;an000; dms;

ER_Overlap_Check_Source:

	mov	di,offset cs:ER_Save_Context_Buffer	;get addressibility to	;an000; dms;
							;  the page frame save
							;buffer
	add	di,bp					;offset BP relative	;an000; dms;

		;**** calc abs address of the bottom of EMS transfer area

	mov	ax,cs:[di].Phys_Page_Segment		;get seg value		;an000; dms;
	xor	dx,dx					;clear high word	;an000; dms;
	mov	bx,ER_10H				;para size		;an000; dms;
	mul	bx					;make abs address	;an000; dms;
	mov	cs:[bp].ER_Src_Abs_Beg_Low,ax		;save abs. address of	;an000; dms;
	mov	cs:[bp].ER_Src_Abs_Beg_High,dx		;  phys page beg.	;an000; dms;

		;**** calc abs address of the top of EMS transfer area

	mov	ax,cs:[di].Phys_Page_Segment		;get seg value		;an000; dms;
	mov	dx,EMS_Page_Size_In_Bytes		;get end of phys page	;an000; dms;
	mov	bx,ER_10H				;para size		;an000; dms;
	mul	bx					;make abs address	;an000; dms;
	mov	cs:[bp].ER_Src_Abs_End_Low,ax		;save abs. address	;an000; dms;
	mov	cs:[bp].ER_Src_Abs_End_High,dx		;  of phys page end	;an000; dms;

		;**** calc abs address of the bottom of CONV transfer area

	mov	ax,[si].Source_Initial_Seg_Page 	;get segment		;an000; dms;
	xor	dx,dx					;clear high word	;an000; dms;
	mov	bx,ER_10H				;para size		;an000; dms;
	mul	bx					;make abs address	;an000; dms;
	add	ax,[si].Source_Initial_Offset		;get offset		;an000; dms;
	adc	dx,0					;pick up carry		;an000; dms;
	mov	cs:[bp].ER_Dst_Abs_Beg_Low,ax		;save initial seg start ;an000; dms;
	mov	cs:[bp].ER_Dst_Abs_Beg_High,dx		;save initial off start ;an000; dms;

		;**** calc abs address of the top of CONV transfer area

	add	ax,[si].Region_Length_Low_Word		;add in low word of	;an000; dms;
							;  trf size
	adc	dx,[si].Region_Length_High_Word 	;add in high word of	;an000; dms;
	mov	cs:[bp].ER_Dst_Abs_End_Low,ax		;save initial seg start ;an000; dms;
	mov	cs:[bp].ER_Dst_Abs_End_High,dx		;save initial off start ;an000; dms;

	call	ER_General_Overlap_Test 		;test for overlap	;an000; dms;

	jnc	ER_Overlap_Good_Exit			;exit good		;an000; dms;
	jmp	ER_Overlap_Error_Exit			;exit bad

ER_Overlap_Good_Exit:

	xor	ah,ah					;signal no error	;an000; dms;
	jmp	ER_Overlap_Exit 			;exit			;an000; dms;

ER_Overlap_Error_Exit:

	mov	ah,EMS_Code94				;signal error		;an000; dms;

ER_Overlap_Exit:

	call	ER_Restore_Context			;restore context	;an000; dms;

	pop	dx					;restore regs		;an000; dms;

	ret						;return to caller	;an000; dms;

ER_Overlap_Check	endp				;end proc		;an000; dms;


;=========================================================================
; ER_EMS_Overlap_Check	: This routine determines if the source and target
;			  EMS regions overlap when both the source and target
;			  reside in EMS.
;
;	Inputs	: DS:SI - Pointer to Move_Source_Dest_Struc data
;
;	Outputs : AH - Non-zero on error
;			Possible error codes: 92h
;
;	Algorithm :
;
;	If Beg.Src.Add. < Beg.Dst.Add
;		If (End.Src.Add - Beg.Dst.Add) > 0
;			signal OVERLAP
;		Else
;			signal NO-OVERLAP
;		EndIf
;	Else
;		If (End.Dst.Add - Beg.Src.Add) > 0
;			signal OVERLAP
;		Else
;			signal NO-OVERLAP
;		EndIf
;	EndIf
;=========================================================================

ER_EMS_Overlap_Check	proc				;check for overlap	;an000; dms;

	push	bx					;save regs		;an000; dms;
	push	dx					;			;an000; dms;

	cmp	[si].Source_Memory_Type,ER_EMS_Memory	;Source EMS?		;an000; dms;
	jne	ER_EMS_Overlap_Exit			;no - exit routine	;an000; dms;

	cmp	[si].Dest_Memory_Type,ER_EMS_Memory	;Dest. EMS?		;an000; dms;
	jne	ER_EMS_Overlap_Exit			;no - exit routine	;an000; dms;

	mov	bx,[si].Source_Handle			;get source handle	;an000; dms;
	cmp	bx,[si].Dest_Handle			;source = dest? 	;an000; dms;
	jne	ER_EMS_Overlap_Good_Exit		;no - exit routine	;an000; dms;

ER_EMS_Overlap_Calc_N_Ck:

		;**** calc absolute beginning address of source page

	mov	ax,[si].Source_Initial_Seg_Page 	;get start page 	;an000; dms;
	xor	dx,dx					;clear high word	;an000; dms;
	mov	bx,EMS_Page_Size_In_Bytes		;get page size		;an000; dms;
	mul	bx					;convert page to abs	;an000; dms;
							;  address
	add	ax,[si].Source_Initial_Offset		;add in offset value	;an000; dms;
	adc	dx,0					;pick up carry		;an000; dms;

	mov	cs:[bp].ER_Src_Abs_Beg_Low,ax		;save low word of add
	mov	cs:[bp].ER_Src_Abs_Beg_High,dx		;save high word of add	;an000; dms;

		;**** calc absolute ending address of source page

	add	ax,[si].Region_Length_Low_Word		;add in low word of	;an000; dms;
							;  length
	adc	dx,[si].Region_Length_High_Word 	;add in high word of	;an000; dms;
							;  length
	mov	cs:[bp].ER_Src_Abs_End_Low,ax		;save low word of end	;an000; dms;
	mov	cs:[bp].ER_Src_Abs_End_High,dx		;save high word of end	;an000; dms;

		;**** calc absolute beginning address of dest. page

	mov	ax,[si].Dest_Initial_Seg_Page		;get start page 	;an000; dms;
	xor	dx,dx					;clear high word	;an000; dms;
	mov	bx,EMS_Page_Size_In_Bytes		;get page size		;an000; dms;
	mul	bx					;convert page to abs	;an000; dms;
							;  address
	add	ax,[si].Dest_Initial_Offset		;add in offset value	;an000; dms;
	adc	dx,0					;pick up carry		;an000; dms;

	mov	cs:[bp].ER_Dst_Abs_Beg_Low,ax		;save low word of add
	mov	cs:[bp].ER_Dst_Abs_Beg_High,dx		;save high word of add	;an000; dms;

		;**** calc absolute ending address of dest. page

	add	ax,[si].Region_Length_Low_Word		;add in low word of	;an000; dms;
							;  length
	adc	dx,[si].Region_Length_High_Word 	;add in high word of	;an000; dms;
							;  length
	mov	cs:[bp].ER_Dst_Abs_End_Low,ax		;save low word of end	;an000; dms;
	mov	cs:[bp].ER_Dst_Abs_End_High,dx		;save high word of end	;an000; dms;

		;**** Actual test for overlap - corresponds to algorithm above

	call	ER_General_Overlap_Test 		;test for overlap	;an000; dms;
	jnc	ER_EMS_Overlap_Good_Exit		;no error		;an000; dms;

ER_EMS_Overlap_Error_Exit:

	mov	ah,EMS_Code92				;signal error		;an000; dms;
	jmp	ER_EMS_Overlap_Exit			;exit			;an000; dms;

ER_EMS_Overlap_Good_Exit:

	xor	ah,ah					;no error		;an000; dms;

ER_EMS_Overlap_Exit:

	pop	dx					;restore regs		;an000; dms;
	pop	bx					;			;an000; dms;

	ret						;return to caller	;an000; dms;

ER_EMS_Overlap_Check	endp				;end proc		;an000; dms;


;=========================================================================
; ER_General_Overlap_Test:This routine determines if the source and target
;			  EMS regions overlap when both the source and target
;			  reside in EMS.
;
;	Inputs	: ER_Src_Abs_Beg_Low  -  Low word of beginning trf area of source
;		  ER_Src_Abs_Beg_High -  High word of beginning trf area of source
;
;		  ER_Src_Abs_End_Low  -  Low word of ending trf area of source
;		  ER_Src_Abs_End_High -  High word of ending trf area of source
;
;		: ER_Dst_Abs_Beg_Low  -  Low word of beginning trf area of dest.
;		  ER_Dst_Abs_Beg_High -  High word of beginning trf area of dest.
;
;		  ER_Dst_Abs_End_Low  -  Low word of ending trf area of dest.
;		  ER_Dst_Abs_End_High -  High word of ending trf area of dest.
;
;	Outputs : NC - no overlap
;		  CY - overlap
;
;	Algorithm :
;
;	If Beg.Src.Add. < Beg.Dst.Add
;		If (End.Src.Add - Beg.Dst.Add) > 0
;			signal OVERLAP
;		Else
;			signal NO-OVERLAP
;		EndIf
;	Else
;		If (End.Dst.Add - Beg.Src.Add) > 0
;			signal OVERLAP
;		Else
;			signal NO-OVERLAP
;		EndIf
;	EndIf
;=========================================================================

ER_General_Overlap_Test 	proc			;			;an000; dms;

	push	ax					;save regs		;an000; dms;
	push	bx					;			;an000; dms;
	push	cx					;			;an000; dms;
	push	dx					;			;an000; dms;

	mov	ax,cs:[bp].ER_Src_Abs_Beg_High		;get source beg. add.	;an000; dms;
	mov	bx,cs:[bp].ER_Src_Abs_Beg_Low		;			;an000; dms;
	mov	cx,cs:[bp].ER_Dst_Abs_Beg_High		;get dest. beg. add.	;an000; dms;
	mov	dx,cs:[bp].ER_Dst_Abs_Beg_Low		;			;an000; dms;
	call	ER_Dword_Compare			;
;	$if	c					;< dest. beg. add.?	;an000; dms;
	JNC ER_IF1
	     mov  ax,cs:[bp].ER_Src_Abs_End_Low 	;get end address	;an000; dms;
	     mov  dx,cs:[bp].ER_Src_Abs_End_High	;			;an000; dms;
	     sub  ax,cs:[bp].ER_Dst_Abs_Beg_Low 	;End.Src.Add-Beg.Dst.Add;an000; dms;
	     sbb  dx,cs:[bp].ER_Dst_Abs_Beg_High	;			;an000; dms;
;	     $if  ns					;yes - overlap		;an000; dms;
	     JS ER_IF2
		  stc					;signal error		;an000; dms;
		  mov cs:[bp].ER_Direction_Flag,ER_Down ;signal reverse move	;an000; dms;
;	     $else					;no - not sure yet	;an000; dms;
	     JMP SHORT ER_EN2
ER_IF2:
		  clc					;signal no overlap	;an000; dms;
		  mov cs:[bp].ER_Direction_Flag,ER_Up	;forward move		;an000; dms;
;	     $endif					;			;an000; dms;
ER_EN2:
;	$else						;not sure if src < dst	;an000; dms;
	JMP SHORT ER_EN1
ER_IF1:
	     mov  ax,cs:[bp].ER_Dst_Abs_End_Low 	;get end address	;an000; dms;
	     mov  dx,cs:[bp].ER_Dst_Abs_End_High	;			;an000; dms;
	     sub  ax,cs:[bp].ER_Src_Abs_Beg_Low 	;End.Dst.Add-Beg.Src.Add;an000; dms;
	     sbb  dx,cs:[bp].ER_Src_Abs_Beg_High	;			;an000; dms;
;	     $if  ns					;yes - overlap		;an000; dms;
	     JS ER_IF6
		  stc					;signal error		;an000; dms;
		  mov cs:[bp].ER_Direction_Flag,ER_Up	;forward move		;an000; dms;
;	     $else					;no - not sure yet	;an000; dms;
	     JMP SHORT ER_EN6
ER_IF6:
		  clc					;signal no overlap	;an000; dms;
		  mov cs:[bp].ER_Direction_Flag,ER_Up	;forward move		;an000; dms;
;	     $endif					;			;an000; dms;
ER_EN6:
;	$endif						;			;an000; dms;
ER_EN1:

	pop	dx					;restore regs		;an000; dms;
	pop	cx					;			;an000; dms;
	pop	bx					;			;an000; dms;
	pop	ax					;			;an000; dms;

	ret						;return to caller	;an000; dms;

ER_General_Overlap_Test 	endp			;end proc		;an000; dms;


;=========================================================================
; ER_Dword_Compare	: This routine determines whether or not a dword
;			  value is greater than another dword value.
;
;	Inputs	: AX - Source high word
;		  BX - Source low word
;		  CX - Destination high word
;		  DX - Destination low word
;
;	Outputs : NC - source >= destination
;		  CY - source < destination
;=========================================================================

ER_Dword_Compare	proc				;			;an000; dms;

	cmp	ax,cx					;src high < dest high?	;an000; dms;
;	$if	b					;yes			;an000; dms;
	JNB ER_IF10
		stc					;signal less than	;an000; dms;
;	$else						;no			;an000; dms;
	JMP SHORT ER_EN10
ER_IF10:
		cmp	ax,cx				;src high > dest high?	;an000; dms;
;		$if	a				;yes			;an000; dms;
		JNA ER_IF12
			clc				;signal greater than	;an000; dms;
;		$else					;no			;an000; dms;
		JMP SHORT ER_EN12
ER_IF12:
			cmp	bx,dx			;src low < dest low?	;an000; dms;
;			$if	b			;yes			;an000; dms;
			JNB ER_IF14
				stc			;signal less than	;an000; dms;
;			$else				;no			;an000; dms;
			JMP SHORT ER_EN14
ER_IF14:
				cmp	bx,dx		;src low > dest low?	;an000; dms;
;				$if	a		;yes			;an000; dms;
				JNA ER_IF16
					clc		;signal greater than	;an000; dms;
;				$else			;no			;an000; dms;
				JMP SHORT ER_EN16
ER_IF16:
					clc		;			;an000; dms;
;				$endif			;			;an000; dms;
ER_EN16:
;			$endif				;			;an000; dms;
ER_EN14:
;		$endif					;			;an000; dms;
ER_EN12:
;	$endif						;			;an000; dms;
ER_EN10:

	ret						;			;an000; dms;

ER_Dword_Compare	endp				;			;an000; dms;



;=========================================================================
; ER_Segment_Adjust	: This routine adjusts the segment:offset to a value
;			  with an offset less than 16.
;
;	Inputs	: AX:DX - Segment:Offset to be adjusted
;
;	Outputs : AX:DX - New Segment:Offset value
;=========================================================================

ER_Segment_Adjust	proc				;adjust segment value	;an000; dms;

	push	bx					;save bx		;an000; dms;
	push	cx					;			;an000; dms;

	mov	bx,ax					;save segment value	;an000; dms;
	mov	ax,dx					;get offset		;an000; dms;
	xor	dx,dx					;clear high word	;an000; dms;
	mov	cx,ER_10h				;divide by 10h		;an000; dms;
	div	cx					;get seg adjustment	;an000; dms;
							;  factor
	add	ax,bx					;adjust segment up	;an000; dms;
							;  dx contains new off. ;an000; dms;
	pop	cx					;restore regs		;an000; dms;
	pop	bx					;restore bx		;an000; dms;

	ret						;return to caller	;an000; dms;

ER_Segment_Adjust	endp				;end proc		;an000; dms;


;=========================================================================
; ER_Log_Page_Test	: This routine checks the offset specified for
;			  the logical page to determine if the offset is
;			  within the valid ranges for the page size.
;
;	Inputs	: DS:SI - Pointer to Move_Source_Dest_Struc data
;
;	Outputs : AH - Non-zero on error
;			Possible error codes: 95h
;=========================================================================

ER_Log_Page_Test	proc				;			;an000; dms;

	mov	ax,EMS_Page_Size_In_Bytes		;get page size		;an000; dms;

	cmp	[si].Source_Memory_Type,ER_EMS_Memory	;EMS memory specified?	;an000; dms;
	jne	ER_Log_Dest_Test			;no - check dest.	;an000; dms;

	cmp	ax,[si].Source_Initial_Offset		;> EMS page size	;an000; dms;
	jae	ER_Log_Good_Exit			;good exit		;an000; dms;
	jmp	ER_Log_Error_Exit			;error - bad exit	;an000; dms;

ER_Log_Dest_Test:

	cmp	[si].Dest_Memory_Type,ER_EMS_Memory	;EMS memory specified?	;an000; dms;
	jne	ER_Log_Good_Exit			;good exit		;an000; dms;

	cmp	ax,[si].Dest_Initial_Offset		;> EMS page size	;an000; dms;
	jae	ER_Log_Good_Exit			;good exit		;an000; dms;

ER_Log_Error_Exit:

	mov	ah,EMS_Code95				;signal error		;an000; dms;
	jmp	ER_Log_Exit				;exit routine		;an000; dms;

ER_Log_Good_Exit:

	xor	ah,ah					;signal no error	;an000; dms;

ER_Log_Exit:

	ret						;return to caller	;an000; dms;

ER_Log_Page_Test	endp				;end proc		;an000; dms;

;=========================================================================
; ER_Save_Context	: This routine saves the context for page frames
;			  needed for the move/exchange.
;
;	Inputs	: none
;
;	Outputs : ER_Save_Context_Buffer - save context for the needed page frames
;=========================================================================

ER_Save_Context 	proc				;save contexts		;an000; dms;

	push	ax					;save regs		;an000; dms;
	push	cx					;			;an000; dms;
	push	di					;			;an000; dms;
	push	si					;			;an000; dms;
	push	ds					;			;an000; dms;
	push	es					;			;an000; dms;

	mov	ax,cs					;make ds/es = cs	;an000; dms;
	mov	ds,ax					;			;an000; dms;
	mov	es,ax					;			;an000; dms;

	mov	si,offset cs:Map_Table			;ptr to page frame table;an000; dms;
	mov	di,offset cs:ER_Save_Context_Buffer	;get dest. offset
	add	di,bp					;offset BP relative	;an000; dms;

	mov	cx,2					;default frame save	;an000; dms;
	cli						;ints off		;an000; dms;
	cmp	Map_Count,2				;2 page frames? 	;an000; dms;
	jae	ER_Save_Context_Loop			;< = 2 - continue	;an000; dms;
	mov	cx,Map_Count				;max frame count to save;an000; dms;

ER_Save_Context_Loop:

	sti						;ints on		;an000; dms;
	push	cx					;save cx		;an000; dms;
	mov	cx,Type Mappable_Phys_Page_Struct	;get byte count to trf	;an000; dms;
	cli						;ints off		;an000; dms;
	rep	movsb					;perform save		;an000; dms;
	sti						;ints on		;an000; dms;
	pop	cx					;restore cx		;an000; dms;
	loop	ER_Save_Context_Loop			;continue		;an000; dms;

ER_Save_Exit:

	pop	es					;restore regs		;an000; dms;
	pop	ds					;			;an000; dms;
	pop	si					;			;an000; dms;
	pop	di					;			;an000; dms;
	pop	cx					;			;an000; dms;
	pop	ax					;			;an000; dms;

	ret						;return to caller	;an000; dms;

ER_Save_Context 	endp				;end proc		;an000; dms;


;=========================================================================
; ER_Restore_Context	: This routine restores the context for page frames
;			  saved.  These pages were used for the
;			  move/exchange requested.
;
;	Inputs	: ER_Save_Context_Buffer - contains saved context
;
;	Outputs : restored context for the saved page frames
;=========================================================================

ER_Restore_Context	proc				;restore contexts	;an000; dms;

	push	ax					;save regs		;an000; dms;
	push	cx					;			;an000; dms;
	push	di					;			;an000; dms;
	push	si					;			;an000; dms;
	push	ds					;			;an000; dms;
	push	es					;			;an000; dms;

	mov	ax,cs					;make ds/es = cs	;an000; dms;
	mov	ds,ax					;			;an000; dms;
	mov	es,ax					;			;an000; dms;

	mov	di,offset cs:Map_Table			;ptr to page frame table;an000; dms;
	mov	si,offset cs:ER_Save_Context_Buffer	;get dest. offset
	add	si,bp					;offset BP relative	;an000; dms;

	mov	cx,2					;default frame restore	;an000; dms;
	cli						;ints off		;an000; dms;
	cmp	Map_Count,2				;2 page frames? 	;an000; dms;
	jae	ER_Restore_Context_Loop 		;< = 2 - continue	;an000; dms;
	mov	cx,Map_Count				;max frame count to rest;an000; dms;

ER_Restore_Context_Loop:

	sti						;ints on		;an000; dms;
	mov	al,byte ptr ds:[si].Phys_Page_Number	;get physical page num. ;an000; dms;
	mov	bx,word ptr ds:[si].PPM_Log_Page	;get logical page num.	;an000; dms;
	mov	dx,word ptr ds:[si].PPM_Handle		;get handle number	;an000; dms;
	call	Map_L_To_P				;map in orig. page	;an000; dms;

	push	cx					;save cx		;an000; dms;
	mov	cx,Type Mappable_Phys_Page_Struct	;get byte count to trf	;an000; dms;
	cli						;ints off		;an000; dms;
	rep	movsb					;perform save		;an000; dms;
	sti						;ints on		;an000; dms;
	pop	cx					;restore cx		;an000; dms;
	loop	ER_Restore_Context_Loop 		;continue		;an000; dms;

ER_Restore_Exit:

	pop	es					;restore regs		;an000; dms;
	pop	ds					;			;an000; dms;
	pop	si					;			;an000; dms;
	pop	di					;			;an000; dms;
	pop	cx					;			;an000; dms;
	pop	ax					;			;an000; dms;

	ret						;return to caller	;an000; dms;

ER_Restore_Context	endp				;end proc		;an000; dms;



;=========================================================================
; ER_Det_Src_Dest_Seg	: This routine determines the applicable segment,
;			  offset, and page to be used for the move/exchange.
;			  This routine sets the pages/addresses to the end
;			  of the area to be moved/exchanged, if the move
;			  is to be a reverse move.  If the move is to be
;			  a forward move, the pages/addresses are set to
;			  the beginning of the area to be moved/exchanged.
;			  In this way an overlapping move can be
;			  performed without overlaying data it is to move.
;
;	Inputs	: DS:SI - Pointer to Move_Source_Dest_Struc data
;
;	Outputs : ER_Source_Seg 	- Segment value of source
;		  ER_Dest_Seg		- Segment value of destination
;
;		  ER_Source_Off 	- Offset value of source
;		  ER_Dest_Off		- Offset value of destination
;
;		  ER_Source_Page	- Source EMS page
;		  ER_Dest_Page		- Destination EMS page
;
;		  ER_Source_Handle	- Source handle
;		  ER_Dest_Handle	- Destination handle
;
;		  ER_Source_Phys_Page	- Physical page number
;		  ER_Dest_Phys_Page	- Physical page number
;=========================================================================

ER_Det_Src_Dest_Seg	proc				;			;an000; dms;

	push	ax					;save regs		;an000; dms;
	push	bx					;			;an000; dms;
	push	cx					;			;an000; dms;
	push	dx					;			;an000; dms;
	push	di					;			;an000; dms;
	push	ds					;			;an000; dms;
	push	es					;			;an000; dms;


	cmp	[si].Source_Memory_Type,ER_EMS_Memory	;EMS?			;an000; dms;
	jne	ER_Det_Source_Conv			;no - conventional mem. ;an000; dms;

	mov	di,offset cs:ER_Save_Context_Buffer	;get addressibility to	;an000; dms;
							;  the page frame save
							;buffer
	add	di,bp					;offset BP relative
	mov	ax,cs:[di].Phys_Page_Segment		;get seg value		;an000; dms;
	mov	cs:[bp].ER_Source_Seg,ax		;save it in variable	;an000; dms;

	mov	ax,[si].Source_Handle			;get source handle	;an000; dms;
	mov	cs:[bp].ER_Source_Handle,ax		;save handle		;an000; dms;

	cmp	cs:[bp].ER_Direction_Flag,ER_Down	;reverse move?		;an000; dms;
;	$if	e					;yes			;an000; dms;
	JNE ER_IF22
		mov	ax,[si].Region_Length_Low_Word	;get low word of move	;an000; dms;
		mov	dx,[si].Region_Length_High_Word ;get high word		;an000; dms;
		add	ax,[si].Source_Initial_Offset	;pick up offset value	;an000; dms;
		adc	dx,0				;pick up carry		;an000; dms;
		mov	bx,4000h			;get page size		;an000; dms;
		div	bx				;get end logical page	;an000; dms;
		add	ax,[si].Source_Initial_Seg_Page ;adjust it for 1st.	;an000; dms;
		mov	cs:[bp].ER_Source_Page,ax	;save log. page 	;an000; dms;
		dec	dx				;adjust to end point	;an000; dms;
		mov	cs:[bp].ER_Source_Off,dx	;save offset in last pg ;an000; dms;

;	$else						;forward move		;an000; dms;
	JMP SHORT ER_EN22
ER_IF22:
		mov	ax,[si].Source_Initial_Seg_Page ;get page		;an000; dms;
		mov	dx,[si].Source_Initial_Offset	;get offset		;an000; dms;
		mov	cs:[bp].ER_Source_Page,ax	;save page		;an000; dms;
		mov	cs:[bp].ER_Source_Off,dx	;save offset		;an000; dms;
;	$endif						;			;an000; dms;
ER_EN22:
	mov	ax,cs:[di].Phys_Page_Number		;get phys. page 	;an000; dms;
	mov	cs:[bp].ER_Source_Phys_Page,ax		;save it		;an000; dms;
	jmp	ER_Det_Dest_Check			;jump to dest check	;an000; dms;

ER_Det_Source_Conv:

	cmp	cs:[bp].ER_Direction_Flag,ER_Down	;reverse move?		;an000; dms;
;	$if	e					;yes			;an000; dms;
	JNE ER_IF25
		mov	ax,[si].Region_Length_Low_Word	;get low word of move	;an000; dms;
		mov	dx,[si].Region_Length_High_Word ;get high word		;an000; dms;
		mov	bx,ER_10h			;get bytes/para 	;an000; dms;
		div	bx				;get para count 	;an000; dms;
							;  AX = para's
							;  DX = offset
		mov	bx,ax				;save across adjust call;an000; dms;
		mov	cx,dx				;			;an000; dms;
		mov	ax,[si].Source_Initial_Seg_Page ;get seg value		;an000; dms;
		mov	dx,[si].Source_Initial_Offset	;get off value		;an000; dms;
		dec	dx				;adjust to end byte
		call	ER_Segment_Adjust		;adjust it downward	;an000; dms;
		add	ax,bx				;new segment value	;an000; dms;
		add	dx,cx				;new offset value	;an000; dms;

		mov	cs:[bp].ER_Source_Seg,ax	;save it in variable	;an000; dms;
		mov	cs:[bp].ER_Source_Off,dx	;save offset in var	;an000; dms;
;	$else						;forward move		;an000; dms;
	JMP SHORT ER_EN25
ER_IF25:
		mov	ax,[si].Source_Initial_Seg_Page ;get seg value		;an000; dms;
		mov	dx,[si].Source_Initial_Offset	;get off value		;an000; dms;
		mov	cs:[bp].ER_Source_Seg,ax	;save it in variable	;an000; dms;
		mov	cs:[bp].ER_Source_Off,dx	;save offset in var	;an000; dms;
;	$endif						;			;an000; dms;
ER_EN25:


ER_Det_Dest_Check:

	cmp	[si].Dest_Memory_Type,ER_EMS_Memory	;Dest. EMS?		;an000; dms;
	jne	ER_Det_Dest_Conv			;no - conventional mem. ;an000; dms;

	mov	di,offset cs:ER_Save_Context_Buffer	;save frame buffer	;an000; dms;
	add	di,bp					;offset BP relative	;an000; dms;
	cli						;ints off		;an000; dms;
	cmp	Map_Count,1				;> 1 page frame?	;an000; dms;
	sti						;ints on		;an000; dms;
	jb	ER_Det_Dest_Check1			;don't adjust pointer   ;an000; dms;
	add	di,Type Mappable_Phys_Page_Struct	;next entry in save buf ;an000; dms;

ER_Det_Dest_Check1:

	mov	ax,cs:[di].Phys_Page_Segment		;get seg value		;an000; dms;
	mov	cs:[bp].ER_Dest_Seg,ax			;save it in variable	;an000; dms;

	mov	ax,[si].Dest_Handle			;get dest. handle	;an000; dms;
	mov	cs:[bp].ER_Dest_Handle,ax		;save handle		;an000; dms;

	cmp	cs:[bp].ER_Direction_Flag,ER_Down	;reverse move?		;an000; dms;
;	$if	e					;yes			;an000; dms;
	JNE ER_IF28
		mov	ax,[si].Region_Length_Low_Word	;get low word of move	;an000; dms;
		mov	dx,[si].Region_Length_High_Word ;get high word		;an000; dms;
		add	ax,[si].Dest_Initial_Offset	;pick up offset value	;an000; dms;
		adc	dx,0				;pick up carry		;an000; dms;

		mov	bx,4000h			;get page size		;an000; dms;
		div	bx				;get end logical page	;an000; dms;
		add	ax,[si].Dest_Initial_Seg_Page	;adjust it for 1st.	;an000; dms;
		mov	cs:[bp].ER_Dest_Page,ax 	;save log. page 	;an000; dms;
		dec	dx				;adjust to end point	;an000; dms;
		mov	cs:[bp].ER_Dest_Off,dx		;save off. in last page ;an000; dms;

;	$else						;forward move		;an000; dms;
	JMP SHORT ER_EN28
ER_IF28:
		mov	ax,[si].Dest_Initial_Seg_Page		;get page	;an000; dms;
		mov	dx,[si].Dest_Initial_Offset		;get offset	;an000; dms;
		mov	cs:[bp].ER_Dest_Page,ax 		;save log. page 	;an000; dms;
		mov	cs:[bp].ER_Dest_Off,dx			;save off. in last page ;an000; dms;
;	$endif							;		;an000; dms;
ER_EN28:
	mov	ax,cs:[di].Phys_Page_Number			;get phys page number	;an000; dms;
	mov	cs:[bp].ER_Dest_Phys_Page,ax			;save it		;an000; dms;
	jmp	ER_Det_Exit				;exit routine		;an000; dms;

ER_Det_Dest_Conv:

	cmp	cs:[bp].ER_Direction_Flag,ER_Down	;reverse move?		;an000; dms;
;	$if	e					;yes			;an000; dms;
	JNE ER_IF31
		mov	ax,[si].Region_Length_Low_Word	;get low word of move	;an000; dms;
		mov	dx,[si].Region_Length_High_Word ;get high word		;an000; dms;
		mov	bx,ER_10H			;get bytes/para 	;an000; dms;
		div	bx				;get para count 	;an000; dms;
							;  AX = para's
							;  DX = offset
		mov	bx,ax				;save across adjust call;an000; dms;
		mov	cx,dx				;			;an000; dms;
		mov	ax,[si].Dest_Initial_Seg_Page	;get seg value		;an000; dms;
		mov	dx,[si].Dest_Initial_Offset	;get off value		;an000; dms;
		dec	dx				;adjust to end byte	;an000; dms;
		call	ER_Segment_Adjust		;adjust it downward	;an000; dms;
		add	ax,bx				;new segment value	;an000; dms;
		add	dx,cx				;new offset value	;an000; dms;

		mov	cs:[bp].ER_Dest_Seg,ax		;save it in variable	;an000; dms;
		mov	cs:[bp].ER_Dest_Off,dx		;save offset in var	;an000; dms;
;	$else						;forward move		;an000; dms;
	JMP SHORT ER_EN31
ER_IF31:
		mov	ax,[si].Dest_Initial_Seg_Page	;get seg value		;an000; dms;
		mov	dx,[si].Dest_Initial_Offset	;get off value		;an000; dms;
		mov	cs:[bp].ER_Dest_Seg,ax		;save it in variable	;an000; dms;
		mov	cs:[bp].ER_Dest_Off,dx		;save offset in var	;an000; dms;
;	$endif						;			;an000; dms;
ER_EN31:


ER_Det_Exit:

	pop	es					;restore regs		;an000; dms;
	pop	ds					;			;an000; dms;
	pop	di					;			;an000; dms;
	pop	dx					;			;an000; dms;
	pop	cx					;			;an000; dms;
	pop	bx					;			;an000; dms;
	pop	ax					;			;an000; dms;

	ret						;return to caller	;an000; dms;

ER_Det_Src_Dest_Seg	endp				;end proc		;an000; dms;


;=========================================================================
; ER_Det_Move_Count	: This initializes the count variables for the
;			  loop iteration counter of the move/exchange.
;
;	Inputs	: DS:SI - Pointer to Move_Source_Dest_Struc data
;
;	Outputs : ER_Move_Count_Low  - low word value of move count
;		  ER_Move_Count_High - high word value of move count
;=========================================================================


ER_Det_Move_Count	proc				;			;an000; dms;

	push	ax					;save regs		;an000; dms;
	push	dx					;			;an000; dms;

	mov	ax,[si].Region_Length_Low_Word		;get low word count	;an000; dms;
	mov	dx,[si].Region_Length_High_Word 	;get high word count	;an000; dms;
	mov	cs:[bp].ER_Move_Count_Low,ax		;save low word		;an000; dms;
	mov	cs:[bp].ER_Move_Count_High,dx		;save high word 	;an000; dms;

	pop	dx					;restore regs		;an000; dms;
	pop	ax					;			;an000; dms;

	ret						;return to caller	;an000; dms;

ER_Det_Move_Count	endp				;end proc		;an000; dms;

;=========================================================================
; ER_Move_Source_To_Buffer	: This routine moves the source data to
;				  the buffer before it is transferred to
;				  its final destination.
;
;	Inputs	: BP - carries type of memory for source/dest
;		  Bit 0 - Destination (EMS if set)
;		  Bit 1 - Source (EMS if set)
;
;	Outputs : ER_Move_Xchg_Buffer1 - Source data
;=========================================================================

ER_Move_Source_To_Buffer	proc			;			;an000; dms;

	push	ax					;save regs		;an000; dms;
	push	bx					;			;an000; dms;
	push	dx					;			;an000; dms;
	push	di					;			;an000; dms;
	push	es					;			;an000; dms;

	test	cs:[bp].ER_Mem_Type,ER_Source_EMS_Memory;Source EMS?		;an000; dms;
	jz	ER_Move_Source_Conv_Mem 		;no - adjust seg:off	;an000; dms;
	jmp	ER_Move_Source_EMS_Mem			;yes- continue move	;an000; dms;

ER_Move_Source_Conv_Mem:

	cmp	cs:[bp].ER_Direction_Flag,ER_Down	;reverse move?		;an000; dms;
;	$if	e					;yes			;an000; dms;
	JNE ER_IF34
		mov	ax,ds				;adjust segment:off	;an000; dms;
		dec	ax				;segment - 1 para	;an000; dms;
		mov	ds,ax				;			;an000; dms;
		add	si,ER_10H			;adjust offset for 1	;an000; dms;
;	$else						;forward move		;an000; dms;
	JMP SHORT ER_EN34
ER_IF34:
		mov	ax,ds				;get segment value	;an000; dms;
		mov	dx,si				;get offset value	;an000; dms;
		call	ER_Segment_Adjust		;adjust the seg:off	;an000; dms;
		mov	ds,ax				;restore ds		;an000; dms;
		mov	si,dx				;restore offset 	;an000; dms;
;	$endif						;			;an000; dms;
ER_EN34:
	jmp	ER_Move_Source_Count			;determine count	;an000; dms;

ER_Move_Source_EMS_Mem:


	cmp	cs:[bp].ER_Direction_Flag,ER_Down	;reverse move?		;an000; dms;
;	$if	e					;yes			;an000; dms;
	JNE ER_IF37
		cmp	si,0ffffh			;beginning of log page	;an000; dms;
;		$if	e				;yes			;an000; dms;
		JNE ER_IF38
			dec	cs:[bp].ER_Source_Page	;adjust page ptr	;an000; dms;
			mov	si,EMS_Page_Size_In_Bytes;get page size 	;an000; dms;
;		$endif					;			;an000; dms;
ER_IF38:
;	$else						;forward move		;an000; dms;
	JMP SHORT ER_EN37
ER_IF37:
		cmp	si,4000h			;wrap beyond page	;an000; dms;
;		$if	e				;yes			;an000; dms;
		JNE ER_IF41
			inc	cs:[bp].ER_Source_Page	;adjust page ptr	;an000; dms;
			xor	si,si			;clear si		;an000; dms;
;		$endif					;			;an000; dms;
ER_IF41:
;	$endif						;			;an000; dms;
ER_EN37:
	mov	bx,cs:[bp].ER_Source_Page		;pass page to map	;an000; dms;
	call	ER_Map_Next_Src_Page			;no  - map in current pg;an000; dms;

ER_Move_Source_Count:

	mov	cx,ER_10H				;default count		;an000; dms;
	cmp	cs:[bp].ER_Move_Count_High,0		;high word set		;an000; dms;
	jne	ER_Move_Source_High_Set 		;yes - use default	;an000; dms;
	cmp	cs:[bp].ER_Move_Count_Low,cx		;>= 10h bytes		;an000; dms;
	jae	ER_Move_Source_High_Set 		;yes - use default	;an000; dms;
	mov	cx,cs:[bp].ER_Move_Count_Low		;no - use last few bytes;an000; dms;

ER_Move_Source_High_Set:

	cmp	cs:[bp].ER_Direction_Flag,ER_Down	;reverse move?		;an000; dms;
;	$if	e					;yes			;an000; dms;
	JNE ER_IF44
		cmp	si,di				;source >= dest?	;an000; dms;
;		$if	b				;no			;an000; dms;
		JNB ER_IF45
			cmp	si,ER_10H		;source >= 10h? 	;an000; dms;
;			$if	b			;no			;an000; dms;
			JNB ER_IF46
				mov	cx,si		;get move count 	;an000; dms;
				inc	cx		;always 1 byte off	;an000; dms;
;			$endif				;			;an000; dms;
ER_IF46:
;		$else					;source >= dest 	;an000; dms;
		JMP SHORT ER_EN45
ER_IF45:
			cmp	di,ER_10H		;dest >= 10h?		;an000; dms;
;			$if	b			;no			;an000; dms;
			JNB ER_IF49
				mov	cx,di		;get move count 	;an000; dms;
				inc	cx		;always 1 byte off	;an000; dms;
;			$endif				;			;an000; dms;
ER_IF49:
;		$endif					;			;an000; dms;
ER_EN45:
;	$else						;forward move		;an000; dms;
	JMP SHORT ER_EN44
ER_IF44:
		cmp	si,di				;source >= dest?	;an000; dms;
;		$if	a				;yes			;an000; dms;
		JNA ER_IF53
			mov	ax,4000h		;get end of page	;an000; dms;
			sub	ax,si			;get bytes remaining	;an000; dms;
			cmp	ax,ER_10H		;source >= 10h		;an000; dms;
;			$if	b			;no			;an000; dms;
			JNB ER_IF54
				mov	cx,ax		;get remaining count	;an000; dms;
;			$endif				;			;an000; dms;
ER_IF54:
;		$else					;source >= dest 	;an000; dms;
		JMP SHORT ER_EN53
ER_IF53:
			mov	ax,4000h		;get end of page	;an000; dms;
			sub	ax,di			;get bytes remaining	;an000; dms;
			cmp	ax,ER_10H		;dest >= 10h		;an000; dms;
;			$if	b			;no			;an000; dms;
			JNB ER_IF57
				mov	cx,ax		;get remaining count	;an000; dms;
;			$endif				;			;an000; dms;
ER_IF57:
;		$endif					;			;an000; dms;
ER_EN53:
;	$endif						;			;an000; dms;
ER_EN44:

	jmp	ER_Move_Source_Default_Count		;continue routine	;an000; dms;

ER_Move_Source_Default_Count:

	mov	cs:[bp].ER_Current_Move_Count,cx	;save current move cnt	;an000; dms;

	sub	cs:[bp].ER_Move_Count_Low,cx		;get new count		;an000; dms;
	sbb	cs:[bp].ER_Move_Count_High,0		;pick up borrow 	;an000; dms;

	mov	ax,cs					;get seg for buffer	;an000; dms;
	mov	es,ax					;put into es		;an000; dms;
	mov	di,offset cs:ER_Move_Xchg_Buffer1	;offset of buffer	;an000; dms;
	add	di,bp					;offset BP relative	;an000; dms;

	cmp	cs:[bp].ER_Direction_Flag,ER_Down	;reverse move?		;an000; dms;
;	$if	e					;yes			;an000; dms;
	JNE ER_IF61
		add	di,ER_10H			;end of buffer	+ 1	;an000; dms;
		dec	di				;end of buffer		;an000; dms;
;	$endif						;			;an000; dms;
ER_IF61:


	cmp	cs:[bp].ER_Direction_Flag,ER_Down	;reverse move?		;an000; dms;
;	$if	e					;yes			;an000; dms;
	JNE ER_IF63
		std					;reverse move		;an000; dms;
;	$else						;forward move		;an000; dms;
	JMP SHORT ER_EN63
ER_IF63:
		cld					;			;an000; dms;
;	$endif						;			;an000; dms;
ER_EN63:
	cli						;ints off		;an000; dms;
	rep	movsb					;move the data		;an000; dms;
	sti						;ints on		;an000; dms;

ER_Move_Source_Exit:

	pop	es					;restore regs		;an000; dms;
	pop	di					;			;an000; dms;
	pop	dx					;			;an000; dms;
	pop	bx					;			;an000; dms;
	pop	ax					;			;an000; dms;

	ret						;return to caller	;an000; dms;

ER_Move_Source_To_Buffer	endp			;end proc		;an000; dms;


;=========================================================================
; ER_Move_Buffer_To_Dest	: This routine moves the data in the buffer
;				  to the destination specified by the user.
;
;	Inputs	: BP - carries type of memory for source/dest
;		  Bit 0 - Destination (EMS if set)
;		  Bit 1 - Source (EMS if set)
;		  ER_Move_Xchg_Buffer1 - Source data
;
;	Outputs : Adjusted segment:offset or page/offset
;=========================================================================

ER_Move_Buffer_To_Dest		proc			;			;an000; dms;

	push	ax					;save regs		;an000; dms;
	push	bx					;			;an000; dms;
	push	dx					;			;an000; dms;
	push	si					;			;an000; dms;
	push	ds					;			;an000; dms;

	test	cs:[bp].ER_Mem_Type,ER_Dest_EMS_Memory	;Source EMS?		;an000; dms;
	jz	ER_Move_Buffer_Conv_Mem 		;no - adjust seg:off	;an000; dms;
	jmp	ER_Move_Buffer_EMS_Mem			;yes- continue move	;an000; dms;

ER_Move_Buffer_Conv_Mem:

	cmp	cs:[bp].ER_Direction_Flag,ER_Down	;reverse move?		;an000; dms;
;	$if	e					;yes			;an000; dms;
	JNE ER_IF66
		mov	ax,es				;adjust segment:off	;an000; dms;
		dec	ax				;segment - 1 para	;an000; dms;
		mov	es,ax				;			;an000; dms;
		add	di,ER_10H			;adjust offset for 1	;an000; dms;
;	$else						;forward move?		;an000; dms;
	JMP SHORT ER_EN66
ER_IF66:
		mov	ax,es				;adjust seg:off 	;an000; dms;
		mov	dx,di				;			;an000; dms;
		call	ER_Segment_Adjust		;			;an000; dms;
		mov	es,ax				;new seg:off		;an000; dms;
		mov	di,dx				;			;an000; dms;
;	$endif						;			;an000; dms;
ER_EN66:
							;  para
	jmp	ER_Move_Buffer_Count			;determine count	;an000; dms;

ER_Move_Buffer_EMS_Mem:

	cmp	cs:[bp].ER_Direction_Flag,ER_Down	;reverse move?		;an000; dms;
;	$if	e					;yes			;an000; dms;
	JNE ER_IF69
		cmp	di,0ffffh			;beginning of log page	;an000; dms;
;		$if	e				;yes			;an000; dms;
		JNE ER_IF70
			dec	cs:[bp].ER_Dest_Page	;next page		;an000; dms;
			mov	di,EMS_Page_Size_In_Bytes;end of page		;an000; dms;
;		$endif					;			;an000; dms;
ER_IF70:
;	$else						;forward move		;an000; dms;
	JMP SHORT ER_EN69
ER_IF69:
		cmp	di,4000h			;end of page?		;an000; dms;
;		$if	e				;yes			;an000; dms;
		JNE ER_IF73
			inc	cs:[bp].ER_Dest_Page	;next page		;an000; dms;
			xor	di,di			;clear di		;an000; dms;
;		$endif					;			;an000; dms;
ER_IF73:
;	$endif						;			;an000; dms;
ER_EN69:
	mov	bx,cs:[bp].ER_Dest_Page 		;pass page to map	;an000; dms;
	call	ER_Map_Next_Dest_Page			;map in the page	;an000; dms;

ER_Move_Buffer_Count:

	mov	cx,cs:[bp].ER_Current_Move_Count	;get move from source	;an000; dms;

	mov	ax,cs					;get seg for buffer	;an000; dms;
	mov	ds,ax					;put into es		;an000; dms;
	mov	si,offset cs:ER_Move_Xchg_Buffer1	;offset of buffer	;an000; dms;
	add	si,bp					;offset BP relative	;an000; dms;
	cmp	cs:[bp].ER_Direction_Flag,ER_Down	;reverse move?		;an000; dms;
;	$if	e					;yes			;an000; dms;
	JNE ER_IF76
		add	si,ER_10H			;end of buffer	+ 1	;an000; dms;
		dec	si				;end of buffer		;an000; dms;
;	$endif						;			;an000; dms;
ER_IF76:

	cmp	cs:[bp].ER_Direction_Flag,ER_Down	;reverse move?		;an000; dms;
;	$if	e					;yes			;an000; dms;
	JNE ER_IF78
		std					;reverse move		;an000; dms;
;	$else						;forward move		;an000; dms;
	JMP SHORT ER_EN78
ER_IF78:
		cld					;			;an000; dms;
;	$endif						;			;an000; dms;
ER_EN78:
	cli						;ints off		;an000; dms;
	rep	movsb					;move the data		;an000; dms;
	sti						;ints on		;an000; dms;

ER_Move_Dest_Exit:

	pop	ds					;restore regs		;an000; dms;
	pop	si					;			;an000; dms;
	pop	dx					;			;an000; dms;
	pop	bx					;			;an000; dms;
	pop	ax					;			;an000; dms;

	ret						;return to caller	;an000; dms;

ER_Move_Buffer_To_Dest		endp			;end proc		;an000; dms;


;=========================================================================
; ER_Xchg_Source_To_Buffer	: This routine moves the source data to
;				  the buffer before it is exchanged with
;				  the destination data.
;
;	Inputs	: BP - carries type of memory for source/dest
;		  Bit 0 - Destination (EMS if set)
;		  Bit 1 - Source (EMS if set)
;
;	Outputs : ER_Move_Xchg_Buffer1 - Source data
;=========================================================================

ER_Xchg_Source_To_Buffer	proc			;			;an000; dms;

	push	ax					;save regs		;an000; dms;
	push	bx					;			;an000; dms;
	push	dx					;			;an000; dms;
	push	di					;			;an000; dms;
	push	si					;			;an000; dms;
	push	ds					;			;an000; dms;
	push	es					;			;an000; dms;

	test	cs:[bp].ER_Mem_Type,ER_Source_EMS_Memory;Source EMS?		;an000; dms;
	jz	ER_Xchg_Source_Conv_Mem 		;no - adjust seg:off	;an000; dms;
	jmp	ER_Xchg_Source_EMS_Mem			;yes- continue move	;an000; dms;

ER_Xchg_Source_Conv_Mem:

	mov	ax,ds					;adjust segment:off	;an000; dms;
	mov	dx,si					;			;an000; dms;
	call	ER_Segment_Adjust			;			;an000; dms;
	mov	ds,ax					;new segment:off	;an000; dms;
	mov	si,dx					;			;an000; dms;
	jmp	ER_Xchg_Source_Count			;determine count	;an000; dms;

ER_Xchg_Source_EMS_Mem:

	cmp	si,4000h				;beginning of log page	;an000; dms;
	je	ER_Xchg_Source_EMS_Next 		;yes - get next page	;an000; dms;
	mov	bx,cs:[bp].ER_Source_Page		;pass log. page to call ;an000; dms;
	call	ER_Map_Next_Src_Page			;no  - map in current pg;an000; dms;
	jmp	ER_Xchg_Source_Count			;get count for move	;an000; dms;

ER_Xchg_Source_EMS_Next:

	mov	bx,cs:[bp].ER_Source_Page		;pass log. page to call ;an000; dms;
	inc	bx					;  adjusted upward	;an000; dms;
	call	ER_Map_Next_Src_Page			;map in the page	;an000; dms;
	xor	si,si					;reinit pointer 	;an000; dms;

ER_Xchg_Source_Count:

	mov	cx,ER_10H				;default count		;an000; dms;
	cmp	cs:[bp].ER_Move_Count_High,0		;high word set		;an000; dms;
	jne	ER_Xchg_Source_High_Set 		;yes - use default	;an000; dms;
	cmp	cs:[bp].ER_Move_Count_Low,cx		;>= 10h bytes		;an000; dms;
	jae	ER_Xchg_Source_High_Set 		;yes - use default	;an000; dms;
	mov	cx,cs:[bp].ER_Move_Count_Low		;no - use last few bytes;an000; dms;

ER_Xchg_Source_High_Set:

	cmp	si,di					;source >= dest?	;an000; dms;
;	$if	b					;no			;an000; dms;
	JNB ER_IF81
		mov	ax,4000h			;get end of page	;an000; dms;
		sub	ax,si				;get bytes remaining	;an000; dms;
		cmp	ax,ER_10H			;source >= 10h		;an000; dms;
;		$if	b				;no			;an000; dms;
		JNB ER_IF82
			mov	cx,ax			;get remaining count	;an000; dms;
;		$endif					;			;an000; dms;
ER_IF82:
;	$else						;source >= dest 	;an000; dms;
	JMP SHORT ER_EN81
ER_IF81:
		mov	ax,4000h			;get end of page	;an000; dms;
		sub	ax,di				;get bytes remaining	;an000; dms;
		cmp	ax,ER_10H			;dest >= 10h		;an000; dms;
;		$if	b				;no			;an000; dms;
		JNB ER_IF85
			mov	cx,ax			;get remaining count	;an000; dms;
;		$endif					;			;an000; dms;
ER_IF85:
;	$endif						;			;an000; dms;
ER_EN81:

ER_Xchg_Source_Default_Count:

	mov	cs:[bp].ER_Current_Move_Count,cx	;save current move cnt	;an000; dms;

	sub	cs:[bp].ER_Move_Count_Low,cx		;get new count		;an000; dms;
	sbb	cs:[bp].ER_Move_Count_High,0		;pick up borrow 	;an000; dms;

	mov	ax,cs					;get seg for buffer	;an000; dms;
	mov	es,ax					;put into es		;an000; dms;
	mov	di,offset cs:ER_Move_Xchg_Buffer1	;offset of buffer	;an000; dms;
	add	di,bp					;offset BP relative	;an000; dms;

	cld						;forward move		;an000; dms;
	cli						;ints off		;an000; dms;
	rep	movsb					;move the data		;an000; dms;
	sti						;ints on		;an000; dms;

ER_Xchg_Source_Exit:

	pop	es					;restore regs		;an000; dms;
	pop	ds					;			;an000; dms;
	pop	si					;			;an000; dms;
	pop	di					;			;an000; dms;
	pop	dx					;			;an000; dms;
	pop	bx					;			;an000; dms;
	pop	ax					;			;an000; dms;

	ret						;return to caller	;an000; dms;

ER_Xchg_Source_To_Buffer	endp			;end proc		;an000; dms;


;=========================================================================
; ER_Xchg_Dest_To_Buffer	: This routine moves the destination data to
;				  the buffer before it is exchanged with
;				  the source data.
;
;	Inputs	: BP - carries type of memory for source/dest
;		  Bit 0 - Destination (EMS if set)
;		  Bit 1 - Source (EMS if set)
;
;	Outputs : ER_Move_Xchg_Buffer2 - Destination data
;=========================================================================

ER_Xchg_Dest_To_Buffer		proc			;			;an000; dms;

	push	ax					;save regs		;an000; dms;
	push	bx					;			;an000; dms;
	push	dx					;			;an000; dms;
	push	di					;			;an000; dms;
	push	si					;			;an000; dms;
	push	ds					;			;an000; dms;
	push	es					;			;an000; dms;

	test	cs:[bp].ER_Mem_Type,ER_Dest_EMS_Memory	;Dest EMS?		;an000; dms;
	jz	ER_Xchg_Dest_Conv_Mem			;no - adjust seg:off	;an000; dms;
	jmp	ER_Xchg_Dest_EMS_Mem			;yes- continue move	;an000; dms;

ER_Xchg_Dest_Conv_Mem:

	mov	ax,es					;adjust segment:off	;an000; dms;
	mov	dx,di					;			;an000; dms;
	call	ER_Segment_Adjust			;			;an000; dms;
	mov	es,ax					;new segment:off	;an000; dms;
	mov	di,dx					;			;an000; dms;
	jmp	ER_Xchg_Dest_Count			;determine count	;an000; dms;

ER_Xchg_Dest_EMS_Mem:

	cmp	di,4000h				;beginning of log page	;an000; dms;
	je	ER_Xchg_Dest_EMS_Next			;yes - get next page	;an000; dms;
	mov	bx,cs:[bp].ER_Dest_Page 		;pass log. page to call ;an000; dms;
	call	ER_Map_Next_Dest_Page			;no  - map in current pg;an000; dms;
	jmp	ER_Xchg_Dest_Count			;get count for move	;an000; dms;

ER_Xchg_Dest_EMS_Next:

	mov	bx,cs:[bp].ER_Dest_Page 		;pass log. page to call ;an000; dms;
	inc	bx					;  adjusted upward	;an000; dms;
	call	ER_Map_Next_Dest_Page			;map in the page	;an000; dms;
	xor	di,di					;reinit pointer 	;an000; dms;

ER_Xchg_Dest_Count:

	mov	cx,cs:[bp].ER_Current_Move_Count	;get move count 	;an000; dms;
	mov	ax,es					;get destination seg	;an000; dms;
	mov	ds,ax					;put into ds for buffer ;an000; dms;
							;  transfer
	mov	si,di					;get destination off	;an000; dms;
	mov	ax,cs					;get seg for buffer	;an000; dms;
	mov	es,ax					;put into es		;an000; dms;
	mov	di,offset cs:ER_Move_Xchg_Buffer2	;offset of buffer	;an000; dms;
	add	di,bp					;offset BP relative	;an000; dms;

	cld						;forward move		;an000; dms;
	cli						;ints off		;an000; dms;
	rep	movsb					;move the data		;an000; dms;
	sti						;ints on		;an000; dms;

ER_Xchg_Dest_Exit:

	pop	es					;restore regs		;an000; dms;
	pop	ds					;			;an000; dms;
	pop	si					;			;an000; dms;
	pop	di					;			;an000; dms;
	pop	dx					;			;an000; dms;
	pop	bx					;			;an000; dms;
	pop	ax					;			;an000; dms;

	ret						;return to caller	;an000; dms;

ER_Xchg_Dest_To_Buffer		endp			;end proc		;an000; dms;




;=========================================================================
; ER_Xchg_Buffer_To_Source	; This routine performs the actual exchange
;				  from the destination buffer to the source
;				  buffer.
;
;	Inputs	: BP - carries type of memory for source/dest
;		  Bit 0 - Destination (EMS if set)
;		  Bit 1 - Source (EMS if set)
;		  ER_Move_Xchg_Buffer2 - Destination data
;
;	Outputs : Adjusted segment:offset or page/offset
;=========================================================================

ER_Xchg_Buffer_To_Source	proc			;			;an000; dms;

	push	ax					;save regs		;an000; dms;
	push	bx					;			;an000; dms;
	push	dx					;			;an000; dms;
	push	di					;			;an000; dms;
	push	es					;			;an000; dms;

	test	cs:[bp].ER_Mem_Type,ER_Source_EMS_Memory;Source EMS?		;an000; dms;
	jz	ER_Xchg_Buf2_Conv_Mem			;no - adjust seg:off	;an000; dms;
	jmp	ER_Xchg_Buf2_EMS_Mem			;yes- continue move	;an000; dms;

ER_Xchg_Buf2_Conv_Mem:

	mov	ax,ds					;adjust segment:off	;an000; dms;
	mov	dx,si					;			;an000; dms;
	call	ER_Segment_Adjust			;			;an000; dms;
	mov	ds,ax					;new segment:off	;an000; dms;
	mov	si,dx					;			;an000; dms;
	jmp	ER_Xchg_Buf2_Count			;determine count	;an000; dms;

ER_Xchg_Buf2_EMS_Mem:

	cmp	si,4000h				;beginning of log page	;an000; dms;
	je	ER_Xchg_Buf2_EMS_Next			;yes - get next page	;an000; dms;
	mov	bx,cs:[bp].ER_Source_Page		;pass log. page to call ;an000; dms;
	call	ER_Map_Next_Src_Page			;no  - map in current pg;an000; dms;
	jmp	ER_Xchg_Buf2_Count			;get count for move	;an000; dms;

ER_Xchg_Buf2_EMS_Next:

	inc	cs:[bp].ER_Source_Page			;adjust log page	;an000; dms;
	mov	bx,cs:[bp].ER_Source_Page		;pass log. page to call ;an000; dms;
	call	ER_Map_Next_Src_Page			;map in the page	;an000; dms;
	xor	si,si					;reinit pointer 	;an000; dms;

ER_Xchg_Buf2_Count:

	mov	cx,cs:[bp].ER_Current_Move_Count	;get move count 	;an000; dms;

	mov	ax,ds					;get destination seg	;an000; dms;
	mov	es,ax					;put into ds for buffer ;an000; dms;
							;  transfer
	mov	di,si					;get destination off	;an000; dms;
	add	si,cx					;adjust source ptr	;an000; dms;
	push	si					;save across xchg	;an000; dms;
	push	ds					;			;an000; dms;

	mov	ax,cs					;get seg for buffer	;an000; dms;
	mov	ds,ax					;put into es		;an000; dms;
	mov	si,offset cs:ER_Move_Xchg_Buffer2	;offset of buffer	;an000; dms;
	add	si,bp					;offset BP relative	;an000; dms;

	cld						;forward move		;an000; dms;
	cli						;ints off		;an000; dms;
	rep	movsb					;move the data		;an000; dms;
	sti						;ints on		;an000; dms;

	pop	ds					;restore ptr		;an000; dms;
	pop	si					;			;an000; dms;

ER_Xchg_Buf2_Exit:

	pop	es					;restore regs		;an000; dms;
	pop	di					;			;an000; dms;
	pop	dx					;			;an000; dms;
	pop	bx					;			;an000; dms;
	pop	ax					;			;an000; dms;

	ret						;return to caller	;an000; dms;

ER_Xchg_Buffer_To_Source	endp			;end proc		;an000; dms;



;=========================================================================
; ER_Xchg_Buffer_To_Dest	; This routine performs the actual exchange
;				  from the source buffer to the destination.
;
;	Inputs	: BP - carries type of memory for source/dest
;		  Bit 0 - Destination (EMS if set)
;		  Bit 1 - Source (EMS if set)
;		  ER_Move_Xchg_Buffer1 - Source data
;
;	Outputs : Adjusted segment:offset or page/offset
;=========================================================================

ER_Xchg_Buffer_To_Dest		proc			;			;an000; dms;

	push	ax					;save regs		;an000; dms;
	push	bx					;			;an000; dms;
	push	dx					;			;an000; dms;
	push	si					;			;an000; dms;
	push	ds					;			;an000; dms;

	test	cs:[bp].ER_Mem_Type,ER_Dest_EMS_Memory	;Dest EMS?		;an000; dms;
	jz	ER_Xchg_Buf1_Conv_Mem			;no - adjust seg:off	;an000; dms;
	jmp	ER_Xchg_Buf1_EMS_Mem			;yes- continue move	;an000; dms;

ER_Xchg_Buf1_Conv_Mem:

	mov	ax,es					;adjust segment:off	;an000; dms;
	mov	dx,di					;			;an000; dms;
	call	ER_Segment_Adjust			;			;an000; dms;
	mov	es,ax					;new segment:off	;an000; dms;
	mov	di,dx					;			;an000; dms;
	jmp	ER_Xchg_Buf1_Count			;determine count	;an000; dms;

ER_Xchg_Buf1_EMS_Mem:

	cmp	di,4000h				;beginning of log page	;an000; dms;
	je	ER_Xchg_Buf1_EMS_Next			;yes - get next page	;an000; dms;
	mov	bx,cs:[bp].ER_Dest_Page 		;pass log. page to call ;an000; dms;
	call	ER_Map_Next_Dest_Page			;no  - map in current pg;an000; dms;
	jmp	ER_Xchg_Buf1_Count			;get count for move	;an000; dms;

ER_Xchg_Buf1_EMS_Next:

	inc	cs:[bp].ER_Dest_Page			;adjust log page	;an000; dms;
	mov	bx,cs:[bp].ER_Dest_Page 		;pass log. page to call ;an000; dms;
	call	ER_Map_Next_Dest_Page			;map in the page	;an000; dms;
	mov	di,EMS_Page_Size_In_Bytes		;reinit pointer 	;an000; dms;

ER_Xchg_Buf1_Count:

	mov	cx,cs:[bp].ER_Current_Move_Count	;get move count 	;an000; dms;
	mov	ax,cs					;get seg for buffer	;an000; dms;
	mov	ds,ax					;put into es		;an000; dms;
	mov	si,offset cs:ER_Move_Xchg_Buffer1	;offset of buffer	;an000; dms;
	add	si,bp					;offset BP relative	;an000; dms;

	cld						;forward move		;an000; dms;
	cli						;ints off		;an000; dms;
	rep	movsb					;move the data		;an000; dms;
	sti						;ints on		;an000; dms;

ER_Xchg_Buf1_Exit:

	pop	ds					;restore regs		;an000; dms;
	pop	si					;			;an000; dms;
	pop	dx					;			;an000; dms;
	pop	bx					;			;an000; dms;
	pop	ax					;			;an000; dms;

	ret						;return to caller	;an000; dms;

ER_Xchg_Buffer_To_Dest		endp			;end proc		;an000; dms;



;=========================================================================
; ER_Map_Next_Src_Page		: This routine maps in the page needed by
;				  the source of the move/exchange.
;
;	Inputs	: ER_Source_Phys_Page - Physical page of source
;		  ER_Source_Handle    - Handle of source
;		  BX		      - logical page
;
;	Outputs : newly mapped page
;=========================================================================

ER_Map_Next_Src_Page	proc				;map next src. page	;an000; dms;

	mov	ax,cs:[bp].ER_Source_Phys_Page		;map the source page	;an000; dms;
	mov	dx,cs:[bp].ER_Source_Handle		;handle to use		;an000; dms;
	call	Map_L_To_P				;map the page		;an000; dms;

	ret						;return to caller	;an000; dms;

ER_Map_Next_Src_Page	endp				;end proc		;an000; dms;

;=========================================================================
; ER_Map_Next_Dest_Page 	: This routine maps in the page needed by
;				  the destination of the move/exchange.
;
;	Inputs	: ER_Dest_Phys_Page - Physical page of source
;		  ER_Dest_Handle    - Handle of source
;		  BX		    - logical page to map
;
;	Outputs : newly mapped page
;=========================================================================

ER_Map_Next_Dest_Page	proc				;map next dest. page	;an000; dms;

	mov	ax,cs:[bp].ER_Dest_Phys_Page		;map the dest. page	;an000; dms;
	mov	dx,cs:[bp].ER_Dest_Handle		;handle to use		;an000; dms;
	call	Map_L_To_P				;map the page		;an000; dms;

	ret						;return to caller	;an000; dms;

ER_Map_Next_Dest_Page	endp				;end proc		;an000; dms;

;=========================================================================
; ER_Move_Data		: This routine will perform the actual move of the
;			  data for the function 5700h.
;
;	Inputs	: DS:SI - Pointer to Move_Source_Dest_Struc data
;
;	Outputs : AH - Non-zero on error
;=========================================================================

ER_Move_Data	proc					;move the data		;an000; dms;

	push	bx					;save regs		;an000; dms;
	push	cx					;			;an000; dms;
	push	dx					;			;an000; dms;
	push	di					;			;an000; dms;
	push	si					;			;an000; dms;
	push	ds					;			;an000; dms;
	push	es					;			;an000; dms;

	call	ER_Save_Context 			;save off max of 2 pages;an000; dms;
	call	ER_Det_Src_Dest_Seg			;determine segs 	;an000; dms;
	call	ER_Det_Move_Count			;ER_10h_Move_Count =	;an000; dms;
							;  # of 10h moves
							;ER_10h_Move_Remainder =
							;  # of bytes remaining

ER_Move_Data_Now:

							;set the flags to signal
							;the memory type in use
							;for Source/Destination.

	xor	al,al					;al signals type of mem ;an000; dms;
	or	al,[si].Source_Memory_Type		;get source memory type ;an000; dms;
	shl	al,1					;put into bit 1 	;an000; dms;
	or	al,[si].Dest_Memory_Type		;get dest. memory type	;an000; dms;
	cbw						;make it a word value	;an000; dms;
	mov	cs:[bp].ER_Mem_Type,ax			;put flags in var	;an000; dms;
							;bp = bit 0 - dest mem
							;     bit 1 - src mem

	mov	di,cs:[bp].ER_Dest_Off			;get dest. offset	;an000; dms;
	mov	es,cs:[bp].ER_Dest_Seg			;get dest. seg		;an000; dms;

	mov	si,cs:[bp].ER_Source_Off		;get src. offset	;an000; dms;
	mov	ds,cs:[bp].ER_Source_Seg		;get src. seg		;an000; dms;

ER_Move_Data_Loop:

	call	ER_Move_Source_To_Buffer		;move data to buffer	;an000; dms;
	call	ER_Move_Buffer_To_Dest			;move buffer to dest.	;an000; dms;

	cmp	cs:[bp].ER_Move_Count_High,0		;end of move?		;an000; dms;
	jne	ER_Move_Data_Loop			;no - continue loop	;an000; dms;
	cmp	cs:[bp].ER_Move_Count_Low,0		;end of move?		;an000; dms;
	jne	ER_Move_Data_Loop			;no - continue loop	;an000; dms;
							;yes - end of loop	;an000; dms;

ER_Move_Data_Error_Exit:

	call	ER_Restore_Context			;restore the context	;an000; dms;

	pop	es					;restore regs		;an000; dms;
	pop	ds					;			;an000; dms;
	pop	si					;			;an000; dms;
	pop	di					;			;an000; dms;
	pop	dx					;			;an000; dms;
	pop	cx					;			;an000; dms;
	pop	bx					;			;an000; dms;

	ret						;return to caller	;an000; dms;

ER_Move_Data	endp					;end proc		;an000; dms;



;=========================================================================
; ER_Exchange_Data	: This routine will perform the actual exchange of
;			  data for the function 5701h.
;
;	Inputs	: DS:SI - Pointer to Move_Source_Dest_Struc data
;
;	Outputs : AH - Non-zero on error
;=========================================================================

ER_Exchange_Data	proc				;xchg the data		;an000; dms;

	push	bx					;save regs		;an000; dms;
	push	cx					;			;an000; dms;
	push	dx					;			;an000; dms;
	push	di					;			;an000; dms;
	push	si					;			;an000; dms;
	push	ds					;			;an000; dms;
	push	es					;			;an000; dms;

	call	ER_Save_Context 			;save off max of 2 pages;an000; dms;
	call	ER_Det_Src_Dest_Seg			;determine segs 	;an000; dms;
	call	ER_Det_Move_Count			;ER_10h_Move_Count =	;an000; dms;
							;  # of 10h moves
							;ER_10h_Move_Remainder =
							;  # of bytes remaining

ER_Xchg_Data_Now:

							;set the flags to signal
							;the memory type in use
							;for Source/Destination.

	xor	al,al					;al signals type of mem ;an000; dms;
	or	al,[si].Source_Memory_Type		;get source memory type ;an000; dms;
	shl	al,1					;put into bit 1 	;an000; dms;
	or	al,[si].Dest_Memory_Type		;get dest. memory type	;an000; dms;
	cbw						;make it a word value	;an000; dms;
	mov	cs:[bp].ER_Mem_Type,ax			;put flags in var	;an000; dms;
							;bp = bit 0 - dest mem
							;     bit 1 - src mem

	mov	di,cs:[bp].ER_Dest_Off			;get dest. offset	;an000; dms;
	mov	es,cs:[bp].ER_Dest_Seg			;get dest. seg		;an000; dms;

	mov	si,cs:[bp].ER_Source_Off		;get src. offset	;an000; dms;
	mov	ds,cs:[bp].ER_Source_Seg		;get src. seg		;an000; dms;

ER_Xchg_Data_Loop:

	call	ER_Xchg_Source_To_Buffer		;move source to buf 1	;an000; dms;
	call	ER_Xchg_Dest_To_Buffer			;move dest. to buf 2	;an000; dms;
	call	ER_Xchg_Buffer_To_Source		;move buf2 to source	;an000; dms;
	call	ER_Xchg_Buffer_To_Dest			;move buf1 to dest.	;an000; dms;

	cmp	cs:[bp].ER_Move_Count_High,0		;end of move?		;an000; dms;
	jne	ER_Xchg_Data_Loop			;no - continue loop	;an000; dms;
	cmp	cs:[bp].ER_Move_Count_Low,0		;end of move?		;an000; dms;
	jne	ER_Xchg_Data_Loop			;no - continue loop	;an000; dms;
							;yes - end of loop	;an000; dms;

ER_Xchg_Data_Error_Exit:

	call	ER_Restore_Context			;restore the context	;an000; dms;

	pop	es					;restore regs		;an000; dms;
	pop	ds					;			;an000; dms;
	pop	si					;			;an000; dms;
	pop	di					;			;an000; dms;
	pop	dx					;			;an000; dms;
	pop	cx					;			;an000; dms;
	pop	bx					;			;an000; dms;

	ret						;return to caller	;an000; dms;

ER_Exchange_Data	endp				;end proc		;an000; dms;



	page

;=========================================================================
;=============== Function 5Ah Logic -  Allocate Raw Pages    =============
;=========================================================================


;=========================================================================
; Alloc_Raw		- This routine allocates raw EMS pages, pages
;			  less than the standard 16k page.  These pages
;			  are a sub-multiple of 16k.  In the IBM version
;			  of this implementation the raw page is defined
;			  as 16k, thus we do not need to do anything
;			  special here.  We map this call to the proc
;			  GET_HANDLE (function 43h) to allocate a handle.
;
;	Inputs	: AH - 5Ah (Allocate Raw Pages)
;		  BX - Number of raw pages to allocate
;
;	Outputs : AH - Non-zero if error (Determined by Get_Handle proc)
;		  DX - Handle if no error
;=========================================================================

Alloc_Raw	proc					;Allocate raw pages	;an000; dms;

	PUSH	BX
	PUSH	CX
	PUSH	DI
	PUSH	SI
	PUSH	DS			;save these registers

	PUSH	CS			;get cs
	POP	DS			;into ds

					;Remove test for BX = 0. This is   @RH4
					; valid under LIM 4.0

	cmp	al,AR_Sub_Max		;sub function out of range?		;an000; dms;
	jna	AR_OKSub		;no					;an000; dms;
		mov	ah,EMS_Code8F	;yes-signal error			;an000; dms;
		jmp	AR_Exit 	;exit routine				;an000; dms;

AR_OKSub:

	CMP	BX,TOTAL_EMS_PAGES	;Enough total EMS pages?
	JNA	AR_OKTOTAL
	MOV	AH,EMS_CODE87
	JMP	AR_EXIT

AR_OKTOTAL:
	cli				;ints off				;an000; dms;
	CMP	BX,FREE_PAGES		;Enough unallocated pages?
	sti				;ints on				;an000; dms;
	JNA	AR_OKFREE
	MOV	AH,EMS_CODE88
	JMP	AR_EXIT
			;-----------------------------------------------------
			; Search for a free handle			 @RH1 º
			;-----------------------------------------------------
AR_OKFREE:
	MOV	CX,NUM_HANDLES		;loop counter is #handles
	DEC	CX			;handle 0 reserved for op. sys.   @RH1
	MOV	DX,1			;handle assignment set to 1	  @RH1
	MOV	DI,TYPE H_LOOKUP_STRUC	;init table index to 1st entry	  @RH1
;--------------------------------
	CLI				;interrupts OFF during allocation
;--------------------------------
AR_FREEHSRCH:
	CMP	HANDLE_LOOKUP_TABLE.H_PAGES[DI],REUSABLE_HANDLE
					;Is this handle available?	  @RH1
	JE	AR_HFREE		;yes end search  dx=handle id	  @RH1
	INC	DX			;next handle assignment
	ADD	DI,TYPE H_LOOKUP_STRUC	;next entry in handle lookup	  @RH1
					;repeat for all table entries
	LOOP AR_FREEHSRCH
	    MOV     AH,EMS_CODE85	;no available handles
	    JMP     AR_EXIT		;go to exit					 ;GGA

			;-----------------------------------------------------
			; If here then there's enough pages for request. @RH1 º
			;   DX = handle #, DI = ptr to hndl lookup entry @RH1 º
AR_HFREE:

	MOV	CX,NUM_HANDLES		;loop counter
	DEC	CX			;handle 0 reserved for op. sys.    @RH1
					;si = index to hndl lookup tbl	   @RH1
	MOV	SI,TYPE H_LOOKUP_STRUC	; for adding pages (skip 0 entry)  @RH1
	XOR	AX,AX			;clear page counter
	CLC				;clear carry for addition
AR_PAGESUM:
	CMP	HANDLE_LOOKUP_TABLE.H_PAGES[SI],REUSABLE_HANDLE
	JE	AR_PGSUM_BOT		;If handle is free don't add       @RH4
	ADD	AX,HANDLE_LOOKUP_TABLE.H_PAGES[SI]
					;add lengths (pages) of PALs	  @RH1
	ADD	SI,TYPE H_LOOKUP_STRUC	; next entry in handle lookup	  @RH1
AR_PGSUM_BOT:
	LOOP	AR_PAGESUM
	CMP	AX,TOTAL_EMS_PAGES	;pages in handle lookup > total?  @RH1
	JNA	AR_CALCHLUP		;no OK				  @RH1
	    MOV     AH,EMS_CODE80	;software error..we screwed up	  @RH1
	    JMP     AR_EXIT		;go to exit			  @RH1		 ;GGA

AR_CALCHLUP:				;calculate entry in hndl lkup tbl @RH1
	cmp	bx,0			;page request?				;an000; dms;
	jne	AR_Alloc_Cont		;yes continue				;an000; dms;
		cli			;ints off				;an001; dms;
		mov	Handle_LookUp_Table.H_Pages[di],bx	;new page count ;an001; dms;
		sti			;ints on				;an001; dms;
		xor	ah,ah		;clear flag				;an000; dms;
		jmp	AR_Exit 	;exit routine				;an000; dms;

AR_Alloc_Cont:

	cli						;ints off		;an001; dms;
	mov	cx,bx					;alloc count		;an000; dms;
	call	EMS_Page_Contig_Chk			;do we have contig pgs. ;an001; dms;
	jnc	AR_Alloc				;yes continue process	;an001; dms;
		mov	ah,EMS_Code88			;no  signal error	;an001; dms;
		sti					;ints on		;an001; dms;
		jmp	AR_Exit 			;exit routine		;an001; dms;

AR_Alloc:

	call	EMS_Link_Set				;set up links		;an001; dms;


	sub	Free_Pages,bx		;free = free - requested pages
	mov	Handle_LookUp_Table.H_Pages[di],bx	;page count		;an000; dms;
	mov	Handle_LookUp_Table.H_Pal_Ptr[di],si	;initialize to ptr for	;ac001; dms;
							;  pages
	sti						;ints on		;an001; dms;
	xor	ah,ah					;clear flag		;an000; dms;


AR_EXIT:										 ;GGA

	POP	DS
	POP	SI
	POP	DI
	POP	CX
	POP	BX

	ret						;return to caller	;an000; dms;

Alloc_Raw	endp					;end proc		;an000; dms;

	page
;=========================================================================
;=============== Function 5Ch Logic -  Prepare for Warm Boot =============
;=========================================================================


;=========================================================================
; Prepare_Boot		- This routine prepares the hardware for a
;			  warm boot.  Since we have no special hardware
;			  requirements at this time, this routine sets
;			  a good error level and returns to the caller.
;
;	Inputs	: AH - 5Ch (Prepare for Warm Boot)
;
;	Outputs : AH - Non-zero if error (Determined by Get_Handle proc)
;=========================================================================

Prepare_Boot	proc					;prepare for warm boot	;an000; dms;

	xor	ah,ah					;signal no error	;an000; dms;

	ret						;return to caller	;an000; dms;

Prepare_Boot	endp					;end proc		;an000; dms;



