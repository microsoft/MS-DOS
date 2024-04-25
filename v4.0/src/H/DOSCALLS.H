/*static char *SCCSID = "@(#)doscalls.hwc	10.3 87/05/27";*/
struct DateTime {
	unsigned char hour;
	unsigned char minutes;
	unsigned char seconds;
	unsigned char hundredths;
	unsigned char day;
	unsigned char month;
	unsigned year;
	int timezone;
	unsigned char day_of_week;
	};
struct FileFindBuf {
	unsigned create_date;
	unsigned create_time;
	unsigned access_date;
	unsigned access_time;
	unsigned write_date;
	unsigned write_time;
	unsigned long file_size;
	unsigned long falloc_size;
	unsigned attributes;
	unsigned char string_len;
	char file_name[13];
	};
struct FileStatus {
	unsigned create_date;
	unsigned create_time;
	unsigned access_date;
	unsigned access_time;
	unsigned write_date;
	unsigned write_time;
	unsigned long file_size;
	unsigned long falloc_size;
	unsigned attributes;
	};
struct FSAllocate {
	unsigned long filsys_id;
	unsigned long sec_per_unit;
	unsigned long num_units;
	unsigned long avail_units;
	unsigned bytes_sec;
	};
struct ProcIDsArea {
	unsigned procid_cpid;
	unsigned procid_ctid;
	unsigned procid_ppid;
	};
struct	ResultCodes {
	unsigned TermCode_PID ;
	unsigned ExitCode ;
	};
struct countrycode {
	unsigned country;
	unsigned codepage;
};
extern unsigned far pascal DOSCREATETHREAD (
	void (far *)(void),
	unsigned far *,
	unsigned char far * );
extern unsigned far pascal DOSRESUMETHREAD (
	unsigned );
extern unsigned far pascal DOSSUSPENDTHREAD (
	unsigned );
extern unsigned far pascal DOSCWAIT (
	unsigned,
	unsigned,
	struct ResultCodes far *,
	unsigned far *,
	unsigned );
extern void far pascal DOSENTERCRITSEC (void);
extern unsigned far pascal DOSEXECPGM (
	char far *,
	unsigned,
	unsigned,
	char far *,
	char far *,
	struct ResultCodes far *,
	char far * );
extern void far pascal DOSEXIT (
	unsigned,
	unsigned );
extern void far pascal DOSEXITCRITSEC (void);
extern unsigned far pascal DOSEXITLIST (
	unsigned,
	void (far *)(void) );
extern unsigned far pascal DOSGETPID (
	struct ProcIDsArea far *);
extern unsigned far pascal DOSGETPRTY (
	unsigned,
	unsigned far *,
	unsigned );
extern unsigned far pascal DOSSETPRTY (
	unsigned,
	unsigned,
	unsigned,
	unsigned );
extern unsigned far pascal DOSKILLPROCESS (
	unsigned,
	unsigned );
extern unsigned far pascal DOSHOLDSIGNAL (
	unsigned );
extern unsigned far pascal DOSFLAGPROCESS (
	unsigned,
	unsigned,
	unsigned,
	unsigned );
extern unsigned far pascal DOSSETSIGHANDLER (
	void (far pascal *)(),
	unsigned long far *,
	unsigned far *,
	unsigned,
	unsigned );
extern unsigned far pascal DOSSENDSIGNAL (
	unsigned,
	unsigned);
extern unsigned far pascal DOSMAKEPIPE (
	unsigned far *,
	unsigned far *,
	unsigned );
extern unsigned far pascal DOSCLOSEQUEUE (
	unsigned ) ;
extern unsigned far pascal DOSCREATEQUEUE (
	unsigned far *,
	unsigned,
	char far * ) ;
extern unsigned far pascal DOSOPENQUEUE (
	unsigned far *,
	unsigned far *,
	char far * ) ;
extern unsigned far pascal DOSPEEKQUEUE (
	unsigned,
	unsigned long far *,
	unsigned far *,
	unsigned long far *,
	unsigned far *,
	unsigned char,
	unsigned char far *,
	unsigned long ) ;
