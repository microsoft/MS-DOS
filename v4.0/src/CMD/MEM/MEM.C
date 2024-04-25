
/*----------------------------------------------------------------------+
|                                                                       |
|                                                                       |
|       Title:          MEM                                             |
|                                                                       |
|       Syntax:                                                         |
|                                                                       |
|               From the DOS command line:                              |
|                                                                       |
|               MEM                                                     |
|                       - Used to display DOS memory map summary.       |
|                                                                       |
|               MEM /PROGRAM                                            |
|                       - Used to display DOS memory map.               |
|                                                                       |
|               MEM /DEBUG                                              |
|                       - Used to display a detailed DOS memory map.    |
|                                                                       |
|       AN001 - PTM P2914 -> This PTM relates to MEM's ability to report|
|                            the accurate total byte count for EM       |
|                            memory.                                    |
|                                                                       |
|       AN002 - PTM P3477 -> MEM was displaying erroneous base memory   |
|                            information for "Total" and "Available"    |
|                            memory.  This was due to incorrect logic   |
|                            for RAM carving.                           |
|                                                                       |
|       AN003 - PTM P3912 -> MEM messages do not conform to spec.       |
|               PTM P3989                                               |
|                                                                       |
|               Date: 1/28/88                                           |
|                                                                       |
|       AN004 - PTM P4510 -> MEM does not give correct DOS size.        |
|                                                                       |
|               Date: 4/27/88                                           |
|                                                                       |
|       AN005 - PTM P4957 -> MEM does not give correct DOS size for     |
|                            programs loaded into high memory.          |
|                                                                       |
|               Date: 6/07/88                                           |
|                                                                       |
+----------------------------------------------------------------------*/

/*컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�*/

#include "ctype.h"                                                                                           /* ;an000; */
#include "conio.h"                      /* need for kbhit prototype */                                       /* ;an000; */
#include "stdio.h"                                                                                           /* ;an000; */
#include "dos.h"                                                                                             /* ;an000; */
#include "string.h"                                                                                          /* ;an000; */
#include "stdlib.h"                                                                                          /* ;an000; */
#include "msgdef.h"                                                                                          /* ;an000; */
#include "parse.h"                                                                                           /* ;an000; */

/* #include "copyrigh.h" */     /* Only need one copyright statement an004 */
                                /* It is included by the message ret an004 */

/*컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�*/

        char    *SingleDrive = "%c:" ;                                                                                           /* ;an000; */
        char    *MultipleDrives = "%c: - %c:" ;                                                                                  /* ;an000; */
        char    *UnOwned = "----------" ;                                                                                        /* ;an000; */
        char    *Ibmbio = "IO    " ;                                                                                             /* ;an000; */
        char    *Ibmdos = "MSDOS " ;
                                                                                                                                 /* ;an000; */
  struct sublistx                                                                                                                /* ;an000; */
   {                                                                                                                             /* ;an000; */
    unsigned char size;                                                         /* sublist size                         */       /* ;an000; */
    unsigned char reserved;                                                     /* reserved for future growth           */       /* ;an000; */
    unsigned far *value;                                                        /* pointer to replaceable parm          */       /* ;an000; */
    unsigned char id;                                                           /* type of replaceable parm             */       /* ;an000; */
    unsigned char flags;                                                        /* how parm is to be displayed          */       /* ;an000; */
    unsigned char max_width;                                                    /* max width of replaceable field       */       /* ;an000; */
    unsigned char min_width;                                                    /* min width of replaceable field       */       /* ;an000; */
    unsigned char pad_char;                                                     /* pad character for replaceable field  */       /* ;an000; */
  } sublist[4];                                                                                                                  /* ;an000; */
                                                                                                                                 /* ;an000; */
/*----------------------------------------------------------------------+
|       define structure used by parser                                 |
+----------------------------------------------------------------------*/

struct p_parms  p_p;                                                                                                             /* ;an000; */
                                                                                                                                 /* ;an000; */
struct p_parmsx p_px;                                                                                                            /* ;an000; */
                                                                                                                                 /* ;an000; */
struct p_control_blk p_con1;                                                                                                     /* ;an000; */
struct p_control_blk p_con2;                                                                                                     /* ;an000; */
                                                                                                                                 /* ;an000; */
struct p_result_blk  p_result1;                                                                                                  /* ;an000; */
struct p_result_blk  p_result2;                                                                                                  /* ;an000; */
                                                                                                                                 /* ;an000; */
struct p_value_blk p_noval;                                                                                                      /* ;an000; */
                                                                                                                                 /* ;an000; */
                                                                                                                                 /* ;an000; */
        struct  DEVICEHEADER {                                                                                                   /* ;an000; */
                struct DEVICEHEADER far *NextDeviceHeader;                                                                       /* ;an000; */
                unsigned                Attributes;                                                                              /* ;an000; */
                unsigned                Strategy;                                                                                /* ;an000; */
                unsigned                Interrupt;                                                                               /* ;an000; */
                char                    Name[8];                                                                                 /* ;an000; */
                };                                                                                                               /* ;an000; */
                                                                                                                                 /* ;an000; */
#define DA_TYPE         0x8000;                                                                                                  /* ;an000; */
#define DA_IOCTL        0x4000;                                                                                                  /* ;an000; */
                                                                                                                                 /* ;an000; */
#define a(fp)   ((char) fp)                                                                                                      /* ;an000; */
                                                                                                                                 /* ;an000; */
/* defines used in EMS support */                                                                                                /* ;an000; */
                                                                                                                                 /* ;an000; */
#define GET_VECT        0x35            /* EMS interrupt  */                                                                     /* ;an000; */
#define EMS             0x67                                                                                                     /* ;an000; */
                                                                                                                                 /* ;an000; */
#define CASSETTE        0x15            /* interrupt to get extended memory */                                                   /* ;an000; */
                                                                                                                                 /* ;an000; */
#define DOSEMSVER       0x40            /* EMS version */                                                                        /* ;an000; */
                                                                                                                                 /* ;an000; */
#define EMSGetStat      0x4000          /* get stat */                                                                           /* ;an000; */
#define EMSGetVer       0x4600          /* get version */                                                                        /* ;an000; */
#define EMSGetFreePgs   0x4200          /* get free pages */                                                                     /* ;an000; */
                                                                                                                                 /* ;an000; */
#define GetExtended     0x8800          /* get extended memory size */                                                           /* ;an000; */
                                                                                                                                 /* ;an000; */
                                                                                                                                 /* ;an000; */
                                                                                                                                 /* ;an000; */
/* defines used by total memory determination */                                                                                 /* ;an000; */
#define GET_PSP         (unsigned char ) 0x62            /* get PSP function call */                                             /* ;an000; */

#define MEMORY_DET      0x12            /* BIOS interrupt used to get total memory size */                                       /* ;an000; */
                                                                                                                                 /* ;an000; */
        struct  SYSIVAR {                                                                                                        /* ;an000; */
                char far *DpbChain;                                                                                              /* ;an000; */
                char far *SftChain;                                                                                              /* ;an000; */
                char far *Clock;                                                                                                 /* ;an000; */
                char far *Con;                                                                                                   /* ;an000; */
                unsigned  MaxSectorSize;                                                                                         /* ;an000; */
                char far *BufferChain;                                                                                           /* ;an000; */
                char far *CdsList;                                                                                               /* ;an000; */
                char far *FcbChain;                                                                                              /* ;an000; */
                unsigned  FcbKeepCount;                                                                                          /* ;an000; */
                unsigned char BlockDeviceCount;                                                                                  /* ;an000; */
                char      CdsCount;                                                                                              /* ;an000; */
                struct DEVICEHEADER far *DeviceDriverChain;                                                                      /* ;an000; */
                unsigned  NullDeviceAttributes;                                                                                  /* ;an000; */
                unsigned  NullDeviceStrategyEntryPoint;                                                                          /* ;an000; */
                unsigned  NullDeviceInterruptEntryPoint;                                                                         /* ;an000; */
                char      NullDeviceName[8];                                                                                     /* ;an000; */
                char      SpliceIndicator;                                                                                       /* ;an000; */
                unsigned  DosParagraphs;                                                                                         /* ;an000; */
                char far *DosServiceRntryPoint;                                                                                  /* ;an000; */
                char far *IfsChain;                                                                                              /* ;an000; */
                unsigned  BufferValues;                                                                                          /* ;an000; */
                unsigned  LastDriveValue;                                                                                        /* ;an000; */
                char      BootDrive;                                                                                             /* ;an000; */
                char      MoveType;
                unsigned  ExtendedMemory;
                };                                                                                                               /* ;an000; */
                                                                                                                                 /* ;an000; */
/*컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�*/                                                  /* ;an000; */
                                                                                                                                 /* ;an000; */
        struct  ARENA    {                                                                                                       /* ;an000; */
                char     Signature;                                                                                              /* ;an000; */
                unsigned Owner;                                                                                                  /* ;an000; */
                unsigned Paragraphs;                                                                                             /* ;an000; */
                char     Dummy[3];                                                                                               /* ;an000; */
                char     OwnerName[8];                                                                                           /* ;an000; */
                };                                                                                                               /* ;an000; */
                                                                                                                                 /* ;an000; */
/*컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�*/                                                  /* ;an000; */
                                                                                                                                 /* ;an000; */
#define FALSE    (char)(1==0)                                                                                                    /* ;an000; */
#define TRUE     !(FALSE)                                                                                                        /* ;an000; */
#define CR       '\x0d'                                                                                                          /* ;an000; */
#define LF       '\x0a'                                                                                                          /* ;an000; */
#define NUL      (char) '\0'                                                                                                     /* ;an000; */
#define TAB      '\x09'                                                                                                          /* ;an000; */
#define BLANK   ' '                                                                                                              /* ;an000; */
                                                                                                                                 /* ;an000; */
extern  unsigned DOS_TopOfMemory;         /* PSP Top of memory from 'C' init code  */                                            /* ;an005; */

/*컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�*/                                                  /* ;an000; */
                                                                                                                                 /* ;an000; */
        unsigned far         *ArenaHeadPtr;                                                                                      /* ;an000; */
        struct   SYSIVAR far *SysVarsPtr;                                                                                        /* ;an000; */
                                                                                                                                 /* ;an000; */
        char    OwnerName[128];                                                                                                  /* ;an000; */
        char    TypeText[128];                                                                                                   /* ;an000; */
        char    cmd_line[128];                                                                                                   /* ;an000; */
        char    far *cmdline;                                                                                                    /* ;an000; */
                                                                                                                                 /* ;an000; */
        char    UseArgvZero = TRUE;                                                                                              /* ;an000; */
        char    EMSInstalledFlag = (char) 2;                                                                                     /* ;an000; */
                                                                                                                                 /* ;an000; */
        union    REGS    InRegs;                                                                                                 /* ;an000; */
        union    REGS    OutRegs;                                                                                                /* ;an000; */
        struct   SREGS   SegRegs;                                                                                                /* ;an000; */
                                                                                                                                 /* ;an000; */
        int      DataLevel;                                                                                                      /* ;an000; */
        int      i;                                                                                                              /* ;an000; */
                                                                                                                                 /* ;an000; */
        int      BlockDeviceNumber;                                                                                              /* ;an000; */
        unsigned Parse_Ptr;                                                     /* ;an003; dms; pointer to command      */
                                                                                                                                 /* ;an000; */
/*컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�*/                                                  /* ;an000; */
                                                                                                                                 /* ;an000; */
void     main(int, char *[]);                                                                                                    /* ;an000; */
                                                                                                                                 /* ;an000; */
int      printf();
int      sprintf();
int      strcmp(const char *, const char *);
int      sscanf();                                                                                                               /* ;an000; */
void     exit(int);                                                                                                              /* ;an000; */
int      kbhit();                                                                                                                /* ;an000; */
char     *OwnerOf(struct ARENA far *);                                                                                           /* ;an000; */
char     *TypeOf(struct ARENA far *);                                                                                            /* ;an000; */
unsigned long AddressOf(char far *);                                                                                             /* ;an000; */
                                                                                                                                 /* ;an000; */
char     EMSInstalled(void);                                                                                                     /* ;an000; */
void     DisplayEMSSummary(void);                                                                                                /* ;an000; */
void     DisplayEMSDetail(void);                                                                                                 /* ;an000; */
                                                                                                                                 /* ;an000; */
void     DisplayBaseSummary(void);                                                                                               /* ;an000; */
void     DisplayExtendedSummary(void);                                                                                           /* ;an000; */
void     DisplayExpandedSummary(void);                                                                                           /* ;an000; */
                                                                                                                                 /* ;an000; */
void     DisplayBaseDetail(void);                                                                                                /* ;an000; */
                                                                                                                                 /* ;an000; */
void     GetFromArgvZero(unsigned,unsigned far *);                                                                               /* ;an000; */
                                                                                                                                 /* ;an000; */
void     DisplayDeviceDriver(struct   DEVICEHEADER far *,int);                                                                   /* ;an000; */
                                                                                                                                 /* ;an000; */
void     parse_init(void);                                                                                                       /* ;an000; */
                                                                                                                                 /* ;an000; */
void     Parse_Message(int,int,unsigned char);                                                                                    /* ;an000; */
void     Sub0_Message(int,int,unsigned char);                                                                                    /* ;an000; */
void     Sub1_Message(int,int,unsigned char,unsigned long int *);                                                                /* ;an000; */
void     Sub2_Message(int,int,unsigned char,char *,int);                                                                         /* ;an000; */
void     Sub3_Message(int,int,unsigned char,                                                                                     /* ;an000; */
                      char *,                                                                                                    /* ;an000; */
                      unsigned long int *,                                                                                       /* ;an000; */
                      int);                                                                                                      /* ;an000; */
                                                                                                                                 /* ;an000; */
void     Sub4_Message(int,int,unsigned char,                                                                                     /* ;an000; */
                      unsigned long int *,                                                                                       /* ;an000; */
                      int,                                                                                                       /* ;an000; */
                      unsigned long int *,                                                                                       /* ;an000; */
                      int);                                                                                                      /* ;an000; */
                                                                                                                                 /* ;an000; */
