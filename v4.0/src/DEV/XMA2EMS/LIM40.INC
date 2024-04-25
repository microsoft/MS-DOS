	page
;-------------------------------------------------------------------
;
;	Equates that are specific to LIM 4.0 functions go here
;
;-------------------------------------------------------------------

null		equ	0		; null value, used everywhere
max_phys_pages	equ	255		; largest allowable phys page

sf_pm_get	equ	0		; 4f00 - get partial map
sf_pm_set	equ	1		; 4f01 - set partial map
sf_pm_size	equ	2		; 4f02 - get partial map size

mu_ppn		equ	0		; 5000 - map/unmap multiple
mu_seg		equ	1		; 5001 - map/unmap multiple
mu_max_fcn	equ	1		; 50 - map/unmap multiple

Hn_Attr_Max_Fcn equ	2		; 52xx - max subfunction		;an000; dms;

sf_hn_get	equ	0		; 5300 - get handle name
sf_hn_set	equ	1		; 5301 - set handle name
hn_max_fcn	equ	1		; 53 - handle name sub-functions 00, 01

sf_hd_get	equ	0		; 5400 - get handle dir
sf_hd_search	equ	1		; 5401 - search for named handle
sf_hd_total	equ	2		; 5402 - get total number of handles
hd_max_fcn	equ	2		; 54 - get handle directory s-f's 00, 01, 02

Add_Get_Array	equ	0		; 5800 - Get Mappable Physical Address Array
Add_Get_Size	equ	1		; 5801 - Get Mappable Physical Address Array Entries

hi_info 	equ	0		; 5900 - hardware info
hi_raw		equ	1		; 5901 - # raw pages

am_get		equ	0		; 5b00 - get alternate map register set
am_set		equ	1		; 5b01 - set alternate map register set
am_size 	equ	2		; 5b02 - get alternate map save array size
am_alloc	equ	3		; 5b03 - allocate alternate map register set
am_dealloc	equ	4		; 5b04 - deallocate alternate map register set
am_dma_alloc	equ	5		; 5b05 - allocate DMA register set
am_dma_enable	equ	6		; 5b06 - enable DMA register set
am_dma_disable	equ	7		; 5b07 - disable DMA register set
am_dma_dealloc	equ	8		; 5b08 - deallocate DMA register set

os_enable	equ	0		; 5d00 - enable OS/E function
os_disable	equ	1		; 5d01 - disable OS/E function
os_access	equ	2		; 5d02 - "return" access key function

map_pages_fcn	equ	44h		; function code used to map pages
get_free_pages	equ	42h		; function code used to get free page count

read_clock	equ	2ch		; function code to read clock
dos_int 	equ	21h		; interrupt 21
xor_mask	equ	0ffffh		; mask used to confuse the random numbers a little

ppm_struct	STRUC			; define the structure
phys_page_offset	dw	?	; offsets into PPM entry
ppm_handle_offset	dw	?
ppm_log_page_offset	dw	?
ppm_struct	ENDS

	page
;-------------------------------------------------------------------
;
;	4F - get/set partial page map
;
;	INPUT:
;		AL	=	00, get partial page map	pm_get
;				01, set partial page map	pm_set
;				02, get partial page map size	pm_size
;
;	OUTPUT:
;		See individual function headers
;
;-------------------------------------------------------------------
partial_map	proc

;	use AL value to select sub-function

	cmp	al,sf_pm_get		; al = 00, get partial page map
	je	pm_get

	cmp	al,sf_pm_set		; al = 01, set partial page map
	je	pm_set

	cmp	al,sf_pm_size		; al = 02, get partial page map size
	jne	pm_invalid_sfcn
	jmp	pm_size


;	invalid sub-function, report the error

pm_invalid_sfcn:
	mov	ah,ems_code8F		; invalid sub-function code
	ret

	page
;-------------------------------------------------------------------
;
;	4F00 - get partial page map
;
;	INPUT:
;		DS:SI	->	partial page map
;
;				dw	?	; segment count (number
;						;   of following entries)
;				dw	?	; segment address to save
;				:		;   (repeats count times)
;				:
;
;		ES:DI	->	user array for mapping info
;				size determined by function 4F02
;
;
;	OUTPUT:
;		AH	=	00,  No error
;				80H, Software error
;				81H, Hardware error
;				84H, Invalid function
;				8FH, Invalid sub-function
;				A3H, Contents of control structure are invalid
;
;		ES:DI	->	saved partial state array
;				format for this is un-disclosed to the user
;				but will be:
;
;			ppm_count	dw	?	; number of saved entries
;			ppm_phys_page	dw	?	; physical page
;			ppm_handle	dw	?	; handle
;			ppm_log_page	dw	?	; logical page
;			:				; repeats for each requested page
;			:
;
;
;-------------------------------------------------------------------
pm_get:

	push	bx			; save some regs
	push	cx
	push	dx
	push	di
	push	si
	push	ds

	mov	di,cs:[bp].IE_Saved_DI_Reg ; restore caller's DI, pointer to mapping control structure


;-------------------------------------------------------------------

;	get count from caller's control structure

	mov	cx,ds:[si]		; the first word of the control
					; structure holds the # of entries

	cmp	cx,0			; 0 pages requested?			;an000; dms;
	je	PM_Get_Error_A3 	; yes - flag an error			;an000; dms;

	cmp	cx,cs:Map_Count 	; do some sanity checking
	jbe	pm_phys_ok		; requested number is ok, do the copies

; They asked for more than we can possibly have.  Sounds like trouble.

PM_Get_Error_A3:

	mov	ah,ems_codea3		; bad stuff in the control structure
	jmp	pm_exit00		; return the error code

pm_phys_ok:
	mov	cx,DS:word ptr [si]	; get count from control structure
	mov	ES:word ptr [di],cx	; save count in save area
	add	di,2			; increment save area pointer

;-------------------------------------------------------------------
;
;	everything is OK so far, copy the entries requested
;
;-------------------------------------------------------------------

ppm_copies:

	add	si,2			; point to next segment number
	mov	ax,DS:word ptr [si]	; get segment value from control structure

	push	si			; save user's si
	push	ds			; save user's ds
	push	cx			; save counter for outer loop

