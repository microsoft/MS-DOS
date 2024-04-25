;0
page 80,132
;
title CP/DOS DOSGETMACHINEMODE mapper
;
dosxxx	segment byte public 'dos'
	assume	cs:dosxxx,ds:nothing,es:nothing,ss:nothing
;
;**********************************************************************
;*
;*   MODULE:   dosgetmachinemode
;*	Note that in PCDOS, this call should NOT BE ISSUED!
;*	This mapper does not return anything, it is meant
;*	only to allow the utility to link without errors.
;*
;*********************************************************************

	    public   dosgetmachinemode
	    .sall
	    .xlist
	    include  macros.inc
	    .list

str	    struc
modeaddr    dw	     ?
str	    ends

dosgetmachinemode proc	far
	Enter	DosGetMachMode	      ; push registers

	sub	ax,ax		      ; set good return code

	mexit			      ; pop registers
	ret	size str - 6	      ; return garbage (Not supported in PCDOS)

dosgetmachinemode endp

dosxxx	    ends

	    end
