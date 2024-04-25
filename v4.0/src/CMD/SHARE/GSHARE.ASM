	Title	Share_1 -  IBM CONFIDENTIAL
;				   $SALUT (0,36,41,44)
				   include SHAREHDR.INC
;
;     Label: "The DOS SHARE Utility"
;	     "Version 4.00 (C) Copyright 1988 Microsoft"
;	     "Licenced Material - Program Property of Microsoft"
;
;******************* END OF SPECIFICATIONS *************************************

extrn				   fnm:near, rsc:near, rmn:near, cps:near, ofl:near, sle:near, interr:near

				   NAME Sharer

				   .xlist
				   .xcref
				   INCLUDE DOSSYM.INC
				   include dpl.asm
				   .cref
				   .list

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
				   IF	x NE 0
				   %out ERRNZ failed
				   ENDIF
				   ENDM
; if we are installed, then define the base code segment of the sharer first

				   IF	Installed
Share				   SEGMENT PARA PUBLIC 'SHARE'
Share				   ENDS
; include the rest of the segment definitions for normal msdos
; We CANNOT include dosseg because start is not declared para in that file

;	$SALUT	(4,9,17,36)

START	SEGMENT PARA PUBLIC 'START'
START	ENDS

CONSTANTS SEGMENT WORD PUBLIC 'CONST'
CONSTANTS ENDS

DATA	SEGMENT WORD PUBLIC 'DATA'
DATA	ENDS

TABLE	SEGMENT BYTE PUBLIC 'TABLE'
TABLE	ENDS

CODE	SEGMENT BYTE PUBLIC 'CODE'
CODE	ENDS

LAST	SEGMENT PARA PUBLIC 'LAST'
LAST	ENDS

DOSGROUP GROUP	START,CONSTANTS,DATA,TABLE,CODE,LAST
	ELSE
	include dosseg.asm
	ENDIF

DATA	SEGMENT WORD PUBLIC 'DATA'
	Extrn	ThisSFT:DWORD	   ; pointer to SFT entry
	Extrn	User_ID:WORD
	Extrn	Proc_ID:WORD
	Extrn	WFP_START:WORD
	Extrn	BytPos:DWORD
	extrn	OpenBuf:BYTE
	extrn	user_in_ax:WORD
	IF	debug
	    Extrn   BugLev:WORD
	    Extrn   BugTyp:WORD
	    include bugtyp.asm
	ENDIF
DATA	ENDS

;   if we are not installed, then the code here is just part of the normal
;   MSDOS code segment otherwise, define our own code segment

	.sall
	IF	NOT INSTALLED
CODE	    SEGMENT BYTE PUBLIC 'CODE'
	    ASSUME  SS:DOSGROUP,CS:DOSGROUP
	ELSE
Share	    SEGMENT PARA PUBLIC 'SHARE'
	    ASSUME  SS:DOSGROUP,CS:SHARE
	ENDIF

	extrn	MFT:BYTE
	extrn	skip_check:BYTE

	include mft.inc

	PUBLIC	FreLock,Serial

	IF	installed
Frelock     DW	    ?		   ; FWA of lock free list
	ELSE
Frelock     DW	    OFFSET DOSGROUP:lck8 ; FWA of lock free list
	ENDIF
Serial	DW	0		   ; serial number
DS_Org	dw	0		   ;an000;DS on entry to routine

ZERO	EQU	0
ONE	EQU	1

FRAME	struc

SavedBP dw	?
RetOFF	dw	?
Parm_1	dw	?
Parm_2	dw	?

FRAME	ends

;  $SALUT (4,4,9,41)

   BREAK <Sharer - MultiProcess File Sharer>

;******************* START OF SPECIFICATIONS ***********************************
;
;	MSDOS MFT Functions
;
;	The Master File Table (MFT) associates the cannonicalized pathnames,
;	lock records and SFTs for all files open on this machine.
;
;	These functions are supplied to maintain the MFT and extract
;	information from it.  All MFT access should be via these routines so
;	that the MFT structure can remain flexible.
;
;******************* END OF SPECIFICATIONS *************************************

   BREAK <Mft_enter - Make an MFT entry and check access>

;******************* START OF SPECIFICATIONS ***********************************
;
;	mft_enter - make an entry in the MFT
;
;	mft_enter is called to make an entry in the MFT.
;	mft_enter checks for a file sharing conflict:
;		No conflict:
;		    A new MFT entry is created, or the existing one updated,
;		    as appropriate.
;		Conflicts:
;		    The existing MFT is left alone.  Note that if we had to
;		    create a new MFT there cannot be, by definition, sharing
;		    conflicts.
;	If no conflict has been discovered, the SFT list for the file is
;	checked for one that matches the following conditions:
;
;	    If mode == 70 then
;		don't link in SFT
;		increment refcount
;	    If mode&sfIsFCB and userids match and process ids match then
;		don't link in SFT
;
;	ENTRY	ThisSFT points to an SFT structure.  The sf_mode field
;		    contains the desired sharing mode.
;		WFP_Start is an offset from DOSGroup of the full pathname for
;		    the file
;		User_ID = 16-bit user id of issuer
;		Proc_ID = 16-bit process id of issuer
;		(DS) = (SS) = DOSGroup
;	EXIT	'C' clear if no error'
;		'C' set if error
;		  (ax) = error code
;	USES	ALL but DS
;
;******************* END OF SPECIFICATIONS *************************************

   Procedure mft_enter,NEAR

;  int 3
   nop
   nop

   EnterCrit critShare

   DOSAssume SS <DS>,"MFT_Enter entry"
   ASSUME ES:NOTHING,SS:DOSGROUP
   push ds

;	find or make a name record

   mov	si,WFP_Start			; (DS:SI) = FBA of file name
   mov	al,1				; allow creation of MFT entry
   push es

   ASSUME DS:NOTHING

   call FNM				; find or create name in MFT
   pop	es
   mov	ax,error_sharing_buffer_exceeded
   jc	ent9				; not enough space
;
;	(bx) = fwa name record
;
   lds	si,ThisSFT
   call ASC				; try to add to chain

;	As noted above, we don't have to worry about an "empty" name record
;	being left if ASC refuses to add the SFT - ASC cannot refuse if we had
;	just created the MFT...

;	return.
;
;	'C' and (Ax) setup appropriately

ent9: pop ds

   LeaveCrit critShare

   ret

   EndProc mft_enter

   BREAK <MftClose - Close out an MFT for given SFT>

;******************* START OF SPECIFICATIONS ***********************************
;
;	MFTclose
;
;	MFTclose(SFT)
;
;	MFTclose removes the SFT entry from the MFT structure.	If this was
;	the last SFT for the particular file the file's entry is also removed
;	from the MFT structure.  If the sharer is installed after some
;	processing has been done, the MFT field of the SFTs will be 0; we must
;	ignore these guys.
;
;	If the sft indicates FCB, we do nothing special.  The SFT behaves
;	    EXACTLY like a normal handle.
;
;	If the sft indicates mode 70 then we do nothing special.  These are
;	normal HANDLES.
;
;	Note that we always care about the SFT refcount.  A refcount of 1
;	means that the SFT is going idle and that we need to remove the sft
;	from the chain.
;
;	ENTRY	(ES:DI) points to an SFT structure
;		(DS) = (SS) = DOSGroup
;	EXIT	NONE
;	USES	ALL but DS, ES:DI
;
;******************* END OF SPECIFICATIONS *************************************

   Procedure MFTclose,NEAR

;  int 3
   nop
   nop

   EnterCrit critShare

   DOSAssume SS,<DS>,"MFTClose entry"
   ASSUME ES:NOTHING
   mov	ax,es:[di].sf_MFT

   fmt	TypShare,LevShEntry,<"MFTClose by $x:$x of $x:$x ($x)\n">,<User_ID,Proc_id,ES,DI,AX>

   or	ax,ax
   jz	mcl10				; No entry for it, ignore (carry clear)
   push ds
   push es
   push di
;;;call CSL				; clear SFT locks		       ;AC008;

   ASSUME DS:NOTHING

   mov	ax,es:[di].sf_ref_count 	; (ax) = ref count
;
; We need to release information in one of two spots.  First, when the SFT has
; a ref count of 0.  Here, there are no more referents and, thus, no sharing
; record need be kept.	Second, the ref count may be -1 indicating that the
; sft is being kept but that the sharing information is no longer needed.
; This occurs in creates of existing files, where we verify the allowed
; access, truncate the file and regain the access.  If the truncation
; generates an error, we do NOT want to have the access locked down.
;


   OR	AX,AX
   jz	mcl85				; ref count is 0 - don't dechain
   inc	ax				; -1 + 1 = 0.  Busy sft.
   jnz	mcl9
mcl85:
   call CSL				; clear SFT locks		       ;AC008;
   call RSC				; remove sft from chain
   jnz	mcl9				; not the last sft for this name
   call RMN				; remove name record
mcl9:
   pop	di				; restore regs for exit
   pop	es
   pop	ds
mcl10:
   LeaveCrit critShare

   ret

   EndProc MFTclose

   BREAK <MftClU - Close out all MFTs for given UID>

