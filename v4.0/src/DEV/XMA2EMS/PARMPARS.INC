	PAGE
;-----------------------------------------------------------------------;
;	GET_PARMS extracts parameters from the command line buffer	;
;									;
;	On entry:   all letters after 'Device=' have been changed       ;
;		    to upper case					;
;									;
;	On exit:    (zf)=0 if syntax error				;
;		    if (zf)=1 then...					;
;									;
;		    EMM_START_BLOCK has been updated			;
;									;
;		    AX,BX,CX,DX,DI,SI,DS are destroyed			;
;-----------------------------------------------------------------------;

include xma2emsp.inc			; include parser things
include parse.asm

GET_PARMS PROC
	LDS	BX,CS:RH_PTRA		;make ds:bx point to request header

	LDS	SI,RH.RH0_BPBA		;make ds:si point to bios paramter buffer
	CLD
	mov	cs:EMS_Pgs_Parm,E_Parm_Def ;default to all of memory		;an000; dms;

;-------------------------------------------------------------------
;	parser support added by GGA
;-------------------------------------------------------------------
	push	cs			; make ES:DI point to parm block
	pop	es
	lea	di,p_block

	xor	cx,cx			; cx = 0, ordinal
	xor	dx,dx			; dx = 0, reserved

	push	ds			; save ds

get_args:
	pop	ds			; restore ds
	call	SysParse		; call the parser
	cmp	ax,0			; end of line?
	je	check_frame		; no, find out what we got this time
	cmp	ax,-1			; end of parse?
	je	end_of_input_line1	; yes
		cmp	ax,-1		; flag an error
		ret			; return to caller

end_of_input_line1:

	jmp	end_of_input_line	;

;	find out which arg was processed this time

check_frame:

;	make ds point to data area for these comparisons, must restore before
;	calling parser again

	push	ds			; save ds
	push	es			; make ds point to save areas
	pop	ds

	cmp	frame_result.$P_Type,2	; was there a FRAME= in this pass?
	jne	check_p0		; no, look for a P0

	mov	parse_flag,1		; set parse flag

	mov	byte ptr frame_ctl+9,0	; turn this off so we don't allow another
	mov	frame_result.$P_Type,0	; clear this so we don't get fooled later

	mov	byte ptr p0_ctl+9,0	; turn these off so we don't allow any
	mov	byte ptr p1_ctl+9,0	; others that would conflict
	mov	byte ptr p2_ctl+9,0
	mov	byte ptr p3_ctl+9,0

	push	si						;save regs

	mov	si,word ptr frame_result.$P_Picked_Val[+0]

	mov	word ptr ds:[si+0],0				;clear the
	mov	word ptr ds:[si+4],0				;  pages
	mov	word ptr ds:[si+8],0
	mov	word ptr ds:[si+12],0

	pop	si						;restore regs


;	set flags for later code to fill in map_table

	or	page_flags,frame_flag	; set frame flag

	jmp	get_args		; go get another argument

check_p0:
	cmp	p0_result.$P_Type,2	; was there a P0= in this pass?
	jne	check_p1		; no, look for a P0

	mov	parse_flag,1		; set parse flag

	mov	byte ptr p0_ctl+9,0	; turn this off so we don't allow another
	mov	p0_result.$P_Type,0	; clear this so we don't get fooled later

	mov	byte ptr frame_ctl+9,0	; turn this off so we don't allow another

	push	si						;save regs

	mov	si,word ptr p0_result.$P_Picked_Val[+0]

	mov	word ptr ds:[si+0],0

	pop	si						;restore regs
;	set flags for later code to fill in map_table

	or	page_flags,p0_flag	; set p0 flag

	jmp	get_args		; go get another argument

