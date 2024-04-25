	TITLE	Message texts for FLUSH13

PAGE	58,132

CONST	SEGMENT WORD PUBLIC 'DATA'
CONST	ENDS

_BSS	SEGMENT WORD PUBLIC 'DATA'
_BSS	ENDS

_DATA	SEGMENT WORD PUBLIC 'DATA'
_DATA	ENDS

DGROUP	    GROUP   CONST, _BSS, _DATA

ASSUME	DS:DGROUP

_DATA	 SEGMENT

	public	_SWTCH_CONF
	public	_BAD_PARM
	public	_NO_DEV_MESS
	public	_IOCTL_BAD_MESS
	public	_STATUS_MES1
	public	_STATUS_MES2
	public	_DISSTRING
	public	_ENSTRING
	public	_OFFSTRING
	public	_ONSTRING
	public	_LOCKSTRING
	public	_UNLSTRING
	public	_REBOOT_MES
	public	_STATUS_3R
	public	_STATUS_3W
	public	_STATUS_3T
	public	_CACHE_MES
	public	_WT_MES
	public	_WB_MES
	public	_L_MES
	public	_C_MES
	public	_T_MES
	public	_STATUS_4
	public	_STATUS_5

;
; Messages
;
_SWTCH_CONF	DB	"Conflicting switch specified",13,10
_BAD_PARM	DB	"Usage:",13,10," FLUSH13 [/s|/sx|/sr] [/d|/e] [/l|/u] [/i] [/f] [/wt:on|/wt:off]",13,10
		DB	"         [/wc:on|/wc:off] [/t:nnnnn] [/c:on|/c:off]",0

_NO_DEV_MESS	 DB	 "SMARTDRV device not found, or device error",0

_IOCTL_BAD_MESS  DB	 "SMARTDRV device function failed",0

_STATUS_MES1 DB  "SMARTDRV Device is NUL (instalation failed)",13,10,0

_STATUS_MES2 DB "FLUSH13/SMARTDRV version 1.00",13,10,0
_CACHE_MES  DB	"    Caching is %-8s",0
_L_MES	    DB	"                   Cache is %-8s",13,10,0

_WB_MES     DB	"    Write Caching is %-3s",0
_REBOOT_MES DB	"                  Reboot flush is %-3s",13,10,0

_C_MES	    DB	"    Caching of full track reads is %-3s",0
_WT_MES     DB	"    Write Through is %-3s",13,10,0

_T_MES	    DB	"    Cache is auto flushed every %2u:%02u minutes (%u ticks)",13,10,0

_DISSTRING  DB	"DISABLED",0
_ENSTRING   DB	"ENABLED",0
_OFFSTRING  DB	"OFF",0
_ONSTRING   DB	"ON",0
_LOCKSTRING DB	"LOCKED",0
_UNLSTRING  DB	"UNLOCKED",0


_STATUS_3W   DB  "    %10lu Write hits out of %10lu Total Writes.     Hit rate %3u%%",13,10,0
_STATUS_3R   DB  "    %10lu Read hits out of  %10lu Total Reads.      Hit rate %3u%%",13,10,0
_STATUS_3T   DB  "    %10lu hits out of       %10lu Total operations. Hit rate %3u%%",13,10,0
_STATUS_4    DB  "    %3u Total tracks, %3u are used, %3u are locked, %3u are dirty",13,10,0

_STATUS_5    DB  "    %4u - Current Size, %4u - Initial Size, %4u - Minimum Size",13,10,0

_DATA	 ENDS
	END
