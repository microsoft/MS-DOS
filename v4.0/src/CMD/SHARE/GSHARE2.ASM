	Title	Share_2
;				   $SALUT (0,36,41,44)
				   include SHAREHDR.INC
;
;     Label: "The DOS SHARE Utility"
;	     "Version 4.00 (C) Copyright 1988 Microsoft"
;	     "Licenced Material - Program Property of Microsoft"
;
;******************* END OF SPECIFICATIONS *************************************

				   NAME Sharer2

					   ;  INCLUDE DOSSYM.INC
					   ;  INCLUDE SYSMSG.INC
				   .xlist
				   .xcref
				   INCLUDE DOSSYM.INC
				   INCLUDE SYSMSG.INC
				   .cref
				   .list
				   page 80,132

				   MSG_UTILNAME <SHARE>

ShareDataVersion		   =	1

AsmVars 			   <IBM, Installed>

Installed			   =	TRUE ; for installed version

OFF				   Macro reg,val
				   IF	installed
				   mov	reg,OFFSET val
				   ELSE
				   mov	si,OFFSET DOSGROUP:val
				   ENDIF
				   ENDM

ERRNZ				   Macro x
				   IF	x    NE 0
				   %out ERRNZ failed
				   ENDIF
				   ENDM
					   ;---------------------------------------
					   ; if we are installed, then define the
					   ; base code segment of the sharer first
					   ;---------------------------------------
;	$SALUT	(4,9,17,36)

	IF	Installed

	    Share   SEGMENT BYTE PUBLIC 'SHARE'
	    Share   ENDS

	ENDIF

				   ;---------------------------------------
				   ; include the rest of the segment
				   ;  definitions for normal msdos

				   ; segment ordering for MSDOS

				   ;---------------------------------------
	include dosseg.asm

	CONSTANTS SEGMENT

	extrn	DataVersion:BYTE   ; version number of DOS data.
	extrn	JShare:BYTE	   ; location of DOS jump table.
	extrn	sftFCB:DWORD	   ; [SYSTEM] pointer to FCB cache table
	extrn	KeepCount:WORD	   ; [SYSTEM] LRU count for FCB cache
	extrn	CurrentPDB:WORD

	CONSTANTS ENDS

	DATA	SEGMENT

	extrn	ThisSFT:DWORD	   ; pointer to SFT entry
	extrn	WFP_start:WORD	   ; pointer to name string
	extrn	User_ID:WORD
	extrn	Proc_ID:WORD
	extrn	SFT_addr:DWORD
	extrn	Arena_Head:WORD
	extrn	fshare:BYTE
	extrn	pJFN:DWORD
	extrn	JFN:WORD

	IF	DEBUG

	    extrn   BugLev:WORD
	    extrn   BugTyp:WORD
	    include bugtyp.asm

	ENDIF


	DATA	ENDS

				   ;---------------------------------------
				   ; if we are not installed, then the
				   ; code here is just part of the normal
				   ; MSDOS code segment otherwise,
				   ; define our own code segment
				   ;---------------------------------------

	.sall
	IF	NOT	INSTALLED

	    CODE    SEGMENT BYTE PUBLIC 'CODE'

	    ASSUME  SS:DOSGROUP,CS:DOSGROUP

	ELSE

	    Share   SEGMENT BYTE PUBLIC 'SHARE'

	    ASSUME  SS:DOSGROUP,CS:SHARE

	ENDIF

	Extrn	FreLock:WORD,Serial:WORD
	Extrn	MFT_Enter:NEAR,MFTClose:NEAR,MFTClu:NEAR,MFTCloseP:NEAR
	Extrn	MFTCloN:NEAR
	Extrn	Set_Mult_Block:NEAR,Clr_Mult_Block:NEAR,Chk_Block:NEAR
	Extrn	MFT_Get:NEAR

	include mft.inc

;  $SALUT (4,4,9,41)

   BREAK <FNM - Find name in MFT>

;******************* START OF SPECIFICATIONS ***********************************
;
;	FNM - Find name in MFT
;
;	FNM searches the MFT for a name record.
;
;	ENTRY	(DS:SI) = pointer to name string (.asciz)
;		(al) = 1 to create record if non exists
;		     = 0 otherwise
;	EXIT	'C' clear if found or created
;		  (DS:BX) = address of MFT name record
;		'C' set if error
;		  If not to create, item not found
;		    (DS:SI) unchanged
;		  If to create, am out of space
;		    (ax) = error code
;	USES	ALL
;
;******************* END OF SPECIFICATIONS *************************************

   Procedure FNM,NEAR

   push ds				; save string address
   push si
   xchg bh,al				; (bh) = create flag
   or	bh,bh				; if not creating
   jz	fnm01				; skip sft test

					;---------------------------------------
					; run down through string counting
					;  and summing
					;---------------------------------------

fnm01: sub dx,dx			; (dx) = byte count
   sub	bl,bl				; (bl) = sum

fnm1: lodsb				; (al) = next char
   add	bl,al
   adc	bl,0
   inc	dx
   and	al,al
   jnz	fnm1				; terminate after null char

					;---------------------------------------
					; Info computed.
					;  Start searching name list

					;  (bh) = create flag
					;  (bl) = sum byte
					;  (dx) = byte count
					;  (TOS+2:TOS) = name string address
					;---------------------------------------
   push cs
   pop	ds

   Off	SI,mft

fnm2: cmp [si].mft_flag,MFLG_FRE
   jl	fnm10				; at end - name not found
   jz	fnm4				; is free, just skip it
   cmp	bl,[si].mft_sum 		; do sums compare?
   jz	fnm5				; its a match - look further
fnm4: add si,[si].mft_len		; not a match... skip it
   JMP	SHORT fnm2
					;---------------------------------------
					; name checksums match
					;   - compare the actual strings
					;
					;   (dx)	= length
					;   (ds:si	= MFT address
					;   (bh)	= create flag
					;   (bl)	= sum byte
					;   (dx)	= byte count
					;   (TOS+2:TOS) = name string address
					;---------------------------------------

fnm5: mov cx,dx 			; (cx) = length to match
   pop	di
   pop	es				; (ES:DI) = fba given name
   push es
   push di
   push si				; save MFT offset
   add	si,mft_name			; (ds:si) = fwa string in record
   repz cmpsb
   pop	si				; (ds:si) = fwa name record
   jnz	fnm4				; not a match

					;---------------------------------------
					; Yes, we've found it.  Return the info
					;
					;  (TOS+2:TOS) = name string address
					;---------------------------------------

   fmt	TypShare,LevMFTSrch,<"FNM found name record at $x\n">,<si>
   pop	ax				; discard unneeded stack stuff
   pop	ax
   mov	bx,si				; (ds:bx) = fwa name record
   clc

   ret
					;---------------------------------------
					;**
					;**  Its not in the list
					;**  - lets find a free spot and put
					;**    it there
					;
					;  (bh)        = create flag
					;  (bl)        = sum byte
					;  (dx)        = string length
					;  (TOS+2:TOS) = ASCIZ string address
					;  (ds)        = SEG CODE
					;---------------------------------------
fnm10:
   and	bh,bh
   jnz	fnm10$5 			; yes, insert it
   pop	si
   pop	ds				; no insert, its a "not found"
   stc

   fmt	TypShare,LevMFTSrch,<"FNM failing\n">

   mov	ax,error_path_not_found

   ret

fnm10$5:
   add	dx,mft_name			; (dx) = minimum space needed

   off	SI,mft

fnm11: cmp [si].mft_flag,MFLG_FRE

   IF	NOT  DEBUG
       jl   fnm20			; at END, am out of space
   ELSE
       jl   fnm20j
   ENDIF

   jz	fnm12				; is a free record
   add	si,[si].mft_len 		; skip name record
   JMP	SHORT fnm11

   IF	DEBUG
fnm20j: jmp fnm20
   ENDIF

fnm12: mov ax,[si].mft_len		; Have free record, (ax) = total length
   cmp	ax,dx
   jnc	fnm13				; big enough
   add	si,ax
   JMP	SHORT fnm11			; not large enough - move on

					;---------------------------------------
					; OK, we have a record which is big
					;  enough.  If its large enough to hold
					;  another name record of 6 characters
					;  than we'll split the block, else
					;  we'll just use the whole thing
					;
					; (ax)	      = size of free record
					; (dx)	      = size needed
					; (ds:si)     = address of free record
					; (bl)	      = sum byte
					; (TOS+2:TOS) = name string address
					;---------------------------------------

fnm13: sub ax,dx			; (ax) = total size of proposed fragment
   cmp	ax,mft_name+6
   jc	fnm14				; not big enough to split
   push bx				; save sum byte
   mov	bx,dx				; (bx) = offset to start of new name record
   mov	[bx][si].mft_flag,MFLG_FRE
   mov	[bx][si].mft_len,ax		; setup tail as free record
   sub	ax,ax				; don't extend this record
   pop	bx				; restore sum byte
fnm14: add dx,ax			; (dx) = total length of this record
   mov	[si].mft_len,dx
   mov	[si].mft_sum,bl
   mov	[si].mft_flag,MFLG_NAM

   fmt	TypShare,LevMFTSrch,<"FNM creating record at $x\n">,<si>

   push ds
   pop	es				; (es) = MFT segment for "stow"
   sub	ax,ax
   mov	di,si
   add	di,mft_lptr
   stosw				; zero LCK pointer
   ERRNZ mft_sptr-mft_lptr-2
;	add	di,mft_sptr-mft_lptr-2
   stosw				; zero SFT pointer
   stosw				; zero SFT pointer
   inc	serial				; bump serial number
   mov	ax,serial
   ERRNZ mft_serl-mft_sptr-4
;	ADD	di,mft_serl-mft_sptr-4
   stosw
					;---------------------------------------
					; We're all setup except for the name.
					;  Note that we'll block copy the whole
					;  name field, even though the name may
					;  be shorter than that (we may have
					;  declined to fragment this memory block)
					;
					;	(dx) = total length of this record
					;	(ds:si) = address of working record
					;	(es) = (ds)
					;	(TOS+2:TOS) = name string address
					;---------------------------------------
   mov	cx,dx
   sub	cx,mft_name			; compute total size of name area
   ERRNZ mft_name-mft_serl-2
;	add	di,mft_name-mft_serl-2	; (ES:DI) = target address
   mov	ax,si				; save name record offset
   pop	si
   pop	ds
   rep	movsb
   mov	bx,ax				; (bx) = name record offset
   push es
   pop	ds				; (DS:BX) = name record offset
   clc

   ret

;**
;**	OUT OF FREE SPACE
;**
;**	This is tough, folks.  Lets trigger a garbage collection and see if
;**	there is enough room.  If there is, we'll hop back and relook for a
;**	free hunk; if there isnt enough space, its error-city!
;
;	WARNING: it is important that the garbage collector be told how big a
;		name record hole we're looking for...  if the size given GCM
;		is too small we'll loop doing "no space; collect; no space;
;		...)
;
;	(dx) = total length of desired name record
;	(ds) = SEG CODE
;	(bl) = sum byte
;	(TOS+2:TOS) = name string address

fnm20:
   mov	ax,dx				; (ax) = size wanted
   sub	dx,mft_name			; (dx) = string length for reentry at fnm10
   push dx
   push bx
   call GCM				; garbage collect MFT
   pop	bx
   pop	dx

   IF	DEBUG
       jnc  fnm10j
   ELSE
       jnc  fnm10			; go back and find that space
   ENDIF

					;---------------------------------------
					; no space, return w/error
					;---------------------------------------