; ready to do the lookup and copy operation

	push	cs			; make DS:SI point to internal data area
	pop	ds
	lea	si,map_table

	mov	cx,map_count		; number of mappable segments

ppm_inner_copy_loop:
	cmp	ax,ds:word ptr [si+phys_page_segment]	; is this entry the requested?
	jne	ppm_not_yet		; no, try again

	mov	cx,ppm_size		; number of bytes to copy
	cld				; make sure direction flag is right
	add	si,2			; point to phys_page_number

	rep	movsb			; copy the entry

	sub	si,2			; reset si

	jmp	ppm_entry_done		; done with this copy, go on

ppm_not_yet:
	add	si,type mappable_phys_page_struct	; point to next entry
	loop	ppm_inner_copy_loop	; try some more

	pop	cx			; restore counter for outer loop
	pop	ds			; restore user's ds
	pop	si			; restore user's si
	mov	ah,EMS_Code8B		; we have an invalid segment specified	;an000; dms;
	jmp	PM_Exit00		; exit the program

ppm_entry_done:

; restore pointer to control structure

	pop	cx			; restore counter for outer loop
	pop	ds			; restore user's ds
	pop	si			; restore user's si


	loop	ppm_copies		; keep going until proper number of
					; entries have been copied

	xor	ah,ah			; good return code
;-------------------------------------------------------------------
pm_exit00:
	pop	ds			; restore these registers
	pop	si
	pop	di
	pop	dx
	pop	cx
	pop	bx

	ret				; return to caller



	page
;-------------------------------------------------------------------
;
;	4F01 - set partial page map
;
;	INPUT:
;		DS:SI	->	source array
;				Format:
;
;			ppm_count	dw	?	; number of saved entries
;			ppm_phys_page	dw	?	; physical page
;			ppm_handle	dw	?	; handle
;			ppm_log_page	dw	?	; logical page
;			:				; repeats ppm_count times
;			:
;
;
;	OUTPUT:
;		AH	=	00,  No error
;				80H, Software error
;				81H, Hardware error
;				84H, Invalid function
;				8FH, Invalid sub-function
;				A3H, Contents of source array invalid
;
;-------------------------------------------------------------------
pm_set:

	push	bx			; save some regs
	push	cx
	push	dx
	push	di
	push	si
	push	ds

	mov	cx,DS:word ptr [si]	; get number of entries in save area

	cmp	cx,0			; is the count zero?
	je	pm_set_error_A3 	; yes - error				;an000; dms;

	cmp	cx,cs:Map_Count 	; greater than phys pages avail?	;an000; dms;
	jbe	count_ok		; no - data not corrupted		;an000; dms;

pm_set_error_A3:

	mov	ah,EMS_CODEA3		; control structure error
	jmp	pm_exit01		; exit

count_ok:
	add	si,2			; point to first entry in save area

pm01_loop:

	mov	ax,DS:word ptr [si+phys_page_offset]	; set up regs for map_l_to_p
	mov	ah,map_pages_fcn
	mov	dx,DS:word ptr [si+ppm_handle_offset]
	mov	bx,DS:word ptr [si+ppm_log_page_offset]

	cmp	dx,0ffffh		; is there a real entry?
	je	no_map			; no, skip the call to map_l_to_p

	call	map_l_to_p		; make the mapping call

no_map:
	add	si,type ppm_struct	; point to next entry

	loop	pm01_loop		;

	xor	ah,ah			; good return code
pm_exit01:

	pop	ds			; restore these registers
	pop	si
	pop	di
	pop	dx
	pop	cx
	pop	bx

	ret				; return to caller


	page
;-------------------------------------------------------------------
;
;	4F02 - get partial page map size
;
;	INPUT:
;		AX	=	4f02h
;
;		BX	=	number of pages in partial page map
;
;	OUTPUT:
;		AH	=	00,  No error
;				80H, Software error
;				81H, Hardware error
;				84H, Invalid function
;				8FH, Invalid sub-function
;
;		AL	=	size of partial page map save array
;				number of bytes that will be needed
;				to save the requested number of pages
;
;-------------------------------------------------------------------
pm_size:

	push	dx			; save dx

	cmp	bx,0			; 0 pages requested?			;an000; dms;
	je	PM_Size_Error_8B	; yes flag an error			;an000; dms;

	cmp	bx,cs:Map_Count 	; page count > phys pages?		;an000; dms;
	jbe	PM_Size_Return		; no - continue 			;an000; dms;

PM_Size_Error_8B:

	mov	ah,EMS_Code8B		; signal page count exceeded		;an000; dms;
	jmp	PM_Exit02		; exit routine				;an000; dms;

PM_Size_Return:

	mov	dx,bx			; number of pages times ...
	mov	ax,ppm_size		; * size of an entry ...
	mul	dx			; = number of bytes in save array
	add	ax,2			; increase by 2 to include count word

	xor	ah,ah			; good return code

pm_exit02:
	pop	dx			; restore dx

	ret				; return to caller

partial_map	endp


	page
;-------------------------------------------------------------------
;
;	50 - map/unmap multiple handle pages
;
;	INPUT:
;		AH	=	00	physical page numbers
;				01	segment numbers
;
;-------------------------------------------------------------------
map_mult	proc

	cmp	al,mu_ppn		; is this a map request?
	je	mu_ppn_fcn		; yes, go do it

	cmp	al,mu_seg		; no, is this an unmap request?
	je	mu_seg_fcn		; yes, go do it

	xor	al,al			; clear al, why not?
	mov	ah,ems_code8f		; no, return invalid sub-function code
	ret				; return to caller

;-------------------------------------------------------------------
;
;	5000 - map/unmap multiple handle pages using physical page numbers
;
;	INPUT:
;		AX	=	5000h
;
;		DX	=	handle
;
;		CX	=	num entries in control structure
;
;		DS:SI	->	points to control structure
;				Format:
;
;			log_pg_num	dw	?	; logical page number
;			phys_pg_num	dw	?	; physical page number
;			:				; repeats CX times
;			:
;
;	OUTPUT:
;
;		AH	=	00,  No error
;				80H, Software error
;				81H, Hardware error
;				83H, Invalid handle
;				84H, Invalid function
;				8AH, Invalid logical page
;				8BH, Invalid physical page
;				8FH, Invalid sub-function
;
;-------------------------------------------------------------------

