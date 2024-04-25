


	PAGE	,132
	TITLE	DOS Keyboard Definition File

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; DOS - NLS Support - Keyboard Definition File
;; (c) Copyright 1988 Microsoft
;;
;; This file contains the eof marker for the entire table
;; and the keyboard.sys copyright 
;;
;; Linkage Instructions:
;;	Refer to KDF.ASM.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				       ;;
				       ;;
CODE	SEGMENT PUBLIC 'CODE'          ;;
	ASSUME CS:CODE,DS:CODE	       ;;
				       ;;
				       ;;
				       ;;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
include copyrigh.inc
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	DB  1AH 		       ;; EOF
				       ;;
CODE	ENDS			       ;;
	END			       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