fnm50: pop ax
   pop	ax				; clean stack
   mov	ax,error_sharing_buffer_exceeded
   stc

   ret

   IF	DEBUG
fnm10j: jmp fnm10
   ENDIF

   EndProc FNM

   BREAK <GCM - Garbage Collect MFT>

;******************* START OF SPECIFICATIONS ***********************************
;
;	GCM - Garbage Collect MFT
;
;	GCM runs down the MFT structure squeezing out the free space and
;	putting it into one free block at the end.  This is a traditional heap
;	collection process.  We must be sure to update the pointer in the
;	SFTs.  This presumes no adjacent free blocks.
;
;	ENTRY	(ax) = space desired in last free block
;		(DS) + SEG CODE
;	EXIT	'C' clear if enough space in block
;		'C' set if not enough space
;
;******************* END OF SPECIFICATIONS *************************************

   Procedure GCM,NEAR

   push ax				; save target
   off	si,mft				; (si) = from pointer
   mov	di,si				; (di) = to pointer

					;---------------------------------------
					; (DI) points to the beginning of
					;	a free space block
					; (SI) points to the next block.
					;---------------------------------------

gcm1: mov cx,[si].mft_len		; (cx) = size of whatever it is
   cmp	[si].mft_flag,MFLG_FRE
   jl	gcm10				; END marker
   jnz	gcm2				; have a name record

					;---------------------------------------
					; (SI) points to a free block.
					;    We coalesce it by changing the size.
					;---------------------------------------
   cmp	si,di
   jz	gcm15				; do NOT coalesce a block with itself
   add	[di].mft_len,cx 		; coalesce
gcm15:
   add	si,cx				; skip the empty one
   JMP	SHORT gcm1
					;---------------------------------------
					; (SI) points to a non-free,
					;	non-last block.
					; (DI) points to the beginning of a
					;	 free block.
					;
					; We move the non-free block down over
					;   the free block
					;---------------------------------------
gcm2: cmp si,di
   jnz	gcm3				; have to copy

					;---------------------------------------
					; SI = DI => we are at a boundary
					;	     between allocated blocks.
					;	     We do no copying.
					;---------------------------------------
   add	si,cx
   mov	di,si				; no emptys yet... no need to copy
   JMP	SHORT gcm1
					;---------------------------------------
					; CX is length of allocated block.
					;      - Move it
					;---------------------------------------

gcm3: mov bx,di 			; (DS:BX) = new home for this record
   mov	ax,ds
   mov	es,ax
   rep	movsb
					;---------------------------------------
					; We've moved the record, now fix up
					;  the pointers in the SFT chain
					;
					;  (si) = address of next record
					;  (di) = address of next free byte
					;  (bx) = address of record in its new home
					;  (TOS) = needed space
					;---------------------------------------
   push di
   push ds
   lds	di,[bx].mft_sptr		; (ds:di) = chain of SFT
gcm4: or di,di
   jz	gcm5				; no more SFT
   mov	[di].sf_mft,bx			; install new MFT position
   lds	di,[di].sf_chain		; link to next
   JMP	gcm4				; fix next SFT

gcm5: pop ds
   pop	di
					;---------------------------------------
					; (DI) points to beginning of
					;	new free record (moved)
					; (SI) points to next record
					;
					; Make sure that the (DI) record
					;  has correct format
					;---------------------------------------

   mov	[di].mft_flag,MFLG_FRE		; indicate free record
   mov	[di].mft_len,si 		; calculate correct length
   sub	[di].mft_len,di
					;---------------------------------------
					; MFT now has correct record structure.
					;  Go find more free blocks
					;---------------------------------------
   JMP	SHORT gcm1
					;---------------------------------------
					; We have scanned the entire table,
					;  compacting all empty records together.
					;
					;   (di) = first free byte in table
					;   (si) = address of END record
					;   (TOS) = size needed
					;
					; Be extra careful!!!
					;---------------------------------------
gcm10: mov ax,si
   sub	ax,di				; (ax) = free space
   pop	bx				; (bx) = space wanted
   sub	ax,bx

   ret

   EndProc GCM

   BREAK <RMN - Remove MFT Name record>

;******************* START OF SPECIFICATIONS ***********************************
;
;	RMN - Remove MFT Name record
;
;	RMN removes a name record from the MFT list.  The record is marked
;	free and all free space is coalesced.
;
;	ENTRY	(DS:BX) = FBA MFT name record
;	EXIT	to INTERR if lock and SFT chains are not empty
;	USES	ALL
;
;******************* END OF SPECIFICATIONS *************************************

   Procedure RMN,NEAR

   mov	si,bx
   mov	ax,word ptr [si].mft_sptr
   or	ax,word ptr [si].mft_lptr
   jnz	RMNIER1 			; not clean - internal error
   mov	si,bx				; (ds:si) = fwa name record

   mov	[si].mft_flag,MFLG_FRE		; mark free

   call mrg				; coalesce all free space

   ret

RMNIER1:push ax
   off	ax,rmnerr1

RMNIER: call INTERR			; internal error

rmnerr1 db "RMN: SFT LCK fields not 0", 13, 10, 0

   EndProc RMN

   Break <MRG - merge all free space>

;******************* START OF SPECIFICATIONS ***********************************
;
;   MRG - merge all free space
;
;   MRG - walk through mft merging adjacent free space.
;
;   Inputs:	ds = CS
;   Outputs:	none (all free space coalesced)
;   Registers Revised: none
;
;******************* END OF SPECIFICATIONS *************************************

   Procedure MRG,near

   assume ds:nothing,es:nothing

   push si
   push bx

   off	si,mft				; start at beginning
mrg1: mov bx,[si].mft_len		; get length
   cmp	[si].mft_flag,MFLG_FRE		; is record free?
   jl	mrg9				; done.
   jz	mrg2				; yes, try to merge with next
mrg15: add si,bx			; advance to next
   jmp	mrg1
					;---------------------------------------
					; (si) points to free record.
					;  - See if next is free
					;---------------------------------------
mrg2: cmp [bx][si].mft_flag,MFLG_FRE
   jnz	mrg15				; not free, go scan again
   mov	bx,[bx][si].mft_len		; get length of next guy
   add	[si].mft_len,bx 		; increase our length
   jmp	mrg1				; and check again
mrg9: pop bx
   pop	si

   ret

   EndProc MRG

   BREAK <RSC - Remove SFT from SFT chain>

;******************* START OF SPECIFICATIONS ***********************************
;
;	RSC - Remove SFT from SFT chain
;
;	RSC removes a given SFT from its chain.  The caller must insure that
;	any locks have been cleared and that the SFT is indeed free.  The
;	sf_mft field is zeroed to indicate that this SFT is no longer chained.
;
;	NOTE - RSC does NOT remove the name record if this was the last SFT on
;		it.  The caller must check for this and remove it, if
;		necessary.
;
;	ENTRY	(ES:DI) = SFT address
;	EXIT	(DS:BX) = FBA name record for this SFT
;		'Z' set if this is the last SFT
;	USES	ALL
;
;******************* END OF SPECIFICATIONS *************************************

   Procedure RSC,NEAR

   push cs
   pop	ds

   mov	ax,es				; easy spot for compare
   mov	bx,es:[di].sf_mft
   lea	si,[bx].mft_sptr-sf_chain	; ds:[si].sf_chain point to prev link
rsc1: or si,si
   jz	rscier
   cmp	word ptr [si].sf_chain,di
   jnz	rsc15
   cmp	word ptr [si].sf_chain+2,ax
   jz	rsc2
rsc15: lds si,[si].sf_chain
   jmp	rsc1
					;---------------------------------------
					; (es:di) is sft
					; (ds:si) is prev sft link
					;---------------------------------------
rsc2: mov ax,word ptr es:[di].sf_chain
   mov	word ptr ds:[si].sf_chain,ax
   mov	ax,word ptr es:[di].sf_chain+2
   mov	word ptr ds:[si].sf_chain+2,ax

   push cs
   pop	ds
   xor	bx,bx
   xchg bx,es:[di].sf_MFT		; (DS:bx) = MFT address
					;    and 0 MFT pointer (show free)
   cmp	word ptr [bx].mft_sptr,0	; set z flag if no more sft

   ret

rscier: push ax
   off	ax,rscerr

   call interr

rscerr db "RSC: SFT not in SFT list", 13, 10, 0

   EndProc RSC

   BREAK <SLE - Scan for Lock Entry>

;******************* START OF SPECIFICATIONS ***********************************
;
;	SLE - Scan for Lock Entry
;
;	SLE scans a lock list looking for a lock range that overlaps the
;	caller-supplied range.	SLE indicates:
;
;		no overlap
;		partial overlay
;		1-to-1 match
;
;	ENTRY	(AX:BX) = FBA of area
;		(CX:DX) = LBA of area
;		(DS:SI) = address of name record
;		(DI)	= 0 to ignore locks by User_ID Proc_ID ThisSFT
;			= 1 to consider all locks
;	EXIT	'C' clear if no overlap
;		  AX,BX,CX,DX preserved
;		'C' set if overlap
;		  (di) = address of pointer to found record
;			 (i.e., DS:((di)) = address of lock record)
;		  'Z' set if 1-to-1 match
;	USES	ALL but (ds), (es) (also see EXIT)
;
;******************* END OF SPECIFICATIONS *************************************

   Procedure SLE,NEAR

   push es
   and	di,di
   pushf				; Z set to ignore own locks
   lea	di,[si].mft_lptr		; (ds:di) = addr of ptr to lock record
   mov	si,[di] 			; (ds:si) = address of 1st lock record

					;---------------------------------------
					; check out next lock
					;
					; (ds:si) = address of next lock record
					; (ds:di) = address of pointer to next
					;	     lock record
					; (TOS)   = flags (Z set to ignore
					;	      own locks)
					; (TOS+1) = Saved ES
					;---------------------------------------
sle1: and si,si
   jz	sle9				; list exhaused, ergo no overlap
   popf 				;
   pushf
   jnz	sle2				; am to check all locks

					;---------------------------------------
					; am to ignore own locks...
					;  check the user and proc IDs on this one
					;---------------------------------------

;dcl - this code used to compare the process id in the sft pointed to by the
;  lock.  now we compare the lock process id to the current process id.  this
;  allows a child process to lock an area and then do i/o with it.  before,
;  the child could lock it, but then could not access it


   mov	bp,[si].rlr_pid 		;dcl
   cmp	bp,Proc_id			;dcl
   jnz	sce1$5				;dcl
   les	si,[si].rlr_sptr		; (si) = sft address		;dcl
   mov	bp,es:[si].sf_UID		;dcl
   cmp	bp,User_ID			;dcl
   jnz	sce1$5				; doesn't belong to user        ;dcl
   mov	bp,es				;dcl
   cmp	bp,WORD PTR ThisSFT+2
   jnz	sce1$5
   cmp	si,WORD PTR ThisSFT
sce1$5: mov si,[di]			; (ds:si) = address of next lock record
   jz	sle3				; owned by user - ignore

sle2: mov bp,dx
   sub	bp,[si].rlr_fba 		; compare proposed last to first of record
   mov	bp,cx
   sbb	bp,[si].rlr_fba+2
   jc	sle3				; proposed is above current
   mov	bp,[si].rlr_lba
   sub	bp,bx				; compare proposed first to last of record
   mov	bp,[si].rlr_lba+2
   sbb	bp,ax
   jnc	sle5				; we have a hit

					;---------------------------------------
					; This entry is harmless...
					;    chain to the next one
					;---------------------------------------
   ERRNZ rlr_next

