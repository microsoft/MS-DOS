/*SCCSID = @(#)subcalls.hwc	10.1 87/05/02*/
struct CursorData {
	unsigned cur_start;
	unsigned cur_end;
	unsigned cur_width;
	unsigned cur_attribute;
	};
struct KbdStatus {
	unsigned length;
	unsigned bit_mask;
	unsigned turn_around_char;
	unsigned interim_char_flags;
	unsigned shift_state;
	};
struct KbdTRANS {
	unsigned char char_code;
	unsigned char scan_code;
	unsigned char status;
	unsigned char nls_shift;
	unsigned shift_state;
	unsigned long time;
	unsigned kbdDDflags;
	unsigned xlt_flags;
	unsigned xlt_shift_state;
	unsigned xlt_rsrv_0;
	};
struct KeyData {
	unsigned char char_code;
	unsigned char scan_code;
	unsigned char status;
	unsigned char nls_shift;
	unsigned shift_state;
	unsigned long time;
	};
struct ModeData {
	unsigned length;
	unsigned char type;
	unsigned char color;
	unsigned col;
	unsigned row;
	unsigned hres;
	unsigned vres;
	};
struct PVBData {
	unsigned pvb_size;
	unsigned long pvb_ptr;
	unsigned pvb_length;
	unsigned pvb_rows;
	unsigned pvb_cols;
	unsigned char pvb_type;
	};
struct PhysBufData {
	unsigned long buf_start;
	unsigned long buf_length;
	unsigned      selectors[2];
	};
struct ConfigData {
	unsigned length ;
	unsigned adapter_type;
	unsigned display_type;
	unsigned long memory_size;
	};
struct VIOFONT {
	unsigned length;
	unsigned req_type;
	unsigned pel_cols;
	unsigned pel_rows;
	unsigned long font_data;
	unsigned font_len;
	};
struct VIOSTATE {
	unsigned length;
	unsigned req_type;
	unsigned double_defined;
	unsigned palette0;
	unsigned palette1;
	unsigned palette2;
	unsigned palette3;
	unsigned palette4;
	unsigned palette5;
	unsigned palette6;
	unsigned palette7;
	unsigned palette8;
	unsigned palette9;
	unsigned palette10;
	unsigned palette11;
	unsigned palette12;
	unsigned palette13;
	unsigned palette14;
	unsigned palette15;
	};
struct EventInfo {
	unsigned Mask;
	unsigned long Time;
	unsigned Row;
	unsigned Col;
	};
struct NoPointer {
	unsigned Row;
	unsigned Col;
	unsigned Height;
	unsigned Width;
	};
struct PtrImage {
	unsigned TotLength;
	unsigned Col;
	unsigned Row;
	unsigned ColOffset;
	unsigned RowOffset;
	};
struct PtrLoc {
	unsigned RowPos;
	unsigned ColPos;
	};
struct QueInfo {
	unsigned Events;
	unsigned QSize;
	};
struct ScaleFact {
	unsigned RowScale;
	unsigned ColScale;
	};
struct StartData {
	unsigned Length;
	unsigned Related;
	unsigned FgBg;
	unsigned TraceOpt;
	char far * PgmTitle;
	char far * PgmName;
	char far * PgmInputs;
	char far * TermQ;
	};
struct StatusData {
	unsigned Length;
	unsigned SelectInd;
	unsigned BindInd;
	};
struct KbdStringInLength
   {
    unsigned int  Length;
    unsigned int  LengthB;
   };
extern unsigned far pascal KBDREGISTER (
	char far *,
	char far *,
	unsigned long);
extern unsigned far pascal KBDDEREGISTER (
	void );
extern unsigned far pascal KBDCHARIN (
	struct KeyData far *,
	unsigned,
	unsigned );
extern unsigned far pascal KBDFLUSHBUFFER (
	unsigned );
extern unsigned far pascal KBDGETSTATUS (
	struct KbdStatus far *,
	unsigned );
extern unsigned far pascal KBDPEEK (
	struct KeyData far *,
	unsigned );
extern unsigned far pascal KBDSETSTATUS (
	struct KbdStatus far *,
	unsigned );
extern unsigned far pascal KBDSTRINGIN (
	char far *,
	struct KbdStringInLength far *,
	unsigned,
	unsigned );