extern unsigned far pascal DOSPURGEQUEUE (
	unsigned ) ;
extern unsigned far pascal DOSQUERYQUEUE (
	unsigned,
	unsigned far * );
extern unsigned far pascal DOSREADQUEUE (
	unsigned,
	unsigned long far *,
	unsigned far *,
	unsigned long far *,
	unsigned,
	unsigned char,
	unsigned char far *,
	unsigned long ) ;
extern unsigned far pascal DOSWRITEQUEUE (
	unsigned,
	unsigned,
	unsigned,
	unsigned char far *,
	unsigned char );
extern unsigned far pascal DOSSEMCLEAR (
	unsigned long );
extern unsigned far pascal DOSSEMREQUEST (
	unsigned long,
	long );
extern unsigned far pascal DOSSEMSET (
	unsigned long );
extern unsigned far pascal DOSSEMSETWAIT (
	unsigned long,
	long );
extern unsigned far pascal DOSSEMWAIT (
	unsigned long,
	long );
extern unsigned far pascal DOSMUXSEMWAIT (
	unsigned far *,
	unsigned far *,
	long );
extern unsigned far pascal DOSCLOSESEM (
	unsigned long );
extern unsigned far pascal DOSCREATESEM (
	unsigned,
	unsigned long far *,
	char far * );
extern unsigned far pascal DOSOPENSEM (
	unsigned long far *,
	char far * );
extern unsigned far pascal DOSGETDATETIME (
	struct DateTime far * );
extern unsigned far pascal DOSSETDATETIME (
	struct DateTime far * );
extern unsigned far pascal DOSSLEEP (
	unsigned long );
extern unsigned far pascal DOSGETTIMERINT (
	unsigned far * );
extern unsigned far pascal DOSTIMERASYNC (
	unsigned long,
	unsigned long,
	unsigned far * );
extern unsigned far pascal DOSTIMERSTART (
	unsigned long,
	unsigned long,
	unsigned far * );
extern unsigned far pascal DOSTIMERSTOP (
	unsigned );
extern unsigned far pascal DOSALLOCSEG (
	unsigned,
	unsigned far *,
	unsigned );
extern unsigned far pascal DOSALLOCSHRSEG (
	unsigned,
	char far *,
	unsigned far * );
extern unsigned far pascal DOSGETSHRSEG (
	char far *,
	unsigned far * );
extern unsigned far pascal DOSGIVESEG (
	unsigned,
	unsigned,
	unsigned far * );
extern unsigned far pascal DOSGETSEG (
	unsigned );
extern unsigned far pascal DOSLOCKSEG (
	unsigned );
extern unsigned far pascal DOSUNLOCKSEG (
	unsigned );
extern unsigned far pascal DOSMEMAVAIL (
	unsigned long far * );
extern unsigned far pascal DOSREALLOCSEG (
	unsigned,
	unsigned );
extern unsigned far pascal DOSFREESEG (
	unsigned );
extern unsigned far pascal DOSALLOCHUGE (
	unsigned,
	unsigned,
	unsigned far *,
	unsigned,
	unsigned );
extern unsigned far pascal DOSGETHUGESHIFT (
	unsigned far *);
extern unsigned far pascal DOSREALLOCHUGE (
	unsigned,
	unsigned,
	unsigned );
extern unsigned far pascal DOSCREATECSALIAS (
	unsigned,
	unsigned far * );
extern unsigned far pascal DOSSUBALLOC (
	unsigned,
	unsigned far *,
	unsigned );
extern unsigned far pascal DOSSUBFREE (
	unsigned,
	unsigned,
	unsigned );
extern unsigned far pascal DOSSUBSET (
	unsigned,
	unsigned,
	unsigned );
extern unsigned far pascal DOSLOADMODULE (
	char far *,
	unsigned,
	char far *,
	unsigned far * );
extern unsigned far pascal DOSFREEMODULE (
	unsigned );
