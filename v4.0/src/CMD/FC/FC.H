struct lineType {
    int     line;                       /* line number                       */
    unsigned char    text[MAXARG];              /* body of line                      */
};

#define byte  unsigned char
#define word  unsigned short

#define LOWVERSION   0x0300 + 10
#define HIGHVERSION  0x0400 + 00

extern unsigned char _ctype_[];
#define _SPACE        0x8       /* tab, carriage return, new line, */
#define ISSPACE(c)     ( (_ctype_+1)[c] & _SPACE )