;******************* START OF SPECIFICATIONS ***********************************
;
;	MFTcloseU
;
;	MFTcloseM(UID)
;
;	MFTcloseM removes all entrys for user UID from the MFT structure.  We
;	    walk the MFT structure closing all relevant SFT's for the user.
;	    We do it the dumb way, iterating closes until the SF ref count is
;	    0.
;
;	ENTRY	User_ID = 16-bit user id of issuer
;		(SS) + DOSGroup
;	EXIT	'C' clear
;	USES	ALL
;
;******************* END OF SPECIFICATIONS *************************************

   Procedure MFTclU,NEAR

;  int 3
   nop
   nop

   ASSUME DS:NOTHING,ES:NOTHING,SS:DOSGROUP

   EnterCrit critShare
   mov	ax,User_ID

   fmt	TypShare,LevShEntry,<"\nCloseUser $x\n">,<AX>

   sub	bx,bx				; insensitive to PID
   sub	dx,dx
   invoke BCS				; bulk close the SFTs
   LeaveCrit critShare
   return
   EndProc MFTclU

   BREAK <MftCloseP - Close out all MFTs for given UID/PID>

;******************* START OF SPECIFICATIONS ***********************************
;
;	MFTcloseP
;
;	MFTcloseP(PID, UID)
;
;	MFTcloseP removes all entrys for process PID on machine MID from the
;	    MFT structure.  We walk the MFT structure closing all relevant
;	    SFT's.  Do it the dumb way by iterating closes until the SFTs
;	    disappear.
;
;	ENTRY	(SS) = DOSGROUP
;		User_ID = 16-bit user id of issuer
;		Proc_ID = 16-bit process id of issuer
;	EXIT	'C' clear
;	USES	ALL
;
;******************* END OF SPECIFICATIONS *************************************

   Procedure MFTcloseP,NEAR

;  int 3
   nop
   nop

   ASSUME DS:NOTHING,ES:NOTHING,SS:DOSGROUP

   EnterCrit critShare
   mov	ax,User_ID
   mov	bx,-1
   mov	dx,Proc_ID

   fmt	TypShare,LevShEntry,<"\nClose UID/PID $x:$x\n">,<AX,DX>

   call BCS				; Bulk close the SFTs
   LeaveCrit critShare

   ret

   EndProc MFTcloseP

   BREAK <MftCloN - Close file by name>

