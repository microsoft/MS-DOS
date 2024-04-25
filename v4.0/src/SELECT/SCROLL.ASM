;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	SCROLL.ASM
;
;
;
;
;
;
;
;
;
;
;
;
;
;
;
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	.alpha		; arrange segments alphabetically

	INCLUDE SEL-PAN.INC		;AN024;
	EXTRN	WR_CIS:WORD		;AN024;
					;
	PUBLIC	WR_SCBVEC		;AN024;
	PUBLIC	NUM_SCB 		;AN024;
					;
PANEL	EQU	0			;AN024;
SCROLL	EQU	1			;AN024;
					;
CODE	SEGMENT PARA PUBLIC 'CODE'      ;AN024
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Scroll Control Block Vector
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
WR_SCBVEC      DW   0,OFFSET WR_SCB1	     ;AN024;SCB 1  segment,offset
	       DW   0,OFFSET WR_SCB2	     ;AN024;SCB 2  segment,offset
	       DW   0,OFFSET WR_SCB3	     ;AN024;SCB 3  segment,offset
	       DW   0,OFFSET WR_SCB4	     ;AN024;SCB 4  segment,offset
	       DW   0,OFFSET WR_SCB5	     ;AN024;SCB 5  segment,offset
	       DW   0,OFFSET WR_SCB6	     ;AN024;SCB 6  segment,offset
	       DW   0,OFFSET WR_SCB7	     ;AN024;SCB 7  segment,offset
	       DW   0,OFFSET WR_SCB8	     ;AN024;SCB 8  segment,offset
	       DW   0,OFFSET WR_SCB9	     ;AN024;SCB 9  segment,offset
	       DW   0,OFFSET WR_SCB10	     ;AN024;SCB 10 segment,offset
	       DW   0,OFFSET WR_SCB11	     ;AN024;SCB 11 segment,offset
	       DW   0,OFFSET WR_SCB12	     ;AN024;SCB 12 segment,offset
	       DW   0,OFFSET WR_SCB13	     ;AN024;SCB 13 segment,offset
	       DW   0,OFFSET WR_SCB14	     ;AN024;SCB 14 segment,offset
	       DW   0,OFFSET WR_SCB15	     ;AN024;SCB 15 segment,offset
	       DW   0,OFFSET WR_SCB16	     ;AN024;SCB 16 segment,offset
	       DW   0,OFFSET WR_SCB17	     ;AN024;SCB 17 segment,offset
	       DW   0,OFFSET WR_SCB18	     ;AN024;SCB 18 segment,offset
	       DW   0,OFFSET WR_SCB19	     ;AN024;SCB 19 segment,offset
	       DW   0,OFFSET WR_SCB20	     ;AN024;SCB 20 segment,offset
	       DW   0,OFFSET WR_SCB21	     ;AN024;SCB 21 segment,offset
	       DW   0,OFFSET WR_SCB22	     ;AN024;SCB 22 segment,offset
	       DW   0,OFFSET WR_SCB23	     ;AN024;SCB 23 segment,offset
	       DW   0,OFFSET WR_SCB24	     ;AN024;SCB 24 segment,offset
	       DW   0,OFFSET WR_SCB25	     ;AN024;SCB 25 segment,offset
	       DW   0,OFFSET WR_SCB26	     ;AN024;SCB 26 segment,offset
	       DW   0,OFFSET WR_SCB27	     ;AN024;SCB 27 segment,offset
	       DW   0,OFFSET WR_SCB28	     ;AN024;SCB 28 segment,offset
NUM_SCB        EQU ($-WR_SCBVEC)/4	     ;AN024;
L_WR_SCBVEC    EQU  NUM_SCB		     ;AN024;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Scroll Data Definition
;
;
; PCSCRWR parameter block
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
WR_INDEX1      DW   15		;AN000;element order number
	       DW   14		;AN000;
	       DW   13		;AN000;
	       DW   12		;AN000;
	       DW   11		;AN000;
	       DW   10		;AN000;
	       DW   9		;AN000;
	       DW   8		;AN000;
	       DW   7		;AN000;
	       DW   6		;AN000;
	       DW   5		;AN000;
	       DW   4		;AN000;
	       DW   3		;AN000;
	       DW   2		;AN000;
	       DW   1		;AN000;
				;