check_p1:
	cmp	p1_result.$P_Type,2	; was there a p1= in this pass?
	jne	check_p2		; no, look for a P2

	mov	parse_flag,1		; set parse flag

	mov	byte ptr p1_ctl+9,0	; turn this off so we don't allow another
	mov	p1_result.$P_Type,0	; clear this so we don't get fooled later

	mov	byte ptr frame_ctl+9,0	; turn this off so we don't allow another

	push	si						;save regs

	mov	si,word ptr p1_result.$P_Picked_Val[+0]

	mov	word ptr ds:[si+0],0

	pop	si						;restore regs
;	set flags for later code to fill in map_table

	or	page_flags,p1_flag	; set p1 flag

	jmp	get_args		; go get another argument

check_p2:
	cmp	p2_result.$P_Type,2	; was there a p2= in this pass?
	jne	check_p3		; no, look for a p3

	mov	parse_flag,1		; set parse flag

	mov	byte ptr p2_ctl+9,0	; turn this off so we don't allow another
	mov	p2_result.$P_Type,0	; clear this so we don't get fooled later

	mov	byte ptr frame_ctl+9,0	; turn this off so we don't allow another

	push	si						;save regs

	mov	si,word ptr p2_result.$P_Picked_Val[+0]

	mov	word ptr ds:[si+0],0

	pop	si						;restore regs
;	set flags for later code to fill in map_table

	or	page_flags,p2_flag	; set p2 flag

	jmp	get_args		; go get another argument

check_p3:
	cmp	p3_result.$P_Type,2	; was there a p3= in this pass?
	jne	check_p254		; no, look for a P254

	mov	parse_flag,1		; set parse flag

	mov	byte ptr p3_ctl+9,0	; turn this off so we don't allow another
	mov	p3_result.$P_Type,0	; clear this so we don't get fooled later

	mov	byte ptr frame_ctl+9,0	; turn this off so we don't allow another

	push	si						;save regs

	mov	si,word ptr p3_result.$P_Picked_Val[+0]

	mov	word ptr ds:[si+0],0

	pop	si						;restore regs
;	set flags for later code to fill in map_table

	or	page_flags,p3_flag	; set p3 flag

	jmp	get_args		; go get another argument

check_p254:
	cmp	p254_result.$P_Type,2	; was there a p254= in this pass?
	jne	check_p255		; no, look for a P255

	mov	parse_flag,1		; set parse flag

	mov	byte ptr p254_ctl+9,0	; turn this off so we don't allow another
	mov	p254_result.$P_Type,0	; clear this so we don't get fooled later

	push	si						;save regs

	mov	si,word ptr p254_result.$P_Picked_Val[+0]

	mov	word ptr ds:[si+0],0

	pop	si						;restore regs
;	set flags for later code to fill in map_table

	or	page_flags,p254_flag	  ; set p254 flag

	jmp	get_args		; go get another argument

check_p255:
	cmp	p255_result.$P_Type,2	; was there a P255= in this pass?
	je	do_p255 		; yes, process it
	jmp	Check_X 		; no, find out if /X was included

do_p255:
	mov	parse_flag,1		; set parse flag

	mov	byte ptr p255_ctl+9,0	; turn this off so we don't allow another
	mov	p255_result.$P_Type,0	; clear this so we don't get fooled later

	push	si						;save regs

	mov	si,word ptr p255_result.$P_Picked_Val[+0]

	mov	word ptr ds:[si+0],0

	pop	si						;restore regs
;	set flags for later code to fill in map_table

	or	page_flags,p255_flag	; set p255 flag

	jmp	get_args		; go get another argument

Check_X:
	cmp	es:X_Result.$P_SYNONYM_Ptr,offset es:X_Switch.$P_KeyorSW ; switch Ptr	   ;an000; dms;
	je	Do_X			; yes, process it
	jmp	get_args		; no, must have been the positional, ignore it and go on

Do_X:

	push	ax			; save regs
	mov	ax,es:word ptr X_Result.$P_Picked_Val ;get low word of result	 ;an000; dms;
	mov	cs:EMS_Pgs_Parm,ax	; pass to program			;an000; dms;
	pop	ax			; restore regs

	jmp	get_args		; go get another argument