;******************* START OF SPECIFICATIONS ***********************************
;
;	MFTcloseN
;
;	MFTcloseN(name)
;
;	MFTcloseN removes all entrys for the given file from the MFT
;	structure.
;
;	NOTE: this function is used infrequently and need not be fast.
;		(although for typical use it's not all that slow...)
;
;	ENTRY	DS:SI point to dpl.
;		(SS) = DOSGroup
;	EXIT	'C' clear if no error
;		'C' set if error
;		  AX = error_path_not_found if not currently open
;	USES	ALL
;
;******************* END OF SPECIFICATIONS *************************************

   Procedure MFTcloN,NEAR

;  int 3
   nop
   nop

   ASSUME SS:DOSGROUP,ES:NOTHING,DS:NOTHING

   EnterCrit critShare
   MOV	DX,[SI.DPL_DX]
   MOV	DS,[SI.DPL_DS]
   mov	si,dx				; (DS:SI) = fwa name
   sub	al,al				; don't create if not found
   push ds
   push si
   call FNM				; find name in MFT
   mov	ax,error_path_not_found 	; assume error
   jc	mclo9				; not found exit

;	Name was found.  Lets yank the SFT entrys one at a time.

mclo1: les di,[bx].mft_sptr		; (ES:DI) = SFT address
   mov	WORD PTR ThisSFT,di
   mov	WORD PTR ThisSFT+2,es		; point to SFT
   cmp	es:[di].sf_ref_count,1
   jnz	mclo15
   call CPS
mclo15:
   Context DS

   IF	installed
       MOV  AX,(multDOS SHL 8) + 1
       INT  2FH
   ELSE
       call DOS_Close
   ENDIF
mclo2:

   ASSUME DS:NOTHING

   pop	si
   pop	ds
   push ds
   push si
   sub	al,al				; don't create an entry
   call FNM				; find the name gain
   jnc	mclo1				; got still more
   clc

;	exit.  'C' and (ax) setup
;
;	(TOS+2:TOS) = address of ASCIZ string

mclo9: pop si				; clean stack
   pop	ds
   LeaveCrit critShare

   ret

   EndProc MFTcloN

   BREAK <Set_Mult_Block - Try to set multiple locks>

;******************* START OF SPECIFICATIONS ***********************************
;
;  NAME:	   Set_Mult_Block  -  Set Multiple Block Locks
;
;  FUNCTION:	   Set_Mult_Block sets a lock on 1 or more specified ranges
;		   of a file.  An error is returned if any lock range conflicts
;		   with another. Ranges of Locks are cleared via Clr_Mult_Block.
;
;		   In DOS 3.3 only one lock range could be set at a time using
;		   Set_Block.  For DOS 4.00 this routine will replace Set_Block
;		   in the jump table and will make repeated calls to Set_Block
;		   in order to process 1 or more lock ranges.
;
;		   NOTE: - This is an all new interface to IBMDOS
;
;  INPUT:	   (AL) = 0  - lock all
;			= 80 - lock write
;		   (CX) = the number of lock ranges
;		   (DS:DX) = pointer to the range list
;		   (ES:DI) = SFT address
;		   User_ID = 16-bit user id of issuer
;		   Proc_ID = 16-bit process id of issuer
;		   (SS) = DOSGroup
;
;  OUTPUT:	   Lock records filled in for all blocks specified
;
;  REGISTERS USED: ALL but DS
;  (NOT RESTORED)
;
;  LINKAGE:	   IBMDOS Jump Table
;
;  EXTERNAL	   Invoke: Load_Regs, Set_Block, Clr_Block
;  REFERENCES:
;
;  NORMAL	   'C' clear if no error
;  EXIT:
;
;  ERROR	   'C' set if error
;  EXIT:	     (ax) = error code
;			       ('error_lock_violation' if conflicting locks)
;
;  CHANGE	04/15/87 - First release
;  LOG:
;
;******************* END OF SPECIFICATIONS *************************************
;******************+ START OF PSEUDOCODE +**************************************
;
;	START Set_Mult_Block
;
;	count = start_count
;	search till count = 0
;		invoke Load_Regs
;		invoke Set_Block
;	exit if error
;		clear_count = start_count - current_count
;		loop till clear_count = 0
;			invoke Load_Regs
;			invoke Clr_Block
;		leave if error
;		end loop
;		set error status
;	orelse
;	endloop
;		set successful status
;	endsrch
;	if error status
;		load return code
;	endif
;	return
;
;	END Set_Mult_Block
;
;******************+  END  OF PSEUDOCODE +**************************************

   Procedure Set_Mult_Block,NEAR

;	PUSH	DS			;ICE
;	push	bx			;ICE
;	push	ax			;ICE

;	mov	bx,0140H		;ICE
;	xor	ax,ax			;ICE
;	mov	ds,ax			;ICE
;	mov	ax,word ptr ds:[bx]	;ICE
;	mov	word ptr ds:[bx],ax	;ICE

;	pop	ax			;ICE
;	pop	bx			;ICE
;	POP	DS			;ICE



   EnterCrit critShare			;				       ;AN000;

   ASSUME ES:NOTHING,DS:NOTHING 	;				       ;AN000;
;	      set up for loop

;      WE HAVE:   (from IBMDOS) 	|	  WE NEED:   (for Set_Block)

; (AL)	  = 0 - lock all		|    (BX)    = 0 lock all operations
;	  = 80- lock write		|	     = 1 lock write operations
; (CX)	  = the number of lock ranges	|    (CX:DX) = offset of area
; (DS:DX) = pointer to the range list	|    (SI:AX) = length of area
; (ES:DI) = SFT address 		|    (ES:DI) = SFT address

;  int 3
   nop
   nop

   mov	DS_Org,ds			;an000;save entry DS

   Context DS				;				       ;AN000;
   CMP	CX,01h				;DO WE HAVE A COUNT?		       ;AN000;

;; $if	ae				; if the count was valid	       ;AN000;
;  $if	e				; if the count was valid	       ;AC006;
   JNE $$IF1

;;     PUSH CX				; count = start_count		       ;AN000;
;;     PUSH DX				; save pointer to range list	       ;AN000;
       MOV  BP,DX			; save current index into list	       ;AN000;
;;     AND  AX,0080H			; clear high byte and be sure low is   ;AN000;
					; set if applicable
;;     ROL  AL,1			; move high bit to bit 0
;;     MOV  BX,AX			; SET UP TYPE OF LOCK		       ;AN000;

;;     $do				; loop till count = 0		       ;AN000;
;;	   cmp	cx,00			;an000;see if at end
;;     $leave e 			;an000;exit if at end
;;	   push cx			;an000;save cx - our counter
;;	   push di			;an000;save di - our SFT pointer
       call load_regs			;an000;load the registers for call
					;      to set_block
       call set_block			;an000;set the lock block
;;	   pop	di			;an000;restore our SFT pointer
;;	   pop	cx			;an000;restore cx - our counter
;;     $leave c 			;an000;on error exit loop
;;	   dec	cx			;an000;decrease counter
;;     $enddo				;an000;end loop

;;     $if  c				;an000;if an error occurred
;;	   pop	dx			;an000;restore range list pointer
;;	   pop	ax			;an000;obtain original count
;;	   sub	ax,cx			;an000;determine how many locks set
;;	   mov	cx,ax			;an000;set the loop counter with count
;;	   mov	bp,dx			;an000;set bp to point to range list
;;	   $do				;an000;while cx not = 0
;;	       cmp  cx,00		;an000;at end?
;;	   $leave e			;an000;yes, exit
;;	       push cx			;an000;save cx - our counter
;;	       push di			;an000;save di - our SFT pointer
;;	       call load_regs		;an000;load the registers for call
					;      to clr_block
;;	       call clr_block		;an000;clear the locks
;;	       pop  di			;an000;restore our SFT pointer
;;	       pop  cx			;an000;restore cx - our counter
;;	   $leave c			;an000;on error exit
;;	       dec  cx			;an000;decrease counter
;;	   $enddo			;an000;
;;	   stc				;an000;signal an error occurred
;;     $else				;an000;no error occurred in locking
;;	   pop	ax			;an000;clear off the stack
;;	   pop	ax			;an000;   to balance it
;;	   clc				;an000;signal no error occurred
;;     $endif				;an000;
;  $else				;an000;cx was 0 - this is an error
   JMP SHORT $$EN1
$$IF1:
       stc				;an000;signal an error occurred
;  $endif				;				       ;an000;
$$EN1:

;  $if	c				; if there was an error 	       ;AN000;
   JNC $$IF4
       MOV  AX,error_lock_violation	; load the return code		       ;AN000;
;  $endif				; endif there was an error	       ;AN000;
$$IF4:

   LeaveCrit critShare			;				       ;AN000;

   ret					; return - all set		       ;AN000;

   EndProc Set_Mult_Block

   BREAK <Load_Regs - Load Registers for ?_Block call>

;******************* START OF SPECIFICATIONS ***********************************
;
;  NAME:	   Load_Regs - Load Registers for ?_Block calls
;
;  FUNCTION:	   This subroutine loads the High and Low Offsets and the
;		   High and Low lengths for Lock ranges from the Range List.
;
;  INPUT:	   (DS_Org:PB) - Range list entry to be loaded
;
;  OUTPUT:	   (DX) - Low Offset
;		   (CX) - High Offset
;		   (AX) - Low Length
;		   (SI) - High Length
;
;  REGISTERS USED: AX CX DX BP SI
;  (NOT RESTORED)
;
;  LINKAGE:	   Called by: Set_Mult_Block, Clr_Mult_Block
;
;  EXTERNAL	   none
;  REFERENCES:
;
;  NORMAL	   none
;  EXIT:
;
;  ERROR	   none
;  EXIT:
;
;  CHANGE	   04/15/87 - first release
;  LOG:
;
;******************* END OF SPECIFICATIONS *************************************
;******************+ START OF PSEUDOCODE +**************************************
;
;	  START Load_Regs
;
;	  recover index into range list
;	  advance pointer to next entry
;	  load DX - Low Offset
;	  load CX - High Offset
;	  load AX - Low Length
;	  load SI - High Length
;	  return
;
;	  END Load_Regs
;
;******************+  END  OF PSEUDOCODE +**************************************

   Procedure Load_Regs,NEAR

   push ds				; save our DS			       ;an000;
   mov	ds,DS_Org			; get range list segment	       ;an000;
   mov	si,bp				; recover pointer		       ;AN000;
   ADD	BP,08h				; move to next entry in list	       ;AN000;
   MOV	DX,[SI] 			; low position			       ;AN000;
   MOV	CX,[SI+2]			; high position 		       ;AN000;
   MOV	AX,[SI+4]			; low length			       ;AN000;
   MOV	SI,[SI+6]			; high length			       ;AN000;
   pop	ds				; restore DS			       ;an000;

   ret					;				       ;AN000;

   EndProc Load_Regs

   BREAK <Clr_Mult_Block - Try to clear multiple locks>

;******************* START OF SPECIFICATIONS ***********************************
;
;  NAME:	   Clr_Mult_Block  -  Clear Multiple Block Locks
;
;  FUNCTION:	   Clr_Mult_Block removes the locks on 1 or more specified
;		   ranges of a file.  An error is returned if any lock range
;		   does not exactly match. Ranges of Locks are set via
;		   Set_Mult_Block.
;
;		   In DOS 3.3 only one lock range could be cleared at a time
;		   using Clr_Block.  For DOS 4.00 this routine will replace
;		   Clr_Block in the jump table and will make repeated calls
;		   to Set_Block in order to process 1 or more lock ranges.
;
;		   NOTE: - This is an all new interface to IBMDOS
;			 - an unlock all 'lock all' request will unlock both
;			   'lock all' and 'lock write'.
;			 - an unlock all 'lock write' request will not unlock
;			   'lock all's. It will only unlock 'lock write's.
;			  (if you can understand the above statement,
;			  understanding the code will be easy!)
;
;  INPUT:	   (AL) = 0 - lock all
;			= 80- lock write
;		   (CX) = the number of lock ranges - NB: all if -1 ***
;		   (DS:DX) = pointer to the range list
;		   (ES:DI) = SFT address
;		   User_ID = 16-bit user id of issuer
;		   Proc_ID = 16-bit process id of issuer
;		   (SS) = DOSGroup
;
;  OUTPUT:	   Lock records filled in for all blocks specified
;
;  REGISTERS USED: ALL but DS
;  (NOT RESTORED)
;
;  LINKAGE:	   IBMDOS Jump Table
;
;  EXTERNAL	   Invoke: Load_Regs, Set_Block, Clr_Block, Clr_List
;  REFERENCES:
;
;  NORMAL	   'C' clear if no error
;  EXIT:
;
;  ERROR	   'C' set if error
;  EXIT:	     (ax) = error code
;			       ('error_lock_violation' if conflicting locks)
;
;  CHANGE	04/15/87 - First release
;  LOG:
;
;******************* END OF SPECIFICATIONS *************************************
;******************+ START OF PSEUDOCODE +**************************************
;
;	START Clr_Mult_Block
;
;	if count is valid and
;	if file (SFT) is 'shared' then
;		if count = all
;			find first RLR
;			loop till all RLR cleared
;				if PROC_ID matches and
;				if UID matches and
;				if SFT matches then
;					if ulocking lock_all or
;					if this RLR is lock_write
;						clear the lock
;					endif
;				endif
;				find next RLR
;			end loop
;		else
;			invoke Clr_List
;		endif
;		set successful status
;	else
;		set error status
;	endif
;	if error
;		load return code
;	endif
;
;	ret
;
;	END Clr_Mult_Block
;
;******************+  END  OF PSEUDOCODE +**************************************

   Procedure clr_mult_block,NEAR


lock_all equ 0h

;	PUSH	DS			;ICE
;	push	bx			;ICE
;	push	ax			;ICE

;	mov	bx,0140H		;ICE
;	xor	ax,ax			;ICE
;	mov	ds,ax			;ICE
;	mov	ax,word ptr ds:[bx]	;ICE
;	mov	word ptr ds:[bx],ax	;ICE

;	pop	ax			;ICE
;	pop	bx			;ICE
;	POP	DS			;ICE

   EnterCrit critShare			;				       ;AN000;

   ASSUME ES:NOTHING,DS:NOTHING 	;				       ;AN000;

;  int 3
   nop
   nop

   mov	DS_Org,DS			;an000;save entry DS

   Context DS				;				       ;AN000;

   CMP	CX,01h				; do we have a count?		       ;AN000;
;; $IF	AE,AND				; IF A VALID COUNT
;  $IF	E,AND				; IF A VALID COUNT		       ;AC006;
   JNE $$IF6
   cmp	es:[di].sf_mft,0		; is this SFT shared?		       ;AN000;
;  $IF	NE				; AND IF FILE IS 'SHARED' THEN
   JE $$IF6

;      WE HAVE:   (from IBMDOS) 	|	  WE NEED:

; (AL)	  = 0 - lock all		|    (AX)    = 0 lock all operations
;	  = 80- lock write		|	     = 1 lock write operations
; (CX)	  = - 1  (unlock all locks)	|    (DS)    = CS
;					|    (DS:DI) = previous RLR
;					|    (DS:SI) = current RLR
; (ES:DI) = current SFT 		|

;;     and  ax,0080h			;be sure it is set right (mask 80 bit) ;AC002;
					;    existing interface
;;     rol  al,1			;put high bit in bit 0		       ;AC002;

;;     CMP  CX,-1h			;				       ;AN000;
;;     $IF  E				; IF unlock all locks then	       ;AN000;

;;	   push cs			;				       ;AN000;
;;	   pop	ds			;				       ;AN000;
;;	   mov	cx,di			; ES:CX is the SFT		       ;AN004;

;	   ASSUME ds:nothing

;;	   mov	si,es:[di].sf_mft	; DS:SI points to MFT		       ;AN000;

;;	   lea	di,[si].mft_lptr	; DS:DI = addr of ptr to lock record   ;AN000;
;;	   mov	si,[di] 		; DS:SI = address of 1st lock record   ;AN000;

;;	   $DO				; loop through the RLR's               ;AN000;

;	DS:DI = points to previous RLR or MFT if no RLR.
;	DS:SI = points to current RLR
;	ES:CX = SFT address
;	AX    = lock type

;;	       and  si,si		; are we at the end of the chain?      ;AN000;
;;	   $LEAVE Z			; we'er done with CF = 0               ;AN000;

;;	       mov  bp,[si].rlr_pid	; get PROC_ID			       ;AN000;
;;	       cmp  bp,PROC_ID		; is it ours?			       ;AN000;
;;	       $IF  E,AND		;				       ;AN000;
;;	       mov  bp,es		;				       ;AN000;
;;	       cmp  bp,WORD PTR [si].rlr_sptr+2 ;			       ;AC004;
;;	       $IF  E,AND		;				       ;AN000;
;;	       cmp  cx,WORD PTR [si].rlr_sptr ; 			       ;AC004;
;;	       mov  si,[di]		; restore pointer to current (using    ;AN000;
					;			     previous)
;;	       $IF  E			; if it is ours 		       ;AN000;

;	this is it. its OURS !

;;		   cmp	ax,lock_all	;				       ;AN000;

;;		   $IF	E,OR		; if unlocking all or		       ;AN000;

;;		   mov	bp,[si].rlr_type ; get lock type		       ;AN000;
;;		   cmp	bp,rlr_lall	; is it lock all?		       ;AN000;

;;		   $IF	NE		; if not a LOCK ALL lock	       ;AN000;

;	remove the RLR from the chain

;;		       mov  bx,[si].rlr_next ; get the pointer to the next RLR ;AN000;
;;		       mov  [di],bx	; install it in the last	       ;AN000;

;	put defunct lock record on the free chain

;;		       mov  bx,Frelock	;				       ;AN000;
;;		       mov  [si].rlr_next,bx ;				       ;AN000;
;;		       mov  Frelock,si	;				       ;AN000;
;;		       mov  si,di	; back up to last		       ;AN000;

;;		   $ENDIF		; should we unlock it		       ;AN000;

;;	       $ENDIF			; it was ours!			       ;AN000;

;	advance to next RLR

;;	       mov  di,si		; load address of next RLR	       ;AN000;
;;	       mov  si,[di]		; update pointer to next RLR	       ;AN000;

;;	   $ENDDO			; loop back to the start	       ;AN000;

;;     $ELSE				; else, its a LIST !		       ;AN000;

;	      set up for loop

;      WE HAVE:   (from IBMDOS) 	|	  WE NEED:   (for Clr_Block)

; (AX)	  = 0 - lock all		|    (BX)    = 0 lock all operations
;	  = 1 - lock write		|	     = 1 lock write operations
; (CX)	  = the number of lock ranges	|    (CX:DX) = offset of area
; (DS:DX) = pointer to the range list	|    (SI:AX) = length of area
; (ES:DI) = SFT address 		|    (ES:DI) = SFT address

;;	   PUSH CX			; count = start_count		       ;AN000;
;;	   PUSH DX			; save pointer to range list	       ;AN000;
       MOV  BP,DX			; save current index into list	       ;AN000;
;;	   MOV	BX,AX			; SET UP TYPE OF LOCK		       ;AN000;

       call Clr_List			; call Clr_List to process the list    ;AN000;

;;     $ENDIF				;				       ;AN000;

;  $ELSE				; NOT VALID
   JMP SHORT $$EN6
$$IF6:

       STC				;				       ;AN000;

;  $ENDIF				; VALID/INVALID 		       ;AN000;
$$EN6:

;  $IF	C				; if carry is set		       ;AN000;
   JNC $$IF9
       MOV  AX,error_lock_violation	; load error condition		       ;AN000;
;  $ENDIF				; carry not set 		       ;AN000;
$$IF9:

   LeaveCrit critShare			;				       ;AN000;

   ret					; return - all set		       ;AN000;

   EndProc clr_mult_block

   BREAK <Clr_List - Clear a list of user specified locks>

;******************* START OF SPECIFICATIONS ***********************************
;
;  NAME:	   Clr_List  -	Clear a list of user specified locks
;
;  FUNCTION:	   Clr_List makes multiple calls to Clr_Block to clear
;		   multiple lock ranges of a file.  An error is returned
;		   if any lock range does not exactly match. Ranges of
;		   Locks are then set via Set_Mult_Block.
;
;
;  INPUT:	   (BX)    = 0 lock all operations
;			   = 1 lock write operations
;		   (CX:DX) = offset of area
;		   (SI:AX) = length of area
;		   (ES:DI) = SFT address
;		   (SS:SP+2)= original index \ see FRAME struc
;		   (SS:SP+4)= original count /
;
;  OUTPUT:	   Lock records removed for all blocks specified
;		   Stack cleard on return
;
;  REGISTERS USED: ALL but DS
;  (NOT RESTORED)
;
;  LINKAGE:	   IBMDOS Jump Table
;
;  EXTERNAL	   Invoke: Load_Regs, Set_Block, Clr_Block
;  REFERENCES:
;
;  NORMAL	   'C' clear if no error
;  EXIT:
;
;  ERROR	   'C' set if error
;  EXIT:	     (ax) = error code
;			       ('error_lock_violation' if conflicting locks)
;
;  CHANGE	04/15/87 - First release
;  LOG:
;
;******************* END OF SPECIFICATIONS *************************************
;******************+ START OF PSEUDOCODE +**************************************
;
;	START Clr_List
;
;	search till count = 0
;		set up for call
;		call clr_Block
;	exit if c
;		clear_count = start_count - current_count
;		loop till clear_count = 0
;			set up for call
;			call Set_Block
;		end loop
;		set error status
;	orelse
;	endloop
;		set successful status
;	endsrch
;	return
;
;	END Clr_List
;
;******************+  END  OF PSEUDOCODE +**************************************

   Procedure Clr_List,NEAR

;; $do					;an000;while cx not = 0
;;     cmp  cx,00			;an000;at end?
;; $leave e				;an000;yes
;;     push cx				;an000;save cx - our counter
;;     push di				;an000;save di - our SFT pointer
   call load_regs			;an000;set up for clr_block call
;;     push bp				; save pointer to range entry	       ;AN000;
   call clr_block			;an000;remove the lock
;;     pop  bp				; recover pointer to range entry       ;AN000;
;;     pop  di				;an000;restore our SFT pointer
;;     pop  cx				;an000;restore cx - our counter
;; $leave c				;an000;leave on error
;;     dec  cx				;an000;decrease counter
;; $enddo				;an000;

;; $if	c				;an000;an error occurred
;;     push bp				;an000;save bp
;;     mov  bp,sp			;an000;get sp
;;     mov  dx,[bp].parm_1		;an000;recover original index
;;     mov  ax,[bp].Parm_2		; original count		       ;AN000;
;;     pop  bp
;;     SUB  AX,CX			; how many did we do?		       ;AN000;
;;     MOV  CX,AX			; set up the loop		       ;AN000;
;;     MOV  BP,DX			; save the index		       ;AN000;

;;     $DO				;				       ;AN000;
;;	   cmp	cx,00			;an000;at end?
;;     $leave e 			;an000;yes
;;	   push cx			;an000;save cx - our counter
;;	   push di			;an000;save di - our SFT pointer
;;	   call load_regs		;an000;set up for set_block call
;;	   call set_block		;an000;reset the locks
;;	   pop	di			;an000;restore our SFT pointer
;;	   pop	cx			;an000;restore cx - our counter
;;     $leave c 			;an000;leave on error
;;	   dec	cx			;an000;decrease counter
;;     $enddo				;an000;
;;     stc				;an000;signal an error
;; $else				;an000;
;;     clc				;an000;signal no error
;; $endif				;an000;

;; ret	4				; return (clear Parm_1 & Parm_2)       ;AN000;
   ret					; return (clear Parm_1 & Parm_2)       ;AC006;

   EndProc Clr_List


   BREAK <Set_Block - Try to set a lock>

;******************* START OF SPECIFICATIONS ***********************************
;
;  NAME:	   Set_Block - set byte range lock on a file
;
;  FUNCTION:	   Set_Block sets a lock on a specified range of a file.  An
;		   error is returned if the lock conflicts with another.
;		   Locks are cleared via clr_block.
;
;  INPUT:	   (ES:DI) = SFT address
;		   (CX:DX) = offset of area
;		   (SI:AX) = length of area
;		   (BX)    = 0 lock all operations
;			   = 1 lock write operations
;		   User_ID = 16-bit user id of issuer
;		   Proc_ID = 16-bit process id of issuer
;		   (SS) = DOSGroup
;
;  OUTPUT:	   Lock records removed for all blocks specified
;
;  REGISTERS USED: ALL but DS, BP
;  (NOT RESTORED)
;
;  LINKAGE:	   Invoked by: Set_Mult_Block
;
;  EXTERNAL	   Invoke: CLP (SLE), OFL
;  REFERENCES:
;
;  NORMAL	   'C' clear if no error
;  EXIT:
;
;  ERROR	   'C' set if error
;  EXIT:
;
;  CHANGE	04/15/87 - lock only write support
;  LOG:
;
;******************* END OF SPECIFICATIONS *************************************
;******************+ START OF PSEUDOCODE +**************************************
;
;	START Set_Block
;
;	if a valid SFT and
;	invoke CLP
;	if no lock conflicts and
;	invoke OFL
;	if empty lock record available
;		store SFT pointer
;		store lock range
;		add RLR to the chain
;		store PROC_ID
;		store rlr_type
;		set successful return status
;	else
;		set error return status
;	endif
;	return
;
;	END Set_Block
;
;******************+  END  OF PSEUDOCODE +**************************************

   Procedure Set_Block,NEAR

   ASSUME ES:NOTHING,DS:NOTHING

   Context DS

   push bp				; preserve (bp) 		       ;AN000;
   push ds				; preserve (ds)
;; push bx				; preserve (bx) 		       ;AN000;
   cmp	es:[di].sf_mft,ZERO
;  $if	nz,and				; if file is SHARED and 	       ;AC000;
   JZ $$IF11
   push di
   call clp				; do common setup code

   ASSUME DS:NOTHING

   pop	bp
;  $if	nc,and				; if no (lock conflict) error and      ;AC000;
   JC $$IF11

;	Its ok to set this lock.  Get a free block and fill it in
;	(es:bp) = sft
;	(ds:si) = pointer to name record
;	(ax:bx) = fba lock area
;	(cx:dx) = lba lock area
;	(ds:di) = pointer to pointer to previous lock
;	(TOS)	= saved (bx)
;	(TOS+1) = saved (ds)
;	(TOS+2) = saved (bp)

   call OFL				; (ds:di) = pointer to new, orphan lock record
;  $if	nc				; if space available		       ;AC000;
   JC $$IF11
       mov  WORD PTR [di].rlr_sptr,bp	; store SFT offset
       mov  WORD PTR [di].rlr_sptr+2,es ; store SFT offset
       mov  [di].rlr_fba+2,ax
       mov  [di].rlr_fba,bx		; store lock range
       mov  [di].rlr_lba+2,cx
       mov  [di].rlr_lba,dx

;	add to front of chain
;
;	(ds:si) = fwa MFT name record

       mov  ax,[si].mft_lptr
       mov  [di].rlr_next,ax
       mov  [si].mft_lptr,di
;
; Set process ID of lock
;
       mov  ax,proc_id
       mov  [di].rlr_pid,ax

;
;;     pop  bx				; recover lock type		       ;AN000;
;;     push bx				; restore the stack		       ;AN000;
;;     mov  [di].rlr_type,bx		; set the rlr_type field	       ;AN000;
       clc				; we finished OK

;  $else				;				       ;AC000;
   JMP SHORT $$EN11
$$IF11:

       mov  ax,error_lock_violation
       stc

;  $endif				;				       ;AC000;
$$EN11:

;; pop	bx				;				       ;AN000;
   pop	ds
   pop	bp				;				       ;AC000;

   ret					; return - all set

   EndProc Set_Block

   BREAK <Clr_Block - Try to clear a lock>

;******************* START OF SPECIFICATIONS ***********************************
;
;  NAME:	   Clr_Block - clear byte range lock on a file
;
;  FUNCTION:	   Clr_Block clears a lock on a specified range of a file.
;		   Locks are set via set_block.
;
;  INPUT:	   (ES:DI) = SFT address
;		   (CX:DX) = offset of area
;		   (SI:AX) = length of area
;		   (BX)    = 0 lock all operations
;			   = 1 lock write operations
;		   User_ID = 16-bit user id of issuer
;		   Proc_ID = 16-bit process id of issuer
;		   (SS) = DOSGroup
;
;  OUTPUT:	   Lock record removed for block specified.
;
;  REGISTERS USED: ALL but DS
;  (NOT RESTORED)
;
;  LINKAGE:	   Invoked by:	Clr_Mult_Block
;
;  EXTERNAL	   Invoke: CLP (SLE), OFL
;  REFERENCES:
;
;  NORMAL	   'C' clear if no error
;  EXIT:
;
;  ERROR	   'C' set if error
;  EXIT:	     (ax) = error code
;			       ('error_lock_violation' if conflicting locks or
;			       range does not exactly match previous lock)
;
;  CHANGE	04/15/87 - lock only write support
;  LOG:
;
;******************* END OF SPECIFICATIONS *************************************
;******************+ START OF PSEUDOCODE +**************************************
;
;	START Clr_Block
;
;	if file is SHARED and
;	if lock is valid and
;	if SFT matches and
;	if PROC_ID matches
;		if lock_reqest = lock_type
;			unchain the lock
;			put defunct lock on free chain
;			clear error status
;		else
;			set error status
;		endif
;	else
;		flush the stack
;		set error status
;	endif
;	if error
;		load return code
;	endif
;	return
;
;	END Clr_Block
;
;******************+  END  OF PSEUDOCODE +**************************************

   Procedure Clr_Block,NEAR

   ASSUME ES:NOTHING,DS:NOTHING

   Context DS
   push ds
;; push bx				; save type of operation	       ;AN000;
   cmp	es:[di].sf_mft,ZERO

;  $if	nz,and				; if file is SHARED and 	       ;AC000;
   JZ $$IF14

   push di
   call clp				; do common setup code

   ASSUME DS:NOTHING

   pop	bp				; ES:BP points to sft.
;; pop	bx				; recover the type of operation        ;AN000;

;  $if	c,and				; if lock exists and		       ;AC000;
   JNC $$IF14
;  $if	z,and				; if range given correctly and	       ;AC000;
   JNZ $$IF14
;
;	We've got the lock
;
;	(ds:di) = address of pointer (offset) to previous lock record
;	(es:BP) = sft address
;
; Now comes the tricky part.  Is the lock for us?  Does the lock match the SFT
; that was given us?  If not, then error.
;
   mov	si,[di] 			; (DS:SI) = address of lock record
   cmp	word ptr [si].rlr_sptr,bp

;  $if	z,and				; if SFT matches and		       ;AC000;
   JNZ $$IF14

   mov	bp,es
   cmp	word ptr [si].rlr_sptr+2,bp
;  $if	z,and				; (check both words of SFT pointer)    ;AC000;
   JNZ $$IF14
   mov	bp,proc_id
   cmp	[si].rlr_pid,bp

;; $if	z,and				; if PROC_ID matches		       ;AC000;
;  $if	z				; if PROC_ID matches		       ;AC006;
   JNZ $$IF14
;
; Make sure that the type of request and the lock type match
;
;; cmp	bx,lock_all			;				       ;AN000;

;; $IF	E,OR				; if unlocking all or		       ;AN000;

;; mov	bp,[si].rlr_type		; get lock type 		       ;AN000;
;; cmp	bp,rlr_lall			; is it lock all?		       ;AN000;

;; $IF	NE				; if not a LOCK ALL lock	       ;AN000;
;
; The locks match the proper open invocation.  Unchain the lock
;
       mov  ax,[si].rlr_next
       mov  [di],ax			; chain it out

;	put defunct lock record on the free chain
;
;	(ds:si) = address of freed lock rec

       mov  ax,Frelock
       mov  [si].rlr_next,ax
       mov  Frelock,si
       clc

;  $else				; we have an error		       ;AC000;
   JMP SHORT $$EN14
$$IF14:

       stc

;  $endif				; Endif - an error		       ;AC000;
$$EN14:

;  $if	c				; If an error was found 	       ;AC000;
   JNC $$IF17

       mov  ax,error_lock_violation

;  $endif				; Endif - an error was found	       ;AC000;
$$IF17:

   pop	ds				; restore DS

   ret


   EndProc Clr_Block

   BREAK <CLP - Common Lock Preamble>

;******************* START OF SPECIFICATIONS ***********************************
;
;  NAME:	   CLP - Common Lock Preamble
;
;  FUNCTION:	   This routine contains a common code fragment for set_block
;		   and clr_block.
;
;  INPUT:	   (ES:DI) = SFT address
;		   (CX:DX) = offset of area
;		   (SI:AX) = length of area
;		   User_ID = 16-bit user id of issuer
;		   Proc_ID = 16-bit process id of issuer
;		   (SS) = (DS) = DOSGroup
;
;  OUTPUT:	   (ds:si) = MFT address
;
;  REGISTERS USED: ALL but ES
;  (NOT RESTORED)
;
;  LINKAGE:	   Invoked by: Set_Block, Clr_Block
;
;  EXTERNAL	   Invoke: SLE
;  REFERENCES:
;
;  NORMAL	   'C' clear if no overlap
;  EXIT:	       (ax:bx) = offset of first byte in range
;		       (cx:dx) = offset of last byte in range
;
;  ERROR	   'C' set if overlap
;  EXIT:	   'Z' set if 1-to-1 match
;		       (di) points to previous lock
;
;  CHANGE	04/15/87 - lock only write support
;  LOG:
;
;******************* END OF SPECIFICATIONS *************************************
;******************+ START OF PSEUDOCODE +**************************************
;
;	START CLP
;
;	shuffle arguments
;	if valid length
;		invoke SLE
;		set successful return status
;	else
;		set error return status
;	endif
;	return
;
;	END CLP
;
;******************+  END  OF PSEUDOCODE +**************************************

   Procedure CLP,NEAR

   mov	bx,dx				; shuffle arguments
   xchg dx,ax
   xchg ax,cx				; (ax:bx) = offset
   mov	cx,si				; (cx:dx) = length

   or	si,dx				; see if length is 0

;  $if	nz,and				; if length is > 0 and		       ;AC000;
   JZ $$IF19

   add	dx,bx
   adc	cx,ax				; (cx:dx) = lba+1

;  $if	nc,or				; no carry is ok		       ;AC000;
   JNC $$LL19

   mov	si,dx
   or	si,cx

;  $if	z				; if !> 0 then			       ;AC000;
   JNZ $$IF19
$$LL19:

       sub  dx,1			; (cx:dx) = lba of locked region
       sbb  cx,0

       push cs
       pop  ds
;   (es:di) is sft
       push si
       mov  si,es:[di].sf_mft
       push si
       mov  di,1			; Find own locks
       call SLE
; di points to previous lock record
       pop  si
       pop  bp

;  $else				; we have an error		       ;AC000;
   JMP SHORT $$EN19
$$IF19:

       xor  si,si
       inc  si				; carry unchanged, zero reset
       mov  ax,error_lock_violation	; assume error
       stc

;  $endif				; endif - we have an error	       ;AC000;
$$EN19:

   ret

   EndProc CLP

   BREAK <Chk_Block - See if the specified I/O violates locks>

;******************* START OF SPECIFICATIONS ***********************************
;
;  NAME:	   Chk_Block - check range lock on a file
;
;  FUNCTION:	   Chk_Block is called to interogate the lock status of a
;		   region of a file.
;
;  NOTE:	   This routine is called for every disk I/O operation
;		   and MUST BE FAST
;
;  INPUT:	   (ES:DI) points to an SFT structure
;		   (AL) = 80h - Write operation  = 0 - any non write operation
;		   (CX) is the number of bytes being read or written
;		   BytPos is a long (low first) offset into the file
;			      of the I/O
;		   User_ID = 16-bit user id of issuer
;		   Proc_ID = 16-bit process id of issuer
;		   (SS) = DOSGroup
;
;  OUTPUT:	   CF set according to status and presence of locks (see below)
;
;  REGISTERS USED: ALL	but ES,DI,CX,DS
;  (NOT RESTORED)
;
;  LINKAGE:	   IBMDOS Jump Table
;
;  NORMAL	   'C' clear if no error
;  EXIT:
;
;  ERROR	   'C' set if error
;  EXIT:	     (ax) = error code
;			       ('error_lock_violation' if conflicting locks)
;
;  CHANGE	04/15/87 - lock only write support
;  LOG:
;
;******************* END OF SPECIFICATIONS *************************************
;******************+ START OF PSEUDOCODE +**************************************
;
;	START Chk_Block
;
;	if shared SFT and
;	if locks exist
;		invoke SLE
;		if lock conflicts occur (error)
;			if this is !write operation and
;			if a write lock found
;				set successfull status
;			else
;				set error status
;			endif
;		else no error
;			flush stack
;		endif
;	endif
;
;	ret
;
;	END Chk_Block
;
;******************+  END  OF PSEUDOCODE +**************************************

   Procedure Chk_Block,NEAR

   ASSUME DS:NOTHING,ES:NOTHING,SS:DOSGROUP

write_op equ 080h			; write operation requested	       ;AN000;
lock_all equ 0h 			; lock all specified		       ;AN000;

;	PUSH	DS			;ICE
;	push	bx			;ICE
;	push	ax			;ICE

;	mov	bx,0140H		;ICE
;	xor	ax,ax			;ICE
;	mov	ds,ax			;ICE
;	mov	ax,word ptr ds:[bx]	;ICE
;	mov	word ptr ds:[bx],ax	;ICE

;	pop	ax			;ICE
;	pop	bx			;ICE
;	POP	DS			;ICE
   EnterCrit critShare

;  int 3
   nop
   nop

   PUSH ES
   PUSH DI
   PUSH CX
   PUSH DS
   cmp	es:[di].sf_mft,0

;  $if	nz,and				; if the file is SHARED and	       ;AC000;
   JZ $$IF22

   push cs
   pop	ds
   mov	si,es:[di].sf_MFT		; (DS:SI) = address of MFT record
   test [si].mft_lptr,-1

;  $if	nz,and				; if there are locks on this file and  ;AC000;
   JZ $$IF22

   sub	cx,1				; (cx) = count-1
   cmc

;  $if	c				; there are bytes to lock	       ;AC000;
   JNC $$IF22

;;     push ax				; preserve type of operation	       ;AN000;
					; DOS passes AL = 80 for writes
					;		= 00 for reads

       mov  ax,WORD PTR BytPos+2
       mov  bx,WORD PTR BytPos		; (ax:bx) = offset
       mov  dx,cx
       sub  cx,cx
       add  dx,bx
       adc  cx,ax			; (cx:dx) = lba of lock area
       sub  di,di			; ignore own locks
       call SLE
;;     pop  ax				; recover type of opperation	       ;AN000;

;   upon return DS:SI points to the RLR with the conflict

;;     $if  c				; if lock conflicts occur - error      ;AC000;

;   now we must check what type of lock exists
;   and the type of operation in progress.

;;	   cmp	al,write_op		;				       ;AN000;

;;	   $if	ne,and			; if NOT a write operation and	       ;AN000;

;;	   cmp	[si].rlr_type,rlr_lwr	;				       ;AN000;

;;	   $if	e			; if write locked (NOT all locked)     ;AN000;

;;	       clc			; then not true conflict - clear error ;AN000;

;;	   $else			; else it IS a valid conflict	       ;AC000;

;;	       stc			; true error - set error status

;;	   $endif			; endif - a valid conflict	       ;AC000;


;;     $endif				; endif -  conflicts		       ;AC000;

       mov  ax,error_lock_violation	; assume error

;  $endif				; endif - no need to check	       ;AC000;
$$IF22:

;	exit
;
;	'C' and (ax) setup

   POP	DS
   POP	CX
   POP	DI
   POP	ES
   LeaveCrit critShare

   ret					; exit

   EndProc Chk_Block

   BREAK <MFT_get - get an entry from the MFT>

;******************* START OF SPECIFICATIONS ***********************************
;
;	MFT_get - get an entry from the MFT
;
;	MFT_get is used to return information from the MFT.  System utilities
;	use this capability to produce status displays.
;
;	MFT_get first locates the (BX)'th file in the list (no particular
;		ordering is promised).	It returns that name and the UID of
;		the (CX)'th SFT on that file and the number of locks on that
;		file via that SFT.
;
;	ENTRY	DS:SI point to DPL which contains:
;		(dBX) = zero-based file index
;		(dCX) = zero-based SFT index
;		(SS) = DOSGroup
;	EXIT	'C' clear if no error
;		  ES:DI buffer is filled in with BX'th file name
;		  (BX) = user id of SFT
;		  (CX) = # of locks via SFT
;		'C' set if error
;		  (ax) = error code
;			    ('error_no_more_files' if either index is out
;			     of range)
;
;******************* END OF SPECIFICATIONS *************************************

   Procedure MFT_get,NEAR

