/*  */
/*                                                                          */
/****************************************************************************/
/* Define statements                                                        */
/****************************************************************************/
/*                                                                          */

#define FLAG      char                                                  /* AN000 */
#define BEGIN     {
#define END       }
#define ESC       0x1B
#define ESC_FLAG  -2                                                    /* AN000 */
#define NUL       0x00
#define NOT_FOUND 0xFF
#define DELETED   -2                                                    /* AC011 */
#define INVALID   0xFF
#define PRIMARY   0x00
#define EXTENDED  0x05
#define BAD_BLOCK 0xFF
#define XENIX1    0x02
#define XENIX2    0x03
#define PCIX      0x75
#define DOS12     0x01
#define DOS16     0x04
#define DOSNEW    0x06                                                   /* AN000 */
#define FAT16_SIZE 32680
#define VOLUME    0x00
#define FALSE   (char) (1==0)                                           /* AC000 */
#define TRUE    (char) !FALSE                                           /* AC000 */
#define LOGICAL   0x05
#define CR        0x0D
#define BACKSPACE 0x08
#define ACTIVE    0x80
#define DOS_MAX   65535                /* Allow exactly 32mb worth of partitions */
#define SYSTEM_FILE_SECTORS 250
#define BYTES_PER_SECTOR 512                                            /* AN000 */

#include <version.h>

#define NETWORK   0x2F
#define INSTALLATION_CHECK  0xB800
#define SERVER_CHECK        0x40


#define FILE_NAME     ":\\????????.???"                                 /* AN000 */
#define NOVOLUME      ""                                                /* AN000 */
#define NOFORMAT      "UNKNOWN "                                        /* AN000 */
#define FAT12         "FAT12   "                                        /* AN000 */
#define FAT16         "FAT16   "                                        /* AN000 */
#define SEA           'C'                                               /* AN000 */
#define ZERO          0                                                 /* AN000 */
#define NO_GOOD       0x02                                              /* AN000 */
#define FIND_FIRST_MATCH 0x4E                                           /* AN000 */
#define GET_DTA          0x2F                                           /* AN000 */
#define NETWORK_IOCTL    0x4409                                         /* AN000 */
#define GENERIC_IOCTL    0x440D                                         /* AN000 */
#define GET_MEDIA_ID     0x0866                                         /* AN007 */
#define SPECIAL_FUNCTION 0x0867                                         /* AN002 AC008 */
#define CAPCHAR    0x6520                                               /* AN000 */
#define CAPSTRING  0x6521                                               /* AN000 */
#define CAP_YN     0x6523                                               /* AN000 */
#define INT21   0x21                                                    /* AN000 */
#define DISK    0x13                                                    /* AN000 */
#define NOERROR 0                                                       /* AN000 */
#define BLANKS  "            "                                          /* AN000 */
#define MAX_STRING_INPUT_LENGTH 11                                      /* AN000 */
#define ERR_LEVEL_0  0                                                  /* AN001 */
#define ERR_LEVEL_1  1                                                  /* AN001 */
#define ERR_LEVEL_2  2                                                  /* AN005 */

#define READ_DISK 2
#define WRITE_DISK 3
#define DISK_INFO 8

#define CURRENT_VIDEO_ATTRIBUTE 8                                       /* AN006 */
#define CURRENT_VIDEO_STATE     15
#define SET_ACTIVE_DISPLAY_PAGE 5
#define SET_MODE       0
#define SET_PAGE       5
#define SET_CURSOR     0x02                                             /* AN006 */
#define WRITE_ATTRCHAR 0x09                                             /* AN006 */
#define VIDEO          0x10
#define SCROLL_PAGE_UP 0x0600                                           /* AN006 */
#define BW40_25        0
#define Color40_25     1
#define BW80_25        2
#define Color80_25     3
#define Color320_200   4
#define BW320_200      5
#define BW640_200      6
#define MONO80_25      7
#define MONO80_25A     15                                               /* AN006 */

#define NORMAL_PRELOAD         0                                        /* AN000 */
#define ALL_UTILITY_MESSAGES  -1                                        /* AN000 */
#define NO_SUBST_TEXT          0                                        /* AN000 */
#define NO_RESPONSE            0                                        /* AN000 */
#define CLASS                 -1                                        /* AN000 */ * AN000 */
#define NUL_POINTER            0                                        /* AN000 */
#define SUBST_LIST             0                                        /* AN000 */
#define SUBST_COUNT            0                                        /* AN000 */

#define VOL_LABEL              0x08                                     /* AN000 */
#define PERCENT                0x25                                     /* AN000 */
#define DECIMAL                0x2E                                     /* AN000 */
#define PERIOD                 0x2E                                     /* AN000 */
#define ONE_MEG                1048576                                  /* AN000 */

     #if IBMCOPYRIGHT
#define HIWHITE_ON_BLUE        0x1F                                     /* AN006 */
#define WHITE_ON_BLUE          0x17                                     /* AN006 */
#define BLINK_HIWHITE_ON_BLUE  0x9F                                     /* AN006 */
#define HIWHITE_ON_BLACK       0x0F                                     /* AN006 */
#define GRAY_ON_BLACK          0x07                                     /* AN006 */
     #else
