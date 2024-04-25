

;******************************************************************************
;
;   (C) Copyright MICROSOFT Corp. 1986
;
;	Title:	MEMM - 386 EMM device driver
;
;	Module: CEM_MSG.INC - messages for ON/OFF/AUTO utility
;
;	Version: 0.02
;
;	Date:	June 7,1986
;
;	Author:
;
;******************************************************************************
;
;	Change Log:
;
;	DATE	 REVISION	Description
;	-------- --------	--------------------------------------------
;	06/07/86 Original
;	06/28/86 0.02		Name change from MEMM386 to MEMM
;
;******************************************************************************
;
not_there	db	"EMM386 driver not installed.",CR,LF,BEL,"$"

vmode		db	"EMM386 Active.",CR,LF,"$"

rmode		db	"EMM386 Inactive.",CR,LF,"$"

amode		db	"EMM386 in Auto mode.",CR,LF,"$"

verr_msg	db	"Unable to activate EMM386.",CR,LF,BEL,"$"

rerr		db	"Unable to inactivate EMM386.",CR,LF,BEL,"$"

aerr		db	"Unable to place EMM386 in Auto mode.",CR,LF,BEL,"$"

parmerr 	db	"Usage: EMM386 [ ON | OFF | AUTO]"
		db	CR,LF,BEL,"$"