extern unsigned far pascal DOSGETPROCADDR (
	unsigned,
	char far *,
	unsigned long far * );
extern unsigned far pascal DOSGETMODHANDLE (
	char far *,
	unsigned far *);
extern unsigned far pascal DOSGETMODNAME (
	unsigned,
	unsigned,
	char far * );
extern unsigned far pascal DOSBEEP (
	unsigned,
	unsigned );
extern unsigned far pascal DOSCLIACCESS (void);
extern unsigned far pascal DOSDEVCONFIG (
	unsigned char far *,
	unsigned,
	unsigned );
extern unsigned far pascal DOSDEVIOCTL (
	char far *,
	char far *,
	unsigned,
	unsigned,
	unsigned );
extern unsigned far pascal DOSIOACCESS (
	unsigned,
	unsigned,
	unsigned,
	unsigned );
extern unsigned far pascal DOSPORTACCESS (
	unsigned,
	unsigned,
	unsigned,
	unsigned );
extern unsigned far pascal DOSSGNUM (
	unsigned far *);
extern unsigned far pascal DOSSGSWITCH (
	unsigned );
extern unsigned far pascal DOSSGSWITCHME (
	unsigned );
extern unsigned far pascal DOSMONOPEN (
	char far *,
	unsigned far * );
extern unsigned far pascal DOSMONCLOSE (
	unsigned );
extern unsigned far pascal DOSMONREG (
	unsigned,
	unsigned char far *,
	unsigned char far *,
	unsigned,
	unsigned );
extern unsigned far pascal DOSMONREAD (
	unsigned char far *,
	unsigned char,
	unsigned char far *,
	unsigned far * );
extern unsigned far pascal DOSMONWRITE (
	unsigned char far *,
	unsigned char far *,
	unsigned );
extern unsigned far pascal DOSBUFRESET (
	unsigned );
extern unsigned far pascal DOSCHDIR (
	char far *,
	unsigned long );
extern unsigned far pascal DOSCHGFILEPTR (
	unsigned,
	long,
	unsigned,
	unsigned long far * );
extern unsigned far pascal DOSCLOSE (
	unsigned );
extern unsigned far pascal DOSDELETE (
	char far *,
	unsigned long );
extern unsigned far pascal DOSDUPHANDLE (
	unsigned,
	unsigned far * );
extern unsigned far pascal DOSFINDCLOSE (
	unsigned );
extern unsigned far pascal DOSFINDFIRST (
	char far *,
	unsigned far *,
	unsigned,
	struct FileFindBuf far *,
	unsigned,
	unsigned far *,
	unsigned long );
extern unsigned far pascal DOSFINDNEXT (
	unsigned,
	struct FileFindBuf far *,
	unsigned,
	unsigned far * );
extern unsigned far pascal DOSFILELOCKS (
	unsigned,
	long far *,
	long far * );
extern unsigned far pascal DOSGETINFOSEG (
	unsigned far *,
	unsigned far * );
extern unsigned far pascal DOSMKDIR (
	char far *,
	unsigned long );
extern unsigned far pascal DOSMOVE (
	char far *,
	char far *,
	unsigned long );
extern unsigned far pascal DOSNEWSIZE (
	unsigned,
	unsigned long );
extern unsigned far pascal DOSOPEN (
	char far *,
	unsigned far *,
	unsigned far *,
	unsigned long,
	unsigned,
	unsigned,
	unsigned,
	unsigned long );
extern unsigned far pascal DOSQCURDIR (
	unsigned,
	char far *,
	unsigned far * );
extern unsigned far pascal DOSQCURDISK (
	unsigned far *,
	unsigned long far * );
extern unsigned far pascal DOSQFHANDSTATE (
	unsigned,
	unsigned far * );
extern unsigned far pascal DOSQFILEINFO (
	unsigned,
	unsigned,
	char far *,
	unsigned );
extern unsigned far pascal DOSQFILEMODE (
	char far *,
	unsigned far *,
	unsigned long );
