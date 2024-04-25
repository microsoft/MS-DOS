TITLE	SORT Messages

false	equ	0
true	equ	not	false
msver	equ	false
ibm	equ	true
internat	equ	true

msg	Macro	lbl,msg
local a
public	lbl,lbl&len
lbl&len dw	a - lbl
lbl	db	msg
a	label	byte
endm

CONST	SEGMENT PUBLIC BYTE

if	internat
	public	table
;This table defibes the coalating sequence to be used for
;international characters.  This table also equates
;lower case character to upper case unlike a straight ASCII sort.
;If your character set is like the IBM PC simply turn
;on the IBM conditional.  If it is different simply modify the
;table appropriately.  Note: to insert a foreign language character
;between two ASCII characters it will be necessary to
;"shift" all the ASCII characters to make room for a new character.
;If this is done be sure to equate the foreign characters to the new
;values instead of the old values which have been set here to the
;upper case ASCII values.

table	db	0,1,2,3,4,5,6,7
	db	8,9,10,11,12,13,14,15
	db	16,17,18,19,20,21,22,23
	db	24,25,26,27,28,29,30,31
	db	" ","!",'"',"#","$","%","&","'"
	db	"(",")","*","+",",","-",".","/"
	db	"0","1","2","3","4","5","6","7"
	db	"8","9",":",";","<","=",">","?"
	db	"@","A","B","C","D","E","F","G"
	db	"H","I","J","K","L","M","N","O"
	db	"P","Q","R","S","T","U","V","W"
	db	"X","Y","Z","[","\","]","^","_"
	db	"`","A","B","C","D","E","F","G"
	db	"H","I","J","K","L","M","N","O"
	db	"P","Q","R","S","T","U","V","W"
	db	"X","Y","Z","{","|","}","~",127
if	msver
	db	128,129,130,131,132,133,134,135
	db	136,137,138,139,140,141,142,143
	db	144,145,146,147,148,149,150,151
	db	152,153,154,155,156,157,158,159
	db	160,161,162,163,164,165,166,167
	db	168,169,170,171,172,173,174,175
	endif
if	ibm
	db	"C","U","E","A","A","A","A","C"
	db	"E","E","E","I","I","I","A","A"
	db	"E","A","A","O","O","O","U","U"
	db	"Y","O","U","$","$","$","$","$"
	db	"A","I","O","U","N","N",166,167
	db	"?",169,170,171,172,"!",'"','"'
	endif
	db	176,177,178,179,180,181,182,183
	db	184,185,186,187,188,189,190,191
	db	192,193,194,195,196,197,198,199
	db	200,201,202,203,204,205,206,207
	db	208,209,210,211,212,213,214,215
	db	216,217,218,219,220,221,222,223
if	ibm
	db	224,"S"
endif
if	msver
	db	224,225
endif
	db	226,227,228,229,230,231
	db	232,233,234,235,236,237,238,239
	db	240,241,242,243,244,245,246,247
	db	248,249,250,251,252,253,254,255
	endif

CONST	ENDS
	END