mu_ppn_fcn:

	push	bx			; save regs				;an000; dms;
	push	cx			; save count
	push	dx			;					;an000; dms;
	push	si			; save pointer

	xor	ah,ah			; good return code
	cmp	cx,0			; is count 0?
	je	mu_ppn_exit

mu_ppn_loop:
	mov	bx,ds:word ptr[si+0]	; get logical page number
	mov	ax,ds:word ptr[si+2]	; get physical page number
	mov	ah,map_pages_fcn	; fcn code for mapping

	push	cx
	call	map_l_to_p		; call the mapping routine
	pop	cx

	cmp	ah,0			; was return code OK
	jne	mu_ppn_error

	add	si,4			; point to next entry

	loop	mu_ppn_loop		; do it again

	xor	ah,ah			; good return code
	jmp	mu_ppn_exit

mu_ppn_error:
mu_ppn_exit:
	pop	si			; restore pointer
	pop	dx			;					;an000; dms;
	pop	cx			; restore count
	pop	bx			; restore regs				;an000; dms;

	ret				; return to caller


;-------------------------------------------------------------------
;
;	5001 - map/unmap multiple handle pages using segment addresses
;
;	INPUT:
;		AX	=	5001h
;
;		DX	=	handle
;
;		CX	=	num entries in control structure
;
;		DS:SI	->	points to control structure
;				Format:
;
;			log_pg_num	dw	?	; logical page number
;			seg_address	dw	?	; physical segment address
;			:				; repeats CX times
;			:
;
;	OUTPUT:
;
;		AH	=	00,  No error
;				80H, Software error
;				81H, Hardware error
;				83H, Invalid handle
;				84H, Invalid function
;				8AH, Invalid logical page
;				8BH, Invalid physical page
;				8FH, Invalid sub-function
;
;-------------------------------------------------------------------

mu_seg_fcn:

	push	bx			; save regs				;an000; dms;
	push	cx			; save count
	push	dx			;					;an000; dms;
	push	si			; save pointer

	xor	ah,ah			; good return code
	cmp	cx,0			; is count 0?
	je	mu_seg_exit

mu_seg_loop:
	mov	bx,ds:word ptr[si+0]	; get logical page number

	push	dx			; save handle
	mov	dx,ds:word ptr[si+2]	; get physical page number
	call	Get_Phys_Seg_Page	; convert to logical page circle
	mov	ax,dx			; must be in AX
	pop	dx			; restore handle

	mov	ah,map_pages_fcn	; fcn code for mapping

	push	cx
	call	map_l_to_p		; call the mapping routine
	pop	cx

	cmp	ah,0			; was return code OK
	jne	mu_seg_error

	add	si,4			; point to next entry

	loop	mu_seg_loop		; do it again

	xor	ah,ah			; good return code
	jmp	mu_seg_exit

mu_seg_error:
mu_seg_exit:
	pop	si			; restore pointer
	pop	dx			;					;an000; dms;
	pop	cx			; restore count
	pop	bx			; restore regs				;an000; dms;

	ret				; return to caller

map_mult	endp

;-------------------------------------------------------------------
include lim40b.inc
;-------------------------------------------------------------------

	page
;-------------------------------------------------------------------
;
;	52 - get/set handle attributes
;
;	The LIM 4.0 spec strongly advises EMS implementers to avoid this
;	call.  Our current implementation of this function is not to provide
;	support.  Possibly in future releases it will be supported, if
;	the proper hardware becomes available.
;
;	DMS	4/29/88
;
;-------------------------------------------------------------------
handle_attrib	proc


	cmp	al,Hn_Attr_Max_Fcn	;maximum subfunction number		;an000; dms;
	jbe	Handle_Attrib_Cont	;continue routine			;an000; dms;
		mov	ah,EMS_Code8F	;we have an invalid subfunction 	;an000; dms;
		jmp	Handle_Attrib_Exit ; exit the routine			;an000; dms;

Handle_Attrib_Cont:

	mov	ah,EMS_Code91		;this function is not supported 	;an000; dms;

Handle_Attrib_Exit:

	RET				; return to caller

handle_attrib	endp

	page
;-------------------------------------------------------------------
;
;	53 - get/set handle name
;
;      Virtual Mode Note:  The Handle Name functions (53 and 54) will	   @RH6
;   be handled differently when running on a system in virtual mode.	   @RH6
;   This is to accommadate the Workstation Program's bank switching.       @RH6
;   In this case, handle names and ID's will only be returned for          @RH6
;   handles allocated in the same PC bank, or for handles in bank 0.	   @RH6
;   Bank 0 is for device drivers, system extensions, or applications	   @RH6
;   that install resident before WSP loads.				   @RH6
;      When interfacing with handles in bank 0, one must be aware of	   @RH6
;   the problem of two PC applications running simultaneously that	   @RH6
;   get the handle ID of the resident program and map its pages.	   @RH6
;   Data corruption will occur if both map and write to the same page	   @RH6
;   at the same time.							   @RH6
;      While these new LIM 4.0 functions will return info only for	   @RH6
;   bank 0 and the current bank, the existing LIM 3.2 functions will	   @RH6
;   continue to return total system values.  For example, function 4B	   @RH6
;   will return the number of active handles in all banks.		   @RH6
;
;	INPUT:
;		AL	=	sub-function code
;				00 = get handle name		hn_get
;				01 = set handle name		hn_set
;
;		DX	=	handle
;
;		ES:DI	->	Get caller's name buffer (8 char's)
;		DS:SI	->	Set caller's name buffer (8 char's)
;
;
;	OUTPUT:
;		AH	=	00,  No error
;				80H, Software error
;				81H, Hardware error
;				83H, Handle not found
;				84H, Invalid function
;				8FH, Invalid sub-function
;
;		AL	=	0
;
;
;	gga	8/21/87
;
;-------------------------------------------------------------------

	Null_Handle_Name     db  8 dup(0)    ;null handle value 		;an000; dms;

