page 80,132
;0
title CP/DOS  DosOpen  mapper


FileAttributeSegment   segment word public 'fat'

		       public	FileAttributeTable

FileAttributeTable     dw     100  dup(0)

FileAttributeSegment	ends


dosxxx	segment byte public 'dos'
	assume	cs:dosxxx,ds:nothing,es:nothing,ss:nothing
;
; ************************************************************************* *
; *
; *	 MODULE: DosOpen
; *
; *	 FILE NAME: DosOpen.ASM
; *
; *	 FUNCTION: This module creates the specified file (if necessary),
; *		   and opens it.  If the file name is a device then the
; *		   handle returned will be a device handle.  The high order
; *		   byte of the open flag is ignored because PC/DOS does not
; *		   support a word long open mode.  Invalid parameters are
; *		   reported as general failures because there are no error
; *		   codes defined at this time.
; *
; *	 CALLING SEQUENCE:
; *
; *		   PUSH@ ASCIIZ  FileName	   ;  File path name
; *		   PUSH@ WORD	 FileHandle	   ;  New file's handle
; *		   PUSH@ WORD	 ActionTaken	   ;  Action taken
; *		   PUSH  DWORD	 FileSize	   ;  File primary allocation
; *		   PUSH  WORD	 FileAttribute	   ;  File attribute
; *		   PUSH  WORD	 OpenFlag	   ;  Open function type
; *		   PUSH  WORD	 OpenMode	   ;  Open mode of the file
; *		   PUSH@ DWORD	 0		   ;  Reserved (must be zero)
; *		   CALL DosOpen
; *
; *	 RETURN SEQUENCE:
; *
; *		   IF ERROR (AX not = 0)
; *
; *		      AX = Error Code:
; *
; *		      o   Invalid parameter(s)
; *
; *		      o   Insufficient disk space available
; *
; *		      o   Insufficient resources (i.e., file handles)
; *
; *
; *	 MODULES CALLED:  DOS int 21H function 3DH
; *			  DOS int 21H function 3EH
; *			  DOS int 21H function 40H
; *			  DOS int 21H function 42H
; *			  DOS int 21H function 43H
; *
; *************************************************************************
;
	public	DosOpen
	.sall
	.xlist
	include macros.inc
	.list

ACT_FileExisted 	equ	1
ACT_FileCreated 	equ	2


str	struc
old_bp		dw     ?
return		dd     ?
resrv34 	dd     ?     ; reserved
OpenMode	dw     ?     ; open mode
OpenFlag	dw     ?     ; open function type (1=Open only if already exist)
OpenFileAttr	dw     ?     ; file attribute
FileSize	dd     ?     ; file allocation size
acttak34	dd     ?     ; action taken
FileHandlePtr	dd     ?     ; New file handler
FileNamePtr	dd     ?     ; file name pointer
str	ends

;
DosOpen  proc	far
	Enter	DosOpen 	       ; save registers
	sub	sp,2		       ; allocate space on the stack
SaveArea	equ	-2

; Check to see if we are trying to open a DASD device.	If so, we must do
; something unique as PC-DOS does not support this behavior.
; Return a dummy DASD file handle.  This used by IOCTL category 8 option.

	test	[bp].OpenMode,08000h   ; DASD open ?
	jz	FileOpenRequest        ; branch if file open

	lds	si,[bp].FileNamePtr    ; convert device name to upper case
	mov	al,ds:[si]
	cmp	al,'a'
	jc	NoFold
	cmp	al,'z'+1
	jnc	NoFold

	add	al,'A' - 'a'

NoFold:
	sub	al,'A'
	jc	BadDASDName	       ; jump if bad DASD name

	cmp	al,27
	jnc	BadDASDName

	xor	ah,ah		       ; drive number from 0 to 25
	inc	ax		       ;		   1 to 26
	inc	ax		       ;		   2 to 27
	neg	ax		       ;		   -2 to -27

	lds	si,[bp].FileHandlePtr
	mov	ds:[si],ax	       ; save dasd dummy device handle
	jmp	GoodExit	       ; in return data area and return

BadDASDName:
	mov	ax,3		       ; set error code
	jmp	ErrorExit	       ; return


;  Query the file attribute to determine if file exists


FileOpenRequest:
	lds	dx,dword ptr [bp].FileNamePtr ; load asciiz string address
	mov	ax,04300h	      ; query file mode
	int	21h		      ; get file mode
	jnc	SaveAttribute	      ; file does exist

	cmp	ax,00002h	      ; check if file does not exist error
	je	dne34		      ; go here if does not exist

	jmp	erret34 	      ; error return

SaveAttribute:
	mov	[bp].SaveArea,cx

