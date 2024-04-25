						  ;;Rev 3.30 Modification
;
; given a label <lbl> either 2 byte jump to another label <lbl>_J
; if it is near enough or 3 byte jump to <lbl>
;

jump	macro lbl
	local a
.xcref

	ifndef lbl&_j			;; is this the first invocation
a:
				JMP lbl
	ELSE
	    IF (lbl&_J GE $) OR ($-lbl&_J GT 126)
a:
				JMP lbl ;; is the jump too far away?
	    ELSE
a:
			       JMP lbl&_J  ;; do the short one...
	    ENDIF
	ENDIF
lbl&_j = a
.cref
	endm
.xcref	jump
;REDEFINE THE ABOVE MACRO TO ALWAYS TRY A 3 BYTE NEAR JUMP		 
JUMP MACRO LBL								 
					JMP LBL 			 
	ENDM					;;End of Modification
