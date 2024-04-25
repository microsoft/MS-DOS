;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	CASTRUC.INC
;
;
;
;
;
; PCPANEL PCB Structure
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PCB_PB	       STRUC			     ;AN000;
PCB_OPT1       DW   0			     ;AN000;option word
PCB_OPT2       DB   0			     ;AN000;option 2 added
PCB_OPT3       DB   0			     ;AN000;option 3 added
PCB_OPT4       DB   0			     ;AN000;option 4 added
PCB_UROW       DW   0			     ;AN000;row location of panel
PCB_UCOL       DW   0			     ;AN000;column location of panel
PCB_WIDTH      DW   0			     ;AN000;text char width of panel
PCB_MAXSIZE    DW   0			     ;AN000;Max poss panel sizing in text
PCB_CCBID      DW   0			     ;AN000;Index number of log color
PCB_BORDER     DB   8  DUP(0)		     ;AN000;8 log border characters
PCB_COMPLEN    DW   0			     ;AN000;Length compress panel in mem
PCB_COMPOFF    DW   0			     ;AN000;Off addr compressed panel
PCB_COMPSEG    DW   0			     ;AN000;Seg addr compressed panel
PCB_EXPANDLEN  DW   0			     ;AN000;Length expanded panel in mem
PCB_EXPANDOFF  DW   0			     ;AN000;Off addr of expanded panel in
PCB_EXPANDSEG  DW   0			     ;AN000;Seg addr of expanded panel in
PCB_MIXEDLEN   DW   0			     ;AN000;Len of the mixed panel in mem
PCB_MIXEDOFF   DW   0			     ;AN000;Off addr of mixed panel in mem
PCB_MIXEDSEG   DW   0			     ;AN000;Seg addr of mixed panel in mem
PCB_LABELLEN   DW   0			     ;AN000;Len of the panel label
PCB_LABELOFF   DW   0			     ;AN000;Off addr of the panel label
PCB_LABELSEG   DW   0			     ;AN000;Seg addr of the panel label
PCB_LABELROW   DW   0			     ;AN000;Beg row of title relative to pan
PCB_LABELCOL   DW   0			     ;AN000;Beg col of title relative to pan
PCB_FPANLEN    DW   0			     ;AN000;Len of the panel stored in file
PCB_FNAMEOFF   DW   0			     ;AN000;Off address of full filespec
PCB_FNAMESEG   DW   0			     ;AN000;Seg address of full filespec
PCB_FTEXTLOCL  DW   0			     ;AN000;Lower off word of the beg off
PCB_FTEXTLOCH  DW   0			     ;AN000;High off word of the beg off
PCB_LROW       DW   0			     ;AN000;lower right corner (graphs only)
PCB_LCOL       DW   0			     ;AN000;lower left corner (graphs only)
PCB_VERTSHADE  DB   0			     ;AN000;vertical shadow mask (grap only)
PCB_HORZSHADE  DB   0			     ;AN000;horizontal shadow mask (graphs)
PCB_GFILLOFF   DW   0			     ;AN000;offset of wind char fill bit map
PCB_GFILLSEG   DW   0			     ;AN000;segmnt of wind char fill bit map
PCB_SCRSV1OFF  DW   0			     ;AN000;off scr buffer save 10H, 12H
PCB_SCRSV2OFF  DW   0			     ;AN000;off scr buffer save 11H
PCB_SCRSAVSEG  DW   0			     ;AN000;segment of screen buffer save
PCB_RESERVED   DW   0			     ;AN000;reserved
PCB_CHILDNUM   DW   0			     ;AN000;Number of child panel entries
PCB_CHILDOFF   DW   0			     ;AN000;Off address of child panel table
PCB_CHILDSEG   DW   0			     ;AN000;Seg address of child panel table
PCB_PB	       ENDS			     ;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; PCSLCTP Structure
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SCB_PB	       STRUC			     ;AN000;
SCB_OPT1       DW   0			     ;AN000;option word one
SCB_OPT2       DW   0			     ;AN000;option word two
SCB_OPT3       DW   0			     ;AN000;option word three
SCB_OPT4       DW   0			     ;AN068;SEH option word four
SCB_FREQ       DW   0			     ;AN000;error beep frequency
SCB_ROW        DW   0			     ;AN000;upper left row
SCB_COL        DW   0			     ;AN000;upper left column
SCB_RELROW     DW   0			     ;AN000;relative upper left row
SCB_RELCOL     DW   0			     ;AN000;relative upper left column
SCB_WIDTH      DW   0			     ;AN000;line width
SCB_NUMLINE    DW   0			     ;AN000;number of lines
SCB_TOPELE     DW   0			     ;AN000;number of element on top
SCB_NUMELE     DW   0			     ;AN000;number of elements
SCB_CURELE     DW   0			     ;AN000;current element
SCB_NUMCOL     DW   0			     ;AN000;maximun number of cols to scroll
SCB_CURCOL     DW   0			     ;AN000;display offset into opt strings
SCB_NLISTCOL   DW   0			     ;AN000;num list txt col offset in strg
SCB_NLISTSEP   DB   0			     ;AN000;numbered list separator
SCB_SKLEN      DW   0			     ;AN000;select keystroke string length
SCB_SKOFF      DW   0			     ;AN000;select keystroke string offset
SCB_SKSEG      DW   0			     ;AN000;select keystroke string segment
SCB_RLLEN      DW   0			     ;AN000;return/leave string length
SCB_RLOFF      DW   0			     ;AN000;return/leave string offset
SCB_RLSEG      DW   0			     ;AN000;return/leave string segment
SCB_RELEN      DW   0			     ;AN000;return/erase string length
SCB_REOFF      DW   0			     ;AN000;return/erase string offset
SCB_RESEG      DW   0			     ;AN000;return/erase string segment
SCB_UALEN      DW   0			     ;AN000;up arrow string length
SCB_UAOFF      DW   0			     ;AN000;up arrow string offset
SCB_UASEG      DW   0			     ;AN000;up arrow string segment
SCB_DALEN      DW   0			     ;AN000;down arrow string length
SCB_DAOFF      DW   0			     ;AN000;down arrow string offset
SCB_DASEG      DW   0			     ;AN000;down arrow string segment
SCB_LALEN      DW   0			     ;AN000;left arrow string length
SCB_LAOFF      DW   0			     ;AN000;left arrow string offset
SCB_LASEG      DW   0			     ;AN000;left arrow string segment
SCB_RALEN      DW   0			     ;AN000;right arrow string length
SCB_RAOFF      DW   0			     ;AN000;right arrow string offset
SCB_RASEG      DW   0			     ;AN000;right arrow string segment
SCB_PULEN      DW   0			     ;AN000;page-up string length
SCB_PUOFF      DW   0			     ;AN000;page-up string offset
SCB_PUSEG      DW   0			     ;AN000;page-up string segment
SCB_PDLEN      DW   0			     ;AN000;page-down string length
SCB_PDOFF      DW   0			     ;AN000;page-down string offset
SCB_PDSEG      DW   0			     ;AN000;page-down string segment
SCB_PILEN      DW   0			     ;AN000;pointer indicator strg length
SCB_PIOFF      DW   0			     ;AN000;pointer indicator string offset
SCB_PISEG      DW   0			     ;AN000;pointer indicator string segment
SCB_PICOL      DW   0			     ;AN000;pointer ind txt col off into stg
SCB_AILEN      DW   0			     ;AN000;active indicator strg length
SCB_AIOFF      DW   0			     ;AN000;active indicator string offset
SCB_AISEG      DW   0			     ;AN000;active indicator string segment
SCB_AICOL      DW   0			     ;AN000;active ind txt col off into stg
SCB_CILEN      DW   0			     ;AN000;check mark text string length
SCB_CIOFF      DW   0			     ;AN000;check mark text string offset
SCB_CISEG      DW   0			     ;AN000;check mark text string segment
SCB_CICOL      DW   0			     ;AN000;check mark offset into opt strg
SCB_UILEN      DW   0			     ;AN000;up indicator string length
SCB_UIOFF      DW   0			     ;AN000;up indicator string offset
SCB_UISEG      DW   0			     ;AN000;up indicator string segment
SCB_UIROW      DW   0			     ;AN000;up indicator row location
SCB_UICOL      DW   0			     ;AN000;up indicator column location
SCB_DILEN      DW   0			     ;AN000;down indicator string length
SCB_DIOFF      DW   0			     ;AN000;down indicator string offset
SCB_DISEG      DW   0			     ;AN000;down indicator string segment
SCB_DIROW      DW   0			     ;AN000;down indicator row location
SCB_DICOL      DW   0			     ;AN000;down indicator column locaiton
SCB_LILEN      DW   0			     ;AN000;left indicator string length
SCB_LIOFF      DW   0			     ;AN000;left indicator string offset
SCB_LISEG      DW   0			     ;AN000;left indicator string segment
SCB_LIROW      DW   0			     ;AN000;left indicator row location
SCB_LICOL      DW   0			     ;AN000;left indicator column location
SCB_RILEN      DW   0			     ;AN000;right indicator string length
SCB_RIOFF      DW   0			     ;AN000;right indicator string offset
SCB_RISEG      DW   0			     ;AN000;right indicator string segment
SCB_RIROW      DW   0			     ;AN000;right indicator row location
SCB_RICOL      DW   0			     ;AN000;right indicator column locaiton
SCB_NCRAYOFF   DW   0			     ;AN000;normal color array offset
SCB_NCRAYSEG   DW   0			     ;AN000;normal color array segment
SCB_CCBID      DW   0			     ;AN000;logical color index number
SCB_CCBVECNUM  DW   0			     ;AN000;number color index table entries
SCB_CCBVECOFF  DW   0			     ;AN000;offset addr of color index table
SCB_CCBVECSEG  DW   0			     ;AN000;segment addr of color index tabl
SCB_INDEXOFF   DW   0			     ;AN000;index array offset
SCB_INDEXSEG   DW   0			     ;AN000;index array segment
SCB_SELOFF     DW   0			     ;AN000;element selection array offset
SCB_SELSEG     DW   0			     ;AN000;element selection array segment
SCB_OAOPT      DW   0			     ;AN000;option array option word
SCB_OAPOFF     DW   0			     ;AN000;option array pointer offset
SCB_OAPSEG     DW   0			     ;AN000;option array pointer segment
SCB_OASLEN     DW   0			     ;AN000;option array string length
SCB_OASSEG     DW   0			     ;AN000;option array string segment
SCB_OASTERMC   DB   0			     ;AN000;option array string term char
SCB_KS	       DW   0			     ;AN000;keystroke
SCB_LVBOFF     DW   0			     ;AN000;log vid buf offset override
SCB_LVBSEG     DW   0			     ;AN000;log vid buf segment override
SCB_FMOPT1     DW   0			     ;AN000;general purpose format hook opt
SCB_FMOPT2     DW   0			     ;AN000;general purpose format hook opt
SCB_TRANLEN    DW   0			     ;AN000;length of translation table
SCB_TRANOFF    DW   0			     ;AN000;offset of translation table
SCB_TRANSEG    DW   0			     ;AN000;segment of translation table
SCB_MONOOFF    DW   0			     ;AN000;monocasing table offset
SCB_MONOSEG    DW   0			     ;AN000;monocasing table segment
SCB_DBCSLEN    DW   0			     ;AN000;dbcs table length
SCB_DBCSOFF    DW   0			     ;AN000;dbcs table offset
SCB_DBCSSEG    DW   0			     ;AN000;dbcs table segment
SCB_FONTOFF    DW   0			     ;AN068;SEH offset of font descriptor block
SCB_FONTSEG    DW   0			     ;AN068;SEH segment of font descriptor block
SCB_PB	       ENDS			     ;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CHD_PB	STRUC				     ;AN000;
CHD_PCB DW	0			     ;AN000;child PCB element number
CHD_ROW DW	0			     ;AN000;row override
CHD_COL DW	0			     ;AN000;column override
CHD_INX DW	0			     ;AN000;color index pointer override
	DW	0			     ;AN000;function key attribute
	DB	0,0			     ;AN000;keystroke associated with child
	DW	0			     ;AN000;option word
