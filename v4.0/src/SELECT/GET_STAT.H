
/*  */
/*                                                                          */
/****************************************************************************/
/* Define statements                                                        */
/****************************************************************************/
/*                  Get_status Input                                        */
#define FST_DRV 0x01
#define SEC_DRV 0x02
/*                                                                          */
/*                  EQUATES FOR N_PART_NAME                                 */
#define E_PART_PRI_DOS      0x01
#define E_PART_EXT_DOS      0x02
#define E_PART_LOG_DRI      0x03
#define E_FREE_MEM_EDOS     0x04
#define E_FREE_MEM_DISK     0x05
#define E_PART_OTHER        0x06
/*                                                                          */
/*                  EQUATES FOR N_PART_STATUS                               */
#define E_PART_UNFORMAT     0x00
#define E_PART_FORMAT       0x01
/*                                                                          */
/*                  EQUATES FOR N_PART_TYPE                                 */
#define E_PART_FAT          0x01
#define E_PART_KSAM         0x02
#define E_PART_UNDEF        0x03
#define E_PART_IGNORE       0x04

/* DISK_1_TABLE        equals  M_DISK_1_ITEMS   */
/* DISK_1_VAL_ITEM     equals  zero             */
/* DISK_1_START        equals  100 times SIZ_DISKSTRUC bytes  */
#define M_DISK_1_ITEMS          ( sizeof(disk_1_start) / SIZ_DISKSTRUC )


/* DISK_2_TABLE        equals  M_DISK_2_ITEMS   */
/* DISK_2_VAL_ITEM     equals  zero             */
/* DISK_2_START        equals  100 times SIZ_DISKSTRUC bytes */
#define SIZ_DISKSTRUC           ( sizeof(struc disk_status))
#define M_DISK_2_ITEMS          ( sizeof(disk_2_start) / SIZ_DISKSTRUC )
/*                  EQUATES FOR BX FLAGS                                    */
#define E_DISK_PRI          0x01
#define E_DISK_EXT_DOS      0x02
#define E_DISK_LOG_DRI      0x04
#define E_DISK_EDOS_MEM     0x08
#define E_DISK_FREE_MEM     0x10


/*                                                                          */

#define FLAG    char                                                    /* AN000 */
#define BEGIN    {
#define END      }
#define ESC     0x1B
#define NUL     0x00
#define NOT_FOUND 0xFF
#define DELETED   0xFF
#define INVALID   0xFF
#define PRIMARY 0x00
#define EXTENDED 0x05
#define BAD_BLOCK 0xFF
#define XENIX1    0x02
#define XENIX2    0x03
#define PCIX     0x75
#define DOS12    0x01
#define DOS16    0x04
#define DOSNEW   0x06                                                   /* AN000 */
#define FAT16_SIZE 32680
#define VOLUME  0x00
#define FALSE   (char) (1==0)                                           /* AC000 */
#define TRUE    (char) !FALSE                                           /* AC000 */
#define LOGICAL 0x05
#define CR      0x0D
#define BACKSPACE 0x08
#define ACTIVE  0x80
#define DOS_MAX   (64*1024) /* Allow exactly 32mb worth of partitions */
#define SYSTEM_FILE_SECTORS 100
#define BYTES_PER_SECTOR 512                                            /* AN000 */



#define NETWORK  0x2F
#define INSTALLATION_CHECK  0xB800
#define SERVER_CHECK        0x40


#define FILE_NAME     ":\\????????.???"                                 /* AN000 */
#define NOVOLUME      " no label  "                                     /* AN000 */
#define NOFORMAT      " no fmt "                                        /* AN000 */
#define FAT           "  FAT   "                                        /* AN000 */
#define ZERO          0                                                 /* AN000 */
#define NO_GOOD       0x02                                              /* AN000 */
#define FIND_FIRST_MATCH 0x4E                                           /* AN000 */
#define GET_DTA          0x2F                                           /* AN000 */
#define GENERIC_IOCTL    0x440D                                         /* AN000 */
#define GET_MEDIA_ID     0x086E                                         /* AN000 */
#define CAPCHAR    0x6520                                               /* AN000 */
#define CAPSTRING  0x6521                                               /* AN000 */
#define CAP_YN     0x6523                                               /* AN000 */
#define INT21   0x21                                                    /* AN000 */
#define DISK    0x13                                                    /* AN000 */
#define NOERROR 0                                                       /* AN000 */
#define BLANKS  "             "                                         /* AN000 */

#define READ_DISK 2
#define WRITE_DISK 3
#define DISK_INFO 8


#define VOL_LABEL              0x08                                     /* AN000 */
#define PERCENT                0x025                                    /* AN000 */
#define PERIOD                 0x02E                                    /* AN000 */
#define ONE_MEG                1048576                                  /* AN000 */

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
#define c(c)            ((char)(c))                                     /* AN000 */
#define f(c)            ((XFLOAT)(c))                                 /* AN000 */
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
     FLAG                formatted;
     XFLOAT              mbytes_used;                                   /* AN000 */
     char                drive_letter;                                  /* AN000 */
     char                system_level[4];                               /* AN000 */
    END;

struct DISK_STATUS
   BEGIN
    unsigned char   n_part_name  ;
    unsigned        n_part_size  ;
    unsigned char   n_part_status;
    unsigned char   p_part_drive ;                                      /* AN000 */
    unsigned char   n_part_type  ;                                      /* AN000 */
    char            n_part_level[4];                                    /* AN000 */
   END OneDiskStatusEntry;            /* TWO ARRAYS to be OUTPUT in ES:DI */

typedef struct DISK_STATUS DSE ;

struct freespace
   BEGIN
    unsigned        space;
    unsigned        start;
    unsigned        end;
    unsigned        mbytes_unused;                                      /* AN000 */
   END;

struct dx_buffer_ioctl                                                  /* AN000 */
   BEGIN                                                                /* AN000 */
    unsigned int    info_level;          /* Information level */        /* AN000 */
    unsigned long   serial_num;          /* serial number     */        /* AN000 */
    char            vol_label[9];        /* volume label      */        /* AN000 */
    char            file_system[12];     /* file system       */        /* AN000 */
   END;                                                                 /* AN000 */