;  int 3
   nop
   nop

   ASSUME DS:NOTHING,ES:NOTHING

   EnterCrit critShare
   MOV	BX,[SI.DPL_BX]
   MOV	CX,[SI.DPL_CX]
   Context ES
   MOV	DI,OFFSET DOSGROUP:OpenBuf

   xchg bx,cx				; (cx) = file index
   push cs
   pop	ds

   Off	SI,mft				; (ds:si) = fwa of OFFSET MFT

;	scan forward until next name

mget1: cmp [si].mft_flag,MFLG_FRE
   jz	mget3				; is free space
   jl	mget7				; is END

;	have another name.  see if this satisfies caller

   jcxz mget4				; caller is happy
   dec	cx
mget3: add si,[si].mft_len		; skip name record
   JMP	SHORT mget1

;	we've located the file name.
;
;	(bx) = SFT index
;	(DS:SI) = MFT entry
;	(ES:DI) = address of caller's buffer

mget4: push di
   push si				; save table offset
   add	si,mft_name
mget5: lodsb
   stosb				; copy name into caller's buffer
   or	al,al
   jnz	mget5
   pop	si				; (DS:SI) = name record address
   xchg bx,cx				; (cx) = SFT chain count
   lds	di,[si].mft_sptr
mget6: jcxz mget8			; have reached the SFT we wanted
   dec	cx
   lds	di,[di].sf_chain		; get next link
   or	di,di
   jnz	mget6				; follow chain some more
   pop	di				; (es:di) = buffer address