handle_name	proc

	push	bx			; save some regs
	push	cx
	push	dx
	push	di
	push	si
	push	ds

	PUSH	CS			;Set addressability to our tables  @RH8
	POP	DS			;Must restore DS for Set name	   @RH8

	cmp	al,hn_max_fcn		; al = 00 or 01, anything else = error
	jbe	hn_val_sf

;	invalid sub-function, report the error

	mov	ah,ems_code8F		; invalid sub-function code
	jmp	hn_exit 		; exit

;	check the handle for valid range

hn_val_sf:

	cmp	dx,num_handles-1	; handle within range ?
	jnae	hn_range_ok		; yes, get down to business

	mov	ah,ems_code83		; handle not found
	jmp	hn_exit 		; exit

;------------------------
;	handle is within valid range, now see if it is valid handle (i.e. in use)

hn_range_ok:

	push	ax			; save fcn code
	push	dx			; save handle

	MOV	AX,DX			;DX = handle id
	MOV	DX,TYPE H_LOOKUP_STRUC	;DI = entry's offset into
	MUL	DX			; the handle lookup table
	MOV	DI,AX			;
	POP	DX			; restore handle
	POP	AX			; restore fcn code

	CMP	HANDLE_LOOKUP_TABLE.H_PAGES[DI],REUSABLE_HANDLE
	JNE	HN_IN_USE		;Is this handle valid (in use)?
					; No...error
	mov	ah,ems_code83		; handle not found
	jmp	hn_exit 		; return the error code

HN_IN_USE:				;Check bank ID if in virutal mode

	mov	bx,ax			;save ax				;an000; dms;
	TEST	MEMCARD_MODE,WSP_VIRT	;If using a card in virtual mode   @RH6
	JZ	HN_VALID		; (i.e. bank swapping), then read  @RH6
	MOV	DX,IDREG		; the current bank ID.		   @RH6
	IN	AL,DX			;				   @RH6
	CMP	HANDLE_LOOKUP_TABLE.H_BANK[DI],AL  ;If handle's bank ID    @RH6
	JE	HN_VALID			   ; is 0 (resident) or    @RH6
	CMP	HANDLE_LOOKUP_TABLE.H_BANK[DI],0   ; = requesters bank	   @RH6
	JE	HN_VALID			   ; then OK		   @RH6
					;Else invalid requester bank	   @RH6
	MOV	AH,EMS_CODE83		;Indicate handle not found	   @RH6
	JMP	HN_EXIT

;------------------------
;	find out if get or set operation

hn_valid:
	mov	ax,bx			;restore ax				;an000; dms;
	cmp	al,sf_hn_get		; al = 00 means GET
	je	hn_get

	cmp	al,sf_hn_set		;    = 01 means SET
	je	hn_set

;	invalid sub-function, report the error

	mov	ah,ems_code8F		; invalid sub-function code
	jmp	hn_exit 		; exit



	page
;-------------------------------------------------------------------
;
;	5300 - GET sub-function
;	       ES:DI -> User's area where name is stored
;-------------------------------------------------------------------
hn_get:
					;Here DI = offset into h lookup
	LEA	SI,HANDLE_LOOKUP_TABLE	;Set the source SI to the handle's
	ADD	SI,DI			; name field in the handle lookup
	ADD	SI,H_NAME		; lookup table

	MOV	DI,cs:[bp].IE_Saved_DI_Reg  ;Restore the user's dest where
					; the handle name will be stored

	MOV	CX,8			; want to copy 8 characters
	CLD				; make sure direction flag is right
	REP	MOVSB			; copy the string

	XOR	AH,AH			; set good return code
	JMP	HN_EXIT 		; exit


	page
;-------------------------------------------------------------------
;
;	5301 - SET sub-function
;	       DS:SI -> User's area where name comes from
;
;-------------------------------------------------------------------

hn_set:

	POP	DS			;Restore the user's source where   @RH6
	PUSH	DS			; the handle name will come from


;------------------------
	push	si			;save regs				;an000; dms;
	push	di			;					;an000; dms;
	push	cx			;					;an000; dms;
	push	es			;					;an000; dms;

	push	cs			;swap segs for compare			;an000; dms;
	pop	es			;					;an000; dms;

	mov	di,offset cs:Null_Handle_Name	;point to null handle name	;an000; dms;
	mov	cx,8			;8 bytes to compare			;an000; dms;
	cld
	cli				;ints off				;an000; dms;
	rep	cmpsb			;null string entered?			;an000; dms;
	sti				;ints on				;an000; dms;

	pop	es			;restore regs				;an000; dms;
	pop	cx			;					;an000; dms;
	pop	di			;					;an000; dms;
	pop	si			;					;an000; dms;
	je	HN_Set_Null_Entered	;continue - don't look for match        ;an000; dms;

	push	dx
	call	hd_named_handle 	; find out if name is in use
	pop	dx

	cmp	ah,0			; is return code good
	je	name_in_use

HN_Set_Null_Entered:

;------------------------
					;Here DI = offset into h lookup
	ADD	DI,OFFSET HANDLE_LOOKUP_TABLE  ;Set the dest. DI to the    @RH6
	ADD	DI,OFFSET H_NAME	       ; handle's name field in    @RH6
					       ; the handle lookup table   @RH6

	PUSH	ES			;Make ES:DI -> destination in
	PUSH	CS			; the handle lookup table where
	POP	ES			; the name will be stored

	mov	cx,8			; want to copy 8 characters
	cld				; clear DF to auto-increment
	rep	movsb			; copy the string

; all done with the SET function, set good return code and exit

	pop	es			; restore user's ES
	xor	ax,ax			; set good return code
	jmp	hn_exit


;------------------------
name_in_use:
	mov	ah,ems_codea1		; name is use error


hn_exit:
	pop	ds			; restore these registers
	pop	si
	pop	di
	pop	dx
	pop	cx
	pop	bx

	ret

handle_name	endp



	page
