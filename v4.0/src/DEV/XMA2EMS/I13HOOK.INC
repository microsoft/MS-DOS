
include MSBDS.INC				;include BDS struc		;an000; dms;




;=========================================================================
; I13_Handler			- This routine is the main driver of the
;				  INT 13h hook.
;=========================================================================

I13_Handler	proc	far			;				;an000; dms;

	jmp	I13_Handler_Start


I13_Max_Head		db	?		;max head count on drive	;an000; dms;
I13_SPT 		db	?		;max sectors/track count	;an000; dms;
I13_BPS 		dw	?		;max number bytes/sector	;an000; dms;
I13_Bytes_Per_Para	dw	10h		;number of bytes per paragraph	;an000; dms;
I13_Bytes_Per_EMS_Page	dw	4000h		;bytes per EMS page		;an000; dms;
I13_Paras_Per_Sector	dw	?		;paras per sector		;an000; dms;
I13_DD_Per_Sector	dw	?		;double words per sector	;an000; dms;
I13_Operation		db	?		;INT 13h function		;an000; dms;
I13_Sector_Count	db	?		;sector count			;an000; dms;
I13_Track_Number	dw	?		;track number			;an000; dms;
I13_Sector_Number	db	?		;sector number			;an000; dms;
I13_Head_Number 	db	?		;head number			;an000; dms;
I13_Drive_Number	db	?		;drive number			;an000; dms;
I13_Sectors_To_Trf	db	1		;current sectors to trf 	;an000; dms;
I13_Curr_Trf_Cnt	db	?		;total transfer count in secs	;an000; dms;
I13_Trf_Off		dw	?		;current address for trf	;an000; dms;
I13_Trf_Seg		dw	?						;an000; dms;
I13_512_Byte_Buffer	db	512 dup(0)	;buffer for sector		;an000; dms;

I13_Handler_Start:

	sti					;ints on			;an000; dms;
	cmp	ah,02h				;read operation?		;an000; dms;
	je	I13_Handler_Get_Parms		;yes - get drive parms		;an000; dms;

	cmp	ah,03h				;write operation?		;an000; dms;
	je	I13_Handler_Get_Parms		;yes - get drive parms		;an000; dms;

	jmp	cs:IntV13			;neither - go to old INT 13h	;an000; dms;

I13_Handler_Get_Parms:

	call	I13_Get_Dev_Parms		;get device parms for this drive;an000; dms;
	jnc	I13_Handler_Range_Ck		;we have device data		;an000; dms;
	jmp	cs:IntV13			;go to old INT 13h vector	;an000; dms;

I13_Handler_Range_Ck:

	call	I13_Target_Source_Range_Ck	;crosses the 640k boundary?	;an000; dms;
	jc	I13_Handler_Request_Break	;break up the request		;an000; dms;
	jmp	cs:IntV13			;go to old INT 13h vector	;an000; dms;

I13_Handler_Request_Break:

	call	I13_Request_Break_Up		;break up I13 request		;an000; dms;

	ret 2					;return to caller		;an000; dms;
						;clear the flags from the stack
						;  and pass back ours
I13_Handler	endp				;				;an000; dms;



;=========================================================================
; I13_Target_Source_Range_Ck	- This routine determines if the
;				  target or source resides in an EMS
;				  page.
;
;	Inputs	: ES:BX - Source/target address
;
;	Outputs : CY	- if address resides in an EMS page
;		  NC	- address not in an EMS page
;=========================================================================


I13_Target_Source_Range_Ck	proc	near	;				;an000; dms;

	push	ax				;save regs			;an000; dms;
	push	bx				;				;an000; dms;
	push	cx				;				;an000; dms;
	push	si				;				;an000; dms;
	push	ds				;				;an000; dms;

	mov	ax,cs				;get cs addressibility		;an000; dms;
	mov	ds,ax				;				;an000; dms;
	mov	si,offset cs:Map_Table		;point to the map table 	;an000; dms;

	mov	cx,cs:Map_Count 		;get the number of phys. pages	;an000; dms;

I13_Target_Source_Loop:

	cmp	cx,0				;at end?			;an000; dms;
	je	I13_Target_Source_Not_EMS_Page	;yes - source/target not in pg	;an000; dms;

	mov	ax,ds:[si].Phys_Page_Segment	;get the segment value		;an000; dms;
	mov	bx,es				;				;an000; dms;
	cmp	bx,ax				;source/target > EMS page?	;an000; dms;
	jb	I13_Target_Source_Not_EMS_Page	;no - we are OK for old INT 13	;an000; dms;
						;must be >= EMS page

	add	ax,400h 			;get end address of EMS page	;an000; dms;
	cmp	bx,ax				;source/target < end of EMS pg? ;an000; dms;
	jb	I13_Target_Source_In_EMS_Page	;yes - we are in a page 	;an000; dms;

	add	si,type Mappable_Phys_Page_Struct ;adjust pointer to next page	;an000; dms;
	dec	cx				;dec counter			;an000; dms;

	jmp	I13_Target_Source_Loop		;continue loop			;an000; dms;

