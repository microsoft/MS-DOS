/* ttypes.h - type definitions for tools library */

#include <stdio.h>

/* assembly routines */
flagType int25 (char, char far *, unsigned int, unsigned int);
flagType int26 (char, char far *, unsigned int, unsigned int);
flagType kbhit ();
char getch ();
void Move (char far *, char far *, unsigned int);
void Fill (char far *, char, unsigned int);
char *strbscan (char *, char *);
char *strbskip (char *, char *);
flagType strpre (char *, char *);
int strcmpi (unsigned char *, unsigned char *);
char *fcopy (char *, char *);
long getlpos ();
void getlinit ( char far *, int, int);
int getl (char *, int);

/* c routines */
/*global*/  char  *lower(char  *);
/*global*/  char  *upper(char  *);
/*global*/  char  *error(void);
/*global*/  long fexpunge(char  *,FILE *);
/*global*/  char  *fcopy(char  *,char  *);
/*global*/  int fgetl(char  *,int ,FILE  *);
/*global*/  int fputl(char  *,int ,FILE  *);
/*global*/  int ffirst(char  *,int ,struct findType  *);
/*global*/  int fnext(struct findType  *);
/*global*/  char forsemi(char  *,char ( *)(), );
/*global*/  long freespac(int );
/*global*/  long sizeround(long ,int );
/*global*/  int rspawnl(char  *,char  *,char  *, );
/*global*/  int rspawnv(char  *,char  *,char  *,char  *[0]);
/*global*/  char  *MakeStr(char  *);
/*global*/  int mapenv(char  *,char  *);
/*global*/  char  *ismark(char  *);
/*global*/  FILE  *swopen(char  *,char  *);
/*global*/  int swclose(FILE  *);
/*global*/  int swread(char  *,int ,FILE  *);
/*global*/  char  *swfind(char  *,FILE *,char  *);
/*global*/  char *getenvini(char  *,char  *);
/*global*/  char fPathChr(int );
/*global*/  char fSwitChr(int );
/*global*/  char fPFind(char  *,unsigned int * *);
/*global*/  char findpath(char  *,char  *,char );
/*global*/  FILE  *pathopen(char  *,char  *,char  *);
/*global*/  int forfile(char  *,int ,void ( *)(), );
/*global*/  int rootpath(char  *,char  *);
/*global*/  int sti(char  *,int );
/*global*/  int ntoi(char  *,int );
/*global*/  int strcmps(unsigned char  *,unsigned char  *);
/*global*/  int strcmpis(unsigned char  *,unsigned char  *);
/*global*/  char  *strend(char  *);
/*global*/  int upd(char  *,char  *,char  *);
/*global*/  int drive(char  *,char  *);
/*global*/  int extention(char  *,char  *);
/*global*/  int filename(char  *,char  *);
/*global*/  int filenamx(char  *,char  *);
/*global*/  int path(char  *,char  *);
/*global*/  int curdir(char  *,char );
/*global*/  int getattr(char  *);
/*global*/  int fdelete(char  *);
/*global*/  char *fmove(char  *, char *);
/*global*/  char *fappend(char  *, int);
/*global*/  long ctime2l(char *);
/*global*/  struct tm *ctime2tm(char *);
/*global*/  long date2l(int, int, int, int, int, int);
/*global*/  struct vectorType *VectorAlloc(int);
/*global*/  flagType fAppendVector(struct vectorType**, unsigned int);