#define HIWHITE_ON_BLUE        0x0F                                     /* AN006 */
#define WHITE_ON_BLUE          0x07                                     /* AN006 */
#define BLINK_HIWHITE_ON_BLUE  0x8F                                     /* AN006 */
#define HIWHITE_ON_BLACK       0x0F                                     /* AN006 */
#define GRAY_ON_BLACK          0x07 
     #endif


#define BYTE    unsigned char                                           /* AN000 */
#define WORD    unsigned short                                          /* AN000 */
#define DWORD   unsigned long                                           /* AN000 */
#define sw_type                                                         /* AN000 */
#define sw_item_tag                                                     /* AN000 */
#define sw_synonym                                                      /* AN000 */
#define sw_value                                                        /* AN000 */

#define CARRY_FLAG              0x0001  /* mask for carry flag */       /* AN000 */
#define PARITY_FLAG             0x0004  /* mask for parity flag */      /* AN000 */
#define ACARRY_FLAG             0x0010  /* mask for aux carry flag */   /* AN000 */
#define ZERO_FLAG               0x0040  /* mask for zero flag */        /* AN000 */
#define SIGN_FLAG               0x0080  /* mask for sign flag */        /* AN000 */
#define TRAP_FLAG               0x0100  /* mask for trap flag */        /* AN000 */
#define INTERRUPT_FLAG          0x0200  /* mask for interrupt flag */   /* AN000 */
#define DIRECTION_FLAG          0x0400  /* mask for direction flag */   /* AN000 */
#define OVERFLOW_FLAG           0x0800  /* mask for overflow flag */    /* AN000 */

#define         SEMICOLON       0x3B           /* AN000 - VALID COMMAND LINE DELIMITER*/

#define XFLOAT          unsigned

#define u(c)            ((unsigned)(c))                                 /* AN000 */
#define f(c)            ((XFLOAT)(c))                                   /* AN000 */
#define c(c)            ((char)(c))                                     /* AN000 */
#define d(c)            ((double)(c))                                   /* AN004 */
#define uc(c)           ((unsigned char)(c))                            /* AN000 */
#define ui(c)           ((unsigned int)(c))                             /* AN000 */
#define ul(c)           ((unsigned long)(c))                            /* AN000 */


struct entry
    BEGIN
     unsigned char       boot_ind;
     unsigned char       start_head;
     unsigned char       start_sector;
     unsigned            start_cyl;
     unsigned char       sys_id;
     unsigned char       end_head;
     unsigned char       end_sector;
     unsigned            end_cyl;
     unsigned long       rel_sec;
     unsigned long       num_sec;
     char                order;
     FLAG                changed;
     unsigned            mbytes_used;                                   /* AN000 */
     unsigned            percent_used;                                  /* AN000 */
     char                vol_label[12];                                 /* AN000 */
     char                system[9];                                     /* AN000 */
     char                drive_letter;                                  /* AN000 */
    END;

struct freespace
   BEGIN
    unsigned        space;
    unsigned        start;
    unsigned        end;
    unsigned        mbytes_unused;                                      /* AN000 */
    unsigned        percent_unused;                                     /* AN000 */
    char            volume_id[12];                                      /* AN000 */
   END;

struct diskaccess                                                       /* AN002 */
   BEGIN                                                                /* AN002 */
    char            dac_special_func;                                   /* AN002 */
    char            dac_access_flag;                                    /* AN002 */
   END;                                                                 /* AN002 */

struct dx_buffer_ioctl                                                  /* AN000 */
   BEGIN                                                                /* AN000 */
    unsigned int    info_level;          /* Information level */        /* AN000 */
    unsigned long   serial_num;          /* serial number     */        /* AN000 */
    char            vol_label[11];       /* volume label      */        /* AN000 */
    char            file_system[8];      /* file system       */        /* AN000 */
   END;                                                                 /* AN000 */

struct subst_list                                                       /* AN000 */
  BEGIN                                                                 /* AN000 */
    char        sl_size1;      /* Size of List */                       /* AN000 */
    char        zero1;         /* Reserved */                           /* AN000 */
    char far   *value1;        /* Time, date, or ptr to data item*/     /* AN000 */
    char        one;           /* n of %n */                            /* AN000 */
    char        flags1;        /* Data Type flags */                    /* AN000 */
    char        max_width1;    /* Maximum FIELD width */                /* AN000 */
    char        min_width1;    /* Minimum FIELD width */                /* AN000 */
    char        pad_char1;     /* Character for pad FIELD */            /* AN000 */
  END;                                                                  /* AN000 */

struct sublistx                                                                                                                /* ;an000; */
  BEGIN                                                                                                                          /* ;an000; */
    unsigned char size;                                                         /* sublist size                         */       /* ;an000; */
    unsigned char reserved;                                                     /* reserved for future growth           */       /* ;an000; */
    unsigned far *value;                                                        /* pointer to replaceable parm          */       /* ;an000; */
    unsigned char id;                                                           /* type of replaceable parm             */       /* ;an000; */
    unsigned char flags;                                                        /* how parm is to be displayed          */       /* ;an000; */
    unsigned char max_width;                                                    /* max width of replaceable field       */       /* ;an000; */
    unsigned char min_width;                                                    /* min width of replaceable field       */       /* ;an000; */
    unsigned char pad_char;                                                     /* pad character for replaceable field  */       /* ;an000; */
  END;
                                                                                                                                 /* ;an000; */