;  File exists - determine what to do

	lds	si,dword ptr [bp].acttak34 ; Load action taken pointer
	mov	word ptr[si],ACT_FileExisted   ; Indicate that file existed
	mov	ax,[bp].OpenFlag   ; load open flag
	and	ax,00003h	   ; mask off the replace and open flags
	cmp	ax,00003h	   ; check if both are requested
	je	nxt134		   ; error - invalid parm

	cmp	ax,00001h	   ; check if file is to be opened
	je	opn34		   ; file should be opened

	cmp	ax,00002h	   ; check if file should be replaced
	je	creat34 	   ; file should be replaced

nxt134:;
	mov	ax,0000ch	   ; report general
	jmp	erret34 	   ;   failure

;
opn34:;

;  set the file attribute ( *** commented to fix mapper problem Pylee 6/10
;
;	lds	dx,dword ptr [bp].FileNamePtr ; load asciiz string address
;	mov	cx,[bp].OpenFileAttr	; load the file attribute
;	mov	ax,04301h	   ; change file mode
;	int	21h		   ; get file mode
;	jnc	nxto34		   ; continue good return
;	jmp	erret34 	   ; error retrun

nxto34:;

;  open the file

	lds	si,dword ptr [bp].acttak34 ; load action taken pointer
	mov	word ptr [si],00h     ; clear action reported flag
	lds	dx,dword ptr [bp].FileNamePtr ; load asciiz string address
	mov	ax,[bp].OpenMode   ; load the  file mode

	mov	ah,03dh 	   ; load opcode
	int	21h		   ; open file
	jc	ErrorExit	   ; error return

FileWasThere:
	lds	si,dword ptr [bp].FileHandlePtr ; load file handle address
	mov	[si],ax 	   ; save file handle
	jmp	PutAwayAttribute   ; normal return

dne34:;

;  File does not exist - determine what to do

	mov	ax,[bp].OpenFlag   ; load open flag
	and	ax,00010h	   ; check create
	cmp	ax,00010h	   ;		 and open file flag
	je	creat34 	   ; go create the file

	mov	ax,0000ch	   ; report general failure
	jmp	erret34 	   ;		     if create not requested

creat34:;

;  file did not exist so it was created or replacement was requested

	lds	si,dword ptr [bp].acttak34 ; load action taken pointer
	mov	word ptr [si],ACT_FileCreated  ; file created -  action reported
	lds	dx,dword ptr [bp].FileNamePtr ; load asciiz string address
	mov	cx,[bp].OpenFileAttr	; set file attribute

	mov	ah,03ch
	int	21h		   ; create the file
	jc	erret34 	   ; error return

	lds	si,dword ptr [bp].FileHandlePtr ; load file handle address
	mov	[si],ax 		   ; save file handle
;
; set file length
;
	les	dx,[bp].FileSize
	mov	cx,es
	mov	bx,ax		   ; load file handle

	mov	ax,04202h	   ; load opcode
	int	21h		   ; move file pointer
	jc	erret34 	   ; error return

len134:;
	lds	si,dword ptr [bp].FileHandlePtr ; load file handle address
	mov	bx,[si] 	   ; load file handle
	lds	dx,dword ptr [bp].acttak34
	sub	cx,cx

	mov	ah,040h
	int	21h		   ; write 0 length record
	jc	erret34 	   ; error return

;
len234:;
;
;  close and reopen the file to make the length permanent
;
	lds	si,dword ptr [bp].FileHandlePtr ; load file handle address
	mov	bx,[si] 		   ; load file handle
	mov	ah,03eh
	int	21h
	jc	erret34 	   ; error return

	lds	dx,dword ptr [bp].FileNamePtr ; load asciiz string address
	mov	ax,[bp].OpenMode   ; load the  file mode
	mov	ah,03dh 	   ;
	int	21h		   ; open the file
	jc	erret34 	   ; error return

	lds	si,dword ptr [bp].FileHandlePtr ; load file handle address
	mov	[si],ax 	   ; save file handle

PutAwayAttribute:		   ; save file attribute for other mapper
	mov	bx,ax		   ; calls
	add	bx,bx

	mov	ax,seg FileAttributeSegment
	mov	ds,ax
	assume	ds:FileAttributeSegment

	mov	ax,[bp].SaveArea
	mov	FileAttributeTable[bx],ax	; save file attribute

GoodExit:
	sub	ax,ax		   ; set good return code

erret34:;
ErrorExit:
	add	sp,2		   ; deallocate space
	mexit			   ; restore registers
	ret	size str - 6	   ; return

DosOpen  endp

dosxxx	ends

	end