I13_Target_Source_Not_EMS_Page:

	clc					;flag not in EMS page		;an000; dms;
	jmp	I13_Target_Source_Exit		;exit routine			;an000; dms;

I13_Target_Source_In_EMS_Page:

	stc					;flag in an EMS page		;an000; dms;

I13_Target_Source_Exit:

	pop	ds				;restore regs			;an000; dms;
	pop	si				;				;an000; dms;
	pop	cx				;				;an000; dms;
	pop	bx				;				;an000; dms;
	pop	ax				;				;an000; dms;

	ret					;				;an000; dms;

I13_Target_Source_Range_Ck	endp		;				;an000; dms;


;=========================================================================
; I13_Request_Break_Up		- Break up the INT 13h request onto 16k
;				  boundaries.
;
;	Inputs	: AH	- 02 (Read)
;			  03 (Write)
;		  AL	- Sector count
;		  CH	- Track number
;		  CL	- Sector number
;		  DH	- Head number
;		  DL	- Drive number
;		  ES:BX - Buffer address
;
;	Outputs : Data transferred
;=========================================================================


I13_Request_Break_Up	proc	near		;				;an000; dms;

	push	bx				;save regs			;an000; dms;
	push	cx				;				;an000; dms;
	push	dx				;				;an000; dms;
	push	di				;				;an000; dms;
	push	si				;				;an000; dms;
	push	ds				;				;an000; dms;
	push	es				;				;an000; dms;


	mov	cs:I13_Trf_Seg,es		;save segment			;an000; dms;
	mov	cs:I13_Trf_Off,bx		;save offset			;an000; dms;
	mov	cs:I13_Curr_Trf_Cnt,0		;init transfer count		;an000; dms;
	mov	cs:I13_Operation,ah		;save operation 		;an000; dms;
	mov	cs:I13_Sector_Count,al		;save sector count		;an000; dms;


	mov	byte ptr cs:I13_Track_Number,ch ;save starting track number	;an000; dms;
	mov	ch,cl				;xchg bytes			;an000; dms;
	shr	ch,1				;shift 6 bits			;an000; dms;
	shr	ch,1				;				;an000; dms;
	shr	ch,1				;				;an000; dms;
	shr	ch,1				;				;an000; dms;
	shr	ch,1				;				;an000; dms;
	shr	ch,1				;				;an000; dms;

	mov	byte ptr cs:I13_Track_Number[+1],ch	;high byte for cylinder ;an000; dms;
	and	cl,00111111b			;get bits 0-5 for sector number ;an000; dms;

	mov	cs:I13_Sector_Number,cl 	;save starting sector number	;an000; dms;
	mov	cs:I13_Head_Number,dh		;save starting head number	;an000; dms;
	mov	cs:I13_Drive_Number,dl		;save drive number		;an000; dms;

	mov	cl,cs:I13_Sector_Count		;while sectors			;an000; dms;

	cmp	cs:I13_Operation,02h		;read?				;an000; dms;
	jne	I13_Request_Write		;must be a write		;an000; dms;

I13_Request_Read:

	cmp	cl,0				;at end?			;an000; dms;
	je	I13_Request_Success		;exit we are done		;an000; dms;

	lea	bx,cs:I13_512_Byte_Buffer	;point to 512 byte buffer	;an000; dms;
	mov	ax,cs				;pass cs to es			;an000; dms;
	mov	es,ax				;				;an000; dms;

	call	I13_Invoke			;do the INT 13h to our buffer	;an000; dms;
	jc	I13_Request_Failed		;signal failure 		;an000; dms;
	mov	ax,cs				;point to our buffer to the	;an000; dms;
	mov	ds,ax				;  transfer			;an000; dms;
	mov	si,offset cs:I13_512_Byte_Buffer;				;an000; dms;

	mov	es,cs:I13_Trf_Seg		;restore seg to target		;an000; dms;
	mov	di,cs:I13_Trf_Off		;restore off to target		;an000; dms;

	push	cx				;save cx across move		;an000; dms;
	cld					;do a forward move		;an000; dms;
	mov	cx,cs:I13_DD_Per_Sector 	;  for 128 dd's                 ;an000; dms;
	db	66h				;op code for dd word move	;an000; dms;
	rep	movsw				;do the move - wow that was fast;an000; dms;
	pop	cx				;restore it			;an000; dms;

	call	I13_Adjust			;adjust our pointers		;an000; dms;

	dec	cl				;decrease sector counter	;an000; dms;
	jmp	I13_Request_Read		;continue loop			;an000; dms;