void     Sub4a_Message(int,int,unsigned char,                                                                                    /* ;an000; */
                      unsigned long int *,                                                                                       /* ;an000; */
                      char *,                                                                                                    /* ;an000; */
                      unsigned long int *,                                                                                       /* ;an000; */
                      char *);                                                                                                   /* ;an000; */
                                                                                                                                 /* ;an000; */
void    EMSPrint(int,int,unsigned char,                                                                                          /* ;an000; */
                 int *,                                                                                                          /* ;an000; */
                 char *,                                                                                                         /* ;an000; */
                 unsigned long int *);                                                                                           /* ;an000; */
                                                                                                                                 /* ;an000; */
extern void sysloadmsg(union REGS *, union REGS *);                                                                              /* ;an000; */
extern void sysdispmsg(union REGS *, union REGS *);                                                                              /* ;an000; */
extern void sysgetmsg(union REGS *, struct SREGS *, union REGS *);                                                               /* ;an000; */
extern void parse(union REGS *, union REGS *);                                                                                   /* ;an000; */
                                                                                                                                 /* ;an000; */
                                                                                                                                /* ;an000; */
/*컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�*/                                                  /* ;an000; */
                                                                                                                                 /* ;an000; */
void     main(argc,argv)                                                                                                         /* ;an000; */
int      argc;                                                                                                                   /* ;an000; */
char     *argv[];                                                                                                                /* ;an000; */
{                                                                                                                                /* ;an000; */
                                                                                                                                 /* ;an000; */
                                                                                                                                 /* ;an000; */
                                                                                                                                 /* ;an000; */
        sysloadmsg(&InRegs,&OutRegs);                                                                                            /* ;an000; */
        if ((OutRegs.x.cflag & CarryFlag) == CarryFlag)                                                                          /* ;an000; */
                {                                                                                                                /* ;an000; */
                sysdispmsg(&OutRegs,&OutRegs);                                                                                   /* ;an000; */
                exit(1);                                                                                                         /* ;an000; */
                }                                                                                                                /* ;an000; */
                                                                                                                                 /* ;an000; */
                                                                                                                                 /* ;an000; */
        InRegs.h.ah = (unsigned char) 0x62;                                     /* an000; dms; get the PSP              */       /* ;an000; */
        intdosx(&InRegs, &InRegs, &SegRegs);                                    /* an000; dms; invoke the INT 21        */       /* ;an000; */
                                                                                                                                 /* ;an000; */
        FP_OFF(cmdline) = 0x81;                                                 /* an000; dms; offset of command line   */       /* ;an000; */
        FP_SEG(cmdline) = InRegs.x.bx;                                          /* an000; dms; segment of command line  */       /* ;an000; */
                                                                                                                                 /* ;an000; */
        i = 0;                                                                  /* an000; dms; init index               */       /* ;an000; */
        while ( *cmdline != (char) '\x0d' ) cmd_line[i++] = *cmdline++;         /* an000; dms; while no CR              */       /* ;an000; */
        cmd_line[i++] = (char) '\x0d';                                          /* an000; dms; CR terminate string      */       /* ;an000; */
        cmd_line[i++] = (char) '\0';                                            /* an000; dms; null terminate string    */       /* ;an000; */
                                                                                                                                 /* ;an000; */
        DataLevel = 0;                                                                                                           /* ;an000; */
                                                                                                                                 /* ;an000; */
        parse_init();                                                           /* an000; dms; init for parser          */       /* ;an000; */
        InRegs.x.si = (unsigned)cmd_line;                                       /* an000; dms; initialize to command ln.*/       /* ;an000; */
        InRegs.x.cx = (unsigned)0;                                              /* an000; dms; ordinal of 0             */       /* ;an000; */
        InRegs.x.dx = (unsigned)0;                                              /* an000; dms; init pointer             */       /* ;an000; */
        InRegs.x.di = (unsigned)&p_p;                                           /* an000; dms; point to ctrl blocks     */       /* ;an000; */
        Parse_Ptr   = (unsigned)cmd_line;                                       /*;an003; dms; point to command         */
                                                                                                                                 /* ;an000; */
        parse(&InRegs,&OutRegs);                                                /* an000; dms; parse command line       */       /* ;an000; */
        while (OutRegs.x.ax == p_no_error)                                      /* an000; dms; good parse loop          */       /* ;an000; */
                {                                                                                                                /* ;an000; */
                if (p_result1.P_SYNONYM_Ptr == (unsigned int)p_con1.p_keyorsw)  /* an000; dms; DEBUG switch             */       /* ;an000; */
                        DataLevel = 2;                                          /* an000; dms; flag DEBUG switch        */       /* ;an000; */
                if (p_result2.P_SYNONYM_Ptr == (unsigned int)p_con2.p_keyorsw)  /* an000; dms; PROGRAM switch           */       /* ;an000; */
                        DataLevel = 1;                                          /* an000; dms; flag PROGRAM switch      */       /* ;an000; */
                Parse_Ptr = OutRegs.x.si;                                       /* an003; dms; point to next parm       */
                parse(&OutRegs,&OutRegs);                                       /* an000; dms; parse the line           */       /* ;an000; */
                if (OutRegs.x.ax == p_no_error)                                 /* an000; dms; check for > 1 switch     */       /* ;an000; */
                        OutRegs.x.ax = p_too_many;                              /* an000; dms; flag too many            */       /* ;an000; */
                }                                                                                                                /* ;an000; */
                                                                                                                                 /* ;an000; */
        if (OutRegs.x.ax != p_rc_eol)                                           /* an000; dms; parse error?             */       /* ;an000; */
                {                                                                                                                /* ;an000; */
                Parse_Message(OutRegs.x.ax,STDERR,Parse_Err_Class);             /* an000; dms; display parse error      */       /* ;an000; */
                exit(1);                                                        /* an000; dms; exit the program         */       /* ;an000; */
                }                                                                                                                /* ;an000; */
                                                                                                                                 /* ;an000; */
                                                                                                                                 /* ;an000; */
        if (DataLevel > 0)                                                                                                       /* ;an000; */
              {                                                                                                                  /* ;an000; */
                DisplayBaseDetail();                                                                                             /* ;an000; */
                }                                                                                                                /* ;an000; */
                                                                                                                                 /* ;an000; */
                                                                                                                                 /* ;an000; */
        Sub0_Message(NewLineMsg,STDOUT,Utility_Msg_Class);                                                                       /* ;an000; */
        DisplayBaseSummary();           /* display low memory totals */                                                          /* ;an000; */
                                                                                                                                 /* ;an000; */
        if (EMSInstalled() && (DataLevel > 1))                                                                                   /* ;an000; */
          DisplayEMSDetail();           /* display EMS memory totals */                                                          /* ;an000; */
                                                                                                                                 /* ;an000; */
                                                                                                                                 /* ;an000; */
        if (EMSInstalled())                                                                                                      /* ;an000; */
          DisplayEMSSummary();          /* display EMS memory totals */                                                          /* ;an000; */
                                                                                                                                 /* ;an000; */
        DisplayExtendedSummary();       /* display extended memory summary */                                                    /* ;an000; */
                                                                                                                                 /* ;an000; */
        return;                         /* end of MEM main routine */                                                            /* ;an000; */
                                                                                                                                 /* ;an000; */
        }                                                                                                                        /* ;an000; */
                                                                                                                                 /* ;an000; */
/*컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�*/                                                  /* ;an000; */
                                                                                                                                 /* ;an000; */
