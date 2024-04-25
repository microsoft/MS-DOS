;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; PCSCRRD option bit equates (SRD_OPT1)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SRD_INITIAL    EQU  0000000000000001B	     ;AN000;initialize SCB and filespec buff
SRD_READONE    EQU  0000000000000010B	     ;AN000;read field specified by SRD_ID
SRD_APPEND     EQU  0000000000000100B	     ;AN000;match field ID are issued new ID
SRD_READALL    EQU  0000000000001000B	     ;AN000;read all FLDS in specified file
SRD_ALLOCRES   EQU  0000000000010000B	     ;AN000;allocate reserved PCSLCTP space
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; PCSCRRD error bit equates (SRD_ERROR)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SRD_BUFSIZE    EQU  0000000000000001B	     ;AN000;buffer size is too small
SRD_NOFIELDS   EQU  0000000000000010B	     ;AN000;file does not contain fields
SRD_NOTCASFILE EQU  0000000000000100B	     ;AN000;file object list does not exist
SRD_FIELDSFULL EQU  0000000000001000B	     ;AN000;max num FLDS read into SCB vect
SRD_NOINITIAL  EQU  0000000000010000B	     ;AN000;make initialize call first
SRD_NOFIELDID  EQU  0000000000100000B	     ;AN000;specified field ID not found
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; PCHLPRD option bit equates (HRD_OPT1)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
HRD_TOPIC      EQU  0000000000000001B	      ;AN000;process help TOPIC(S) index
HRD_TEXT       EQU  0000000000000010B	      ;AN000;process HELP or ERROR text
HRD_DISPID     EQU  0000000000000100B	      ;AN000;display unique id on topic list
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; PCHLPRD error bit equates (HRD_ERROR)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
HRD_BUFSIZE    EQU  0000000000000001B	      ;AN000;buffer size is too small
HRD_NOHLPOBJ   EQU  0000000000000010B	      ;AN000;file does not contain helps
HRD_NOOBJLST   EQU  0000000000000100B	      ;AN000;file object list does not exist
HRD_NOHELPID   EQU  0000000000001000B	      ;AN000;requested id was not found
HRD_NOTCASFILE EQU  0000000000010000B	      ;AN000;not a valid cas file
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
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
SSC_SBE        EQU  2			     ;AN000;error in string buffer
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
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
SCB_FM	       EQU  0000010000000000B	     ;AN000;make call to dynamic format rout
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
; PCINCHA option equates (INC_OPT)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
INC_KWAIT      EQU  0000000000000001B	     ;keystroke
INC_UTRAN      EQU  0000000000000010B	     ;translate keys using user table
INC_UDBCS      EQU  0000000000000100B	     ;DBCS processed using user table
INC_DDBCS      EQU  0000000000001000B	     ;DBCS processed using DOS table
INC_UMONO      EQU  0000000000010000B	     ;monocase keys using user table
INC_AMONO      EQU  0000000000100000B	     ;monocase keys using USA algorithm
INC_RSCAN      EQU  0000000001000000B	     ;return scan codes for norm chars
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; PCINCHA option equates (INC_STAT)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
INC_KFND       EQU  0000000000000001B	     ;AN000;character found in buffer
INC_DBCS       EQU  0000000000000010B	     ;AN000;character found is double byte
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; PCCLRRD error bit equates (CRD_ERROR)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CRD_BUFSIZE	EQU  0000000000000001B	     ;AN000;buffer size is too small
CRD_NOCOLORS	EQU  0000000000000010B	     ;AN000;file does not contain colors
CRD_NOTCASFILE	EQU  0000000000000100B	     ;AN000;file object list does not exist
CRD_IDNOTFOUND	EQU  0000000000001000B	     ;AN000;color index ID not found
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; PCPANRD option bit equates (PRD_OPT1)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PRD_INITIAL    EQU  0000000000000001B	     ;AN000;initialize PCB and filespec buff
PRD_READONE    EQU  0000000000000010B	     ;AN000;read pan specified by PRD_ID
PRD_APPEND     EQU  0000000000000100B	     ;AN000;match pans ID are issued new ID
PRD_READALL    EQU  0000000000001000B	     ;AN000;read all pans in specified file
PRD_SIZEMALL   EQU  0000000000010000B	     ;AN000;reserve space for panel sizing
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; PCPANRD error bit equates (PRD_ERROR)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PRD_BUFSIZE    EQU  0000000000000001B	     ;AN000;buffer size is too small
PRD_NOPANELS   EQU  0000000000000010B	     ;AN000;file does not contain panels
PRD_NOTCASFILE EQU  0000000000000100B	     ;AN000;file object list does not exist
PRD_PANELSFULL EQU  0000000000001000B	     ;AN000;max num pans read into PCB vect
PRD_NOINITIAL  EQU  0000000000010000B	     ;AN000;make initialize call first
PRD_NOPANELID  EQU  0000000000100000B	     ;AN000;specified panel ID not found
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; PCDISPQ option equates (QM_OPT1)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
QM_INIT        EQU  0000000000000001B	     ;AN000;Initialize working buffer
QM_PUSHCHD     EQU  0000000000000010B	     ;AN000;Add child number
QM_RVMCHD      EQU  0000000000000100B	     ;AN000;Remove specific child number
QM_POPCHD      EQU  0000000000001000B	     ;AN000;Pop (n) number of child cur queue
QM_PUSHPAN     EQU  0000000000010000B	     ;AN000;Add panel number
QM_RVMPAN      EQU  0000000000100000B	     ;AN000;Remove specific panel number
QM_POPPAN      EQU  0000000001000000B	     ;AN000;Pop (n) number of panls cur queue
QM_PUSHCQU     EQU  0000000010000000B	     ;AN000;Push current child queue
QM_POPCQU      EQU  0000000100000000B	     ;AN000;Pop last child queue
QM_PUSHPQU     EQU  0000001000000000B	     ;AN000;Push current panel queue
QM_POPPQU      EQU  0000010000000000B	     ;AN000;Pop last panel queue pushed
QM_CLSCHD      EQU  0000100000000000B	     ;AN000;Clear current child queue.
QM_CLSPAN      EQU  0001000000000000B	     ;AN000;Clear current panel queue.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; PCDISPQ option equates (QM_OPT2)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
QM_BREAKON     EQU  0000000000000001B	     ;AN000;break option is on
QM_BREAKOFF    EQU  0000000000000010B	     ;AN000;break option is off
QM_SRFON       EQU  0000000000000100B	     ;AN000;selected refresh option is on
QM_SRFOFF      EQU  0000000000001000B	     ;AN000;selected refresh option is off
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; PCDISPQ error equates (QM_ERROR)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
QM_ERRMP       EQU  0000000000000001B	     ;AN000;max number of panels added
QM_ERRMC       EQU  0000000000000010B	     ;AN000;max number of childs added
QM_ERRMPQ      EQU  0000000000000100B	     ;AN000;max number of panel queues pushed
QM_ERRMCQ      EQU  0000000000001000B	     ;AN000;max number of child queues pushed
QM_ERROP       EQU  0000000000010000B	     ;AN000;max number of panel queues popped
QM_ERROC       EQU  0000000000100000B	     ;AN000;max number of child queues popped
QM_ERRBU       EQU  0000000001000000B	     ;AN000;inadequate buffer size avail
QM_ERRPN       EQU  0000000010000000B	     ;AN000;specified panel not found
QM_ERRCN       EQU  0000000100000000B	     ;AN000;specified child not found
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
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
PCB_DTB        EQU  0000000100000000B	     ;AN000;Draw top border (graphics only)
PCB_DBB        EQU  0000001000000000B	     ;AN000;Draw bottom border (graphic only)
PCB_DLB        EQU  0000010000000000B	     ;AN000;Draw left border (graphics only)
PCB_DRB        EQU  0000100000000000B	     ;AN000;Draw right border (graphics only)
PCB_DSHADOW    EQU  0001000000000000B	     ;AN000;Draw shadow (graphics only)
PCB_PELCOORD   EQU  0010000000000000B	     ;AN000;row/col in pel coordinates (grap)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; PCINSTR option bit equates (INS_OPT)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
INS_FKS        EQU  0000000000000001B	     ;AN000;find keystroke
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; PCGVIDO Status equates (GV_STAT1)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
GV_TV	       EQU  0000000000000001B	     ;AN000;TopView is present
GV_CGA	       EQU  0000000000000010B	     ;AN000;CGA is present
GV_EGA	       EQU  0000000000000100B	     ;AN000;EGA is present
GV_PGA	       EQU  0000000000001000B	     ;AN000;PGA is present
GV_MGA	       EQU  0000000000010000B	     ;AN000;MGA is present
GV_EGAA        EQU  0000000000100000B	     ;AN000;EGA is active card
GV_CGAA        EQU  0000000001000000B	     ;AN000;CGA is active card
GV_EGACM       EQU  0000000010000000B	     ;AN000;EGA is set to monochrome
GV_PGAEM       EQU  0000000100000000B	     ;AN000;PGA is in color emulation mode
GV_HS	       EQU  0000001000000000B	     ;AN000;display requires sync check 1=Y
GV_64K	       EQU  0000010000000000B	     ;AN000; 64K memory on EGA card
GV_128K        EQU  0000100000000000B	     ;AN000;128K memory on EGA card
GV_192K        EQU  0001000000000000B	     ;AN000;192K memory on EGA card
GV_256K        EQU  0010000000000000B	     ;AN000;256K memory on EGA card
GV_UM	       EQU  0100000000000000B	     ;AN000;error unknown moniter or config
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; PCGVIDO Status equates (GV_STAT2)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
GV_TVW	       EQU  0000000000000001B	     ;AN000;App is 'well behaved' under TV
GV_P5140       EQU  0000000000000010B	     ;AN000;P12 with LCD
GV_P5153       EQU  0000000000000100B	     ;AN000;P12 with color
GV_P5151       EQU  0000000000001000B	     ;AN000;P12 with monochrome
GV_COLOR       EQU  0000000000010000B	     ;AN000;color mode
GV_TEXTGRAPH   EQU  0000000000100000B	     ;AN000;graphics mode
GV_MONOP       EQU  0000000001000000B	     ;AN000;monochrome adapter is primary
GV_CGAP        EQU  0000000010000000B	     ;AN000;CGA adapter is primary card
GV_EGAP        EQU  0000000100000000B	     ;AN000;EGA adapter is primary card
GV_TURBOP      EQU  0000001000000000B	     ;AN000;Turbo graphics adapter is primary
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; PCINPUT option equates.
;
;
; PCINPUT Option equates (IN_OPT)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
IN_UTRAN       EQU  0000000000000001B	     ;AN000;translate keys using user table
IN_ADBCS       EQU  0000000000000010B	     ;AN000;DBCS option active
IN_UDBCS       EQU  0000000000000100B	     ;AN000;DBCS processed using user table
IN_DDBCS       EQU  0000000000001000B	     ;AN000;DBCS processed using DOS table
IN_UMONO       EQU  0000000000010000B	     ;AN000;monocase keys using user table
IN_AMONO       EQU  0000000000100000B	     ;AN000;monocase keys using USA algorithm
IN_LICBX       EQU  0000000001000000B	     ;AN000;load ICB off:seg and exit
IN_LVBOV       EQU  0000000010000000B	     ;AN000;use video buffer seg:off override
					     ;
