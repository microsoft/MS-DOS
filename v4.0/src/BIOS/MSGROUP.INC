EVBOUND = 1  ;THIS VALUE BEING 0 DOES NO BOUNDARY ALLIGNMENT, VALUE 1	  ;3.30
	     ; ALIGNS TO EVEN						  ;3.30
; : : : : : : : : : : : : : :						  ;3.30
	IF EVBOUND	;;IF EVEN (WORD) ALLIGNMENT IS REQUESTED,	  ;3.30
; : : : : : : : : : : : : : :						  ;3.30
EVENB	MACRO								  ;3.30
	  EVEN	;;ADJUST TO EVEN BOUNDARY				  ;3.30
	ENDM								  ;3.30
									  ;3.30
ODD	MACRO								  ;3.30
;;GENERATE BOUNDARY PADDING TO FORCE ODD OFFSET 			  ;3.30
	IF (($-CODE) MOD 2) EQ 0					  ;3.30
	  DB	?							  ;3.30
	ENDIF								  ;3.30
	ENDM								  ;3.30
									  ;3.30
CODE_SEGMENT MACRO							  ;3.30
;;ALLIGN THE SEGMENT ON WORD BOUNDARY TO ALLOW FOR EVEN ALLIGNMENT OF DATA;3.30
CODE	SEGMENT WORD PUBLIC 'CODE'                                        ;3.30 ;3.30
	ENDM								  ;3.30
									  ;3.30
; : : : : : : : : : : : : : :						  ;3.30
	ELSE	;;SINCE EVEN ALLIGNMENT IS NOT DESIRED, JUST USE BYTE ALLI;3.30 GNMENT
; : : : : : : : : : : : : : :						  ;3.30
									  ;3.30
EVENB	MACRO								  ;3.30
;;REQUEST FOR WORD ALLIGNMENT DOES NOTHING				  ;3.30
	ENDM								  ;3.30
									  ;3.30
ODD	MACRO								  ;3.30
;;REQUEST FOR ODD ALLIGNMENT DOES NOTHING				  ;3.30
	ENDM								  ;3.30
									  ;3.30
CODE_SEGMENT MACRO							  ;3.30
;;SEGMENT IS ALLIGNED ON BYTE BOUNDARY FOR MINIMUM SIZE OF GENERATION	  ;3.30
CODE	SEGMENT BYTE PUBLIC 'CODE'                                        ;3.30
	ENDM								  ;3.30
									  ;3.30
; : : : : : : : : : : : : : :						  ;3.30
	ENDIF								  ;3.30
; : : : : : : : : : : : : : :						  ;3.30
									  ;3.30
	CODE_SEGMENT							  ;3.30
	ASSUME	CS:CODE 						  ;3.30
									  ;3.30