;-------------------------------------------------------------------
;
;	54 - get handle directory
;
;	SUB-FCNS:
;		AL	=	00, get handle directory	hd_directory
;				01, search for named handle	hd_named_handle
;				02, get total handles		hd_total_handles
;
;-------------------------------------------------------------------
handle_dir	proc

	cmp	al,sf_hd_get		; 00 get handle dir
	je	hd_directory

	cmp	al,sf_hd_search 	; 01 search for named handle
	je	hd_named_handle

	cmp	al,sf_hd_total		; 02 get total number of handles
	jne	hd_invalid_sfcn 	; must be an invalid function code

	jmp	hd_total_handles	; go display total handles


;	invalid sub-function, report the error

hd_invalid_sfcn:
	mov	ah,ems_code8F		; invalid sub-function code

;	invalid sub-function, fall through to exit

hd_exit:

	ret


;-------------------------------------------------------------------
;	5400 - get handle directory
;
;
;	INPUT:
;		AL	=	00, get handle directory
;
;		ES:DI	->	caller's buffer for handle directory
;
;	OUTPUT:
;		AH	=	00H, no error
;				80H, software error
;				81H, hardware error
;				84H, invalid function
;				8FH, invalid subfunction
;
;		AL	=	number of entries in handle directory
;
;		ES:DI	->	handle directory
;
;				dw	?		; handle number
;				db	8 dup(?)	; handle name
;				:
;				:			; repeats AL times
;
;-------------------------------------------------------------------
hd_directory:

	push	bx			; save some regs
	push	cx
	push	dx
	push	di
	push	si
	push	ds

	TEST	MEMCARD_MODE,WSP_VIRT	;If using a card in virtual mode   @RH6
	JZ	HD_LOOP_INIT		; (i.e. bank swapping), then read  @RH6
	MOV	DX,IDREG		; the current bank ID and save it. @RH6
	IN	AL,DX			;				   @RH6
	MOV	cs:BANKID,AL


;	initialize some things for the loop
HD_LOOP_INIT:
	mov	di,cs:[bp].IE_Saved_DI_Reg ;restore users DI			;an000; dms;
	xor	al,al			; al = num entries
	xor	dx,dx			; dx = handle index
	mov	cx,NUM_HANDLES		; loop enough for all handles
	cld				; make sure direction flag cleared

	push	cs			; get cs
	pop	ds			; into ds
	XOR	SI,SI			; SI = offset into handle lookup   @RH6
					;  table
hd_loop:
	CMP	HANDLE_LOOKUP_TABLE.h_pages[SI],REUSABLE_HANDLE
					; If handle not active, then	   @RH6
	je	hd_next_hndl		; loop and look again
;-------------------------
;    Active handle...if in virtual mode check bank ID			   @RH6
;-------------------------

	TEST	MEMCARD_MODE,WSP_VIRT	;If using a card in virtual mode   @RH6
	JZ	HD_ACTIVE		; (i.e. bank swapping), then check @RH6
	MOV	BL,cs:BANKID		; handle's bank id                 @RH6
	CMP	HANDLE_LOOKUP_TABLE.H_BANK[SI],BL  ;If handle's bank ID    @RH6
	JE	HD_Active			   ; is 0 (resident) or    @RH6
	CMP	HANDLE_LOOKUP_TABLE.H_BANK[SI],0   ; = requesters bank	   @RH6
	JE	HD_Active			   ; then OK		   @RH6
	jmp	HD_Next_Hndl			   ;Else skip to next one  @RH6

;------------------------
;	found an active handle, copy info to directory
;------------------------
hd_active:
	mov	es:word ptr[di],dx	; put handle number in directory
	add	di,2			; move directory table pointer along,
					; must point to area for handle name now

	push	cx			; save counter for outer loop
	push	si			; save si for outer loop

	mov	cx,8			; need to copy 8 chars
	add	si,offset Handle_LookUp_Table	;point to entry 		;an000; dms;
	add	si,h_name		; make DS:SI -> handle name in lookup table

rep	movsb				; copy the string

	pop	si			; restore si for outer loop
	pop	cx			; restore counter for outer loop
	inc	al			; increment entry count

;------------------------
;	done with the copy
;------------------------

hd_next_hndl:
	inc	dx			; update handle index
	add	si,type h_lookup_struc	; point to next entry in lookup table
	loop	hd_loop 		; look for more

	xor	ah,ah			; good return code

;	all done, fall through to exit

hd_exit00:

	pop	ds			;restore these registers
	pop	si
	pop	di
	pop	dx
	pop	cx
	pop	bx

	ret



	page
;-------------------------------------------------------------------
;
;	5401 - Search for named handle sub-function
;
;
;	INPUT:
;		AL	=	01, search for named handle
;
;		DS:SI	=	Pointer to handle name to search for
;
;
;	OUTPUT sub-fcn 01:	Search for named handle
;
;		AH	=	00H, no error
;				80H, software error
;				81H, hardware error
;				84H, invalid function
;				8FH, invalid subfunction
;				A0H, no matching handle found
;				A1H, duplicate handle found
;
;		DX	=	value of named handle
;
;-------------------------------------------------------------------

hd_named_handle:

	push	bx			; save some regs
	push	cx
	push	di
	push	si
	push	ds
	push	es								;an000; dms;

	TEST	MEMCARD_MODE,WSP_VIRT	;If using a card in virtual mode   @RH6
	JZ	HD1_LOOP_INIT		; (i.e. bank swapping), then read  @RH6
	MOV	DX,IDREG		; the current bank ID and save it. @RH6
	IN	AL,DX			;				   @RH6
	MOV	cs:BANKID,AL


;	initialize some things for the loop
HD1_LOOP_INIT:
	xor	ah,ah			; good return code
	xor	dx,dx			; dx = handle index
	mov	cx,NUM_HANDLES		; loop enough for all handles
	cld				; make sure direction flag cleared

	push	cs			; get cs
	pop	es			; into es
	XOR	DI,DI			; DI = offset into handle lookup   @RH6
					;  table			   @RH6
hd1_loop:
	CMP	ES:HANDLE_LOOKUP_TABLE.h_pages[DI],REUSABLE_HANDLE
					; If handle not active, then	   @RH6
	je	hd1_next_hndl		; loop and look again