LEFT_COL_SCROLL  EQU  11	;AN000;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; DOSLEVEL SUPPORT
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
WR_SCB1        DW   SCB_WRAP		     ;AN000;option word one
	       DW   SCB_SKIP		     ;AN000;option word two
	       DW   SCB_NUMS		     ;AN000;option word three
	       DW   0			     ;AN068;SEH option word four
	       DW   SND_FREQ		     ;AN000;error beep frequency
	       DW   12			     ;AN000;upper left row
	       DW   LEFT_COL_SCROLL	     ;AN000;upper left column
	       DW   0			     ;AN000;relative upper left row
	       DW   0			     ;AN000;relative upper left column
	       DW   SCB_LIST1_W 	     ;AN000;line width
	       DW   SCB_LIST1_N 	     ;AN000;number of lines
	       DW   1			     ;AN000;number of element on top
	       DW   SCB_LIST1_N 	     ;AN000;number of elements
	       DW   1			     ;AN000;current element
	       DW   0			     ;AN000;maximun number of cols to scroll
	       DW   0			     ;AN000;display offset into opt strings
	       DW   1			     ;AN000;num list txt col offset in strg
	       DB   '.'                      ;AN000;numbered list separator
	       DW   0			     ;AN000;select keystroke string length
	       DW   0			     ;AN000;select keystroke string offset
	       DW   0			     ;AN000;select keystroke string segment
	       DW   0			     ;AN000;return/leave string length
	       DW   0			     ;AN000;return/leave string offset
	       DW   0			     ;AN000;return/leave string segment
	       DW   0			     ;AN000;return/erase string length
	       DW   0			     ;AN000;return/erase string offset
	       DW   0			     ;AN000;return/erase string segment
	       DW   WR_UAKEYSLEN	     ;AN000;up arrow string length
	       DW   WR_UAKEYS		     ;AN000;up arrow string offset
	       DW   0			     ;AN000;up arrow string segment
	       DW   WR_DAKEYSLEN	     ;AN000;down arrow string length
	       DW   WR_DAKEYS		     ;AN000;down arrow string offset
	       DW   0			     ;AN000;down arrow string segment
	       DW   0			     ;AN000;left arrow string length
	       DW   0			     ;AN000;left arrow string offset
	       DW   0			     ;AN000;left arrow string segment
	       DW   0			     ;AN000;right arrow string length
	       DW   0			     ;AN000;right arrow string offset
	       DW   0			     ;AN000;right arrow string segment
	       DW   WR_PUKEYSLEN	     ;AN000;page-up string length
	       DW   WR_PUKEYS		     ;AN000;page-up string offset
	       DW   0			     ;AN000;page-up string segment
	       DW   WR_PDKEYSLEN	     ;AN000;page-down string length
	       DW   WR_PDKEYS		     ;AN000;page-down string offset
	       DW   0			     ;AN000;page-down string segment
	       DW   WR_PIINDLEN 	     ;AN000;pointer indicator strg length
	       DW   WR_PIIND		     ;AN000;pointer indicator string offset
	       DW   0			     ;AN000;pointer indicator string segment
	       DW   1			     ;AN000;pointer ind txt col off into strg
	       DW   WR_AIINDLEN 	     ;AN000;active indicator strg length
	       DW   WR_AIIND		     ;AN000;active indicator string offset
	       DW   0			     ;AN000;active indicator string segment
	       DW   1			     ;AN000;active ind txt col off into stg
	       DW   WR_CIINDLEN 	     ;AN000;check mark text string length
	       DW   WR_CIIND		     ;AN000;check mark text string offset
	       DW   0			     ;AN000;check mark text string segment
	       DW   1			     ;AN000;check mark offset into opt strg
	       DW   WR_UIINDLEN 	     ;AN000;up indicator string length
	       DW   WR_UIIND		     ;AN000;up indicator string offset
	       DW   0			     ;AN000;up indicator string segment
	       DW   2			     ;AN000;up indicator row location
	       DW   1			     ;AN000;up indicator column location
	       DW   WR_DIINDLEN 	     ;AN000;down indicator string length
	       DW   WR_DIIND		     ;AN000;down indicator string offset
	       DW   0			     ;AN000;down indicator string segment
	       DW   2			     ;AN000;down indicator row location
	       DW   2			     ;AN000;down indicator column locaiton
	       DW   0			     ;AN000;left indicator string length
	       DW   0			     ;AN000;left indicator string offset
	       DW   0			     ;AN000;left indicator string segment
	       DW   0			     ;AN000;left indicator row location
	       DW   0			     ;AN000;left indicator column location
	       DW   0			     ;AN000;right indicator string length
	       DW   0			     ;AN000;right indicator string offset
	       DW   0			     ;AN000;right indicator string segment
	       DW   0			     ;AN000;right indicator row location
	       DW   0			     ;AN000;right indicator column locaiton
	       DW   0			     ;AN000;normal color array offset
	       DW   0			     ;AN000;normal color array segment
	       DW   1			     ;AN000;logical color index number
	       DW   0			     ;AN000;number color index table entries
	       DW   0			     ;AN000;offset addr of color index table
	       DW   0			     ;AN000;segment addr of color index tabl
	       DW   WR_INDEX1		     ;AN000;index array offset
	       DW   0			     ;AN000;index array segment
	       DW   WR_SELECT_NUM	     ;AN000;element selection array offset
	       DW   0			     ;AN000;element selection array segment
	       DW   SSC_PTSB		     ;AN000;option array option word
	       DW   SCB_LIST1		     ;AN000;option array pointer offset
	       DW   0			     ;AN000;option array pointer segment
	       DW   SCB_LIST1_W 	     ;AN000;option array string length
	       DW   0			     ;AN000;option array string segment
	       DB   'A'                      ;AN000;option array string term char
	       DW   0			     ;AN000;keystroke
	       DW   0			     ;AN000;log vid buf offset override
	       DW   0			     ;AN000;log vid buf segment override
	       DW   0			     ;AN000;general purpose format hook opt
	       DW   0			     ;AN000;general purpose format hook opt
	       DW   0			     ;AN000;length of translation table
	       DW   0			     ;AN000;offset of translation table
	       DW   0			     ;AN000;segment of translation table
	       DW   0			     ;AN000;monocasing table offset
	       DW   0			     ;AN000;monocasing table segment
	       DW   0			     ;AN000;dbcs table length
	       DW   0			     ;AN000;dbcs table offset
	       DW   0			     ;AN000;dbcs table segment
	       DW   0			     ;AN068;SEH offset of font descriptor block
	       DW   0			     ;AN068;SEH segment of font descriptor block
	       DB   236 DUP(0)		     ;AN024;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; SELECT COUNTRY CODE AND KEYBOARD
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
WR_SCB2        DW    SCB_WRAP		     ;AN000;option word one
	       DW    SCB_SKIP		     ;AN000;option word two
	       DW    SCB_NUMS		     ;AN000;option word three
	       DW   0			     ;AN068;SEH option word four
	       DW   SND_FREQ		     ;AN000;error beep frequency
	       DW   13			     ;AN000;upper left row
	       DW   LEFT_COL_SCROLL	     ;AN000;upper left column
	       DW   0			     ;AN000;relative upper left row
	       DW   0			     ;AN000;relative upper left column
	       DW   SCB_LIST2_W 	     ;AN000;line width
	       DW   SCB_LIST2_N 	     ;AN000;number of lines
	       DW   1			     ;AN000;number of element on top
	       DW   SCB_LIST2_N 	     ;AN000;number of elements
	       DW   1			     ;AN000;current element
	       DW   0			     ;AN000;maximun number of cols to scroll
	       DW   0			     ;AN000;display offset into opt strings
	       DW   1			     ;AN000;num list txt col offset in strg
	       DB   '.'                      ;AN000;numbered list separator
	       DW   0			     ;AN000;select keystroke string length
	       DW   0			     ;AN000;select keystroke string offset
	       DW   0			     ;AN000;select keystroke string segment
	       DW   0			     ;AN000;return/leave string length
	       DW   0			     ;AN000;return/leave string offset
	       DW   0			     ;AN000;return/leave string segment
	       DW   0			     ;AN000;return/erase string length
	       DW   0			     ;AN000;return/erase string offset
	       DW   0			     ;AN000;return/erase string segment
	       DW   WR_UAKEYSLEN	     ;AN000;up arrow string length
	       DW   WR_UAKEYS		     ;AN000;up arrow string offset
	       DW   0			     ;AN000;up arrow string segment
	       DW   WR_DAKEYSLEN	     ;AN000;down arrow string length
	       DW   WR_DAKEYS		     ;AN000;down arrow string offset
	       DW   0			     ;AN000;down arrow string segment
	       DW   0			     ;AN000;left arrow string length
	       DW   0			     ;AN000;left arrow string offset
	       DW   0			     ;AN000;left arrow string segment
	       DW   0			     ;AN000;right arrow string length
	       DW   0			     ;AN000;right arrow string offset
	       DW   0			     ;AN000;right arrow string segment
	       DW   WR_PUKEYSLEN	     ;AN000;page-up string length
	       DW   WR_PUKEYS		     ;AN000;page-up string offset
	       DW   0			     ;AN000;page-up string segment
	       DW   WR_PDKEYSLEN	     ;AN000;page-down string length
	       DW   WR_PDKEYS		     ;AN000;page-down string offset
	       DW   0			     ;AN000;page-down string segment
	       DW   WR_PIINDLEN 	     ;AN000;pointer indicator strg length
	       DW   WR_PIIND		     ;AN000;pointer indicator string offset
	       DW   0			     ;AN000;pointer indicator string segment
	       DW   1			     ;AN000;pointer ind txt col off into strg
	       DW   WR_AIINDLEN 	     ;AN000;active indicator strg length
	       DW   WR_AIIND		     ;AN000;active indicator string offset
	       DW   0			     ;AN000;active indicator string segment
	       DW   1			     ;AN000;active ind txt col off into stg
	       DW   WR_CIINDLEN 	     ;AN000;check mark text string length
	       DW   WR_CIIND		     ;AN000;check mark text string offset
	       DW   0			     ;AN000;check mark text string segment
	       DW   1			     ;AN000;check mark offset into opt strg
	       DW   WR_UIINDLEN 	     ;AN000;up indicator string length
	       DW   WR_UIIND		     ;AN000;up indicator string offset
	       DW   0			     ;AN000;up indicator string segment
	       DW   2			     ;AN000;up indicator row location
	       DW   1			     ;AN000;up indicator column location
	       DW   WR_DIINDLEN 	     ;AN000;down indicator string length
	       DW   WR_DIIND		     ;AN000;down indicator string offset
	       DW   0			     ;AN000;down indicator string segment
	       DW   2			     ;AN000;down indicator row location
	       DW   2			     ;AN000;down indicator column locaiton
	       DW   0			     ;AN000;left indicator string length
	       DW   0			     ;AN000;left indicator string offset
	       DW   0			     ;AN000;left indicator string segment
	       DW   0			     ;AN000;left indicator row location
	       DW   0			     ;AN000;left indicator column location
	       DW   0			     ;AN000;right indicator string length
	       DW   0			     ;AN000;right indicator string offset
	       DW   0			     ;AN000;right indicator string segment
	       DW   0			     ;AN000;right indicator row location
	       DW   0			     ;AN000;right indicator column locaiton
	       DW   WR_CIS		     ;AN000;normal color array offset
	       DW   0			     ;AN000;normal color array segment
	       DW   2			     ;AN000;logical color index number
	       DW   0			     ;AN000;number color index table entries
	       DW   0			     ;AN000;offset addr of color index table
	       DW   0			     ;AN000;segment addr of color index tabl
	       DW   WR_INDEX1		     ;AN000;index array offset
	       DW   0			     ;AN000;index array segment
	       DW   WR_SELECT_NUM	     ;AN000;element selection array offset
	       DW   0			     ;AN000;element selection array segment
	       DW   SSC_PTSB		     ;AN000;option array option word
	       DW   SCB_LIST2		     ;AN000;option array pointer offset
	       DW   0			     ;AN000;option array pointer segment
	       DW   SCB_LIST2_W 	     ;AN000;option array string length
	       DW   0			     ;AN000;option array string segment
	       DB   'A'                      ;AN000;option array string term char
	       DW   0			     ;AN000;keystroke
	       DW   0			     ;AN000;log vid buf offset override
	       DW   0			     ;AN000;log vid buf segment override
	       DW   0			     ;AN000;general purpose format hook opt
	       DW   0			     ;AN000;general purpose format hook opt
	       DW   0			     ;AN000;length of translation table
	       DW   0			     ;AN000;offset of translation table
	       DW   0			     ;AN000;segment of translation table
	       DW   0			     ;AN000;monocasing table offset
	       DW   0			     ;AN000;monocasing table segment
	       DW   0			     ;AN000;dbcs table length
	       DW   0			     ;AN000;dbcs table offset
	       DW   0			     ;AN000;dbcs table segment
	       DW   0			     ;AN068;SEH offset of font descriptor block
	       DW   0			     ;AN068;SEH segment of font descriptor block
	       DB   236 DUP(0)		     ;AN024;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; defined country codes 1
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
WR_SCB3        DW   SCB_FRBF+SCB_FRAL	     ;AN000;option word one
	       DW   SCB_ROTN		     ;AN000;option word two
	       DW   0			     ;AN000;option word three
	       DW   0			     ;AN068;SEH option word four
	       DW   SND_FREQ		     ;AN000;error beep frequency
	       DW   6			     ;AN000;upper left row
	       DW   LEFT_COL_SCROLL		    ;AN000;upper left column
	       DW   0			     ;AN000;relative upper left row
	       DW   0			     ;AN000;relative upper left column
	       DW   SCB_LIST3_W 	     ;AN000;line width
	       DW   SCB_LIST3_N 	     ;AN000;number of lines
	       DW   1			     ;AN000;number of element on top
	       DW   SCB_LIST3_N 	     ;AN000;number of elements
	       DW   1			     ;AN000;current element
	       DW   0			     ;AN000;maximun number of cols to scroll
	       DW   0			     ;AN000;display offset into opt strings
	       DW   1			     ;AN000;num list txt col offset in strg
	       DB   '.'                      ;AN000;numbered list separator
	       DW   0			     ;AN000;select keystroke string length
	       DW   0			     ;AN000;select keystroke string offset
	       DW   0			     ;AN000;select keystroke string segment
	       DW   0			     ;AN000;return/leave string length
	       DW   0			     ;AN000;return/leave string offset
	       DW   0			     ;AN000;return/leave string segment
	       DW   0			     ;AN000;return/erase string length
	       DW   0			     ;AN000;return/erase string offset
	       DW   0			     ;AN000;return/erase string segment
	       DW   WR_UAKEYSLEN	     ;AN000;up arrow string length
	       DW   WR_UAKEYS		     ;AN000;up arrow string offset
	       DW   0			     ;AN000;up arrow string segment
	       DW   WR_DAKEYSLEN	     ;AN000;down arrow string length
	       DW   WR_DAKEYS		     ;AN000;down arrow string offset
	       DW   0			     ;AN000;down arrow string segment
	       DW   0			     ;AN000;left arrow string length
	       DW   0			     ;AN000;left arrow string offset
	       DW   0			     ;AN000;left arrow string segment
	       DW   0			     ;AN000;right arrow string length
	       DW   0			     ;AN000;right arrow string offset
	       DW   0			     ;AN000;right arrow string segment
	       DW   0			     ;AN000;page-up string length
	       DW   0			     ;AN000;page-up string offset
	       DW   0			     ;AN000;page-up string segment
	       DW   0			     ;AN000;page-down string length
	       DW   0			     ;AN000;page-down string offset
	       DW   0			     ;AN000;page-down string segment
	       DW   WR_PIINDLEN 	     ;AN000;pointer indicator strg length
	       DW   WR_PIIND		     ;AN000;pointer indicator string offset
	       DW   0			     ;AN000;pointer indicator string segment
	       DW   1			     ;AN000;pointer ind txt col off into strg
	       DW   WR_AIINDLEN 	     ;AN000;active indicator strg length
	       DW   WR_AIIND		     ;AN000;active indicator string offset
	       DW   0			     ;AN000;active indicator string segment
	       DW   1			     ;AN000;active ind txt col off into stg
	       DW   WR_CIINDLEN 	     ;AN000;check mark text string length
	       DW   WR_CIIND		     ;AN000;check mark text string offset
	       DW   0			     ;AN000;check mark text string segment
	       DW   1			     ;AN000;check mark offset into opt strg
	       DW   WR_UIINDLEN 	     ;AN000;up indicator string length
	       DW   WR_UIIND		     ;AN000;up indicator string offset
	       DW   0			     ;AN000;up indicator string segment
	       DW   2			     ;AN000;up indicator row location
	       DW   1			     ;AN000;up indicator column location
	       DW   WR_DIINDLEN 	     ;AN000;down indicator string length
	       DW   WR_DIIND		     ;AN000;down indicator string offset
	       DW   0			     ;AN000;down indicator string segment
	       DW   2			     ;AN000;down indicator row location
	       DW   2			     ;AN000;down indicator column locaiton
	       DW   0			     ;AN000;left indicator string length
	       DW   0			     ;AN000;left indicator string offset
	       DW   0			     ;AN000;left indicator string segment
	       DW   0			     ;AN000;left indicator row location
	       DW   0			     ;AN000;left indicator column location
	       DW   0			     ;AN000;right indicator string length
	       DW   0			     ;AN000;right indicator string offset
	       DW   0			     ;AN000;right indicator string segment
	       DW   0			     ;AN000;right indicator row location
	       DW   0			     ;AN000;right indicator column locaiton
	       DW   WR_CIS		     ;AN000;normal color array offset
	       DW   0			     ;AN000;normal color array segment
	       DW   3			     ;AN000;logical color index number
	       DW   0			     ;AN000;number color index table entries
	       DW   0			     ;AN000;offset addr of color index table
	       DW   0			     ;AN000;segment addr of color index tabl
	       DW   WR_INDEX1		     ;AN000;index array offset
	       DW   0			     ;AN000;index array segment
	       DW   WR_SELECT		     ;AN000;element selection array offset
	       DW   0			     ;AN000;element selection array segment
	       DW   SSC_PTSB		     ;AN000;option array option word
	       DW   SCB_LIST3		     ;AN000;option array pointer offset
	       DW   0			     ;AN000;option array pointer segment
	       DW   SCB_LIST3_W 	     ;AN000;option array string length
	       DW   0			     ;AN000;option array string segment
	       DB   'A'                      ;AN000;option array string term char
	       DW   0			     ;AN000;keystroke
	       DW   0			     ;AN000;log vid buf offset override
	       DW   0			     ;AN000;log vid buf segment override
	       DW   0			     ;AN000;general purpose format hook opt
	       DW   0			     ;AN000;general purpose format hook opt
	       DW   0			     ;AN000;length of translation table
	       DW   0			     ;AN000;offset of translation table
	       DW   0			     ;AN000;segment of translation table
	       DW   0			     ;AN000;monocasing table offset
	       DW   0			     ;AN000;monocasing table segment
	       DW   0			     ;AN000;dbcs table length
	       DW   0			     ;AN000;dbcs table offset
	       DW   0			     ;AN000;dbcs table segment
	       DW   0			     ;AN068;SEH offset of font descriptor block
	       DW   0			     ;AN068;SEH segment of font descriptor block
	       DB   236 DUP(0)		     ;AN024;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; defined country codes 2
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
WR_SCB4        DW   SCB_FRBF+SCB_FRAL	     ;AN000;option word one
	       DW   SCB_ROTN		     ;AN000;option word two
	       DW   0			     ;AN000;option word three
	       DW   0			     ;AN068;SEH option word four
	       DW   SND_FREQ		     ;AN000;error beep frequency
	       DW   6			     ;AN000;upper left row
	       DW   LEFT_COL_SCROLL+SCB_LIST4_W+2   ;AN000;upper left column
	       DW   0			     ;AN000;relative upper left row
	       DW   0			     ;AN000;relative upper left column
	       DW   SCB_LIST4_W 	     ;AN000;line width
	       DW   SCB_LIST4_N 	     ;AN000;number of lines
	       DW   1			     ;AN000;number of element on top
	       DW   SCB_LIST4_N 	     ;AN000;number of elements
	       DW   1			     ;AN000;current element
	       DW   0			     ;AN000;maximun number of cols to scroll
	       DW   0			     ;AN000;display offset into opt strings
	       DW   1			     ;AN000;num list txt col offset in strg
	       DB   '.'                      ;AN000;numbered list separator
	       DW   0			     ;AN000;select keystroke string length
	       DW   0			     ;AN000;select keystroke string offset
	       DW   0			     ;AN000;select keystroke string segment
	       DW   0			     ;AN000;return/leave string length
	       DW   0			     ;AN000;return/leave string offset
	       DW   0			     ;AN000;return/leave string segment
	       DW   0			     ;AN000;return/erase string length
	       DW   0			     ;AN000;return/erase string offset
	       DW   0			     ;AN000;return/erase string segment
	       DW   WR_UAKEYSLEN	     ;AN000;up arrow string length
	       DW   WR_UAKEYS		     ;AN000;up arrow string offset
	       DW   0			     ;AN000;up arrow string segment
	       DW   WR_DAKEYSLEN	     ;AN000;down arrow string length
	       DW   WR_DAKEYS		     ;AN000;down arrow string offset
	       DW   0			     ;AN000;down arrow string segment
	       DW   0			     ;AN000;left arrow string length
	       DW   0			     ;AN000;left arrow string offset
	       DW   0			     ;AN000;left arrow string segment
	       DW   0			     ;AN000;right arrow string length
	       DW   0			     ;AN000;right arrow string offset
	       DW   0			     ;AN000;right arrow string segment
	       DW   0			     ;AN000;page-up string length
	       DW   0			     ;AN000;page-up string offset
	       DW   0			     ;AN000;page-up string segment
	       DW   0			     ;AN000;page-down string length
	       DW   0			     ;AN000;page-down string offset
	       DW   0			     ;AN000;page-down string segment
	       DW   WR_PIINDLEN 	     ;AN000;pointer indicator strg length
	       DW   WR_PIIND		     ;AN000;pointer indicator string offset
	       DW   0			     ;AN000;pointer indicator string segment
	       DW   1			     ;AN000;pointer ind txt col off into strg
	       DW   WR_AIINDLEN 	     ;AN000;active indicator strg length
	       DW   WR_AIIND		     ;AN000;active indicator string offset
	       DW   0			     ;AN000;active indicator string segment
	       DW   1			     ;AN000;active ind txt col off into stg
	       DW   WR_CIINDLEN 	     ;AN000;check mark text string length
	       DW   WR_CIIND		     ;AN000;check mark text string offset
	       DW   0			     ;AN000;check mark text string segment
	       DW   1			     ;AN000;check mark offset into opt strg
	       DW   WR_UIINDLEN 	     ;AN000;up indicator string length
	       DW   WR_UIIND		     ;AN000;up indicator string offset
	       DW   0			     ;AN000;up indicator string segment
	       DW   2			     ;AN000;up indicator row location
	       DW   1			     ;AN000;up indicator column location
	       DW   WR_DIINDLEN 	     ;AN000;down indicator string length
	       DW   WR_DIIND		     ;AN000;down indicator string offset
	       DW   0			     ;AN000;down indicator string segment
	       DW   2			     ;AN000;down indicator row location
	       DW   2			     ;AN000;down indicator column locaiton
	       DW   0			     ;AN000;left indicator string length
	       DW   0			     ;AN000;left indicator string offset
	       DW   0			     ;AN000;left indicator string segment
	       DW   0			     ;AN000;left indicator row location
	       DW   0			     ;AN000;left indicator column location
	       DW   0			     ;AN000;right indicator string length
	       DW   0			     ;AN000;right indicator string offset
	       DW   0			     ;AN000;right indicator string segment
	       DW   0			     ;AN000;right indicator row location
	       DW   0			     ;AN000;right indicator column locaiton
	       DW   WR_CIS		     ;AN000;normal color array offset
	       DW   0			     ;AN000;normal color array segment
	       DW   4			     ;AN000;logical color index number
	       DW   0			     ;AN000;number color index table entries
	       DW   0			     ;AN000;offset addr of color index table
	       DW   0			     ;AN000;segment addr of color index tabl
	       DW   WR_INDEX1		     ;AN000;index array offset
	       DW   0			     ;AN000;index array segment
	       DW   WR_SELECT		     ;AN000;element selection array offset
	       DW   0			     ;AN000;element selection array segment
	       DW   SSC_PTSB		     ;AN000;option array option word
	       DW   SCB_LIST4		     ;AN000;option array pointer offset
	       DW   0			     ;AN000;option array pointer segment
	       DW   SCB_LIST4_W 	     ;AN000;option array string length
	       DW   0			     ;AN000;option array string segment
	       DB   'A'                      ;AN000;option array string term char
	       DW   0			     ;AN000;keystroke
	       DW   0			     ;AN000;log vid buf offset override
	       DW   0			     ;AN000;log vid buf segment override
	       DW   0			     ;AN000;general purpose format hook opt
	       DW   0			     ;AN000;general purpose format hook opt
	       DW   0			     ;AN000;length of translation table
	       DW   0			     ;AN000;offset of translation table
	       DW   0			     ;AN000;segment of translation table
	       DW   0			     ;AN000;monocasing table offset
	       DW   0			     ;AN000;monocasing table segment
	       DW   0			     ;AN000;dbcs table length
	       DW   0			     ;AN000;dbcs table offset
	       DW   0			     ;AN000;dbcs table segment
	       DW   0			     ;AN068;SEH offset of font descriptor block
	       DW   0			     ;AN068;SEH segment of font descriptor block
	       DB   236 DUP(0)		     ;AN024;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; defined keyboard codes 1
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
WR_SCB5        DW   SCB_FRBF+SCB_FRAL	     ;AN000;option word one
	       DW   SCB_ROTN		     ;AN000;option word two
	       DW   0			     ;AN000;option word three
	       DW   0			     ;AN068;SEH option word four
	       DW   SND_FREQ		     ;AN000;error beep frequency
	       DW   6			     ;AN000;upper left row
	       DW   LEFT_COL_SCROLL		    ;AN000;upper left column
	       DW   0			     ;AN000;relative upper left row
	       DW   0			     ;AN000;relative upper left column
	       DW   SCB_LIST5_W 	     ;AN000;line width
	       DW   SCB_LIST5_N 	     ;AN000;number of lines
	       DW   1			     ;AN000;number of element on top
	       DW   SCB_LIST5_N 	     ;AN000;number of elements
	       DW   1			     ;AN000;current element
	       DW   0			     ;AN000;maximun number of cols to scroll
	       DW   0			     ;AN000;display offset into opt strings
	       DW   1			     ;AN000;num list txt col offset in strg
	       DB   '.'                      ;AN000;numbered list separator
	       DW   0			     ;AN000;select keystroke string length
	       DW   0			     ;AN000;select keystroke string offset
	       DW   0			     ;AN000;select keystroke string segment
	       DW   0			     ;AN000;return/leave string length
	       DW   0			     ;AN000;return/leave string offset
	       DW   0			     ;AN000;return/leave string segment
	       DW   0			     ;AN000;return/erase string length
	       DW   0			     ;AN000;return/erase string offset
	       DW   0			     ;AN000;return/erase string segment
	       DW   WR_UAKEYSLEN	     ;AN000;up arrow string length
	       DW   WR_UAKEYS		     ;AN000;up arrow string offset
	       DW   0			     ;AN000;up arrow string segment
	       DW   WR_DAKEYSLEN	     ;AN000;down arrow string length
	       DW   WR_DAKEYS		     ;AN000;down arrow string offset
	       DW   0			     ;AN000;down arrow string segment
	       DW   0			     ;AN000;left arrow string length
	       DW   0			     ;AN000;left arrow string offset
	       DW   0			     ;AN000;left arrow string segment
	       DW   0			     ;AN000;right arrow string length
	       DW   0			     ;AN000;right arrow string offset
	       DW   0			     ;AN000;right arrow string segment
	       DW   0			     ;AN000;page-up string length
	       DW   0			     ;AN000;page-up string offset
	       DW   0			     ;AN000;page-up string segment
	       DW   0			     ;AN000;page-down string length
	       DW   0			     ;AN000;page-down string offset
	       DW   0			     ;AN000;page-down string segment
	       DW   WR_PIINDLEN 	     ;AN000;pointer indicator strg length
	       DW   WR_PIIND		     ;AN000;pointer indicator string offset
	       DW   0			     ;AN000;pointer indicator string segment
	       DW   1			     ;AN000;pointer ind txt col off into strg
	       DW   WR_AIINDLEN 	     ;AN000;active indicator strg length
	       DW   WR_AIIND		     ;AN000;active indicator string offset
	       DW   0			     ;AN000;active indicator string segment
	       DW   1			     ;AN000;active ind txt col off into stg
	       DW   WR_CIINDLEN 	     ;AN000;check mark text string length
	       DW   WR_CIIND		     ;AN000;check mark text string offset
	       DW   0			     ;AN000;check mark text string segment
	       DW   1			     ;AN000;check mark offset into opt strg
	       DW   WR_UIINDLEN 	     ;AN000;up indicator string length
	       DW   WR_UIIND		     ;AN000;up indicator string offset
	       DW   0			     ;AN000;up indicator string segment
	       DW   2			     ;AN000;up indicator row location
	       DW   1			     ;AN000;up indicator column location
	       DW   WR_DIINDLEN 	     ;AN000;down indicator string length
	       DW   WR_DIIND		     ;AN000;down indicator string offset
	       DW   0			     ;AN000;down indicator string segment
	       DW   2			     ;AN000;down indicator row location
	       DW   2			     ;AN000;down indicator column locaiton
	       DW   0			     ;AN000;left indicator string length
	       DW   0			     ;AN000;left indicator string offset
	       DW   0			     ;AN000;left indicator string segment
	       DW   0			     ;AN000;left indicator row location
	       DW   0			     ;AN000;left indicator column location
	       DW   0			     ;AN000;right indicator string length
	       DW   0			     ;AN000;right indicator string offset
	       DW   0			     ;AN000;right indicator string segment
	       DW   0			     ;AN000;right indicator row location
	       DW   0			     ;AN000;right indicator column locaiton
	       DW   WR_CIS		     ;AN000;normal color array offset
	       DW   0			     ;AN000;normal color array segment
	       DW   5			     ;AN000;logical color index number
	       DW   0			     ;AN000;number color index table entries
	       DW   0			     ;AN000;offset addr of color index table
	       DW   0			     ;AN000;segment addr of color index tabl
	       DW   WR_INDEX1		     ;AN000;index array offset
	       DW   0			     ;AN000;index array segment
	       DW   WR_SELECT		     ;AN000;element selection array offset
	       DW   0			     ;AN000;element selection array segment
	       DW   SSC_PTSB		     ;AN000;option array option word
	       DW   SCB_LIST5		     ;AN000;option array pointer offset
	       DW   0			     ;AN000;option array pointer segment
	       DW   SCB_LIST5_W 	     ;AN000;option array string length
	       DW   0			     ;AN000;option array string segment
	       DB   'A'                      ;AN000;option array string term char
	       DW   0			     ;AN000;keystroke
	       DW   0			     ;AN000;log vid buf offset override
	       DW   0			     ;AN000;log vid buf segment override
	       DW   0			     ;AN000;general purpose format hook opt
	       DW   0			     ;AN000;general purpose format hook opt
	       DW   0			     ;AN000;length of translation table
	       DW   0			     ;AN000;offset of translation table
	       DW   0			     ;AN000;segment of translation table
	       DW   0			     ;AN000;monocasing table offset
	       DW   0			     ;AN000;monocasing table segment
	       DW   0			     ;AN000;dbcs table length
	       DW   0			     ;AN000;dbcs table offset
	       DW   0			     ;AN000;dbcs table segment
	       DW   0			     ;AN068;SEH offset of font descriptor block
	       DW   0			     ;AN068;SEH segment of font descriptor block
	       DB   236 DUP(0)		     ;AN024;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; defined keyboard codes 2
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
WR_SCB6        DW   SCB_FRBF+SCB_FRAL	     ;AN000;option word one
	       DW   SCB_ROTN		     ;AN000;option word two
	       DW   0			     ;AN000;option word three
	       DW   0			     ;AN068;SEH option word four
	       DW   SND_FREQ		     ;AN000;error beep frequency
	       DW   6			     ;AN000;upper left row
	       DW   LEFT_COL_SCROLL+SCB_LIST6_W+2   ;AN000;upper left column
	       DW   0			     ;AN000;relative upper left row
	       DW   0			     ;AN000;relative upper left column
	       DW   SCB_LIST6_W 	     ;AN000;line width
	       DW   SCB_LIST6_N 	     ;AN000;number of lines
	       DW   1			     ;AN000;number of element on top
	       DW   SCB_LIST6_N 	     ;AN000;number of elements
	       DW   1			     ;AN000;current element
	       DW   0			     ;AN000;maximun number of cols to scroll
	       DW   0			     ;AN000;display offset into opt strings
	       DW   1			     ;AN000;num list txt col offset in strg
	       DB   '.'                      ;AN000;numbered list separator
	       DW   0			     ;AN000;select keystroke string length
	       DW   0			     ;AN000;select keystroke string offset
	       DW   0			     ;AN000;select keystroke string segment
	       DW   0			     ;AN000;return/leave string length
	       DW   0			     ;AN000;return/leave string offset
	       DW   0			     ;AN000;return/leave string segment
	       DW   0			     ;AN000;return/erase string length
	       DW   0			     ;AN000;return/erase string offset
	       DW   0			     ;AN000;return/erase string segment
	       DW   WR_UAKEYSLEN	     ;AN000;up arrow string length
	       DW   WR_UAKEYS		     ;AN000;up arrow string offset
	       DW   0			     ;AN000;up arrow string segment
	       DW   WR_DAKEYSLEN	     ;AN000;down arrow string length
	       DW   WR_DAKEYS		     ;AN000;down arrow string offset
	       DW   0			     ;AN000;down arrow string segment
	       DW   0			     ;AN000;left arrow string length
	       DW   0			     ;AN000;left arrow string offset
	       DW   0			     ;AN000;left arrow string segment
	       DW   0			     ;AN000;right arrow string length
	       DW   0			     ;AN000;right arrow string offset
	       DW   0			     ;AN000;right arrow string segment
	       DW   0			     ;AN000;page-up string length
	       DW   0			     ;AN000;page-up string offset
	       DW   0			     ;AN000;page-up string segment
	       DW   0			     ;AN000;page-down string length
	       DW   0			     ;AN000;page-down string offset
	       DW   0			     ;AN000;page-down string segment
	       DW   WR_PIINDLEN 	     ;AN000;pointer indicator strg length
	       DW   WR_PIIND		     ;AN000;pointer indicator string offset
	       DW   0			     ;AN000;pointer indicator string segment
	       DW   1			     ;AN000;pointer ind txt col off into strg
	       DW   WR_AIINDLEN 	     ;AN000;active indicator strg length
	       DW   WR_AIIND		     ;AN000;active indicator string offset
	       DW   0			     ;AN000;active indicator string segment
	       DW   1			     ;AN000;active ind txt col off into stg
	       DW   WR_CIINDLEN 	     ;AN000;check mark text string length
	       DW   WR_CIIND		     ;AN000;check mark text string offset
	       DW   0			     ;AN000;check mark text string segment
	       DW   1			     ;AN000;check mark offset into opt strg
	       DW   WR_UIINDLEN 	     ;AN000;up indicator string length
	       DW   WR_UIIND		     ;AN000;up indicator string offset
	       DW   0			     ;AN000;up indicator string segment
	       DW   2			     ;AN000;up indicator row location
	       DW   1			     ;AN000;up indicator column location
	       DW   WR_DIINDLEN 	     ;AN000;down indicator string length
	       DW   WR_DIIND		     ;AN000;down indicator string offset
	       DW   0			     ;AN000;down indicator string segment
	       DW   2			     ;AN000;down indicator row location
	       DW   2			     ;AN000;down indicator column locaiton
	       DW   0			     ;AN000;left indicator string length
	       DW   0			     ;AN000;left indicator string offset
	       DW   0			     ;AN000;left indicator string segment
	       DW   0			     ;AN000;left indicator row location
	       DW   0			     ;AN000;left indicator column location
	       DW   0			     ;AN000;right indicator string length
	       DW   0			     ;AN000;right indicator string offset
	       DW   0			     ;AN000;right indicator string segment
	       DW   0			     ;AN000;right indicator row location
	       DW   0			     ;AN000;right indicator column locaiton
	       DW   WR_CIS		     ;AN000;normal color array offset
	       DW   0			     ;AN000;normal color array segment
	       DW   6			     ;AN000;logical color index number
	       DW   0			     ;AN000;number color index table entries
	       DW   0			     ;AN000;offset addr of color index table
	       DW   0			     ;AN000;segment addr of color index tabl
	       DW   WR_INDEX1		     ;AN000;index array offset
	       DW   0			     ;AN000;index array segment
	       DW   WR_SELECT		     ;AN000;element selection array offset
	       DW   0			     ;AN000;element selection array segment
	       DW   SSC_PTSB		     ;AN000;option array option word
	       DW   SCB_LIST6		     ;AN000;option array pointer offset
	       DW   0			     ;AN000;option array pointer segment
	       DW   SCB_LIST6_W 	     ;AN000;option array string length
	       DW   0			     ;AN000;option array string segment
	       DB   'A'                      ;AN000;option array string term char
	       DW   0			     ;AN000;keystroke
	       DW   0			     ;AN000;log vid buf offset override
	       DW   0			     ;AN000;log vid buf segment override
	       DW   0			     ;AN000;general purpose format hook opt
	       DW   0			     ;AN000;general purpose format hook opt
	       DW   0			     ;AN000;length of translation table
	       DW   0			     ;AN000;offset of translation table
	       DW   0			     ;AN000;segment of translation table
	       DW   0			     ;AN000;monocasing table offset
	       DW   0			     ;AN000;monocasing table segment
	       DW   0			     ;AN000;dbcs table length
	       DW   0			     ;AN000;dbcs table offset
	       DW   0			     ;AN000;dbcs table segment
	       DW   0			     ;AN068;SEH offset of font descriptor block
	       DW   0			     ;AN068;SEH segment of font descriptor block
	       DB   236 DUP(0)		     ;AN024;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; defined FRENCH keyboard
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
WR_SCB7        DW   SCB_WRAP		     ;AN000;option word one
	       DW   SCB_SKIP		     ;AN000;option word two
	       DW   SCB_NUMS		     ;AN000;option word three
	       DW   0			     ;AN068;SEH option word four
	       DW   SND_FREQ		     ;AN000;error beep frequency
	       DW   10			     ;AN000;upper left row
	       DW   LEFT_COL_SCROLL		    ;AN000;upper left column
	       DW   0			     ;AN000;relative upper left row
	       DW   0			     ;AN000;relative upper left column
	       DW   SCB_LIST7_W 	     ;AN000;line width
	       DW   SCB_LIST7_N 	     ;AN000;number of lines
	       DW   1			     ;AN000;number of element on top
	       DW   SCB_LIST7_N 	     ;AN000;number of elements
	       DW   1			     ;AN000;current element
	       DW   0			     ;AN000;maximun number of cols to scroll
	       DW   0			     ;AN000;display offset into opt strings
	       DW   1			     ;AN000;num list txt col offset in strg
	       DB   '.'                      ;AN000;numbered list separator
	       DW   0			     ;AN000;select keystroke string length
	       DW   0			     ;AN000;select keystroke string offset
	       DW   0			     ;AN000;select keystroke string segment
	       DW   0			     ;AN000;return/leave string length
	       DW   0			     ;AN000;return/leave string offset
	       DW   0			     ;AN000;return/leave string segment
	       DW   0			     ;AN000;return/erase string length
	       DW   0			     ;AN000;return/erase string offset
	       DW   0			     ;AN000;return/erase string segment
	       DW   WR_UAKEYSLEN	     ;AN000;up arrow string length
	       DW   WR_UAKEYS		     ;AN000;up arrow string offset
	       DW   0			     ;AN000;up arrow string segment
	       DW   WR_DAKEYSLEN	     ;AN000;down arrow string length
	       DW   WR_DAKEYS		     ;AN000;down arrow string offset
	       DW   0			     ;AN000;down arrow string segment
	       DW   0			     ;AN000;left arrow string length
	       DW   0			     ;AN000;left arrow string offset
	       DW   0			     ;AN000;left arrow string segment
	       DW   0			     ;AN000;right arrow string length
	       DW   0			     ;AN000;right arrow string offset
	       DW   0			     ;AN000;right arrow string segment
	       DW   0			     ;AN000;page-up string length
	       DW   0			     ;AN000;page-up string offset
	       DW   0			     ;AN000;page-up string segment
	       DW   0			     ;AN000;page-down string length
	       DW   0			     ;AN000;page-down string offset
	       DW   0			     ;AN000;page-down string segment
	       DW   WR_PIINDLEN 	     ;AN000;pointer indicator strg length
	       DW   WR_PIIND		     ;AN000;pointer indicator string offset
	       DW   0			     ;AN000;pointer indicator string segment
	       DW   1			     ;AN000;pointer ind txt col off into strg
	       DW   WR_AIINDLEN 	     ;AN000;active indicator strg length
	       DW   WR_AIIND		     ;AN000;active indicator string offset
	       DW   0			     ;AN000;active indicator string segment
	       DW   1			     ;AN000;active ind txt col off into stg
	       DW   WR_CIINDLEN 	     ;AN000;check mark text string length
	       DW   WR_CIIND		     ;AN000;check mark text string offset
	       DW   0			     ;AN000;check mark text string segment
	       DW   1			     ;AN000;check mark offset into opt strg
	       DW   WR_UIINDLEN 	     ;AN000;up indicator string length
	       DW   WR_UIIND		     ;AN000;up indicator string offset
	       DW   0			     ;AN000;up indicator string segment
	       DW   2			     ;AN000;up indicator row location
	       DW   1			     ;AN000;up indicator column location
	       DW   WR_DIINDLEN 	     ;AN000;down indicator string length
	       DW   WR_DIIND		     ;AN000;down indicator string offset
	       DW   0			     ;AN000;down indicator string segment
	       DW   2			     ;AN000;down indicator row location
	       DW   2			     ;AN000;down indicator column locaiton
	       DW   0			     ;AN000;left indicator string length
	       DW   0			     ;AN000;left indicator string offset
	       DW   0			     ;AN000;left indicator string segment
	       DW   0			     ;AN000;left indicator row location
	       DW   0			     ;AN000;left indicator column location
	       DW   0			     ;AN000;right indicator string length
	       DW   0			     ;AN000;right indicator string offset
	       DW   0			     ;AN000;right indicator string segment
	       DW   0			     ;AN000;right indicator row location
	       DW   0			     ;AN000;right indicator column locaiton
	       DW   WR_CIS		     ;AN000;normal color array offset
	       DW   0			     ;AN000;normal color array segment
	       DW   7			     ;AN000;logical color index number
	       DW   0			     ;AN000;number color index table entries
	       DW   0			     ;AN000;offset addr of color index table
	       DW   0			     ;AN000;segment addr of color index tabl
	       DW   WR_INDEX1		     ;AN000;index array offset
	       DW   0			     ;AN000;index array segment
	       DW   WR_SELECT_NUM	     ;AN000;element selection array offset
	       DW   0			     ;AN000;element selection array segment
	       DW   SSC_PTSB		     ;AN000;option array option word
	       DW   SCB_LIST7		     ;AN000;option array pointer offset
	       DW   0			     ;AN000;option array pointer segment
	       DW   SCB_LIST7_W 	     ;AN000;option array string length
	       DW   0			     ;AN000;option array string segment
	       DB   'A'                      ;AN000;option array string term char
	       DW   0			     ;AN000;keystroke
	       DW   0			     ;AN000;log vid buf offset override
	       DW   0			     ;AN000;log vid buf segment override
	       DW   0			     ;AN000;general purpose format hook opt
	       DW   0			     ;AN000;general purpose format hook opt
	       DW   0			     ;AN000;length of translation table
	       DW   0			     ;AN000;offset of translation table
	       DW   0			     ;AN000;segment of translation table
	       DW   0			     ;AN000;monocasing table offset
	       DW   0			     ;AN000;monocasing table segment
	       DW   0			     ;AN000;dbcs table length
	       DW   0			     ;AN000;dbcs table offset
	       DW   0			     ;AN000;dbcs table segment
	       DW   0			     ;AN068;SEH offset of font descriptor block
	       DW   0			     ;AN068;SEH segment of font descriptor block
	       DB   236 DUP(0)		     ;AN024;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; defined italian keyboard
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
WR_SCB8        DW   SCB_WRAP		     ;AN000;option word one
	       DW   SCB_SKIP		     ;AN000;option word two
	       DW   SCB_NUMS		     ;AN000;option word three
	       DW   0			     ;AN068;SEH option word four
	       DW   SND_FREQ		     ;AN000;error beep frequency
	       DW   10			     ;AN000;upper left row
	       DW   LEFT_COL_SCROLL		    ;AN000;upper left column
	       DW   0			     ;AN000;relative upper left row
	       DW   0			     ;AN000;relative upper left column
	       DW   SCB_LIST8_W 	     ;AN000;line width
	       DW   SCB_LIST8_N 	     ;AN000;number of lines
	       DW   1			     ;AN000;number of element on top
	       DW   SCB_LIST8_N 	     ;AN000;number of elements
	       DW   1			     ;AN000;current element
	       DW   0			     ;AN000;maximun number of cols to scroll
	       DW   0			     ;AN000;display offset into opt strings
	       DW   1			     ;AN000;num list txt col offset in strg
	       DB   '.'                      ;AN000;numbered list separator
	       DW   0			     ;AN000;select keystroke string length
	       DW   0			     ;AN000;select keystroke string offset
	       DW   0			     ;AN000;select keystroke string segment
	       DW   0			     ;AN000;return/leave string length
	       DW   0			     ;AN000;return/leave string offset
	       DW   0			     ;AN000;return/leave string segment
	       DW   0			     ;AN000;return/erase string length
	       DW   0			     ;AN000;return/erase string offset
	       DW   0			     ;AN000;return/erase string segment
	       DW   WR_UAKEYSLEN	     ;AN000;up arrow string length
	       DW   WR_UAKEYS		     ;AN000;up arrow string offset
	       DW   0			     ;AN000;up arrow string segment
	       DW   WR_DAKEYSLEN	     ;AN000;down arrow string length
	       DW   WR_DAKEYS		     ;AN000;down arrow string offset
	       DW   0			     ;AN000;down arrow string segment
	       DW   0			     ;AN000;left arrow string length
	       DW   0			     ;AN000;left arrow string offset
	       DW   0			     ;AN000;left arrow string segment
	       DW   0			     ;AN000;right arrow string length
	       DW   0			     ;AN000;right arrow string offset
	       DW   0			     ;AN000;right arrow string segment
	       DW   0			     ;AN000;page-up string length
	       DW   0			     ;AN000;page-up string offset
	       DW   0			     ;AN000;page-up string segment
	       DW   0			     ;AN000;page-down string length
	       DW   0			     ;AN000;page-down string offset
	       DW   0			     ;AN000;page-down string segment
	       DW   WR_PIINDLEN 	     ;AN000;pointer indicator strg length
	       DW   WR_PIIND		     ;AN000;pointer indicator string offset
	       DW   0			     ;AN000;pointer indicator string segment
	       DW   1			     ;AN000;pointer ind txt col off into strg
	       DW   WR_AIINDLEN 	     ;AN000;active indicator strg length
	       DW   WR_AIIND		     ;AN000;active indicator string offset
	       DW   0			     ;AN000;active indicator string segment
	       DW   1			     ;AN000;active ind txt col off into stg
	       DW   WR_CIINDLEN 	     ;AN000;check mark text string length
	       DW   WR_CIIND		     ;AN000;check mark text string offset
	       DW   0			     ;AN000;check mark text string segment
	       DW   1			     ;AN000;check mark offset into opt strg
	       DW   WR_UIINDLEN 	     ;AN000;up indicator string length
	       DW   WR_UIIND		     ;AN000;up indicator string offset
	       DW   0			     ;AN000;up indicator string segment
	       DW   2			     ;AN000;up indicator row location
	       DW   1			     ;AN000;up indicator column location
	       DW   WR_DIINDLEN 	     ;AN000;down indicator string length
	       DW   WR_DIIND		     ;AN000;down indicator string offset
	       DW   0			     ;AN000;down indicator string segment
	       DW   2			     ;AN000;down indicator row location
	       DW   2			     ;AN000;down indicator column locaiton
	       DW   0			     ;AN000;left indicator string length
	       DW   0			     ;AN000;left indicator string offset
	       DW   0			     ;AN000;left indicator string segment
	       DW   0			     ;AN000;left indicator row location
	       DW   0			     ;AN000;left indicator column location
	       DW   0			     ;AN000;right indicator string length
	       DW   0			     ;AN000;right indicator string offset
	       DW   0			     ;AN000;right indicator string segment
	       DW   0			     ;AN000;right indicator row location
	       DW   0			     ;AN000;right indicator column locaiton
	       DW   WR_CIS		     ;AN000;normal color array offset
	       DW   0			     ;AN000;normal color array segment
	       DW   8			     ;AN000;logical color index number
	       DW   0			     ;AN000;number color index table entries
	       DW   0			     ;AN000;offset addr of color index table
	       DW   0			     ;AN000;segment addr of color index tabl
	       DW   WR_INDEX1		     ;AN000;index array offset
	       DW   0			     ;AN000;index array segment
	       DW   WR_SELECT_NUM	     ;AN000;element selection array offset
	       DW   0			     ;AN000;element selection array segment
	       DW   SSC_PTSB		     ;AN000;option array option word
	       DW   SCB_LIST8		     ;AN000;option array pointer offset
	       DW   0			     ;AN000;option array pointer segment
	       DW   SCB_LIST8_W 	     ;AN000;option array string length
	       DW   0			     ;AN000;option array string segment
	       DB   'A'                      ;AN000;option array string term char
	       DW   0			     ;AN000;keystroke
	       DW   0			     ;AN000;log vid buf offset override
	       DW   0			     ;AN000;log vid buf segment override
	       DW   0			     ;AN000;general purpose format hook opt
	       DW   0			     ;AN000;general purpose format hook opt
	       DW   0			     ;AN000;length of translation table
	       DW   0			     ;AN000;offset of translation table
	       DW   0			     ;AN000;segment of translation table
	       DW   0			     ;AN000;monocasing table offset
	       DW   0			     ;AN000;monocasing table segment
	       DW   0			     ;AN000;dbcs table length
	       DW   0			     ;AN000;dbcs table offset
	       DW   0			     ;AN000;dbcs table segment
	       DW   0			     ;AN068;SEH offset of font descriptor block
	       DW   0			     ;AN068;SEH segment of font descriptor block
	       DB   236 DUP(0)		     ;AN024;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; defined UK keyboard
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
WR_SCB9        DW   SCB_WRAP		     ;AN000;option word one
	       DW   SCB_SKIP		     ;AN000;option word two
	       DW   SCB_NUMS		     ;AN000;option word three
	       DW   0			     ;AN068;SEH option word four
	       DW   SND_FREQ		     ;AN000;error beep frequency
	       DW   10			     ;AN000;upper left row
	       DW   LEFT_COL_SCROLL	     ;AN000;upper left column
	       DW   0			     ;AN000;relative upper left row
	       DW   0			     ;AN000;relative upper left column
	       DW   SCB_LIST9_W 	     ;AN000;line width
	       DW   SCB_LIST9_N 	     ;AN000;number of lines
	       DW   1			     ;AN000;number of element on top
	       DW   SCB_LIST9_N 	     ;AN000;number of elements
	       DW   1			     ;AN000;current element
	       DW   0			     ;AN000;maximun number of cols to scroll
	       DW   0			     ;AN000;display offset into opt strings
	       DW   1			     ;AN000;num list txt col offset in strg
	       DB   '.'                      ;AN000;numbered list separator
	       DW   0			     ;AN000;select keystroke string length
	       DW   0			     ;AN000;select keystroke string offset
	       DW   0			     ;AN000;select keystroke string segment
	       DW   0			     ;AN000;return/leave string length
	       DW   0			     ;AN000;return/leave string offset
	       DW   0			     ;AN000;return/leave string segment
	       DW   0			     ;AN000;return/erase string length
	       DW   0			     ;AN000;return/erase string offset
	       DW   0			     ;AN000;return/erase string segment
	       DW   WR_UAKEYSLEN	     ;AN000;up arrow string length
	       DW   WR_UAKEYS		     ;AN000;up arrow string offset
	       DW   0			     ;AN000;up arrow string segment
	       DW   WR_DAKEYSLEN	     ;AN000;down arrow string length
	       DW   WR_DAKEYS		     ;AN000;down arrow string offset
	       DW   0			     ;AN000;down arrow string segment
	       DW   0			     ;AN000;left arrow string length
	       DW   0			     ;AN000;left arrow string offset
	       DW   0			     ;AN000;left arrow string segment
	       DW   0			     ;AN000;right arrow string length
	       DW   0			     ;AN000;right arrow string offset
	       DW   0			     ;AN000;right arrow string segment
	       DW   0			     ;AN000;page-up string length
	       DW   0			     ;AN000;page-up string offset
	       DW   0			     ;AN000;page-up string segment
	       DW   0			     ;AN000;page-down string length
	       DW   0			     ;AN000;page-down string offset
	       DW   0			     ;AN000;page-down string segment
	       DW   WR_PIINDLEN 	     ;AN000;pointer indicator strg length
	       DW   WR_PIIND		     ;AN000;pointer indicator string offset
	       DW   0			     ;AN000;pointer indicator string segment
	       DW   1			     ;AN000;pointer ind txt col off into strg
	       DW   WR_AIINDLEN 	     ;AN000;active indicator strg length
	       DW   WR_AIIND		     ;AN000;active indicator string offset
	       DW   0			     ;AN000;active indicator string segment
	       DW   1			     ;AN000;active ind txt col off into stg
	       DW   WR_CIINDLEN 	     ;AN000;check mark text string length
	       DW   WR_CIIND		     ;AN000;check mark text string offset
	       DW   0			     ;AN000;check mark text string segment
	       DW   1			     ;AN000;check mark offset into opt strg
	       DW   WR_UIINDLEN 	     ;AN000;up indicator string length
	       DW   WR_UIIND		     ;AN000;up indicator string offset
	       DW   0			     ;AN000;up indicator string segment
	       DW   2			     ;AN000;up indicator row location
	       DW   1			     ;AN000;up indicator column location
	       DW   WR_DIINDLEN 	     ;AN000;down indicator string length
	       DW   WR_DIIND		     ;AN000;down indicator string offset
	       DW   0			     ;AN000;down indicator string segment
	       DW   2			     ;AN000;down indicator row location
	       DW   2			     ;AN000;down indicator column locaiton
	       DW   0			     ;AN000;left indicator string length
	       DW   0			     ;AN000;left indicator string offset
	       DW   0			     ;AN000;left indicator string segment
	       DW   0			     ;AN000;left indicator row location
	       DW   0			     ;AN000;left indicator column location
	       DW   0			     ;AN000;right indicator string length
	       DW   0			     ;AN000;right indicator string offset
	       DW   0			     ;AN000;right indicator string segment
	       DW   0			     ;AN000;right indicator row location
	       DW   0			     ;AN000;right indicator column locaiton
	       DW   WR_CIS		     ;AN000;normal color array offset
	       DW   0			     ;AN000;normal color array segment
	       DW   9			     ;AN000;logical color index number
	       DW   0			     ;AN000;number color index table entries
	       DW   0			     ;AN000;offset addr of color index table
	       DW   0			     ;AN000;segment addr of color index tabl
	       DW   WR_INDEX1		     ;AN000;index array offset
	       DW   0			     ;AN000;index array segment
	       DW   WR_SELECT_NUM	     ;AN000;element selection array offset
	       DW   0			     ;AN000;element selection array segment
	       DW   SSC_PTSB		     ;AN000;option array option word
	       DW   SCB_LIST9		     ;AN000;option array pointer offset
	       DW   0			     ;AN000;option array pointer segment
	       DW   SCB_LIST9_W 	     ;AN000;option array string length
	       DW   0			     ;AN000;option array string segment
	       DB   'A'                      ;AN000;option array string term char
	       DW   0			     ;AN000;keystroke
	       DW   0			     ;AN000;log vid buf offset override
	       DW   0			     ;AN000;log vid buf segment override
	       DW   0			     ;AN000;general purpose format hook opt
	       DW   0			     ;AN000;general purpose format hook opt
	       DW   0			     ;AN000;length of translation table
	       DW   0			     ;AN000;offset of translation table
	       DW   0			     ;AN000;segment of translation table
	       DW   0			     ;AN000;monocasing table offset
	       DW   0			     ;AN000;monocasing table segment
	       DW   0			     ;AN000;dbcs table length
	       DW   0			     ;AN000;dbcs table offset
	       DW   0			     ;AN000;dbcs table segment
	       DW   0			     ;AN068;SEH offset of font descriptor block
	       DW   0			     ;AN068;SEH segment of font descriptor block
	       DB   236 DUP(0)		     ;AN024;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; select drive b: or c:
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
WR_SCB10       DW   SCB_WRAP		     ;AN000;option word one
	       DW   SCB_SKIP		     ;AN000;option word two
	       DW   SCB_NUMS		     ;AN000;option word three
	       DW   0			     ;AN068;SEH option word four
	       DW   SND_FREQ		     ;AN000;error beep frequency
	       DW   8			     ;AN000;upper left row
	       DW   LEFT_COL_SCROLL		    ;AN000;upper left column
	       DW   0			     ;AN000;relative upper left row
	       DW   0			     ;AN000;relative upper left column
	       DW   SCB_LIST10_W	     ;AN000;line width
	       DW   SCB_LIST10_N	     ;AN000;number of lines
	       DW   1			     ;AN000;number of element on top
	       DW   SCB_LIST10_N	     ;AN000;number of elements
	       DW   1			     ;AN000;current element
	       DW   0			     ;AN000;maximun number of cols to scroll
	       DW   0			     ;AN000;display offset into opt strings
	       DW   1			     ;AN000;num list txt col offset in strg
	       DB   '.'                      ;AN000;numbered list separator
	       DW   0			     ;AN000;select keystroke string length
	       DW   0			     ;AN000;select keystroke string offset
	       DW   0			     ;AN000;select keystroke string segment
	       DW   0			     ;AN000;return/leave string length
	       DW   0			     ;AN000;return/leave string offset
	       DW   0			     ;AN000;return/leave string segment
	       DW   0			     ;AN000;return/erase string length
	       DW   0			     ;AN000;return/erase string offset
	       DW   0			     ;AN000;return/erase string segment
	       DW   WR_UAKEYSLEN	     ;AN000;up arrow string length
	       DW   WR_UAKEYS		     ;AN000;up arrow string offset
	       DW   0			     ;AN000;up arrow string segment
	       DW   WR_DAKEYSLEN	     ;AN000;down arrow string length
	       DW   WR_DAKEYS		     ;AN000;down arrow string offset
	       DW   0			     ;AN000;down arrow string segment
	       DW   0			     ;AN000;left arrow string length
	       DW   0			     ;AN000;left arrow string offset
	       DW   0			     ;AN000;left arrow string segment
	       DW   0			     ;AN000;right arrow string length
	       DW   0			     ;AN000;right arrow string offset
	       DW   0			     ;AN000;right arrow string segment
	       DW   0			     ;AN000;page-up string length
	       DW   0			     ;AN000;page-up string offset
	       DW   0			     ;AN000;page-up string segment
	       DW   0			     ;AN000;page-down string length
	       DW   0			     ;AN000;page-down string offset
	       DW   0			     ;AN000;page-down string segment
	       DW   WR_PIINDLEN 	     ;AN000;pointer indicator strg length
	       DW   WR_PIIND		     ;AN000;pointer indicator string offset
	       DW   0			     ;AN000;pointer indicator string segment
	       DW   1			     ;AN000;pointer ind txt col off into strg
	       DW   WR_AIINDLEN 	     ;AN000;active indicator strg length
	       DW   WR_AIIND		     ;AN000;active indicator string offset
	       DW   0			     ;AN000;active indicator string segment
	       DW   1			     ;AN000;active ind txt col off into stg
	       DW   WR_CIINDLEN 	     ;AN000;check mark text string length
	       DW   WR_CIIND		     ;AN000;check mark text string offset
	       DW   0			     ;AN000;check mark text string segment
	       DW   1			     ;AN000;check mark offset into opt strg
	       DW   WR_UIINDLEN 	     ;AN000;up indicator string length
	       DW   WR_UIIND		     ;AN000;up indicator string offset
	       DW   0			     ;AN000;up indicator string segment
	       DW   2			     ;AN000;up indicator row location
	       DW   1			     ;AN000;up indicator column location
	       DW   WR_DIINDLEN 	     ;AN000;down indicator string length
	       DW   WR_DIIND		     ;AN000;down indicator string offset
	       DW   0			     ;AN000;down indicator string segment
	       DW   2			     ;AN000;down indicator row location
	       DW   2			     ;AN000;down indicator column locaiton
	       DW   0			     ;AN000;left indicator string length
	       DW   0			     ;AN000;left indicator string offset
	       DW   0			     ;AN000;left indicator string segment
	       DW   0			     ;AN000;left indicator row location
	       DW   0			     ;AN000;left indicator column location
	       DW   0			     ;AN000;right indicator string length
	       DW   0			     ;AN000;right indicator string offset
	       DW   0			     ;AN000;right indicator string segment
	       DW   0			     ;AN000;right indicator row location
	       DW   0			     ;AN000;right indicator column locaiton
	       DW   WR_CIS		     ;AN000;normal color array offset
	       DW   0			     ;AN000;normal color array segment
	       DW   10			     ;AN000;logical color index number
	       DW   0			     ;AN000;number color index table entries
	       DW   0			     ;AN000;offset addr of color index table
	       DW   0			     ;AN000;segment addr of color index tabl
	       DW   WR_INDEX1		     ;AN000;index array offset
	       DW   0			     ;AN000;index array segment
	       DW   WR_SELECT_NUM	     ;AN000;element selection array offset
	       DW   0			     ;AN000;element selection array segment
	       DW   SSC_PTSB		     ;AN000;option array option word
	       DW   SCB_LIST10		     ;AN000;option array pointer offset
	       DW   0			     ;AN000;option array pointer segment
	       DW   SCB_LIST10_W	     ;AN000;option array string length
	       DW   0			     ;AN000;option array string segment
	       DB   'A'                      ;AN000;option array string term char
	       DW   0			     ;AN000;keystroke
	       DW   0			     ;AN000;log vid buf offset override
	       DW   0			     ;AN000;log vid buf segment override
	       DW   0			     ;AN000;general purpose format hook opt
	       DW   0			     ;AN000;general purpose format hook opt
	       DW   0			     ;AN000;length of translation table
	       DW   0			     ;AN000;offset of translation table
	       DW   0			     ;AN000;segment of translation table
	       DW   0			     ;AN000;monocasing table offset
	       DW   0			     ;AN000;monocasing table segment
	       DW   0			     ;AN000;dbcs table length
	       DW   0			     ;AN000;dbcs table offset
	       DW   0			     ;AN000;dbcs table segment
	       DW   0			     ;AN068;SEH offset of font descriptor block
	       DW   0			     ;AN068;SEH segment of font descriptor block
	       DB   236 DUP(0)		     ;AN024;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; select printer type
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
WR_SCB11       DW   0			     ;AN000;option word one
	       DW   scb_uind		     ;AN000;option word two
	       DW   0			     ;AN000;option word three
	       DW   0			     ;AN068;SEH option word four
	       DW   SND_FREQ		     ;AN000;error beep frequency
	       DW   11			     ;AN000;upper left row
	       DW   LEFT_COL_SCROLL		    ;AN000;upper left column
	       DW   0			     ;AN000;relative upper left row
	       DW   0			     ;AN000;relative upper left column
	       DW   SCB_LIST11_W	     ;AN000;line width
	       DW   10			     ;AN000;number of lines
	       DW   1			     ;AN000;number of element on top
	       DW   SCB_LIST11_N	     ;AN000;number of elements
	       DW   1			     ;AN000;current element
	       DW   0			     ;AN000;maximun number of cols to scroll
	       DW   0			     ;AN000;display offset into opt strings
	       DW   1			     ;AN000;num list txt col offset in strg
	       DB   '.'                      ;AN000;numbered list separator
	       DW   0			     ;AN000;select keystroke string length
	       DW   0			     ;AN000;select keystroke string offset
	       DW   0			     ;AN000;select keystroke string segment
	       DW   0			     ;AN000;return/leave string length
	       DW   0			     ;AN000;return/leave string offset
	       DW   0			     ;AN000;return/leave string segment
	       DW   0			     ;AN000;return/erase string length
	       DW   0			     ;AN000;return/erase string offset
	       DW   0			     ;AN000;return/erase string segment
	       DW   WR_UAKEYSLEN	     ;AN000;up arrow string length
	       DW   WR_UAKEYS		     ;AN000;up arrow string offset
	       DW   0			     ;AN000;up arrow string segment
	       DW   WR_DAKEYSLEN	     ;AN000;down arrow string length
	       DW   WR_DAKEYS		     ;AN000;down arrow string offset
	       DW   0			     ;AN000;down arrow string segment
	       DW   0			     ;AN000;left arrow string length
	       DW   0			     ;AN000;left arrow string offset
	       DW   0			     ;AN000;left arrow string segment
	       DW   0			     ;AN000;right arrow string length
	       DW   0			     ;AN000;right arrow string offset
	       DW   0			     ;AN000;right arrow string segment
	       DW   0			     ;AN000;page-up string length
	       DW   0			     ;AN000;page-up string offset
	       DW   0			     ;AN000;page-up string segment
	       DW   0			     ;AN000;page-down string length
	       DW   0			     ;AN000;page-down string offset
	       DW   0			     ;AN000;page-down string segment
	       DW   WR_PIINDLEN 	     ;AN000;pointer indicator strg length
	       DW   WR_PIIND		     ;AN000;pointer indicator string offset
	       DW   0			     ;AN000;pointer indicator string segment
	       DW   1			     ;AN000;pointer ind txt col off into strg
	       DW   WR_AIINDLEN 	     ;AN000;active indicator strg length
	       DW   WR_AIIND		     ;AN000;active indicator string offset
	       DW   0			     ;AN000;active indicator string segment
	       DW   1			     ;AN000;active ind txt col off into stg
	       DW   WR_CIINDLEN 	     ;AN000;check mark text string length
	       DW   WR_CIIND		     ;AN000;check mark text string offset
	       DW   0			     ;AN000;check mark text string segment
	       DW   1			     ;AN000;check mark offset into opt strg
	       DW   WR_UIINDLEN 	     ;AN000;up indicator string length
	       DW   WR_UIIND		     ;AN000;up indicator string offset
	       DW   0			     ;AN000;up indicator string segment
	       DW   9			     ;AN000;up indicator row location
	       DW   64			     ;AN000;up indicator column location
	       DW   WR_DIINDLEN 	     ;AN000;down indicator string length
	       DW   WR_DIIND		     ;AN000;down indicator string offset
	       DW   0			     ;AN000;down indicator string segment
	       DW   9			     ;AN000;down indicator row location
	       DW   66			     ;AN000;down indicator column locaiton
	       DW   0			     ;AN000;left indicator string length
	       DW   0			     ;AN000;left indicator string offset
	       DW   0			     ;AN000;left indicator string segment
	       DW   0			     ;AN000;left indicator row location
	       DW   0			     ;AN000;left indicator column location
	       DW   0			     ;AN000;right indicator string length
	       DW   0			     ;AN000;right indicator string offset
	       DW   0			     ;AN000;right indicator string segment
	       DW   0			     ;AN000;right indicator row location
	       DW   0			     ;AN000;right indicator column locaiton
	       DW   WR_CIS		     ;AN000;normal color array offset
	       DW   0			     ;AN000;normal color array segment
	       DW   1			     ;AN000;logical color index number
	       DW   16			     ;AN000;number color index table entries
	       DW   WR_CIS		     ;AN000;offset addr of color index table
	       DW   0			     ;AN000;segment addr of color index tabl
	       DW   WR_INDEX1		     ;AN000;index array offset
	       DW   0			     ;AN000;index array segment
	       DW   WR_SELECT		     ;AN000;element selection array offset
	       DW   0			     ;AN000;element selection array segment
	       DW   SSC_PTSB		     ;AN000;option array option word
	       DW   SCB_LIST11		     ;AN000;option array pointer offset
	       DW   0			     ;AN000;option array pointer segment
	       DW   SCB_LIST11_W	     ;AN000;option array string length
	       DW   0			     ;AN000;option array string segment
	       DB   'A'                      ;AN000;option array string term char
	       DW   0			     ;AN000;keystroke
	       DW   0			     ;AN000;log vid buf offset override
	       DW   0			     ;AN000;log vid buf segment override
	       DW   0			     ;AN000;general purpose format hook opt
	       DW   0			     ;AN000;general purpose format hook opt
	       DW   0			     ;AN000;length of translation table
	       DW   0			     ;AN000;offset of translation table
	       DW   0			     ;AN000;segment of translation table
	       DW   0			     ;AN000;monocasing table offset
	       DW   0			     ;AN000;monocasing table segment
	       DW   0			     ;AN000;dbcs table length
	       DW   0			     ;AN000;dbcs table offset
	       DW   0			     ;AN000;dbcs table segment
	       DW   0			     ;AN068;SEH offset of font descriptor block
	       DW   0			     ;AN068;SEH segment of font descriptor block
	       DB   236 DUP(0)		     ;AN024;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; PARALLEL PRINTER PORT
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
WR_SCB12       DW   SCB_WRAP		     ;AN000;option word one
	       DW   SCB_SKIP		     ;AN000;option word two
	       DW   SCB_NUMS		     ;AN000;option word three
	       DW   0			     ;AN068;SEH option word four
	       DW   SND_FREQ		     ;AN000;error beep frequency
	       DW   9			     ;AN000;upper left row
	       DW   LEFT_COL_SCROLL	     ;AN000;upper left column
	       DW   0			     ;AN000;relative upper left row
	       DW   0			     ;AN000;relative upper left column
	       DW   SCB_LIST12_W	     ;AN000;line width
	       DW   SCB_LIST12_N	     ;AN000;number of lines
	       DW   1			     ;AN000;number of element on top
	       DW   SCB_LIST12_N	     ;AN000;number of elements
	       DW   1			     ;AN000;current element
	       DW   0			     ;AN000;maximun number of cols to scroll
	       DW   0			     ;AN000;display offset into opt strings
	       DW   1			     ;AN000;num list txt col offset in strg
	       DB   '.'                      ;AN000;numbered list separator
	       DW   0			     ;AN000;select keystroke string length
	       DW   0			     ;AN000;select keystroke string offset
	       DW   0			     ;AN000;select keystroke string segment
	       DW   0			     ;AN000;return/leave string length
	       DW   0			     ;AN000;return/leave string offset
	       DW   0			     ;AN000;return/leave string segment
	       DW   0			     ;AN000;return/erase string length
	       DW   0			     ;AN000;return/erase string offset
	       DW   0			     ;AN000;return/erase string segment
	       DW   WR_UAKEYSLEN	     ;AN000;up arrow string length
	       DW   WR_UAKEYS		     ;AN000;up arrow string offset
	       DW   0			     ;AN000;up arrow string segment
	       DW   WR_DAKEYSLEN	     ;AN000;down arrow string length
	       DW   WR_DAKEYS		     ;AN000;down arrow string offset
	       DW   0			     ;AN000;down arrow string segment
	       DW   0			     ;AN000;left arrow string length
	       DW   0			     ;AN000;left arrow string offset
	       DW   0			     ;AN000;left arrow string segment
	       DW   0			     ;AN000;right arrow string length
	       DW   0			     ;AN000;right arrow string offset
	       DW   0			     ;AN000;right arrow string segment
	       DW   0			     ;AN000;page-up string length
	       DW   0			     ;AN000;page-up string offset
	       DW   0			     ;AN000;page-up string segment
	       DW   0			     ;AN000;page-down string length
	       DW   0			     ;AN000;page-down string offset
	       DW   0			     ;AN000;page-down string segment
	       DW   WR_PIINDLEN 	     ;AN000;pointer indicator strg length
	       DW   WR_PIIND		     ;AN000;pointer indicator string offset
	       DW   0			     ;AN000;pointer indicator string segment
	       DW   1			     ;AN000;pointer ind txt col off into strg
	       DW   WR_AIINDLEN 	     ;AN000;active indicator strg length
	       DW   WR_AIIND		     ;AN000;active indicator string offset
	       DW   0			     ;AN000;active indicator string segment
	       DW   1			     ;AN000;active ind txt col off into stg
	       DW   WR_CIINDLEN 	     ;AN000;check mark text string length
	       DW   WR_CIIND		     ;AN000;check mark text string offset
	       DW   0			     ;AN000;check mark text string segment
	       DW   1			     ;AN000;check mark offset into opt strg
	       DW   WR_UIINDLEN 	     ;AN000;up indicator string length
	       DW   WR_UIIND		     ;AN000;up indicator string offset
	       DW   0			     ;AN000;up indicator string segment
	       DW   2			     ;AN000;up indicator row location
	       DW   1			     ;AN000;up indicator column location
	       DW   WR_DIINDLEN 	     ;AN000;down indicator string length
	       DW   WR_DIIND		     ;AN000;down indicator string offset
	       DW   0			     ;AN000;down indicator string segment
	       DW   2			     ;AN000;down indicator row location
	       DW   2			     ;AN000;down indicator column locaiton
	       DW   0			     ;AN000;left indicator string length
	       DW   0			     ;AN000;left indicator string offset
	       DW   0			     ;AN000;left indicator string segment
	       DW   0			     ;AN000;left indicator row location
	       DW   0			     ;AN000;left indicator column location
	       DW   0			     ;AN000;right indicator string length
	       DW   0			     ;AN000;right indicator string offset
	       DW   0			     ;AN000;right indicator string segment
	       DW   0			     ;AN000;right indicator row location
	       DW   0			     ;AN000;right indicator column locaiton
	       DW   WR_CIS		     ;AN000;normal color array offset
	       DW   0			     ;AN000;normal color array segment
	       DW   1			     ;AN000;logical color index number
	       DW   16			     ;AN000;number color index table entries
	       DW   WR_CIS		     ;AN000;offset addr of color index table
	       DW   0			     ;AN000;segment addr of color index tabl
	       DW   WR_INDEX1		     ;AN000;index array offset
	       DW   0			     ;AN000;index array segment
	       DW   WR_SELECT_NUM	     ;AN000;element selection array offset
	       DW   0			     ;AN000;element selection array segment
	       DW   SSC_PTSB		     ;AN000;option array option word
	       DW   SCB_LIST12		     ;AN000;option array pointer offset
	       DW   0			     ;AN000;option array pointer segment
	       DW   SCB_LIST12_W	     ;AN000;option array string length
	       DW   0			     ;AN000;option array string segment
	       DB   'A'                      ;AN000;option array string term char
	       DW   0			     ;AN000;keystroke
	       DW   0			     ;AN000;log vid buf offset override
	       DW   0			     ;AN000;log vid buf segment override
	       DW   0			     ;AN000;general purpose format hook opt
	       DW   0			     ;AN000;general purpose format hook opt
	       DW   0			     ;AN000;length of translation table
	       DW   0			     ;AN000;offset of translation table
	       DW   0			     ;AN000;segment of translation table
	       DW   0			     ;AN000;monocasing table offset
	       DW   0			     ;AN000;monocasing table segment
	       DW   0			     ;AN000;dbcs table length
	       DW   0			     ;AN000;dbcs table offset
	       DW   0			     ;AN000;dbcs table segment
	       DW   0			     ;AN068;SEH offset of font descriptor block
	       DW   0			     ;AN068;SEH segment of font descriptor block
	       DB   236 DUP(0)		     ;AN024;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; serial port
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
WR_SCB13       DW   SCB_WRAP		     ;AN000;option word one
	       DW   SCB_SKIP		     ;AN000;option word two
	       DW   SCB_NUMS		     ;AN000;option word three
	       DW   0			     ;AN068;SEH option word four
	       DW   SND_FREQ		     ;AN000;error beep frequency
	       DW   8			     ;AN000;upper left row
	       DW   LEFT_COL_SCROLL		    ;AN000;upper left column
	       DW   0			     ;AN000;relative upper left row
	       DW   0			     ;AN000;relative upper left column
	       DW   SCB_LIST13_W	     ;AN000;line width
	       DW   SCB_LIST13_N	     ;AN000;number of lines
	       DW   1			     ;AN000;number of element on top
	       DW   SCB_LIST13_N	     ;AN000;number of elements
	       DW   1			     ;AN000;current element
	       DW   0			     ;AN000;maximun number of cols to scroll
	       DW   0			     ;AN000;display offset into opt strings
	       DW   1			     ;AN000;num list txt col offset in strg
	       DB   '.'                      ;AN000;numbered list separator
	       DW   0			     ;AN000;select keystroke string length
	       DW   0			     ;AN000;select keystroke string offset
	       DW   0			     ;AN000;select keystroke string segment
	       DW   0			     ;AN000;return/leave string length
	       DW   0			     ;AN000;return/leave string offset
	       DW   0			     ;AN000;return/leave string segment
	       DW   0			     ;AN000;return/erase string length
	       DW   0			     ;AN000;return/erase string offset
	       DW   0			     ;AN000;return/erase string segment
	       DW   WR_UAKEYSLEN	     ;AN000;up arrow string length
	       DW   WR_UAKEYS		     ;AN000;up arrow string offset
	       DW   0			     ;AN000;up arrow string segment
	       DW   WR_DAKEYSLEN	     ;AN000;down arrow string length
	       DW   WR_DAKEYS		     ;AN000;down arrow string offset
	       DW   0			     ;AN000;down arrow string segment
	       DW   0			     ;AN000;left arrow string length
	       DW   0			     ;AN000;left arrow string offset
	       DW   0			     ;AN000;left arrow string segment
	       DW   0			     ;AN000;right arrow string length
	       DW   0			     ;AN000;right arrow string offset
	       DW   0			     ;AN000;right arrow string segment
	       DW   0			     ;AN000;page-up string length
	       DW   0			     ;AN000;page-up string offset
	       DW   0			     ;AN000;page-up string segment
	       DW   0			     ;AN000;page-down string length
	       DW   0			     ;AN000;page-down string offset
	       DW   0			     ;AN000;page-down string segment
	       DW   WR_PIINDLEN 	     ;AN000;pointer indicator strg length
	       DW   WR_PIIND		     ;AN000;pointer indicator string offset
	       DW   0			     ;AN000;pointer indicator string segment
	       DW   1			     ;AN000;pointer ind txt col off into strg
	       DW   WR_AIINDLEN 	     ;AN000;active indicator strg length
	       DW   WR_AIIND		     ;AN000;active indicator string offset
	       DW   0			     ;AN000;active indicator string segment
	       DW   1			     ;AN000;active ind txt col off into stg
	       DW   WR_CIINDLEN 	     ;AN000;check mark text string length
	       DW   WR_CIIND		     ;AN000;check mark text string offset
	       DW   0			     ;AN000;check mark text string segment
	       DW   1			     ;AN000;check mark offset into opt strg
	       DW   WR_UIINDLEN 	     ;AN000;up indicator string length
	       DW   WR_UIIND		     ;AN000;up indicator string offset
	       DW   0			     ;AN000;up indicator string segment
	       DW   2			     ;AN000;up indicator row location
	       DW   1			     ;AN000;up indicator column location
	       DW   WR_DIINDLEN 	     ;AN000;down indicator string length
	       DW   WR_DIIND		     ;AN000;down indicator string offset
	       DW   0			     ;AN000;down indicator string segment
	       DW   2			     ;AN000;down indicator row location
	       DW   2			     ;AN000;down indicator column locaiton
	       DW   0			     ;AN000;left indicator string length
	       DW   0			     ;AN000;left indicator string offset
	       DW   0			     ;AN000;left indicator string segment
	       DW   0			     ;AN000;left indicator row location
	       DW   0			     ;AN000;left indicator column location
	       DW   0			     ;AN000;right indicator string length
	       DW   0			     ;AN000;right indicator string offset
	       DW   0			     ;AN000;right indicator string segment
	       DW   0			     ;AN000;right indicator row location
	       DW   0			     ;AN000;right indicator column locaiton
	       DW   WR_CIS		     ;AN000;normal color array offset
	       DW   0			     ;AN000;normal color array segment
	       DW   1			     ;AN000;logical color index number
	       DW   16			     ;AN000;number color index table entries
	       DW   WR_CIS		     ;AN000;offset addr of color index table
	       DW   0			     ;AN000;segment addr of color index tabl
	       DW   WR_INDEX1		     ;AN000;index array offset
	       DW   0			     ;AN000;index array segment
	       DW   WR_SELECT		     ;AN000;element selection array offset
	       DW   0			     ;AN000;element selection array segment
	       DW   SSC_PTSB		     ;AN000;option array option word
	       DW   SCB_LIST13		     ;AN000;option array pointer offset
	       DW   0			     ;AN000;option array pointer segment
	       DW   SCB_LIST13_W	     ;AN000;option array string length
	       DW   0			     ;AN000;option array string segment
	       DB   'A'                      ;AN000;option array string term char
	       DW   0			     ;AN000;keystroke
	       DW   0			     ;AN000;log vid buf offset override
	       DW   0			     ;AN000;log vid buf segment override
	       DW   0			     ;AN000;general purpose format hook opt
	       DW   0			     ;AN000;general purpose format hook opt
	       DW   0			     ;AN000;length of translation table
	       DW   0			     ;AN000;offset of translation table
	       DW   0			     ;AN000;segment of translation table
	       DW   0			     ;AN000;monocasing table offset
	       DW   0			     ;AN000;monocasing table segment
	       DW   0			     ;AN000;dbcs table length
	       DW   0			     ;AN000;dbcs table offset
	       DW   0			     ;AN000;dbcs table segment
	       DW   0			     ;AN068;SEH offset of font descriptor block
	       DW   0			     ;AN068;SEH segment of font descriptor block
	       DB   236 DUP(0)		     ;AN024;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; parallel redirection
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
WR_SCB14       DW   SCB_WRAP		     ;AN000;option word one
	       DW   SCB_SKIP		     ;AN000;option word two
	       DW   SCB_NUMS		     ;AN000;option word three
	       DW   0			     ;AN068;SEH option word four
	       DW   SND_FREQ		     ;AN000;error beep frequency
	       DW   17			     ;AN000;upper left row
	       DW   LEFT_COL_SCROLL		    ;AN000;upper left column
	       DW   0			     ;AN000;relative upper left row
	       DW   0			     ;AN000;relative upper left column
	       DW   SCB_LIST14_W	     ;AN000;line width
	       DW   SCB_LIST14_N	     ;AN000;number of lines
	       DW   1			     ;AN000;number of element on top
	       DW   SCB_LIST14_N	     ;AN000;number of elements
	       DW   1			     ;AN000;current element
	       DW   0			     ;AN000;maximun number of cols to scroll
	       DW   0			     ;AN000;display offset into opt strings
	       DW   1			     ;AN000;num list txt col offset in strg
	       DB   '.'                      ;AN000;numbered list separator
	       DW   0			     ;AN000;select keystroke string length
	       DW   0			     ;AN000;select keystroke string offset
	       DW   0			     ;AN000;select keystroke string segment
	       DW   0			     ;AN000;return/leave string length
	       DW   0			     ;AN000;return/leave string offset
	       DW   0			     ;AN000;return/leave string segment
	       DW   0			     ;AN000;return/erase string length
	       DW   0			     ;AN000;return/erase string offset
	       DW   0			     ;AN000;return/erase string segment
	       DW   WR_UAKEYSLEN	     ;AN000;up arrow string length
	       DW   WR_UAKEYS		     ;AN000;up arrow string offset
	       DW   0			     ;AN000;up arrow string segment
	       DW   WR_DAKEYSLEN	     ;AN000;down arrow string length
	       DW   WR_DAKEYS		     ;AN000;down arrow string offset
	       DW   0			     ;AN000;down arrow string segment
	       DW   0			     ;AN000;left arrow string length
	       DW   0			     ;AN000;left arrow string offset
	       DW   0			     ;AN000;left arrow string segment
	       DW   0			     ;AN000;right arrow string length
	       DW   0			     ;AN000;right arrow string offset
	       DW   0			     ;AN000;right arrow string segment
	       DW   WR_PUKEYSLEN	     ;AN000;page-up string length
	       DW   WR_PUKEYS		     ;AN000;page-up string offset
	       DW   0			     ;AN000;page-up string segment
	       DW   WR_PDKEYSLEN	     ;AN000;page-down string length
	       DW   WR_PDKEYS		     ;AN000;page-down string offset
	       DW   0			     ;AN000;page-down string segment
	       DW   WR_PIINDLEN 	     ;AN000;pointer indicator strg length
	       DW   WR_PIIND		     ;AN000;pointer indicator string offset
	       DW   0			     ;AN000;pointer indicator string segment
	       DW   1			     ;AN000;pointer ind txt col off into strg
	       DW   WR_AIINDLEN 	     ;AN000;active indicator strg length
	       DW   WR_AIIND		     ;AN000;active indicator string offset
	       DW   0			     ;AN000;active indicator string segment
	       DW   1			     ;AN000;active ind txt col off into stg
	       DW   WR_CIINDLEN 	     ;AN000;check mark text string length
	       DW   WR_CIIND		     ;AN000;check mark text string offset
	       DW   0			     ;AN000;check mark text string segment
	       DW   1			     ;AN000;check mark offset into opt strg
	       DW   WR_UIINDLEN 	     ;AN000;up indicator string length
	       DW   WR_UIIND		     ;AN000;up indicator string offset
	       DW   0			     ;AN000;up indicator string segment
	       DW   2			     ;AN000;up indicator row location
	       DW   1			     ;AN000;up indicator column location
	       DW   WR_DIINDLEN 	     ;AN000;down indicator string length
	       DW   WR_DIIND		     ;AN000;down indicator string offset
	       DW   0			     ;AN000;down indicator string segment
	       DW   2			     ;AN000;down indicator row location
	       DW   2			     ;AN000;down indicator column locaiton
	       DW   0			     ;AN000;left indicator string length
	       DW   0			     ;AN000;left indicator string offset
	       DW   0			     ;AN000;left indicator string segment
	       DW   0			     ;AN000;left indicator row location
	       DW   0			     ;AN000;left indicator column location
	       DW   0			     ;AN000;right indicator string length
	       DW   0			     ;AN000;right indicator string offset
	       DW   0			     ;AN000;right indicator string segment
	       DW   0			     ;AN000;right indicator row location
	       DW   0			     ;AN000;right indicator column locaiton
	       DW   0			     ;AN000;normal color array offset
	       DW   0			     ;AN000;normal color array segment
	       DW   1			     ;AN000;logical color index number
	       DW   16			     ;AN000;number color index table entries
	       DW   WR_CIS		     ;AN000;offset addr of color index table
	       DW   0			     ;AN000;segment addr of color index tabl
	       DW   WR_INDEX1		     ;AN000;index array offset
	       DW   0			     ;AN000;index array segment
	       DW   WR_SELECT		     ;AN000;element selection array offset
	       DW   0			     ;AN000;element selection array segment
	       DW   SSC_PTSB		     ;AN000;option array option word
	       DW   SCB_LIST14		     ;AN000;option array pointer offset
	       DW   0			     ;AN000;option array pointer segment
	       DW   SCB_LIST14_W	     ;AN000;option array string length
	       DW   0			     ;AN000;option array string segment
	       DB   'A'                      ;AN000;option array string term char
	       DW   0			     ;AN000;keystroke
	       DW   0			     ;AN000;log vid buf offset override
	       DW   0			     ;AN000;log vid buf segment override
	       DW   0			     ;AN000;general purpose format hook opt
	       DW   0			     ;AN000;general purpose format hook opt
	       DW   0			     ;AN000;length of translation table
	       DW   0			     ;AN000;offset of translation table
	       DW   0			     ;AN000;segment of translation table
	       DW   0			     ;AN000;monocasing table offset
	       DW   0			     ;AN000;monocasing table segment
	       DW   0			     ;AN000;dbcs table length
	       DW   0			     ;AN000;dbcs table offset
	       DW   0			     ;AN000;dbcs table segment
	       DW   0			     ;AN068;SEH offset of font descriptor block
	       DW   0			     ;AN068;SEH segment of font descriptor block
	       DB   236 DUP(0)		     ;AN024;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; review selections
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
WR_SCB15       DW   SCB_WRAP		     ;AN000;option word one
	       DW   SCB_SKIP		     ;AN000;option word two
	       DW   SCB_NUMS		     ;AN000;option word three
	       DW   0			     ;AN068;SEH option word four
	       DW   SND_FREQ		     ;AN000;error beep frequency
	       DW   11			     ;AC079;SEH ;AN000;upper left row
	       DW   LEFT_COL_SCROLL	     ;AN000;upper left column
	       DW   0			     ;AN000;relative upper left row
	       DW   0			     ;AN000;relative upper left column
	       DW   SCB_LIST15_W	     ;AN000;line width
	       DW   SCB_LIST15_N	     ;AN000;number of lines
	       DW   1			     ;AN000;number of element on top
	       DW   SCB_LIST15_N	     ;AN000;number of elements
	       DW   1			     ;AN000;current element
	       DW   0			     ;AN000;maximun number of cols to scroll
	       DW   0			     ;AN000;display offset into opt strings
	       DW   1			     ;AN000;num list txt col offset in strg
	       DB   '.'                      ;AN000;numbered list separator
	       DW   0			     ;AN000;select keystroke string length
	       DW   0			     ;AN000;select keystroke string offset
	       DW   0			     ;AN000;select keystroke string segment
	       DW   0			     ;AN000;return/leave string length
	       DW   0			     ;AN000;return/leave string offset
	       DW   0			     ;AN000;return/leave string segment
	       DW   0			     ;AN000;return/erase string length
	       DW   0			     ;AN000;return/erase string offset
	       DW   0			     ;AN000;return/erase string segment
	       DW   WR_UAKEYSLEN	     ;AN000;up arrow string length
	       DW   WR_UAKEYS		     ;AN000;up arrow string offset
	       DW   0			     ;AN000;up arrow string segment
	       DW   WR_DAKEYSLEN	     ;AN000;down arrow string length
	       DW   WR_DAKEYS		     ;AN000;down arrow string offset
	       DW   0			     ;AN000;down arrow string segment
	       DW   0			     ;AN000;left arrow string length
	       DW   0			     ;AN000;left arrow string offset
	       DW   0			     ;AN000;left arrow string segment
	       DW   0			     ;AN000;right arrow string length
	       DW   0			     ;AN000;right arrow string offset
	       DW   0			     ;AN000;right arrow string segment
	       DW   0			     ;AN000;page-up string length
	       DW   0			     ;AN000;page-up string offset
	       DW   0			     ;AN000;page-up string segment
	       DW   0			     ;AN000;page-down string length
	       DW   0			     ;AN000;page-down string offset
	       DW   0			     ;AN000;page-down string segment
	       DW   WR_PIINDLEN 	     ;AN000;pointer indicator strg length
	       DW   WR_PIIND		     ;AN000;pointer indicator string offset
	       DW   0			     ;AN000;pointer indicator string segment
	       DW   1			     ;AN000;pointer ind txt col off into strg
	       DW   WR_AIINDLEN 	     ;AN000;active indicator strg length
	       DW   WR_AIIND		     ;AN000;active indicator string offset
	       DW   0			     ;AN000;active indicator string segment
	       DW   1			     ;AN000;active ind txt col off into stg
	       DW   WR_CIINDLEN 	     ;AN000;check mark text string length
	       DW   WR_CIIND		     ;AN000;check mark text string offset
	       DW   0			     ;AN000;check mark text string segment
	       DW   1			     ;AN000;check mark offset into opt strg
	       DW   WR_UIINDLEN 	     ;AN000;up indicator string length
	       DW   WR_UIIND		     ;AN000;up indicator string offset
	       DW   0			     ;AN000;up indicator string segment
	       DW   2			     ;AN000;up indicator row location
	       DW   1			     ;AN000;up indicator column location
	       DW   WR_DIINDLEN 	     ;AN000;down indicator string length
	       DW   WR_DIIND		     ;AN000;down indicator string offset
	       DW   0			     ;AN000;down indicator string segment
	       DW   2			     ;AN000;down indicator row location
	       DW   2			     ;AN000;down indicator column locaiton
	       DW   0			     ;AN000;left indicator string length
	       DW   0			     ;AN000;left indicator string offset
	       DW   0			     ;AN000;left indicator string segment
	       DW   0			     ;AN000;left indicator row location
	       DW   0			     ;AN000;left indicator column location
	       DW   0			     ;AN000;right indicator string length
	       DW   0			     ;AN000;right indicator string offset
	       DW   0			     ;AN000;right indicator string segment
	       DW   0			     ;AN000;right indicator row location
	       DW   0			     ;AN000;right indicator column locaiton
	       DW   WR_CIS		     ;AN000;normal color array offset
	       DW   0			     ;AN000;normal color array segment
	       DW   1			     ;AN000;logical color index number
	       DW   16			     ;AN000;number color index table entries
	       DW   WR_CIS		     ;AN000;offset addr of color index table
	       DW   0			     ;AN000;segment addr of color index tabl
	       DW   WR_INDEX1		     ;AN000;index array offset
	       DW   0			     ;AN000;index array segment
	       DW   WR_SELECT_NUM	     ;AN000;element selection array offset
	       DW   0			     ;AN000;element selection array segment
	       DW   SSC_PTSB		     ;AN000;option array option word
	       DW   SCB_LIST15		     ;AN000;option array pointer offset
	       DW   0			     ;AN000;option array pointer segment
	       DW   SCB_LIST15_W	     ;AN000;option array string length
	       DW   0			     ;AN000;option array string segment
	       DB   'A'                      ;AN000;option array string term char
	       DW   0			     ;AN000;keystroke
	       DW   0			     ;AN000;log vid buf offset override
	       DW   0			     ;AN000;log vid buf segment override
	       DW   0			     ;AN000;general purpose format hook opt
	       DW   0			     ;AN000;general purpose format hook opt
	       DW   0			     ;AN000;length of translation table
	       DW   0			     ;AN000;offset of translation table
	       DW   0			     ;AN000;segment of translation table
	       DW   0			     ;AN000;monocasing table offset
	       DW   0			     ;AN000;monocasing table segment
	       DW   0			     ;AN000;dbcs table length
	       DW   0			     ;AN000;dbcs table offset
	       DW   0			     ;AN000;dbcs table segment
	       DW   0			     ;AN068;SEH offset of font descriptor block
	       DW   0			     ;AN068;SEH segment of font descriptor block
	       DB   236 DUP(0)		     ;AN024;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; review selections #2
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
WR_SCB16       DW   SCB_WRAP+SCB_DCHECK+SCB_DACTIVE;AN000;option word one
	       DW   SCB_LCOX		     ;AN000;option word two
	       DW   SCB_SELACT		     ;AN000;option word three
	       DW   0			     ;AN068;SEH option word four
	       DW   SND_FREQ		     ;AN000;error beep frequency
	       DW   12			     ;AN000;upper left row
	       DW   LEFT_COL_SCROLL		    ;AN000;upper left column
	       DW   0			     ;AN000;relative upper left row
	       DW   0			     ;AN000;relative upper left column
	       DW   42 ;;AN000;;;SCB_LIST16_W		  ;line width
	       DW   SCB_LIST16_N	     ;AN000;number of lines
	       DW   1			     ;AN000;number of element on top
	       DW   SCB_LIST16_N	     ;AN000;number of elements
	       DW   1			     ;AN000;current element
	       DW   0			     ;AN000;maximun number of cols to scroll
	       DW   0			     ;AN000;display offset into opt strings
	       DW   1			     ;AN000;num list txt col offset in strg
	       DB   '.'                      ;AN000;numbered list separator
	       DW   0			     ;AN000;select keystroke string length
	       DW   0			     ;AN000;select keystroke string offset
	       DW   0			     ;AN000;select keystroke string segment
	       DW   0			     ;AN000;return/leave string length
	       DW   0			     ;AN000;return/leave string offset
	       DW   0			     ;AN000;return/leave string segment
	       DW   0			     ;AN000;return/erase string length
	       DW   0			     ;AN000;return/erase string offset
	       DW   0			     ;AN000;return/erase string segment
	       DW   WR_UAKEYSLEN	     ;AN000;up arrow string length
	       DW   WR_UAKEYS		     ;AN000;up arrow string offset
	       DW   0			     ;AN000;up arrow string segment
	       DW   WR_DAKEYSLEN	     ;AN000;down arrow string length
	       DW   WR_DAKEYS		     ;AN000;down arrow string offset
	       DW   0			     ;AN000;down arrow string segment
	       DW   0			     ;AN000;left arrow string length
	       DW   0			     ;AN000;left arrow string offset
	       DW   0			     ;AN000;left arrow string segment
	       DW   0			     ;AN000;right arrow string length
	       DW   0			     ;AN000;right arrow string offset
	       DW   0			     ;AN000;right arrow string segment
	       DW   0			     ;AN000;page-up string length
	       DW   0			     ;AN000;page-up string offset
	       DW   0			     ;AN000;page-up string segment
	       DW   0			     ;AN000;page-down string length
	       DW   0			     ;AN000;page-down string offset
	       DW   0			     ;AN000;page-down string segment
	       DW   WR_PIINDLEN 	     ;AN000;pointer indicator strg length
	       DW   WR_PIIND		     ;AN000;pointer indicator string offset
	       DW   0			     ;AN000;pointer indicator string segment
	       DW   1			     ;AN000;pointer ind txt col off into strg
	       DW   WR_NOINDLEN 	     ;AN000;active indicator strg length
	       DW   WR_NOIND		     ;AN000;active indicator string offset
	       DW   0			     ;AN000;active indicator string segment
	       DW   50			     ;AN000;active ind txt col off into stg
	       DW   WR_YESINDLEN	     ;AN000;check mark text string length
	       DW   WR_YESIND		     ;AN000;check mark text string offset
	       DW   0			     ;AN000;check mark text string segment
	       DW   50			     ;AN000;check mark offset into opt strg
	       DW   WR_UIINDLEN 	     ;AN000;up indicator string length
	       DW   WR_UIIND		     ;AN000;up indicator string offset
	       DW   0			     ;AN000;up indicator string segment
	       DW   2			     ;AN000;up indicator row location
	       DW   1			     ;AN000;up indicator column location
	       DW   WR_DIINDLEN 	     ;AN000;down indicator string length
	       DW   WR_DIIND		     ;AN000;down indicator string offset
	       DW   0			     ;AN000;down indicator string segment
	       DW   2			     ;AN000;down indicator row location
	       DW   2			     ;AN000;down indicator column locaiton
	       DW   0			     ;AN000;left indicator string length
	       DW   0			     ;AN000;left indicator string offset
	       DW   0			     ;AN000;left indicator string segment
	       DW   0			     ;AN000;left indicator row location
	       DW   0			     ;AN000;left indicator column location
	       DW   0			     ;AN000;right indicator string length
	       DW   0			     ;AN000;right indicator string offset
	       DW   0			     ;AN000;right indicator string segment
	       DW   0			     ;AN000;right indicator row location
	       DW   0			     ;AN000;right indicator column locaiton
	       DW   WR_CIS		     ;AN000;normal color array offset
	       DW   0			     ;AN000;normal color array segment
	       DW   1			     ;AN000;logical color index number
	       DW   16			     ;AN000;number color index table entries
	       DW   WR_CIS		     ;AN000;offset addr of color index table
	       DW   0			     ;AN000;segment addr of color index tabl
	       DW   WR_INDEX1		     ;AN000;index array offset
	       DW   0			     ;AN000;index array segment
	       DW   WR_SELECT_MOD	     ;AN000;element selection array offset
	       DW   0			     ;AN000;element selection array segment
	       DW   SSC_PTSB		     ;AN000;option array option word
	       DW   SCB_LIST16		     ;AN000;option array pointer offset
	       DW   0			     ;AN000;option array pointer segment
	       DW   SCB_LIST16_W	     ;AN000;option array string length
	       DW   0			     ;AN000;option array string segment
	       DB   'A'                      ;AN000;option array string term char
	       DW   0			     ;AN000;keystroke
	       DW   0			     ;AN000;log vid buf offset override
	       DW   0			     ;AN000;log vid buf segment override
	       DW   0			     ;AN000;general purpose format hook opt
	       DW   0			     ;AN000;general purpose format hook opt
	       DW   0			     ;AN000;length of translation table
	       DW   0			     ;AN000;offset of translation table
	       DW   0			     ;AN000;segment of translation table
	       DW   0			     ;AN000;monocasing table offset
	       DW   0			     ;AN000;monocasing table segment
	       DW   0			     ;AN000;dbcs table length
	       DW   0			     ;AN000;dbcs table offset
	       DW   0			     ;AN000;dbcs table segment
	       DW   0			     ;AN068;SEH offset of font descriptor block
	       DW   0			     ;AN068;SEH segment of font descriptor block
	       DB   236 DUP(0)		     ;AN024;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; review selections 3
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
WR_SCB17       DW   SCB_WRAP+SCB_DCHECK+SCB_DACTIVE;AN000;option word one
	       DW   SCB_LCOX		     ;AN000;option word two
	       DW   SCB_SELACT		     ;AN000;option word three
	       DW   0			     ;AN068;SEH option word four
	       DW   SND_FREQ		     ;AN000;error beep frequency
	       DW   12			     ;AN000;upper left row
	       DW   LEFT_COL_SCROLL		    ;AN000;upper left column
	       DW   0			     ;AN000;relative upper left row
	       DW   0			     ;AN000;relative upper left column
	       DW   SCB_LIST17_W	     ;AN000;line width
	       DW   SCB_LIST17_N	     ;AN000;number of lines
	       DW   1			     ;AN000;number of element on top
	       DW   SCB_LIST17_N	     ;AN000;number of elements
	       DW   1			     ;AN000;current element
	       DW   0			     ;AN000;maximun number of cols to scroll
	       DW   0			     ;AN000;display offset into opt strings
	       DW   1			     ;AN000;num list txt col offset in strg
	       DB   '.'                      ;AN000;numbered list separator
	       DW   0			     ;AN000;select keystroke string length
	       DW   0			     ;AN000;select keystroke string offset
	       DW   0			     ;AN000;select keystroke string segment
	       DW   0			     ;AN000;return/leave string length
	       DW   0			     ;AN000;return/leave string offset
	       DW   0			     ;AN000;return/leave string segment
	       DW   0			     ;AN000;return/erase string length
	       DW   0			     ;AN000;return/erase string offset
	       DW   0			     ;AN000;return/erase string segment
	       DW   WR_UAKEYSLEN	     ;AN000;up arrow string length
	       DW   WR_UAKEYS		     ;AN000;up arrow string offset
	       DW   0			     ;AN000;up arrow string segment
	       DW   WR_DAKEYSLEN	     ;AN000;down arrow string length
	       DW   WR_DAKEYS		     ;AN000;down arrow string offset
	       DW   0			     ;AN000;down arrow string segment
	       DW   0			     ;AN000;left arrow string length
	       DW   0			     ;AN000;left arrow string offset
	       DW   0			     ;AN000;left arrow string segment
	       DW   0			     ;AN000;right arrow string length
	       DW   0			     ;AN000;right arrow string offset
	       DW   0			     ;AN000;right arrow string segment
	       DW   0			     ;AN000;page-up string length
	       DW   0			     ;AN000;page-up string offset
	       DW   0			     ;AN000;page-up string segment
	       DW   0			     ;AN000;page-down string length
	       DW   0			     ;AN000;page-down string offset
	       DW   0			     ;AN000;page-down string segment
	       DW   WR_PIINDLEN 	     ;AN000;pointer indicator strg length
	       DW   WR_PIIND		     ;AN000;pointer indicator string offset
	       DW   0			     ;AN000;pointer indicator string segment
	       DW   1			     ;AN000;pointer ind txt col off into strg
	       DW   WR_NOINDLEN 	     ;AN000;active indicator strg length
	       DW   WR_NOIND		     ;AN000;active indicator string offset
	       DW   0			     ;AN000;active indicator string segment
	       DW   50			     ;AN000;active ind txt col off into stg
	       DW   WR_YESINDLEN	     ;AN000;check mark text string length
	       DW   WR_YESIND		     ;AN000;check mark text string offset
	       DW   0			     ;AN000;check mark text string segment
	       DW   50			     ;AN000;check mark offset into opt strg
	       DW   WR_UIINDLEN 	     ;AN000;up indicator string length
	       DW   WR_UIIND		     ;AN000;up indicator string offset
	       DW   0			     ;AN000;up indicator string segment
	       DW   2			     ;AN000;up indicator row location
	       DW   1			     ;AN000;up indicator column location
	       DW   WR_DIINDLEN 	     ;AN000;down indicator string length
	       DW   WR_DIIND		     ;AN000;down indicator string offset
	       DW   0			     ;AN000;down indicator string segment
	       DW   2			     ;AN000;down indicator row location
	       DW   2			     ;AN000;down indicator column locaiton
	       DW   0			     ;AN000;left indicator string length
	       DW   0			     ;AN000;left indicator string offset
	       DW   0			     ;AN000;left indicator string segment
	       DW   0			     ;AN000;left indicator row location
	       DW   0			     ;AN000;left indicator column location
	       DW   0			     ;AN000;right indicator string length
	       DW   0			     ;AN000;right indicator string offset
	       DW   0			     ;AN000;right indicator string segment
	       DW   0			     ;AN000;right indicator row location
	       DW   0			     ;AN000;right indicator column locaiton
	       DW   WR_CIS		     ;AN000;normal color array offset
	       DW   0			     ;AN000;normal color array segment
	       DW   1			     ;AN000;logical color index number
	       DW   16			     ;AN000;number color index table entries
	       DW   WR_CIS		     ;AN000;offset addr of color index table
	       DW   0			     ;AN000;segment addr of color index tabl
	       DW   WR_INDEX1		     ;AN000;index array offset
	       DW   0			     ;AN000;index array segment
	       DW   WR_SELECT_MOD	     ;AN000;element selection array offset
	       DW   0			     ;AN000;element selection array segment
	       DW   SSC_PTSB		     ;AN000;option array option word
	       DW   SCB_LIST17		     ;AN000;option array pointer offset
	       DW   0			     ;AN000;option array pointer segment
	       DW   SCB_LIST17_W	     ;AN000;option array string length
	       DW   0			     ;AN000;option array string segment
	       DB   'A'                      ;AN000;option array string term char
	       DW   0			     ;AN000;keystroke
	       DW   0			     ;AN000;log vid buf offset override
	       DW   0			     ;AN000;log vid buf segment override
	       DW   0			     ;AN000;general purpose format hook opt
	       DW   0			     ;AN000;general purpose format hook opt
	       DW   0			     ;AN000;length of translation table
	       DW   0			     ;AN000;offset of translation table
	       DW   0			     ;AN000;segment of translation table
	       DW   0			     ;AN000;monocasing table offset
	       DW   0			     ;AN000;monocasing table segment
	       DW   0			     ;AN000;dbcs table length
	       DW   0			     ;AN000;dbcs table offset
	       DW   0			     ;AN000;dbcs table segment
	       DW   0			     ;AN068;SEH offset of font descriptor block
	       DW   0			     ;AN068;SEH segment of font descriptor block
	       DB   236 DUP(0)		     ;AN024;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; paritition fixed disk
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
WR_SCB18       DW   SCB_WRAP		     ;AN000;option word one
	       DW   SCB_SKIP		     ;AN000;option word two
	       DW   SCB_NUMS		     ;AN000;option word three
	       DW   0			     ;AN068;SEH option word four
	       DW   SND_FREQ		     ;AN000;error beep frequency
	       DW   15			     ;AN000;upper left row
	       DW   LEFT_COL_SCROLL		    ;AN000;upper left column
	       DW   0			     ;AN000;relative upper left row
	       DW   0			     ;AN000;relative upper left column
	       DW   SCB_LIST18_W	     ;AN000;line width
	       DW   SCB_LIST18_N	     ;AN000;number of lines
	       DW   1			     ;AN000;number of element on top
	       DW   SCB_LIST18_N	     ;AN000;number of elements
	       DW   1			     ;AN000;current element
	       DW   0			     ;AN000;maximun number of cols to scroll
	       DW   0			     ;AN000;display offset into opt strings
	       DW   1			     ;AN000;num list txt col offset in strg
	       DB   '.'                      ;AN000;numbered list separator
	       DW   0			     ;AN000;select keystroke string length
	       DW   0			     ;AN000;select keystroke string offset
	       DW   0			     ;AN000;select keystroke string segment
	       DW   0			     ;AN000;return/leave string length
	       DW   0			     ;AN000;return/leave string offset
	       DW   0			     ;AN000;return/leave string segment
	       DW   0			     ;AN000;return/erase string length
	       DW   0			     ;AN000;return/erase string offset
	       DW   0			     ;AN000;return/erase string segment
	       DW   WR_UAKEYSLEN	     ;AN000;up arrow string length
	       DW   WR_UAKEYS		     ;AN000;up arrow string offset
	       DW   0			     ;AN000;up arrow string segment
	       DW   WR_DAKEYSLEN	     ;AN000;down arrow string length
	       DW   WR_DAKEYS		     ;AN000;down arrow string offset
	       DW   0			     ;AN000;down arrow string segment
	       DW   0			     ;AN000;left arrow string length
	       DW   0			     ;AN000;left arrow string offset
	       DW   0			     ;AN000;left arrow string segment
	       DW   0			     ;AN000;right arrow string length
	       DW   0			     ;AN000;right arrow string offset
	       DW   0			     ;AN000;right arrow string segment
	       DW   0			     ;AN000;page-up string length
	       DW   0			     ;AN000;page-up string offset
	       DW   0			     ;AN000;page-up string segment
	       DW   0			     ;AN000;page-down string length
	       DW   0			     ;AN000;page-down string offset
	       DW   0			     ;AN000;page-down string segment
	       DW   WR_PIINDLEN 	     ;AN000;pointer indicator strg length
	       DW   WR_PIIND		     ;AN000;pointer indicator string offset
	       DW   0			     ;AN000;pointer indicator string segment
	       DW   1			     ;AN000;pointer ind txt col off into strg
	       DW   WR_AIINDLEN 	     ;AN000;active indicator strg length
	       DW   WR_AIIND		     ;AN000;active indicator string offset
	       DW   0			     ;AN000;active indicator string segment
	       DW   1			     ;AN000;active ind txt col off into stg
	       DW   WR_CIINDLEN 	     ;AN000;check mark text string length
	       DW   WR_CIIND		     ;AN000;check mark text string offset
	       DW   0			     ;AN000;check mark text string segment
	       DW   1			     ;AN000;check mark offset into opt strg
	       DW   WR_UIINDLEN 	     ;AN000;up indicator string length
	       DW   WR_UIIND		     ;AN000;up indicator string offset
	       DW   0			     ;AN000;up indicator string segment
	       DW   2			     ;AN000;up indicator row location
	       DW   1			     ;AN000;up indicator column location
	       DW   WR_DIINDLEN 	     ;AN000;down indicator string length
	       DW   WR_DIIND		     ;AN000;down indicator string offset
	       DW   0			     ;AN000;down indicator string segment
	       DW   2			     ;AN000;down indicator row location
	       DW   2			     ;AN000;down indicator column locaiton
	       DW   0			     ;AN000;left indicator string length
	       DW   0			     ;AN000;left indicator string offset
	       DW   0			     ;AN000;left indicator string segment
	       DW   0			     ;AN000;left indicator row location
	       DW   0			     ;AN000;left indicator column location
	       DW   0			     ;AN000;right indicator string length
	       DW   0			     ;AN000;right indicator string offset
	       DW   0			     ;AN000;right indicator string segment
	       DW   0			     ;AN000;right indicator row location
	       DW   0			     ;AN000;right indicator column locaiton
	       DW   WR_CIS		     ;AN000;normal color array offset
	       DW   0			     ;AN000;normal color array segment
	       DW   1			     ;AN000;logical color index number
	       DW   16			     ;AN000;number color index table entries
	       DW   WR_CIS		     ;AN000;offset addr of color index table
	       DW   0			     ;AN000;segment addr of color index tabl
	       DW   WR_INDEX1		     ;AN000;index array offset
	       DW   0			     ;AN000;index array segment
	       DW   WR_SELECT_NUM	     ;AN000;element selection array offset
	       DW   0			     ;AN000;element selection array segment
	       DW   SSC_PTSB		     ;AN000;option array option word
	       DW   SCB_LIST18		     ;AN000;option array pointer offset
	       DW   0			     ;AN000;option array pointer segment
	       DW   SCB_LIST18_W	     ;AN000;option array string length
	       DW   0			     ;AN000;option array string segment
	       DB   'A'                      ;AN000;option array string term char
	       DW   0			     ;AN000;keystroke
	       DW   0			     ;AN000;log vid buf offset override
	       DW   0			     ;AN000;log vid buf segment override
	       DW   0			     ;AN000;general purpose format hook opt
	       DW   0			     ;AN000;general purpose format hook opt
	       DW   0			     ;AN000;length of translation table
	       DW   0			     ;AN000;offset of translation table
	       DW   0			     ;AN000;segment of translation table
	       DW   0			     ;AN000;monocasing table offset
	       DW   0			     ;AN000;monocasing table segment
	       DW   0			     ;AN000;dbcs table length
	       DW   0			     ;AN000;dbcs table offset
	       DW   0			     ;AN000;dbcs table segment
	       DW   0			     ;AN068;SEH offset of font descriptor block
	       DW   0			     ;AN068;SEH segment of font descriptor block
	       DB   236 DUP(0)		     ;AN024;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; paritition fixed disk 2
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
WR_SCB19       DW   SCB_WRAP		     ;AN000;option word one
	       DW   SCB_SKIP		     ;AN000;option word two
	       DW   SCB_NUMS		     ;AN000;option word three
	       DW   0			     ;AN068;SEH option word four
	       DW   SND_FREQ		     ;AN000;error beep frequency
	       DW   15			     ;AN000;upper left row
	       DW   LEFT_COL_SCROLL		    ;AN000;upper left column
	       DW   0			     ;AN000;relative upper left row
	       DW   0			     ;AN000;relative upper left column
	       DW   SCB_LIST19_W	     ;AN000;line width
	       DW   SCB_LIST19_N	     ;AN000;number of lines
	       DW   1			     ;AN000;number of element on top
	       DW   SCB_LIST19_N	     ;AN000;number of elements
	       DW   1			     ;AN000;current element
	       DW   0			     ;AN000;maximun number of cols to scroll
	       DW   0			     ;AN000;display offset into opt strings
	       DW   1			     ;AN000;num list txt col offset in strg
	       DB   '.'                      ;AN000;numbered list separator
	       DW   0			     ;AN000;select keystroke string length
	       DW   0			     ;AN000;select keystroke string offset
	       DW   0			     ;AN000;select keystroke string segment
	       DW   0			     ;AN000;return/leave string length
	       DW   0			     ;AN000;return/leave string offset
	       DW   0			     ;AN000;return/leave string segment
	       DW   0			     ;AN000;return/erase string length
	       DW   0			     ;AN000;return/erase string offset
	       DW   0			     ;AN000;return/erase string segment
	       DW   WR_UAKEYSLEN	     ;AN000;up arrow string length
	       DW   WR_UAKEYS		     ;AN000;up arrow string offset
	       DW   0			     ;AN000;up arrow string segment
	       DW   WR_DAKEYSLEN	     ;AN000;down arrow string length
	       DW   WR_DAKEYS		     ;AN000;down arrow string offset
	       DW   0			     ;AN000;down arrow string segment
	       DW   0			     ;AN000;left arrow string length
	       DW   0			     ;AN000;left arrow string offset
	       DW   0			     ;AN000;left arrow string segment
	       DW   0			     ;AN000;right arrow string length
	       DW   0			     ;AN000;right arrow string offset
	       DW   0			     ;AN000;right arrow string segment
	       DW   0			     ;AN000;page-up string length
	       DW   0			     ;AN000;page-up string offset
	       DW   0			     ;AN000;page-up string segment
	       DW   0			     ;AN000;page-down string length
	       DW   0			     ;AN000;page-down string offset
	       DW   0			     ;AN000;page-down string segment
	       DW   WR_PIINDLEN 	     ;AN000;pointer indicator strg length
	       DW   WR_PIIND		     ;AN000;pointer indicator string offset
	       DW   0			     ;AN000;pointer indicator string segment
	       DW   1			     ;AN000;pointer ind txt col off into strg
	       DW   WR_AIINDLEN 	     ;AN000;active indicator strg length
	       DW   WR_AIIND		     ;AN000;active indicator string offset
	       DW   0			     ;AN000;active indicator string segment
	       DW   1			     ;AN000;active ind txt col off into stg
	       DW   WR_CIINDLEN 	     ;AN000;check mark text string length
	       DW   WR_CIIND		     ;AN000;check mark text string offset
	       DW   0			     ;AN000;check mark text string segment
	       DW   1			     ;AN000;check mark offset into opt strg
	       DW   WR_UIINDLEN 	     ;AN000;up indicator string length
	       DW   WR_UIIND		     ;AN000;up indicator string offset
	       DW   0			     ;AN000;up indicator string segment
	       DW   2			     ;AN000;up indicator row location
	       DW   1			     ;AN000;up indicator column location
	       DW   WR_DIINDLEN 	     ;AN000;down indicator string length
	       DW   WR_DIIND		     ;AN000;down indicator string offset
	       DW   0			     ;AN000;down indicator string segment
	       DW   2			     ;AN000;down indicator row location
	       DW   2			     ;AN000;down indicator column locaiton
	       DW   0			     ;AN000;left indicator string length
	       DW   0			     ;AN000;left indicator string offset
	       DW   0			     ;AN000;left indicator string segment
	       DW   0			     ;AN000;left indicator row location
	       DW   0			     ;AN000;left indicator column location
	       DW   0			     ;AN000;right indicator string length
	       DW   0			     ;AN000;right indicator string offset
	       DW   0			     ;AN000;right indicator string segment
	       DW   0			     ;AN000;right indicator row location
	       DW   0			     ;AN000;right indicator column locaiton
	       DW   WR_CIS		     ;AN000;normal color array offset
	       DW   0			     ;AN000;normal color array segment
	       DW   1			     ;AN000;logical color index number
	       DW   16			     ;AN000;number color index table entries
	       DW   WR_CIS		     ;AN000;offset addr of color index table
	       DW   0			     ;AN000;segment addr of color index tabl
	       DW   WR_INDEX1		     ;AN000;index array offset
	       DW   0			     ;AN000;index array segment
	       DW   WR_SELECT_NUM	     ;AN000;element selection array offset
	       DW   0			     ;AN000;element selection array segment
	       DW   SSC_PTSB		     ;AN000;option array option word
	       DW   SCB_LIST19		     ;AN000;option array pointer offset
	       DW   0			     ;AN000;option array pointer segment
	       DW   SCB_LIST19_W	     ;AN000;option array string length
	       DW   0			     ;AN000;option array string segment
	       DB   'A'                      ;AN000;option array string term char
	       DW   0			     ;AN000;keystroke
	       DW   0			     ;AN000;log vid buf offset override
	       DW   0			     ;AN000;log vid buf segment override
	       DW   0			     ;AN000;general purpose format hook opt
	       DW   0			     ;AN000;general purpose format hook opt
	       DW   0			     ;AN000;length of translation table
	       DW   0			     ;AN000;offset of translation table
	       DW   0			     ;AN000;segment of translation table
	       DW   0			     ;AN000;monocasing table offset
	       DW   0			     ;AN000;monocasing table segment
	       DW   0			     ;AN000;dbcs table length
	       DW   0			     ;AN000;dbcs table offset
	       DW   0			     ;AN000;dbcs table segment
	       DW   0			     ;AN068;SEH offset of font descriptor block
	       DW   0			     ;AN068;SEH segment of font descriptor block
	       DB   236 DUP(0)		     ;AN024;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; FORMAT FIXED DISK DRIVE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