extern unsigned far pascal KBDOPEN (
	unsigned far * );
extern unsigned far pascal KBDCLOSE (
	unsigned );
extern unsigned far pascal KBDGETFOCUS (
	unsigned,
	unsigned );
extern unsigned far pascal KBDFREEFOCUS (
	unsigned );
extern unsigned far pascal KBDGETCP (
	unsigned long,
	unsigned far *,
	unsigned );
extern unsigned far pascal KBDSETCP (
	unsigned,
	unsigned,
	unsigned );
extern unsigned far pascal KBDXLATE (
	struct KbdTRANS far *,
	unsigned );
extern unsigned far pascal KBDSETCUSTXT (
	unsigned far *,
	unsigned );
extern unsigned far pascal KBDSYNCH (
	unsigned );
extern unsigned far pascal VIOREGISTER (
	char far *,
	char far *,
	unsigned long,
	unsigned long );
extern unsigned far pascal VIODEREGISTER (
	void );
extern unsigned far pascal VIOGETBUF (
	unsigned long far *,
	unsigned far *,
	unsigned );
extern unsigned far pascal VIOGETCURPOS (
	unsigned far *,
	unsigned far *,
	unsigned );
extern unsigned far pascal VIOGETCURTYPE (
	struct CursorData far *,
	unsigned );
extern unsigned far pascal VIOGETMODE (
	struct ModeData far *,
	unsigned );
extern unsigned far pascal VIOGETPHYSBUF (
	struct PhysBufData far *,
	unsigned );
extern unsigned far pascal VIOREADCELLSTR (
	char far *,
	unsigned far *,
	unsigned,
	unsigned,
	unsigned );
extern unsigned far pascal VIOREADCHARSTR (
	char far *,
	unsigned far *,
	unsigned,
	unsigned,
	unsigned );
extern unsigned far pascal VIOSCROLLDN (
	unsigned,
	unsigned,
	unsigned,
	unsigned,
	unsigned,
	char far *,
	unsigned );
extern unsigned far pascal VIOSCROLLUP (
	unsigned,
	unsigned,
	unsigned,
	unsigned,
	unsigned,
	char far *,
	unsigned );
extern unsigned far pascal VIOSCROLLLF (
	unsigned,
	unsigned,
	unsigned,
	unsigned,
	unsigned,
	char far *,
	unsigned );
extern unsigned far pascal VIOSCROLLRT (
	unsigned,
	unsigned,
	unsigned,
	unsigned,
	unsigned,
	char far *,
	unsigned );
extern unsigned far pascal VIOSETCURPOS (
	unsigned,
	unsigned,
	unsigned );
extern unsigned far pascal VIOSETCURTYPE (
	struct CursorData far *,
	unsigned );
extern unsigned far pascal VIOSETMODE (
	struct ModeData far *,
	unsigned );
extern unsigned far pascal VIOSHOWBUF (
	unsigned,
	unsigned,
	unsigned );
extern unsigned far pascal VIOWRTCELLSTR (
	char far *,
	unsigned,
	unsigned,
	unsigned,
	unsigned );
extern unsigned far pascal VIOWRTCHARSTR (
	char far *,
	unsigned,
	unsigned,
	unsigned,
	unsigned );
extern unsigned far pascal VIOWRTCHARSTRATT (
	char far *,
	unsigned,
	unsigned,
	unsigned,
	char far *,
	unsigned );
extern unsigned far pascal VIOWRTNATTR (
	char far *,
	unsigned,
	unsigned,
	unsigned,
	unsigned );
extern unsigned far pascal VIOWRTNCELL (
	char far *,
	unsigned,
	unsigned,
	unsigned,
	unsigned );
extern unsigned far pascal VIOWRTNCHAR (
	char far *,
	unsigned,
	unsigned,
	unsigned,
	unsigned );
extern unsigned far pascal VIOWRTTTY (
	char far *,
	unsigned,
	unsigned );
extern unsigned far pascal VIOSETANSI (
	unsigned,
	unsigned );
extern unsigned far pascal VIOGETANSI (
	unsigned far *,
	unsigned );
extern unsigned far pascal VIOPRTSC (
	unsigned );
extern unsigned far pascal VIOPRTSCTOGGLE (
	unsigned );
extern unsigned far pascal VIOSAVREDRAWWAIT (
	unsigned,
	unsigned far *,
	unsigned );
