;----------------------------------------------------------------------------
     ;DOS (C)Copyright 1988 Microsoft
     ;Licensed Material - Program Property of Microsoft
;----------------------------------------------------------------------------
PRINTER GRAPHICS,THERMAL    ;; 5152, 4201, 4202(8"), 5201-002(8"), 5202, 3812
			    ;; 4207, 4208, 5140

   ; Maximum Print width: 8"
   ; Horizontal BPI: 120    Vertical BPI: 72
   ; SETUP Statements contain the following escape sequences:
   ;   27,51,24 = set line spacing to 24/216
   ; GRAPHICS Statements use ESC "L" with the last two bytes being
   ;  the data count (low,high)

  DISPLAYMODE 4,5,13,19     ;; 320x200 > 6.7"x8.9" rotated
    SETup 27,51,24
    GRAPHICS 32,32,32,32,32,32,27,76,LOWCOUNT,HIGHCOUNT
    PRINTBOX STD,4,2,ROTATE
    PRINTBOX LCD,2,2,ROTATE

  DISPLAYMODE 6,14	   ;; 640x200 > 6.7"x8.9" rotated
    SETup 27,51,24
    GRAPHICS 32,32,32,32,32,32,27,76,LOWCOUNT,HIGHCOUNT
    PRINTBOX STD,4,1,ROTATE
    PRINTBOX LCD,2,1,ROTATE

  DISPLAYMODE 15,16	   ;; 640x350 > 5.8"x8.9" rotated
    SETup 27,51,24
    GRAPHICS 32,32,32,32,32,32,32,27,76,LOWCOUNT,HIGHCOUNT
    PRINTBOX STD,2,1,ROTATE
    PRINTBOX LCD	     ;; PC/Convertible doesn't support these modes

  DISPLAYMODE 17,18	   ;; 640x480 > 8"x8.9" rotated
    SETup 27,51,24
    GRAPHICS 27,76,LOWCOUNT,HIGHCOUNT
    PRINTBOX STD,2,1,ROTATE
    PRINTBOX LCD	     ;; PC/Convertible doesn't support these modes


;---------------------------------------------------------------------------
PRINTER COLOR8		     ;; 5182 CMY Ribbon

   ; Maximum Print width: 8"
   ; Horizontal BPI: 168 in 1:1 aspect ratio, 140 in 5:6 aspect ratio
   ; Vertical BPI: 84
   ; SETUP Statements contain the following escape sequences:
   ;   27,51,14 = set line spacing to 14/144
   ;   27,110,[0|1] = 0 sets aspect ratio to 5:6, 1 sets it to 1:1
   ; GRAPHICS Statements use ESC "L" with the last two bytes being
   ;  the data count (low,high)

  COLORSELECT Y,27,121	     ;; yellow band
  COLORSELECT M,27,109	     ;; magenta band
  COLORSELECT C,27,99	     ;; cyan band
  COLORSELECT B,27,98	     ;; black band
			     ;;
			     ;; Following RGB's represent the first 16
			     ;; screen colors.
			     ;; SCREEN COLOR	   PRINT COLOR
			     ;; ------------	   -----------
  COLORPRINT 0,0,0,B	     ;; BLACK		   BLACK
  COLORPRINT 0,0,42,C	     ;; BLUE		   CYAN
  COLORPRINT 0,42,0,Y,C      ;; GREEN		   GREEN
  COLORPRINT 0,42,42,C	     ;; CYAN		   CYAN
  COLORPRINT 42,0,0,Y,M      ;; RED		   RED
  COLORPRINT 42,0,42,C,M     ;; PURPLE		   PURPLE
  COLORPRINT 42,21,0,Y,C,M   ;; BROWN		   BROWN
  COLORPRINT 42,42,42	     ;; LOW WHITE	   WHITE (NOTHING)
  COLORPRINT 21,21,21,B      ;; GREY		   BLACK
  COLORPRINT 21,21,63,C      ;; HIGH BLUE	   CYAN
  COLORPRINT 21,63,21,Y,C    ;; HIGH GREEN	   GREEN
  COLORPRINT 21,63,63,C      ;; HIGH CYAN	   CYAN
  COLORPRINT 63,21,21,Y,M    ;; HIGH RED	   RED
  COLORPRINT 63,21,63,M      ;; MAGENTA 	   MAGENTA
  COLORPRINT 63,63,21,Y      ;; YELLOW		   YELLOW
  COLORPRINT 63,63,63	     ;; HIGH WHITE	   WHITE (NOTHING)

  COLORPRINT 42,42,0,Y	     ;; This statement maps the "yellow" in CGA
			     ;;  palette 0 to yellow
			     ;;
  DISPLAYMODE 4,5,13,19       ;; 320x200
    SETUP 27,51,14,27,110,0   ;; aspect ratio = 5:6
    GRAPHICS 32,32,32,32,27,76,LOWCOUNT,HIGHCOUNT
    PRINTBOX STD,4,2,ROTATE
  DISPLAYMODE 6,14	      ;; 640x200
     SETUP 27,51,14,27,110,0  ;; aspect ratio = 5:6
     GRAPHICS 32,32,32,32,27,76,LOWCOUNT,HIGHCOUNT
     PRINTBOX STD,4,1,ROTATE
  DISPLAYMODE 15,16	      ;; 640x350
     SETUP 27,51,14,27,110,1  ;; aspect ratio = 1:1
     GRAPHICS 32,32,32,32,27,76,LOWCOUNT,HIGHCOUNT
     PRINTBOX STD,3,1,ROTATE
  DISPLAYMODE 17,18	      ;; 640x480
     SETUP 27,51,14,27,110,1  ;; aspect ratio = 1:1
     GRAPHICS 32,32,32,32,27,76,LOWCOUNT,HIGHCOUNT
     PRINTBOX STD,2,1