sle3: mov di,si 			; save addr of pointer to next
   mov	si,[di]
   JMP	SHORT sle1
					;---------------------------------------
					; We have an overlap.
					;  - See if its an exact match
					;
					; (ds:di) = address of pointer
					;	    (offset only) to the lock record
					; (ds:si) = address of lock record
					; (TOS) = flags ('Z' set if to ignore
					;	  own locks)
					; (TOS+1) = saved (es)
					;---------------------------------------

sle5: xor ax,[si].rlr_fba+2		; require a 4-word match
   xor	bx,[si].rlr_fba
   xor	cx,[si].rlr_lba+2
   xor	dx,[si].rlr_lba
   or	ax,bx
   or	ax,cx
   or	ax,dx				; 'Z' set if exact match
   stc					; flag an overlap
   mov	ax,error_lock_violation
sle9: pop bp				; discard flags (pushf)
   pop	es				; restore (es)

					;---------------------------------------
					; (ds:si) = address of lock record
					;	    for Chk_Block
					;---------------------------------------
   ret

   EndProc SLE

   BREAK <OFL - obtain free lock-record>

;******************* START OF SPECIFICATIONS ***********************************
;
;	OFL - obtain free lock-record
;
;	OFL returns a free lock-record, if one can be had.
;
;	ENTRY	(DS) = MFT Segment
;	EXIT	'C' clear if OK
;		  (DI) = FBA lock record
;		'C' set if no space
;		  (ax) = error code
;	USES	DI, FLAGS
;
;******************* END OF SPECIFICATIONS *************************************

   Procedure OFL,NEAR

   mov	di,Frelock
   and	di,di

;  $if	nz				; if something there
   JZ $$IF1

       push [di].rlr_next
       pop  Frelock			; chain off of the list
					; exit with 'C' clear

;  $else				; none on free list
   JMP SHORT $$EN1
$$IF1:

       mov  ax,error_sharing_buffer_exceeded ; None on free list, give up until
       stc				;  garbage collector is ready

;  $endif
$$EN1:

   ret

   EndProc OFL

   Break <CPS - close process SFT>

;******************* START OF SPECIFICATIONS ***********************************
;
;   CPS - close process SFT.
;
;	During maintenance, it is necessary to close a
;	file given ONLY the SFT.  This necessitates walking all PDB's JFN
;	tables looking for the SFN.  The difficult part is in generating the
;	SFN from the SFT.  This is done by enumerating SFT's and comparing for
;	the correct SFT.  Finding all PDBs is easy:  walk arena and check
;	owner fields
;
;   Inputs:	ThisSFT points to SFT of interest
;   Outputs:	Handle is closed on user
;   Registers Revised: none
;
;******************* END OF SPECIFICATIONS *************************************

   Procedure CPS,NEAR

   ASSUME DS:NOTHING,ES:NOTHING

   SaveReg <DS,SI,ES,DI,AX,BX,CX>

   lds	si,ThisSFT
   xor	bx,bx
cps01:

   CallInstall SFFromSFN,multDOS,22,bx,bx

   jc	cps31				; no more SFN's.  Must be FCB.

   CallInstall PointComp,multDOS,20

   jz	cps02				; found matching SFN, go scan.
   inc	bx				; did not match, go back for more
   jmp	cps01
					;---------------------------------------
					; BL is the sfn we want to find.  Walk
					;  the memory arena enumerating all PDB's
					;  and zap the handle tables for the
					;  specified sfn.
					;---------------------------------------
cps02:
   mov	al,bl
   mov	ds,Arena_Head			; get first arena pointer

					;---------------------------------------
					; DS:[0] is the arena header.
					; AL is sfn to be closed
					;---------------------------------------
cps1:
   mov	cx,ds:[arena_owner]
   mov	bx,ds
   inc	bx				; is the owner the same as the current
   cmp	cx,bx				; block?
   jnz	cps2				; no, go skip some more...

					;---------------------------------------
					; CX:0 is the correct pointer to a PDB.
					;---------------------------------------
   push ds
   mov	ds,cx
					;---------------------------------------
					; Given a PDB at DS:0, scan his handle
					;  table and then loop through the next
					;  PDB link.
					;---------------------------------------
cps15:
   call CPJ				; free for this PDB
   lds	cx,DS:[PDB_Next_PDB]		; advance to next
   cmp	cx,-1
   jnz	cps15				; there is another link to process
   pop	ds
					;---------------------------------------
					; We have processed the current
					;  allocation block pointed to by DS.
					;  DS:[0] is the allocation block
					;---------------------------------------
cps2:
   cmp	ds:[arena_signature],arena_signature_end
   jz	cps3				; no more blocks to do
   mov	bx,ds				; get current address
   add	bx,DS:[Arena_size]		; add on size of block
   inc	bx				; remember size of header
   mov	ds,bx				; link to next
   jmp	cps1
					;---------------------------------------
					; Just for good measure, use CurrentPDB
					;  and clean off him
					;---------------------------------------
cps3:
   mov	ds,CurrentPDB

   call CPJ

cps31:

   RestoreReg <

   RestoreReg <CX,BX,AX,DI,ES,SI,DS>

   ret

   EndProc CPS

;******************* START OF SPECIFICATIONS ***********************************
;
; CPJ -
;
; Scan JFN table for SFT # and put in -1 if found
;
; Input: DS:0 is PDB
;	 AL is SFT index # of interest
;
; Output: None
;
; Uses: Flags,CX,ES,DI
;
;******************* END OF SPECIFICATIONS *************************************

   Procedure CPJ,NEAR

   assume ds:nothing,es:nothing

   mov	cx,ds:[PDB_JFN_length]
   les	di,ds:[PDB_JFN_pointer]
   cld
cpj1: repne scasb

   retnz				; none found

   mov	byte ptr es:[di-1],-1		; free this
   jcxz CPJret				; Found one in last JFN entry
   jmp	cpj1				; keep looking
CPJret:

   ret

   EndProc CPJ

   Break <SFM - convert an mft pointer into a serial number>

;******************* START OF SPECIFICATIONS ***********************************
;
;   SFM - convert a pointer to a mft entry into the serial number for that
;   entry.  We keep these around to see if a FCB really points to the correct
;   SFT.
;
;   Inputs:	BX is the mft pointer
;   Outputs:	BX is the serial number
;   Registers Revised: none
;
;******************* END OF SPECIFICATIONS *************************************

   Procedure SFM,NEAR

   ASSUME CS:SHARE,DS:NOTHING,ES:NOTHING,SS:DOSGROUP

   mov	bx,cs:[bx].mft_serl

   ret

   EndProc SFM

   Break <ShChk - check a fcb for share related information>

;******************* START OF SPECIFICATIONS ***********************************
;
;   ShChk - check a fcb for share related information
;
;   ShChk - checks the reserved field contents of an FCB with a SFT to see
;   if they represent the same file.  The open ref count must be > 0.
;
;   Inputs:	DS:SI point to FCB
;		ES:DI point to SFT
;   Outputs:	Carry Set if contents do not match
;		Carry clear if contents match
;		    BX has first cluster
;   Registers Revised: none
;
;******************* END OF SPECIFICATIONS *************************************

   Procedure ShChk,NEAR

   ASSUME CS:SHARE,DS:NOTHING,ES:NOTHING,SS:DOSGROUP

   CMP	ES:[DI].sf_ref_count,0
   JZ	BadSFT
   MOV	BX,ES:[DI].sf_mft		; Local file or dev with sharing

   call SFM

   CMP	BX,[SI].fcb_l_mfs
   JNZ	BadSFT
   MOV	BX,[SI].fcb_l_firclus

   ret

BadSFT: stc

   ret

   EndProc ShChk

   Break <ShSave - save information from SFT into an FCB>

;******************* START OF SPECIFICATIONS ***********************************
;
;   ShSave - save information from SFT into an FCB
;
;   ShSave - copy information into the reserved area of an FCB from a SFT.
;   This is so that we can later match the SFT with the FCB.
;
;   Inputs:	ES:DI point to SFT
;		DS:SI point to FCB
;   Outputs:	FCB reserved field is filled in
;		BL = FCBSHARE
;   Registers Revised: AX,BX
;
;******************* END OF SPECIFICATIONS *************************************

   Procedure ShSave,NEAR

   ASSUME CS:SHARE,DS:NOTHING,ES:NOTHING,SS:DOSGROUP

   MOV	AL,ES:[DI].sf_attr		; move attribute (for reopen)
   MOV	[SI].FCB_l_attr,AL
   MOV	AX,ES:[DI].sf_firclus		; get first cluster
   MOV	[SI].FCB_l_firclus,AX
   MOV	BX,ES:[DI].sf_mft		; get sharing pointer

   call SFM

   MOV	[SI].FCB_l_mfs,BX
   MOV	BL,FCBSHARE

   ret

   EndProc ShSave

   Break <ShCol - collapse identical handle SFTs in mode 70 only>