I13_Request_Write:

	cmp	cl,0				;at end?			;an000; dms;
	je	I13_Request_Success		;exit we are done		;an000; dms;

	mov	ax,cs				;point to 512 byte buffer	;an000; dms;
	mov	es,ax				;				;an000; dms;
	mov	di,offset cs:I13_512_Byte_Buffer;				;an000; dms;

	mov	ds,cs:I13_Trf_Seg		;get source segment		;an000; dms;
	mov	si,cs:I13_Trf_Off		;get source offset		;an000; dms;

	push	cx				;save cx across move		;an000; dms;
	cld					;do a forward move		;an000; dms;
	mov	cx,cs:I13_DD_Per_Sector 	;  for 128 dd's                 ;an000; dms;
	db	66h				;op code for dd word move	;an000; dms;
	rep	movsw				;do the move - wow that was fast;an000; dms;
	pop	cx				;restore it			;an000; dms;

	lea	bx,cs:I13_512_Byte_Buffer	;point to 512 byte buffer	;an000; dms;
	mov	ax,cs				;pass cs to es			;an000; dms;
	mov	es,ax				;				;an000; dms;

	call	I13_Invoke			;do the INT 13h to our buffer	;an000; dms;
	jc	I13_Request_Failed		;signal failure 		;an000; dms;
	call	I13_Adjust			;adjust our pointers		;an000; dms;

	dec	cl				;decrease sector counter	;an000; dms;
	jmp	I13_Request_Write		;continue loop			;an000; dms;

I13_Request_Failed:

	jmp	I13_Request_Exit		;exit on error			;an000; dms;


I13_Request_Success:

	xor	ax,ax				;clear status byte		;an000; dms;

I13_Request_Exit:

	pop	es				;restore regs			;an000; dms;
	pop	ds				;				;an000; dms;
	pop	si				;				;an000; dms;
	pop	di				;				;an000; dms;
	pop	dx				;				;an000; dms;
	pop	cx				;				;an000; dms;
	pop	bx				;				;an000; dms;


	ret					;				;an000; dms;

I13_Request_Break_Up	endp			;				;an000; dms;



;=========================================================================
; I13_Adjust		- This routine adjusts the needed fields for
;			  the next iteration of INT 13h.
;
;	Inputs	: I13_Sectors_To_Trf	- Sectors just read/written
;		  I13_Sector_Number	- Starting sector number for trf
;		  I13_Head_Number	- Starting head number for trf
;		  I13_Track_Number	- Starting track number for trf
;
;	Outputs : I13_Sector_Number	- New starting sector for trf
;		  I13_Head_Number	- New starting head for trf
;		  I13_Track_Number	- New starting track for trf
;=========================================================================


I13_Adjust	proc	near			;adjust values			;an000; dms;

	push	ax				;save regs			;an000; dms;

	inc	cs:I13_Sector_Number		;next sector			;an000; dms;
	mov	al,cs:I13_Sector_Number 	;				;an000; dms;
	cmp	al,cs:I13_SPT			;> sectors on track?		;an000; dms;
	jna	I13_Adjust_Exit 		;no				;an000; dms;
		mov	cs:I13_Sector_Number,1	;yes - start at next		;an000; dms;
		inc	cs:I13_Head_Number	;next head			;an000; dms;
		mov	al,cs:I13_Head_Number	;				;an000; dms;
		cmp	al,cs:I13_Max_Head	;> head count			;an000; dms;
		jb	I13_Adjust_Exit 	;no				;an000; dms;
			 mov	 cs:I13_Head_Number,0	 ;yes - head 0	 ;an000; dms;
			 inc	 cs:I13_Track_Number	 ;next track	 ;an000; dms;

I13_Adjust_Exit:

	mov	ax,cs:I13_Paras_Per_Sector	;get bytes per sector		;an000; dms;
	add	cs:I13_Trf_Seg,ax		;adjust segment 		;an000; dms;

	pop	ax				;restore regs			;an000; dms;

	ret					;				;an000; dms;

I13_Adjust	endp				;				;an000; dms;


;=========================================================================
; I13_Invoke		- This routine sets up the regs for the INT 13h
;			  and invokes it for the sector we need.
;
;	Inputs	: I13_Operation 	- read/write
;		  I13_Track_Number	- cylinder to read/write
;		  I13_Sector_Number	- starting sector for read/write
;		  I13_Head_Number	- starting head
;		  I13_Drive_Number	- starting drive
;
;	Outputs : NC			- good read/write
;		  CY			- bad read/write
;=========================================================================

