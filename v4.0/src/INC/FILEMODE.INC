;	SCCSID = @(#)filemode.asm	1.1 85/04/10
;	SCCSID = @(#)filemode.asm	1.1 85/04/10
BREAK <Standard I/O assignments>

stdin	    EQU     0
stdout	    EQU     1
stderr	    EQU     2
stdaux	    EQU     3
stdprn	    EQU     4

BREAK <File modes>

access_mask	EQU 0FH
open_for_read	EQU 00h
open_for_write	EQU 01h
open_for_both	EQU 02h

sharing_mask	    EQU 0F0H
sharing_compat	    EQU 000H
sharing_deny_both   EQU 010H
sharing_deny_write  EQU 020H
sharing_deny_read   EQU 030H
sharing_deny_none   EQU 040H
sharing_net_FCB     EQU 070h
sharing_no_inherit  EQU 080H

BREAK <Extended Open>

no_code_page_check	  EQU 0100H
int_24_error		  EQU 2000H
auto_commit_write	  EQU 4000H
ext_open_on		  EQU 01H
ext_file_not_exists	  EQU 04H
ext_open_I24_off	  EQU 02H
io_mode_id		  EQU 00000010B
reserved_bits_mask	  EQU 0FE00H
exists_mask		  EQU 0FH
not_exists_mask 	  EQU 0F0H
action_opened		  EQU  01H
action_created_opened	  EQU  02H
action_replaced_opened	  EQU  03H

ext_exists_open     EQU 01H
ext_exists_fail     EQU 0H
ext_nexists_create  EQU 10H



ext_open_parm	   struc
ext_set_list	    dd ?
ext_num_of_parm     dw ?
ext_open_parm	   ends



