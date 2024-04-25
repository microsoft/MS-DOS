/*
 *  FLUSH13 -- Device mod utility for INT13 memory cache
 *
 *  FLUSH13 [/s|/sx|/sr] [/d|/e] [/l|/u] [/i] [/f] [/wt:on|/wt:off]
 *	    [/wc:on|/wc:off] [/t:nnnnn] [/r:on|/r:off] [/c:on|/c:off]
 *
 *	  No arguments - This causes FLUSH13 to flush out any "dirty"
 *		  tracks in the INT13 cache. A "dirty" track is one
 *		  which has been written into the cache, but not yet
 *		  written to the disk. This invokation causes all dirty tracks
 *		  to be written out to the disk so that the system can
 *		  be re-booted or turned off. NOTE: FAILURE TO FLUSH
 *		  THE CACHE BEFORE A RE-BOOT OR POWER OFF CAN CAUSE THE
 *		  INFORMATION ON THE HARDFILE TO BE CORRUPTED.
 *
 *	  /f	  - Flush. Same as the no arguments case, but allows you to
 *		  perform the flush and do something else (like /s).
 *
 *	  /i	  - Flush and invalidate. This is the same as the no argument
 *		  case except that all of the information in the cache
 *		  is also discarded. This makes the cache EMPTY.
 *
 *	  /d	  - Disable caching. This causes all dirty cache information
 *		  to be flushed and all caching to stop.
 *
 *	  /e	  - Enable caching. This causes caching to be enabled after
 *		  a previous /d disable. When INT13 is started it is enabled.
 *
 *	  /l	  - Lock the cache. This causes all dirty information to be
 *		  flushed, and the cache contents to be locked in the cache.
 *		  When in this mode the locked elements will not be discarded
 *		  to make room for new tracks. This can be used
 *		  to "load" the cache with desired things. For instance if
 *		  you use the "foobar" program a lot, you can run foobar,
 *		  causing it to be loaded into the cache, then lock the cache.
 *		  This causes the foobar program to always be in the cache.
 *		  You may lock the cache as many times as you want. Each lock
 *		  causes the current information (including any previously
 *		  locked information) to be locked.
 *		  NOTE: Information in a locked cache is READ ONLY!! Any write
 *		  operation on information in a locked cache causes the
 *		  information to be unlocked.
 *
 *	  /u	  - Unlock the cache. This undoes a previous /l and returns
 *		  the cache to normal operation.
 *
 *	  /s	  - Print status. This displays the settings of the setable
 *		  device parameters.
 *	  /sx	  - Print extended status. Same as /s, only additional
 *		  Statistical information is also given.
 *	  /sr	  - Reset statistics. Same as /sx, only the additional
 *		  Statistical information is reset to 0.
 *
 *	  /wt:on off - Enable or Disable write through. When INT13 is caching
 *		  write information, it is a good idea to imply a flush of
 *		  the cache on some operations so that in case of a crash or
 *		  power failure the information in the cache which is not on
 *		  the disk will not be lost. /wt:on enables write through on full
 *		  track INT 13s which are to tracks not currently in the cache.
 *		  /wt:off disables it. INT13 is faster with write through
 *		  off, at the expense of there being a bigger risk of
 *		  loosing data. /wt:on IS NOT a substitute for flushing before
 *		  a re-boot!!!! This write through mechanism is far from perfect,
 *		  all it is is a risk REDUCER, not a risk eliminator. /wt:off
 *		  is the setting when INT13 is started.
 *
 *	  /wc:on off - Enable or Disable write caching. There is risk when
 *		  caching "dirty" information that the system will crash,
 *		  or be re-booted, or be turned off before this information
 *		  can be written to the disk. This may corrupt the disk.
 *		  This risk can be ELIMINATED, at the expense of cache
 *		  performance, by NOT caching any dirty information.
 *		  /wc:off disables the caching of dirty information,
 *		  eliminating the risk. /wc:on enables the caching of dirty
 *		  information. /wc:on is the default when INT13 is started.
 *
 *		  WARNING: You must be careful to flush the cache before
 *		    re-booting the system, or turning it off if /wc:on is selected.
 *		    You should also be careful to disable the cache (/d), or do
 *		    /wc:off before running any program under development which
 *		    has a chance of crashing due to bugs.
 *
 *		  NOTE: When /wc:off is selected, write info CAN get into
 *		    the cache (when the write is to a track which is currently
 *		    in the cache). The difference is that this "dirty" information
 *		    is IMMEDIATELY written out to the disk instead of being
 *		    held in the cache in the "dirty" state. When the write is
 *		    to a track that is not in the cache, it will be passed
 *		    through to the disk without being cached.
 *
 *	  /t:nnnnn - Set the auto flush interval. INT13 listens on the system
 *		  timer to note the passage of time and "age" the dirty
 *		  information in the cache. Every nnnnn ticks, the cache is
 *		  flushed. The timer ticks 18.2 times a second.
 *
 *		   nnnnn   |
 *		  ===========================================
 *		      18   |	 Flush every second
 *		    1092   |	 Flush every minute
 *		    5460   |	 Flush every 5 minutes
 *		   10920   |	 Flush every 10 minutes
 *		   21840   |	 Flush every 20 minutes
 *		   32760   |	 Flush every 30 minutes
 *		   65520   |	 Flush every hour
 *
 *		  The default setting of nnnnn is 1092 or every minute.
 *		  NOTE: There is no way to "disable" this tick aging. Setting
 *			nnnnn = 0 causes a wait for 65536 ticks which is a
 *			little over an hour. The max value for nnnnn is 65535.
 *			Disabling the cache (/d), or turning write caching
 *			off (/wc:off) effectively prevents the aging from
 *			doing anything as there is never anything to flush
 *			in these cases. Setting very low values of nnnnn
 *			should be avoided as it places a lot of overhead into
 *			the timer interrupt service. Rather than set low values,
 *			it is better to just turn off write caching (/wc:off).
 *		  NOTE: As stated above, the max value for nnnnn is 65535. It
 *			should be noted however that FLUSH13 DOES NOT object if
 *			you specify a number larger than this! It will simply
 *			use only the low 16 bits of the number.
 *
 *	  /r:on off - En/Disable reboot flush.
 *		  INT13 has a provision for detecting Ctrl-Alt-Del user
 *		  reboots. /r:on enables a flush of the cache at this time
 *		  to prevent the disks from being corrupted. The default
 *		  setting is /r:off. NOTE WARNING DANGER!!!!! Enabling
 *		  this feature can prevent disks from being damaged BUT
 *		  the mechanism has flaws. For one, you will have to hit
 *		  Ctrl-Alt-Del a second time to get the system to reboot.
 *		  YOU MUST NOT POUND ON THE KEY. You will crash the system if
 *		  you do. Hit the key ONCE, if the system re-boots, fine. If
 *		  there is info to flush out of the cache, the drive light
 *		  will come on and the system will probably NOT reboot. WAIT
 *		  until the drive light is OFF before hitting Ctrl-Alt-Del
 *		  again. This feature of INT13 MAY NOT WORK with other
 *		  software in the system. USER BEWARE!!!!!!!!!!!!!!!!!!!
 *
 *	  /c:on off - En/Disable all cache on reads.
 *		  Normally INT13 does not cache EVERY I/O. Whenever
 *		  it sees a full track I/O which is not currently in
 *		  the cache, it DOES NOT cache that track. This is
 *		  an optimization for "typical" operation, and actually
 *		  increases performance. This is the default setting
 *		  (/c:off). There may be some cases where it is desirable
 *		  that ALL reads be cached. One example is that you are
 *		  "loading" the cache prior to locking it with FLUSH13 /l.
 *		  With /c:off, some pieces of what you're trying to load
 *		  may not get into the cache. Another example is that
 *		  you continually access in a sequential manner (like
 *		  program load) some large file which happens to be
 *		  contiguous on the disk. Again, there may be some "piece"
 *		  of the file which does not get into the cache with
 *		  /c:off. /c:on enables the caching of ALL reads.
 *		  NOTE: The same "don't bother caching operations which
 *			are full track and not in the cache" applies
 *			to writes as well. /c has NO EFFECT on this
 *			behavior however. /c only effects read operations.
 *
 * MODIFICATION HISTORY
 *
 *	 1.10	 5/26/86 ARR First version in assembler
 *	 1.20	 5/27/86 ARR Lock cache function added.
 *	 1.22	 5/30/86 ARR /r reboot flush code added
 *	 1.23	 6/03/86 ARR Cache statistics added
 *	 1.24	 6/05/86 ARR Added /a "all cache" code
 *	 1.25	 6/10/86 ARR Added total used, total locked to status
 *			     RECODED in 'C'.
 *			     /f switch added.
 *	 1.26	 6/12/86 ARR /wb changed to /wc. Some status report wording
 *			     changed. This was to align the behavior with the
 *			     documentation a little better.
 *	 1.27	 1/22/87 ARR Change to format of status information.
 */

