;-----------------------------------------------------------------------------+
;	SELECT.INC							      :
;									      :
;									      :
;  Dialog Equates							      :
;									      :
;  These values will eventually be defined by the dialog manager	      :
;									      :
;-----------------------------------------------------------------------------+
;
; Help ID equates
;
HCB_KEYS       EQU  1			     ;AN000;help on keys text
HCB_HELP       EQU  2			     ;AN000;help on help text
;
; Color ID equates
;
CLR_CLR        EQU  1			     ;AN000;shipped text mode color index
CLR_MON        EQU  2			     ;AN000;shipped monochrome color index
;
; Sound equates
;
SND_DURA       EQU  40000		     ;AN000;duration of error beep
SND_FREQ       EQU  440 		     ;AN000;frequency of error beep
;
; Size equates
;
MAX_MEMPAR     EQU  0F7FH		     ;AC091;SEH reduce area to 62K to help 256K mem problem;AN000;size of buffer in 16 byte paraghp (64KB)
MAX_MEMLVB     EQU  012BH		     ;AN000;size of buffer in 16 byte paraghp (4240 BYTES)
MAX_RETKSZ     EQU  50			     ;AN000;max # of bytes in return key buff
MAX_HELPSZ     EQU  2000H		     ;AN000;max # of bytes in help text buff (8KB)
MAX_PANNUM     EQU  98		   ;AC111;JW ;max num of panels possible in mem
MAX_SCRNUM     EQU  28		   ;AC111;JW ;max num of scroll possible in mem
MAX_CHDQUE     EQU  2			     ;AN000;max # of child queues to save
MAX_PANQUE     EQU  5			     ;AN000;max # of panel queues to save
MAX_NUMCHD     EQU  5			     ;AN000;max # of parent panels queued
MAX_NUMPAN     EQU  5			     ;AN000;max # of child panels queued
MAX_CLRECD     EQU  12			     ;AN000;num of bytes per PCPANEL color rc
;
; Keystroke equates
;
KEY_HELP       EQU  3B00H		     ;AN000;F1=Help
KEY_SWIT       EQU  3C00H		     ;AN000;F2=Switch
KEY_INDX       EQU  3F00H		     ;AN000;F5=Index
KEY_KEYS       EQU  4300H		     ;AN000;F9=Keys
KEY_SELT       EQU  000DH		     ;AN000;Enter
KEY_QUIT       EQU  001BH		     ;AN000;Esc=Quit
;
; Miscellaneous equates
;
VECSEGLEN      EQU  2			     ;AN000;vector segment length
VECOFFLEN      EQU  2			     ;AN000;vector offset length

	INCLUDE PCEQUATE.INC		     ;AN000;