void    DisplayBaseDetail()                                                                                                      /* ;an000; */
{                                                                                                                                /* ;an000; */
                                                                                                                                 /* ;an000; */
        struct   ARENA far *ThisArenaPtr;                                                                                        /* ;an000; */
        struct   ARENA far *NextArenaPtr;                                                                                        /* ;an000; */
        struct   ARENA far *ThisConfigArenaPtr;                                                                                  /* ;an000; */
        struct   ARENA far *NextConfigArenaPtr;                                                                                  /* ;an000; */
                                                                                                                                 /* ;an000; */
        struct   DEVICEHEADER far *ThisDeviceDriver;                                                                             /* ;an000; */
                                                                                                                                 /* ;an000; */
        int      SystemDataType;                                                                                                 /* ;an000; */
        char     SystemDataOwner[64];                                                                                            /* ;an000; */
                                                                                                                                 /* ;an000; */
        int     i;                                                                                                               /* ;an000; */
        unsigned int long       Out_Var1;                                                                                        /* ;an000; */
        unsigned int long       Out_Var2;                                                                                        /* ;an000; */
        char                    Out_Str1[64];                                                                                    /* ;an000; */
        char                    Out_Str2[64];                                                                                    /* ;an000; */
                                                                                                                                 /* ;an000; */
        Sub0_Message(NewLineMsg,STDOUT,Utility_Msg_Class);                                                                       /* ;an000; */
        if (DataLevel > 0)                                                                                                       /* ;an000; */
              {                                                                                                                  /* ;an000; */
                Sub0_Message(Title1Msg,STDOUT,Utility_Msg_Class);                                                                /* ;an000; */
                Sub0_Message(Title2Msg,STDOUT,Utility_Msg_Class);                                                                /* ;an000; */
                }                                                                                                                /* ;an000; */
                                                                                                                                 /* ;an000; */
        InRegs.h.ah = (unsigned char) 0x30;                                                                                      /* ;an000; */
        intdos(&InRegs, &OutRegs);                                                                                               /* ;an000; */
                                                                                                                                 /* ;an000; */
        if ( (OutRegs.h.al != (unsigned char) 3) || (OutRegs.h.ah < (unsigned char) 40) )                                        /* ;an000; */
                UseArgvZero = TRUE;                                                                                              /* ;an000; */
           else UseArgvZero = FALSE;                                                                                             /* ;an000; */
                                                                                                                                 /* ;an000; */
        /* Display stuff below DOS  */                                                                                           /* ;an000; */
                                                                                                                                 /* ;an000; */
        Out_Var1 = 0l;                                                                                                           /* ;an000; */
        Out_Var2 = 0x400l;                                                                                                       /* ;an000; */
        Sub4_Message(MainLineMsg,                                                                                                /* ;an000; */
                     STDOUT,                                                                                                     /* ;an000; */
                     Utility_Msg_Class,                                                                                          /* ;an000; */
                     &Out_Var1,                                                                                                  /* ;an000; */
                     BlankMsg,                                                                                                   /* ;an000; */
                     &Out_Var2,                                                                                                  /* ;an000; */
                     InterruptVectorMsg);                                                                                        /* ;an000; */
                                                                                                                                 /* ;an000; */
        Out_Var1 = 0x400l;                                                                                                       /* ;an000; */
        Out_Var2 = 0x100l;                                                                                                       /* ;an000; */
        Sub4_Message(MainLineMsg,                                                                                                /* ;an000; */
                     STDOUT,                                                                                                     /* ;an000; */
                     Utility_Msg_Class,                                                                                          /* ;an000; */
                     &Out_Var1,                                                                                                  /* ;an000; */
                     BlankMsg,                                                                                                   /* ;an000; */
                     &Out_Var2,                                                                                                  /* ;an000; */
                     ROMCommunicationAreaMsg);                                                                                   /* ;an000; */
                                                                                                                                 /* ;an000; */
        Out_Var1 = 0x500l;                                                                                                       /* ;an000; */
        Out_Var2 = 0x200l;                                                                                                       /* ;an000; */
        Sub4_Message(MainLineMsg,                                                                                                /* ;an000; */
                     STDOUT,                                                                                                     /* ;an000; */
                     Utility_Msg_Class,                                                                                          /* ;an000; */
                     &Out_Var1,                                                                                                  /* ;an000; */
                     BlankMsg,                                                                                                   /* ;an000; */
                     &Out_Var2,                                                                                                  /* ;an000; */
                     DOSCommunicationAreaMsg);                                                                                   /* ;an000; */
                                                                                                                                 /* ;an000; */
        /* Display the DOS data */                                                                                               /* ;an000; */
                                                                                                                                 /* ;an000; */
        InRegs.h.ah = (unsigned char) 0x52;                                                                                      /* ;an000; */
        intdosx(&InRegs,&OutRegs,&SegRegs);                                                                                      /* ;an000; */
                                                                                                                                 /* ;an000; */
        FP_SEG(SysVarsPtr) = SegRegs.es;                                                                                         /* ;an000; */
        FP_OFF(SysVarsPtr) = OutRegs.x.bx;                                                                                       /* ;an000; */
                                                                                                                                 /* ;an000; */
        /* Display the BIO location and size */                                                                                  /* ;an000; */
                                                                                                                                 /* ;an000; */
        Sub0_Message(NewLineMsg,STDOUT,Utility_Msg_Class);                                                                       /* ;an000; */
                                                                                                                                 /* ;an000; */
                                                                                                                                 /* ;an000; */
        Out_Var1 = 0x700l;                                                                                                       /* ;an000; */
        Out_Var2 = (long) (FP_SEG(SysVarsPtr) - 0x70)*16l;                                                                       /* ;an000; */
        Sub4_Message(MainLineMsg,                                                                                                /* ;an000; */
                     STDOUT,                                                                                                     /* ;an000; */
                     Utility_Msg_Class,                                                                                          /* ;an000; */
                     &Out_Var1,                                                                                                  /* ;an000; */
                     IbmbioMsg,                                                                                                  /* ;an000; */
                     &Out_Var2,                                                                                                  /* ;an000; */
                     SystemProgramMsg);                                                                                          /* ;an000; */
                                                                                                                                 /* ;an000; */
        /* Display the Base Device Driver Locations and Sizes */                                                                 /* ;an000; */
                                                                                                                                 /* ;an000; */
        BlockDeviceNumber = 0;                                                                                                   /* ;an000; */
                                                                                                                                 /* ;an000; */
        for (ThisDeviceDriver = SysVarsPtr -> DeviceDriverChain;                                                                 /* ;an000; */
              (FP_OFF(ThisDeviceDriver) != 0xFFFF);                                                                              /* ;an000; */
               ThisDeviceDriver = ThisDeviceDriver -> NextDeviceHeader)                                                          /* ;an000; */
              { if ( FP_SEG(ThisDeviceDriver) < FP_SEG(SysVarsPtr) )                                                             /* ;an000; */
                        DisplayDeviceDriver(ThisDeviceDriver,SystemDeviceDriverMsg);                                             /* ;an000; */
                kbhit();                                                                                                         /* ;an000; */
                }                                                                                                                /* ;an000; */
                                                                                                                                 /* ;an000; */
        /* Display the DOS location and size */                                                                                  /* ;an000; */

        FP_SEG(ArenaHeadPtr) = FP_SEG(SysVarsPtr);                                                                               /* ;an004; */
        FP_OFF(ArenaHeadPtr) = FP_OFF(SysVarsPtr) - 2;                                                                           /* ;an004; */
                                                                                                                                 /* ;an004; */
        FP_SEG(ThisArenaPtr) = *ArenaHeadPtr;                                                                                    /* ;an004; */
        FP_OFF(ThisArenaPtr) = 0;                                                                                                /* ;an004; */
                                                                                                                                 /* ;an000; */
        Sub0_Message(NewLineMsg,STDOUT,Utility_Msg_Class);                                                                       /* ;an000; */
                                                                                                                                 /* ;an000; */
        Out_Var1 = (long) FP_SEG(SysVarsPtr) * 16l;                                                                              /* ;an000; */
        Out_Var2 = (long) ((AddressOf((char far *)ThisArenaPtr)) - Out_Var1);                                                    /* ;ac004; */
        Sub4_Message(MainLineMsg,                                                                                                /* ;an000; */
                     STDOUT,                                                                                                     /* ;an000; */
                     Utility_Msg_Class,                                                                                          /* ;an000; */
                     &Out_Var1,                                                                                                  /* ;an000; */
                     IbmdosMsg,                                                                                                  /* ;an000; */
                     &Out_Var2,                                                                                                  /* ;an000; */
                     SystemProgramMsg);                                                                                          /* ;an000; */
                                                                                                                                 /* ;an000; */
        Sub0_Message(NewLineMsg,STDOUT,Utility_Msg_Class);                                                                       /* ;an000; */
                                                                                                                                 /* ;an000; */
        /* Display the memory data */                                                                                            /* ;an000; */
                                                                                                                                 /* ;an000; */
        while (ThisArenaPtr -> Signature != (char) 'Z')                                                                          /* ;an000; */
              {                                                                                                                  /* ;an000; */
                                                                                                                                 /* ;an000; */
                if (ThisArenaPtr -> Owner == 8)                                                                                  /* ;an000; */
                      {                                                                                                          /* ;an000; */
                                                                                                                                 /* ;an000; */
                                                                                                                                 /* ;an000; */
                        Out_Var1 = AddressOf((char far *)ThisArenaPtr);                                                          /* ;an000; */
                        Out_Var2 = (long) (ThisArenaPtr -> Paragraphs) * 16l;                                                    /* ;an000; */
                        Sub4_Message(MainLineMsg,                                                                                /* ;an000; */
                                     STDOUT,                                                                                     /* ;an000; */
                                     Utility_Msg_Class,                                                                          /* ;an000; */
                                     &Out_Var1,                                                                                  /* ;an000; */
                                     IbmbioMsg,                                                                                  /* ;an000; */
                                     &Out_Var2,                                                                                  /* ;an000; */
                                     SystemDataMsg);                                                                             /* ;an000; */
                                                                                                                                 /* ;an000; */
                        FP_SEG(NextArenaPtr) = FP_SEG(ThisArenaPtr) + ThisArenaPtr -> Paragraphs + 1;                            /* ;an000; */
                        FP_OFF(NextArenaPtr) = 0;                                                                                /* ;an000; */
                                                                                                                                 /* ;an000; */
                        FP_SEG(ThisConfigArenaPtr) = FP_SEG(ThisArenaPtr) + 1;                                                   /* ;an000; */
                        FP_OFF(ThisConfigArenaPtr) = 0;                                                                          /* ;an000; */
                                                                                                                                 /* ;an000; */
                                                                                                                                 /* ;an000; */
                        while ( (FP_SEG(ThisConfigArenaPtr) > FP_SEG(ThisArenaPtr)) &&                                           /* ;an000; */
                                (FP_SEG(ThisConfigArenaPtr) < FP_SEG(NextArenaPtr))    )                                         /* ;an000; */
                              {                                                                                                  /* ;an000; */
                                strcpy(SystemDataOwner," ");                                                                     /* ;an000; */
                                switch(ThisConfigArenaPtr -> Signature)                                                          /* ;an000; */
                                      {                                                                                          /* ;an000; */
                                        case 'B':                                                                                /* ;an000; */
                                                SystemDataType = ConfigBuffersMsg;                                               /* ;an000; */
                                                break;                                                                           /* ;an000; */
                                        case 'D':                                                                                /* ;an000; */
                                                SystemDataType = ConfigDeviceMsg;                                                /* ;an000; */
                                                strcpy(SystemDataOwner,OwnerOf(ThisConfigArenaPtr));                             /* ;an000; */
                                                break;                                                                           /* ;an000; */
                                        case 'F':                                                                                /* ;an000; */
                                                SystemDataType = ConfigFilesMsg;                                                 /* ;an000; */
                                                break;                                                                           /* ;an000; */
                                        case 'I':                                                                                /* ;an000; */
                                                SystemDataType = ConfigIFSMsg;                                                   /* ;an000; */
                                                strcpy(SystemDataOwner,OwnerOf(ThisConfigArenaPtr));                             /* ;an000; */
                                                break;                                                                           /* ;an000; */
                                        case 'L':                                                                                /* ;an000; */
                                                SystemDataType = ConfigLastDriveMsg;                                             /* ;an000; */
                                                break;                                                                           /* ;an000; */
                                        case 'S':                                                                                /* ;an000; */
                                                SystemDataType = ConfigStacksMsg;                                                /* ;an000; */
                                                break;                                                                           /* ;an000; */
                                        case 'T':                                        /* gga */                               /* ;an000; */
                                                SystemDataType = ConfigInstallMsg;       /* gga */                               /* ;an000; */
                                                break;                                   /* gga */                               /* ;an000; */
                                        case 'X':                                                                                /* ;an000; */
                                                SystemDataType = ConfigFcbsMsg;                                                  /* ;an000; */
                                                break;                                                                           /* ;an000; */
                                        default:                                                                                 /* ;an000; */
                                                SystemDataType = BlankMsg;                                                       /* ;an000; */
                                                break;                                                                           /* ;an000; */
                                        }                                                                                        /* ;an000; */
                                Out_Var1 = ((long) ThisConfigArenaPtr -> Paragraphs) * 16l;                                      /* ;an000; */
                                Sub3_Message(DriverLineMsg,                                                                      /* ;an000; */
                                             STDOUT,                                                                             /* ;an000; */
                                             Utility_Msg_Class,                                                                  /* ;an000; */
                                             SystemDataOwner,                                                                    /* ;an000; */
                                             &Out_Var1,                                                                          /* ;an000; */
                                             SystemDataType );                                                                   /* ;an000; */
                                                                                                                                 /* ;an000; */
                                NextConfigArenaPtr = ThisConfigArenaPtr;                                                         /* ;an000; */
                                FP_SEG(NextConfigArenaPtr) += NextConfigArenaPtr -> Paragraphs + 1;                              /* ;an000; */
                                if (ThisConfigArenaPtr -> Signature == (char) 'D')                                               /* ;an000; */
                                      {                                                                                          /* ;an000; */
                                                                                                                                 /* ;an000; */
                                        FP_SEG(ThisDeviceDriver) = FP_SEG(ThisConfigArenaPtr) + 1;                               /* ;an000; */
                                        FP_OFF(ThisDeviceDriver) = 0;                                                            /* ;an000; */
                                        while ( (a(ThisDeviceDriver) > a(ThisConfigArenaPtr)) &&                                 /* ;an000; */
                                                (a(ThisDeviceDriver) < a(NextConfigArenaPtr))    )                               /* ;an000; */
                                                DisplayDeviceDriver(ThisDeviceDriver,InstalledDeviceDriverMsg);                  /* ;an000; */
                                        }                                                                                        /* ;an000; */
                                                                                                                                 /* ;an000; */
                                FP_SEG(ThisConfigArenaPtr) += ThisConfigArenaPtr -> Paragraphs + 1;                              /* ;an000; */
                                                                                                                                 /* ;an000; */
                                }                                                                                                /* ;an000; */
                                                                                                                                 /* ;an000; */
                        }                                                                                                        /* ;an000; */
                 else {                                                                                                          /* ;an000; */
                                                                                                                                 /* ;an000; */
                      Out_Var1 = AddressOf((char far *)ThisArenaPtr);                                                            /* ;an000; */
                      Out_Var2 = ((long) (ThisArenaPtr -> Paragraphs)) * 16l;                                                    /* ;an000; */
                      strcpy(Out_Str1,OwnerOf(ThisArenaPtr));                                                                    /* ;an000; */
                      strcpy(Out_Str2,TypeOf(ThisArenaPtr));                                                                     /* ;an000; */
                      Sub4a_Message(MainLineMsg,                                                                                 /* ;an000; */
                                   STDOUT,                                                                                       /* ;an000; */
                                   Utility_Msg_Class,                                                                            /* ;an000; */
                                   &Out_Var1,                                                                                    /* ;an000; */
                                   Out_Str1,                                                                                     /* ;an000; */
                                   &Out_Var2,                                                                                    /* ;an000; */
                                   Out_Str2);                                                                                    /* ;an000; */
                        }                                                                                                        /* ;an000; */
                                                                                                                                 /* ;an000; */
                FP_SEG(ThisArenaPtr) += ThisArenaPtr -> Paragraphs + 1;                                                          /* ;an000; */
                                                                                                                                 /* ;an000; */
                }                                                                                                                /* ;an000; */
        Out_Var1 = AddressOf((char far *)ThisArenaPtr);                                                                          /* ;an000; */
        Out_Var2 = ((long) (ThisArenaPtr -> Paragraphs)) * 16l;                                                                  /* ;an000; */
        strcpy(Out_Str1,OwnerOf(ThisArenaPtr));                                                                                  /* ;an000; */
        strcpy(Out_Str2,TypeOf(ThisArenaPtr));                                                                                   /* ;an000; */
        Sub4a_Message(MainLineMsg,                                                                                               /* ;an000; */
                     STDOUT,                                                                                                     /* ;an000; */
                     Utility_Msg_Class,                                                                                          /* ;an000; */
                     &Out_Var1,                                                                                                  /* ;an000; */
                     Out_Str1,                                                                                                   /* ;an000; */
                     &Out_Var2,                                                                                                  /* ;an000; */
                     Out_Str2);                                                                                                  /* ;an000; */
                                                                                                                                 /* ;an000; */
                                                                                                                                 /* ;an000; */
        return;                         /* end of MEM main routine */                                                            /* ;an000; */
                                                                                                                                 /* ;an000; */
        }                                                                                                                        /* ;an000; */
                                                                                                                                 /* ;an000; */
                                                                                                                                 /* ;an000; */
                                                                                                                                /* ;an000; */
/*컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�*/                                                  /* ;an000; */
                                                                                                                                 /* ;an000; */
void     DisplayDeviceDriver(ThisDeviceDriver,DeviceDriverType)                                                                  /* ;an000; */
struct   DEVICEHEADER far *ThisDeviceDriver;                                                                                     /* ;an000; */
int      DeviceDriverType;                                                                                                       /* ;an000; */
{                                                                                                                                /* ;an000; */
        char     LocalDeviceName[16];                                                                                            /* ;an000; */
        int      i;                                                                                                              /* ;an000; */
                                                                                                                                 /* ;an000; */
        if (DataLevel < 2) return;                                                                                               /* ;an000; */
                                                                                                                                 /* ;an000; */
        if ( ((ThisDeviceDriver -> Attributes) & 0x8000 ) != 0 )                                                                 /* ;an000; */
              { for (i = 0; i < 8; i++) LocalDeviceName[i] = ThisDeviceDriver -> Name[i];                                        /* ;an000; */
                LocalDeviceName[8] = NUL;                                                                                        /* ;an000; */
                                                                                                                                 /* ;an000; */
                Sub2_Message(DeviceLineMsg,                                                                                      /* ;an000; */
                             STDOUT,                                                                                             /* ;an000; */
                             Utility_Msg_Class,                                                                                  /* ;an000; */
                             LocalDeviceName,                                                                                    /* ;an000; */
                             DeviceDriverType);                                                                                  /* ;an000; */
                                                                                                                                 /* ;an000; */
                }                                                                                                                /* ;an000; */
                                                                                                                                 /* ;an000; */
         else {                                                                                                                  /* ;an000; */
                if ((int) ThisDeviceDriver -> Name[0] == 1)                                                                      /* ;an000; */
                        sprintf(&LocalDeviceName[0],SingleDrive,'A'+BlockDeviceNumber);                                          /* ;an000; */
                   else sprintf(&LocalDeviceName[0],MultipleDrives,                                                              /* ;an000; */
                                'A'+BlockDeviceNumber,                                                                           /* ;an000; */
                                'A'+BlockDeviceNumber + ((int) ThisDeviceDriver -> Name[0]) - 1);                                /* ;an000; */
                                                                                                                                 /* ;an000; */
                Sub2_Message(DeviceLineMsg,                                                                                      /* ;an000; */
                             STDOUT,                                                                                             /* ;an000; */
                             Utility_Msg_Class,                                                                                  /* ;an000; */
                             LocalDeviceName,                                                                                    /* ;an000; */
                             DeviceDriverType);                                                                                  /* ;an000; */
                                                                                                                                 /* ;an000; */
                BlockDeviceNumber += (int) (ThisDeviceDriver -> Name[0]);                                                        /* ;an000; */
                                                                                                                                 /* ;an000; */
                }                                                                                                                /* ;an000; */
                                                                                                                                 /* ;an000; */
        return;                                                                                                                  /* ;an000; */
                                                                                                                                 /* ;an000; */
        }                                                                                                                        /* ;an000; */
                                                                                                                                 /* ;an000; */
                                                                                                                                /* ;an000; */