#include <stdio.h>

/*
 * Messages in flmes.asm
 */
extern char NO_DEV_MESS[], IOCTL_BAD_MESS[], STATUS_MES2[], SWTCH_CONF[];
extern char BAD_PARM[], STATUS_MES1[], DISSTRING[], ENSTRING[];
extern char LOCKSTRING[], UNLSTRING[], REBOOT_MES[];
extern char STATUS_3R[], STATUS_3W[], STATUS_3T[];
extern char CACHE_MES[], WT_MES[], WB_MES[], L_MES[], C_MES[], T_MES[];
extern char STATUS_4[], ONSTRING[], OFFSTRING[], STATUS_5[];

/*
 * Structure of the data returned by the status call to INT13
 */
typedef struct {
	unsigned char write_through;
	unsigned char write_buff;
	unsigned char enable_13;
	unsigned char nuldev;
	unsigned int  ticksetting;
	unsigned char lock_cache;
	unsigned char reboot_flush;
	unsigned char all_cache;
	unsigned char pad;
	unsigned long total_writes;
	unsigned long write_hits;
	unsigned long total_reads;
	unsigned long read_hits;
	unsigned int  ttracks;
	unsigned int  total_used;
	unsigned int  total_locked;
	unsigned int  total_dirty;
	unsigned int  current_size;
	unsigned int  initial_size;
	unsigned int  minimum_size;
} status;