;	getting here means invalid argument, figure out what to do later

end_of_input_line:

	cmp	parse_flag,null 	; were there command line args?
	jne	cmd_line_args		; yes, process them
	jmp	null_cmd_line		; no, skip processing

cmd_line_args:

;	put the stuff into map_table, this is done by looking at flags set
;	by the above code and putting the addresses into map_table

	push	ax			; save some regs
	push	bx
	push	cx
	push	dx
	push	di

	xor	di,di			; clear index pointer

	mov	map_count,null		; clear map count default

	test	page_flags,frame_flag	; was FRAME= included?
	jz	chk_p0			; no, try p0

;	yes, fix up page count and fill in map_table

	mov	map_count,4		; FRAME= takes up 4 map entries

;	convert the item tag into a segment address

	xor	ah,ah			; make 0
	mov	al,frame_result.$P_Item_Tag	; get item tag
	mov	cx,8			; need to shift left eight bits
	shl	ax,cl			; to convert to a segment address

;	do some math with di

	xor	di,di			; clear index pointer

;	save the segment addresses in map_table

	mov	map_table.phys_page_segment[di],ax	; store p0 segment
	mov	map_table.phys_page_number[di],0	    ; p0 page number
	mov	cs:Page_Frame_Sta,ax			;save our page for XMA1 ;an000; dms;
							;  diags.

	add	ax,400h 		; increase segment ID by 16K
	add	di,type mappable_phys_page_struct

	mov	map_table.phys_page_segment[di],ax	; store p1 segment
	mov	map_table.phys_page_number[di],1	    ; p1 page number

	add	ax,400h 		; increase segment ID by 16K
	add	di,type mappable_phys_page_struct

	mov	map_table.phys_page_segment[di],ax	; store p2 segment
	mov	map_table.phys_page_number[di],2	    ; p2 page number

	add	ax,400h 		; increase segment ID by 16K
	add	di,type mappable_phys_page_struct

	mov	map_table.phys_page_segment[di],ax	; store p3 segment
	mov	map_table.phys_page_number[di],3	    ; p3 page number

;	do some math with di, this will be used as a pointer into map_table

	add	di,type mappable_phys_page_struct

	jmp	chk_p254		; FRAME= implies that p0 - p3 were not present,
					; skip ahead and look for p254 and p255

;	check for p0

chk_p0:

	test	page_flags,p0_flag	; was p0= included?
	jz	chk_p1			; no, try p1

;	yes, fix up page count and fill in map_table

	add	map_count,1		; one extra map entry

;	convert the item tag into a segment address

	xor	ah,ah			; make 0
	mov	al,p0_result.$P_Item_Tag; get item tag
	mov	cx,8			; need to shift left eight bits
	shl	ax,cl			; to convert to a segment address


;	save the segment addresses in map_table

	mov	map_table.phys_page_segment[di],ax	; store p0 segment
	mov	map_table.phys_page_number[di],0	    ; p0 page number
	mov	cs:Page_Frame_Sta,ax			;save our page for XMA1 ;an000; dms;
							;  diags.

;	do some math with di, this will be used as a pointer into map_table

	add	di,type mappable_phys_page_struct

;------------------------
;	check for p1
;------------------------

chk_p1:

	test	page_flags,p1_flag	; was p1= included?
	jz	chk_p2			; no, try p2

;	yes, fix up page count and fill in map_table

	add	map_count,1		; one extra map entry

;	convert the item tag into a segment address

	xor	ah,ah			; make 0
	mov	al,p1_result.$P_Item_Tag; get item tag
	mov	cx,8			; need to shift left eight bits
	shl	ax,cl			; to convert to a segment address


;	save the segment addresses in map_table

	mov	map_table.phys_page_segment[di],ax	; store p1 segment
	mov	map_table.phys_page_number[di],1	    ; p0 page number
	mov	cs:Page_Frame_Sta,ax			;save our page for XMA1 ;an000; dms;
							;  diags.

