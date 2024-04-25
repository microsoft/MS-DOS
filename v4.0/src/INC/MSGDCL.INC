; This Macro was removed from sysmsg.inc. We had to remove this
; macro and put it into it's own include file in order to clear up
; some assembly errors. MS MASM will not allow a public declaration
; during the second pass of the assembler. IBM MASM will allow this.
;
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;	$M_DECLARE	     Macro
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;
$M_DECLARE    macro	numcls	       ;
   $M_DCOUNT = 0		       ;
   REPT  numcls 		       ;
     $M_DCOUNT =  $M_DCOUNT + 1        ;
     $M_DECLARE2  %$M_DCOUNT	       ;
   ENDM 			       ;

  IF COMR
    IFNDEF $M_RT2			;  If Resident table is not in this assembly,
	EXTRN	$M_RT2:BYTE		;     Must be external
    ELSE
	PUBLIC	$M_RT2
    ENDIF				;
  ELSE
    IFNDEF $M_RT			;  If Resident table is not in this assembly,
	EXTRN	$M_RT:BYTE		;     Must be external
    ELSE
	PUBLIC	$M_RT
    ENDIF				;
  ENDIF

  $M_CHECK $M_GET_MSG_ADDRESS	      ;  If this subroutine is not in this assembly,
  $M_CHECK $M_MSGSERV_1 	      ;  If this subroutine is not in this assembly,
  $M_CHECK $M_MSGSERV_2 	      ;  If this subroutine is not in this assembly,

ENDM				       ;
				       ;
$M_DECLARE2   macro   innum	       ;
  IF NOT COMR			       ; IF Not resident COMMAND.COM
    IF NOT COMT 			 ; IF Not transient COMMAND.COM
      IFNDEF  $M_CLS_&innum		 ; IF class is not in this assembly,
	IF	FARmsg			 ;
	  EXTRN   $M_CLS_&innum:FAR	 ;    Must be external
	ELSE				 ;
	  EXTRN   $M_CLS_&innum:NEAR	 ;    Must be external
	ENDIF				 ;
      ELSE				 ; ELSE
	PUBLIC	$M_CLS_&innum		 ;    Label PUBLIC
      ENDIF				 ;
    ELSE				 ; ELSE
      IFDIF  <$M_CLS_&innum>,<$M_CLS_1>  ; IF NOT $M_CLS_1 or
	IFDIF <$M_CLS_&innum>,<$M_CLS_2> ;   IF NOT $M_CLS_2 then
	  IFNDEF  $M_CLS_&innum 	 ;     IF class is not in this assembly,
	    IF	    FARmsg		 ;
	      EXTRN   $M_CLS_&innum:FAR  ;	 Must be external
	    ELSE			 ;
	      EXTRN   $M_CLS_&innum:NEAR ;	 Must be external
	    ENDIF			 ;
	  ELSE				 ;     ELSE
	    PUBLIC  $M_CLS_&innum	 ;	 Label PUBLIC
	  ENDIF 			 ;
	ENDIF				 ;
      ENDIF				 ;
    ENDIF				 ;
  ELSE					 ; ELSE
    IFDIF  <$M_CLS_&innum>,<$M_CLS_1>	 ; IF NOT $M_CLS_1 or
      IFDIF <$M_CLS_&innum>,<$M_CLS_2>	 ;   IF NOT $M_CLS_2 then
	IFNDEF	$M_CLS_&innum		 ;     IF class is not in this assembly,
	  IF	  FARmsg		 ;
	    EXTRN   $M_CLS_&innum:FAR	 ;	 Must be external
	  ELSE				 ;
	    EXTRN   $M_CLS_&innum:NEAR	 ;	 Must be external
	  ENDIF 			 ;
	ELSE				 ;     ELSE
	  PUBLIC  $M_CLS_&innum 	 ;	 Label PUBLIC
	ENDIF				 ;
      ENDIF				 ;
    ENDIF				 ;
  ENDIF 			       ;
ENDM				       ;
				       ;
$M_CHECK      macro   parm	       ;
  IFNDEF  parm			       ; IF class is not in this assembly,
    IF	    FARmsg		       ;
      EXTRN   parm:FAR		       ;    Must be external
    ELSE			       ;
      EXTRN   parm:NEAR 	       ;    Must be external
    ENDIF			       ;
  ELSE
    IF COMR
    ELSE
      PUBLIC parm
    ENDIF
  ENDIF 			       ;
ENDM				       ;
				       ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;
IF1				       ;
  $M_DECLARE %$M_NUM_CLS	       ;  Declare any class not in this assembly
ENDIF				       ;
				       ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