/*컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�*/                                                  /* ;an000; */
                                                                                                                                 /* ;an000; */
void DisplayBaseSummary()                                                                                                        /* ;an000; */
        {                                                                                                                        /* ;an000; */
                                                                                                                                 /* ;an000; */
        struct  PSP_STRUC                                                                                                        /* ;an000; */
                {                                                                                                                /* ;an000; */
                unsigned int    int_20;                                                                                          /* ;an000; */
                unsigned int    top_of_memory;                                                                                   /* ;an000; */
                };                                                                                                               /* ;an000; */
                                                                                                                                 /* ;an000; */
        char     far *CarvedPtr;                                                                                                 /* ;an000; */
                                                                                                                                 /* ;an000; */
        unsigned long int total_mem;              /* total memory in system */                                                   /* ;an000; */
        unsigned long int avail_mem;              /* avail memory in system */                                                   /* ;an000; */
        unsigned long int free_mem;               /* free memory */                                                              /* ;an000; */
        struct   PSP_STRUC far *PSPptr;                                                                                            /* ;an000; */
                                                                                                                                 /* ;an000; */
/* skip a line */                                                                                                                /* ;an000; */
        Sub0_Message(NewLineMsg,STDOUT,Utility_Msg_Class);                                                                       /* ;an000; */
                                                                                                                                 /* ;an000; */
/*  get PSP info */                                                                                                              /* ;an000; */
        InRegs.h.ah = GET_PSP;                  /* get PSP function call */                                                      /* ;an000; */
        intdos(&InRegs,&OutRegs);                                                                                                /* ;an000; */
                                                                                                                                 /* ;an000; */
        FP_SEG(PSPptr) = OutRegs.x.bx;          /* PSP segment */                                                                /* ;an000; */
        FP_OFF(PSPptr) = 0;                     /* offset 0 */                                                                   /* ;an000; */

/* Get total memory in system */                                                                                                 /* ;an000; */
        int86(MEMORY_DET,&InRegs,&OutRegs);                                                                                      /* ;an000; */
                                                                                                                                 /* ;an000; */
/* Convert to bytes */                                                                                                           /* ;an000; */
        total_mem = (unsigned long int) OutRegs.x.ax * 1024l;                                                                    /* ;an000; */
        avail_mem = total_mem;
        InRegs.x.bx = 0;                                                                                                         /* ;an000; */
        InRegs.x.ax = 0xc100;                                                                                                    /* ;an000; */
        int86x(0x15, &InRegs, &OutRegs, &SegRegs);                                                                               /* ;an000; */
        if (OutRegs.x.cflag == 0)                                                                                                /* ;an000; */
              {                                                                                                                  /* ;an000; */
                FP_SEG(CarvedPtr) = SegRegs.es;                                                                                  /* ;an000; */
                FP_OFF(CarvedPtr) = 0;                                                                                           /* ;an000; */
                total_mem = total_mem + ( (unsigned long int) (*CarvedPtr) * 1024l) ;   /* ;an002; dms;adjust total for */
                }                                                                       /*             RAM carve value  */
                                                                                                                                 /* ;an000; */
        Sub1_Message(TotalMemoryMsg,STDOUT,Utility_Msg_Class,&total_mem);                                                        /* ;an000; */
                                                                                                                                 /* ;an000; */
        Sub1_Message(AvailableMemoryMsg,STDOUT,Utility_Msg_Class,&avail_mem);                                                    /* ;an000; */
                                                                                                                                 /* ;an000; */
/* Calculate the total memory used.   PSP segment * 16. Subtract from total to get free_mem */                                   /* ;an000; */
        free_mem = (DOS_TopOfMemory * 16l) - (FP_SEG(PSPptr)*16l);                                                               /* ;an000;ac005; */
                                                                                                                                 /* ;an000; */
        Sub1_Message(FreeMemoryMsg,STDOUT,Utility_Msg_Class,&free_mem);                                                          /* ;an000; */
                                                                                                                                 /* ;an000; */
                                                                                                                                 /* ;an000; */
                                                                                                                                 /* ;an000; */
        return;                                                                                                                  /* ;an000; */
                                                                                                                                 /* ;an000; */
        }                       /* end of display_low_total */                                                                   /* ;an000; */
                                                                                                                                 /* ;an000; */
                                                                                                                                /* ;an000; */
/*컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�*/                                                  /* ;an000; */
                                                                                                                                 /* ;an000; */
void DisplayEMSDetail()                                                                                                          /* ;an000; */
  {                                                                                                                              /* ;an000; */
                                                                                                                                 /* ;an000; */
#define EMSGetHandleName 0x5300         /* get handle name function */                                                           /* ;an000; */
#define EMSGetHandlePages 0x4c00        /* get handle name function */                                                           /* ;an000; */
#define EMSCODE_83      0x83            /* handle not found error */                                                             /* ;an000; */
#define EMSMaxHandles   256             /* max number handles */                                                                 /* ;an000; */
                                                                                                                                 /* ;an000; */
  int   HandleIndex;                    /* used to step through handles */                                                       /* ;an000; */
  char  HandleName[9];                  /* save area for handle name */                                                          /* ;an000; */
  unsigned long int HandleMem;          /* memory associated w/handle */                                                         /* ;an000; */
  char  TitlesPrinted = FALSE;          /* flag for printing titles */                                                           /* ;an000; */
                                                                                                                                 /* ;an000; */
  HandleName[0] = NUL;                  /* initialize the array         */                                                       /* ;an000; */
                                                                                                                                 /* ;an000; */
  Sub0_Message(NewLineMsg,STDOUT,Utility_Msg_Class);                                                                             /* ;an000; */
                                                                                                                                 /* ;an000; */
  segread(&SegRegs);                                                                                                             /* ;an000; */
                                                                                                                                 /* ;an000; */
  SegRegs.es = SegRegs.ds;                                                                                                       /* ;an000; */
                                                                                                                                 /* ;an000; */
  for (HandleIndex = 0; HandleIndex < EMSMaxHandles; HandleIndex++)                                                              /* ;an000; */
    {                                                                                                                            /* ;an000; */
                                                                                                                                 /* ;an000; */
    InRegs.x.ax = EMSGetHandleName;     /* get handle name */                                                                    /* ;an000; */
    InRegs.x.dx = HandleIndex;          /* handle in question */                                                                 /* ;an000; */
    InRegs.x.di = (unsigned int) HandleName;    /* point to handle name */                                                       /* ;an000; */
    int86x(EMS, &InRegs, &OutRegs, &SegRegs);                                                                                    /* ;an000; */
                                                                                                                                 /* ;an000; */
    HandleName[8] = NUL;                /* make sure terminated w/nul */                                                         /* ;an000; */
                                                                                                                                 /* ;an000; */
    if (OutRegs.h.ah != EMSCODE_83)                                                                                              /* ;an000; */
      {                                                                                                                          /* ;an000; */
      InRegs.x.ax = EMSGetHandlePages;  /* get pages assoc w/this handle */                                                      /* ;an000; */
      InRegs.x.dx = HandleIndex;                                                                                                 /* ;an000; */
      int86x(EMS, &InRegs, &OutRegs, &SegRegs);                                                                                  /* ;an000; */
      HandleMem = OutRegs.x.bx;                                                                                                  /* ;an000; */
      HandleMem *= (long) (16l*1024l);                                                                                           /* ;an000; */
                                                                                                                                 /* ;an000; */
      if (!TitlesPrinted)                                                                                                        /* ;an000; */
        {                                                                                                                        /* ;an000; */
        Sub0_Message(Title3Msg,STDOUT,Utility_Msg_Class);                                                                        /* ;an000; */
        Sub0_Message(Title4Msg,STDOUT,Utility_Msg_Class);                                                                        /* ;an000; */
        TitlesPrinted = TRUE;                                                                                                    /* ;an000; */
        }                                                                                                                        /* ;an000; */
                                                                                                                                 /* ;an000; */
      if (HandleName[0] == NUL) strcpy(HandleName,"        ");                                                                   /* ;an000; */
      EMSPrint(HandleMsg,                                                                                                        /* ;an000; */
               STDOUT,                                                                                                           /* ;an000; */
               Utility_Msg_Class,                                                                                                /* ;an000; */
               &HandleIndex,                                                                                                     /* ;an000; */
               HandleName,                                                                                                       /* ;an000; */
               &HandleMem);                                                                                                      /* ;an000; */
      }                                                                                                                          /* ;an000; */
                                                                                                                                 /* ;an000; */
    }                                   /* end   for (HandleIndex = 0; HandleIndex < EMSMaxHandles;HandleIndex++) */             /* ;an000; */
                                                                                                                                 /* ;an000; */
  return;                                                                                                                        /* ;an000; */
                                                                                                                                 /* ;an000; */
  }                                     /* end of DisplayEMSDetail */                                                            /* ;an000; */
                                                                                                                                 /* ;an000; */
                                                                                                                                 /* ;an000; */
                                                                                                                                /* ;an000; */
/*컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�*/                                                  /* ;an000; */
                                                                                                                                 /* ;an000; */
void DisplayExtendedSummary()                                                                                                    /* ;an000; */
  {                                                                                                                              /* ;an000; */
                                                                                                                                 /* ;an000; */
  unsigned long int       EXTMemoryTot;                                                                                          /* ;an000; */
                                                                                                                                 /* ;an000; */
  InRegs.h.ah = (unsigned char) 0x52;                                           /* Get SysVar Pointer   ;an001; dms;*/
  intdosx(&InRegs,&OutRegs,&SegRegs);                                           /* Invoke interrupt     ;an001; dms;*/
                                                                                                                                                         /* ;an000; */
  FP_SEG(SysVarsPtr) = SegRegs.es;                                              /* put pointer in var   ;an001; dms;*/
  FP_OFF(SysVarsPtr) = OutRegs.x.bx;                                            /*                      ;an001; dms;*/
  if ((SysVarsPtr) -> ExtendedMemory != 0)                                      /* extended memory?     ;an001; dms;*/
  {                                                                             /* yes                  ;an001; dms;*/
      EXTMemoryTot = (long) (SysVarsPtr) -> ExtendedMemory;                     /* get total EM size    ;an001; dms;*/
      EXTMemoryTot *= (long) 1024l;                                             /*  at boot time        ;an001; dms;*/
      Sub0_Message(NewLineMsg,STDOUT,Utility_Msg_Class);                        /* print blank line     ;an001; dms;*/
      Sub1_Message(EXTMemoryMsg,STDOUT,Utility_Msg_Class,&EXTMemoryTot);        /* print total EM mem   ;an001; dms;*/
                                                                                                                                 /* ;an000; */
      OutRegs.x.cflag = 0;                                                      /* clear carry flag     ;an001; dms;*/
      InRegs.x.ax = GetExtended;                                                /* get extended mem     ;an001; dms;*/
                                                                                /*   available                      */
      int86(CASSETTE, &InRegs, &OutRegs);                                       /* INT 15h call         ;an001; dms;*/

      EXTMemoryTot = (long) OutRegs.x.ax;                                       /* returns 1K mem blocks;an001; dms;*/
      EXTMemoryTot *= (long) 1024l;                                             /* convert to bytes     ;an001; dms;*/

      Sub1_Message(EXTMemAvlMsg,STDOUT,Utility_Msg_Class,&EXTMemoryTot);        /* display available    ;an001; dms;*/
  }

                                                                                                                                 /* ;an000; */
  return;                                                                                                                        /* ;an000; */
                                                                                                                                 /* ;an000; */
  }                                     /* end of DisplayExtendedSummary */                                                      /* ;an000; */
                                                                                                                                 /* ;an000; */
                                                                                                                                 /* ;an000; */
                                                                                                                                 /* ;an000; */
                                                                                                                                 /* ;an000; */
                                                                                                                                /* ;an000; */
/*컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�*/                                                  /* ;an000; */
                                                                                                                                 /* ;an000; */
void DisplayEMSSummary()                                                                                                         /* ;an000; */
  {                                                                                                                              /* ;an000; */
                                                                                                                                 /* ;an000; */
  unsigned long int       EMSFreeMemoryTot;                                                                                      /* ;an000; */
  unsigned long int       EMSAvailMemoryTot;                                                                                     /* ;an000; */
                                                                                                                                 /* ;an000; */
  Sub0_Message(NewLineMsg,STDOUT,Utility_Msg_Class);                                                                             /* ;an000; */
                                                                                                                                 /* ;an000; */
  InRegs.x.ax = EMSGetFreePgs;              /* get total number unallocated pages */                                             /* ;an000; */
  int86x(EMS, &InRegs, &OutRegs, &SegRegs);                                                                                      /* ;an000; */
                                                                                                                                 /* ;an000; */
  EMSFreeMemoryTot = OutRegs.x.bx;          /* total unallocated pages in  BX */                                                 /* ;an000; */
  EMSFreeMemoryTot *= (long) (16l*1024l);                                                                                        /* ;an000; */
                                                                                                                                 /* ;an000; */
  EMSAvailMemoryTot = OutRegs.x.dx;         /* total pages */                                                                    /* ;an000; */
  EMSAvailMemoryTot *= (long) (16l*1024l);                                                                                       /* ;an000; */
                                                                                                                                 /* ;an000; */
  Sub1_Message(EMSTotalMemoryMsg,STDOUT,Utility_Msg_Class,&EMSAvailMemoryTot);                                                   /* ;an000; */
  Sub1_Message(EMSFreeMemoryMsg,STDOUT,Utility_Msg_Class,&EMSFreeMemoryTot);                                                     /* ;an000; */
                                                                                                                                 /* ;an000; */
  return;                                                                                                                        /* ;an000; */
                                                                                                                                 /* ;an000; */
  }                                     /* end of DisplayEMSSummary */                                                           /* ;an000; */
                                                                                                                                 /* ;an000; */
                                                                                                                                /* ;an000; */
/*컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�*/                                                  /* ;an000; */
                                                                                                                                 /* ;an000; */
                                                                                                                                 /* ;an000; */
