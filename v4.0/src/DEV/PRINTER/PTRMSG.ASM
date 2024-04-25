
	PAGE	,132

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  FILENAME:	  CPS Device Driver -- Message File
;;  MODULE NAME:  PTRMSG1
;;  TYPE:	  Message External File
;;  LINK PROCEDURE:  see CPSPMNN.ASM
;;
;;  INCLUDE FILES:
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					;;
					;;
CSEG	SEGMENT PUBLIC 'CODE'           ;;
	ASSUME	CS:CSEG 		;;
	ASSUME	DS:NOTHING		;;
					;;
PUBLIC	msg_no_init_p			;;
PUBLIC	msg_no_init			;;
PUBLIC	msg_bad_syntax			;;
PUBLIC	msg_insuff_mem			;;
					;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  ************************************
;;  **				      **
;;  **	     Resident Code	      **
;;  **				      **
;;  ************************************
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INCLUDE PTRMSG.INC

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CSEG	ENDS
	END