;---------------------------------------------------------------------------
PRINTER COLOR4		     ;; 5182 RGB Ribbon

   ; Maximum Print width: 8"
   ; Horizontal BPI: 168 in 1:1 aspect ratio, 140 in 5:6 aspect ratio
   ; Vertical BPI: 84
   ; SETUP Statements contain the following escape sequences:
   ;   27,51,14 = set line spacing to 14/144
   ;   27,110,[0|1] = 0 sets aspect ratio to 5:6, 1 sets it to 1:1
   ; GRAPHICS Statements use ESC "L" with the last two bytes being
   ;  the data count (low,high)

  COLORSELECT R,27,121	     ;; red band
  COLORSELECT G,27,109	     ;; green band
  COLORSELECT B,27,99	     ;; blue band
  COLORSELECT X,27,98	     ;; black band
			     ;;
			     ;; Following RGB's represent the first 16
			     ;; screen colors.
			     ;; SCREEN COLOR	   PRINT COLOR
			     ;; ------------	   -----------
  COLORPRINT 0,0,0,X	     ;; BLACK		   BLACK
  COLORPRINT 0,0,42,B	     ;; BLUE		   BLUE
  COLORPRINT 0,42,0,G	     ;; GREEN		   GREEN
  COLORPRINT 0,42,42,B	     ;; CYAN		   BLUE
  COLORPRINT 42,0,0,R	     ;; RED		   RED
  COLORPRINT 42,0,42,R	     ;; PURPLE		   RED
  COLORPRINT 42,21,0,X	     ;; BROWN		   BLACK
  COLORPRINT 42,42,42	     ;; LOW WHITE	   WHITE (NOTHING)
  COLORPRINT 21,21,21,X      ;; GREY		   BLACK
  COLORPRINT 21,21,63,B      ;; HIGH BLUE	   BLUE
  COLORPRINT 21,63,21,G      ;; HIGH GREEN	   GREEN
  COLORPRINT 21,63,63,B      ;; HIGH CYAN	   BLUE
  COLORPRINT 63,21,21,R      ;; HIGH RED	   RED
  COLORPRINT 63,21,63,R      ;; MAGENTA 	   RED
  COLORPRINT 63,63,21	     ;; YELLOW		   WHITE (NOTHING)
  COLORPRINT 63,63,63	     ;; HIGH WHITE	   WHITE (NOTHING)

  COLORPRINT 42,42,0,B	     ;; This statement maps the "yellow" in CGA
			     ;;  palette 0 to blue as was done in
			     ;;   versions of GRAPHICS
			     ;;
  DISPLAYMODE 4,5,13,19       ;; 320x200
    SETUP 27,51,14,27,110,0   ;; aspect ratio = 5:6
    GRAPHICS 32,32,32,32,27,76,LOWCOUNT,HIGHCOUNT
    PRINTBOX STD,4,2,ROTATE
  DISPLAYMODE 6,14	      ;; 640x200
     SETUP 27,51,14,27,110,0  ;; aspect ratio = 5:6
     GRAPHICS 32,32,32,32,27,76,LOWCOUNT,HIGHCOUNT
     PRINTBOX STD,4,1,ROTATE
  DISPLAYMODE 15,16	      ;; 640x350
     SETUP 27,51,14,27,110,1  ;; aspect ratio = 1:1
     GRAPHICS 32,32,32,32,27,76,LOWCOUNT,HIGHCOUNT
     PRINTBOX STD,3,1,ROTATE
  DISPLAYMODE 17,18	      ;; 640x480
     SETUP 27,51,14,27,110,1  ;; aspect ratio = 1:1
     GRAPHICS 32,32,32,32,27,76,LOWCOUNT,HIGHCOUNT
     PRINTBOX STD,2,1

