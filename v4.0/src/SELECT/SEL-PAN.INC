;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;	SEL-PAN.INC
;
;
FALSE = 0

;
;  Dialog Equates
;
;  These values will eventually be defined by the dialog.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.XLIST				;AN000;
LEFT_COL	EQU	8	;AN000;
SCR_CONT       EQU  1		;AN000;contextual helps
SCR_INDX       EQU  2		;AN000;indexed helps
SCR_MAIN       EQU  3		;AN000;main menu
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Help ID equates
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
HCB_KEYS       EQU  1		;AN000;help on keys text
HCB_HELP       EQU  2		;AN000;help on help text
HCB_MAIN       EQU  3		;AN000;main menu help text
HCB_SAMP       EQU  4		;AN000;sample application help text
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Color index record equates
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
WHITE_BLUE	EQU	1	;AN000;
BLACK_WHITE	EQU	4	;AN000;
WHITE_RED	EQU	5	;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Color ID equates
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CLR_CLR 	EQU  1		;AN000;shipped text mode color index
CLR_MON 	EQU  2		;AN000;shipped monochrome color index
CLR_USE 	EQU  3		;AN000;user color index
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Sound equates
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SND_DURA	EQU  10000	;AN000;duration of error beep
SND_FREQ	EQU  440	;AN000;frequency of error beep
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Size equates
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
MAX_MEMPAR	EQU  4000	;AN000;size of buffer in 16 byte paraghp
MAX_RETKSZ	EQU  512	;AN000;max # of bytes in return key buff
MAX_HELPSZ	EQU  5000	;AN000;max # of bytes in help text buff
MAX_PANNUM	EQU  98 	;AN000;max num of panels possible in mem
MAX_SCRNUM	EQU  28 	;AN000;max num of scroll possible in mem
MAX_CHDQUE	EQU  5		;AN000;max # of child queues to save
MAX_PANQUE	EQU  4		;AN000;max # of panel queues to save
MAX_NUMCHD	EQU  11 	;AN000;max # of parent panels queued
MAX_NUMPAN	EQU  10 	;AN000;max # of child panels queued
MAX_CLRECD	EQU  12 	;AN000;num of bytes per PCPANEL color rc
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Keystroke equates
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
KEY_HELP	EQU  3B00H	;AN000;F1=Help
KEY_SWIT	EQU  3C00H	;AN000;F2=Switch
KEY_INDX	EQU  3F00H	;AN000;F5=Index
KEY_KEYS	EQU  4000H	;AN000;F7=Keys
KEY_SELT	EQU  000DH	;AN000;Enter
KEY_QUIT	EQU  001BH	;AN000;Esc=Quit
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; PCPANWR equates
;
;
; PCPANWR option bit equates (PWR_OPT1)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PWR_WRITEONE   EQU  0000000000000001B	     ;AN000;write pan specified by PWR_ID
PWR_WRITEALL   EQU  0000000000000010B	     ;AN000;write all pans to specified file
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; PCPANWR error bit equates (PWR_ERROR)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PWR_BUFSIZE    EQU  0000000000000001B	     ;AN000;buffer size is too small
PWR_NOPANELS   EQU  0000000000000010B	     ;AN000;file does not contain panels
PWR_NOTCASFILE EQU  0000000000000100B	     ;AN000;CAS file obj list does not exist
PWR_PANELSFULL EQU  0000000000001000B	     ;AN000;panel vector is full
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; PCPANEL equates
;
;
; PCPANEL option bit equates (PM_OPT1)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PM_RF	       EQU  0000000000000001B	     ;AN000;do not refresh display
PM_SRF	       EQU  0000000000000010B	     ;AN000;selective PVB refresh from LVB
PM_BK	       EQU  0000000000000100B	     ;AN000;panel break function active
PM_CL	       EQU  0000000000001000B	     ;AN000;initialize LVB to base char/attr
PM_DOA	       EQU  0000000000010000B	     ;AN000;display childs in active parent
PM_DOV	       EQU  0000000000100000B	     ;AN000;use child row, col, color overrid
PM_DOQ	       EQU  0000000001000000B	     ;AN000;disp all child in parent chd tabl
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; PCPANEL error equates for (PM_ERROR)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PM_PANPDQ      EQU  0000000000000001B	     ;AN000;invalid parent PDQ or start num
PM_PCBVEC      EQU  0000000000000010B	     ;AN000;invalid PCB vector entry found
PM_UNKNPANS    EQU  0000000000000100B	     ;AN000;unknown panel source found
PM_CHDTAB      EQU  0000000000001000B	     ;AN000;set error with child table
PM_COLORX      EQU  0000000000010000B	     ;AN000;panel's color index out of range
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; PCPANEL Parent and Child Display Queue option bit equates (PT_OPT)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PT_BK	       EQU  0000000000000001B	     ;AN000;panel break on
PT_SRF	       EQU  0000000000000010B	     ;AN000;selective refresh of panel to PVB
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; PCPANEL Panel Control Block option equates for individual panels (PCB_OPT1)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PCB_CRE        EQU  0000000000000001B	     ;AN000;Create panel from scratch
PCB_CMP        EQU  0000000000000010B	     ;AN000;Use compress text form in memory
PCB_EXP        EQU  0000000000000100B	     ;AN000;Use expanded text form in memory
PCB_MXP        EQU  0000000000001000B	     ;AN000;Use mixed text/attr form in memoy
PCB_LB	       EQU  0000000000010000B	     ;AN000;Use logical border
PCB_ASZ        EQU  0000000000100000B	     ;AN000;Allow sizing of panel
PCB_ASC        EQU  0000000001000000B	     ;AN000;Allow scrolling of panel
PCB_LAB        EQU  0000000010000000B	     ;AN000;Use the defined panel label
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; PCPANEL Child information table option equates (CHILD_OPT)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CHD_ABS        EQU  0000000000000001B	     ;AN000;calc child pan pos from scr corne
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; PCCLRWR equates
;
; PCCLRWR error bit equates (CWR_ERROR)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CWR_BUFSIZE    EQU  0000000000000001B	     ;AN000;buffer size is too small
CWR_NOCOLORS   EQU  0000000000000010B	     ;AN000;file does not contain colors
CWR_NOTCASFILE EQU  0000000000000100B	     ;AN000;file object list does not exist
CWR_COLORSFULL EQU  0000000000001000B	     ;AN000;color vector is full
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; PCSCRWR equates
;
;
; PCSCRWR option bit equates (SWR_OPT1)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SWR_WRITEONE   EQU  0000000000000001B	     ;AN000;write pan specified by SWR_ID
SWR_WRITEALL   EQU  0000000000000010B	     ;AN000;write all pans to specified file
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; PCSCRWR error bit equates (SWR_ERROR)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SWR_BUFSIZE    EQU  0000000000000001B	     ;AN000;buffer size is too small
SWR_NOFIELDS   EQU  0000000000000010B	     ;AN000;file does not contain fields
SWR_NOTCASFILE EQU  0000000000000100B	     ;AN000;file object list does not exist
SWR_FIELDSFULL EQU  0000000000001000B	     ;AN000;field vector is full
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; PCSTRST equates
;
; PCSTRST equates
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SSC_TBSL       EQU  0000000000000001B	     ;AN000;use two byte string length
SSC_PTSB       EQU  0000000000000010B	     ;AN000;pointer points to string buffer
SSC_VTSAO      EQU  0000000000000100B	     ;AN000;vector table is string addr only
SSC_VTASO      EQU  0000000000001000B	     ;AN000;vector table addr is seg:offset
SSC_SLSB       EQU  0000000000010000B	     ;AN000;string length is in string buffer
SSC_SBTC       EQU  0000000000100000B	     ;AN000;string buffer has term. character
SSC_VTE        EQU  1			     ;AN000;error in vector table
SSC_SBE        EQU  2			     ;AN000;error in sting buffer
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; PCSLCTP equates
;
; PCSLCTP Option word one (SCB_OPT1)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SCB_UC	       EQU  0000000000000001B	     ;AN000;upper case option
SCB_WRAP       EQU  0000000000000010B	     ;AN000;wrap option
SCB_FRBF       EQU  0000000000000100B	     ;AN000;force return before first option
SCB_FRAL       EQU  0000000000001000B	     ;AN000;force return after last option
SCB_LL	       EQU  0000000000010000B	     ;AN000;lock line
SCB_UKS        EQU  0000000000100000B	     ;AN000;use keystroke
SCB_RD	       EQU  0000000001000000B	     ;AN000;return after display option
SCB_RUK        EQU  0000000010000000B	     ;AN000;return unused keys option
SCB_UI	       EQU  0000000100000000B	     ;AN000;use index option
SCB_TRN        EQU  0000001000000000B	     ;AN000;translate character
SCB_MON        EQU  0000010000000000B	     ;AN000;convert to upper case monocasing
SCB_DBCS       EQU  0000100000000000B	     ;AN000;check for double byte chars
SCB_TBL        EQU  0001000000000000B	     ;AN000;use given DBCS range table
SCB_DCHECK     EQU  0010000000000000B	     ;AN000;display check mark characters
SCB_DACTIVE    EQU  0100000000000000B	     ;AN000;display active string indicators
SCB_DPOINT     EQU  1000000000000000B	     ;AN000;display selection pointer string
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; PCSLCTP Option word two (SCB_OPT2)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SCB_CS	       EQU  0000000000000001B	     ;AN000;clear screen on entry option
SCB_ROTN       EQU  0000000000000010B	     ;AN000;reset option to normal on return
SCB_UET        EQU  0000000000000100B	     ;AN000;use existing text option
SCB_CFO        EQU  0000000000001000B	     ;AN000;cursor follows option
SCB_LCOX       EQU  0000000000010000B	     ;AN000;leave cursor on exit
SCB_IPAGE      EQU  0000000000100000B	     ;AN000;instant paging
SCB_PM1        EQU  0000000001000000B	     ;AN000;paging is minus one line
SCB_UIND       EQU  0000000010000000B	     ;AN000;display up, dn, lf, rg indicators
SCB_UNCA       EQU  0000000100000000B	     ;AN000;use normal color array
SCB_DYN        EQU  0000001000000000B	     ;AN000;option array is dynamicly created
SCB_LANDR      EQU  0000010000000000B	     ;AN000;left and right scrolling active
SCB_CPHY       EQU  0000100000000000B	     ;AN000;color array is physical attributs
SCB_NUML       EQU  0001000000000000B	     ;AN000;generate num list in opt strings
SCB_SKIP       EQU  0010000000000000B	     ;AN000;skip inactive option strings
SCB_SHIGH      EQU  0100000000000000B	     ;AN000;highlight the selected opt strgs
SCB_AHIGH      EQU  1000000000000000B	     ;AN000;highlight the active option strgs
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; PCSLCTP Option word three (SCB_OPT3)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SCB_SELACT     EQU  0000000000000001B	     ;AN000;allow selection of inactive elem
SCB_SELEXC     EQU  0000000000000010B	     ;AN000;exclusive selection of one elemet
SCB_EXCSING    EQU  0000000000000100B	     ;AN000;one element is always selected
SCB_NUMUIND    EQU  0000000000001000B	     ;AN000;display line number count
SCB_CHIGH      EQU  0000000000010000B	     ;AN000;hilight cursored and selected stg
SCB_NUMS       EQU  0000000000100000B	     ;AN000;auto 0-9 number selection
SCB_FINDE      EQU  0000000001000000B	     ;AN000;auto character search
SCB_RELUIND    EQU  0000000010000000B	     ;AN000;rel row/col used w/dirct indicato
SCB_RELSCR     EQU  0000000100000000B	     ;AN000;rel row/col used w/scroll field
SCB_LVBOVR     EQU  0000001000000000B	     ;AN000;use video buffer seg:off override
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; PCSLCTP Select Array Option (SCB_SELSEG:SCB_SELOFF)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SCB_SELECTON   EQU  0000000000000001B	     ;AN000;element selected
SCB_ACTIVEON   EQU  0000000000000010B	     ;AN000;element active
SCB_SKIPON     EQU  0000000000000100B	     ;AN000;element should be skipped
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; PCHLPWR equates
;
; PCHLPWR option bit equates (HWR_OPT1)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
HWR_REPLACE    EQU  0000000000000001B	      ;AN000;Replace existing help text/topic
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; PCHLPWR error bit equates (HWR_ERROR)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
HWR_BUFSIZE    EQU  0000000000000001B	      ;AN000;buffer size is too small
HWR_HELPUSED   EQU  0000000000000010B	      ;AN000;help ID already in use
HWR_INVALDID   EQU  0000000000000100B	      ;AN000;help ID is out of range
HWR_NOHLPOBJ   EQU  0000000000001000B	      ;AN000;no help object
HWR_NOTCASFILE EQU  0000000000010000B	      ;AN000;not a valid cas file
HWR_HELPSFULL  EQU  0000000000100000B	      ;AN000;help vector is full
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Internal equates
;
; internal equates
;
;;;;;;;;;;;;;;;;;;;;;;;;;
UPARROW EQU	72	;AN000;up arrow
DNARROW EQU	80	;AN000;down arrow
LFARROW EQU	75	;AN000;left arrow
RTARROW EQU	77	;AN000;right arrow
PGUP	EQU	73	;AN000;
PGDN	EQU	81	;AN000;
ESCAPE	EQU	27	;AN000;
ENTER	EQU	13	;AN000;
SPACE	EQU	32	;AN000;
F1	EQU	59	;AN000;
F2	EQU	60	;AN000;
F3	EQU	61	;AN000;
F4	EQU	62	;AN000;
F5	EQU	63	;AN000;
F6	EQU	64	;AN000;
F7	EQU	65	;AN000;
F8	EQU	66	;AN000;
F9	EQU	67	;AN000;
F10	EQU	68	;AN000;
.LIST			;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;