;-------------------------
;    Active handle...if in virtual mode check bank ID			   @RH6
;-------------------------

	TEST	MEMCARD_MODE,WSP_VIRT	;If using a card in virtual mode   @RH6
	JZ	HD1_ACTIVE		; (i.e. bank swapping), then check @RH6
	MOV	BL,cs:BANKID		; handle's bank id                 @RH6
	CMP	ES:HANDLE_LOOKUP_TABLE.H_BANK[DI],BL ;If handle's bank ID  @RH6
	JE	HD1_Active			     ; is 0 (resident) or  @RH6
	CMP	ES:HANDLE_LOOKUP_TABLE.H_BANK[DI],0  ; = requesters bank   @RH6
	JE	HD1_Active			   ; then OK		   @RH6
	jmp	HD1_Next_Hndl			   ;Else skip to next one  @RH6
;------------------------
;	found an active handle, check the name
;------------------------

HD1_ACTIVE:
	push	cx			; save counter for outer loop
	push	si			; save si for outer loop
	push	di			; save di for outer loop

	mov	cx,8			; need to compare 8 chars
	add	di,offset Handle_LookUp_Table	;point to entry 		;an000; dms;
	add	di,offset H_Name	; must point to area for handle name now;an000; dms;

rep	cmpsb				; compare the strings

	pop	di			; restore di for outer loop
	pop	si			; restore si for outer loop
	pop	cx			; restore counter for outer loop
	je	hd_exit01		; found a match, exit

;------------------------
;	done with the check
;------------------------

hd1_next_hndl:
	inc	dx			; update handle index
	add	di,type h_lookup_struc	; point to next entry in lookup table
	loop	hd1_loop		; look for more



;	all done, if we fall through loop without finding a match,
;	must report the error

	mov	ah,ems_codea0		; no matching handle
	xor	dx,dx			; invalid handle

hd_exit01:


	pop	es			;restore these registers		;an000; dms;
	pop	ds
	pop	si
	pop	di
	pop	cx
	pop	bx

	ret



	page
;-------------------------------------------------------------------
;
;	5402 - Get total handles sub-function
;
;	INPUT:
;		AL	=	02, get total handles
;
;
;	OUTPUT:
;		AH	=	00H, no error
;				80H, software error
;				81H, hardware error
;				84H, invalid function
;				8FH, invalid subfunction
;
;		BX	=	total number of handles (includes OS handle, 0)
;
;-------------------------------------------------------------------

hd_total_handles:

	mov	bx,NUM_HANDLES		; return number of handles
	xor	ah,ah			; good return code

;	all done, fall through to exit

hd_exit02:

	ret				; return to caller

handle_dir	endp

	page
;-------------------------------------------------------------------
;
;	58 - Get mappable physical address array
;
;
;	INPUT:
;		AX	=	5800h
;
;		ES:DI	->	mappable physical array address
;
;	OUTPUT:
;		AH	=	00,  no error
;				80H, software error
;				81H, hardware error
;				84H, invalid function
;				8FH, invalid subfunction
;
;		CX	=	number of entries returned in the table below
;
;		ES:DI	->	DW	?	; phys_page_segment
;				DW	?	; phys_page_number
;				:
;				:		; repeats CX times
;
;-------------------------------------------------------------------
address_array	proc

	cmp	al,Add_Get_Array	; subfunction 00 Get Mappable Physical	;an000; dms;
					;    Address Array
	je	Address_Get_Physical_Address

	cmp	al,Add_Get_Size 	; subfunction 01 Get Mappable Physical	;an000; dms;
					;    Address Array Entries
	je	Address_Get_Size_Entries

	mov	ah,EMS_Code8F		; none of the above - invalid sub parm	;an000; dms;

	ret


Address_Get_Physical_Address:

	push	si			; save some regs
	push	di			; save di				;an000; dms;
	push	ds			; save DS


;	set up some things for the loop

	mov	di,cs:[bp].IE_Saved_DI_Reg ; restore caller's DI, pointer to handle area

	mov	cx,map_count		; number of entries in table

	push	cs			; make DS:SI -> array
	pop	ds

	lea	si,map_table

	cld				; make sure direction flag is right

copy_address_array:

	mov	ax,DS:[si+phys_page_segment]
	mov	ES:[di],ax
	add	di,2			; increment destination pointer
	mov	ax,DS:[si+phys_page_number]
	mov	ES:[di],ax

	add	si,type mappable_phys_page_struct ; increment pointer
	add	di,2			; increment destination pointer

	loop	copy_address_array

	mov	cx,map_count		; number of entries
	xor	ah,ah			; good return code

	pop	ds			; restore DS
	pop	di			; restore di
	pop	si			; restore SI

	RET				; return to caller

Address_Get_Size_Entries:

	mov	cx,cs:Map_Count 	; return the number of pages allocated	;an000; dms;
	xor	ax,ax			; clear error flag			;an000; dms;
	ret				; return to caller			;an000; dms;


address_array	endp



	page
;-------------------------------------------------------------------
;
;	59 - Get extended momory hardware information
;
;-------------------------------------------------------------------
hardware_info	proc

	cmp	ose_functions,ose_enabled	; first, check for fcns enabled
	je	hi_enabled		;


	mov	ah,EMS_CODEA4		; access denied
	jmp	hi_exit 		; exit

hi_enabled:
	cmp	al,hi_info		; 5900 - hardware info fcn
	je	hi_info_fcn

	cmp	al,hi_raw		; 5901 - unallocated raw page count
	je	hi_raw_fcn

	mov	ah,EMS_CODE8F		; invalid sub-function

hi_exit:
	RET				; return to caller


	page
;-------------------------------------------------------------------
;
;	hi_info_fcn
;
;-------------------------------------------------------------------

hi_info_fcn:

	mov	di,cs:[bp].IE_Saved_DI_Reg ; get di register

	mov	es:word ptr[di+0],1024	; raw page size = 16KB
	mov	es:word ptr[di+2],0	; number of alternate register sets
	mov	es:word ptr[di+4],type H_SAVE_STRUC ; size of save array
	mov	es:word ptr[di+6],0	; number of DMA register sets
	mov	es:word ptr[di+8],1	; 1 = no special DMA register sets

	xor	ah,ah			; good return code
	ret				; return to caller

	page
