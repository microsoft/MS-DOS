;*************************************
; COMMAND EQUs which are switch dependant

IF1
    IF IBM
        %OUT IBM version
    ELSE
        %OUT Normal version
    ENDIF

    IF   HIGHMEM
        %OUT Highmem version
    ENDIF

    IF   KANJI
        %OUT Kanji version
    ENDIF
ENDIF
