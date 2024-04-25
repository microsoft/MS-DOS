
#include "stdio.h"                                                      /* ;AN000; */
#include "stdlib.h"                                                     /* ;AN000; */
#include "string.h"                                                     /* ;AN000; */
#include "dos.h"                                                        /* ;AN000; */
#include "get_stat.h"                                                   /* ;AN000; */
#include "extern.h"                                                     /* ;AN000; */
									/* ;AN000; */
char	  read_boot_record(unsigned,unsigned char,unsigned char,unsigned char);  /* ;AN000; */
void	  DiskIo(union REGS *,union REGS *, struct SREGS *);		/* ;AN000; */
unsigned  cylinders_to_mbytes(unsigned,unsigned char,unsigned char);	/* ;AN000; */
char	  get_drive_parameters(unsigned char);				/* ;AN000; */
char	  get_disk_info(void);						/* ;AN000; */
									/* ;AN000; */
/*  */ 								/* ;AN000; */
char get_disk_info()							/* ;AN000; */
									/* ;AN000; */
BEGIN									/* ;AN000; */
									/* ;AN000; */
unsigned char	i;							/* ;AN000; */
									/* ;AN000; */
	/* Initialize values */ 					/* ;AN000; */
	number_of_drives = uc(0);					/* ;AN000; */
	for (i=uc(0); i < uc(2); i++)					/* ;AN000; */
	   BEGIN							/* ;AN000; */
	    total_disk[i] = u(0);					/* ;AN000; */
	    total_mbytes[i] = f(0);					/* ;AN000; */
	    max_sector[i] = uc(0);					/* ;AN000; */
	    max_head[0] = uc(0);					/* ;AN000; */
	   END								/* ;AN000; */
									/* ;AN000; */
	/* See how many drives there are */				/* ;AN000; */
	if (get_drive_parameters(uc(0x80)))				/* ;AN000; */
									/* ;AN000; */
	   BEGIN							/* ;AN000; */
	    /* Get the drive parameters for all drives */		/* ;AN000; */
	    for (i = uc(0); i < number_of_drives;i++)			/* ;AN000; */
									/* ;AN000; */
	       BEGIN							/* ;AN000; */
		if (get_drive_parameters(uc(0x80)+i))			/* ;AN000; */
									/* ;AN000; */
		   BEGIN						/* ;AN000; */
		    /* Save drive parameters */ 			/* ;AN000; */
		    max_sector[i] = ((unsigned char)(regs.h.cl & 0x3F)); /* ;AN000; */
		    max_head[i] = ((unsigned char)(regs.h.dh +1));	/* ;AN000; */
		    total_disk[i] = ((((unsigned)(regs.h.cl & 0xC0 )) & 0x00C0) << 2)+ ((unsigned)regs.h.ch) +1; /* ;AN000; */
		    total_mbytes[i] = cylinders_to_mbytes(total_disk[i], max_sector[i], max_head[i]); /* ;AN000; */
		   END							/* ;AN000; */
		else							/* ;AN000; */
		   BEGIN						/* ;AN000; */
		    good_disk[i] = FALSE;				/* ;AN000; */
		    return(FALSE);					/* ;AN000; */
		   END							/* ;AN000; */
	       END							/* ;AN000; */
	    return(TRUE);						/* ;AN000; */
	   END								/* ;AN000; */
	else								/* ;AN000; */
	    /* No drives present */					/* ;AN000; */
	    BEGIN							/* ;AN000; */
	     no_fatal_error = FALSE;					/* ;AN000; */
	     return(FALSE);						/* ;AN000; */
	    END 							/* ;AN000; */
END									/* ;AN000; */
									/* ;AN000; */
									/* ;AN000; */
									/* ;AN000; */
									/* ;AN000; */
/*  */ 								/* ;AN000; */
char get_drive_parameters(drive)					/* ;AN000; */
									/* ;AN000; */
unsigned char	drive;							/* ;AN000; */
									/* ;AN000; */
BEGIN									/* ;AN000; */
	/* See how many drives there are */				/* ;AN000; */
	regs.h.ah = uc(DISK_INFO);					/* ;AN000; */
	regs.h.dl = drive;						/* ;AN000; */
	DiskIo(&regs,&regs,&segregs);					/* ;AN000; */
									/* ;AN000; */
	/* See if any drives exist */					/* ;AN000; */
	if ((regs.h.dl == uc(0)) || ((regs.x.cflag & 1) == u(1)))	/* ;AN000; */
	   BEGIN							/* ;AN000; */
	    return(FALSE);						/* ;AN000; */
	   END								/* ;AN000; */
	else								/* ;AN000; */
	   BEGIN							/* ;AN000; */
	    /* Save the number of drives */				/* ;AN000; */
	    number_of_drives = regs.h.dl;				/* ;AN000; */
		if (number_of_drives < 2) good_disk[1] = FALSE; 	/* ;AN000; */
		if (number_of_drives < 1) good_disk[0] = FALSE; 	/* ;AN000; */
	    return(TRUE);						/* ;AN000; */
	   END								/* ;AN000; */
									/* ;AN000; */
END									/* ;AN000; */
									/* ;AN000; */
