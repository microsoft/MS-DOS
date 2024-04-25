;-------------------------------------------------------------------------
;
;  File: msvolid.asm
;	This file contains the volume_id subroutines and data structures.
;
;	Routines in this file are:
;	   Set_Volume_ID       -	main routine, calls other routines.
;	   read_volume_id      -	read the volume ID and tells if it has
;					   been changed.
;	   Transfer_volume_id  -	copy the volume ID from TMP to special
;					   drive.
;	   Check_Volume_ID     -	compare volume ID in TMP area with one
;					   expected for drive.
;	   Fat_Check	       -	see of the fatID has changed in the
;					   specified drive.
;	   Init_Vid_loop       -	set up for VID scan or move
;
;
;-------------------------------------------------------------------------

;
; length of the volume id
;

vid_size    equ 12

	    PATHSTART 001,VOLID 					  ;3.30

;
; null volume id
;

nul_vid db  "NO NAME    ",0

;
; data scratch area used to hold volume ids
;

tmp_vid db  "NO NAME    ",0

	    PATHEND 001,VOLID						  ;3.30

;
; Set_Volume_ID
;   If drive has changeline support, read in and set the volume_ID
; and the last FAT_ID byte.  If no change line support then do nothing.
;
;   On entry:
;	DS:DI points to the BDS for this disk.
;	AH contains media byte
;
;   On Exit:
;	Carry clear:
;	   Successful call
;	Carry set
;	   Error and AX has error code
;

Set_Volume_ID:
	PUBLIC SET_VOLUME_ID						  ;3.30
	push	dx			; save registers
	push	ax
	CALL	HasChange		; does drive have changeline support?
	jz	setvret 		; no, get out
	push	di
	call	read_volume_ID		; read the volume ID
	pop	di
	jc	SetErr			; if error go to error routine
	call	transfer_volume_ID	; copy the volume id to special drive
	call	ResetChanged		; restore value of change line

setvret:				; SET Volume RETurn
	clc				; no error, clear carry flag
	pop	ax			; restore registers
	pop	dx
	ret
SetErr:
	pop	dx			; pop stack but don't overwrite AX
	pop	dx			; restore DX
	ret



root_sec	DW	?	;Root sector #




;
; read_volume_id read the volume ID and tells if it has been changed.
;
;   On entry:
;	DS:DI points to current BDS for drive.
;   On Exit:
;	Carry Clear
;	    SI = 1  No change
;	    SI = 0  ?
;	    SI = -1 Change
;
;	Carry Set:
;	    Error and AX has error code.
;

read_volume_id:
	push	ES			; preserve registers
	push	DX
	push	CX
	push	BX
	push	AX
	push	DS			; Preserve Current BDS
	push	DI
	push	cs			; get ES segment correct
	pop	es
	push	cs			; get DS segment correct
	pop	ds
	mov	di,offset tmp_vid
	mov	si,offset nul_vid
	mov	cx,vid_size
	rep	movsb			; initialize tmp_vid to null vi_id

	pop	DI			; Restore Current BDS
	pop	DS
	mov	al,byte ptr ds:[di].cFAT    ; # of fats
	mov	cx,word ptr ds:[di].csecfat ; sectors / fat
	mul	cl			    ; size taken by fats
	add	ax,word ptr ds:[di].ressec  ; add on reserved sectors
					; AX is now sector # (0 based)
	mov	cs:[root_sec],ax	; set initial value
	mov	ax,[di].cDir		; # root dir entries
	mov	cl,4			; 16 entries/sector
	shr	ax,cl			; divide by 16
	mov	cx,ax			; cx is # of sectors to scan
next_sec:
	push	cx			; save outer loop counter
	mov	ax,cs:[root_sec]	; get sector #
	mov	cx,word ptr ds:[di].seclim    ; sectors / track
	xor	DX,DX
	div	cx
			; set up registers for call to read_sector
	inc	DX		; dx= sectors into track, ax= track count from 0
	mov	cl,dl		; sector to read
	xor	DX,DX
	div	word ptr ds:[di].hdlim ; # heads on this disc
	mov	dh,dl		; Head number
	mov	ch,al		; Track #
	call	read_sector	; get first sector of the root directory,
				; ES:BX -> BOOT
	jc	ReadVIDErr	; error on read
	mov	cx,16		; # of dir entries in a block of root
	mov	al,08h		; volume label bit