;---------------------------------------------------------------------------
PRINTER GRAPHICSWIDE   ;; 4202(13.5"), 5201-002(13.5")

   ; Maximum Print width: 13.5"
   ; Horizontal BPI: 120    Vertical BPI: 72
   ; SETUP Statements contain the following escape sequences:
   ;   27,88,1,255 = enable 13.5" printing
   ;   27,51,24 = set line spacing to 24/216
   ;   27,51,18 = set line spacing to 18/216 (320x200 MODES ONLY!!)
   ; GRAPHICS Statements use ESC "L" with the last two bytes being
   ;  the data count (low,high)

  DISPLAYMODE 4,5,13,19     ;; 320x200	> 10.7"x8.3" non-rotated
    SETup 27,88,1,255,27,51,18
    GRAPHICS 27,76,LOWCOUNT,HIGHCOUNT
    PRINTBOX STD,4,3

  DISPLAYMODE 6,14	    ;; 640x200 - same as for 8" printing
    SETup 27,88,1,255,27,51,24
    GRAPHICS 27,76,LOWCOUNT,HIGHCOUNT
    PRINTBOX STD,4,1,ROTATE

  DISPLAYMODE 15,16	    ;; 640x350 > 11.7"x17.8" rotated
    SETup 27,88,1,255,27,51,24
    GRAPHICS 27,76,LOWCOUNT,HIGHCOUNT
    PRINTBOX STD,4,2,ROTATE

  DISPLAYMODE 17,18	    ;; 640x480 > 12"x17.8" rotated
    SETup 27,88,1,255,27,51,24
    GRAPHICS 27,76,LOWCOUNT,HIGHCOUNT
    PRINTBOX STD,3,2,ROTATE

;---------------------------------------------------------------------------
PRINTER COLOR1		       ;; 5182 with black ribbon

   ; Maximum Print width: 8"
   ; Horizontal BPI: 168 in 1:1 aspect ratio, 140 in 5:6 aspect ratio
   ; Vertical BPI: 84
   ; SETUP Statements contain the following escape sequences:
   ;   27,51,14 = set line spacing to 14/144
   ;   27,110,[0|1] = 0 sets aspect ratio to 5:6, 1 sets it to 1:1
   ; GRAPHICS Statements use ESC "L" with the last two bytes being
   ;  the data count (low,high)

  DARKADJUST 0		      ; Code a positive number to lighten
			      ;  printing. Suggested value = 10

  DISPLAYMODE 4,5,13,19       ;; 320x200
    SETUP 27,51,14,27,110,0   ;; aspect ratio = 5:6
    GRAPHICS 32,32,32,32,32,32,27,76,LOWCOUNT,HIGHCOUNT
    PRINTBOX STD,4,2,ROTATE
    PRINTBOX LCD,2,2,ROTATE

  DISPLAYMODE 6,14	      ;; 640x200
    SETUP 27,51,14,27,110,0  ;; aspect ratio = 5:6
    GRAPHICS 32,32,32,32,32,32,27,76,LOWCOUNT,HIGHCOUNT
    PRINTBOX STD,4,1,ROTATE
    PRINTBOX LCD,2,1,ROTATE

  DISPLAYMODE 15,16	      ;; 640x350
     SETUP 27,51,14,27,110,1  ;; aspect ratio = 1:1
     GRAPHICS 32,32,32,32,32,27,76,LOWCOUNT,HIGHCOUNT
     PRINTBOX STD,3,1,ROTATE
     PRINTBOX LCD	      ;; PC/Convertible doesn't support these modes

  DISPLAYMODE 17,18	      ;; 640x480
     SETUP 27,51,14,27,110,1  ;; aspect ratio = 1:1
     GRAPHICS 32,32,32,32,27,76,LOWCOUNT,HIGHCOUNT
     PRINTBOX STD,2,1
     PRINTBOX LCD	      ;; PC/Convertible doesn't support these modes


;===========================================================================
;			    End of Profile
;===========================================================================