IN_RANG        EQU  0000000000000001B	     ;AN000;ICB ID out of vector range
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Input Field Control Block Equates
;
; ICB_OPT1  Option word one equates
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ICB_ECL 	EQU  0000000000000001B	      ;AN000;set specified color on entry
ICB_XCL 	EQU  0000000000000010B	      ;AN000;set specified color on exit
ICB_USC 	EQU  0000000000000100B	      ;AN000;use color attribute string
ICB_BEN 	EQU  0000000000001000B	      ;AN000;display entry delimiters
ICB_BEX 	EQU  0000000000010000B	      ;AN000;display exit delimiters
ICB_BOX 	EQU  0000000000100000B	      ;AN000;display border delimiters
ICB_MUS 	EQU  0000000001000000B	      ;AN000;plus and minus display active
ICB_SMU 	EQU  0000000010000000B	      ;AN000;starting default is negative
ICB_OUT 	EQU  0000000100000000B	      ;AN000;display default and accept input
ICB_CLR 	EQU  0000001000000000B	      ;AN000;clear default on first entry
ICB_PSW 	EQU  0000010000000000B	      ;AN000;password
ICB_RJU 	EQU  0000100000000000B	      ;AN000;right justification is activated
ICB_SWK 	EQU  0001000000000000B	      ;AN000;switch entry dir key active
ICB_RTA 	EQU  0010000000000000B	      ;AN000;right arrow editing
ICB_LFA 	EQU  0100000000000000B	      ;AN000;left arrow editing
ICB_BKS 	EQU  1000000000000000B	      ;AN000;backspace editing
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; ICB_OPT2  Option word two equates
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ICB_INS 	EQU  0000000000000001B	      ;AN000;insert key editing
ICB_DEL 	EQU  0000000000000010B	      ;AN000;delete key editing
ICB_HOM 	EQU  0000000000000100B	      ;AN000;home key editing
ICB_CTE 	EQU  0000000000001000B	      ;AN000;control + end key editing
ICB_END 	EQU  0000000000010000B	      ;AN000;end key editing
ICB_AXC 	EQU  0000000000100000B	      ;AN000;auto enter on cursor
ICB_AXD 	EQU  0000000001000000B	      ;AN000;auto enter on data
ICB_CSW 	EQU  0000000010000000B	      ;AN000;wrap the cursor end to end
ICB_UPC 	EQU  0000000100000000B	      ;AN000;lower case to upper conversion
ICB_UFK 	EQU  0000001000000000B	      ;AN000;use supplied keystroke as 1 key
ICB_UDO 	EQU  0000010000000000B	      ;AN000;undo key replaces default
ICB_TSD 	EQU  0000100000000000B	      ;AN000;thousands separators during inpu
ICB_TSA 	EQU  0001000000000000B	      ;AN000;thousands separators after entry
ICB_TSR 	EQU  0010000000000000B	      ;AN000;return thousand separators
ICB_PAD 	EQU  0100000000000000B	      ;AN000;pad zeros to precision
ICB_WRP 	EQU  1000000000000000B	      ;AN000;word wrap in windowed field
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; ICB_OPT3  Option word three equates
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ICB_WIN        EQU  0000000000000001B	     ;AN000;windowing wrap of field
ICB_WAE        EQU  0000000000000010B	     ;AN000;up and down arrow editing
ICB_TBX        EQU  0000000000000100B	     ;AN000;exit if arrows reach top/bottom
ICB_HOR        EQU  0000000000001000B	     ;AN000;horizontial windowing
ICB_WHM        EQU  0000000000010000B	     ;AN000;full window Home key
ICB_WEN        EQU  0000000000100000B	     ;AN000;full window End key
ICB_WCE        EQU  0000000001000000B	     ;AN000;full window Ctrl-End key
ICB_WDL        EQU  0000000010000000B	     ;AN000;full window Delete key
ICB_WAR        EQU  0000000100000000B	     ;AN000;full window arrow keys
ICB_WBS        EQU  0000001000000000B	     ;AN000;full window backspace key
ICB_FGS        EQU  0000010000000000B	     ;AN000;use the ICB_STATUS status values
ICB_SCR        EQU  0000100000000000B	     ;AN000;display of scroll flag active
ICB_NUM        EQU  0001000000000000B	     ;AN000;display of numlock flag active
ICB_CAP        EQU  0010000000000000B	     ;AN000;display of caps flag active
ICB_FIN        EQU  0100000000000000B	     ;AN000;display of insert flag active
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; ICB_STATUS status word equates
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ICB_SDEF       EQU  0000000000000001B	     ;AN000;default value changed
ICB_SMUS       EQU  0000000000000010B	     ;AN000;minus sign active
ICB_SPUS       EQU  0000000000000100B	     ;AN000;plus sign active
ICB_STRU       EQU  0000000000001000B	     ;AN000;default value was truncated
ICB_SSCR       EQU  0000000000010000B	     ;AN000;scroll lock flag on at exit/entry
ICB_SNUM       EQU  0000000000100000B	     ;AN000;num lock flag on at exit/entry
ICB_SCAP       EQU  0000000001000000B	     ;AN000;caps lock flag on at exit/entry
ICB_SINS       EQU  0000000010000000B	     ;AN000;insert flag on at exit/entry
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; PCWWRAP option bit equates (WWP_OPT1)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
WWP_LEFTJUST   EQU  0000000000000001B	     ;AN000;process with left straight edge
WWP_RIGHTJUST  EQU  0000000000000010B	     ;AN000;process with right straight edge
WWP_LEFTNRIGHT EQU  0000000000000100B	     ;AN000;process with left and right edge
WWP_HYPHEN     EQU  0000000000001000B	     ;AN000;hyphenate word(s)
WWP_DESTBUFFER EQU  0000000000010000B	     ;AN000;Use specified destination buffer
WWP_SRCBUFFER  EQU  0000000000100000B	     ;AN000;Use the same buf as the text
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; PCWWRAP error bit equates (WWP_ERROR)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
WWP_BUFSIZE    EQU  0000000000000001B	     ;AN000;buffer size is too small
WWP_DUPSYMBOL  EQU  0000000000000010B	     ;AN000;WWP_HYSMBOL and WWP_SRCHYSMB
					     ; are set to same character