fvid_loop:
	cmp	byte ptr es:[bx],0	; End of dir?
	jz	no_vid			; yes, no vol id
	cmp	byte ptr es:[bx],0E5h	; empty entry?
	jz	ent_loop		; yes, skip
	test	es:[bx+11],al		; is volume label bit set in fcb?
	jnz	found_vid		; jmp yes
ent_loop:
	ADD	BX,32		;MJB003 ADD LENGTH OF DIRECTORY ENTRY	  ;3.30
	loop	fvid_loop
	pop	cx			; outer loop
	inc	cs:[root_sec]		; next sector
	loop	next_sec		; continue
NotFound:
	XOR	SI,SI
	jmp	short fvid_ret

found_vid:
	pop	cx			; clean stack of outer loop counter
	mov	si,bx			; point to volume_id
	push	ds			; preserve currnet BDS
	push	di
	push	es			; es:si points to volume id.
	pop	ds			; source segment
	push	cs
	pop	es			; destination segment
	mov	di,offset tmp_vid	; dest of volume_id
	mov	cx,vid_size -1		; length of string minus NUL
	rep	movsb			; mov volume label to tmp_vid
	xor	al,al
	stosb				; Null terminate
	XOR	SI,SI
	pop	DI			; restore current BDS
	pop	DS
fvid_ret:
	pop	ax
	clc
RVIDRet:
	pop	BX			; restore register
	pop	CX
	pop	DX
	pop	ES
	ret
no_vid:
	pop	cx			; clean stack of outer loop counter
	jmp	NotFound		; not found
ReadVIDErr:
	pop	SI
	pop	SI
	jmp	RVIDRet



;
;   Transfer_volume_id - copy the volume ID from TMP to special drive
;
;   Inputs:	DS:DI nas current BDS
;   Outputs:	BDS for drive has volume ID from TMP
;

transfer_volume_ID:
	push	DS		; preserve current BDS
	push	DI
	push	ES
	push	SI
	push	CX
	call	init_vid_loop
	cld
	rep	MOVSB		; transfer
	pop	CX
	pop	SI
	pop	ES
	pop	DI		; restore current BDS
	pop	DS
	ret


;
;   Check_Volume_ID - compare volume ID in TMP area with one expected for
;	drive
;
;   Inputs:	DS:DI has current BDS for drive
;   Outputs:	SI = 0 if compare succeeds
;		SI = -1 if compare fails.

check_volume_id:
	push	DS			; preserve current BDS for drive
	push	DI
	push	ES
	push	CX
	call	init_vid_loop
	cld
	repz	cmpsb			; are the 2 volume_ids the same?
	mov	si,0			; assume unknown
	jz	check_vid_ret		; carry clear if jump taken
	mov	si,-1			; failure
check_vid_ret:
	pop	CX
	pop	ES
	pop	DI			; restore current BDS
	pop	DS
	ret

;
;   Fat_Check - see of the fatID has changed in the specified drive.
;	      - uses the FAT ID obtained from the boot sector.
;
;   Inputs:	MedByt is expected FAT ID
;		DS:DI points to current BDS
;   Output:	Carry Clear
;		    SI = -1 if fat ID different,
;		    SI = 0 otherwise
;   No other registers changed.

FAT_CHECK:
	push	AX
	xor	SI, SI			 ; say FAT ID's are same.
	mov	AL, cs:MedByt
	cmp	AL, byte ptr [DI].Mediad ; compare it with the BDS medbyte
	jz	OKRET1			 ; carry clear
	dec	SI
OkRet1: clc
	pop	AX
	ret


;
;   Init_Vid_loop - set up for VID scan or move
;
;   Inputs:	DS:DI pionts to BDS for the drive
;   Outputs:	DS:SI points to tmp_vid
;		ES:DI points to vid for drive
;		CX has size for VID compare
;

init_vid_loop:
	push	ax
	push	ds
	pop	es
	push	cs
	pop	ds
	mov	si,offset tmp_vid   ; source
	add	di,volid
	mov	cx,vid_size
	pop	ax
	ret