;-------------------------------------------------------------------
;
;	hi_raw_fcn
;
;-------------------------------------------------------------------

hi_raw_fcn:

	mov	ah,get_free_pages	; function code to get free pages

	call	q_pages 		; pass this one through, since our
					; raw pages = 16 KB
					; this fcn returns exacly the same
					; regs as are needed here

	ret				; return to caller

hardware_info	endp

	page
;-------------------------------------------------------------------
;
;	5B - alternate map register set
;
;-------------------------------------------------------------------

	AM_ES_Save	dw	0		;ES save variable		;an000; dms;
	AM_DI_Save	dw	0		;DI save variable		;an000; dms;
	AM_Set_Flag	db	0		;set called flag		;an000; dms;

alternate_map	proc

	cmp	ose_functions,ose_enabled	; first, check for fcns enabled
	je	am_enabled		;


	mov	ah,EMS_CODEA4		; access denied
	jmp	am_exit 		; exit

am_enabled:
	cmp	al,am_get		; 5b00 - get alternate map register set
	je	_am_get

	cmp	al,am_set		; 5b01 - set alternate map register set
	je	_am_set

	cmp	al,am_size		; 5b02 - get alternate map save array size
	je	_am_size

	cmp	al,am_alloc		; 5b03 - allocate alternate map register set
	je	_am_alloc

	cmp	al,am_dealloc		; 5b04 - deallocate alternate map register set
	je	_am_dealloc

	cmp	al,am_dma_alloc 	; 5b05 - allocate DMA register set
	je	_am_dma_alloc

	cmp	al,am_dma_enable	; 5b06 - enable DMA register set
	je	_am_dma_enable

	cmp	al,am_dma_disable	; 5b07 - disable DMA register set
	je	_am_dma_disable

	cmp	al,am_dma_dealloc	; 5b08 - deallocate DMA register set
	je	_am_dma_dealloc

	mov	ah,EMS_CODE8F		; invalid sub-function

am_exit:
	ret				; return to caller


	page
;-------------------------------------------------------------------
;
;	_am_get
;
;-------------------------------------------------------------------
_am_get:

	cmp	cs:AM_Set_Flag,0	;flag set?				;an000; dms;
	jne	AM_Get_Continue 	;yes					;an000; dms;
		xor	di,di		;signal set has not			;an000; dms;
		mov	es,di		;  been performed			;an000; dms;
		xor	ah,ah		;signal good exit			;an000; dms;
		jmp	AM_Get_Exit	;exit routine				;an000; dms;

AM_Get_Continue:

	mov	di,cs:AM_DI_Save
	mov	es,cs:AM_ES_Save
	mov	cs:[bp].IE_Saved_DI_Reg,di;set instance table entry		;an000; dms;

	call	GET_SUBFCN		; copy the save area info to user's buffer

	xor	bl,bl			; bl = 0 for our implementation
					; this indicates to user that ES:DI
					; buffer has been filled in with save
					; area info
AM_Get_Exit:

	ret

	page
;-------------------------------------------------------------------
;
;	_am_set
;
;-------------------------------------------------------------------
_am_set:

	push	si
	push	ds

	cmp	bl,null 		; bl must be 0 for us
	jne	_am_set_error		; set error code and exit

	mov	di,cs:[bp].IE_Saved_DI_Reg ; restore caller's DI, pointer to mapping control structure

	mov	cs:AM_ES_Save,es	; save es value 			;an000; dms;
	mov	cs:AM_DI_Save,di	; save di value 			;an000; dms;
	mov	cs:AM_Set_Flag,01	; flag indicates set performed		;an000; dms;
	mov	si,di			; restore_pgfrm_map expects DS:SI to point to save area
	push	es
	pop	ds

	call	RESTORE_PGFRM_MAP

	xor	ah,ah			; good return code

	jmp	_am_set_exit

_am_set_error:
	mov	ah,EMS_CODE9C		; fast regs not supported and BL != 0

_am_set_exit:

	pop	ds
	pop	si

	ret

	page
;-------------------------------------------------------------------
;
;	_am_size
;
;-------------------------------------------------------------------
_am_size:

	mov	dx,type h_save_struc	; get size requirements for save area

	xor	ah,ah			; good return code

	ret

	page
;-------------------------------------------------------------------
;
;	_am_alloc
;
;-------------------------------------------------------------------
_am_alloc:


	xor	bl,bl			; We don't support this function
					; in hardware, so return 0.
					; This indicates we will do software
					; emulation of these register sets.

	xor	ah,ah			; good return code

	ret

	page
;-------------------------------------------------------------------
;
;	_am_dealloc - 5b04
;
;-------------------------------------------------------------------
_am_dealloc:

	xor	ah,ah			; assume good return code

	cmp	bl,0			; is this a deallocate for 0?
	je	_am_dealloc_exit	; yes, goo return code

	mov	ah,EMS_CODE9C		; error code for dealloc of unsupported
					; register set

_am_dealloc_exit:

	ret

	page
;-------------------------------------------------------------------
;
;	_am_dma_alloc
;
;-------------------------------------------------------------------
_am_dma_alloc:

	xor	ah,ah			; good return code
	xor	bl,bl			; no DMA sets available

	ret

	page
;-------------------------------------------------------------------
;
;	_am_dma_enable
;
;-------------------------------------------------------------------
_am_dma_enable:

	mov	ah,EMS_CODE9E		; dedicated DMA not supported

	ret

	page
;-------------------------------------------------------------------
;
;	_am_dma_disable
;
;-------------------------------------------------------------------
_am_dma_disable:

	mov	ah,EMS_CODE9E		; dedicated DMA not supported

	ret

	page
;-------------------------------------------------------------------
;
;	_am_dma_dealloc
;
;-------------------------------------------------------------------
_am_dma_dealloc:

	xor	ah,ah			; assume good return code

	cmp	bl,null 		; is the DMA channel 0?
	je	_am_dma_de_exit

	mov	ah,EMS_CODE9C		; DMA register sets are not
					; supported and bl != 0