char EMSInstalled()                                                                                                              /* ;an000; */
  {                                                                                                                              /* ;an000; */
                                                                                                                                 /* ;an000; */
  unsigned int  EMSStatus;                                                                                                       /* ;an000; */
  unsigned int  EMSVersion;                                                                                                      /* ;an000; */
  char          ReturnFlag;                                                                                                      /* ;an000; */
                                                                                                                                 /* ;an000; */
  if (EMSInstalledFlag == 2)                                                                                                     /* ;an000; */
    {                                                                                                                            /* ;an000; */
    EMSInstalledFlag = FALSE;                                                                                                    /* ;an000; */
    InRegs.h.ah = GET_VECT;               /* get int 67 vector */                                                                /* ;an000; */
    InRegs.h.al = EMS;                                                                                                           /* ;an000; */
    intdosx(&InRegs,&OutRegs,&SegRegs);                                                                                          /* ;an000; */
                                                                                                                                 /* ;an000; */
    /* only want to try this if vector is non-zero */                                                                            /* ;an000; */
                                                                                                                                 /* ;an000; */
                                                                                                                                 /* ;an000; */
    if ((SegRegs.es != 0) && (OutRegs.x.bx != 0))                                                                                /* ;an000; */
      {                                                                                                                          /* ;an000; */
      InRegs.x.ax = EMSGetStat;           /* get EMS status */                                                                   /* ;an000; */
      int86x(EMS, &InRegs, &OutRegs, &SegRegs);                                                                                  /* ;an000; */
      EMSStatus = OutRegs.h.ah;           /* EMS status returned in AH */                                                        /* ;an000; */
                                                                                                                                 /* ;an000; */
      InRegs.x.ax = EMSGetVer;            /* get EMS version */                                                                  /* ;an000; */
      int86x(EMS, &InRegs, &OutRegs, &SegRegs);                                                                                  /* ;an000; */
      EMSVersion = OutRegs.h.al;          /* EMS version returned in AL */                                                       /* ;an000; */
                                                                                                                                 /* ;an000; */
      if ((EMSStatus == 0) && (EMSVersion >= DOSEMSVER))                                                                         /* ;an000; */
        EMSInstalledFlag = TRUE;                                                                                                 /* ;an000; */
      else                                                                                                                       /* ;an000; */
        EMSInstalledFlag = FALSE;                                                                                                /* ;an000; */
                                                                                                                                 /* ;an000; */
      }                                   /* end ((SegRegs.es != 0) && (OutRegs.x.bx != 0)) */                                   /* ;an000; */
                                                                                                                                 /* ;an000; */
    }                                   /* end if (EMSInstalledFlag == 2) */                                                     /* ;an000; */
                                                                                                                                 /* ;an000; */
                                                                                                                                 /* ;an000; */
  return(EMSInstalledFlag);                                                                                                      /* ;an000; */
                                                                                                                                 /* ;an000; */
                                                                                                                                 /* ;an000; */
  }                                                                                                                              /* ;an000; */
                                                                                                                                 /* ;an000; */
                                                                                                                                /* ;an000; */
/*컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�*/                                                  /* ;an000; */
                                                                                                                                 /* ;an000; */
                                                                                                                                 /* ;an000; */
char *OwnerOf(ArenaPtr)                                                                                                          /* ;an000; */
struct ARENA far *ArenaPtr;                                                                                                      /* ;an000; */
{                                                                                                                                /* ;an000; */
                                                                                                                                 /* ;an000; */
        char     far *StringPtr;                                                                                                 /* ;an000; */
        unsigned far *WordPtr;                                                                                                   /* ;an000; */
        char         *o;                                                                                                         /* ;an000; */
        unsigned far *EnvironmentSegmentPtr;                                                                                     /* ;an000; */
        unsigned     PspSegment;                                                                                                 /* ;an000; */
        int          i;                                                                                                          /* ;an000; */
                                                                                                                                 /* ;an000; */
        o = &OwnerName[0];                                                                                                       /* ;an000; */
        *o = NUL;                                                                                                                /* ;an000; */
        sprintf(o,UnOwned);                                                                                                      /* ;an000; */
                                                                                                                                 /* ;an000; */
        PspSegment = ArenaPtr -> Owner;                                                                                          /* ;an000; */
                                                                                                                                 /* ;an000; */
                                                                                                                                 /* ;an000; */
        if (PspSegment == 0) sprintf(o,Ibmdos);                                                                                  /* ;an000; */
         else if (PspSegment == 8) sprintf(o,Ibmbio);                                                                            /* ;an000; */
          else {                                                                                                                 /* ;an000; */
                FP_SEG(ArenaPtr) = PspSegment-1;        /* -1 'cause Arena is 16 bytes before PSP */                             /* ;an000; */
                StringPtr = (char far *) &(ArenaPtr -> OwnerName[0]);                                                            /* ;an000; */
                for (i = 0; i < 8; i++) *o++ = *StringPtr++;                                                                     /* ;an000; */
                *o = (char) '\0';                                                                                                /* ;an000; */
                }                                                                                                                /* ;an000; */
                                                                                                                                 /* ;an000; */
        if (UseArgvZero) GetFromArgvZero(PspSegment,EnvironmentSegmentPtr);                                                      /* ;an000; */
                                                                                                                                 /* ;an000; */
        return(&OwnerName[0]);                                                                                                   /* ;an000; */
                                                                                                                                 /* ;an000; */
        }                                                                                                                        /* ;an000; */
                                                                                                                                 /* ;an000; */
                                                                                                                                /* ;an000; */
/*컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�*/                                                  /* ;an000; */
                                                                                                                                 /* ;an000; */
void         GetFromArgvZero(PspSegment,EnvironmentSegmentPtr)                                                                   /* ;an000; */
unsigned     PspSegment;                                                                                                         /* ;an000; */
unsigned far *EnvironmentSegmentPtr;                                                                                             /* ;an000; */
{                                                                                                                                /* ;an000; */
                                                                                                                                 /* ;an000; */
        char    far *StringPtr;                                                                                                  /* ;an000; */
        char    *OutputPtr;                                                                                                      /* ;an000; */
        unsigned far *WordPtr;                                                                                                   /* ;an000; */
                                                                                                                                 /* ;an000; */
        OutputPtr = &OwnerName[0];                                                                                               /* ;an000; */
                                                                                                                                 /* ;an000; */
        if (UseArgvZero)                                                                                                         /* ;an000; */
              {                                                                                                                  /* ;an000; */
                if (PspSegment < FP_SEG(ArenaHeadPtr))                                                                           /* ;an000; */
                      {                                                                                                          /* ;an000; */
                        if (*OutputPtr == NUL) sprintf(OutputPtr,Ibmdos);                                                        /* ;an000; */
                        }                                                                                                        /* ;an000; */
                 else {                                                                                                          /* ;an000; */
                        FP_SEG(EnvironmentSegmentPtr) = PspSegment;                                                              /* ;an000; */
                        FP_OFF(EnvironmentSegmentPtr) = 44;                                                                      /* ;an000; */
                                                                                                                                 /* ;an000; */
/*                         FP_SEG(StringPtr) = *EnvironmentSegmentPtr;  */                                                          /* ;an000; */
                        FP_SEG(StringPtr) = FP_SEG(EnvironmentSegmentPtr);                                                              /* ;an000; */
                        FP_OFF(StringPtr) = 0;                                                                                   /* ;an000; */
                                                                                                                                 /* ;an000; */
                        while ( (*StringPtr != NUL) || (*(StringPtr+1) != NUL) ) StringPtr++;                                    /* ;an000; */
                                                                                                                                 /* ;an000; */
                        StringPtr += 2;                                                                                          /* ;an000; */
                        WordPtr = (unsigned far *) StringPtr;                                                                    /* ;an000; */
                                                                                                                                 /* ;an000; */
                        if (*WordPtr == 1)                                                                                       /* ;an000; */
                              {                                                                                                  /* ;an000; */
                                StringPtr += 2;                                                                                  /* ;an000; */
                                while (*StringPtr != NUL)                                                                        /* ;an000; */
                                        *OutputPtr++ = *StringPtr++;                                                             /* ;an000; */
                                *OutputPtr++ = NUL;                                                                              /* ;an000; */
                                                                                                                                 /* ;an000; */
                                while ( OutputPtr > &OwnerName[0] )                                                              /* ;an000; */
                                      { if (*OutputPtr == (char) '.') *OutputPtr = NUL;                                          /* ;an000; */
                                        if ( (*OutputPtr == (char) '\\') || (*OutputPtr == (char) ':') )                         /* ;an000; */
                                              { OutputPtr++;                                                                     /* ;an000; */
                                                break;                                                                           /* ;an000; */
                                                }                                                                                /* ;an000; */
                                        OutputPtr--;                                                                             /* ;an000; */
                                        }                                                                                        /* ;an000; */
                                                                                                                                 /* ;an000; */
                                }                                                                                                /* ;an000; */
                                                                                                                                 /* ;an000; */
                        }                                                                                                        /* ;an000; */
                }                                                                                                                /* ;an000; */
                                                                                                                                 /* ;an000; */
        strcpy(&OwnerName[0],OutputPtr);                                                                                         /* ;an000; */
                                                                                                                                 /* ;an000; */
        return;                                                                                                                  /* ;an000; */
                                                                                                                                 /* ;an000; */
        }                                                                                                                        /* ;an000; */
                                                                                                                                 /* ;an000; */
                                                                                                                                /* ;an000; */
/*컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�*/                                                  /* ;an000; */
                                                                                                                                 /* ;an000; */

char *TypeOf(Header)                                                                                                             /* ;an000; */
struct ARENA far *Header;                                                                                                        /* ;an000; */
{                                                                                                                                /* ;an000; */
                                                                                                                                 /* ;an000; */
        char         *t;                                                                                                         /* ;an000; */
        unsigned     PspSegment;                                                                                                 /* ;an000; */
        unsigned far *EnvironmentSegmentPtr;                                                                                     /* ;an000; */
        unsigned int Message_Number;
        char far     *Message_Buf;
        unsigned int i;
                                                                                                                                 /* ;an000; */
        t = &TypeText[0];                                                                                                        /* ;an000; */
        *t = NUL;                                                                                                                /* ;an000; */
                                                                                                                                 /* ;an000; */
        Message_Number = 0xff;                                                  /* ;an000; initialize number value      */
        if (Header -> Owner == 8) Message_Number = StackMsg;                                 /* ;an000; */
        if (Header -> Owner == 0) Message_Number = FreeMsg;                                  /* ;an000; */
                                                                                             /* ;an000; */
        PspSegment = Header -> Owner;                                                        /* ;an000; */
        if (PspSegment < FP_SEG(ArenaHeadPtr))                                               /* ;an000; */
                {                                                                              /* ;an000; */
                if (Message_Number == 0xff) Message_Number = BlankMsg;
                }                                                                            /* ;an000; */
        else {                                                                              /* ;an000; */
                FP_SEG(EnvironmentSegmentPtr) = PspSegment;                                  /* ;an000; */
                FP_OFF(EnvironmentSegmentPtr) = 44;                                          /* ;an000; */
                                                                                                                                 /* ;an000; */
                                                                                                                                 /* ;an000; */
                if (PspSegment == FP_SEG(Header)+1)
                        Message_Number = ProgramMsg;
                else if ( *EnvironmentSegmentPtr == FP_SEG(Header)+1 )
                        Message_Number = EnvironMsg;
                else
                        Message_Number = DataMsg;

                }

        InRegs.x.ax = Message_Number;                                /* ;an000; */
        InRegs.h.dh = Utility_Msg_Class;                             /* ;an000; */
        sysgetmsg(&InRegs,&SegRegs,&OutRegs);                        /* ;an000; */

        FP_OFF(Message_Buf)    = OutRegs.x.si;                                                      /* ;an000; */
        FP_SEG(Message_Buf)    = SegRegs.ds;                                                        /* ;an000; */

        i = 0;
        while ( *Message_Buf != (char) '\x0' )
                TypeText[i++] = *Message_Buf++;
        TypeText[i++] = '\x0';

                                                                                                                                 /* ;an000; */
        return(t);                                                                                                               /* ;an000; */
                                                                                                                                 /* ;an000; */
        }                                                                                                                        /* ;an000; */
                                                                                                                                 /* ;an000; */
                                                                                                                                 /* ;an000; */
/*컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�*/                                                  /* ;an000; */
                                                                                                                                 /* ;an000; */
unsigned long AddressOf(Pointer)                                                                                                 /* ;an000; */
char far *Pointer;                                                                                                               /* ;an000; */
{                                                                                                                                /* ;an000; */
                                                                                                                                 /* ;an000; */
        unsigned long SegmentAddress,OffsetAddress;                                                                              /* ;an000; */
                                                                                                                                 /* ;an000; */
        SegmentAddress = (unsigned long) (FP_SEG(Pointer)) * 16l;                                                                /* ;an000; */
        OffsetAddress = (unsigned long) (FP_OFF(Pointer));                                                                       /* ;an000; */
                                                                                                                                 /* ;an000; */
        return( SegmentAddress + OffsetAddress);                                                                                 /* ;an000; */
                                                                                                                                 /* ;an000; */
        }                                                                                                                        /* ;an000; */
                                                                                                                                 /* ;an000; */
/*컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�*/                                                  /* ;an000; */
                                                                                                                                 /* ;an000; */
                                                                                                                                 /* ;an000; */
/************************************************************************/                                                       /* ;an000; */
/* SUB0_MESSAGE                 - This routine will print only those    */                                                       /* ;an000; */
/*                                messages that do not require a        */                                                       /* ;an000; */
/*                                a sublist.                            */                                                       /* ;an000; */
/*                                                                      */                                                       /* ;an000; */
/*      Inputs  : Msg_Num       - number of applicable message          */                                                       /* ;an000; */
/*                Handle        - display type                          */                                                       /* ;an000; */
/*                Message_Type  - type of message to display            */                                                       /* ;an000; */
/*                                                                      */                                                       /* ;an000; */
/*      Outputs : message                                               */                                                       /* ;an000; */
/*                                                                      */                                                       /* ;an000; */
/************************************************************************/                                                       /* ;an000; */
                                                                                                                                 /* ;an000; */
