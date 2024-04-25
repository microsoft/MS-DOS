;       Static Name Aliases
;
        TITLE   bootrec.asm - master boot record images for fdisk

_TEXT   SEGMENT BYTE PUBLIC 'CODE'
_TEXT   ENDS
_DATA   SEGMENT WORD PUBLIC 'DATA'
_DATA   ENDS
CONST   SEGMENT WORD PUBLIC 'CONST'
CONST   ENDS
_BSS    SEGMENT WORD PUBLIC 'BSS'
_BSS    ENDS

DGROUP  GROUP     CONST,  _BSS,   _DATA
        ASSUME  CS: _TEXT, DS: DGROUP, SS: DGROUP, ES: DGROUP

_DATA   SEGMENT  WORD PUBLIC 'DATA'

;
;               extern  struct struct-name BootRecordData;
;
;
;


PUBLIC  _master_boot_record
        public  _master_boot_record
_master_boot_record label   byte

include fdboot.inc
include fdboot.inc

_DATA      ENDS

END
