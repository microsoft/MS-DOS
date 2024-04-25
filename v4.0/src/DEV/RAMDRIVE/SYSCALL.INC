BREAK <system call definitions>

Abort				EQU 0	;  0	  0
Std_Con_Input			EQU 1	;  1	  1
Std_Con_Output			EQU 2	;  2	  2
Std_Aux_Input			EQU 3	;  3	  3
Std_Aux_Output			EQU 4	;  4	  4
Std_Printer_Output		EQU 5	;  5	  5
Raw_Con_IO			EQU 6	;  6	  6
Raw_Con_Input			EQU 7	;  7	  7
Std_Con_Input_No_Echo		EQU 8	;  8	  8
Std_Con_String_Output		EQU 9	;  9	  9
Std_Con_String_Input		EQU 10	; 10	  A
Std_Con_Input_Status		EQU 11	; 11	  B
Std_Con_Input_Flush		EQU 12	; 12	  C
Disk_Reset			EQU 13	; 13	  D
Set_Default_Drive		EQU 14	; 14	  E
FCB_Open			EQU 15	; 15	  F
FCB_Close			EQU 16	; 16	 10
Dir_Search_First		EQU 17	; 17	 11
Dir_Search_Next 		EQU 18	; 18	 12
FCB_Delete			EQU 19	; 19	 13
FCB_Seq_Read			EQU 20	; 20	 14
FCB_Seq_Write			EQU 21	; 21	 15
FCB_Create			EQU 22	; 22	 16
FCB_Rename			EQU 23	; 23	 17
Get_Default_Drive		EQU 25	; 25	 19
Set_DMA 			EQU 26	; 26	 1A
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
;	     C	A  V  E  A  T	  P  R	O  G  R  A  M  M  E  R		   ;
;									   ;
Get_Default_DPB 		EQU 31	; 31	 1F
;									   ;
;	     C	A  V  E  A  T	  P  R	O  G  R  A  M  M  E  R		   ;
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
FCB_Random_Read 		EQU 33	; 33	 21
FCB_Random_Write		EQU 34	; 34	 22
Get_FCB_File_Length		EQU 35	; 35	 23
Get_FCB_Position		EQU 36	; 36	 24
Set_Interrupt_Vector		EQU 37	; 37	 25
Create_Process_Data_Block	EQU 38	; 38	 26
FCB_Random_Read_Block		EQU 39	; 39	 27
FCB_Random_Write_Block		EQU 40	; 40	 28
Parse_File_Descriptor		EQU 41	; 41	 29
Get_Date			EQU 42	; 42	 2A
Set_Date			EQU 43	; 43	 2B
Get_Time			EQU 44	; 44	 2C
Set_Time			EQU 45	; 45	 2D
Set_Verify_On_Write		EQU 46	; 46	 2E
; Extended functionality group
Get_DMA 			EQU 47	; 47	 2F
Get_Version			EQU 48	; 48	 30
Keep_Process			EQU 49	; 49	 31
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
;	     C	A  V  E  A  T	  P  R	O  G  R  A  M  M  E  R		   ;
;									   ;
Get_DPB 			EQU 50	; 50	 32
;									   ;
;	     C	A  V  E  A  T	  P  R	O  G  R  A  M  M  E  R		   ;
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
Set_CTRL_C_Trapping		EQU 51	; 51	 33
Get_InDOS_Flag			EQU 52	; 52	 34
Get_Interrupt_Vector		EQU 53	; 53	 35
Get_Drive_Freespace		EQU 54	; 54	 36
Char_Oper			EQU 55	; 55	 37
International			EQU 56	; 56	 38
;   Directory Group
MKDir				EQU 57	; 57	 39
RMDir				EQU 58	; 58	 3A
CHDir				EQU 59	; 59	 3B
;   File Group
Creat				EQU 60	; 60	 3C
Open				EQU 61	; 61	 3D
Close				EQU 62	; 62	 3E
Read				EQU 63	; 63	 3F
Write				EQU 64	; 64	 40
Unlink				EQU 65	; 65	 41
LSeek				EQU 66	; 66	 42
CHMod				EQU 67	; 67	 43
IOCtl				EQU 68	; 68	 44
XDup				EQU 69	; 69	 45
XDup2				EQU 70	; 70	 46
Current_Dir			EQU 71	; 71	 47
;    Memory Group
Alloc				EQU 72	; 72	 48
Dealloc 			EQU 73	; 73	 49
Setblock			EQU 74	; 74	 4A
;    Process Group
Exec				EQU 75	; 75	 4B
Exit				EQU 76	; 76	 4C
Wait				EQU 77	; 77	 4D
Find_First			EQU 78	; 78	 4E
;   Special Group
Find_Next			EQU 79	; 79	 4F
; SPECIAL SYSTEM GROUP
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
;	     C	A  V  E  A  T	  P  R	O  G  R  A  M  M  E  R		   ;
;									   ;
Set_Current_PDB 		EQU 80	; 80	 50
Get_Current_PDB 		EQU 81	; 81	 51
Get_In_Vars			EQU 82	; 82	 52
SetDPB				EQU 83	; 83	 53
;									   ;
;	     C	A  V  E  A  T	  P  R	O  G  R  A  M  M  E  R		   ;
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
Get_Verify_On_Write		EQU 84	; 84	 54
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
;	     C	A  V  E  A  T	  P  R	O  G  R  A  M  M  E  R		   ;
;									   ;
Dup_PDB 			EQU 85	; 85	 55
;									   ;
;	     C	A  V  E  A  T	  P  R	O  G  R  A  M  M  E  R		   ;
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
Rename				EQU 86	; 86	 56
File_Times			EQU 87	; 87	 57
AllocOper			EQU 88	; 88	 58
; Network extention system calls
GetExtendedError		EQU 89	; 89	 59
CreateTempFile			EQU 90	; 90	 5A
CreateNewFile			EQU 91	; 91	 5B
LockOper			EQU 92	; 92	 5C Lock and Unlock
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
;	     C	A  V  E  A  T	  P  R	O  G  R  A  M  M  E  R		   ;
;									   ;
ServerCall			EQU 93	; 93	 5D CommitAll, ServerDOSCall,
					;	    CloseByName, CloseUser,
					;	    CloseUserProcess,
					;	    GetOpenFileList
;									   ;
;	     C	A  V  E  A  T	  P  R	O  G  R  A  M  M  E  R		   ;
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
UserOper			EQU 94	; 94	 5E Get and Set
AssignOper			EQU 95	; 95	 5F On, Off, Get, Set, Cancel
xNameTrans			EQU 96	; 96	 60
PathParse			EQU 97	; 97	 61
GetCurrentPSP			EQU 98	; 98	 62
Hongeul 			EQU 99	; 99	 63

Set_Oem_Handler 		EQU 248 ; 248	 F8
OEM_C1				EQU 249 ; 249	 F9
OEM_C2				EQU 250 ; 250	 FA
OEM_C3				EQU 251 ; 251	 FB
OEM_C4				EQU 252 ; 252	 FC
OEM_C5				EQU 253 ; 253	 FD
OEM_C6				EQU 254 ; 254	 FE
OEM_C7				EQU 255 ; 255	 FF