;**	The file or SFT index was too large - return w/ error

mget7: mov ax,error_no_more_files
   stc
   LeaveCrit critShare

   ret

;**	We've got the SFT he wants.  Lets count the locks
;
;	(es:TOS) = buffer address
;	(DS:DI) = address of SFT
;	(si) = address of mft

mget8: mov ax,[DI].sf_flags
   mov	dx,ds				; save segment
   push cs
   pop	ds
   mov	si,[si].mft_lptr		; (DS:SI) = Lock record address
   sub	cx,cx				; clear counter

mget9: or si,si
   jz	mget11				; no more
   cmp	di,WORD PTR [si].rlr_sptr
   jnz	mget10
   cmp	dx,word PTR [si].rlr_sptr+2
   jnz	mget10
   inc	cx
mget10: mov si,[si].rlr_next
   JMP	SHORT mget9

;	Done counting locks.  return the info
;
;	(cx) = count of locks
;	(es:TOS) = buffer address

mget11: mov ds,dx
   mov	bx,[di].SF_UID			; (bx) = UID
   pop	di
   clc
   LeaveCrit critShare

   ret

   EndProc MFT_get

   BREAK <ASC - Add SFT to Chain>

;******************* START OF SPECIFICATIONS ***********************************
;
;	ASC - Add SFT to Chain
;
;	ASC is called to add an SFT to the front of the chain.
;
;	ASC checks the file share mode bits on the other SFTs in the chain and
;	reports a conflict.  The new SFT is NOT ADDED in the case of
;	conflicts.
;
;	ENTRY	(BX) = FBA MFT name record
;		(DS:SI) = SFT address
;	EXIT	'C' clear if added
;		    (ds:si) point to sft
;		    (bx) offset of mft
;		'C' set if conflict
;		  (ax) = error code
;	USES	ALL
;
;******************* END OF SPECIFICATIONS *************************************

   Procedure ASC,NEAR

   cmp	[si].sf_MFT,0
   jnz	asc9				; already on chain - internal error