I13_Invoke	proc	near			;invoke INT 13h 		;an000; dms;

	push	bx				;save regs			;an000; dms;
	push	cx				;				;an000; dms;
	push	dx				;				;an000; dms;

	mov	ah,cs:I13_Operation		;get function call		;an000; dms;
	mov	al,cs:I13_Sectors_To_Trf	;get sectors to transfer	;an000; dms;

	mov	ch,byte ptr cs:I13_Track_Number ;get track number		;an000; dms;
	mov	cl,byte ptr cs:I13_Track_Number[+1]	;get high 2 bits	;an000; dms;
	shl	cl,1				;put bit is positions 6&7	;an000; dms;
	shl	cl,1				;				;an000; dms;
	shl	cl,1				;				;an000; dms;
	shl	cl,1				;				;an000; dms;
	shl	cl,1				;				;an000; dms;
	shl	cl,1				;				;an000; dms;
	or	cl,cs:I13_Sector_Number 	;place the sector number in cl	;an000; dms;

	mov	dh,cs:I13_Head_Number		;get head number		;an000; dms;
	mov	dl,cs:I13_Drive_Number		;get drive number		;an000; dms;
	pushf
	call	cs:IntV13			;go to old vector		;an000; dms;
	inc	cs:I13_Curr_Trf_Cnt		;increment counter		;an000; dms;

	pop	dx				;restore regs			;an000; dms;
	pop	cx				;				;an000; dms;
	pop	bx				;				;an000; dms;

	ret					;				;an000; dms;

I13_Invoke	endp				;				;an000; dms;


;=========================================================================
; I13_Get_Dev_Parms	- This routine obtains the device parameters for
;			  the drive being accessed for the INT 13h.
;
;	Inputs	: DL - drive number
;
;	Outputs : I13_Max_Head		- max head count on drive
;		  I13_SPT		- max sectors/track count for drive
;		  CY			- error
;		  NC			- no error
;=========================================================================



I13_Get_Dev_Parms	proc	near		;get sectors/track & head cnt.	;an000; dms;

	push	ax				;save regs			;an000; dms;
	push	bx				;				;an000; dms;
	push	cx				;				;an000; dms;
	push	dx				;				;an000; dms;
	push	di				;				;an000; dms;
	push	ds				;				;an000; dms;

	mov	ax,0803h			;get the BDS table		;an000; dms;
	int	2fh				;				;an000; dms;

I13_Get_Dev_Next_Entry:

	cmp	ds:[di].Drivenum,dl		;do we have our drive?		;an000; dms;
	je	I13_Get_Dev_Save_Parms		;yes get data			;an000; dms;
	cmp	word ptr ds:[di].Link[+0],-1	;last entry in list?		;an000; dms;
	je	I13_Get_Dev_Parms_Error_Exit	;yes - did not find drive	;an000; dms;
	mov	ax,word ptr ds:[di].Link[+0]	;get offset of next entry	;an000; dms;
	mov	bx,word ptr ds:[di].Link[+2]	;get segment of next entry	;an000; dms;
	mov	ds,bx				;stuff into ds:di		;an000; dms;
	mov	di,ax				;				;an000; dms;
	jmp	I13_Get_Dev_Next_Entry		;continue			;an000; dms;

I13_Get_Dev_Save_Parms:

	mov	ax,ds:[di].BytePerSec		;get byte count per sector	;an000; dms;
	mov	cs:I13_BPS,ax			;				;an000; dms;

	xor	dx,dx				;clear high word		;an000; dms;
	div	cs:I13_Bytes_Per_Para		;get number of paras in sector	;an000; dms;
	mov	cs:I13_Paras_Per_Sector,ax	;save it			;an000; dms;
	shl	ax,1				;get DD's per sector            ;an000; dms;
	shl	ax,1				;				;an000; dms;
	mov	cs:I13_DD_Per_Sector,ax 	;				;an000; dms;

	mov	ax,ds:[di].SecLim		;get sectors per track		;an000; dms;
	mov	cs:I13_SPT,al			;				;an000; dms;

	mov	ax,ds:[di].HdLim		;get max head count		;an000; dms;
	mov	cs:I13_Max_Head,al		;				;an000; dms;

	clc					;flag data found		;an000; dms;

	jmp	I13_Get_Dev_Parms_Exit		;				;an000; dms;


I13_Get_Dev_Parms_Error_Exit:

	stc					;flag no data found		;an000; dms;

I13_Get_Dev_Parms_Exit:

	pop	ds				;restore regs			;an000; dms;
	pop	di				;				;an000; dms;
	pop	dx				;				;an000; dms;
	pop	cx				;				;an000; dms;
	pop	bx				;				;an000; dms;
	pop	ax				;				;an000; dms;

	ret					;				;an000; dms;

I13_Get_Dev_Parms	endp			;				;an000; dms;