_am_dma_de_exit:
	ret


alternate_map	endp

	page
;-------------------------------------------------------------------
;
;	5D - enable/disable OS/E functions set functions
;
;-------------------------------------------------------------------
enable_os	proc

	cmp	al,os_enable		; fcn code for enable
	je	os_enable_fcn

	cmp	al,os_disable		; fcn code for disable
	je	os_disable_fcn

	cmp	al,os_access		; fcn code for access key return
	je	os_access_fcn

	mov	ah,EMS_CODE8F		;invalid sub-function code error

	ret				; return to caller

	page
;-------------------------------------------------------------------
;
;	5d00 - enable OS/E function set
;
;	INPUT:
;
;		BX,CX	=	Access key
;
;	OUTPUT:
;
;		AH	=	00h, no error
;				80H, software error
;				81H, hardware error
;				84H, invalid function
;				8FH, invalid subfunction
;				A4H, access denied, incorrect access key supplied
;
;-------------------------------------------------------------------
os_enable_fcn:

;	find out if this is the first time

	cmp	word ptr access_code[0],0 ; access_code = 0, means enabled
	jne	ose_check_code		; not 0, must check access code

	cmp	word ptr access_code[2],0 ; access_code = 0, means enabled
	jne	ose_check_code		; not 0, must check access code

	call	get_code		; get access code to return

	xor	ah,ah			; good return code
	jmp	ose_exit

;	not the first time, must check access code

ose_check_code:

	cmp	word ptr access_code[0],bx	; does it match?
	jne	ose_bad 		; no, return access denied error

	cmp	word ptr access_code[2],cx	; get second word of access code
	jne	ose_bad 		; no, return access denied error

;	access code was OK, enable functions and return no error condition

	mov	word ptr ose_functions,ose_enabled	; reset enabled flag

	xor	ah,ah			; good return code
	jmp	ose_exit		; all done, exit

ose_bad:
	mov	ah,EMS_CODEA4		; return access denied error code

ose_exit:
	ret				; return to caller


	page
;-------------------------------------------------------------------
;
;	5d01 - disable OS/E function set
;
;	INPUT:
;
;		BX,CX	=	Access key
;
;	OUTPUT:
;
;		AH	=	00h, no error
;				80H, software error
;				81H, hardware error
;				84H, invalid function
;				8FH, invalid subfunction
;				A4H, access denied, incorrect access key supplied
;
;-------------------------------------------------------------------
os_disable_fcn:

;	find out if this is the first time

	cmp	word ptr access_code[0],0 ; access_code = 0, means enabled
	jne	osd_check_code		; not 0, must check access code

	cmp	word ptr access_code[2],0 ; access_code = 0, means enabled
	jne	osd_check_code		; not 0, must check access code

;	yes, first time, must set access code and disable fcns

	call	get_code		; get access code to return

	mov	word ptr ose_functions,ose_disabled	; disable fcns

	xor	ah,ah			; good return code
	jmp	osd_exit

;	not the first time, must check access code

osd_check_code:

	cmp	word ptr access_code[0],bx	; does it match?
	jne	osd_bad 		; no, return access denied error

	cmp	word ptr access_code[2],cx	; get second word of access code
	jne	osd_bad 		; no, return access denied error

;	access code was OK, enable functions and return no error condition

	mov	word ptr ose_functions,ose_disabled	; disable functions

	xor	ah,ah			; good return code
	jmp	osd_exit		; all done, exit

osd_bad:
	mov	ah,EMS_CODEA4		; return access denied error code

osd_exit:
	ret				; return to caller

	page
;-------------------------------------------------------------------
;
;	5d02 - return OS/E function set access code
;
;	INPUT:
;
;		BX,CX	=	Access key
;
;	OUTPUT:
;
;		AH	=	00h, no error
;				80H, software error
;				81H, hardware error
;				84H, invalid function
;				8FH, invalid subfunction
;				A4H, access denied, incorrect access key supplied
;
;-------------------------------------------------------------------
os_access_fcn:

;	check access code


	cmp	word ptr access_code[0],bx	; does it match?
	jne	osa_bad 		; no, return access denied error

	cmp	word ptr access_code[2],cx	; get second word of access code
	jne	osa_bad 		; no, return access denied error

;	clear access code and return "no error" return code (AH = 00)

	xor	ax,ax			; clear ax
	mov	word ptr access_code[0],ax	; clear access code
	mov	word ptr access_code[2],ax	; clear access code

	jmp	osa_exit

osa_bad:
	mov	ah,ems_codeA4		; access denied error code

osa_exit:
	ret				; return to caller




	page
;-------------------------------------------------------------------
;
;	get_code - returns random access code in cx,dx and stores it in
;		system variable access_code.  Access_code is a double-word
;		which is used to save the bx,cx combination making up the
;		"password" for OS/E functions.
;
;-------------------------------------------------------------------

get_code:

	push	dx			; save dx

;	get a "random" number for first word of access code

redo1:
	call	get_rand		; returns "random" num in dx
	xor	dx,xor_mask		; confuse it a little

	cmp	dx,0			; make sure we didn't end up w/0
	je	redo1

	mov	word ptr access_code[0],dx ; save it away
	mov	bx,dx

;	get another one for second word of access code

redo2:
	call	get_rand
	add	dx,dx			; confuse it a little
	xor	dx,xor_mask

	cmp	dx,0			; make sure we didn't end up w/0
	je	redo2

	mov	word ptr access_code[2],dx ; save it away
	mov	cx,dx			; put second word in cx

	pop	dx			; restore

	ret				; return to caller


;-------------------------------------------------------------------
;
;	get_rand - returns a "random" number in dx
;
;-------------------------------------------------------------------
get_rand:

	push	ax			; save some regs
	push	cx

redo:
	mov	ah,read_clock		; function code to read clock
	int	dos_int 		; read the time
					; keep DX since it changes the most

	cmp	dx,0			; did we end up with 0?
	je	redo			; yes, redo it ... never want 0

	pop	cx			; restore some regs
	pop	ax

	ret				; return to caller

enable_os	endp

