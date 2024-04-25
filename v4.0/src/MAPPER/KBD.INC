; KeyData

KeyData         struc

Char_Code       db      ?
Scan_Code       db      ?
Status          db      ?
Shift_State     dw      ?
Time            dd      ?

KeyData         ends



KbdStatus       struc

KS_Length               dw      ?
Bit_mask                dw      ?
Turn_Around_Char        dw      ?
Interim_Char_Flags      dw      ?
Status_Shift_State      dw      ?

KbdStatus       ends

; Bit_Mask equates

CookedModeOn    equ     8
RawModeOn       equ     4
EchoOff         equ     2
EchoOn          equ     1


        include macros.inc

