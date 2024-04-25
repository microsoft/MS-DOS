	TITLE	Assembler helper routines for FLUSH13

PAGE	58,132


memS	EQU	1		; Small model
?PLM	=	0		; Standard 'C'
?WIN	=	0		; Not windows

include cmacros.inc

;extern int	 IOCTLOpen(char *);
;extern int	 IOCTLWrite(int,char *,int);
;extern int	 IOCTLRead(int,status *,int);
;extern int	 IOCTLClose(int);

sBegin	CODE

assumes CS, CODE
assumes DS, DATA

;**	IOCTLOpen - Open the indicated device and make sure it's a device
;
;  ENTRY:
;	Pointer to name of device
;  EXIT:
;	AX = -1 if error, device not opened
;	else AX = handle of open device
;  USES:
;	Standard 'C'
;
cProc IOCTLOpen, <PUBLIC>, <si,di,es>

ParmW Nameptr

cBegin
	mov	dx,Nameptr
	MOV	AX,3D02H
	INT	21H		; Open the device
	JC	NO_DEV_ERR	; No device
	MOV	BX,AX
	MOV	AX,4400H
	INT	21H		; Make sure it IS a device
	JC	CLOSE_NO_DEV
	TEST	DX,4080H
	JZ	CLOSE_NO_DEV
	mov	ax,bx		; Return the handle
	jmp	short PXDONE

CLOSE_NO_DEV:
	mov	ax,3e00H	; Close
	int	21H
NO_DEV_ERR:
	mov	ax,-1
PXDONE:
cEnd

;**	IOCTLClose - Close the indicated handle
;
;  ENTRY:
;	Handle
;  EXIT:
;	None
;  USES:
;	Standard 'C'
;
cProc IOCTLClose, <PUBLIC>, <si,di,es>

ParmW Handle

cBegin
	mov	bx,Handle
	MOV	AX,3E00H
	INT	21H		; close the device
cEnd

;**	IOCTLWrite - Perform IOCTLWrite to device handle
;
;  ENTRY:
;	Handle to open device
;	Pointer to data to write
;	Count in bytes of data to write
;  EXIT:
;	AX = -1 error
;	else AX = input count
;  USES:
;	Standard 'C'
;
cProc IOCTLWrite, <PUBLIC>, <si,di,es>

ParmW WHandle
ParmW WDataPtr
ParmW WCount

cBegin
	mov	bx,WHandle
	mov	cx,WCount
	mov	dx,WDataPtr
	MOV	AX,4403H	; IOCTL Write
	INT	21H
	JC	Werr
	CMP	AX,CX
	JNZ	Werr
	jmp	short WDONE

WERR:
	mov	ax,-1
WDONE:
cEnd

;**	IOCTLRead - Perform IOCTLRead to device handle
;
;  ENTRY:
;	Handle to open device
;	Pointer to data area to read into
;	Count in bytes of size of data area
;  EXIT:
;	AX = -1 error
;	else AX = input count
;  USES:
;	Standard 'C'
;
cProc IOCTLRead, <PUBLIC>, <si,di,es>

ParmW RHandle
ParmW RDataPtr
ParmW RCount

cBegin
	mov	bx,RHandle
	mov	cx,RCount
	mov	dx,RDataPtr
	MOV	AX,4402H	; IOCTL Read
	INT	21H
	JC	Rerr
	CMP	AX,CX
	JNZ	Rerr
	jmp	short RDONE

RERR:
	mov	ax,-1
RDONE:
cEnd


sEnd	CODE

	end