/*
 * Assembler routines in fl13.asm
 */
extern int	IOCTLOpen(char *);
extern int	IOCTLWrite(int,char *,int);
extern int	IOCTLRead(int,status *,int);
extern int	IOCTLClose(int);

/*
 *  GetNum - Read an unsigned 16 bit decimal number
 *
 *	ENTRY: cptr points to string where decimal number is
 *	       iptr points to unsigned int where number goes
 *
 *	NOTES: Calls Fatal (which doesn't return) if no number is present.
 *	       No error if number is > 16 bits, only low 16 bits are returned.
 *
 *	EXIT:  returns cptr advanced past number
 *	       iptr contains number found
 *
 */
char *GetNum(cptr,iptr)
unsigned char *cptr;
unsigned int  *iptr;
{
    *iptr = 0;
    if((*cptr < '0') || (*cptr > '9'))
	Fatal(BAD_PARM);
    while((*cptr >= '0') && (*cptr <= '9'))
	*iptr = (*iptr * 10) + ((unsigned int) (*cptr++ - '0'));
    return(cptr);
}

/*
 *  GetOnOff - Check for :on or :off string
 *
 *	ENTRY: cptr points to string where :on or :off is supposed to be
 *	       iptr points to unsigned int which is a boolean
 *
 *	NOTES: Calls Fatal (which doesn't return) if :on or :off is not found.
 *	       Case insensitive.
 *
 *	EXIT:  returns cptr advanced past :on or :off
 *	       iptr contains 1 if :on was found
 *	       iptr contains 0 if :off was found
 *
 */
char *GetOnOff(cptr,iptr)
char *cptr;
int  *iptr;
{
    if(*cptr++ != ':')
	Fatal(BAD_PARM);
    *cptr |= 0x20;
    if(*cptr++ != 'o')
	Fatal(BAD_PARM);
    *cptr |= 0x20;
    if(*cptr == 'n') {
	cptr++;
	*iptr = 1;
    }
    else if(*cptr == 'f'){
	cptr++;
	*cptr |= 0x20;
	if(*cptr++ != 'f')
	    Fatal(BAD_PARM);
	*iptr = 0;
    }
    else
	Fatal(BAD_PARM);
    return(cptr);
}


/*
 *  Flush13
 *
 *	ENTRY: Std
 *
 *	NOTES:
 *
 *	EXIT: exit(0) if OK, exit(-1) if error.
 *
 */
main(argc, argv, envp)
int argc;
char **argv;
char **envp;

