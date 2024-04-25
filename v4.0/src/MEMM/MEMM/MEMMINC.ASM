

	page 58,132
;******************************************************************************
	title	MEMMINC.ASM - lists all MEMM include files
;******************************************************************************
;
;   (C) Copyright MICROSOFT Corp. 1986
;
;	Title:	   MEMM - MICROSOFT Expanded Memory Manager
;
;	Module:	   MEMMINC.ASM - lists all MEMM include files
;
;	Version:   0.02
;
;	Date:	   June 14, 1986
;
;	Author:
;
;******************************************************************************
;
;	Change Log:
;
;	DATE	 REVISION	Description
;	-------- --------	--------------------------------------------
;	06/25/86 original	
;	06/28/86 0.02		Name change from MEMM386 to MEMM
;
;******************************************************************************
;   Functional Description:
;		This module includes all MEMM include files and will
;   provide a listing of all when assembled to produce a listing file.
;
;******************************************************************************
.lfcond
.386p

;******************************************************************************
;	I N C L U D E S
;******************************************************************************
INC_LIST	EQU	1		; list include files

	page
	include	ASCII_SM.EQU
	page
	include	DRIVER.EQU
	page
	include	PIC_DEF.EQU
	page
	include	ROMSTRUC.EQU
	page
	include	ROMXBIOS.EQU

	page
	include	DESC.INC
	page
	include	ELIM.INC
	page
	include	EMM386.INC
	page
	include	INSTR386.INC
	page
	include	KBD.INC
	page
	include	LOADALL.INC
	page
	include	OEMDEP.INC
	page
	include	PAGE.INC
	page
	include	VDMSEG.INC
	page
	include	VDMSEL.INC
	page
	include	VM386.INC

	page
	include	DRIVER.STR

	end