CHD_PB	ENDS				     ;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Input Field Control Block (ICB) Structure
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ICB_PB	       STRUC			     ;AN000;begin input field control block
ICB_OPT1       DW   0			     ;AN000;option word one
ICB_OPT2       DW   0			     ;AN000;option word two
ICB_OPT3       DW   0			     ;AN000;option word three
ICB_OPT4       DW   0			     ;AN000;option word four
ICB_ROW        DW   0			     ;AN000;upper left corner field row
ICB_COL        DW   0			     ;AN000;upper left corner field column
ICB_WIDTH      DW   0			     ;AN000;number of chars before wrapping
ICB_CCBID      DW   0			     ;AN000;color index number assigned
ICB_STATUS     DW   0			     ;AN000;default change/minus status
ICB_CURCHAR    DW   0			     ;AN000;cursor character pos in field
ICB_HRSTART    DW   0			     ;AN000;NEW ADD...Hor scroll support
ICB_SOUND      DW   0			     ;AN000;frequency of error beep
ICB_KEYRET     DW   0			     ;AN000;ASCII code of the key returned
ICB_ENDBYTE    DW   0			     ;AN000;length of data entered into fld
ICB_FIELDLEN   DW   0			     ;AN000;length of input field
ICB_FIELDOFF   DW   0			     ;AN000;offset of input field
ICB_FIELDSEG   DW   0			     ;AN000;segment of input field
ICB_ATTROFF    DW   0			     ;AN000;offset of color attribute buffer
ICB_ATTRSEG    DW   0			     ;AN000;segment of color attr buffer
ICB_DEFLEN     DW   0			     ;AN000;length of field's default value
ICB_DEFOFF     DW   0			     ;AN000;offset field's default value
ICB_DEFSEG     DW   0			     ;AN000;segment field's default value
ICB_RETLEN     DW   0			     ;AN000;length of return string
ICB_RETOFF     DW   0			     ;AN000;offset of return string
ICB_RETSEG     DW   0			     ;AN000;segment of return string
ICB_ALLLEN     DW   0			     ;AN000;length of allow chars
ICB_ALLOFF     DW   0			     ;AN000;offset of allow chars
ICB_ALLSEG     DW   0			     ;AN000;segment of allow chars
ICB_SKIPLEN    DW   0			     ;AN000;length of skip chars
ICB_SKIPOFF    DW   0			     ;AN000;offset of skip chars
ICB_SKIPSEG    DW   0			     ;AN000;segment of skip chars
ICB_ALL1LEN    DW   0			     ;AN000;length of allow once chars
ICB_ALL1OFF    DW   0			     ;AN000;offset of allow once chars
ICB_ALL1SEG    DW   0			     ;AN000;segment of allow once chars
ICB_DECPOS     DW   0			     ;AN000;precision of decimal point
ICB_RANUML1    DW   0			     ;AN000;low numeric range (low intrgr)
ICB_RANUMH1    DW   0			     ;AN000;low numeric range (high intrgr)
ICB_RANUML2    DW   0			     ;AN000;high numeric range (low intrgr)
ICB_RANUMH2    DW   0			     ;AN000;high numeric range (high intrgr)
ICB_MANDPROW   DW   0			     ;AN000;beginning row of minus and plus
ICB_MANDPCOL   DW   0			     ;AN000;beginning col of minus & plus
ICB_MINUSLEN   DW   0			     ;AN000;length of minus sign string
ICB_MINUSOFF   DW   0			     ;AN000;offset of minus sign string
ICB_MINUSSEG   DW   0			     ;AN000;segment of minus sign string
ICB_PLUSLEN    DW   0			     ;AN000;length of plus sign string
ICB_PLUSOFF    DW   0			     ;AN000;offset of plus sign string
ICB_PLUSSEG    DW   0			     ;AN000;segment of plus sign string
ICB_PB	       ENDS			     ;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