/*  */ 								/* ;AN000; */
char read_boot_record(cylinder,which_disk,which_head,which_sector)	/* ;AN000; */
									/* ;AN000; */
unsigned	cylinder;						/* ;AN000; */
unsigned char	which_disk;						/* ;AN000; */
unsigned char	which_head;						/* ;AN000; */
unsigned char	which_sector;						/* ;AN000; */
									/* ;AN000; */
BEGIN									/* ;AN000; */
									/* ;AN000; */
char far *buffer_pointer = boot_record; 				/* ;AN000; */
									/* ;AN000; */
	/* Setup read, always on a cylinder boundary */ 		/* ;AN000; */
	regs.h.ah = uc(READ_DISK);					/* ;AN000; */
	regs.h.al = uc(1);						/* ;AN000; */
	regs.h.dh = which_head; 					/* ;AN000; */
	regs.h.cl = which_sector;					/* ;AN000; */
									/* ;AN000; */
	/* Specify the disk */						/* ;AN000; */
	regs.h.dl = which_disk + 0x80;					/* ;AN000; */
									/* ;AN000; */
	/* Need to scramble CX so that sectors and cyl's are in INT 13 format */ /* ;AN000; */
									/* ;AN000; */
	if (cylinder > u(255))						/* ;AN000; */
	   BEGIN							/* ;AN000; */
	    regs.h.cl = regs.h.cl | ((char)((cylinder /256) << 6));	/* ;AN000; */
	   END								/* ;AN000; */
	regs.h.ch = (unsigned char)(cylinder & 0xFF);			/* ;AN000; */
									/* ;AN000; */
	/* Point at the place to write the boot record */		/* ;AN000; */
	regs.x.bx = FP_OFF(buffer_pointer);				/* ;AN000; */
	segregs.es = FP_SEG(buffer_pointer);				/* ;AN000; */
									/* ;AN000; */
	/* read in the boot record */					/* ;AN000; */
	DiskIo(&regs,&regs,&segregs);					/* ;AN000; */
	/* Check for error reading it */				/* ;AN000; */
	if ((regs.x.cflag & 1) != u(1)) 				/* ;AN000; */
	   BEGIN							/* ;AN000; */
	    return(TRUE);						/* ;AN000; */
	   END								/* ;AN000; */
	else								/* ;AN000; */
	   BEGIN							/* ;AN000; */
	    /* Tell user there was an error */				/* ;AN000; */
	    good_disk[which_disk] = FALSE;				/* ;AN000; */
	    return(FALSE);						/* ;AN000; */
	   END								/* ;AN000; */
END									/* ;AN000; */
									/* ;AN000; */
/*  */ 								/* ;AN000; */
void DiskIo(InRegs,OutRegs,SegRegs)					/* ;AN000; */
union	REGS	*InRegs;						/* ;AN000; */
union	REGS	*OutRegs;						/* ;AN000; */
struct	SREGS	*SegRegs;						/* ;AN000; */
									/* ;AN000; */
BEGIN									/* ;AN000; */
									/* ;AN000; */
	char	*WritePtr;						/* ;AN000; */
									/* ;AN000; */
#ifdef DEBUG								/* ;AN000; */
									/* ;AN000; */
	switch(InRegs->h.ah)						/* ;AN000; */
	      { 							/* ;AN000; */
		case 0: 						/* ;AN000; */
		case 1: 						/* ;AN000; */
		case 2: 						/* ;AN000; */
		case 4: 						/* ;AN000; */
		case 8: 						/* ;AN000; */
		case 15:						/* ;AN000; */
		case 16:						/* ;AN000; */
			int86x((int)DISK,InRegs,OutRegs,SegRegs);	/* ;AN000; */
			break;						/* ;AN000; */
									/* ;AN000; */
		default:						/* ;AN000; */
			WritePtr = getenv("WRITE");                     /* ;AN000; */
			if (strcmpi(WritePtr,"ON") != 0)                /* ;AN000; */
			       BEGIN					/* ;AN000; */
				printf("\nDisallowing Disk I/O Request\n"); /* ;AN000; */
				printf("AX:%04X BX:%04X CX:%04X DX:%04X ES:%04X\n", /* ;AN000; */
					InRegs->x.ax,InRegs->x.bx,InRegs->x.cx,InRegs->x.dx,SegRegs->es);  /* ;AN000; */
									/* ;AN000; */
				OutRegs->h.ah = (unsigned char) 0;	/* ;AN000; */
				OutRegs->x.cflag = (unsigned) 0;	/* ;AN000; */
				END					/* ;AN000; */
			 else int86x((int)DISK,InRegs,OutRegs,SegRegs); /* ;AN000; */
									/* ;AN000; */
			break;						/* ;AN000; */
									/* ;AN000; */
		}							/* ;AN000; */
									/* ;AN000; */
#else									/* ;AN000; */
									/* ;AN000; */
	int86x((int)DISK,InRegs,OutRegs,SegRegs);			/* ;AN000; */
									/* ;AN000; */
#endif									/* ;AN000; */
									/* ;AN000; */
	return; 							/* ;AN000; */
									/* ;AN000; */
END									/* ;AN000; */
									/* ;AN000; */
