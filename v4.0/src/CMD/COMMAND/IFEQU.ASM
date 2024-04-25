;       SCCSID = @(#)ifequ.asm  1.1 85/05/14
;       SCCSID = @(#)ifequ.asm  1.1 85/05/14
;*************************************
; COMMAND EQUs which are switch dependant

IF1
    IF IBM
        %OUT DBCS Enabled IBM  version
    ELSE
        %OUT Normal version
    ENDIF

;;  IF   KANJI                  3/3/KK
;;      %OUT Kanji version      3/3/KK
;;  ENDIF                       3/3/KK

ENDIF