WWP_LONGWORD   EQU  0000000000000100B	     ;AN000;word is longer than WWP_WIDTH
WWP_NOBUFFER   EQU  0000000000001000B	     ;AN000;no address to src or dest buf
WWP_NOJUSTOPT  EQU  0000000000010000B	     ;AN000;no justification option was set
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Help options (WR_HLPOPT, WR_HLPPAN, WR_HLPDIS)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
HLP_CONT       EQU  0000000000000001B	     ;AN000;contextual help
HLP_KEYS       EQU  0000000000000010B	     ;AN000;keys help
HLP_HELP       EQU  0000000000000100B	     ;AN000;help-on-help
HLP_INDX       EQU  0000000000001000B	     ;AN000;help index
HLP_OVER       EQU  0000000000010000B	     ;AN000;help row and column overrides
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Internal equates
;
;
; Internal keystroke equates
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
UPARROW        EQU  72*256		     ;AN000;up arrow
DNARROW        EQU  80*256		     ;AN000;down arrow
LFARROW        EQU  75*256		     ;AN000;left arrow
RTARROW        EQU  77*256		     ;AN000;right arrow
PGUP	       EQU  73			     ;AN000;
PGDN	       EQU  81			     ;AN000;
ESCAPE	       EQU  27			     ;AN000;
ENTER	       EQU  13			     ;AN000;
SPACE	       EQU  32			     ;AN000;
TAB	       EQU   9			     ;AN000;
F1	       EQU  59			     ;AN000;
F2	       EQU  60			     ;AN000;
F3	       EQU  61			     ;AN000;
F4	       EQU  62			     ;AN000;
F5	       EQU  63			     ;AN000;
F6	       EQU  64			     ;AN000;
F7	       EQU  65			     ;AN000;
F8	       EQU  66			     ;AN000;
F9	       EQU  67			     ;AN000;
F10	       EQU  68			     ;AN000;