extern unsigned far pascal VIOSAVREDRAWUNDO (
	unsigned,
	unsigned,
	unsigned );
extern unsigned far pascal VIOMODEWAIT (
	unsigned,
	unsigned far *,
	unsigned );
extern unsigned far pascal VIOMODEUNDO (
	unsigned,
	unsigned,
	unsigned );
extern unsigned far pascal VIOSCRLOCK (
	unsigned,
	unsigned char far *,
	unsigned );
extern unsigned far pascal VIOSCRUNLOCK (
	unsigned );
extern unsigned far pascal VIOPOPUP (
	unsigned far *,
	unsigned );
extern unsigned far pascal VIOENDPOPUP (
	unsigned );
extern unsigned far pascal VIOGETCONFIG (
	unsigned,
	struct ConfigData far *,
	unsigned );
extern unsigned far pascal VIOGETFONT (
	struct VIOFONT far *,
	unsigned );
extern unsigned far pascal VIOGETCP (
	unsigned,
	unsigned far *,
	unsigned );
extern unsigned far pascal VIOSETCP (
	unsigned,
	unsigned,
	unsigned );
extern unsigned far pascal VIOSETFONT (
	struct VIOFONT far *,
	unsigned );
extern unsigned far pascal VIOGETSTATE (
	struct VIOSTATE far *,
	unsigned );
extern unsigned far pascal VIOSETSTATE (
	struct VIOSTATE far *,
	unsigned );
extern unsigned far pascal MOUREGISTER (
	char far *,
	char far *,
	unsigned long );
extern unsigned far pascal MOUDEREGISTER (
	void );
extern unsigned far pascal MOUFLUSHQUE (
	unsigned );
extern unsigned far pascal MOUGETHOTKEY (
	unsigned far *,
	unsigned );
extern unsigned far pascal MOUSETHOTKEY (
	unsigned far *,
	unsigned );
extern unsigned far pascal MOUGETPTRPOS (
	struct PtrLoc far *,
	unsigned );
extern unsigned far pascal MOUSETPTRPOS (
	struct PtrLoc far *,
	unsigned );
extern unsigned far pascal MOUGETPTRSHAPE (
	unsigned char far *,
	struct PtrImage far *,
	unsigned );
extern unsigned far pascal MOUSETPTRSHAPE (
	unsigned char far *,
	struct PtrImage far *,
	unsigned );
extern unsigned far pascal MOUGETDEVSTATUS (
	unsigned far *,
	unsigned );
extern unsigned far pascal MOUGETNUMBUTTONS (
	unsigned far *,
	unsigned );
extern unsigned far pascal MOUGETNUMMICKEYS (
	unsigned far *,
	unsigned );
extern unsigned far pascal MOUREADEVENTQUE (
	struct EventInfo far *,
	unsigned far *,
	unsigned );
extern unsigned far pascal MOUGETNUMQUEEL (
	struct QueInfo far *,
	unsigned );
extern unsigned far pascal MOUGETEVENTMASK (
	unsigned far *,
	unsigned );
extern unsigned far pascal MOUSETEVENTMASK (
	unsigned far *,
	unsigned );
extern unsigned far pascal MOUGETSCALEFACT (
	struct ScaleFact far *,
	unsigned );
extern unsigned far pascal MOUSETSCALEFACT (
	struct ScaleFact far *,
	unsigned );
extern unsigned far pascal MOUOPEN (
	char far *,
	unsigned far * );
extern unsigned far pascal MOUCLOSE (
	unsigned );
extern unsigned far pascal MOUREMOVEPTR (
	struct NoPointer far *,
	unsigned );
extern unsigned far pascal MOUDRAWPTR (
	unsigned );
extern unsigned far pascal MOUSETDEVSTATUS (
	unsigned far *,
	unsigned );
extern unsigned far pascal MOUINITREAL (
	char far * );
extern unsigned far pascal DOSSTARTSESSION (
	struct StartData far *,
	unsigned far *,
	unsigned far * );
extern unsigned far pascal DOSSETSESSION (
	unsigned,
	struct StatusData far * );
extern unsigned far pascal DOSSELECTSESSION (
	unsigned,
	unsigned long );
extern unsigned far pascal DOSSTOPSESSION (
	unsigned,
	unsigned,
	unsigned long );