;	The SFT looks good... lets see if there are any use conflicts

;	Message 1,<"Adding sft ">

   mov	ax,User_ID			; place user information in SFT
   mov	[si].sf_UID,ax			; do it before CUC (he checks UID)
   mov	ax,Proc_ID
   mov	[si].sf_PID,ax

   cmp	skip_check,1
;  $if	ne				;
   JE $$IF24

       call CUC 			; check use conflicts

;  $endif
$$IF24:

   jc	asc8				; use conflicts - forget it

;	MessageNum   AX

;	MessageNum   AX
;	Message 1,<" to ">
;	MEssageNum  DS
;	Message 1,<":">
;	MessageNum  SI
;	Message 1,<" ">

   mov	[si].sf_MFT,bx			; make SFT point to MFT

;	MessageNum  [si].sf_mft
;	Message 1,<13,10>

   mov	cx,[si].sf_mode 		; (cx) = open mode
   mov	dx,ds				; (dx:si) = SFT address
   push cs
   pop	ds				; (ds:bx) = MFT address

;
;   Not special file and no previous sft found OR normal SFT.  We link it in
;   at the head of the list.
;
;   (dx:si) point to sft
;   (ds:bx) point to mft
;
   les	di,[bx].mft_sptr		; get first link
   mov	word ptr [bx].mft_sptr,si	; link in this sft
   mov	word ptr [bx].mft_sptr+2,dx	; link in this sft
   mov	ds,dx
   mov	word ptr [si].sf_chain,di
   mov	word ptr [si].sf_chain+2,es