void Sub0_Message(Msg_Num,Handle,Message_Type)                                       /* print messages with no subs          */  /* ;an000; */
                                                                                                                                 /* ;an000; */
int             Msg_Num;                                                                                                         /* ;an000; */
int             Handle;                                                                                                          /* ;an000; */
unsigned char   Message_Type;                                                                                                    /* ;an000; */
                                                                                /*     extended, parse, or utility      */       /* ;an000; */
        {                                                                                                                        /* ;an000; */
        InRegs.x.ax = Msg_Num;                                                  /* put message number in AX             */       /* ;an000; */
        InRegs.x.bx = Handle;                                                   /* put handle in BX                     */       /* ;an000; */
        InRegs.x.cx = No_Replace;                                               /* no replaceable subparms              */       /* ;an000; */
        InRegs.h.dl = No_Input;                                                 /* no keyboard input                    */       /* ;an000; */
        InRegs.h.dh = Message_Type;                                             /* type of message to display           */       /* ;an000; */
        sysdispmsg(&InRegs,&OutRegs);                                          /* display the message                  */        /* ;an000; */
                                                                                                                                 /* ;an000; */
        return;                                                                                                                  /* ;an000; */
        }                                                                                                                        /* ;an000; */
                                                                                                                                 /* ;an000; */
                                                                                                                                 /* ;an000; */
/************************************************************************/                                                       /* ;an000; */
/* SUB1_MESSAGE                 - This routine will print only those    */                                                       /* ;an000; */
/*                                messages that require 1 replaceable   */                                                       /* ;an000; */
/*                                parm.                                 */                                                       /* ;an000; */
/*                                                                      */                                                       /* ;an000; */
/*      Inputs  : Msg_Num       - number of applicable message          */                                                       /* ;an000; */
/*                Handle        - display type                          */                                                       /* ;an000; */
/*                Message_Type  - type of message to display            */                                                       /* ;an000; */
/*                Replace_Parm  - pointer to parm to replace            */                                                       /* ;an000; */
/*                                                                      */                                                       /* ;an000; */
/*      Outputs : message                                               */                                                       /* ;an000; */
/*                                                                      */                                                       /* ;an000; */
/************************************************************************/                                                       /* ;an000; */
                                                                                                                                 /* ;an000; */
void Sub1_Message(Msg_Num,Handle,Message_Type,Replace_Parm)                                                                      /* ;an000; */
                                                                                                                                 /* ;an000; */
int             Msg_Num;                                                                                                         /* ;an000; */
int             Handle;                                                                                                          /* ;an000; */
unsigned char   Message_Type;                                                                                                    /* ;an000; */
                                                                                /*     extended, parse, or utility      */       /* ;an000; */
unsigned long int    *Replace_Parm;                                             /* pointer to message to print          */       /* ;an000; */
                                                                                                                                 /* ;an000; */
{                                                                                                                                /* ;an000; */
                                                                                                                                 /* ;an000; */
                                                                                                                                 /* ;an000; */
        {                                                                                                                        /* ;an000; */
                                                                                                                                 /* ;an000; */
        sublist[1].value     = (unsigned far *)Replace_Parm;                                                                     /* ;an000; */
        sublist[1].size      = Sublist_Length;                                                                                   /* ;an000; */
        sublist[1].reserved  = Reserved;                                                                                         /* ;an000; */
        sublist[1].id        = 1;                                                                                                /* ;an000; */
        sublist[1].flags     = Unsgn_Bin_DWord+Right_Align;                                                                      /* ;an000; */
        sublist[1].max_width = 10;                                                                                               /* ;an000; */
        sublist[1].min_width = 10;                                                                                               /* ;an000; */
        sublist[1].pad_char  = Blank;                                                                                            /* ;an000; */
                                                                                                                                 /* ;an000; */
        InRegs.x.ax = Msg_Num;                                                                                                   /* ;an000; */
        InRegs.x.bx = Handle;                                                                                                    /* ;an000; */
        InRegs.x.cx = SubCnt1;                                                                                                   /* ;an000; */
        InRegs.h.dl = No_Input;                                                                                                  /* ;an000; */
        InRegs.h.dh = Message_Type;                                                                                              /* ;an000; */
        InRegs.x.si = (unsigned int)&sublist[1];                                                                                 /* ;an000; */
        sysdispmsg(&InRegs,&OutRegs);                                                                                            /* ;an000; */
        }                                                                                                                        /* ;an000; */
        return;                                                                                                                  /* ;an000; */
}                                                                                                                                /* ;an000; */
                                                                                                                                 /* ;an000; */
                                                                                                                                 /* ;an000; */
/************************************************************************/                                                       /* ;an000; */
/* SUB2_MESSAGE                 - This routine will print only those    */                                                       /* ;an000; */
/*                                messages that require 2 replaceable   */                                                       /* ;an000; */
/*                                parms.                                */                                                       /* ;an000; */
/*                                                                      */                                                       /* ;an000; */
/*      Inputs  : Msg_Num       - number of applicable message          */                                                       /* ;an000; */
/*                Handle        - display type                          */                                                       /* ;an000; */
/*                Message_Type  - type of message to display            */                                                       /* ;an000; */
/*                Replace_Parm1 - pointer to parm to replace            */                                                       /* ;an000; */
/*                Replace_Parm2 - pointer to parm to replace            */                                                       /* ;an000; */
/*                Replace_Parm3 - pointer to parm to replace            */                                                       /* ;an000; */
/*                                                                      */                                                       /* ;an000; */
/*      Outputs : message                                               */                                                       /* ;an000; */
/*                                                                      */                                                       /* ;an000; */
/************************************************************************/                                                       /* ;an000; */
                                                                                                                                 /* ;an000; */
void Sub2_Message(Msg_Num,Handle,Message_Type,                                                                                   /* ;an000; */
             Replace_Parm1,                                                                                                      /* ;an000; */
             Replace_Message1)                                                                                                   /* ;an000; */
                                                                                                                                 /* ;an000; */
int             Msg_Num;                                                                                                         /* ;an000; */
int             Handle;                                                                                                          /* ;an000; */
unsigned char   Message_Type;                                                                                                    /* ;an000; */
int             Replace_Message1;                                                                                                /* ;an000; */
                                                                                /*     extended, parse, or utility      */       /* ;an000; */
char    *Replace_Parm1;                                                         /* pointer to message to print          */       /* ;an000; */
{                                                                                                                                /* ;an000; */
                                                                                                                                 /* ;an000; */
                                                                                                                                 /* ;an000; */
        {                                                                                                                        /* ;an000; */
                switch(Msg_Num)                                                                                                  /* ;an000; */
                        {                                                                                                        /* ;an000; */
                        case    DeviceLineMsg:                                                                                   /* ;an000; */
                                                                                                                                 /* ;an000; */
                                sublist[1].value     = (unsigned far *)Replace_Parm1;                                            /* ;an000; */
                                sublist[1].size      = Sublist_Length;                                                           /* ;an000; */
                                sublist[1].reserved  = Reserved;                                                                 /* ;an000; */
                                sublist[1].id        = 1;                                                                        /* ;an000; */
                                sublist[1].flags     = Char_Field_ASCIIZ+Left_Align;                                             /* ;an000; */
                                sublist[1].max_width = 0x0008;                                                                   /* ;an000; */
                                sublist[1].min_width = 0x0008;                                                                   /* ;an000; */
                                sublist[1].pad_char  = Blank;                                                                    /* ;an000; */
                                                                                                                                 /* ;an000; */
                                InRegs.x.ax = Replace_Message1;                                                                  /* ;an000; */
                                InRegs.h.dh = Message_Type;                                                                      /* ;an000; */
                                sysgetmsg(&InRegs,&SegRegs,&OutRegs);                                                            /* ;an000; */
                                                                                                                                 /* ;an000; */
                                FP_OFF(sublist[2].value)    = OutRegs.x.si;                                                      /* ;an000; */
                                FP_SEG(sublist[2].value)    = SegRegs.ds;                                                        /* ;an000; */
                                sublist[2].size      = Sublist_Length;                                                           /* ;an000; */
                                sublist[2].reserved  = Reserved;                                                                 /* ;an000; */
                                sublist[2].id        = 2;                                                                        /* ;an000; */
                                sublist[2].flags     = Char_Field_ASCIIZ+Right_Align;                                            /* ;an000; */
                                sublist[2].max_width = 00;                                                                       /* ;an000; */
                                sublist[2].min_width = 10;                                                                       /* ;an000; */
                                sublist[2].pad_char  = Blank;                                                                    /* ;an000; */
                                break;                                                                                           /* ;an000; */
                        }                                                                                                        /* ;an000; */
                                                                                                                                 /* ;an000; */
        InRegs.x.ax = Msg_Num;                                                                                                   /* ;an000; */
        InRegs.x.bx = Handle;                                                                                                    /* ;an000; */
        InRegs.x.cx = SubCnt2;                                                                                                   /* ;an000; */
        InRegs.h.dl = No_Input;                                                                                                  /* ;an000; */
        InRegs.h.dh = Message_Type;                                                                                              /* ;an000; */
        InRegs.x.si = (unsigned int)&sublist[1];                                                                                 /* ;an000; */
        sysdispmsg(&InRegs,&OutRegs);                                                                                            /* ;an000; */
        }                                                                                                                        /* ;an000; */
        return;                                                                                                                  /* ;an000; */
}                                                                                                                                /* ;an000; */
                                                                                                                                 /* ;an000; */
/************************************************************************/                                                       /* ;an000; */
/* SUB3_MESSAGE                 - This routine will print only those    */                                                       /* ;an000; */
/*                                messages that require 3 replaceable   */                                                       /* ;an000; */
/*                                parms.                                */                                                       /* ;an000; */
/*                                                                      */                                                       /* ;an000; */
/*      Inputs  : Msg_Num       - number of applicable message          */                                                       /* ;an000; */
/*                Handle        - display type                          */                                                       /* ;an000; */
/*                Message_Type  - type of message to display            */                                                       /* ;an000; */
/*                Replace_Parm1 - pointer to parm to replace            */                                                       /* ;an000; */
/*                Replace_Parm2 - pointer to parm to replace            */                                                       /* ;an000; */
/*                Replace_Parm3 - pointer to parm to replace            */                                                       /* ;an000; */
/*                                                                      */                                                       /* ;an000; */
/*      Outputs : message                                               */                                                       /* ;an000; */
/*                                                                      */                                                       /* ;an000; */
/************************************************************************/                                                       /* ;an000; */
                                                                                                                                 /* ;an000; */
void Sub3_Message(Msg_Num,Handle,Message_Type,                                                                                   /* ;an000; */
             Replace_Parm1,                                                                                                      /* ;an000; */
             Replace_Parm2,                                                                                                      /* ;an000; */
             Replace_Message1)                                                                                                   /* ;an000; */
                                                                                                                                 /* ;an000; */