WR_SCB20       DW   SCB_WRAP		     ;AN000;option word one
	       DW   SCB_SKIP		     ;AN000;option word two
	       DW   SCB_NUMS		     ;AN000;option word three
	       DW   0			     ;AN068;SEH option word four
	       DW   SND_FREQ		     ;AN000;error beep frequency
	       DW   9			     ;AC000;upper left row JW
	       DW   LEFT_COL_SCROLL		    ;AN000;upper left column
	       DW   0			     ;AN000;relative upper left row
	       DW   0			     ;AN000;relative upper left column
	       DW   SCB_LIST20_W	     ;AN000;line width
	       DW   SCB_LIST20_N	     ;AN000;number of lines
	       DW   1			     ;AN000;number of element on top
	       DW   SCB_LIST20_N	     ;AN000;number of elements
	       DW   1			     ;AN000;current element
	       DW   0			     ;AN000;maximun number of cols to scroll
	       DW   0			     ;AN000;display offset into opt strings
	       DW   1			     ;AN000;num list txt col offset in strg
	       DB   '.'                      ;AN000;numbered list separator
	       DW   0			     ;AN000;select keystroke string length
	       DW   0			     ;AN000;select keystroke string offset
	       DW   0			     ;AN000;select keystroke string segment
	       DW   0			     ;AN000;return/leave string length
	       DW   0			     ;AN000;return/leave string offset
	       DW   0			     ;AN000;return/leave string segment
	       DW   0			     ;AN000;return/erase string length
	       DW   0			     ;AN000;return/erase string offset
	       DW   0			     ;AN000;return/erase string segment
	       DW   WR_UAKEYSLEN	     ;AN000;up arrow string length
	       DW   WR_UAKEYS		     ;AN000;up arrow string offset
	       DW   0			     ;AN000;up arrow string segment
	       DW   WR_DAKEYSLEN	     ;AN000;down arrow string length
	       DW   WR_DAKEYS		     ;AN000;down arrow string offset
	       DW   0			     ;AN000;down arrow string segment
	       DW   0			     ;AN000;left arrow string length
	       DW   0			     ;AN000;left arrow string offset
	       DW   0			     ;AN000;left arrow string segment
	       DW   0			     ;AN000;right arrow string length
	       DW   0			     ;AN000;right arrow string offset
	       DW   0			     ;AN000;right arrow string segment
	       DW   0			     ;AN000;page-up string length
	       DW   0			     ;AN000;page-up string offset
	       DW   0			     ;AN000;page-up string segment
	       DW   0			     ;AN000;page-down string length
	       DW   0			     ;AN000;page-down string offset
	       DW   0			     ;AN000;page-down string segment
	       DW   WR_PIINDLEN 	     ;AN000;pointer indicator strg length
	       DW   WR_PIIND		     ;AN000;pointer indicator string offset
	       DW   0			     ;AN000;pointer indicator string segment
	       DW   1			     ;AN000;pointer ind txt col off into strg
	       DW   WR_AIINDLEN 	     ;AN000;active indicator strg length
	       DW   WR_AIIND		     ;AN000;active indicator string offset
	       DW   0			     ;AN000;active indicator string segment
	       DW   1			     ;AN000;active ind txt col off into stg
	       DW   WR_CIINDLEN 	     ;AN000;check mark text string length
	       DW   WR_CIIND		     ;AN000;check mark text string offset
	       DW   0			     ;AN000;check mark text string segment
	       DW   1			     ;AN000;check mark offset into opt strg
	       DW   WR_UIINDLEN 	     ;AN000;up indicator string length
	       DW   WR_UIIND		     ;AN000;up indicator string offset
	       DW   0			     ;AN000;up indicator string segment
	       DW   2			     ;AN000;up indicator row location
	       DW   1			     ;AN000;up indicator column location
	       DW   WR_DIINDLEN 	     ;AN000;down indicator string length
	       DW   WR_DIIND		     ;AN000;down indicator string offset
	       DW   0			     ;AN000;down indicator string segment
	       DW   2			     ;AN000;down indicator row location
	       DW   2			     ;AN000;down indicator column locaiton
	       DW   0			     ;AN000;left indicator string length
	       DW   0			     ;AN000;left indicator string offset
	       DW   0			     ;AN000;left indicator string segment
	       DW   0			     ;AN000;left indicator row location
	       DW   0			     ;AN000;left indicator column location
	       DW   0			     ;AN000;right indicator string length
	       DW   0			     ;AN000;right indicator string offset
	       DW   0			     ;AN000;right indicator string segment
	       DW   0			     ;AN000;right indicator row location
	       DW   0			     ;AN000;right indicator column locaiton
	       DW   WR_CIS		     ;AN000;normal color array offset
	       DW   0			     ;AN000;normal color array segment
	       DW   1			     ;AN000;logical color index number
	       DW   16			     ;AN000;number color index table entries
	       DW   WR_CIS		     ;AN000;offset addr of color index table
	       DW   0			     ;AN000;segment addr of color index tabl
	       DW   WR_INDEX1		     ;AN000;index array offset
	       DW   0			     ;AN000;index array segment
	       DW   WR_SELECT_NUM	     ;AN000;element selection array offset
	       DW   0			     ;AN000;element selection array segment
	       DW   SSC_PTSB		     ;AN000;option array option word
	       DW   SCB_LIST20		     ;AN000;option array pointer offset
	       DW   0			     ;AN000;option array pointer segment
	       DW   SCB_LIST20_W	     ;AN000;option array string length
	       DW   0			     ;AN000;option array string segment
	       DB   'A'                      ;AN000;option array string term char
	       DW   0			     ;AN000;keystroke
	       DW   0			     ;AN000;log vid buf offset override
	       DW   0			     ;AN000;log vid buf segment override
	       DW   0			     ;AN000;general purpose format hook opt
	       DW   0			     ;AN000;general purpose format hook opt
	       DW   0			     ;AN000;length of translation table
	       DW   0			     ;AN000;offset of translation table
	       DW   0			     ;AN000;segment of translation table
	       DW   0			     ;AN000;monocasing table offset
	       DW   0			     ;AN000;monocasing table segment
	       DW   0			     ;AN000;dbcs table length
	       DW   0			     ;AN000;dbcs table offset
	       DW   0			     ;AN000;dbcs table segment
	       DW   0			     ;AN068;SEH offset of font descriptor block
	       DW   0			     ;AN068;SEH segment of font descriptor block
	       DB   236 DUP(0)		     ;AN024;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; HELP SCROLL INFORMATION
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
WR_SCB21       DW   scb_uc+SCB_LL	     ;AN000;option word one
	       DW   SCB_ROTN+scb_dyn+scb_uind;AN000;option word two
	       DW   SCB_RELSCR+SCB_RELUIND   ;AN000;option word three
	       DW   0			     ;AN068;SEH option word four
	       DW   100 		     ;AN000;error beep frequency
	       DW   4			     ;AN000;upper left row
	       DW   3			     ;AN000;upper left column
	       DW   0			     ;AN000;relative upper left row
	       DW   0			     ;AN000;relative upper left column
	       DW   53			     ;AN000;line width
	       DW   7			     ;AN000;number of lines
	       DW   1			     ;AN000;number of element on top
	       DW   55			     ;AN000;number of elements
	       DW   1			     ;AN000;current element
	       DW   0			     ;AN000;maximun number of cols to scroll
	       DW   0			     ;AN000;display offset into opt strings
	       DW   0			     ;AN000;num list txt col offset in strg
	       DB   0			     ;AN000;numbered list separator
	       DW   0			     ;AN000;select keystroke string length
	       DW   0			     ;AN000;select keystroke string offset
	       DW   0			     ;AN000;select keystroke string segment
	       DW   WR_REHLPKEYSLEN	     ;AN000;return/leave string length
	       DW   WR_REHLPKEYS	     ;AN000;return/leave string offset
	       DW   0			     ;AN000;return/leave string segment
	       DW   0			     ;AN000;return/erase string length
	       DW   0			     ;AN000;return/erase string offset
	       DW   0			     ;AN000;return/erase string segment
	       DW   WR_UAKEYSLEN	     ;AN000;up arrow string length
	       DW   WR_UAKEYS		     ;AN000;up arrow string offset
	       DW   0			     ;AN000;up arrow string segment
	       DW   WR_DAKEYSLEN	     ;AN000;down arrow string length
	       DW   WR_DAKEYS		     ;AN000;down arrow string offset
	       DW   0			     ;AN000;down arrow string segment
	       DW   0			     ;AN000;left arrow string length
	       DW   0			     ;AN000;left arrow string offset
	       DW   0			     ;AN000;left arrow string segment
	       DW   0			     ;AN000;right arrow string length
	       DW   0			     ;AN000;right arrow string offset
	       DW   0			     ;AN000;right arrow string segment
	       DW   WR_PUKEYSLEN	     ;AN000;page-up string length
	       DW   WR_PUKEYS		     ;AN000;page-up string offset
	       DW   0			     ;AN000;page-up string segment
	       DW   WR_PDKEYSLEN	     ;AN000;page-down string length
	       DW   WR_PDKEYS		     ;AN000;page-down string offset
	       DW   0			     ;AN000;page-down string segment
	       DW   WR_PIINDLEN 	     ;AN000;pointer indicator strg length
	       DW   WR_PIIND		     ;AN000;pointer indicator string offset
	       DW   0			     ;AN000;pointer indicator string segment
	       DW   1			     ;AN000;pointer ind txt col off into strg
	       DW   WR_AIINDLEN 	     ;AN000;active indicator strg length
	       DW   WR_AIIND		     ;AN000;active indicator string offset
	       DW   0			     ;AN000;active indicator string segment
	       DW   1			     ;AN000;active ind txt col off into stg
	       DW   WR_CIINDLEN 	     ;AN000;check mark text string length
	       DW   WR_CIIND		     ;AN000;check mark text string offset
	       DW   0			     ;AN000;check mark text string segment
	       DW   1			     ;AN000;check mark offset into opt strg
	       DW   WR_UIINDLEN 	     ;AN000;up indicator string length
	       DW   WR_UIIND		     ;AN000;up indicator string offset
	       DW   0			     ;AN000;up indicator string segment
	       DW   2			     ;AN000;up indicator row location
	       DW   50			     ;AN000;up indicator column location
	       DW   WR_DIINDLEN 	     ;AN000;down indicator string length
	       DW   WR_DIIND		     ;AN000;down indicator string offset
	       DW   0			     ;AN000;down indicator string segment
	       DW   2			     ;AN000;down indicator row location
	       DW   51			     ;AN000;down indicator column locaiton
	       DW   0			     ;AN000;left indicator string length
	       DW   0			     ;AN000;left indicator string offset
	       DW   0			     ;AN000;left indicator string segment
	       DW   0			     ;AN000;left indicator row location
	       DW   0			     ;AN000;left indicator column location
	       DW   0			     ;AN000;right indicator string length
	       DW   0			     ;AN000;right indicator string offset
	       DW   0			     ;AN000;right indicator string segment
	       DW   0			     ;AN000;right indicator row location
	       DW   0			     ;AN000;right indicator column locaiton
	       DW   0			     ;AN000;normal color array offset
	       DW   0			     ;AN000;normal color array segment
	       DW   3;AN000;BLACK_WHITE 	     ;logical color index number
	       DW   0			     ;AN000;number color index table entries
	       DW   0			     ;AN000;offset addr of color index table
	       DW   0			     ;AN000;segment addr of color index tabl
	       DW   0			     ;AN000;index array offset
	       DW   0			     ;AN000;index array segment
	       DW   WR_SELECT		     ;AN000;element selection array offset
	       DW   0			     ;AN000;element selection array segment
	       DW   SSC_PTSB		     ;AN000;option array option word
	       DW   0			     ;AN000;option array pointer offset
	       DW   0			     ;AN000;option array pointer segment
	       DW   53			     ;AN000;option array string length
	       DW   0			     ;AN000;option array string segment
	       DB   0			     ;AN000;option array string term char
	       DW   0			     ;AN000;keystroke
	       DW   0			     ;AN000;log vid buf offset override
	       DW   0			     ;AN000;log vid buf segment override
	       DW   0			     ;AN000;general purpose format hook opt
	       DW   0			     ;AN000;general purpose format hook opt
	       DW   0			     ;AN000;length of translation table
	       DW   0			     ;AN000;offset of translation table
	       DW   0			     ;AN000;segment of translation table
	       DW   0			     ;AN000;monocasing table offset
	       DW   0			     ;AN000;monocasing table segment
	       DW   0			     ;AN000;dbcs table length
	       DW   0			     ;AN000;dbcs table offset
	       DW   0			     ;AN000;dbcs table segment
	       DW   0			     ;AN068;SEH offset of font descriptor block
	       DW   0			     ;AN068;SEH segment of font descriptor block
	       DB   236 DUP(0)		     ;AN024;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; HELP TITLE SCROLL INFORMATION
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
WR_SCB22       DW   scb_uc+SCB_LL	     ;AN000;option word one
	       DW   SCB_ROTN+scb_dyn+scb_uind;AN000;option word two
	       DW   SCB_RELSCR+SCB_RELUIND   ;AN000;option word three
	       DW   0			     ;AN068;SEH option word four
	       DW   100 		     ;AN000;error beep frequency
	       DW   2			     ;AN000;upper left row
	       DW   3			     ;AN000;upper left column
	       DW   0			     ;AN000;relative upper left row
	       DW   0			     ;AN000;relative upper left column
	       DW   53			     ;AN000;line width
	       DW   1			     ;AN000;number of lines
	       DW   1			     ;AN000;number of element on top
	       DW   1			     ;AN000;number of elements
	       DW   1			     ;AN000;current element
	       DW   0			     ;AN000;maximun number of cols to scroll
	       DW   0			     ;AN000;display offset into opt strings
	       DW   0			     ;AN000;num list txt col offset in strg
	       DB   0			     ;AN000;numbered list separator
	       DW   0			     ;AN000;select keystroke string length
	       DW   0			     ;AN000;select keystroke string offset
	       DW   0			     ;AN000;select keystroke string segment
	       DW   0			     ;AN000;return/leave string length
	       DW   0			     ;AN000;return/leave string offset
	       DW   0			     ;AN000;return/leave string segment
	       DW   0			     ;AN000;return/erase string length
	       DW   0			     ;AN000;return/erase string offset
	       DW   0			     ;AN000;return/erase string segment
	       DW   WR_UAKEYSLEN	     ;AN000;up arrow string length
	       DW   WR_UAKEYS		     ;AN000;up arrow string offset
	       DW   0			     ;AN000;up arrow string segment
	       DW   WR_DAKEYSLEN	     ;AN000;down arrow string length
	       DW   WR_DAKEYS		     ;AN000;down arrow string offset
	       DW   0			     ;AN000;down arrow string segment
	       DW   0			     ;AN000;left arrow string length
	       DW   0			     ;AN000;left arrow string offset
	       DW   0			     ;AN000;left arrow string segment
	       DW   0			     ;AN000;right arrow string length
	       DW   0			     ;AN000;right arrow string offset
	       DW   0			     ;AN000;right arrow string segment
	       DW   WR_PUKEYSLEN	     ;AN000;page-up string length
	       DW   WR_PUKEYS		     ;AN000;page-up string offset
	       DW   0			     ;AN000;page-up string segment
	       DW   WR_PDKEYSLEN	     ;AN000;page-down string length
	       DW   WR_PDKEYS		     ;AN000;page-down string offset
	       DW   0			     ;AN000;page-down string segment
	       DW   WR_PIINDLEN 	     ;AN000;pointer indicator strg length
	       DW   WR_PIIND		     ;AN000;pointer indicator string offset
	       DW   0			     ;AN000;pointer indicator string segment
	       DW   1			     ;AN000;pointer ind txt col off into strg
	       DW   WR_AIINDLEN 	     ;AN000;active indicator strg length
	       DW   WR_AIIND		     ;AN000;active indicator string offset
	       DW   0			     ;AN000;active indicator string segment
	       DW   1			     ;AN000;active ind txt col off into stg
	       DW   WR_CIINDLEN 	     ;AN000;check mark text string length
	       DW   WR_CIIND		     ;AN000;check mark text string offset
	       DW   0			     ;AN000;check mark text string segment
	       DW   1			     ;AN000;check mark offset into opt strg
	       DW   WR_UIINDLEN 	     ;AN000;up indicator string length
	       DW   WR_UIIND		     ;AN000;up indicator string offset
	       DW   0			     ;AN000;up indicator string segment
	       DW   2			     ;AN000;up indicator row location
	       DW   23			     ;AN000;up indicator column location
	       DW   WR_DIINDLEN 	     ;AN000;down indicator string length
	       DW   WR_DIIND		     ;AN000;down indicator string offset
	       DW   0			     ;AN000;down indicator string segment
	       DW   2			     ;AN000;down indicator row location
	       DW   21			     ;AN000;down indicator column locaiton
	       DW   0			     ;AN000;left indicator string length
	       DW   0			     ;AN000;left indicator string offset
	       DW   0			     ;AN000;left indicator string segment
	       DW   0			     ;AN000;left indicator row location
	       DW   0			     ;AN000;left indicator column location
	       DW   0			     ;AN000;right indicator string length
	       DW   0			     ;AN000;right indicator string offset
	       DW   0			     ;AN000;right indicator string segment
	       DW   0			     ;AN000;right indicator row location
	       DW   0			     ;AN000;right indicator column locaiton
	       DW   0			     ;AN000;normal color array offset
	       DW   0			     ;AN000;normal color array segment
	       DW   3;AN000;BLACK_WHITE 	     ;logical color index number
	       DW   0			     ;AN000;number color index table entries
	       DW   0			     ;AN000;offset addr of color index table
	       DW   0			     ;AN000;segment addr of color index tabl
	       DW   0			     ;AN000;index array offset
	       DW   0			     ;AN000;index array segment
	       DW   WR_SELECT		     ;AN000;element selection array offset
	       DW   0			     ;AN000;element selection array segment
	       DW   SSC_PTSB		     ;AN000;option array option word
	       DW   0			     ;AN000;option array pointer offset
	       DW   0			     ;AN000;option array pointer segment
	       DW   53			     ;AN000;option array string length
	       DW   0			     ;AN000;option array string segment
	       DB   0			     ;AN000;option array string term char
	       DW   0			     ;AN000;keystroke
	       DW   0			     ;AN000;log vid buf offset override
	       DW   0			     ;AN000;log vid buf segment override
	       DW   0			     ;AN000;general purpose format hook opt
	       DW   0			     ;AN000;general purpose format hook opt
	       DW   0			     ;AN000;length of translation table
	       DW   0			     ;AN000;offset of translation table
	       DW   0			     ;AN000;segment of translation table
	       DW   0			     ;AN000;monocasing table offset
	       DW   0			     ;AN000;monocasing table segment
	       DW   0			     ;AN000;dbcs table length
	       DW   0			     ;AN000;dbcs table offset
	       DW   0			     ;AN000;dbcs table segment
	       DW   0			     ;AN068;SEH offset of font descriptor block
	       DW   0			     ;AN068;SEH segment of font descriptor block
	       DB   236 DUP(0)		     ;AN024;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; SCR_ACC_CTY
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
WR_SCB23       DW   SCB_FRBF+SCB_FRAL	     ;AN000;option word one
	       DW   SCB_ROTN		     ;AN000;option word two
	       DW   0			     ;AN000;option word three
	       DW   0			     ;AN068;SEH option word four
	       DW   SND_FREQ		     ;AN000;error beep frequency
	       DW   4			     ;AN000;upper left row
	       DW   37			 ;AN000;**********;upper left column
	       DW   0			     ;AN000;relative upper left row
	       DW   0			     ;AN000;relative upper left column
	       DW   SCB_LIST23_W	     ;AN000;line width
	       DW   1			     ;AN000;number of lines
	       DW   1			     ;AN000;number of element on top
	       DW   SCB_LIST23_N	     ;AN000;number of elements
	       DW   1			     ;AN000;current element
	       DW   0			     ;AN000;maximun number of cols to scroll
	       DW   0			     ;AN000;display offset into opt strings
	       DW   1			     ;AN000;num list txt col offset in strg
	       DB   '.'                      ;AN000;numbered list separator
	       DW   0			     ;AN000;select keystroke string length
	       DW   0			     ;AN000;select keystroke string offset
	       DW   0			     ;AN000;select keystroke string segment
	       DW   0			     ;AN000;return/leave string length
	       DW   0			     ;AN000;return/leave string offset
	       DW   0			     ;AN000;return/leave string segment
	       DW   0			     ;AN000;return/erase string length
	       DW   0			     ;AN000;return/erase string offset
	       DW   0			     ;AN000;return/erase string segment
	       DW   WR_UAKEYSLEN	     ;AN000;up arrow string length
	       DW   WR_UAKEYS		     ;AN000;up arrow string offset
	       DW   0			     ;AN000;up arrow string segment
	       DW   WR_DAKEYSLEN	     ;AN000;down arrow string length
	       DW   WR_DAKEYS		     ;AN000;down arrow string offset
	       DW   0			     ;AN000;down arrow string segment
	       DW   0			     ;AN000;left arrow string length
	       DW   0			     ;AN000;left arrow string offset
	       DW   0			     ;AN000;left arrow string segment
	       DW   0			     ;AN000;right arrow string length
	       DW   0			     ;AN000;right arrow string offset
	       DW   0			     ;AN000;right arrow string segment
	       DW   0			     ;AN000;page-up string length
	       DW   0			     ;AN000;page-up string offset
	       DW   0			     ;AN000;page-up string segment
	       DW   0			     ;AN000;page-down string length
	       DW   0			     ;AN000;page-down string offset
	       DW   0			     ;AN000;page-down string segment
	       DW   WR_PIINDLEN 	     ;AN000;pointer indicator strg length
	       DW   WR_PIIND		     ;AN000;pointer indicator string offset
	       DW   0			     ;AN000;pointer indicator string segment
	       DW   1			     ;AN000;pointer ind txt col off into strg
	       DW   WR_AIINDLEN 	     ;AN000;active indicator strg length
	       DW   WR_AIIND		     ;AN000;active indicator string offset
	       DW   0			     ;AN000;active indicator string segment
	       DW   1			     ;AN000;active ind txt col off into stg
	       DW   WR_CIINDLEN 	     ;AN000;check mark text string length
	       DW   WR_CIIND		     ;AN000;check mark text string offset
	       DW   0			     ;AN000;check mark text string segment
	       DW   1			     ;AN000;check mark offset into opt strg
	       DW   WR_UIINDLEN 	     ;AN000;up indicator string length
	       DW   WR_UIIND		     ;AN000;up indicator string offset
	       DW   0			     ;AN000;up indicator string segment
	       DW   2			     ;AN000;up indicator row location
	       DW   1			     ;AN000;up indicator column location
	       DW   WR_DIINDLEN 	     ;AN000;down indicator string length
	       DW   WR_DIIND		     ;AN000;down indicator string offset
	       DW   0			     ;AN000;down indicator string segment
	       DW   2			     ;AN000;down indicator row location
	       DW   2			     ;AN000;down indicator column locaiton
	       DW   0			     ;AN000;left indicator string length
	       DW   0			     ;AN000;left indicator string offset
	       DW   0			     ;AN000;left indicator string segment
	       DW   0			     ;AN000;left indicator row location
	       DW   0			     ;AN000;left indicator column location
	       DW   0			     ;AN000;right indicator string length
	       DW   0			     ;AN000;right indicator string offset
	       DW   0			     ;AN000;right indicator string segment
	       DW   0			     ;AN000;right indicator row location
	       DW   0			     ;AN000;right indicator column locaiton
	       DW   WR_CIS		     ;AN000;normal color array offset
	       DW   0			     ;AN000;normal color array segment
	       DW   1			     ;AN000;logical color index number
	       DW   16			     ;AN000;number color index table entries
	       DW   WR_CIS		     ;AN000;offset addr of color index table
	       DW   0			     ;AN000;segment addr of color index tabl
	       DW   WR_INDEX1		     ;AN000;index array offset
	       DW   0			     ;AN000;index array segment
	       DW   WR_SELECT		     ;AN000;element selection array offset
	       DW   0			     ;AN000;element selection array segment
	       DW   SSC_PTSB		     ;AN000;option array option word
	       DW   SCB_LIST23		     ;AN000;option array pointer offset
	       DW   0			     ;AN000;option array pointer segment
	       DW   SCB_LIST23_W	     ;AN000;option array string length
	       DW   0			     ;AN000;option array string segment
	       DB   'A'                      ;AN000;option array string term char
	       DW   0			     ;AN000;keystroke
	       DW   0			     ;AN000;log vid buf offset override
	       DW   0			     ;AN000;log vid buf segment override
	       DW   0			     ;AN000;general purpose format hook opt
	       DW   0			     ;AN000;general purpose format hook opt
	       DW   0			     ;AN000;length of translation table
	       DW   0			     ;AN000;offset of translation table
	       DW   0			     ;AN000;segment of translation table
	       DW   0			     ;AN000;monocasing table offset
	       DW   0			     ;AN000;monocasing table segment
	       DW   0			     ;AN000;dbcs table length
	       DW   0			     ;AN000;dbcs table offset
	       DW   0			     ;AN000;dbcs table segment
	       DW   0			     ;AN068;SEH offset of font descriptor block
	       DW   0			     ;AN068;SEH segment of font descriptor block
	       DB   236 DUP(0)		     ;AN024;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; SCR_ACC_KYB
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
WR_SCB24       DW   SCB_FRBF+SCB_FRAL	     ;AN000;option word one
	       DW   SCB_ROTN		     ;AN000;option word two
	       DW   0			     ;AN000;option word three
	       DW   0			     ;AN068;SEH option word four
	       DW   SND_FREQ		     ;AN000;error beep frequency
	       DW   5			     ;AN000;upper left row
	       DW   37			 ;AN000;**********;upper left column
	       DW   0			     ;AN000;relative upper left row
	       DW   0			     ;AN000;relative upper left column
	       DW   SCB_LIST24_W	     ;AN000;line width
	       DW   1			     ;AN000;number of lines
	       DW   1			     ;AN000;number of element on top
	       DW   SCB_LIST24_N	     ;AN000;number of elements
	       DW   1			     ;AN000;current element
	       DW   0			     ;AN000;maximun number of cols to scroll
	       DW   0			     ;AN000;display offset into opt strings
	       DW   1			     ;AN000;num list txt col offset in strg
	       DB   '.'                      ;AN000;numbered list separator
	       DW   0			     ;AN000;select keystroke string length
	       DW   0			     ;AN000;select keystroke string offset
	       DW   0			     ;AN000;select keystroke string segment
	       DW   0			     ;AN000;return/leave string length
	       DW   0			     ;AN000;return/leave string offset
	       DW   0			     ;AN000;return/leave string segment
	       DW   0			     ;AN000;return/erase string length
	       DW   0			     ;AN000;return/erase string offset
	       DW   0			     ;AN000;return/erase string segment
	       DW   WR_UAKEYSLEN	     ;AN000;up arrow string length
	       DW   WR_UAKEYS		     ;AN000;up arrow string offset
	       DW   0			     ;AN000;up arrow string segment
	       DW   WR_DAKEYSLEN	     ;AN000;down arrow string length
	       DW   WR_DAKEYS		     ;AN000;down arrow string offset
	       DW   0			     ;AN000;down arrow string segment
	       DW   0			     ;AN000;left arrow string length
	       DW   0			     ;AN000;left arrow string offset
	       DW   0			     ;AN000;left arrow string segment
	       DW   0			     ;AN000;right arrow string length
	       DW   0			     ;AN000;right arrow string offset
	       DW   0			     ;AN000;right arrow string segment
	       DW   0			     ;AN000;page-up string length
	       DW   0			     ;AN000;page-up string offset
	       DW   0			     ;AN000;page-up string segment
	       DW   0			     ;AN000;page-down string length
	       DW   0			     ;AN000;page-down string offset
	       DW   0			     ;AN000;page-down string segment
	       DW   WR_PIINDLEN 	     ;AN000;pointer indicator strg length
	       DW   WR_PIIND		     ;AN000;pointer indicator string offset
	       DW   0			     ;AN000;pointer indicator string segment
	       DW   1			     ;AN000;pointer ind txt col off into strg
	       DW   WR_AIINDLEN 	     ;AN000;active indicator strg length
	       DW   WR_AIIND		     ;AN000;active indicator string offset
	       DW   0			     ;AN000;active indicator string segment
	       DW   1			     ;AN000;active ind txt col off into stg
	       DW   WR_CIINDLEN 	     ;AN000;check mark text string length
	       DW   WR_CIIND		     ;AN000;check mark text string offset
	       DW   0			     ;AN000;check mark text string segment
	       DW   1			     ;AN000;check mark offset into opt strg
	       DW   WR_UIINDLEN 	     ;AN000;up indicator string length
	       DW   WR_UIIND		     ;AN000;up indicator string offset
	       DW   0			     ;AN000;up indicator string segment
	       DW   2			     ;AN000;up indicator row location
	       DW   1			     ;AN000;up indicator column location
	       DW   WR_DIINDLEN 	     ;AN000;down indicator string length
	       DW   WR_DIIND		     ;AN000;down indicator string offset
	       DW   0			     ;AN000;down indicator string segment
	       DW   2			     ;AN000;down indicator row location
	       DW   2			     ;AN000;down indicator column locaiton
	       DW   0			     ;AN000;left indicator string length
	       DW   0			     ;AN000;left indicator string offset
	       DW   0			     ;AN000;left indicator string segment
	       DW   0			     ;AN000;left indicator row location
	       DW   0			     ;AN000;left indicator column location
	       DW   0			     ;AN000;right indicator string length
	       DW   0			     ;AN000;right indicator string offset
	       DW   0			     ;AN000;right indicator string segment
	       DW   0			     ;AN000;right indicator row location
	       DW   0			     ;AN000;right indicator column locaiton
	       DW   WR_CIS		     ;AN000;normal color array offset
	       DW   0			     ;AN000;normal color array segment
	       DW   1			     ;AN000;logical color index number
	       DW   16			     ;AN000;number color index table entries
	       DW   WR_CIS		     ;AN000;offset addr of color index table
	       DW   0			     ;AN000;segment addr of color index tabl
	       DW   WR_INDEX1		     ;AN000;index array offset
	       DW   0			     ;AN000;index array segment
	       DW   WR_SELECT		     ;AN000;element selection array offset
	       DW   0			     ;AN000;element selection array segment
	       DW   SSC_PTSB		     ;AN000;option array option word
	       DW   SCB_LIST24		     ;AN000;option array pointer offset
	       DW   0			     ;AN000;option array pointer segment
	       DW   SCB_LIST24_W	     ;AN000;option array string length
	       DW   0			     ;AN000;option array string segment
	       DB   'A'                      ;AN000;option array string term char
	       DW   0			     ;AN000;keystroke
	       DW   0			     ;AN000;log vid buf offset override
	       DW   0			     ;AN000;log vid buf segment override
	       DW   0			     ;AN000;general purpose format hook opt
	       DW   0			     ;AN000;general purpose format hook opt
	       DW   0			     ;AN000;length of translation table
	       DW   0			     ;AN000;offset of translation table
	       DW   0			     ;AN000;segment of translation table
	       DW   0			     ;AN000;monocasing table offset
	       DW   0			     ;AN000;monocasing table segment
	       DW   0			     ;AN000;dbcs table length
	       DW   0			     ;AN000;dbcs table offset
	       DW   0			     ;AN000;dbcs table segment
	       DW   0			     ;AN068;SEH offset of font descriptor block
	       DW   0			     ;AN068;SEH segment of font descriptor block
	       DB   236 DUP(0)		     ;AN024;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; SCR_ACC_PRT
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
WR_SCB25       DW   SCB_FRBF+SCB_FRAL	     ;AN000;option word one
	       DW   SCB_ROTN		     ;AN000;option word two
	       DW   0			     ;AN000;option word three
	       DW   0			     ;AN068;SEH option word four
	       DW   SND_FREQ		     ;AN000;error beep frequency
	       DW   4			     ;AN000;upper left row
	       DW   32			     ;AN000;upper left column
	       DW   0			     ;AN000;relative upper left row
	       DW   0			     ;AN000;relative upper left column
	       DW   SCB_LIST11_W	     ;AN000;line width
	       DW   1			     ;AN000;number of lines
	       DW   1			     ;AN000;number of element on top
	       DW   SCB_LIST11_N	     ;AN000;number of elements
	       DW   1			     ;AN000;current element
	       DW   0			     ;AN000;maximun number of cols to scroll
	       DW   0			     ;AN000;display offset into opt strings
	       DW   1			     ;AN000;num list txt col offset in strg
	       DB   '.'                      ;AN000;numbered list separator
	       DW   0			     ;AN000;select keystroke string length
	       DW   0			     ;AN000;select keystroke string offset
	       DW   0			     ;AN000;select keystroke string segment
	       DW   0			     ;AN000;return/leave string length
	       DW   0			     ;AN000;return/leave string offset
	       DW   0			     ;AN000;return/leave string segment
	       DW   0			     ;AN000;return/erase string length
	       DW   0			     ;AN000;return/erase string offset
	       DW   0			     ;AN000;return/erase string segment
	       DW   WR_UAKEYSLEN	     ;AN000;up arrow string length
	       DW   WR_UAKEYS		     ;AN000;up arrow string offset
	       DW   0			     ;AN000;up arrow string segment
	       DW   WR_DAKEYSLEN	     ;AN000;down arrow string length
	       DW   WR_DAKEYS		     ;AN000;down arrow string offset
	       DW   0			     ;AN000;down arrow string segment
	       DW   0			     ;AN000;left arrow string length
	       DW   0			     ;AN000;left arrow string offset
	       DW   0			     ;AN000;left arrow string segment
	       DW   0			     ;AN000;right arrow string length
	       DW   0			     ;AN000;right arrow string offset
	       DW   0			     ;AN000;right arrow string segment
	       DW   0			     ;AN000;page-up string length
	       DW   0			     ;AN000;page-up string offset
	       DW   0			     ;AN000;page-up string segment
	       DW   0			     ;AN000;page-down string length
	       DW   0			     ;AN000;page-down string offset
	       DW   0			     ;AN000;page-down string segment
	       DW   WR_PIINDLEN 	     ;AN000;pointer indicator strg length
	       DW   WR_PIIND		     ;AN000;pointer indicator string offset
	       DW   0			     ;AN000;pointer indicator string segment
	       DW   1			     ;AN000;pointer ind txt col off into strg
	       DW   WR_AIINDLEN 	     ;AN000;active indicator strg length
	       DW   WR_AIIND		     ;AN000;active indicator string offset
	       DW   0			     ;AN000;active indicator string segment
	       DW   1			     ;AN000;active ind txt col off into stg
	       DW   WR_CIINDLEN 	     ;AN000;check mark text string length
	       DW   WR_CIIND		     ;AN000;check mark text string offset
	       DW   0			     ;AN000;check mark text string segment
	       DW   1			     ;AN000;check mark offset into opt strg
	       DW   WR_UIINDLEN 	     ;AN000;up indicator string length
	       DW   WR_UIIND		     ;AN000;up indicator string offset
	       DW   0			     ;AN000;up indicator string segment
	       DW   2			     ;AN000;up indicator row location
	       DW   1			     ;AN000;up indicator column location
	       DW   WR_DIINDLEN 	     ;AN000;down indicator string length
	       DW   WR_DIIND		     ;AN000;down indicator string offset
	       DW   0			     ;AN000;down indicator string segment
	       DW   2			     ;AN000;down indicator row location
	       DW   2			     ;AN000;down indicator column locaiton
	       DW   0			     ;AN000;left indicator string length
	       DW   0			     ;AN000;left indicator string offset
	       DW   0			     ;AN000;left indicator string segment
	       DW   0			     ;AN000;left indicator row location
	       DW   0			     ;AN000;left indicator column location
	       DW   0			     ;AN000;right indicator string length
	       DW   0			     ;AN000;right indicator string offset
	       DW   0			     ;AN000;right indicator string segment
	       DW   0			     ;AN000;right indicator row location
	       DW   0			     ;AN000;right indicator column locaiton
	       DW   WR_CIS		     ;AN000;normal color array offset
	       DW   0			     ;AN000;normal color array segment
	       DW   1			     ;AN000;logical color index number
	       DW   16			     ;AN000;number color index table entries
	       DW   WR_CIS		     ;AN000;offset addr of color index table
	       DW   0			     ;AN000;segment addr of color index tabl
	       DW   WR_INDEX1		     ;AN000;index array offset
	       DW   0			     ;AN000;index array segment
	       DW   WR_SELECT		     ;AN000;element selection array offset
	       DW   0			     ;AN000;element selection array segment
	       DW   SSC_PTSB		     ;AN000;option array option word
	       DW   SCB_LIST11		     ;AN000;option array pointer offset
	       DW   0			     ;AN000;option array pointer segment
	       DW   SCB_LIST11_W	     ;AN000;option array string length
	       DW   0			     ;AN000;option array string segment
	       DB   'A'                      ;AN000;option array string term char
	       DW   0			     ;AN000;keystroke
	       DW   0			     ;AN000;log vid buf offset override
	       DW   0			     ;AN000;log vid buf segment override
	       DW   0			     ;AN000;general purpose format hook opt
	       DW   0			     ;AN000;general purpose format hook opt
	       DW   0			     ;AN000;length of translation table
	       DW   0			     ;AN000;offset of translation table
	       DW   0			     ;AN000;segment of translation table
	       DW   0			     ;AN000;monocasing table offset
	       DW   0			     ;AN000;monocasing table segment
	       DW   0			     ;AN000;dbcs table length
	       DW   0			     ;AN000;dbcs table offset
	       DW   0			     ;AN000;dbcs table segment
	       DW   0			     ;AN068;SEH offset of font descriptor block
	       DW   0			     ;AN068;SEH segment of font descriptor block
	       DB   236 DUP(0)		     ;AN024;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; DOS LOCATION SUPPORT	   ;AN000;JW
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
WR_SCB26       DW   SCB_WRAP		     ;AN000;option word one
	       DW   SCB_SKIP		     ;AN000;option word two
	       DW   SCB_NUMS		     ;AN000;option word three
	       DW   0			     ;AN068;SEH option word four
	       DW   SND_FREQ		     ;AN000;error beep frequency
	       DW   17			     ;AN000;upper left row
	       DW   LEFT_COL_SCROLL	     ;AN000;upper left column
	       DW   0			     ;AN000;relative upper left row
	       DW   0			     ;AN000;relative upper left column
	       DW   SCB_LIST26_W	     ;AN000;line width
	       DW   SCB_LIST26_N	     ;AN000;number of lines
	       DW   1			     ;AN000;number of element on top
	       DW   SCB_LIST26_N	     ;AN000;number of elements
	       DW   1			     ;AN000;current element
	       DW   0			     ;AN000;maximun number of cols to scroll
	       DW   0			     ;AN000;display offset into opt strings
	       DW   1			     ;AN000;num list txt col offset in strg
	       DB   '.'                      ;AN000;numbered list separator
	       DW   0			     ;AN000;select keystroke string length
	       DW   0			     ;AN000;select keystroke string offset
	       DW   0			     ;AN000;select keystroke string segment
	       DW   0			     ;AN000;return/leave string length
	       DW   0			     ;AN000;return/leave string offset
	       DW   0			     ;AN000;return/leave string segment
	       DW   0			     ;AN000;return/erase string length
	       DW   0			     ;AN000;return/erase string offset
	       DW   0			     ;AN000;return/erase string segment
	       DW   WR_UAKEYSLEN	     ;AN000;up arrow string length
	       DW   WR_UAKEYS		     ;AN000;up arrow string offset
	       DW   0			     ;AN000;up arrow string segment
	       DW   WR_DAKEYSLEN	     ;AN000;down arrow string length
	       DW   WR_DAKEYS		     ;AN000;down arrow string offset
	       DW   0			     ;AN000;down arrow string segment
	       DW   0			     ;AN000;left arrow string length
	       DW   0			     ;AN000;left arrow string offset
	       DW   0			     ;AN000;left arrow string segment
	       DW   0			     ;AN000;right arrow string length
	       DW   0			     ;AN000;right arrow string offset
	       DW   0			     ;AN000;right arrow string segment
	       DW   WR_PUKEYSLEN	     ;AN000;page-up string length
	       DW   WR_PUKEYS		     ;AN000;page-up string offset
	       DW   0			     ;AN000;page-up string segment
	       DW   WR_PDKEYSLEN	     ;AN000;page-down string length
	       DW   WR_PDKEYS		     ;AN000;page-down string offset
	       DW   0			     ;AN000;page-down string segment
	       DW   WR_PIINDLEN 	     ;AN000;pointer indicator strg length
	       DW   WR_PIIND		     ;AN000;pointer indicator string offset
	       DW   0			     ;AN000;pointer indicator string segment
	       DW   1			     ;AN000;pointer ind txt col off into strg
	       DW   WR_AIINDLEN 	     ;AN000;active indicator strg length
	       DW   WR_AIIND		     ;AN000;active indicator string offset
	       DW   0			     ;AN000;active indicator string segment
	       DW   1			     ;AN000;active ind txt col off into stg
	       DW   WR_CIINDLEN 	     ;AN000;check mark text string length
	       DW   WR_CIIND		     ;AN000;check mark text string offset
	       DW   0			     ;AN000;check mark text string segment
	       DW   1			     ;AN000;check mark offset into opt strg
	       DW   WR_UIINDLEN 	     ;AN000;up indicator string length
	       DW   WR_UIIND		     ;AN000;up indicator string offset
	       DW   0			     ;AN000;up indicator string segment
	       DW   2			     ;AN000;up indicator row location
	       DW   1			     ;AN000;up indicator column location
	       DW   WR_DIINDLEN 	     ;AN000;down indicator string length
	       DW   WR_DIIND		     ;AN000;down indicator string offset
	       DW   0			     ;AN000;down indicator string segment
	       DW   2			     ;AN000;down indicator row location
	       DW   2			     ;AN000;down indicator column locaiton
	       DW   0			     ;AN000;left indicator string length
	       DW   0			     ;AN000;left indicator string offset
	       DW   0			     ;AN000;left indicator string segment
	       DW   0			     ;AN000;left indicator row location
	       DW   0			     ;AN000;left indicator column location
	       DW   0			     ;AN000;right indicator string length
	       DW   0			     ;AN000;right indicator string offset
	       DW   0			     ;AN000;right indicator string segment
	       DW   0			     ;AN000;right indicator row location
	       DW   0			     ;AN000;right indicator column locaiton
	       DW   0			     ;AN000;normal color array offset
	       DW   0			     ;AN000;normal color array segment
	       DW   1			     ;AN000;logical color index number
	       DW   16			     ;AN000;number color index table entries
	       DW   WR_CIS		     ;AN000;offset addr of color index table
	       DW   0			     ;AN000;segment addr of color index tabl
	       DW   WR_INDEX1		     ;AN000;index array offset
	       DW   0			     ;AN000;index array segment
	       DW   WR_SELECT_NUM	     ;AN000;element selection array offset
	       DW   0			     ;AN000;element selection array segment
	       DW   SSC_PTSB		     ;AN000;option array option word
	       DW   SCB_LIST26		     ;AN000;option array pointer offset
	       DW   0			     ;AN000;option array pointer segment
	       DW   SCB_LIST26_W	     ;AN000;option array string length
	       DW   0			     ;AN000;option array string segment
	       DB   'A'                      ;AN000;option array string term char
	       DW   0			     ;AN000;keystroke
	       DW   0			     ;AN000;log vid buf offset override
	       DW   0			     ;AN000;log vid buf segment override
	       DW   0			     ;AN000;general purpose format hook opt
	       DW   0			     ;AN000;general purpose format hook opt
	       DW   0			     ;AN000;length of translation table
	       DW   0			     ;AN000;offset of translation table
	       DW   0			     ;AN000;segment of translation table
	       DW   0			     ;AN000;monocasing table offset
	       DW   0			     ;AN000;monocasing table segment
	       DW   0			     ;AN000;dbcs table length
	       DW   0			     ;AN000;dbcs table offset
	       DW   0			     ;AN000;dbcs table segment
	       DW   0			     ;AN068;SEH offset of font descriptor block
	       DW   0			     ;AN068;SEH segment of font descriptor block
	       DB   236 DUP(0)		     ;AN024;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; select drive a: or c:  ;AN111;JW
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
WR_SCB27       DW   SCB_WRAP		     ;AN000;option word one
	       DW   SCB_SKIP		     ;AN000;option word two
	       DW   SCB_NUMS		     ;AN000;option word three
	       DW   0			     ;AN068;SEH option word four
	       DW   SND_FREQ		     ;AN000;error beep frequency
	       DW   8			     ;AN000;upper left row
	       DW   LEFT_COL_SCROLL	     ;AN000;upper left column
	       DW   0			     ;AN000;relative upper left row
	       DW   0			     ;AN000;relative upper left column
	       DW   SCB_LIST27_W	     ;AN000;line width
	       DW   SCB_LIST27_N	     ;AN000;number of lines
	       DW   1			     ;AN000;number of element on top
	       DW   SCB_LIST27_N	     ;AN000;number of elements
	       DW   1			     ;AN000;current element
	       DW   0			     ;AN000;maximun number of cols to scroll
	       DW   0			     ;AN000;display offset into opt strings
	       DW   1			     ;AN000;num list txt col offset in strg
	       DB   '.'                      ;AN000;numbered list separator
	       DW   0			     ;AN000;select keystroke string length
	       DW   0			     ;AN000;select keystroke string offset
	       DW   0			     ;AN000;select keystroke string segment
	       DW   0			     ;AN000;return/leave string length
	       DW   0			     ;AN000;return/leave string offset
	       DW   0			     ;AN000;return/leave string segment
	       DW   0			     ;AN000;return/erase string length
	       DW   0			     ;AN000;return/erase string offset
	       DW   0			     ;AN000;return/erase string segment
	       DW   WR_UAKEYSLEN	     ;AN000;up arrow string length
	       DW   WR_UAKEYS		     ;AN000;up arrow string offset
	       DW   0			     ;AN000;up arrow string segment
	       DW   WR_DAKEYSLEN	     ;AN000;down arrow string length
	       DW   WR_DAKEYS		     ;AN000;down arrow string offset
	       DW   0			     ;AN000;down arrow string segment
	       DW   0			     ;AN000;left arrow string length
	       DW   0			     ;AN000;left arrow string offset
	       DW   0			     ;AN000;left arrow string segment
	       DW   0			     ;AN000;right arrow string length
	       DW   0			     ;AN000;right arrow string offset
	       DW   0			     ;AN000;right arrow string segment
	       DW   0			     ;AN000;page-up string length
	       DW   0			     ;AN000;page-up string offset
	       DW   0			     ;AN000;page-up string segment
	       DW   0			     ;AN000;page-down string length
	       DW   0			     ;AN000;page-down string offset
	       DW   0			     ;AN000;page-down string segment
	       DW   WR_PIINDLEN 	     ;AN000;pointer indicator strg length
	       DW   WR_PIIND		     ;AN000;pointer indicator string offset
	       DW   0			     ;AN000;pointer indicator string segment
	       DW   1			     ;AN000;pointer ind txt col off into strg
	       DW   WR_AIINDLEN 	     ;AN000;active indicator strg length
	       DW   WR_AIIND		     ;AN000;active indicator string offset
	       DW   0			     ;AN000;active indicator string segment
	       DW   1			     ;AN000;active ind txt col off into stg
	       DW   WR_CIINDLEN 	     ;AN000;check mark text string length
	       DW   WR_CIIND		     ;AN000;check mark text string offset
	       DW   0			     ;AN000;check mark text string segment
	       DW   1			     ;AN000;check mark offset into opt strg
	       DW   WR_UIINDLEN 	     ;AN000;up indicator string length
	       DW   WR_UIIND		     ;AN000;up indicator string offset
	       DW   0			     ;AN000;up indicator string segment
	       DW   2			     ;AN000;up indicator row location
	       DW   1			     ;AN000;up indicator column location
	       DW   WR_DIINDLEN 	     ;AN000;down indicator string length
	       DW   WR_DIIND		     ;AN000;down indicator string offset
	       DW   0			     ;AN000;down indicator string segment
	       DW   2			     ;AN000;down indicator row location
	       DW   2			     ;AN000;down indicator column locaiton
	       DW   0			     ;AN000;left indicator string length
	       DW   0			     ;AN000;left indicator string offset
	       DW   0			     ;AN000;left indicator string segment
	       DW   0			     ;AN000;left indicator row location
	       DW   0			     ;AN000;left indicator column location
	       DW   0			     ;AN000;right indicator string length
	       DW   0			     ;AN000;right indicator string offset
	       DW   0			     ;AN000;right indicator string segment
	       DW   0			     ;AN000;right indicator row location
	       DW   0			     ;AN000;right indicator column locaiton
	       DW   0			     ;AN000;normal color array offset
	       DW   0			     ;AN000;normal color array segment
	       DW   1			     ;AN000;logical color index number
	       DW   16			     ;AN000;number color index table entries
	       DW   WR_CIS		     ;AN000;offset addr of color index table
	       DW   0			     ;AN000;segment addr of color index tabl
	       DW   WR_INDEX1		     ;AN000;index array offset
	       DW   0			     ;AN000;index array segment
	       DW   WR_SELECT_NUM	     ;AN000;element selection array offset
	       DW   0			     ;AN000;element selection array segment
	       DW   SSC_PTSB		     ;AN000;option array option word
	       DW   SCB_LIST27		     ;AN000;option array pointer offset
	       DW   0			     ;AN000;option array pointer segment
	       DW   SCB_LIST27_W	     ;AN000;option array string length
	       DW   0			     ;AN000;option array string segment
	       DB   'A'                      ;AN000;option array string term char
	       DW   0			     ;AN000;keystroke
	       DW   0			     ;AN000;log vid buf offset override
	       DW   0			     ;AN000;log vid buf segment override
	       DW   0			     ;AN000;general purpose format hook opt
	       DW   0			     ;AN000;general purpose format hook opt
	       DW   0			     ;AN000;length of translation table
	       DW   0			     ;AN000;offset of translation table
	       DW   0			     ;AN000;segment of translation table
	       DW   0			     ;AN000;monocasing table offset
	       DW   0			     ;AN000;monocasing table segment
	       DW   0			     ;AN000;dbcs table length
	       DW   0			     ;AN000;dbcs table offset
	       DW   0			     ;AN000;dbcs table segment
	       DW   0			     ;AN068;SEH offset of font descriptor block
	       DW   0			     ;AN068;SEH segment of font descriptor block
	       DB   236 DUP(0)		     ;AN024;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; chose shell
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
WR_SCB28       DW   SCB_WRAP		     ;AN000;option word one
	       DW   SCB_SKIP		     ;AN000;option word two
	       DW   SCB_NUMS		     ;AN000;option word three
	       DW   0			     ;AN068;SEH option word four
	       DW   SND_FREQ		     ;AN000;error beep frequency
	       DW   11			     ;AC079;SEH ;AN000;upper left row
	       DW   LEFT_COL_SCROLL	     ;AN000;upper left column
	       DW   0			     ;AN000;relative upper left row
	       DW   0			     ;AN000;relative upper left column
	       DW   SCB_LIST28_W	     ;AN000;line width
	       DW   SCB_LIST28_N	     ;AN000;number of lines
	       DW   1			     ;AN000;number of element on top
	       DW   SCB_LIST28_N	     ;AN000;number of elements
	       DW   1			     ;AN000;current element
	       DW   0			     ;AN000;maximun number of cols to scroll
	       DW   0			     ;AN000;display offset into opt strings
	       DW   1			     ;AN000;num list txt col offset in strg
	       DB   '.'                      ;AN000;numbered list separator
	       DW   0			     ;AN000;select keystroke string length
	       DW   0			     ;AN000;select keystroke string offset
	       DW   0			     ;AN000;select keystroke string segment
	       DW   0			     ;AN000;return/leave string length
	       DW   0			     ;AN000;return/leave string offset
	       DW   0			     ;AN000;return/leave string segment
	       DW   0			     ;AN000;return/erase string length
	       DW   0			     ;AN000;return/erase string offset
	       DW   0			     ;AN000;return/erase string segment
	       DW   WR_UAKEYSLEN	     ;AN000;up arrow string length
	       DW   WR_UAKEYS		     ;AN000;up arrow string offset
	       DW   0			     ;AN000;up arrow string segment
	       DW   WR_DAKEYSLEN	     ;AN000;down arrow string length
	       DW   WR_DAKEYS		     ;AN000;down arrow string offset
	       DW   0			     ;AN000;down arrow string segment
	       DW   0			     ;AN000;left arrow string length
	       DW   0			     ;AN000;left arrow string offset
	       DW   0			     ;AN000;left arrow string segment
	       DW   0			     ;AN000;right arrow string length
	       DW   0			     ;AN000;right arrow string offset
	       DW   0			     ;AN000;right arrow string segment
	       DW   0			     ;AN000;page-up string length
	       DW   0			     ;AN000;page-up string offset
	       DW   0			     ;AN000;page-up string segment
	       DW   0			     ;AN000;page-down string length
	       DW   0			     ;AN000;page-down string offset
	       DW   0			     ;AN000;page-down string segment
	       DW   WR_PIINDLEN 	     ;AN000;pointer indicator strg length
	       DW   WR_PIIND		     ;AN000;pointer indicator string offset
	       DW   0			     ;AN000;pointer indicator string segment
	       DW   1			     ;AN000;pointer ind txt col off into strg
	       DW   WR_AIINDLEN 	     ;AN000;active indicator strg length
	       DW   WR_AIIND		     ;AN000;active indicator string offset
	       DW   0			     ;AN000;active indicator string segment
	       DW   1			     ;AN000;active ind txt col off into stg
	       DW   WR_CIINDLEN 	     ;AN000;check mark text string length
	       DW   WR_CIIND		     ;AN000;check mark text string offset
	       DW   0			     ;AN000;check mark text string segment
	       DW   1			     ;AN000;check mark offset into opt strg
	       DW   WR_UIINDLEN 	     ;AN000;up indicator string length
	       DW   WR_UIIND		     ;AN000;up indicator string offset
	       DW   0			     ;AN000;up indicator string segment
	       DW   2			     ;AN000;up indicator row location
	       DW   1			     ;AN000;up indicator column location
	       DW   WR_DIINDLEN 	     ;AN000;down indicator string length
	       DW   WR_DIIND		     ;AN000;down indicator string offset
	       DW   0			     ;AN000;down indicator string segment
	       DW   2			     ;AN000;down indicator row location
	       DW   2			     ;AN000;down indicator column locaiton
	       DW   0			     ;AN000;left indicator string length
	       DW   0			     ;AN000;left indicator string offset
	       DW   0			     ;AN000;left indicator string segment
	       DW   0			     ;AN000;left indicator row location
	       DW   0			     ;AN000;left indicator column location
	       DW   0			     ;AN000;right indicator string length
	       DW   0			     ;AN000;right indicator string offset
	       DW   0			     ;AN000;right indicator string segment
	       DW   0			     ;AN000;right indicator row location
	       DW   0			     ;AN000;right indicator column locaiton
	       DW   WR_CIS		     ;AN000;normal color array offset
	       DW   0			     ;AN000;normal color array segment
	       DW   1			     ;AN000;logical color index number
	       DW   16			     ;AN000;number color index table entries
	       DW   WR_CIS		     ;AN000;offset addr of color index table
	       DW   0			     ;AN000;segment addr of color index tabl
	       DW   WR_INDEX1		     ;AN000;index array offset
	       DW   0			     ;AN000;index array segment
	       DW   WR_SELECT_NUM	     ;AN000;element selection array offset
	       DW   0			     ;AN000;element selection array segment
	       DW   SSC_PTSB		     ;AN000;option array option word
	       DW   SCB_LIST28		     ;AN000;option array pointer offset
	       DW   0			     ;AN000;option array pointer segment
	       DW   SCB_LIST28_W	     ;AN000;option array string length
	       DW   0			     ;AN000;option array string segment
	       DB   'A'                      ;AN000;option array string term char
	       DW   0			     ;AN000;keystroke
	       DW   0			     ;AN000;log vid buf offset override
	       DW   0			     ;AN000;log vid buf segment override
	       DW   0			     ;AN000;general purpose format hook opt
	       DW   0			     ;AN000;general purpose format hook opt
	       DW   0			     ;AN000;length of translation table
	       DW   0			     ;AN000;offset of translation table
	       DW   0			     ;AN000;segment of translation table
	       DW   0			     ;AN000;monocasing table offset
	       DW   0			     ;AN000;monocasing table segment
	       DW   0			     ;AN000;dbcs table length
	       DW   0			     ;AN000;dbcs table offset
	       DW   0			     ;AN000;dbcs table segment
	       DW   0			     ;AN068;SEH offset of font descriptor block
	       DW   0			     ;AN068;SEH segment of font descriptor block
	       DB   236 DUP(0)		     ;AN024;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Keystroke Strings and length calculations
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
WR_REHLPKEYS	DB   0,F1,0,F9,ESCAPE	     ;AN000;return/erase keystroke string
WR_REHLPKEYSLEN EQU  ($-WR_REHLPKEYS)	     ;AN000;