asc75: mov ds,dx			; point back to sft

   clc
asc8: ret

;	the SFT is already in use... internal error

asc9: push ax
   off	ax,ascerr
   call INTERR				; NEVER RETURNS
ascerr db "ASC: sft already in use", 13, 10, 0

   EndProc ASC


   BREAK <BCS - Bulk Close of SFTs>

;******************* START OF SPECIFICATIONS ***********************************
;
;	BCS - Bulk Close of SFTs
;
;	BCS scans the MFT structures looking for SFTs that match a UID (and
;	perhaps a PID).  The SFTs are closed.  The MFT name record is removed
;	if all its SFTs are closed.
;
;	BCS is called with a PID and a PID MASK.  The SFT is closed if its UID
;	matches the supplied UID AND (PID_ & PIDMASK) == PID_supplied
;
;	We walk the MFT structure closing all relevant SFT's. There is no
;	need for special handling of 70 handles or FCBs.
;
;	Note that we call DOS_close to close the SFT; DOS_close in turn calls
;	mftclose which may remove the SFT and even the MFT.  This means that
;	the MFT may vanish as we are working on it.  Whenever we call
;	DOS_close we'll know the next SFT and, if there is no next SFT we'll
;	know the next MFT.  (If the MFT were released a pointer to the carcass
;	is not of any help.  An MFT carcass cannot help find the next MFT
;	record)
;
;	ENTRY	(AX) = UID to match
;		(BX) = PID mask
;		(DX) = PID value
;	EXIT	'C' clear
;	USES	ALL
;
;******************* END OF SPECIFICATIONS *************************************

   ASSUME SS:DOSGROUP

   Procedure BCS,NEAR

   push cs
   pop	ds

   Off	SI,mft				; start at beginning of buffer

;	scan forward to the nearest name record (we may be at it now)
;
;	(DS:SI) = record pointer

bcs1: cmp [si].mft_flag,MFLG_FRE
   jl	bcs16				; at end of names, all done
   jg	bcs2				; have a name record

bcs1$5: add si,[si].mft_len		; skip record and loop
   jmp	bcs1

bcs16: jmp bcs9

bcs2: les di,[si].mft_sptr		; got name record - get first SFT
;	run down SFT chain
;
;	(es:di) = FBA next SFT
;	(ds:si) = FBA name record
;	(ax) = UID to match
;	(bx) = PID mask
;	(dx) = PID value

bcs3: or di,di
   jz	bcs1$5				; at end of SFT chain
   cmp	ax,es:[di].sf_UID
   jnz	bcs4				; not a match
   mov	cx,es:[di].sf_PID
   and	cx,bx				; apply mask
   cmp	cx,dx
   jz	bcs51				; got a match
bcs4:
   les	di,es:[di].sf_chain
   JMP	bcs3				; chain to next SFT


;	We have an SFT to close
;
;	(es:di) = FBA SFT to be closed
;
;	(ds:si) = FBA name record
;	(ax) = UID to match
;	(bx) = PID mask
;	(dx) = PID value

bcs51: mov es:[di].sf_ref_count,1
   push ax
   push bx
   push dx				; save ID values (ax,bx,dx) and mask
   push ds
   push si				; save name record address (ds:si)
   mov	si,word ptr es:[di].sf_chain
   or	si,si
   jnz	bcs7				; isnt last sft, MFT will remain

;	yup, this is the last sft for this MFT, the MFT may evaporate.	we have
;	to find the next one NOW, and remember it

   pop	si				; undo saved name record address
   pop	ds
bcs6: add si,[si].mft_len		; go to next guy
   cmp	[si].mft_flag,MFLG_FRE
   jz	bcs6				; must be a non-free guy
   push ds
   push si				; resave our new next MFT
   sub	si,si				; no next sft

;	Allright, we're ready to call the DOS.
;
;	(es:di)     = FBA sft to be closed
;	((sp))	 = long address of current or next MFT
;	((sp)+4) = PID value
;	((sp)+6) = PID mask
;	((sp)+8) = UID value

bcs7: mov WORD PTR ThisSFT,di
   mov	WORD PTR ThisSFT+2,es
   mov	es,word ptr es:[di].sf_chain+2
   SaveReg <es,si>
   call CPS				; clear JFN
   Context DS

   CallInstall DOS_Close,multDos,1

   ASSUME DS:NOTHING

   RestoreReg <di,es>			; (es:DI) = offset of next sft
   pop	si
   pop	ds				; (DS:SI) = fwa of current or next MFT
   pop	dx
   pop	bx
   pop	ax
   or	di,di
   jnz	bcs85				; have more sft's
   JMP	bcs1				; look at this new MFT
bcs85: jmp bcs3

;	All Done

bcs9: clc

   ret

   EndProc BCS

   BREAK <CSL - Clear SFT Locks>

;******************* START OF SPECIFICATIONS ***********************************
;
;	CSL - Clear SFT Locks
;
;	CSL clears any locks associated with this SFT.
;
;	ENTRY	(ES:DI) = SFT address
;	EXIT	(ES:DI) unchanged
;	USES	All but ES,DI
;
;******************* END OF SPECIFICATIONS *************************************

   Procedure CSL,NEAR

   mov	si,es:[di].sf_MFT
   push cs
   pop	ds
   lea	bx,[si].mft_lptr		; (DS:BX) = addr of lock ptr
   mov	si,[bx] 			; (DS:SI) = fba first lock record

;	scan the locks looking for belongers.
;
;	(es:di) = SFT address
;	(ds:si) = this lock address
;	(ds:bx) = address of link (offset value) to this lock (prev lock)

csl1: or si,si
   jz	csl3				; done with lock list
   cmp	di,word ptr [si].rlr_sptr
   jnz	csl2				; not my lock
   mov	ax,es
   cmp	ax,word ptr [si].rlr_sptr+2
   jnz	csl2				; not my lock
;
; Make sure that the lock REALLY belongs to the correct process
;
   cmp	user_in_ax, (ServerCall shl 8) + 4 ; only check if   ; @@01
   jnz	csl15				; process specific; @@01
   mov	ax,Proc_ID
   cmp	ax,[si].rlr_pid 		; is process ID of lock = this PID?
   jnz	csl2				; nope, skip this lock

;	got a lock to remove

