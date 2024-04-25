


.seq
stack       segment  Stack  'STACK' ; represents STACK                            ;AN000;
stack       ends                                                             ;AN000;

cseg_main   segment   Public 'CODE'; represents MAIN
cseg_main   ends

cseg_open   segment   Public 'CODE'; represents  FASTOPEN                          ;AN000;
cseg_open   ends                                                             ;AN000;

cseg_seek   segment   Public 'CODE'; represents FASTSEEK                           ;AN000;
cseg_seek   ends                                                             ;AN000;

cseg_init   segment  Public 'CODE' ; represents INIT
cseg_init   ends