;******************* START OF SPECIFICATIONS ***********************************
;
;   ShCol - collapse identical handle SFTs in mode 70 only
;
;   ShCol - collapse same 70-mode handles together.  This represents network
;   originated FCBs.  Since FCB's are incredibly mis-behaved, we collapse the
;   SFT's for identical files, thus using a single sft for each file instead
;   of a separate sft for each instance of the file.
;
;   Note that the redirectors will collapse multiple instances of these
;   files together.  FCB's are pretty misbehaved, so the redirector will
;   inform us of EACH close done on an FCB.  Therefore, we must increment
;   the ref count each time we see a collapse here.
;
;   Inputs:	DS:SI ThisSFT has new sft to find.
;   Outputs:	Carry set - no matching SFT was found
;		Carry clear - matching SFT was found and all collapsing done.
;		    AX has proper handle
;   Registers Revised: all.
;
;******************* END OF SPECIFICATIONS *************************************

   Procedure ShCol,NEAR

   ASSUME CS:SHARE,DS:NOTHING,ES:NOTHING,SS:DOSGROUP

					;---------------------------------------
					; Collapse the files ONLY if
					;  the mode is for net FCB's
					;---------------------------------------

   MOV	AL,BYTE PTR [SI].sf_mode
   AND	AL,sharing_mask
   CMP	AL,sharing_net_FCB
   JNZ	UseJFN

					;---------------------------------------
					; In share support
					;---------------------------------------

   XOR	BX,BX				;   for (i=0; sffromsfn(i); i++) {
OpenScan:

   CallInstall SFFromSFN,multDOS,22,bx,bx

   JC	UseJFN

   CallInstall PointComp,multDOS,20	;	if (!pointcomp (s,d))

   JZ	OpenNext
   CMP	ES:[DI].sf_ref_count,0
   JZ	OpenNext
   MOV	AX,ES:[DI].sf_mode
   CMP	AX,[SI].sf_mode
   JNZ	OpenNext
   MOV	AX,ES:[DI].sf_mft
   CMP	AX,[SI].sf_mft
   JNZ	OpenNext
   MOV	AX,WORD PTR ES:[DI].sf_UID
   CMP	AX,WORD PTR [SI].sf_uid
   JNZ	OpenNext
   MOV	AX,WORD PTR ES:[DI].sf_pid
   CMP	AX,WORD PTR [SI].sf_pid
   JZ	OpenFound
OpenNext:
   INC	BX
   JMP	OpenScan
					;--------------------------------------
					; DS:SI points to an sft which is a
					;	 duplicate of that found in
					; ES:DI is the older one.
					;
					; We call mftclose to release the
					;   appropriate info.
					;--------------------------------------
OpenFound:
   MOV	[SI].sf_ref_count,0		; free 'new' sft

   SaveReg <DS,SI,ES,DI,BX>

   Context DS

   LES	DI,ThisSFT

   call MFTClose

   RestoreReg <AX,DI,ES,SI,DS>

   ASSUME DS:NOTHING

   INC	ES:[DI].sf_ref_count		;   d->refcount++;
   XOR	BX,BX				; find jfn with sfn as contents
JFNScan:

   CallInstall pJFNFromHandle,multDOS,32,AX,AX

   JC	UseJFN				; ran out of handles?
   CMP	AL,BYTE PTR ES:[DI]		; does JFN have SFN?
   jz	JFNfound			; YES, go return JFN
   INC	BX				; no, look at next
   JMP	JFNScan
JFNFound:
   LDS	SI,pJFN
   MOV	BYTE PTR [SI],0FFh		; free JFN
   MOV	AX,BX				; return JFN

   ret

UseJFN:
   MOV	AX,JFN

   ret

   EndProc ShCol

   Break <ShCloseFile - close a particular file for a particular UID/PID>

;******************* START OF SPECIFICATIONS ***********************************
;
;   ShCloseFile - close a particular file for a particular UID/PID
;
;   ShCloseFile - Compatability mode programs will often delete files that
;   they had open.  This was perfectly valid in the 2.0 days, but this
;   presents a reliability problem in the network based operating environment.
;   As a result, both RENAME and DELETE will call us to see if the file is
;   open by is only.  If it is not open or is open by us only, we close it.
;   Note that we will ONLY close compatability SFTs.
;   Otherwise, we signal and error.
;
;   Inputs:	WFT_Start has a DOSGROUP offset to the file name
;		DS is DOSGroup
;   Outputs:	nothing relevant.
;   Registers Revised: None.
;
;******************* END OF SPECIFICATIONS *************************************

   Procedure ShCloseFile,NEAR

   ASSUME DS:DOSGroup,ES:NOTHING,SS:DOSGroup

   SaveReg <AX,BX,CX,DX,SI,DI,BP,DS,ES>

   EnterCrit critShare

ShCl:
   MOV	SI,WFP_Start
   XOR	AL,AL

   call FNM				; attempt to find name in list

   ASSUME DS:NOTHING

   JC	ShCloseDone			; can't find, signal success

					;--------------------------------------
					; We have found a file in the MFT.
					;  Walk the open sft list to find
					;  the SFTs for the current UID/PID.
					;--------------------------------------
   MOV	CX,DS
   LDS	SI,[BX].mft_sptr
ShClCheck:
   MOV	AX,Proc_ID
   CMP	[SI].sf_PID,AX
   JNZ	ShCloseDone
   MOV	AX,User_ID
   CMP	[SI].sf_UID,AX
   JNZ	ShCloseDone
   MOV	AX,[SI].sf_mode
   AND	AX,sharing_mask
   CMP	AX,sharing_net_fcb
   jz	ShClNext
   CMP	AX,sharing_compat
   jnz	ShCloseDOne
ShClNext:
   LDS	SI,[SI].sf_chain
   OR	SI,SI
   JNZ	ShClCheck
   MOV	DS,CX
   LDS	SI,[BX].mft_sptr
					;--------------------------------------
					; Everything matches.  Set up ThisSFT
					;  and walk the chain from the beginning.
					;--------------------------------------
   MOV	WORD PTR ThisSFT,SI
   MOV	WORD PTR ThisSFT+2,DS
					;--------------------------------------
					; Close all handles for this SFT
					;--------------------------------------
   call CPS
					;--------------------------------------
					; Close the sft itself.
					;--------------------------------------
   Context DS

   CallInstall DOS_Close,multDos,1
					;--------------------------------------
					; The SFT may be free and we have no
					;  idea where the next is.  Go and loop
					;  all over.
					;--------------------------------------
   JMP	ShCl
					;--------------------------------------
					; There are no more SFTs to close. Leave
					;---------------------------------------
ShCloseDone:

   LeaveCrit critShare

   STC

   RestoreReg <ES,DS,BP,DI,SI,DX,CX,BX,AX>

   ret

   EndProc ShCloseFile

   .xall
   Break <ShSU - update all SFTs for a specified change>
;******************* START OF SPECIFICATIONS ***********************************
;
;  NAME:	   ShSU - update all SFTs for a specified change>
;
;  FUNCTION:	   In a shared environment, we want to propogate the SFT
;		   changes for a particular file to all other SFTs for that
;		   file.  The types of things we propogate are:
;
;		   - Time of last write - we only do this on CLOSE and on
;		     FILETIMES.
;
;		   - Size and allocation information - we do this ONLY when
;		     we change sf_size.
;
;		   We achieve this by walking the linked list of SFTs for the
;		   file. See PSEUDOCODE below
;
;  INPUT:	   ES.DI  has SFT that was just Revised.
;		   AX = 0 for updating of time from ES:DI into old sfts
;		   AX = 1 for updating of size/allocation for growth from ES:DI
;		   AX = 2 for updating of size/allocation for shrink from ES:DI
;		   AX = 3 for new instance copy into ES:DI
;		   AX = 4 for update of codepage and high attribute
;
;  OUTPUT:	   All relevant SFTs are updated.
;
;  REGISTERS USED: All except ES:DI and DS:SI
;  (NOT RESTORED)
;
;  LINKAGE:	   DOS Jump Table
;
;  EXTERNAL	   Invoke: New_Sft, Call_IFS
;  REFERENCES:	   Callinstall
;
;  NORMAL	   -
;  EXIT:
;
;  ERROR	   -
;  EXIT:
;
;  CHANGE	   04/15/87 - Major overhaul and IFS support
;  LOG:
;
;******************* END OF SPECIFICATIONS *************************************
;******************+ START OF PSEUDOCODE +**************************************
;
;	START ShSU
;
;	if not a device and
;	if not a network
;		search
;			if our SFT
;				advance to next SFT
;			endif
;		leave if no more SFT's
;		exitif cx = 3
;			invoke New_Sft
;		orelse
;			if cx = 0
;				update time
;				update date
;				if non - FAT file system
;					call IFSFUNC
;				endif
;			else cx = 1 or 2
;				update size
;				if non - FAT file system
;					call IFSFUNC
;				else
;					update first cluster
;					if cx = 2 or
;					if lstclus un-set from create
;						update cluster position
;						update last cluster
;					endif
;				endif
;			endif
;			advance to next SFT
;		endloop
;		endsearch
;	endif
;	return
;
;	END ShSU
;
;******************+  END  OF PSEUDOCODE +**************************************

   Procedure ShSU,near

   ASSUME DS:NOTHING,ES:NOTHING

   nop
;  int 3
   nop

ifs_flag equ 8000h			;				       ;AN000;
					;---------------------------------------
					; Do nothing for device or network
					;---------------------------------------
   mov	bx,es:[di].sf_mode
   and	bx,sf_isnet + devid_device

;  $if	z,and,long			; if not device and		       ;AC000;
   JZ $$XL1
   JMP $$IF4
$$XL1:

   mov	bx,es:[di].sf_MFT
   or	bx,bx

;  $if	nz,,long			; if not network		       ;AC000;
   JNZ $$XL2
   JMP $$IF4
$$XL2:

       EnterCrit critShare
					;---------------------------------------
					; Walk the sft chain for this file and
					;  skip the current SFT (ES:DI)
					;---------------------------------------
       SaveReg <DS,SI>

       lds  si,cs:[bx].MFT_SPTR
       mov  cx,ax

;      $search				;				       ;AC000;
$$DO5:

	   CallInstall PointComp,multDOS,20 ; pointers different?

;	   $if	z			; if ourselves			       ;AC000;
	   JNZ $$IF6

	       lds  si,[si].sf_chain	; move to next			       ;AC000;

;	   $endif			; endif - ourselves		       ;AC000;
$$IF6:

	   or	si,si

;      $leave z 			;				       ;AC000;
       JZ $$EN5

					;---------------------------------------
					; CX = 0 for updating of time
					; CX = 1 for updating of size/allocation
					;	   for growth
					; CX = 2 for updating of size/allocation
					;	   for shrink
					; CX = 3 for new instance copy.
					;---------------------------------------
	   cmp	cx,2			;				       ;AC000;

;      $exitif a			;				       ;AC000;
       JNA $$IF5
					;---------------------------------------
					; CX = 3 for new instance copy.
					; CX = 4 for codepage and high attrib update
					;---------------------------------------
	   cmp	cx,3			; cx = 3 ?			       ;an000;
;	   $if	e			; yes				       ;an000;
	   JNE $$IF10
	       call New_Sft		;				       ;AN000;
;;	   $else			; cx = 4			       ;an000;
;;	       call New_CP_Attrib	; update codepage and high attrib      ;an000;
;	   $endif			;				       ;an000;
$$IF10:

;      $orelse				;				       ;AC000;
       JMP SHORT $$SR5
$$IF5:

	   or	cx,cx

;	   $if	z			; if cx = 0 then		       ;AC000;
	   JNZ $$IF13
					;---------------------------------------
					; CX = 0 for updating of time
					;
					; Copy time from ES:DI into DS:SI
					;---------------------------------------
	       mov  bx,es:[di].sf_time
	       mov  [si].sf_time,bx
	       mov  bx,es:[di].sf_date
	       mov  [si].sf_date,bx
	       test [si].sf_flags,ifs_flag ;				       ;AN000;

;	       $if  nz			; if non-FAT			       ;AC003;
	       JZ $$IF14

		   call Call_IFS	; tell IFS of SFT change	       ;AN000;

;	       $endif			; endif non- FAT		       ;AN000;
$$IF14:

;	   $else			; else - must be >0 and <2	       ;AC000;
	   JMP SHORT $$EN13
$$IF13:
					;---------------------------------------
					; CX = 1 for updating of size/allocation
					;	  for growth
					; CX = 2 for updating of size/allocation
					;	  for shrink
					;
					; We always copy size and firclus
					;---------------------------------------
	       mov  bx,word ptr es:[di].sf_size
	       mov  word ptr [si].sf_size,bx
	       mov  bx,word ptr es:[di].sf_size+2
	       mov  word ptr [si].sf_size+2,bx
	       test [si].sf_flags,ifs_flag ;				       ;AN000;

;	       $if  nz			; if non-FAT			       ;AC003;
	       JZ $$IF17

		   invoke Call_IFS	; tell IFS of SFT change	       ;AN000;

;	       $else			; else - its FAT		       ;AN000;
	       JMP SHORT $$EN17
$$IF17:

		   mov	bx,es:[di].sf_firclus
		   mov	[si].sf_firclus,bx
		   cmp	cx,2		;				       ;AC000;

;		   $if	z,or		; if SFT is shrinking or	       ;AC000;
		   JZ $$LL19

		   cmp	[si].sf_lstclus,0 ; lstclus UN-set from a create?      ;AC000;

;		   $if	z		; If it is, set lstclus and cluspos too;AC000;
		   JNZ $$IF19
$$LL19:
					;---------------------------------------
					; Shrink the file, move in new cluspos
					;  and lstclus
					;---------------------------------------
		       mov  [si].sf_cluspos,0 ; retrace from start
		       mov  [si].sf_lstclus,bx ; ditto

;		   $endif		; endif - set lstclus and cluspos      ;AC000;
$$IF19:

;	       $endif			; endif  FAT			       ;AN000;
$$EN17:

;	   $endif			; enndif - > 0			       ;AC000;
$$EN13:
					;---------------------------------------
					; Link to next SFT
					;---------------------------------------
	   lds	si,[si].sf_chain

;      $endloop 			;				       ;AC000;
       JMP SHORT $$DO5
$$EN5:

;      $endsrch 			;				       ;AC000;
$$SR5:
					;---------------------------------------
					; All Done
					;---------------------------------------
       RestoreReg <SI,DS>

       LeaveCrit critShare

;  $endif				; endif - device and network	       ;AC000;
$$IF4:

   ret

   EndProc ShSU

   Break <New_Sft - update a new SFT>

;******************* START OF SPECIFICATIONS ***********************************
;
;  NAME:	   New_Sft - update a new SFT
;
;  FUNCTION:	   Copy all SFT information into a NEW sft of a SHARED file.
;
;
;  INPUT:	   ES.DI  has SFT that was just Revised.
;		   DS:SI  has SFT that is to be updated
;
;  OUTPUT:	   SFT is updated.
;
;  REGISTERS USED: AX, BX
;  (NOT RESTORED)
;
;  LINKAGE:	   Invoked by: ShSU
;
;  EXTERNAL	   Invoke: Call_IFS
;  REFERENCES:
;
;  CHANGE	   04/15/87 - First release
;  LOG:
;
;******************* END OF SPECIFICATIONS *************************************
;******************+ START OF PSEUDOCODE +**************************************
;
;	START New_Sft
;
;	update time
;	update date
;	update size
;	if   non - FAT file system
;		call IFSFUNC
;	else
;		update first cluster
;		update cluster position
;		update last cluster
;	endif
;	return
;
;	END New_Sft
;
;******************+  END  OF PSEUDOCODE +**************************************

   Procedure New_Sft,near		;				       ;AN000;

   mov	bx,[si].sf_time 		; update time
   mov	es:[di].sf_time,bx
   mov	bx,[si].sf_date 		; update date
   mov	es:[di].sf_date,bx
   mov	bx,word ptr [si].sf_size	; update size
   mov	word ptr es:[di].sf_size,bx
   mov	bx,word ptr [si].sf_size+2
   mov	word ptr es:[di].sf_size+2,bx
   test es:[di].sf_flags,ifs_flag	;				       ;AN000;

;  $if	nz				; if non-FAT			       ;AC003;
   JZ $$IF26

       call Call_IFS			; tell IFS of SFT change	       ;AN000;

;  $else				; else - its FAT		       ;AN000;
   JMP SHORT $$EN26
$$IF26:

       mov  bx,[si].sf_firclus		; update first cluster
       mov  es:[di].sf_firclus,bx
       mov  es:[di].sf_cluspos,0	; retrace from start
       mov  es:[di].sf_lstclus,bx	; ditto

;  $endif				; endif  FAT			       ;AN000;
$$EN26:

   ret					; we'er done                           ;AN000;

   EndProc New_Sft			;				       ;AN000;

   Break <New_CP_Attrib - update the codepage and attrib in SFT>

;******************* START OF SPECIFICATIONS ***********************************
;
;  NAME:	   New_CP_Attrib - Update codepage and attrib in SFT
;
;  FUNCTION:	   Copy all codepage and attrib into SFT of a SHARED file.
;
;
;  INPUT:	   ES.DI  has SFT that was just Revised.
;		   DS:SI  has SFT that is to be updated
;
;  OUTPUT:	   SFT is updated.
;
;  REGISTERS USED: AX, BX
;  (NOT RESTORED)
;
;  LINKAGE:	   Invoked by: ShSU
;
;  EXTERNAL	   Invoke: Call_IFS
;  REFERENCES:
;
;  CHANGE	   10/06/87 - First release	- D. M. Sewell
;  LOG:
;
;******************* END OF SPECIFICATIONS *************************************
;******************+ START OF PSEUDOCODE +**************************************
;
;	START New_CP_Attrib
;
;	Update codepage
;	Update high attribute
;	$if ifs_flag
;		call Call_IFS
;	$endif
;	return
;
;	END New_CP_Attrib
;
;******************+  END  OF PSEUDOCODE +**************************************

;; Procedure New_CP_Attrib,near 	;				       ;AN000;

;; mov	bx,es:[di].SF_Codepage		; update codepage		       ;an000;
;; mov	[si].SF_Codepage,bx		;an000; dms;
;; mov	bl,es:[di].SF_Attr_Hi		; update high attribute 	       ;an000;
;; mov	[si].SF_Attr,bl 		;an000; dms;
;; test es:[di].sf_flags,ifs_flag	;				       ;AN000;

;; $if	nz				; if non-FAT			       ;AC003;

;;     call Call_IFS			; tell IFS of SFT change	       ;AN000;

;; $endif				; endif  FAT			       ;AN000;

;; ret					; we'er done                           ;AN000;

;; EndProc New_CP_Attrib		;				       ;AN000;


   Break <Call_IFS - warn IFS that SFT has changed>

;******************* START OF SPECIFICATIONS ***********************************
;
;  NAME:	   Call_IFS - warn IFS that SFT has changed
;
;  FUNCTION:	   Call IFS thru 2F interupt.
;
;  INPUT:	   DS.SI  points to SFT that was just Revised.
;
;  OUTPUT:	   none
;
;  REGISTERS USED: AX
;  (NOT RESTORED)
;
;  LINKAGE:	   Invoked by: ShSU, New_SFT
;
;  EXTERNAL	   Callinstall
;  REFERENCES:
;
;  CHANGE	   04/15/87 - First release
;  LOG:
;
;******************* END OF SPECIFICATIONS *************************************
;******************+ START OF PSEUDOCODE +**************************************
;
;	START Call_IFS
;
;	set up for INT
;	INT 2F
;	return
;
;	END Call_IFS
;
;******************+  END  OF PSEUDOCODE +**************************************

   Procedure Call_IFS,near		;				       ;AN000;

   CallInstall BlockUpdate,MultIFS,44,CX,CX ;				       ;AC005;

   ret					;				       ;AN000;

   EndProc Call_IFS			;				       ;AN000;

   Break <Internal error routines>

;******************* START OF SPECIFICATIONS ***********************************
;
; INTERR - INTernal ERRor routines
;
;******************* END OF SPECIFICATIONS *************************************

   Procedure INTERR,NEAR

   ASSUME DS:NOTHING,ES:NOTHING,SS:NOTHING

   SaveReg <BX,SI,DS>			; save registers that get clobbered

   push cs				; gain addressability
   pop	ds
   mov	si,ax				; get message to print

   call gout

   off	si,IntErrMSG

   call gout

   RestoreReg <ds,si,bx>

INTERRL:jmp INTERRL			; hang here - we're sick

gout: lodsb
   or	al,al
   retz
   mov	ah,14
   int	10h
   jmp	gout

IntErrMsg DB "Share: Internal error", 13, 10, 0

   EndProc INTERR

   Break <INT 2F handler>

   IF	installed

       public skip_check

skip_check db 0 			; start with do checking

state_change db 0			; SHARE change in state flag
					; 0 - no change in state
					; 1 - SHARE load state has changed

CONT   DD   ?

INT2F  PROC FAR

       ASSUME CS:SHARE,DS:NOTHING,ES:NOTHING,SS:NOTHING
       cmp  ah,multSHARE
       jnz  ContJ

; Its for SHARE!  Check to see who is calling:

; AL =
;      81h its us, with /NC - set skip_check
;			    - return 0F0h - end init
;      80h its us
;	if skip_check is reset
;			    - return 0FFh - loaded
;	if skip_check is set
;			    - reset skip_check
;			    - return 0F0h - end init
;
;      40h its IFSFUNC	    - return 0FFh - loaded
;
;      00h its anyone else  - clear skip_check
;			    - return 0FFh - loaded

       test al,80h			; is it share?			       ;AN010;
;      $if  nz				; if it is			       ;AN010;
       JZ $$IF29
	   and	al,1			; is /NC set			       ;AN010;
	   mov	al,0F0H 		; assume a quiet return 	       ;AN010;
;	   $if	nz			; if it is			       ;AN010;
	   JZ $$IF30
	       cmp  skip_check,1	; is skip_check set ?		       ;AN011;
;	       $if  ne			; if it is			       ;AN011;
	       JE $$IF31
		   mov	state_change,1	; set the change state flag	       ;AN011;
;	       $endif			;				       ;AN011;
$$IF31:
	       mov  skip_check,1	; set skip_check		       ;AN010;
;	   $else			;  /NC not requested		       ;AN010;
	   JMP SHORT $$EN30
$$IF30:
	       cmp  skip_check,1	; is skip_check set ?		       ;AN010;
;	       $if  e			; if it is			       ;AN010;
	       JNE $$IF34
		   mov	state_change,1	; set the change state flag	       ;AN011;
		   mov	skip_check,0	; reset skip_check		       ;AN010;
;	       $else			; else , its already clear	       ;AN010;
	       JMP SHORT $$EN34
$$IF34:
		   mov	al,0FFH 	;    and we are loaded		       ;AN010;
;	       $endif			;				       ;AN010;
$$EN34:
;	   $endif			;				       ;AN010;
$$EN30:

;      $else				;				       ;AN010;
       JMP SHORT $$EN29
$$IF29:
	   cmp	al,40h			; is it IFSFUNC?		       ;AN010;
;	   $if	ne			; if it is not			       ;AN010;
	   JE $$IF39

	       or   al,al		;    loop it any other value caus'     ;AC010;
Freeze:
	       jnz  freeze		;    no one should EVER issue this     ;AC010;
	       cmp  skip_check,1	; is skip_check set ?		       ;AN010;
;	       $if  e			; if it is			       ;AN011;
	       JNE $$IF40
		   mov	state_change,1	; set the change state flag	       ;AN011;
;	       $endif			;				       ;AN011;
$$IF40:
	       mov  skip_check,0	;    and believe it !		       ;AN011;

;	   $endif			;				       ;AN010;
$$IF39:
	   mov	al,0FFH 		;  else - say we are here	       ;AN010;
;      $endif				;				       ;AN010;
$$EN29:
       cmp  state_change,1		; SHARE installed state may have change;AN011;d
;      $if  e				;    - update DOS		       ;AN011;
       JNE $$IF44
	   push ax			;				       ;AN011;
	   push es			;  this is interesting -	       ;AN011;
	   MOV	AH,Get_In_Vars		;    if SHARE =1 and DOS =1 - no change;AN011;
	   INT	21h			;    if SHARE = 		       ;AN011;

	   ASSUME ES:DOSGROUP

	   mov	al,skip_check		; get the SHARE operating mode	       ;AN011;
	   cmp	al,1			;  is it a /nc	  -  tell DOS  " 1 "   ;AN011;
;	   $if	ne			; if not			       ;AN011;
	   JE $$IF45
	       dec  al			;   "full" SHARE  -  tell DOS  " -1 "  ;AN011;
;	   $endif			;				       ;AN011;
$$IF45:
	   MOV	fShare,al		; tell DOS we are here		       ;AN011;
	   pop	es			;				       ;AN011;
	   pop	ax			;				       ;AN011;
	   mov	state_change,0		; REset the change state flag	       ;AN011;
;      $endif				;				       ;AN011;
$$IF44:

       ASSUME ES:nothing

       iret
ContJ:
       JMP  CONT
INT2F  ENDP

       ASSUME CS:SHARE,DS:NOTHING,ES:NOTHING,SS:DOSGroup

IRP    rtn,<MFT_enter, MFTClose, MFTclU, MFTCloseP, MFTCloN, set_mult_block, clr_mult_block>
J&rtn  proc far
       call rtn
       ret
j&rtn  endp
endm

IRP    rtn,<chk_block, MFT_get, ShSave, ShChk, ShCol, ShCloseFile, ShSU>
J&rtn  proc far
       call rtn
       ret
j&rtn  endp
endm

IRP    sect,<critShare>
       Procedure E&sect,NEAR
       PUSH AX
       MOV  AX,8000h+sect
       INT  int_ibm
       POP  AX
       ret
       EndProc E&sect

       Procedure L&sect,NEAR
       PUSH AX
       MOV  AX,8100h+sect
       INT  int_ibm
       POP  AX
       ret
       EndProc L&sect
       ENDM

   ENDIF

   BREAK <MFT and Lock Record Data Area>

;******************* START OF SPECIFICATIONS ***********************************
;
;	first MFT record
;
;	Note that the name field can have garbage after the trailing
;	00 byte.  This is because the field might be too long, but
;	not long enough (at least 16 extra bytes) to fragment.
;	in this case we copy the length of the string area, not
;	the length of the string and thus may copy tailing garbage.
;
;******************* END OF SPECIFICATIONS *************************************

PoolSize = 2048

   PUBLIC MFT

MFT DB	0				; free
   DW	PoolSize			; PoolSize bytes long

   IF	not  Installed

       DB   (PoolSize-3) DUP(0) 	; leave rest of record
MEND   DB   -1				; END record

lck1   DW   0				; link
       DB   SIZE RLR_entry-2 DUP(0)
lck2   DW   OFFSET DOSGROUP:lck1	; link
       DB   SIZE RLR_entry-2 DUP(0)
lck3   DW   OFFSET DOSGROUP:lck2	; link
       DB   SIZE RLR_entry-2 DUP(0)
lck4   DW   OFFSET DOSGROUP:lck3	; link
       DB   SIZE RLR_entry-2 DUP(0)
lck5   DW   OFFSET DOSGROUP:lck4	; link
       DB   SIZE RLR_entry-2 DUP(0)
lck6   DW   OFFSET DOSGROUP:lck5	; link
       DB   SIZE RLR_entry-2 DUP(0)
lck7   DW   OFFSET DOSGROUP:lck6	; link
       DB   SIZE RLR_entry-2 DUP(0)
lck8   DW   OFFSET DOSGROUP:lck7	; link
       DB   SIZE RLR_entry-2 DUP(0)

       CODE ENDS

       %out Ignore this END error (blasted assembler)

   ENDIF

IF Installed

   ASSUME CS:SHARE,DS:NOTHING,ES:NOTHING,SS:NOTHING

   IF1
InitSpace DW PoolSize
   ELSE
       IF   shareinit-MFT LT PoolSize
InitSpace  DW	PoolSize
       ELSE
InitSpace  DW	shareinit-MFT
       ENDIF
   ENDIF
InitLocks DW 20


JTable LABEL BYTE
   DD	?
   DD	JMFT_Enter			;   1	MFT_enter
   DD	JMFTClose			;   2	MFTClose
   DD	JMFTclU 			;   3	MFTclU
   DD	JMFTcloseP			;   4	MFTCloseP
   DD	JMFTcloN			;   5	MFTCloN
   DD	JSet_Mult_Block 		;   6	Set_Mult_Block
   DD	JClr_Mult_Block 		;   7	Clr_Mult_Block
   DD	JChk_Block			;   8	Chk_Block
   DD	JMFT_Get			;   9	MFT_get
   DD	JShSave 			;   10	ShSave
   DD	JShChk				;   11	ShChk
   DD	JShCol				;   12	ShCol
   DD	JShCloseFile			;   13	ShCloseFile
   DD	JShSU				;   14	ShSU
JTableLen = $ - JTable

;	$SALUT	(4,9,17,36)
				   ;---------------------------------------
				   ;  STRUCTURE TO DEFINE ADDITIONAL
				   ;  COMMAND LINE PARAMETERS
				   ;---------------------------------------
PARMS	LABEL	DWORD
	DW	OFFSET PARMSX	   ; POINTER TO PARMS STRUCTURE
	DB	0		   ; NO DELIMITER LIST FOLLOWS
	DB	0		   ; NUMBER OF ADDITIONAL DELIMITERS

				   ;---------------------------------------
				   ;  STRUCTURE TO DEFINE SORT
				   ;  SYNTAX REQUIREMENTS
				   ;---------------------------------------
PARMSX	LABEL	BYTE
	DB	0,0		   ; THERE ARE NO POSITIONAL PARAMETERS
	DB	1		   ; THERE ARE ONLY ONE TYPE OF SWITCH
	DW	OFFSET SW	   ; POINTER TO THE SWITCH DEFINITION AREA
	DW	0		   ; THERE ARE NO KEYWORDS IN SHARE SYNTAX

				   ;---------------------------------------
				   ;  STRUCTURE TO DEFINE THE SWITCHES
				   ;---------------------------------------

SW	LABEL	WORD
	DW	08001H		   ; MUST BE NUMERIC
	DW	0		   ; NO FUNCTION FLAGS
	DW	OFFSET SWITCH_BUFF ; PLACE RESULT IN SWITCH BUFFER
	DW	OFFSET VALUES	   ; NEED VALUE LIST
	DB	3		   ; TWO SWITCHES IN FOLLOWING LIST
F_SW	DB	"/F",0		   ; /F: INDICATES n FILESPACE REQUESTED
L_SW	DB	"/L",0		   ; /L: INDICATES m LOCKS REQUESTED
N_SW	DB	"/NC",0 	   ; /NC: INDICATES no checking required


				   ;---------------------------------------
				   ;  VALUE LIST DEFINITION FOR n
				   ;---------------------------------------

VALUES	LABEL	BYTE
	DB	1		   ; ONE VALUE ALLOWED
	DB	1		   ; ONLY ONE RANGE
	DB	FILE_SWITCH	   ; IDENTIFY IT AS n
	DD	1,65535 	   ; USER CAN SPECIFY /+1 THROUGH /+65535

				   ;---------------------------------------
				   ;  RETURN BUFFER FOR SWITCH INFORMATION
				   ;---------------------------------------
;		$SALUT	  (4,17,27,36)

SWITCH_BUFF	LABEL	  BYTE
SW_TYPE 	DB	  ?	   ; TYPE RETURNED
SW_ITEM_TAG	DB	  ?	   ; SPACE FOR ITEM TAG
SW_SYN		DW	  ?	   ; POINTER TO SWITCH LIST ENTRY
SW_VALUE	DD	  ?	   ; SPACE FOR VALUE

;  $SALUT (4,4,9,41)

   Break <INIT - INITalization routines>

;******************* START OF SPECIFICATIONS ***********************************
;
; INIT - INITalization routines
;
;******************* END OF SPECIFICATIONS *************************************

   Procedure Init,NEAR

   PUSH CS
   POP	DS

   ASSUME DS:SHARE

   MOV	BX,InitSpace

   SUB	BX,3
   MOV	SI,OFFSET MFT
   MOV	WORD PTR [SI+1],BX		; length of first item
   ADD	SI,BX				; link to end of structure
   MOV	BYTE PTR [SI],-1		; signal end
   INC	SI				; point to next free byte

   MOV	CX,initlocks			; count for loop
   MOV	AX,0

;  $do					;				       ;AC000;
$$DO48:

       MOV  [SI].RLR_next,AX		; link in previous
       MOV  AX,SI			; this is now previous
       ADD  SI,SIZE RLR_Entry		; move to next object

;  $enddo loop				;				       ;AC000;
   LOOP $$DO48

   MOV	FreLock,AX			; point to beginning of free list

   MOV	DX,CS
   MOV	BX,ES
   SUB	DX,BX
   ADD	SI,15
   RCR	SI,1
   SHR	SI,1
   SHR	SI,1
   SHR	SI,1

   ADD	SI,DX
   PUSH SI				; # of paras for share on stack

   MOV	AX,(Get_Interrupt_Vector SHL 8) + 2Fh
   INT	21h
   MOV	WORD PTR CONT,BX
   MOV	WORD PTR CONT+2,ES
   MOV	AX,(Set_Interrupt_Vector SHL 8) + 2Fh
   MOV	DX,OFFSET INT2F
   INT	21h
					;---------------------------------------
					; Notify the DOS that we are around so that
					; the DOS can make expensive calls to us.
					;---------------------------------------
   MOV	AH,Get_In_Vars
   INT	21h

   ASSUME ES:DOSGROUP

   mov	al,skip_check			; get the SHARE operating mode	       ;AN011;
   cmp	al,1				;  is it a /nc	  -  tell DOS  " 1 "   ;AN011;

;  $if	ne				; if not			       ;AN011;
   JE $$IF50
       dec  al				;   "full" SHARE  -  tell DOS  " -1 "  ;AN011;
;  $endif				;
$$IF50:

   MOV	fShare,al			; tell DOS we are here		       ;AC011;
					;---------------------------------------
					; Cram in the new jump table
					;---------------------------------------
   CLI
   MOV	SI,OFFSET JTable
   MOV	DI,OFFSET JShare
   MOV	CX,JTableLen/2
   REP	MOVSW
					;---------------------------------------
					; Examine the size of the FCB cache.
					; If it is NOT the system default of 4,0
					; change it (via reallocation) to 16,8.
					; The old table is lost.
					;---------------------------------------
   ASSUME DS:NOTHING

   CMP	KeepCount,0

;  $if	z,and				; if the ",0"  part and 	       ;AC000;
   JNZ $$IF52

   LDS	SI,ES:[BX].SYSI_FCB		; point to the existing cache
   CMP	[SI].sfCount,4

;  $if	z				; if the "4,"  part then	       ;AC000;
   JNZ $$IF52

					;---------------------------------------
					; Whammo, we need to allocate 16 * size
					; of SF_entry + size of sfTable.
					; Compute this size in paragraphs
					;---------------------------------------
       MOV  AX,16
       MOV  CX,size sf_entry
       MUL  CX
       ADD  AX,(size sf) - 2
					;---------------------------------------
					; This size is in bytes...
					; Round up to paragraph size
					;---------------------------------------
       ADD  AX,0Fh
       RCR  AX,1
       SHR  AX,1
       SHR  AX,1
       SHR  AX,1
					;---------------------------------------
					; AX is the number of paragraphs to add.
					; Word on stack is current TNR size.
					; Make dos point to new table
					;---------------------------------------
       MOV  WORD PTR ES:[BX].SYSI_FCB,0
       MOV  WORD PTR ES:[BX].SYSI_FCB+2,SS
       POP  SI
       ADD  WORD PTR ES:[BX].SYSI_FCB+2,SI
					;---------------------------------------
					; Initialize table parts, next link
					;   and size
					;---------------------------------------
       MOV  DS,WORD PTR ES:[BX].SYSI_FCB+2
       MOV  WORD PTR DS:[sfLink],-1
       MOV  WORD PTR DS:[sfLink+2],-1
       MOV  DS:[sfcount],16
					;---------------------------------------
					; Set up succeeding LRU size
					;---------------------------------------
       MOV  KeepCount,8

       ADD  SI,AX
       PUSH SI

;  $endif				; endif - "4,0" 		       ;AC000;
$$IF52:

					;---------------------------------------
					; Clean out the FCB Cache
					;---------------------------------------
   LES	DI,ES:[BX].SYSI_FCB

   ASSUME ES:Nothing

   MOV	CX,ES:[DI].SFCount
   LEA	DI,[DI].SFTable

;  $do					;				       ;AC000;
$$DO54:

       MOV  ES:[DI].sf_ref_count,0
       MOV  WORD PTR ES:[DI].sf_position,0
       MOV  WORD PTR ES:[DI].sf_position+2,0
       ADD  DI,SIZE sf_entry

;  $enddo loop				;				       ;AC000;
   LOOP $$DO54

   STI

   ASSUME ES:NOTHING

   XOR	BX,BX
   MOV	CX,5				; StdIN,StdOUT,StdERR,StdAUX,StdPRN

;  $do					; Close STD handles before	       ;AC000;
$$DO56:
					; keep process
       MOV  AH,CLOSE
       INT  21H
       INC  BX

;  $enddo loop				;				       ;AC000;
   LOOP $$DO56

   POP	DX				; T+R size in DX
   MOV	AX,(Keep_Process SHL 8) + 0
   INT	21h
   MOV	AX,(EXIT SHL 8) + 1
   INT	21h				; We'er now resident, return to DOS

   EndProc Init

   Break <SHAREINIT - Share initialization entry point>

;******************* START OF SPECIFICATIONS ***********************************
;
; SHAREINIT - Share initialization entry point
;
;******************* END OF SPECIFICATIONS *************************************

   Procedure SHAREINIT,NEAR

   ASSUME CS:SHARE,DS:NOTHING,ES:NOTHING,SS:STACK

;  int 3
   nop
   nop


   PUSH DS				; save PSP segment for later stack     ;AC001;
					;     relocation

					;---------------------------------------
					; Load Messages
					;---------------------------------------
   call ShLoadMsg			;				       ;AN000;
					;---------------------------------------
					; At this point, the DOS version is OK.
					;  (checked by SYSLOADMSG)
					;  Now - Check the DOS data version
					;---------------------------------------
;  $if	c,or				; if not same as us			;AC009;
   JC $$LL58

   MOV	AH,Get_In_Vars
   INT	21h

   ASSUME ES:DOSGROUP

   CMP	DataVersion,ShareDataVersion

   ASSUME ES:NOTHING

;  $if	ne				; if not same as us			;AC000;
   JE $$IF58
$$LL58:
       mov  ax,(Utility_Msg_CLASS shl 8) + Bad_DOS_Ver ;			;AN000;
       call ShDispMsg			;					;AN000;
;  $endif				; endif - not same as us		;AC000;
$$IF58:

					;---------------------------------------
					; Deallocate memory if possible
					;---------------------------------------
   mov	ax,ds:[pdb_environ]
   or	ax,ax

;  $if	nz				; if > 0 deallocate memory	       ;AC000;
   JZ $$IF60
       mov  es,ax
       mov  ah,dealloc
       int  21h
;  $endif				; endif - > 0 deallocate memory        ;AC000;
$$IF60:

					;---------------------------------------
					; Parse the command line
					;---------------------------------------
   call ShComndParse			;				       ;AN000;
					;---------------------------------------
					; Check to see if share already installed.
					;---------------------------------------
   mov	al,skip_check			;				       ;AN010;
   or	al,80h				; signal its SHARE calling	       ;AN010;
   mov	ah,multShare			;				       ;AC010;
   INT	2Fh				;				       ;AC010;
   CMP	AL,0FFh 			;				       ;AC010;

;  $if	z				; if we'er already loaded              ;AC010;
   JNZ $$IF62
       mov  ax,(UTILITY_MSG_CLASS shl 8) + Sh_Already_Loaded ;		       ;AC010;
       call ShDispMsg			;				       ;AC010;
;  $endif				; endif - we'er already loaded         ;AC010;
$$IF62:

					;---------------------------------------
					; Check to see if share installed and
					; a toggle was just performed
					;---------------------------------------
   CMP	AL,0F0h 			;				       ;AN010;

;  $if	z				; if we'er already loaded              ;AN010;
   JNZ $$IF64

       MOV  AX,(EXIT SHL 8)		;				       ;AN010;
       INT  21h 			; Return to DOS with RC = 0	       ;AN010;

;  $endif				; endif - we'er already loaded         ;AN010;
$$IF64:

					;---------------------------------------
					; All set to initialize the world.
					; Make sure that we have enough memory
					; for everything in our little 64K here.
					; First get avail count of paras.
					;---------------------------------------
   pop	es				; recover PSP segment		       ;AC002;
   push es				;				       ;AC002;
   MOV	BX,CS
   MOV	AX,ES:[PDB_Block_Len]
   SUB	AX,BX
					;---------------------------------------
					; AX has the number of paragraphs
					; available to us after the beginning
					; of CS.  Max this out at 64K.
					;---------------------------------------
   CMP	AX,1000h

;  $if	a				; if more than we can handle	       ;AC000;
   JNA $$IF66
       MOV  AX,1000h			;  force it
;  $endif				; endif - more than we can handle      ;AC000;
$$IF66:

					;---------------------------------------
					; Take AX paragraphs and convert them
					; into BX:CX bytes.
					;---------------------------------------
   XOR	BX,BX
   SHL	AX,1
   SHL	AX,1
   SHL	AX,1
   SHL	AX,1
   ADC	BX,0
   MOV	CX,AX
					;---------------------------------------
					; compute in DX:AX, the size
					; requested by the user
					;---------------------------------------
   MOV	AX,initlocks
   MOV	SI,size RLR_Entry
   MUL	SI
   ADD	AX,OFFSET MFT
   ADC	DX,0
   ADD	AX,InitSpace
   ADC	DX,0
					;---------------------------------------
					; Compare the 32 bit sizes DX:AX and BX:CX.
					; If BX:CX is smaller, then we
					; are out of memory.
					;---------------------------------------

   CMP	DX,BX				; try upper half first

;  $if	a,or				; if most significant is bigger or     ;AC000;
   JA $$LL68

;  $if	e,and				; if equal and			       ;AC000;
   JNE $$IF68

   CMP	AX,CX				;

;  $if	a				; if least significant is bigger       ;AC000;
   JNA $$IF68
$$LL68:

       mov  ax,(EXT_ERR_CLASS shl 8) + No_Mem_Error ; issue error message      ;AN000;

       call ShDispMsg			;				       ;AN000;

;  $endif				; endif - bigger		       ;AC000;
$$IF68:

					;--------------------------------------
					; Move stack to PSP area.  Otherwise we
					; will run into problems with growing
					; the stack into the lock records.
					;---------------------------------------
   POP	AX				; this is the entry value for DS (PSP) ;AC001;
   MOV	SS,AX				;				       ;AC001;
   MOV	SP,100h 			;				       ;AC001;

   ASSUME SS:NOTHING
					;---------------------------------------
					; Continue with rest of initialization
					;---------------------------------------
   JMP	INIT

   EndProc SHAREINIT

   Break <ShLoadMsg  -	Share Load Message>

;******************* START OF SPECIFICATIONS ***********************************
;
;  NAME:	ShLoadMsg  -  Share Load Message
;
;  FUNCTION:	Load the Share messages into the message buffer.
;
;  INPUT:	None
;
;  OUTPUT:	Messages loaded into the message buffer and Message
;		Sevices code initalized
;
;  REGISTERS USED:  DI AX CX DX
;  (NOT RESTORED)
;
;  LINKAGE:	Call near
;
;  NORMAL	CF = O
;  EXIT:
;
;  ERROR	CF = 1
;  EXIT:
;
;  CHANGE	04/15/87 - First release
;  LOG:
;
;******************* END OF SPECIFICATIONS *************************************

					;---------------------------------------
					; Message Equates
					;---------------------------------------

;			  $SALUT (4,27,34,41)

Bad_DOS_Ver		  equ	 1	; Incorrect DOS version 	       ;AN000;
Sh_Already_Loaded	  equ	 2	; SHARE already loaded message number  ;AN000;
No_Mem_Error		  equ	 8	; insufficient memory message number   ;AN000;

;  $SALUT (4,4,9,41)

   Procedure ShLoadMsg,near		;				       ;AN000;
					;---------------------------------------
					; Load the Messages
					;---------------------------------------
EXTRN SYSLOADMSG:NEAR			;				       ;AN000;

   call SYSLOADMSG			;				       ;AN000;

;  $IF	C				; if we have a MAJOR problem	       ;AN000;
   JNC $$IF70
       mov  ah,dh			; save the class
       call ShDispMsg			;				       ;AN000;
					; For pre DOS 2.0, we may come back
       xor  ax,ax			;   here - so do it the old way
       push ss				;   just in case
       push ax				;

xxx    proc far 			;				       ;AN000;
       ret				;				       ;AN000;
xxx    endp				;				       ;AN000;

;  $ENDIF				; endif - we have a MAJOR problem      ;AN000;
$$IF70:


   ret					;				       ;AN000;

   EndProc ShLoadMsg			;

   Break <ShDispMsg  -	Share Display Message>

;******************* START OF SPECIFICATIONS ***********************************
;
;  NAME:	ShDispMsg  -  Share Display Message
;
;  FUNCTION:	Display the messages for share
;
;  INPUT:	AX = message number - AH - Class
;				      AL - Number
;
;  OUTPUT:	- Messages output to Output Device
;		- Exit to DOS
;
;  REGISTERS USED:  CX DX
;  (NOT RESTORED)
;
;  LINKAGE:	Call near
;
;  NORMAL	CF = O
;  EXIT:
;
;  ERROR	CF = 1
;  EXIT:	CX = 0 - INCORRECT DOS VERSION
;
;  CHANGE	04/15/87 - First release
;  LOG:
;
;******************* END OF SPECIFICATIONS *************************************

;			  $SALUT (4,27,34,41)

					; The following structure is a
					;   SYSMSG SUBLIST control block.
					;   It is initalized for the "already
					;   installed " message.  The parse
					;   routine will set it up to work
					;   for parseing.
SUBLIST 		  LABEL  WORD

			  db	 sub_size ; size of sublist
			  db	 0	; reserved
msg_offset		  dw	 offset SHARE_Name ; insert 'SHARE'

msg_segment		  LABEL  WORD

IF			  NOT	 INSTALLED

			  dw	 CODE

ELSE

			  dw	 SHARE

ENDIF

num_ins 		  db	 1	; only one insert
			  db	 Char_Field_ASCIIZ ; data type flag - ascii z string
max_ins 		  db	 SHARE_Name_Size ; maximum field size
min_ins 		  db	 SHARE_Name_Size ; minimum field size
			  db	 " "	; pad character

sub_size		  equ	 $ - SUBLIST

SHARE_Name		  LABEL  WORD

			  db	 "SHARE"

SHARE_Name_Size 	  equ	 $ - Share_Name

			  db	 0	; make it a Z string
;  $SALUT (4,4,9,41)

   Procedure ShDispMsg,near		;				       ;AN000;
					;---------------------------------------
					; Set up required parameters
					;--------------------------------------
   MOV	BX,STDERR			;display message on STD ERROR	       ;AN000;
   XOR	CX,CX				;no substitution required	       ;AN000;
   XOR	DX,DX				;set flags to 0 		       ;AN000;
   DEC	DH				;and class to utility		       ;AN000;
   cmp	ah,PARSE_ERR_CLASS		;
;  $if	be,and				;				       ;AC009;
   JNBE $$IF72
   mov	dh,ah				;
;  $if	e				; set up implied substitution	       ;AC009;
   JNE $$IF72

       ASSUME DS:nothing,ES:DOSGROUP

       mov  num_ins,cl			; set number of inserts to 0	       ;AN009;
       mov  BYTE PTR max_ins,030h	; set maximum size of insert	       ;AN009;
       mov  BYTE PTR min_ins,1		; set minimum size of insert	       ;AN009;
       push ds				; set up segment		       ;AN009;
       pop  [msg_segment]		;				       ;AN009;
       mov  BYTE PTR ds:[si],0		; turn it into a ASCIIZ string	       ;AN009;
       cmp  si,msg_offset		; is there something there?	       ;AN009;
;      $if  a				; if it is...			       ;AN009;
       JNA $$IF73
	   inc	cx			;				       ;AN009;
;      $endif				;				       ;AN009;
$$IF73:
;  $endif				;
$$IF72:
   cmp	al,Sh_Already_Loaded		; SHARE already loaded message ?       ;AN000;
;  $if	e				; if it is...			       ;AN000;
   JNE $$IF76
       inc  cx				;
       mov  msg_offset,OFFSET SHARE_name ; ensure the pointer is right	       ;AN010;
;  $endif				;
$$IF76:
   push cs				; ensure that SYSMSG has proper        ;AC009;
   pop	ds				;	   addressability	       ;AC009;
   lea	si,SUBLIST			; point to sublist		       ;AC009;
   xor	ah,ah				;				       ;AN000;

					;--------------------------------------
					; Output the Message
					;---------------------------------------
EXTRN SYSDISPMSG:NEAR			;				       ;AN000;

   CALL SYSDISPMSG			;				       ;AN000;

;  $IF	C				; if error occured		       ;AN000;
   JNC $$IF78

       CALL Get_DOS_Error		; a DOS extended error occured	       ;AN000;
       CALL SYSDISPMSG			; try to issue it		       ;AN000;

;  $ENDIF				; endif - error occured 	       ;AN000;
$$IF78:

   MOV	AX,(EXIT SHL 8) + 0FFH		; exit to DOS			       ;AN000;
   INT	21h				;				       ;AN000;

   ret					; may return if pre DOS 2.0	       ;AN000;

   EndProc ShDispMsg			;				       ;AN000;

   BREAK < Get_DOS_Error >

;******************* START OF SPECIFICATIONS ***********************************
;Routine name: Get_DOS_Error
;*******************************************************************************
;
;Description:  Call DOS to obtain DOS extended error #
;
;Called Procedures: None
;
;Input: 	    None
;
;Output:	    AX = error number
;		    DH = DOS extended error class
;
;Change History:    Created	   5/01/87	   FG
;
;******************* END OF SPECIFICATIONS *************************************
;******************+ START OF PSEUDOCODE +**************************************
;
;	START  Get_DOS_Error
;
;	call DOS for extended error (INT21 GetExtendedError + 00 <5900>)
;	set up registers for return
;	ret
;
;	END  Get_DOS_Error
;
;******************-  END  OF PSEUDOCODE -**************************************

   public Get_DOS_Error

   Get_DOS_Error PROC NEAR

   mov	ax,(GetExtendedError shl 8)	; DOS ext. error		       ;AN000;
   xor	bx,bx
   push es				;				       ;AN000;
   INT	21h				;    GetExtendedError + not_used <5900>;AN000;
   pop	es
   mov	bx,STDERR			; fix up bx			       ;AN000;
   xor	cx,cx				; fix up cx			       ;AN000;
   mov	dh,EXT_ERR_CLASS		; set class to dos error

   ret					;				       ;AN000;

   ENDPROC Get_DOS_Error

   Break <ShComndParse	-  Share Command line Parser>

;******************* START OF SPECIFICATIONS ***********************************
;
;  NAME:	ShComndParse  -  Share Command line Parser
;
;  FUNCTION:	Call the DOS PARSE Service Routines to process the command
;		line. Search for valid switches (/F:n and /L:m) and
;		update the values for file size and number of locks accordingly
;
;  INPUT:	Parameter string from command line in the PSP
;
;  OUTPUT:	INITspace and INITlocks are updated.
;
;  REGISTERS USED: ES DI AX BX CX DX
;  (NOT RESTORED)
;
;  LINKAGE:	Call
;
;  NORMAL	- If /F:n specified, then INITspace is updated.
;  EXIT:	- If /L:m specified, then INITlocks is updated.
;
;  ERROR	If user enters:
;  EXIT:	- any parameter or switch other than /F:n or /L:m
;		- an invalid value for "n" or "m"
;		then this routine will display the "Invalid Parameter"
;		error message and terminate.
;
;  EXTERNAL	- System parse service routines
;  REFERENCES:	- INT21 - GET PSP Function Call 062h
;
;  CHANGE	04/15/87 - First release
;  LOG:
;
;******************* END OF SPECIFICATIONS *************************************
;******************+ START OF PSEUDOCODE +**************************************
;
;	START
;
;	return
;
;	END
;
;******************-  END  OF PSEUDOCODE -*************************************

;			  $SALUT (4,27,34,41)

					;--------------------------------------
					; Parse Equates
					;--------------------------------------

EOL			  equ	 -1	; Indicator for End-Of-Line	       ;AN000;
NOERROR 		  equ	 0	; Return Indicator for No Errors       ;AN000;
FILE_SWITCH		  equ	 1	; this is a file switch 	       ;AN000;
LOCK_SWITCH		  equ	 2	; this is a lock switch 	       ;AN000;
Syntax_Error		  equ	 9	; maximum PARSE error # 	       ;AN000;

;  $SALUT (4,4,9,41)

   Procedure ShComndParse,near		;				       ;AN000;
					;--------------------------------------
					;  Get address of command line
					;--------------------------------------
EXTRN SYSPARSE:NEAR			;				       ;AN000;

   MOV	SI,0081H			; OFFSET OF COMMAND LINE IN PSP        ;AN000;
   MOV	AH,62H				; AH=GET PSP ADDRESS FUNCTION CALL     ;AN000;
   INT	21H				; PSP SEGMENT RETURNED IN BX	       ;AN000;
   MOV	DS,BX				; PUT PSP SEG IN DS		       ;AN000;
   MOV	CX,0				; NUMBER OF PARMS PROCESSED SO FAR     ;AN000;
   PUSH CS				;				       ;AN000;
   POP	ES				;				       ;AN000;

   ASSUME ES:SHARE			;				       ;AN000;

					;--------------------------------------
					;  Loop for each operand at DS:SI
					;--------------------------------------
;  $do					;				       ;AN000;
$$DO80:

       LEA  DI,PARMS			; ADDRESS OF PARSE CONTROLS	       ;AN000;
       MOV  DX,0			; RESERVED			       ;AN000;
       mov  msg_offset,si		; save the start scan point	       ;AC009;
       CALL SYSPARSE			; PARSE IT!			       ;AN000;
       CMP  AX,EOL			; ARE WE AT END OF COMMAND LINE ?      ;AN000;

;  $leave e				;				       ;AN000;
   JE $$EN80

       CMP  AX,NOERROR			; ANY ERRORS?			       ;AN000;

;      $if  ne,or			; if parse says error or	       ;AN000;
       JNE $$LL82

       MOV  AX,Syntax_Error		; Parse syntax error - just in case    ;AN000;
       MOV  BX,DX			; PLACE RESULT ADDRESS IN BX	       ;AN000;
       CMP  BX,OFFSET SWITCH_BUFF	;				       ;AN000;

;      $if  ne				; if no pointer 		       ;AN000;
       JE $$IF82
$$LL82:

	   call PARSE_ERROR		;   call error routine		       ;AN000;

;      $endif				; endif - error 		       ;AN000;
$$IF82:

       MOV  AX,WORD PTR SW_VALUE	; load the value		       ;AN000;
       MOV  BX,SW_SYN			; load pointer to synonym	       ;AN000;

					;--------------------------------------
					;  If user said  /F:n, then
					;--------------------------------------

       CMP  BX,OFFSET F_SW		; IF USER SPECIFIED /F		       ;AN000;

;      $if  e				;				       ;AN000;
       JNE $$IF84

	   CMP	INITspace,AX		; is default < requested ?	       ;AN000;

;	   $if	b			; if default is <		       ;AN000;
	   JNB $$IF85
	       MOV  INITspace,AX	; save the new value		       ;AN000;
;	   $endif			; endif   (else leave it alone)        ;AN000;
$$IF85:

;      $else				; else - CHECK FOR LOCKS	       ;AN000;
       JMP SHORT $$EN84
$$IF84:

					;---------------------------------------
					;  If user said /L:m, then update INITlocks
					;---------------------------------------
	   CMP	BX,OFFSET L_SW		; IF USER SPECIFIED /L		       ;AN000;

;	   $if	e			; if it is				;AN000;
	   JNE $$IF88

	       CMP  INITlocks,AX	; is default < requested ?	       ;AN000;

;	       $if  b			; if default is <		       ;AN000;
	       JNB $$IF89
		   MOV	INITlocks,AX	;   save the value		       ;AN000;
;	       $endif			; endif      (else leave it alone)     ;AN000;
$$IF89:

;	   $else			; else - CHECK FOR TOGGLE	       ;AN010;
	   JMP SHORT $$EN88
$$IF88:

					;---------------------------------------
					;  If user said /NC, then update check_flag
					;---------------------------------------
	       CMP  BX,OFFSET N_SW	; IF USER SPECIFIED /NC 	       ;AN010;
;	       $if  ne			; if error			       ;AC010;
	       JE $$IF92
		   MOV	AX,Syntax_Error ; Parse syntax error		       ;AN000;
		   call PARSE_ERROR	;   call error routine		       ;AN000;
;	       $endif			; endif - error 		       ;AC010;
$$IF92:

	       mov  skip_check,1	; set the skip check flag	       ;AN010;

;	   $endif			; endif - CHECK FOR TOGGLE	       ;AN010;
$$EN88:

;      $endif				; endif - CHECK FOR LOCKS	       ;AN000;
$$EN84:

;  $enddo				; CHECK FOR NEXT PARM		       ;AN000;
   JMP SHORT $$DO80
$$EN80:

   ret					; NORMAL RETURN TO CALLER	       ;AN000;

					;---------------------------------------
					;  If any other parameter specified,
					;  display message and quit
					;---------------------------------------
PARSE_ERROR:				;				       ;AN000;

   cmp	al,Syntax_Error 		; error 1 to 9 ?		       ;AN000;

;  $if	a				; if parse error		       ;AN000;
   JNA $$IF97

       mov  al,Syntax_Error		; Parse syntax error

;  $endif				; endif errors			       ;AN000;
$$IF97:

   lea	bx,Parse_Ret_Code
   xlat cs:[bx]
   mov	ah,PARSE_ERR_CLASS		; set class to parse error	       ;AN000;

   CALL ShDispMsg			; display the parse error	       ;AN000;

   ret					; this should never be used

Parse_Ret_Code label byte

   db	0				; Ret Code 0 -
   db	9				; Ret Code 1 - Too many parameters
   db	9				; Ret Code 2 - Required parameter missing
   db	3				; Ret Code 3 - Invalid switch
   db	9				; Ret Code 4 - Invalid keyword
   db	9				; Ret Code 5 - (reserved)
   db	6				; Ret Code 6 - Parm val out of range
   db	9				; Ret Code 7 - Parameter val not allowed
   db	9				; Ret Code 8 - Parameter val not allowed
   db	9				; Ret Code 9 - Parm format not correct

   EndProc ShComndParse 		;				       ;AN000;

   include msgdcl.inc

   SHARE ENDS

   STACK SEGMENT STACK
   DB	278  + 128 DUP (?)		; 278 == IBM's ROM requirements
   STACK ENDS

ENDIF

   END	shareinit