csl15:
   mov	dx,[si].rlr_next
   mov	[bx],dx 			; link him out
   mov	ax,Frelock
   mov	[si].rlr_next,ax
   mov	Frelock,si
   mov	si,dx				; (DS:SI) = next lock address
   JMP	SHORT csl1

   ERRNZ rlr_next			; lock is not ours... follow chain
csl2: mov bx,si
   mov	si,[si].rlr_next
   JMP	SHORT csl1

;	All done

csl3: ret

   EndProc CSL

   ASSUME DS:NOTHING

   BREAK <CUC - check usage conflicts>

;******************* START OF SPECIFICATIONS ***********************************
;
;	Use conflict table
;
;	Algorithm:
;
;		if ((newmode == COMPAT) or (oldmode == COMPAT))
;			and (user ID's match)
;		   then accept
;		else
;		for new and old mode, compute index of (SH*3)+ACC
;		shift right table[new_index] by old_index+2;
;			'C' set if FAIL
;
;	The bit in the old_index position indicates the success or failure.  0
;	=> allow access, 1 => fail access
;
;******************* END OF SPECIFICATIONS *************************************

   PUBLIC CUCA

CUCA: DW 0ffffh 			; Compat    Read
   DW	0ffffh				; Compat    Write
   DW	0ffffh				; Compat    Read/Write
   DW	0ffffh				; Deny R/W  Read
   DW	0ffffh				; Deny R/W  Write
   DW	0ffffh				; Deny R/W  Read/Write
   DW	0df7fh				; Deny W    Read
   DW	0dbffh				; Deny W    Write
   DW	0dfffh				; Deny W    Read/Write
   DW	0beffh				; Deny R    Read
   DW	0b7ffh				; Deny R    Write
   DW	0bfffh				; Deny R    Read/Write
   DW	01c7fh				; Deny None Read
   DW	003ffh				; Deny None Write
   DW	01fffh				; Deny None Read/Write

;					     4443 3322 2111 000
;   Deny/Compat 			/    DDDD DDDD DDDD CCCx
;   DenyRead			       /	R RR	RRR
;   DenyWrite		  1st Access =< 	    WW WWWW
;   AccessRead			       \     R RR  RR  RR R R R
;   AccessWrite 			\    WW W W WW	WW  WW
;   x					     1111 1111 1111 1111
;   C  R    00				     1111 1111 1111 1111  ffff
;   C	W   01				     1111 1111 1111 1111  ffff
;   C  RW   02				     1111 1111 1111 1111  ffff

;   DRWR    10				     1111 1111 1111 1111  ffff
;   DRW W   11				     1111 1111 1111 1111  ffff
;   DRWRW   12				     1111 1111 1111 1111  ffff
;   D WR    20				     1101 1111 0111 1111  df7f

;   D W W   21				     1101 1011 1111 1111  dbff
;   D WRW   22				     1101 1111 1111 1111  dfff
;   DR R    30				     1011 1110 1111 1111  beff
;   DR	W   31				     1011 0111 1111 1111  b7ff

;   DR RW   32				     1011 1111 1111 1111  bfff
;   D  R    40				     0001 1100 0111 1111  1c7f
;   D	W   41				     0000 0011 1111 1111  03ff
;   D  RW   42				     0001 1111 1111 1111  1fff

;   In order to allow the greatest number of accesses, compatability read mode
;   is treated as deny-write read.  The other compatability modes are treated
;   as deny-both.

;******************* START OF SPECIFICATIONS ***********************************
;
;	CUC - check usage conflicts
;
;	CUC is called to see if a would-be open would generate a share
;	conflict with an existing open.  See CUCA for the algorithm and table
;	format.
;
;	ENTRY	(BX) = FBA MFT name record
;		(DS:SI) = SFT address
;	EXIT	'C' clear if OK
;		'C' set if conflict
;		  (ax) = error code
;	USES	ALL but arguments (BX, DS:SI)
;
;******************* END OF SPECIFICATIONS *************************************

   Procedure CUC,NEAR

   push ds
   pop	es
   mov	di,si				; (es:di) = FBA SFT record
   call gom				; get open mode
   mov	ch,al
   and	ch,sharing_mask 		; (ch) = new guy share
   jz	cuc0				; new guy is compatability mode
   mov	ch,sharing_mask
cuc0: call csi				; compute share index
   add	ax,ax				; *2 for word index
   xchg ax,si				; (si) = share table index
   push cs
   pop	ds				; (ds:bx) = FBA MFT record
   mov	dx,WORD PTR CUCA[si]		; (dx) = share mask
   lds	si,[bx].mft_sptr		; (ds:si) = first sft guy

;	ready to do access compares.
;
;	(ds:si) = address of next sft
;	(es:di) = address of new  sft
;	(dx) = share word from CUCA
;	(cs:bx) = MFT offset
;	(ch) = 0 if new SFT is compatibilty mode, else sharing_mask

cuc1: or si,si
   jz	cuc9				; at end of chain, no problems
   call gom				; if not FCB, then mode in al is good
   mov	ah,al
   and	ah,sharing_mask 		; (ah) = sharing mode
   or	ah,ch				; (ah) = 0 iff new and old is SH_COMP
   jnz	cuc2				; neither is SH_COMP

;	Both the old and the new guy are SH_COMP mode.	If the UIDs match,
;	step onward.  If they don't match do normal share check.

   mov	bp,es:[di].sf_UID
   cmp	bp,[si].sf_UID
   jz	cuc20				; equal => next sft to check

cuc2: call csi				; compute the share index
   inc	ax
   inc	ax
   xchg al,cl				; (cl) = shift count
   mov	ax,dx
   sar	ax,cl				; select the bit
   jc	cuc8				; a conflict!
cuc20:
   lds	si,[si].sf_chain
   JMP	cuc1				; chain to next SFT and try again

;	Have a share conflict

cuc8: mov ax,error_sharing_violation	; assume share conflict
   stc

;	done with compare.  Restore regs and return
;
;	'C' set as appropriate
;	(es:di) = new SFT address
;	(ax) set as appropriate
;	(bx) = MFT offset

cuc9: push es
   pop	ds
   mov	si,di

   ret

   EndProc CUC

   BREAK <csi - compute share index>

;******************* START OF SPECIFICATIONS ***********************************
;
;	csi - compute share index
;
;
;	If the mode byte has a leading 7 then it is interpreted as a 0
;	csi turns a mode byte into an index from 0 to 14:
;
;		(share index)*3 + (access index)
;
;	ENTRY	(al) = mode byte
;	EXIT	(ax) = index
;	USES	AX, CL
;
;******************* END OF SPECIFICATIONS *************************************

   Procedure CSI,NEAR

   mov	ah,al
   and	ah,access_mask			; (ah) = access bits
   and	al,sharing_mask 		; (al) = share bites
   ERRNZ sharing_mask-0F0h
   cmp	al,sharing_net_FCB
   jnz	csi1
   xor	al,al
csi1:
   shr	al,1
   shr	al,1
   shr	al,1
   mov	cl,al				; (cl) = SHVAL*2
   shr	al,1
   add	al,cl				; (al) = SHVAL*3
   add	al,ah				; (al) = SH*3 + ACC
   sub	ah,ah

   ret

   EndProc CSI

   Break <GOM - get open mode>

;******************* START OF SPECIFICATIONS ***********************************
;
;	GOM - get open mode
;
;   Find the correct open mode given the encoded sf_mode.  Note that files
;   marked READ-ONLY and are opened in compatability read-only are treated as
;   deny-write read-only.  FCB opens are sharing_compat open_for_both and
;   net FCB opens are sharing_compat
;
;	Entry:	    (DS:SI) points to SFT
;   Exit:	(AL) has correct mode
;   Uses:	(AX)
;******************* END OF SPECIFICATIONS *************************************

   Procedure GOM,NEAR

   mov	ax,[si].sf_mode
   TEST AX,sf_IsFCB
   jz	gom1				; if not FCB, then mode in al is good
   mov	al,sharing_compat+open_for_both
gom1:
   mov	ah,al
   and	ah,sharing_mask
   cmp	ah,sharing_net_FCB		; is sharing from net FCB?
   jnz	gom2				; no, got good mode
   and	al,access_mask			; yes, convert to compat mode sharing
   or	al,sharing_compat
;
; The sharing mode and access mode in AL is now correct for the file.  See if
; mode is compatability.  If so and file is read-only, convert access mode to
; deny-write read.
;
gom2:
   mov	ah,al
   and	ah,sharing_mask
   retnz				; not compatability, return.
   test [si].sf_attr,attr_read_only
   retz 				; not read-only
   mov	al,sharing_deny_write + open_for_read

   ret

   EndProc GOM

   SHARE ENDS

   END
   ELSE
CODE ENDS
   ENDIF
   END					; This can't be inside the if
; mode is compatability.  If so and file is read-only, convert access mode to
; deny-write read.
;
gom2:
   mov	ah,al
   and	ah,sharing_mask
   retnz				; not compatability, return.
   test [si].sf_attr,attr_read_only
   retz 				; not read-only
   mov	al,sharing_deny_write + open_for_read

   ret

   EndProc GOM

   SHARE ENDS

   END
   ELSE
CODE ENDS
   ENDIF
   END					; This can't be inside the if