int               Msg_Num;                                                                                                       /* ;an000; */
int               Handle;                                                                                                        /* ;an000; */
unsigned char     Message_Type;                                                                                                  /* ;an000; */
char              *Replace_Parm1;                                                                                                /* ;an000; */
unsigned long int *Replace_Parm2;                                                                                                /* ;an000; */
int               Replace_Message1;                                                                                              /* ;an000; */
                                                                                /*     extended, parse, or utility      */       /* ;an000; */
{                                                                                                                                /* ;an000; */
                                                                                                                                 /* ;an000; */
                                                                                                                                 /* ;an000; */
        {                                                                                                                        /* ;an000; */
                switch(Msg_Num)                                                                                                  /* ;an000; */
                        {                                                                                                        /* ;an000; */
                        case    DriverLineMsg:                                                                                   /* ;an000; */
                                                                                                                                 /* ;an000; */
                                sublist[1].value     = (unsigned far *)Replace_Parm1;                                            /* ;an000; */
                                sublist[1].size      = Sublist_Length;                                                           /* ;an000; */
                                sublist[1].reserved  = Reserved;                                                                 /* ;an000; */
                                sublist[1].id        = 1;                                                                        /* ;an000; */
                                sublist[1].flags     = Char_Field_ASCIIZ+Left_Align;                                             /* ;an000; */
                                sublist[1].max_width = 0x0008;                                                                   /* ;an000; */
                                sublist[1].min_width = 0x0008;                                                                   /* ;an000; */
                                sublist[1].pad_char  = Blank;                                                                    /* ;an000; */
                                                                                                                                 /* ;an000; */
                                sublist[2].value     = (unsigned far *)Replace_Parm2;                                            /* ;an000; */
                                sublist[2].size      = Sublist_Length;                                                           /* ;an000; */
                                sublist[2].reserved  = Reserved;                                                                 /* ;an000; */
                                sublist[2].id        = 2;                                                                        /* ;an000; */
                                sublist[2].flags     = Bin_Hex_DWord+Right_Align;                                                /* ;an000; */
                                sublist[2].max_width = 0x0006;                                                                   /* ;an000; */
                                sublist[2].min_width = 0x0006;                                                                   /* ;an000; */
                                sublist[2].pad_char  = 0x0030;                                                                   /* ;an000; */
                                                                                                                                 /* ;an000; */
                                InRegs.x.ax = Replace_Message1;                                                                  /* ;an000; */
                                InRegs.h.dh = Message_Type;                                                                      /* ;an000; */
                                sysgetmsg(&InRegs,&SegRegs,&OutRegs);                                                            /* ;an000; */
                                                                                                                                 /* ;an000; */
                                FP_OFF(sublist[3].value)    = OutRegs.x.si;                                                      /* ;an000; */
                                FP_SEG(sublist[3].value)    = SegRegs.ds;                                                        /* ;an000; */
                                sublist[3].size      = Sublist_Length;                                                           /* ;an000; */
                                sublist[3].reserved  = Reserved;                                                                 /* ;an000; */
                                sublist[3].id        = 3;                                                                        /* ;an000; */
                                sublist[3].flags     = Char_Field_ASCIIZ+Left_Align;                                             /* ;an000; */
                                sublist[3].max_width = 00;                                                                       /* ;an000; */
                                sublist[3].min_width = 10;                                                                       /* ;an000; */
                                sublist[3].pad_char  = Blank;                                                                    /* ;an000; */
                                break;                                                                                           /* ;an000; */
                                                                                                                                 /* ;an000; */
                        case    HandleMsg:                                                                                       /* ;an000; */
                                sublist[1].value     = (unsigned far *)Replace_Parm1;                                            /* ;an000; */
                                sublist[1].size      = Sublist_Length;                                                           /* ;an000; */
                                sublist[1].reserved  = Reserved;                                                                 /* ;an000; */
                                sublist[1].id        = 1;                                                                        /* ;an000; */
                                sublist[1].flags     = Unsgn_Bin_Byte+Right_Align;                                               /* ;an000; */
                                sublist[1].max_width = 0x0009;                                                                   /* ;an000; */
                                sublist[1].min_width = 0x0009;                                                                   /* ;an000; */
                                sublist[1].pad_char  = Blank;                                                                    /* ;an000; */
                                                                                                                                 /* ;an000; */
                                sublist[2].value     = (unsigned far *)Replace_Parm2;                                            /* ;an000; */
                                sublist[2].size      = Sublist_Length;                                                           /* ;an000; */
                                sublist[2].reserved  = Reserved;                                                                 /* ;an000; */
                                sublist[2].id        = 2;                                                                        /* ;an000; */
                                sublist[2].flags     = Char_Field_ASCIIZ+Left_Align;                                             /* ;an000; */
                                sublist[2].max_width = 0x0008;                                                                   /* ;an000; */
                                sublist[2].min_width = 0x0008;                                                                   /* ;an000; */
                                sublist[2].pad_char  = Blank;                                                                    /* ;an000; */
                                                                                                                                 /* ;an000; */
                                InRegs.x.ax = Replace_Message1;                                                                  /* ;an000; */
                                InRegs.h.dh = Message_Type;                                                                      /* ;an000; */
                                sysgetmsg(&InRegs,&SegRegs,&OutRegs);                                                            /* ;an000; */
                                                                                                                                 /* ;an000; */
                                FP_OFF(sublist[3].value)    = OutRegs.x.si;                                                      /* ;an000; */
                                FP_SEG(sublist[3].value)    = SegRegs.ds;                                                        /* ;an000; */
                                sublist[3].size      = Sublist_Length;                                                           /* ;an000; */
                                sublist[3].reserved  = Reserved;                                                                 /* ;an000; */
                                sublist[3].id        = 3;                                                                        /* ;an000; */
                                sublist[3].flags     = Bin_Hex_DWord+Right_Align;                                                /* ;an000; */
                                sublist[3].max_width = 00;                                                                       /* ;an000; */
                                sublist[3].min_width = 10;                                                                       /* ;an000; */
                                sublist[3].pad_char  = Blank;                                                                    /* ;an000; */
                                break;                                                                                           /* ;an000; */
                                                                                                                                 /* ;an000; */
                        }                                                                                                        /* ;an000; */
                                                                                                                                 /* ;an000; */
        InRegs.x.ax = Msg_Num;                                                                                                   /* ;an000; */
        InRegs.x.bx = Handle;                                                                                                    /* ;an000; */
        InRegs.x.cx = SubCnt3;                                                                                                   /* ;an000; */
        InRegs.h.dl = No_Input;                                                                                                  /* ;an000; */
        InRegs.h.dh = Message_Type;                                                                                              /* ;an000; */
        InRegs.x.si = (unsigned int)&sublist[1];                                                                                 /* ;an000; */
        sysdispmsg(&InRegs,&OutRegs);                                                                                            /* ;an000; */
        }                                                                                                                        /* ;an000; */
        return;                                                                                                                  /* ;an000; */
}                                                                                                                                /* ;an000; */
                                                                                                                                 /* ;an000; */
                                                                                                                                 /* ;an000; */
/************************************************************************/                                                       /* ;an000; */
/* SUB4_MESSAGE                 - This routine will print only those    */                                                       /* ;an000; */
/*                                messages that require 4 replaceable   */                                                       /* ;an000; */
/*                                parms.                                */                                                       /* ;an000; */
/*                                                                      */                                                       /* ;an000; */
/*      Inputs  : Msg_Num       - number of applicable message          */                                                       /* ;an000; */
/*                Handle        - display type                          */                                                       /* ;an000; */
/*                Message_Type  - type of message to display            */                                                       /* ;an000; */
/*                Replace_Parm1 - pointer to parm to replace            */                                                       /* ;an000; */
/*                Replace_Parm2 - pointer to parm to replace            */                                                       /* ;an000; */
/*                Replace_Parm3 - pointer to parm to replace            */                                                       /* ;an000; */
/*                Dynamic_Parm  - parm number to use as replaceable     */                                                       /* ;an000; */
/*                                                                      */                                                       /* ;an000; */
/*      Outputs : message                                               */                                                       /* ;an000; */
/*                                                                      */                                                       /* ;an000; */
/************************************************************************/                                                       /* ;an000; */
                                                                                                                                 /* ;an000; */
void Sub4_Message(Msg_Num,Handle,Message_Type,                                                                                   /* ;an000; */
             Replace_Value1,                                                                                                     /* ;an000; */
             Replace_Message1,                                                                                                   /* ;an000; */
             Replace_Value2,                                                                                                     /* ;an000; */
             Replace_Message2)                                                                                                   /* ;an000; */
                                                                                                                                 /* ;an000; */
int                     Msg_Num;                                                                                                 /* ;an000; */
int                     Handle;                                                                                                  /* ;an000; */
unsigned char           Message_Type;                                                                                            /* ;an000; */
unsigned long int       *Replace_Value1;                                                                                         /* ;an000; */
int                     Replace_Message1;                                                                                        /* ;an000; */
unsigned long int       *Replace_Value2;                                                                                         /* ;an000; */
int                     Replace_Message2;                                                                                        /* ;an000; */
                                                                                /*     extended, parse, or utility      */       /* ;an000; */
{                                                                                                                                /* ;an000; */
                                                                                                                                 /* ;an000; */
                                                                                                                                 /* ;an000; */
        {                                                                                                                        /* ;an000; */
                switch(Msg_Num)                                                                                                  /* ;an000; */
                        {                                                                                                        /* ;an000; */
                        case    MainLineMsg:                                                                                     /* ;an000; */
                                                                                                                                 /* ;an000; */
                                sublist[1].value     = (unsigned far *)Replace_Value1;                                           /* ;an000; */
                                sublist[1].size      = Sublist_Length;                                                           /* ;an000; */
                                sublist[1].reserved  = Reserved;                                                                 /* ;an000; */
                                sublist[1].id        = 1;                                                                        /* ;an000; */
                                sublist[1].flags     = Bin_Hex_DWord+Right_Align;                                                /* ;an000; */
                                sublist[1].max_width = 06;                                                                       /* ;an000; */
                                sublist[1].min_width = 06;                                                                       /* ;an000; */
                                sublist[1].pad_char  = 0x0030;                                                                   /* ;an000; */
                                                                                                                                 /* ;an000; */
                                InRegs.x.ax        = Replace_Message1;                                                           /* ;an000; */
                                InRegs.h.dh        = Message_Type;                                                               /* ;an000; */
                                sysgetmsg(&InRegs,&SegRegs,&OutRegs);                                                            /* ;an000; */
                                                                                                                                 /* ;an000; */
                                FP_OFF(sublist[2].value)    = OutRegs.x.si;                                                      /* ;an000; */
                                FP_SEG(sublist[2].value)    = SegRegs.ds;                                                        /* ;an000; */
                                sublist[2].size      = Sublist_Length;                                                           /* ;an000; */
                                sublist[2].reserved  = Reserved;                                                                 /* ;an000; */
                                sublist[2].id        = 2;                                                                        /* ;an000; */
                                sublist[2].flags     = Char_Field_ASCIIZ+Left_Align;                                             /* ;an000; */
                                sublist[2].max_width = 0x0008;                                                                   /* ;an000; */
                                sublist[2].min_width = 0x0008;                                                                   /* ;an000; */
                                sublist[2].pad_char  = Blank;                                                                    /* ;an000; */
                                                                                                                                 /* ;an000; */
                                sublist[3].value     = (unsigned far *)Replace_Value2;                                           /* ;an000; */
                                sublist[3].size      = Sublist_Length;                                                           /* ;an000; */
                                sublist[3].reserved  = Reserved;                                                                 /* ;an000; */
                                sublist[3].id        = 3;                                                                        /* ;an000; */
                                sublist[3].flags     = Bin_Hex_DWord+Right_Align;                                                /* ;an000; */
                                sublist[3].max_width = 06;                                                                       /* ;an000; */
                                sublist[3].min_width = 06;                                                                       /* ;an000; */
                                sublist[3].pad_char  = 0x0030;                                                                   /* ;an000; */
                                                                                                                                 /* ;an000; */
                                InRegs.x.ax = Replace_Message2;                                                                  /* ;an000; */
                                InRegs.h.dh = Message_Type;                                                                      /* ;an000; */
                                sysgetmsg(&InRegs,&SegRegs,&OutRegs);                                                            /* ;an000; */
                                                                                                                                 /* ;an000; */
                                FP_OFF(sublist[4].value)    = OutRegs.x.si;                                                      /* ;an000; */
                                FP_SEG(sublist[4].value)    = SegRegs.ds;                                                        /* ;an000; */
                                sublist[4].size      = Sublist_Length;                                                           /* ;an000; */
                                sublist[4].reserved  = Reserved;                                                                 /* ;an000; */
                                sublist[4].id        = 4;                                                                        /* ;an000; */
                                sublist[4].flags     = Char_Field_ASCIIZ+Left_Align;                                             /* ;an000; */
                                sublist[4].max_width = 0;                                                                        /* ;an000; */
                                sublist[4].min_width = 10;                                                                       /* ;an000; */
                                sublist[4].pad_char  = Blank;                                                                    /* ;an000; */
                                break;                                                                                           /* ;an000; */
                        }                                                                                                        /* ;an000; */
                                                                                                                                 /* ;an000; */
        InRegs.x.ax = Msg_Num;                                                                                                   /* ;an000; */
        InRegs.x.bx = Handle;                                                                                                    /* ;an000; */
        InRegs.x.cx = SubCnt4;                                                                                                   /* ;an000; */
        InRegs.h.dl = No_Input;                                                                                                  /* ;an000; */
        InRegs.h.dh = Message_Type;                                                                                              /* ;an000; */
        InRegs.x.si = (unsigned int)&sublist[1];                                                                                 /* ;an000; */
        sysdispmsg(&InRegs,&OutRegs);                                                                                            /* ;an000; */
        }                                                                                                                        /* ;an000; */
        return;                                                                                                                  /* ;an000; */
}                                                                                                                                /* ;an000; */
                                                                                                                                 /* ;an000; */
                                                                                                                                 /* ;an000; */
                                                                                                                                 /* ;an000; */
/************************************************************************/                                                       /* ;an000; */
/* SUB4a_MESSAGE                - This routine will print only those    */                                                       /* ;an000; */
/*                                messages that require 4 replaceable   */                                                       /* ;an000; */
/*                                parms.                                */                                                       /* ;an000; */
/*                                                                      */                                                       /* ;an000; */
/*      Inputs  : Msg_Num       - number of applicable message          */                                                       /* ;an000; */
/*                Handle        - display type                          */                                                       /* ;an000; */
/*                Message_Type  - type of message to display            */                                                       /* ;an000; */
/*                Replace_Parm1 - pointer to parm to replace            */                                                       /* ;an000; */
/*                Replace_Parm2 - pointer to parm to replace            */                                                       /* ;an000; */
/*                Replace_Parm3 - pointer to parm to replace            */                                                       /* ;an000; */
/*                Dynamic_Parm  - parm number to use as replaceable     */                                                       /* ;an000; */
/*                                                                      */                                                       /* ;an000; */
/*      Outputs : message                                               */                                                       /* ;an000; */
/*                                                                      */                                                       /* ;an000; */
/************************************************************************/                                                       /* ;an000; */
                                                                                                                                 /* ;an000; */
void Sub4a_Message(Msg_Num,Handle,Message_Type,                                                                                  /* ;an000; */
             Replace_Value1,                                                                                                     /* ;an000; */
             Replace_Message1,                                                                                                   /* ;an000; */
             Replace_Value2,                                                                                                     /* ;an000; */
             Replace_Message2)                                                                                                   /* ;an000; */
                                                                                                                                 /* ;an000; */