;	do some math with di, this will be used as a pointer into map_table

	add	di,type mappable_phys_page_struct

;------------------------
;	check for p2
;------------------------

chk_p2:

	test	page_flags,p2_flag	; was p2= included?
	jz	chk_p3			; no, try p3

;	yes, fix up page count and fill in map_table

	add	map_count,1		; one extra map entry

;	convert the item tag into a segment address

	xor	ah,ah			; make 0
	mov	al,p2_result.$P_Item_Tag; get item tag
	mov	cx,8			; need to shift left eight bits
	shl	ax,cl			; to convert to a segment address


;	save the segment addresses in map_table

	mov	map_table.phys_page_segment[di],ax	; store p2 segment
	mov	map_table.phys_page_number[di],2	    ; p2 page number
	mov	cs:Page_Frame_Sta,ax			;save our page for XMA1 ;an000; dms;
							;  diags.

;	do some math with di, this will be used as a pointer into map_table

	add	di,type mappable_phys_page_struct

;------------------------
;	check for p3
;------------------------

chk_p3:

	test	page_flags,p3_flag	; was p3= included?
	jz	chk_p254		; no, try p254

;	yes, fix up page count and fill in map_table

	add	map_count,1		; one extra map entry

;	convert the item tag into a segment address

	xor	ah,ah			; make 0
	mov	al,p3_result.$P_Item_Tag; get item tag
	mov	cx,8			; need to shift left eight bits
	shl	ax,cl			; to convert to a segment address


;	save the segment addresses in map_table

	mov	map_table.phys_page_segment[di],ax	; store p3 segment
	mov	map_table.phys_page_number[di],3	    ; p3 page number
	mov	cs:Page_Frame_Sta,ax			;save our page for XMA1 ;an000; dms;
							;  diags.

;	do some math with di, this will be used as a pointer into map_table

	add	di,type mappable_phys_page_struct

;------------------------
;	check for p254
;------------------------

chk_p254:

	test	page_flags,p254_flag	  ; was p254= included?
	jz	chk_p255		; no, try p255

;	yes, fix up page count and fill in map_table

	add	map_count,1		; one extra map entry

;	convert the item tag into a segment address

	xor	ah,ah			; make 0
	mov	al,p254_result.$P_Item_Tag; get item tag
	mov	cx,8			; need to shift left eight bits
	shl	ax,cl			; to convert to a segment address


;	save the segment addresses in map_table

	mov	map_table.phys_page_segment[di],ax	; store p254 segment
	mov	map_table.phys_page_number[di],0feh	    ; p254 page number
	mov	cs:Page_Frame_Sta,ax			;save our page for XMA1 ;an000; dms;
							;  diags.

;	do some math with di, this will be used as a pointer into map_table

	add	di,type mappable_phys_page_struct

;------------------------
;	check for p255
;------------------------

chk_p255:

	test	page_flags,p255_flag	  ; was p255= included?
	jz	Chk_X			; no, /X switch

;	yes, fix up page count and fill in map_table

	add	map_count,1		; one extra map entry

;	convert the item tag into a segment address

	xor	ah,ah			; make 0
	mov	al,p255_result.$P_Item_Tag; get item tag
	mov	cx,8			; need to shift left eight bits
	shl	ax,cl			; to convert to a segment address


;	save the segment addresses in map_table

	mov	map_table.phys_page_segment[di],ax	; store p255 segment
	mov	map_table.phys_page_number[di],0ffh	    ; p255 page number
	mov	cs:Page_Frame_Sta,ax			;save our page for XMA1 ;an000; dms;
							;  diags.

;	do some math with di, this will be used as a pointer into map_table

	add	di,type mappable_phys_page_struct

Chk_X:

	pop	di			; restore some regs
	pop	dx
	pop	cx
	pop	bx
	pop	ax


null_cmd_line:
	CMP	AL,AL			; else set zf to indicate no error
	ret				; return to calling routine


GET_PARMS ENDP