extern unsigned far pascal DOSQFSINFO (
	unsigned,
	unsigned,
	char far *,
	unsigned );
extern unsigned far pascal DOSQHANDTYPE (
	unsigned,
	unsigned far *,
	unsigned far * );
extern unsigned far pascal DOSQVERIFY (
	unsigned far * );
extern unsigned far pascal DOSREAD (
	unsigned,
	char far *,
	unsigned,
	unsigned far * );
extern unsigned far pascal DOSREADASYNC (
	unsigned,
	unsigned long far *,
	unsigned far *,
	char far *,
	unsigned,
	unsigned far * );
extern unsigned far pascal DOSRMDIR (
	char far *,
	unsigned long );
extern unsigned far pascal DOSSELECTDISK (
	unsigned );
extern unsigned far pascal DOSSETFHANDSTATE (
	unsigned,
	unsigned);
extern unsigned far pascal DOSSETFSINFO (
	unsigned,
	unsigned,
	char far *,
	unsigned );
extern unsigned far pascal DOSSETFILEINFO (
	unsigned,
	unsigned,
	char far *,
	unsigned );
extern unsigned far pascal DOSSETFILEMODE (
	char far *,
	unsigned,
	unsigned long );
extern unsigned far pascal DOSSETMAXFH (
	unsigned );
extern unsigned far pascal DOSSETVERIFY (
	unsigned );
extern unsigned far pascal DOSWRITE (
	unsigned,
	char far *,
	unsigned,
	unsigned far * );
extern unsigned far pascal DOSWRITEASYNC (
	unsigned,
	unsigned long far *,
	unsigned far *,
	char far *,
	unsigned,
	unsigned far * );
extern unsigned far pascal DOSERROR (
	unsigned );
extern unsigned far pascal DOSSETVEC (
	unsigned,
	void (far *)(void),
	void (far * far *)(void) );
extern unsigned far pascal DOSGETMESSAGE (
	char far * far *,
	unsigned,
	char far *,
	unsigned,
	unsigned,
	char far *,
	unsigned far * );
extern unsigned far pascal DOSERRCLASS (
	unsigned,
	unsigned far *,
	unsigned far *,
	unsigned far * );
extern unsigned far pascal DOSINSMESSAGE (
	char far * far *,
	unsigned,
	char far *,
	unsigned,
	char far *,
	unsigned,
	unsigned far * );
extern unsigned far pascal DOSPUTMESSAGE (
	unsigned,
	unsigned,
	char far * );
extern unsigned far pascal DOSSYSTRACE (
	unsigned,
	unsigned,
	unsigned,
	char far * );
extern unsigned far pascal DOSGETENV (
	unsigned far *,
	unsigned far * );
extern unsigned far pascal DOSSCANENV (
     char far *,
     char far * far * );
extern unsigned far pascal DOSSEARCHPATH (
     unsigned,
     char far *,
     char far *,
     char far *,
     unsigned );
extern unsigned far pascal DOSGETVERSION (
	unsigned far * );
extern unsigned far pascal DOSGETMACHINEMODE (
	unsigned char far * );
extern unsigned far pascal DOSGETCTRYINFO (
	unsigned,
	struct countrycode far *,
	char far *,
	unsigned far * );
extern unsigned far pascal DOSGETDBCSEV (
	unsigned,
	struct countrycode far *,
	char far * );
extern unsigned far pascal DOSCASEMAP (
	unsigned,
	struct countrycode far *,
	char far * );
extern unsigned far pascal DOSGETCOLLATE (
	unsigned,
	struct countrycode far *,
	char far *,
	unsigned far *);
extern unsigned far pascal DOSGETCP (
	unsigned,
	unsigned far *,
	unsigned far *);
extern unsigned far pascal DOSSETCP (
	unsigned,
	unsigned);
extern unsigned far pascal DOSPHYSICALDISK (
	unsigned,
	char far *,
	unsigned,
	char far *,
	unsigned);
extern unsigned far pascal DOSSYSTEMSERVICE (
	unsigned,
	char far *,
	char far *);