int                     Msg_Num;                                                                                                 /* ;an000; */
int                     Handle;                                                                                                  /* ;an000; */
unsigned char           Message_Type;                                                                                            /* ;an000; */
unsigned long int       *Replace_Value1;                                                                                         /* ;an000; */
char                    *Replace_Message1;                                                                                       /* ;an000; */
unsigned long int       *Replace_Value2;                                                                                         /* ;an000; */
char                    *Replace_Message2;                                                                                       /* ;an000; */
                                                                                                                                 /* ;an000; */
{                                                                                                                                /* ;an000; */
                                                                                                                                 /* ;an000; */
                                                                                                                                 /* ;an000; */
        {                                                                                                                        /* ;an000; */
                switch(Msg_Num)                                                                                                  /* ;an000; */
                        {                                                                                                        /* ;an000; */
                        case    MainLineMsg:                                                                                     /* ;an000; */
                                                                                                                                 /* ;an000; */
                                sublist[1].value     = (unsigned far *)Replace_Value1;                                           /* ;an000; */
                                sublist[1].size      = Sublist_Length;                                                           /* ;an000; */
                                sublist[1].reserved  = Reserved;                                                                 /* ;an000; */
                                sublist[1].id        = 1;                                                                        /* ;an000; */
                                sublist[1].flags     = Bin_Hex_DWord+Right_Align;                                                /* ;an000; */
                                sublist[1].max_width = 06;                                                                       /* ;an000; */
                                sublist[1].min_width = 06;                                                                       /* ;an000; */
                                sublist[1].pad_char  = 0x0030;                                                                   /* ;an000; */
                                                                                                                                 /* ;an000; */
                                sublist[2].value     = (unsigned far *)Replace_Message1;                                         /* ;an000; */
                                sublist[2].size      = Sublist_Length;                                                           /* ;an000; */
                                sublist[2].reserved  = Reserved;                                                                 /* ;an000; */
                                sublist[2].id        = 2;                                                                        /* ;an000; */
                                sublist[2].flags     = Char_Field_ASCIIZ+Left_Align;                                             /* ;an000; */
                                sublist[2].max_width = 0x0008;                                                                   /* ;an000; */
                                sublist[2].min_width = 0x0008;                                                                   /* ;an000; */
                                sublist[2].pad_char  = Blank;                                                                    /* ;an000; */
                                                                                                                                 /* ;an000; */
                                sublist[3].value     = (unsigned far *)Replace_Value2;                                           /* ;an000; */
                                sublist[3].size      = Sublist_Length;                                                           /* ;an000; */
                                sublist[3].reserved  = Reserved;                                                                 /* ;an000; */
                                sublist[3].id        = 3;                                                                        /* ;an000; */
                                sublist[3].flags     = Bin_Hex_DWord+Right_Align;                                                /* ;an000; */
                                sublist[3].max_width = 06;                                                                       /* ;an000; */
                                sublist[3].min_width = 06;                                                                       /* ;an000; */
                                sublist[3].pad_char  = 0x0030;                                                                   /* ;an000; */
                                                                                                                                 /* ;an000; */
                                sublist[4].value     = (unsigned far *)Replace_Message2;                                         /* ;an000; */
                                sublist[4].size      = Sublist_Length;                                                           /* ;an000; */
                                sublist[4].reserved  = Reserved;                                                                 /* ;an000; */
                                sublist[4].id        = 4;                                                                        /* ;an000; */
                                sublist[4].flags     = Char_Field_ASCIIZ+Left_Align;                                             /* ;an000; */
                                sublist[4].max_width = 0;                                                                        /* ;an000; */
                                sublist[4].min_width = 10;                                                                       /* ;an000; */
                                sublist[4].pad_char  = Blank;                                                                    /* ;an000; */
                                break;                                                                                           /* ;an000; */
                        }                                                                                                        /* ;an000; */
                                                                                                                                 /* ;an000; */
        InRegs.x.ax = Msg_Num;                                                                                                   /* ;an000; */
        InRegs.x.bx = Handle;                                                                                                    /* ;an000; */
        InRegs.x.cx = SubCnt4;                                                                                                   /* ;an000; */
        InRegs.h.dl = No_Input;                                                                                                  /* ;an000; */
        InRegs.h.dh = Message_Type;                                                                                              /* ;an000; */
        InRegs.x.si = (unsigned int)&sublist[1];                                                                                 /* ;an000; */
        sysdispmsg(&InRegs,&OutRegs);                                                                                            /* ;an000; */
        }                                                                                                                        /* ;an000; */
        return;                                                                                                                  /* ;an000; */
}                                                                                                                                /* ;an000; */
                                                                                                                                 /* ;an000; */
                                                                                                                                 /* ;an000; */
/************************************************************************/                                                       /* ;an000; */
/* EMSPrint                     - This routine will print the message   */                                                       /* ;an000; */
/*                                necessary for EMS reporting.          */                                                       /* ;an000; */
/*                                                                      */                                                       /* ;an000; */
/*      Outputs : message                                               */                                                       /* ;an000; */
/*                                                                      */                                                       /* ;an000; */
/************************************************************************/                                                       /* ;an000; */
                                                                                                                                 /* ;an000; */
void EMSPrint(Msg_Num,Handle,Message_Type,                                                                                       /* ;an000; */
             Replace_Value1,                                                                                                     /* ;an000; */
             Replace_Message1,                                                                                                   /* ;an000; */
             Replace_Value2)                                                                                                     /* ;an000; */
                                                                                                                                 /* ;an000; */
int                     Msg_Num;                                                                                                 /* ;an000; */
int                     Handle;                                                                                                  /* ;an000; */
unsigned char           Message_Type;                                                                                            /* ;an000; */
int                     *Replace_Value1;                                                                                         /* ;an000; */
char                    *Replace_Message1;                                                                                       /* ;an000; */
unsigned long int       *Replace_Value2;                                                                                         /* ;an000; */
                                                                                /*     extended, parse, or utility      */       /* ;an000; */
{                                                                                                                                /* ;an000; */
                                                                                                                                 /* ;an000; */
        {                                                                                                                        /* ;an000; */
        sublist[1].value     = (unsigned far *)Replace_Value1;                                                                   /* ;an000; */
        sublist[1].size      = Sublist_Length;                                                                                   /* ;an000; */
        sublist[1].reserved  = Reserved;                                                                                         /* ;an000; */
        sublist[1].id        = 1;                                                                                                /* ;an000; */
        sublist[1].flags     = Unsgn_Bin_Word+Right_Align;                                                                       /* ;an000; */
        sublist[1].max_width = 03;                                                                                               /* ;an000; */
        sublist[1].min_width = 03;                                                                                               /* ;an000; */
        sublist[1].pad_char  = Blank;                                                                                            /* ;an000; */
                                                                                                                                 /* ;an000; */
        sublist[2].value     = (unsigned far *)Replace_Message1;                                                                 /* ;an000; */
        sublist[2].size      = Sublist_Length;                                                                                   /* ;an000; */
        sublist[2].reserved  = Reserved;                                                                                         /* ;an000; */
        sublist[2].id        = 2;                                                                                                /* ;an000; */
        sublist[2].flags     = Char_Field_ASCIIZ+Left_Align;                                                                     /* ;an000; */
        sublist[2].max_width = 0x0008;                                                                                           /* ;an000; */
        sublist[2].min_width = 0x0008;                                                                                           /* ;an000; */
        sublist[2].pad_char  = Blank;                                                                                            /* ;an000; */
                                                                                                                                 /* ;an000; */
        sublist[3].value     = (unsigned far *)Replace_Value2;                                                                   /* ;an000; */
        sublist[3].size      = Sublist_Length;                                                                                   /* ;an000; */
        sublist[3].reserved  = Reserved;                                                                                         /* ;an000; */
        sublist[3].id        = 3;                                                                                                /* ;an000; */
        sublist[3].flags     = Bin_Hex_DWord+Right_Align;                                                                        /* ;an000; */
        sublist[3].max_width = 06;                                                                                               /* ;an000; */
        sublist[3].min_width = 06;                                                                                               /* ;an000; */
        sublist[3].pad_char  = 0x0030;                                                                                           /* ;an000; */
                                                                                                                                 /* ;an000; */
        InRegs.x.ax = Msg_Num;                                                                                                   /* ;an000; */
        InRegs.x.bx = Handle;                                                                                                    /* ;an000; */
        InRegs.x.cx = SubCnt3;                                                                                                   /* ;an000; */
        InRegs.h.dl = No_Input;                                                                                                  /* ;an000; */
        InRegs.h.dh = Message_Type;                                                                                              /* ;an000; */
        InRegs.x.si = (unsigned int)&sublist[1];                                                                                 /* ;an000; */
        sysdispmsg(&InRegs,&OutRegs);                                                                                            /* ;an000; */
        }                                                                                                                        /* ;an000; */
        return;                                                                                                                  /* ;an000; */
}                                                                                                                                /* ;an000; */
                                                                                                                                 /* ;an000; */
/*----------------------------------------------------------------------+
|                                                                       |
|  SUBROUTINE NAME:     PARSE_INIT                                      |
|                                                                       |
|  SUBROUTINE FUNCTION:                                                 |
|                                                                       |
|       This routine is called by the FILESYS MAIN routine to initialize|
|       the parser data structures.                                     |
|                                                                       |
|  INPUT:                                                               |
|       none                                                            |
|                                                                       |
|  OUTPUT:                                                              |
|       properly initialized parser control blocks                      |
|                                                                       |
+----------------------------------------------------------------------*/
void parse_init()                                                                                                                /* ;an000; */
  {                                                                                                                              /* ;an000; */
  p_p.p_parmsx_address    = &p_px;      /* address of extended parm list */                                                      /* ;an000; */
  p_p.p_num_extra         = 0;                                                                                                   /* ;an000; */
                                                                                                                                 /* ;an000; */
  p_px.p_minp             = 0;                                                                                                   /* ;an000; */
  p_px.p_maxp             = 0;                                                                                                   /* ;an000; */
  p_px.p_maxswitch        = 2;                                                                                                   /* ;an000; */
  p_px.p_control[0]       = &p_con1;                                                                                             /* ;an000; */
  p_px.p_control[1]       = &p_con2;                                                                                             /* ;an000; */
  p_px.p_keyword          = 0;                                                                                                   /* ;an000; */
                                                                                                                                 /* ;an000; */
  p_con1.p_match_flag     = p_none;                                                                                              /* ;an000; */
  p_con1.p_function_flag  = p_cap_file;                                                                                          /* ;an000; */
  p_con1.p_result_buf     = (unsigned int)&p_result1;                                                                            /* ;an000; */
  p_con1.p_value_list     = (unsigned int)&p_noval;                                                                              /* ;an000; */
  p_con1.p_nid            = 1;                                                                                                   /* ;an000; */
  strcpy(p_con1.p_keyorsw,"/DEBUG"+NUL);                                                                                         /* ;an000; */
                                                                                                                                 /* ;an000; */
  p_con2.p_match_flag     = p_none;                                                                                              /* ;an000; */
  p_con2.p_function_flag  = p_cap_file;                                                                                          /* ;an000; */
  p_con2.p_result_buf     = (unsigned int)&p_result2;                                                                            /* ;an000; */
  p_con2.p_value_list     = (unsigned int)&p_noval;                                                                              /* ;an000; */
  p_con2.p_nid            = 1;                                                                                                   /* ;an000; */
  strcpy(p_con2.p_keyorsw,"/PROGRAM"+NUL);                                                                                       /* ;an000; */
                                                                                                                                 /* ;an000; */
  p_noval.p_val_num       = 0;                                                                                                   /* ;an000; */
                                                                                                                                 /* ;an000; */
  p_result1.P_Type        = 0;                                                                                                   /* ;an000; */
  p_result1.P_Item_Tag    = 0;                                                                                                   /* ;an000; */
  p_result1.P_SYNONYM_Ptr = 0;                                                                                                   /* ;an000; */
  p_result1.p_result_buff = 0;                                                                                                   /* ;an000; */
                                                                                                                                 /* ;an000; */
  p_result2.P_Type        = 0;                                                                                                   /* ;an000; */
  p_result2.P_Item_Tag    = 0;                                                                                                   /* ;an000; */
  p_result2.P_SYNONYM_Ptr = 0;                                                                                                   /* ;an000; */
  p_result2.p_result_buff = 0;                                                                                                   /* ;an000; */
                                                                                                                                 /* ;an000; */
  return;                                                                                                                        /* ;an000; */
                                                                                                                                 /* ;an000; */
  }                                     /* end parse_init */                                                                     /* ;an000; */


/************************************************************************/                                                       /* ;an000; */
/* Parse_Message                - This routine will print only those    */
/*                                messages that require 1 replaceable   */
/*                                parm.                                 */
/*                                                                      */
/*      Inputs  : Msg_Num       - number of applicable message          */
/*                Handle        - display type                          */
/*                Message_Type  - type of message to display            */
/*                Replace_Parm  - pointer to parm to replace            */
/*                                                                      */
/*      Outputs : message                                               */
/*                                                                      */
/************************************************************************/

void Parse_Message(Msg_Num,Handle,Message_Type)                                 /*;an003; dms;                          */
                                                                                /*;an003; dms;                          */
int             Msg_Num;                                                        /*;an003; dms;                          */
int             Handle;                                                         /*;an003; dms;                          */
unsigned char   Message_Type;                                                   /*;an003; dms;                          */
                                                                                /*;an003; dms;                          */
{                                                                               /*;an003; dms;                          */
char    far *Cmd_Ptr;                                                           /*;an003; dms;                          */
                                                                                /*;an003; dms;                          */
                                                                                /*;an003; dms;                          */
        {                                                                       /*;an003; dms;                          */
        segread(&SegRegs);                                                      /*;an003; dms;                          */
        FP_SEG(Cmd_Ptr) = SegRegs.ds;                                           /*;an003; dms;                          */
        FP_OFF(Cmd_Ptr) = OutRegs.x.si;                                         /*;an003; dms;                          */
        *Cmd_Ptr        = '\0';                                                 /*;an003; dms;                          */
                                                                                /*;an003; dms;                          */
        FP_SEG(sublist[1].value) = SegRegs.ds;                                  /*;an003; dms;                          */
        FP_OFF(sublist[1].value) = Parse_Ptr;                                   /*;an003; dms;                          */
        sublist[1].size      = Sublist_Length;                                  /*;an003; dms;                          */
        sublist[1].reserved  = Reserved;                                        /*;an003; dms;                          */
        sublist[1].id        = 0;                                               /*;an003; dms;                          */
        sublist[1].flags     = Char_Field_ASCIIZ+Left_Align;                    /*;an003; dms;                          */
        sublist[1].max_width = 40;                                              /*;an003; dms;                          */
        sublist[1].min_width = 01;                                              /*;an003; dms;                          */
        sublist[1].pad_char  = Blank;                                           /*;an003; dms;                          */
                                                                                /*;an003; dms;                          */
        InRegs.x.ax = Msg_Num;                                                  /*;an003; dms;                          */
        InRegs.x.bx = Handle;                                                   /*;an003; dms;                          */
        InRegs.x.cx = SubCnt1;                                                  /*;an003; dms;                          */
        InRegs.h.dl = No_Input;                                                 /*;an003; dms;                          */
        InRegs.h.dh = Message_Type;                                             /*;an003; dms;                          */
        InRegs.x.si = (unsigned int)&sublist[1];                                /*;an003; dms;                          */
        sysdispmsg(&InRegs,&OutRegs);                                           /*;an003; dms;                          */
        }                                                                       /*;an003; dms;                          */
        return;                                                                 /*;an003; dms;                          */
}                                                                               /*;an003; dms;                          */


