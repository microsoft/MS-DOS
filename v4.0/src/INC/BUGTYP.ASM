;	SCCSID = @(#)bugtyp.asm	1.1 85/04/09
;
; debugging types and levels for MSDOS
;

TypAccess   EQU     0001h
    LevSFN	EQU	0000h
    LevBUSY	EQU	0001h

TypShare    EQU     0002h
    LevShEntry	EQU	0000h
    LevMFTSrch	EQU	0001h

TypSect     EQU     0004h
    LevEnter	EQU	0000h
    LevLeave	EQU	0001h
    LevReq	EQU	0002h

TypSMB	    EQU     0008h
    LevSMBin	EQU	0000h
    LevSMBout	EQU	0001h
    LevParm	EQU	0002h
    LevASCIZ	EQU	0003h
    LevSDB	EQU	0004h
    LevVarlen	EQU	0005h

TypNCB	    EQU     0010h
    LevNCBin	EQU	0000h
    LevNCBout	EQU	0001h

TypSeg	    EQU     0020h
    LevAll	EQU	0000h

TypSyscall  EQU     0040h
    LevLog	EQU	0000h
    LevArgs	EQU	0001h

TypInt24    EQU     0080h
    LevLog	EQU	0000h

TypProlog   EQU     0100h
    LevLog	EQU	0000h

TypInt	    EQU     0200h
    LevLog	equ	0000h

typFCB	    equ     0400h
    LevLog	equ	0000h
    LevCheck	equ	0001h