{

    int handle,boolval;
    char *cptr;
    unsigned long total_hits,total_ops;
    unsigned int minutes,seconds;
    struct {
	unsigned    SWITCH_S : 1;
	unsigned    SWITCH_I : 1;
	unsigned    SWITCH_D : 1;
	unsigned    SWITCH_E : 1;
	unsigned    SWITCH_L : 1;
	unsigned    SWITCH_U : 1;
	unsigned    SWITCH_T : 1;
	unsigned    SWITCH_WCON : 1;
	unsigned    SWITCH_WCOFF : 1;
	unsigned    SWITCH_WTON : 1;
	unsigned    SWITCH_WTOFF : 1;
	unsigned    SWITCH_ROFF : 1;
	unsigned    SWITCH_RON : 1;
	unsigned    SWITCH_SX : 1;
	unsigned    SWITCH_SR : 1;
	unsigned    SWITCH_CON : 1;
	unsigned    SWITCH_COFF : 1;
	unsigned    SWITCH_F : 1;
    } switches;
    struct {
	unsigned char Tchar;
	unsigned char tickvall; 	/* this is actually an unsigned int */
	unsigned char tickvalh; 	/* but we have to declare it this way */
    } tickpacket;			/* so that the compiler doesn't word align */
    status config;

    /* Check for no arguments case and process if found */

    handle = -1;
    if (argc == 1) {		    /* no arguments */
	    if((handle = IOCTLOpen("SMARTAAR")) == -1)
		Fatal(NO_DEV_MESS);
	    if(IOCTLWrite(handle,"\x00",1) == -1)
		Fatal(IOCTL_BAD_MESS);
	    IOCTLClose(handle);
	    exit(0);
    }

    /* Initialize data associated with the argument parse */

    switches.SWITCH_S = switches.SWITCH_I = switches.SWITCH_D = 0;
    switches.SWITCH_E = switches.SWITCH_L = switches.SWITCH_U = 0;
    switches.SWITCH_T = switches.SWITCH_WCON = switches.SWITCH_WCOFF = 0;
    switches.SWITCH_WTON = switches.SWITCH_WTOFF = switches.SWITCH_ROFF = 0;
    switches.SWITCH_RON = switches.SWITCH_SX = switches.SWITCH_SR = 0;
    switches.SWITCH_CON = switches.SWITCH_COFF = switches.SWITCH_F = 0;

    /* Parse the arguments */

    ++argv;			/* Skip argv[0] */
    while(--argc) {		/* While arguments */
	cptr = *argv;
	if(*cptr++ != '/')	/* all arguments are switches */
	    Fatal(BAD_PARM);
	if(*cptr == '\0')	/* trailing / error? */
	    Fatal(BAD_PARM);
	*cptr |= 0x20;		/* lower case */
	switch (*cptr++) {

	    /* Status */
	    case 's':
			if(switches.SWITCH_S || switches.SWITCH_SX || switches.SWITCH_SR)
			    Fatal(SWTCH_CONF);
			if(*cptr == '\0')
			    switches.SWITCH_S = 1;
			else {
			    *cptr |= 0x20;
			    if(*cptr == 'r')
				switches.SWITCH_SR = 1;
			    else if(*cptr == 'x')
				switches.SWITCH_SX = 1;
			    else
				Fatal(BAD_PARM);
			    cptr++;
			}
			break;

	    /* c on or off */
	    case 'c':
			if(switches.SWITCH_CON || switches.SWITCH_COFF)
			    Fatal(SWTCH_CONF);
			cptr = GetOnOff(cptr,&boolval);
			if(boolval)
			    switches.SWITCH_CON = 1;
			else
			    switches.SWITCH_COFF = 1;
			break;

	    /* t set tick value */
	    case 't':
			if(switches.SWITCH_T)
			    Fatal(SWTCH_CONF);
			if(*cptr++ != ':')
			    Fatal(BAD_PARM);
			cptr = GetNum(cptr,&tickpacket.tickvall);
			tickpacket.Tchar = '\x0B';	 /* set tick is call 5 */
			switches.SWITCH_T = 1;
			break;

	    /* wt or wb on or off */
	    case 'w':
			*cptr |= 0x20;
			if(*cptr == 'c') {
			    cptr++;
			    if(switches.SWITCH_WCOFF || switches.SWITCH_WCON)
				Fatal(SWTCH_CONF);
			    cptr = GetOnOff(cptr,&boolval);
			    if(boolval)
				switches.SWITCH_WCON = 1;
			    else
				switches.SWITCH_WCOFF = 1;
			}
			else if(*cptr == 't') {
			    cptr++;
			    if(switches.SWITCH_WTOFF || switches.SWITCH_WTON)
				Fatal(SWTCH_CONF);
			    cptr = GetOnOff(cptr,&boolval);
			    if(boolval)
				switches.SWITCH_WTON = 1;
			    else
				switches.SWITCH_WTOFF = 1;
			}
			else
			    Fatal(BAD_PARM);
			break;

	    /* d disable */
	    case 'd':
			if(switches.SWITCH_D || switches.SWITCH_E)
			    Fatal(SWTCH_CONF);
			switches.SWITCH_D = 1;
			break;

	    /* e enable */
	    case 'e':
			if(switches.SWITCH_D || switches.SWITCH_E)
			    Fatal(SWTCH_CONF);
			switches.SWITCH_E = 1;
			break;

	    /* l lock */
	    case 'l':
			if(switches.SWITCH_L || switches.SWITCH_U)
			    Fatal(SWTCH_CONF);
			switches.SWITCH_L = 1;
			break;

	    /* u unlock */
	    case 'u':
			if(switches.SWITCH_L || switches.SWITCH_U)
			    Fatal(SWTCH_CONF);
			switches.SWITCH_U = 1;
			break;

	    /* i invalidate */
	    case 'i':
			if(switches.SWITCH_I)
			    Fatal(SWTCH_CONF);
			switches.SWITCH_I = 1;
			break;

	    /* f flush */
	    case 'f':
			if(switches.SWITCH_F)
			    Fatal(SWTCH_CONF);
			switches.SWITCH_F = 1;
			break;

	    /* r on or off */
	    case 'r':
			if(switches.SWITCH_RON || switches.SWITCH_ROFF)
			    Fatal(SWTCH_CONF);
			cptr = GetOnOff(cptr,&boolval);
			if(boolval)
			    switches.SWITCH_RON = 1;
			else
			    switches.SWITCH_ROFF = 1;
			break;

	    default:
			Fatal(BAD_PARM);

	}
	if(*cptr != '\0')		/* must be at end of argument */
	    Fatal(BAD_PARM);
	++argv; 			/* next argument */
    }

    /* Open the device */

    if((handle = IOCTLOpen("SMARTAAR")) == -1) 
	Fatal(NO_DEV_MESS);

    /* Perform the actions indicated by the arguments */

    if(switches.SWITCH_I) {
	if(IOCTLWrite(handle,"\x01",1) == -1)
	    FatalC(handle,IOCTL_BAD_MESS);
    }

    if(switches.SWITCH_F) {
	if(IOCTLWrite(handle,"\x00",1) == -1)
	    FatalC(handle,IOCTL_BAD_MESS);
    }

    if(switches.SWITCH_WTON) {
	if(IOCTLWrite(handle,"\x04\x01",2) == -1)
	    FatalC(handle,IOCTL_BAD_MESS);
    }
    else if(switches.SWITCH_WTOFF) {
	if(IOCTLWrite(handle,"\x04\x00",2) == -1)
	    FatalC(handle,IOCTL_BAD_MESS);
    }

    if(switches.SWITCH_WCON) {
	if(IOCTLWrite(handle,"\x04\x03",2) == -1)
	    FatalC(handle,IOCTL_BAD_MESS);
    }
    else if(switches.SWITCH_WCOFF) {
	if(IOCTLWrite(handle,"\x04\x02",2) == -1)
	    FatalC(handle,IOCTL_BAD_MESS);
    }

    if(switches.SWITCH_L) {
	if(IOCTLWrite(handle,"\x06",1) == -1)
	    FatalC(handle,IOCTL_BAD_MESS);
    }
    else if(switches.SWITCH_U) {
	if(IOCTLWrite(handle,"\x07",1) == -1)
	    FatalC(handle,IOCTL_BAD_MESS);
    }

    if(switches.SWITCH_T) {
	if(IOCTLWrite(handle,&tickpacket.Tchar,3) == -1)
	    FatalC(handle,IOCTL_BAD_MESS);
    }

    if(switches.SWITCH_RON) {
	if(IOCTLWrite(handle,"\x08\x01",2) == -1)
	    FatalC(handle,IOCTL_BAD_MESS);
    }
    else if(switches.SWITCH_ROFF) {
	if(IOCTLWrite(handle,"\x08\x00",2) == -1)
	    FatalC(handle,IOCTL_BAD_MESS);
    }

    if(switches.SWITCH_CON) {
	if(IOCTLWrite(handle,"\x0A\x01",2) == -1)
	    FatalC(handle,IOCTL_BAD_MESS);
    }
    else if(switches.SWITCH_COFF) {
	if(IOCTLWrite(handle,"\x0A\x00",2) == -1)
	    FatalC(handle,IOCTL_BAD_MESS);
    }

    if(switches.SWITCH_E) {
	if(IOCTLWrite(handle,"\x03",1) == -1)
	    FatalC(handle,IOCTL_BAD_MESS);
    }
    else if(switches.SWITCH_D) {
	if(IOCTLWrite(handle,"\x02",1) == -1)
	    FatalC(handle,IOCTL_BAD_MESS);
    }

    if(switches.SWITCH_S || switches.SWITCH_SR || switches.SWITCH_SX) {
	if(IOCTLRead(handle,&config,sizeof(config)) == -1)
	    FatalC(handle,IOCTL_BAD_MESS);
	if(config.nuldev != 0)
	    printf(STATUS_MES1);
	else {
	    printf(STATUS_MES2);
	    if(config.enable_13 != 0)
		printf(CACHE_MES,ENSTRING);
	    else
		printf(CACHE_MES,DISSTRING);
	    if(config.lock_cache != 0)
		printf(L_MES,LOCKSTRING);
	    else
		printf(L_MES,UNLSTRING);

	    if(config.write_buff != 0)
		printf(WB_MES,ONSTRING);
	    else
		printf(WB_MES,OFFSTRING);
	    if(config.reboot_flush != 0)
		printf(REBOOT_MES,ONSTRING);
	    else
		printf(REBOOT_MES,OFFSTRING);

	    if(config.all_cache != 0)
		printf(C_MES,ONSTRING);
	    else
		printf(C_MES,OFFSTRING);
	    if(config.write_through != 0)
		printf(WT_MES,ONSTRING);
	    else
		printf(WT_MES,OFFSTRING);

	    if(config.ticksetting == 0) {
		minutes = 60;
		seconds = 1;
	    }
	    else {
		seconds = ((unsigned long)config.ticksetting * 10) / 182;
		minutes = seconds / 60;
		seconds = seconds % 60;
	    }
	    printf(T_MES,minutes,seconds,config.ticksetting);

	    if(switches.SWITCH_SR) {
		if(IOCTLWrite(handle,"\x09",1) == -1)
		    FatalC(handle,IOCTL_BAD_MESS);
	      /* get the status again so that the extended status has the reset */
		if(IOCTLRead(handle,&config,sizeof(config)) == -1)
		    FatalC(handle,IOCTL_BAD_MESS);
	    }
	    if(switches.SWITCH_SX || switches.SWITCH_SR) {
		if(config.total_writes == 0)
		    printf(STATUS_3W,config.write_hits,config.total_writes,(unsigned int) 0);
		else
		    printf(STATUS_3W,config.write_hits,config.total_writes,(unsigned int)(config.write_hits*100/config.total_writes));
		if(config.total_reads == 0)
		    printf(STATUS_3R,config.read_hits,config.total_reads,(unsigned int) 0);
		else
		    printf(STATUS_3R,config.read_hits,config.total_reads,(unsigned int)(config.read_hits*100/config.total_reads));
		total_ops = config.total_reads + config.total_writes;
		total_hits = config.read_hits + config.write_hits;
		if(total_ops == 0)
		    printf(STATUS_3T,total_hits,total_ops,(unsigned int) 0);
		else
		    printf(STATUS_3T,total_hits,total_ops,(unsigned int)(total_hits*100/total_ops));
		printf(STATUS_4,config.ttracks,config.total_used,config.total_locked,config.total_dirty);
		printf(STATUS_5,config.current_size,config.initial_size,config.minimum_size);
	    }
	}
    }

    /* Close the device, and done */

    IOCTLClose(handle);
    exit(0);
}

/*
 *  Fatal -- Fatal (to flush13) error
 *
 *	ENTRY: p is pointer to error message to print
 *
 *	NOTES:
 *
 *	EXIT: exit(-1)
 *
 */
Fatal(p)
char *p;
{
	fprintf(stderr,"\n%s\n",p);
	exit(-1);
}

/*
 *  FatalC -- Fatal (to flush13) error, and close open handle
 *
 *	ENTRY: p is pointer to error message to print
 *	       hand is handle number of open device channel to close
 *
 *	NOTES:
 *
 *	EXIT: To Fatal
 *
 */
FatalC(hand,p)
int hand;
char *p;
{
	IOCTLClose(hand);
	Fatal(p);
}