WR_UAKEYS      DB   0,UPARROW		     ;AN000;up arrow keystroke string
WR_UAKEYSLEN   EQU  ($-WR_UAKEYS)	     ;AN000;

WR_DAKEYS      DB   0,DNARROW		     ;AN000;down arrow keystroke string
WR_DAKEYSLEN   EQU  ($-WR_DAKEYS)	     ;AN000;


WR_PUKEYS      DB   0,PGUP		     ;AN000;define page up key buffer
WR_PUKEYSLEN   EQU  ($-WR_PUKEYS)	     ;AN000;

WR_PDKEYS      DB   0,PGDN		     ;AN000;define page down key buffer
WR_PDKEYSLEN   EQU  ($-WR_PDKEYS)	     ;AN000;

WR_UIIND       DB   24			     ;AN000;define up indicator buffer
WR_UIINDLEN    EQU  ($-WR_UIIND)	     ;AN000;

WR_DIIND       DB   25			     ;AN000;define down indicator buffer
WR_DIINDLEN    EQU  ($-WR_DIIND)	     ;AN000;

WR_PIIND       DB   '�'                      ;AN000;selection pointer indicator buff
WR_PIINDLEN    EQU  ($-WR_PIIND)	     ;AN000;

WR_AIIND       DB   '<'                      ;AN000;active string indicator buffer
WR_AIINDLEN    EQU  ($-WR_AIIND)	     ;AN000;

WR_CIIND       DB   '>'                      ;AN000;check mark string indicator buff
WR_CIINDLEN    EQU  ($-WR_CIIND)	     ;AN000;

;
; Selection array structure
;
WR_SELECT_NUM  DW   SCB_ACTIVEON	     ;AN000;
	       DW   SCB_SKIPON		     ;AN000;
	       DW   SCB_ACTIVEON	     ;AN000;
	       DW   SCB_SKIPON		     ;AN000;
	       DW   SCB_ACTIVEON	     ;AN000;
	       DW   SCB_SKIPON		     ;AN000;
	       DW   SCB_ACTIVEON	     ;AN000;
	       DW   SCB_SKIPON		     ;AN000;
	       DW   SCB_ACTIVEON	     ;AN000;
	       DW   SCB_SKIPON		     ;AN000;
	       DW   SCB_ACTIVEON	     ;AN000;

WR_SELECT      DW   SCB_ACTIVEON	     ;AN000;
	       DW   SCB_ACTIVEON	     ;AN000;
	       DW   SCB_ACTIVEON	     ;AN000;
	       DW   SCB_ACTIVEON	     ;AN000;
	       DW   SCB_ACTIVEON	     ;AN000;
	       DW   SCB_ACTIVEON	     ;AN000;
	       DW   SCB_ACTIVEON	     ;AN000;
	       DW   SCB_ACTIVEON	     ;AN000;
	       DW   SCB_ACTIVEON	     ;AN000;
	       DW   SCB_ACTIVEON	     ;AN000;
	       DW   SCB_ACTIVEON	     ;AN000;
	       DW   SCB_ACTIVEON	     ;AN000;
WR_SELECT_MOD  DW   10 DUP (0)		     ;AN000;

	INCLUDE 	PANEL.INF	     ;AN000;

CODE	ENDS				     ;AN000;
	END				     ;AN000;
