PROGRAM prohst(input,output);
{$debug- $line- $symtab+}

{**********************************************************************}
{*                                                                    *}
{*                           prohst                                   *}
{*                                                                    *}
{* This program produces a histogram from the profile file produced   *}
{* by the MS-DOS profile utility. It optionally reads the map file    *}
{* generated when the program being profiled was linked, and writes   *}
{* either the module address or, if available, the line number as     *}
{* a prefix to the line of the graph which describes a particular     *}
{* bucket.                                                            *}
{*                                                                    *}
{* After using filbm (derived from the Pascal and Fortran front end   *}
{* command scanner) to parse its parameters, prohst opens the map     *}
{* file if specified, searches for the heading line, and then reads   *}
{* the lines giving the names and positions of the modules. It builds *}
{* a linked list of module names and start addresses.                 *}
{*                                                                    *}
{* It then reads the bucket file header and and bucket array elements *}
{* into a variable created on the heap. It simultaneously calculates  *}
{* a normalization factor. It writes the profile listing header and   *}
{* starts to write the profile lines. For each bucket, the address    *}
{* is calculated. The first entry in the address/name linked list     *}
{* is the lowest addressed module. This is initially the 'current'    *}
{* module. The bucket address is compared with the current module     *}
{* address. When it becomes the greater, the module name is written   *}
{* to the listing and the next entry in the address/name list becomes *}
{* the current module. If line numbers are available, the bucket      *}
{* address is also compared to the current line/address. This is      *}
{* read and calculated directly from the file. Since there may be     *}
{* more than one line per bucket, several entries may be read until   *}
{* the addresses compare within the span of addresses encompassed by  *}
{* a bucket (its 'width'). Note that the idiosyncracies of Pascal i/o *}
{* make it necessary to continually check for the end of the map file *}
{* and the complexity of this code is mainly due to an attempt to     *}
{* make it reasonably resilient to changes in the format of the map   *}
{* file.                                                              *}
{*                                                                    *}
{**********************************************************************}


CONST
  max_file = 32;


TYPE
  filenam = LSTRING (max_file);
  sets = SET OF 0..31;
  address_pointer = ^address_record;
  address_record = RECORD
                     next: address_pointer;
                     name: STRING (15);
                     address: WORD;
                   END;

        



VAR

  i: INTEGER;
  bucket: FILE OF WORD;
  hist: TEXT;
  map: TEXT;

  first_address,
  this_address: address_pointer; 
  current_base: WORD;
  bucket_name,
  hist_name,
  map_name: filenam;

  switches: sets;

  line: LSTRING (100);

  map_avail: BOOLEAN;
  line_nos_avail: BOOLEAN;

  norm: REAL;
  per_cent: INTEGER;
  real_bucket,
  norm_bucket: REAL;
  cum_per_cent,
  real_per_cent: REAL;

  bucket_num,
  clock_grain,
  bucket_size,
  prog_low_pa,
  prog_high_pa,
  dos_pa,
  hit_io,
  hit_dos,
  hit_high: WORD;

  seg,
  offset,
  parcel: WORD;

  address: WORD;
  new_line_no,
  line_no: WORD;

  dummy : LSTRING (8);
  name: LSTRING (20);
  line_no_part: LSTRING (17);
  start: LSTRING (6);

  buckets: ^SUPER ARRAY [1 .. *] OF REAL;

  this_bucket: WORD;

LABEL 1;


PROCEDURE filbm (VAR prffil, hstfil, mapfil: filenam;
                      VAR switches: sets); EXTERN;

FUNCTION realword (w: WORD): REAL;
BEGIN
  IF ORD (w) < 0 THEN BEGIN
    realword := FLOAT (maxint) + FLOAT (ORD (w - maxint));
    END
  ELSE BEGIN
    realword := FLOAT (ORD(w));
  END {IF};
END {realword};



PROCEDURE skip_spaces;
BEGIN
  WHILE NOT eof(map) AND THEN map^ = ' ' DO BEGIN
    get (map);
  END {WHILE};
END {skip_spaces};


FUNCTION hex_char (ch: CHAR): WORD;
BEGIN
  IF ch >= '0' AND THEN ch <= '9' THEN BEGIN
    hex_char := WRD (ch) - WRD ('0');
    END
  ELSE IF ch >= 'A' AND THEN ch <= 'F' THEN BEGIN
    hex_char := WRD (ch) - WRD ('A') + 10;
    END
  ELSE BEGIN
    WRITELN ('Invalid hex character');
    hex_char := 0;
  END {IF};
END {hex_char};


FUNCTION read_hex (i :WORD): WORD;
VAR
  hex_val: WORD;
BEGIN
  skip_spaces;
  hex_val := 0;
  WHILE NOT eof (map) AND THEN i <> 0 DO BEGIN
    hex_val := hex_val * 16 + hex_char (map^);
    GET (map);
    i := i - 1;
  END {WHILE};
    read_hex := hex_val;
END {read_hex};

FUNCTION read_h: WORD;
BEGIN
  read_h := read_hex (4);
  get (map);
  get (map);
END;

FUNCTION read_word: WORD;
VAR 
  int_value: WORD;
BEGIN
  int_value := 0;
  IF NOT EOF (map) THEN BEGIN
    READ (map, int_value);
  END {IF};
  read_word := int_value;
END {read_word};


FUNCTION map_digit: BOOLEAN;
BEGIN
  map_digit := (map^ >= '0') OR (map^ <= '9');
END {map_digit};

BEGIN {prohst}
  writeln (output, '    Profile Histogram Utility - Version 1.0');
  writeln (output);
  writeln (output, '         Copyright - Microsoft, 1983');
         
  start := '      ';

  filbm (bucket_name, hist_name, map_name, switches);

  IF 31 IN switches THEN BEGIN
    ABORT ('Map file must not be terminal', 0, 0);
  END {IF};

  IF NOT (28 IN switches) THEN BEGIN
    ABORT ('No histogram file specified', 0, 0);
  END {IF};

  ASSIGN (bucket, bucket_name);
  reset (bucket);
  ASSIGN (hist, hist_name);
  rewrite (hist);
  
  map_avail := 29 IN switches;
  line_nos_avail := FALSE;

  IF map_avail THEN BEGIN
    ASSIGN (map, map_name);
    RESET (map);
  
    WHILE NOT EOF (map) AND THEN start <> ' Start' DO BEGIN
      READLN (map, start);
    END {WHILE};
    
    NEW (first_address);
    this_address := NIL;

    WHILE NOT EOF(map) DO BEGIN
      READLN (map, line);
      IF line.len < 6 OR ELSE line [2] < '0' OR ELSE
          line [2] > '9' THEN BEGIN
        BREAK;
      END {IF};

      IF this_address <> NIL THEN BEGIN
        NEW (this_address^.next);
        this_address := this_address^.next;
        END
      ELSE BEGIN
        this_address := first_address;
      END {IF};
      this_address^.next := NIL;

      this_address^.address := (hex_char (line [2]) * 4096) + 
                               (hex_char (line [3]) * 256) +   
                               (hex_char (line [4]) * 16) + 
                               hex_char (line [5]);

      FOR i := 1 TO 15 DO BEGIN
        this_address^.name [i] := line [22 + i];
      END {FOR};

    END {WHILE};

    WHILE NOT EOF (map) DO BEGIN
      READLN (map, line_no_part);
      IF line_no_part = 'Line numbers for ' THEN BEGIN
        line_nos_avail := TRUE;
        BREAK;
      END {IF};
    END {WHILE};
    
  END {IF};

  read (bucket, clock_grain, bucket_num, bucket_size,
    prog_low_pa, prog_high_pa, dos_pa, hit_io, hit_dos, hit_high);

  NEW (buckets,ORD (bucket_num));

  norm := 0.0;
  norm_bucket := 0.0;

  FOR i := 1 TO ORD (bucket_num) DO BEGIN
    read (bucket, this_bucket);
    real_bucket := realword (this_bucket);

    IF real_bucket > norm_bucket THEN BEGIN
      norm_bucket := real_bucket;
    END {IF};

    norm := norm + real_bucket;
    buckets^[i] := real_bucket;
  END {FOR};
  norm_bucket := 45.0/norm_bucket;
  norm := 100.0/norm;

  WRITELN (hist, 'Microsoft Profiler Output Listing');
  
  WRITELN (hist);
  WRITELN (hist, ORD (bucket_num):6, bucket_size:4,'-byte buckets.');

  WRITELN (hist);
  WRITELN (hist, 'Profile taken between ', prog_low_pa*16::16,
    ' and ', prog_high_pa*16::16, '.');

  WRITELN (hist);
  WRITELN (hist, 'DOS program address:', dos_pa::16);

  WRITELN (hist);
  WRITELN (hist, 'Number of hits in DOS: ', hit_dos:5, 
            ' or ', realword (hit_dos) * norm:4:1, '%.');
  WRITELN (hist, 'Number of hits in I/O: ', hit_io:5,
            ' or ', realword (hit_io) * norm:4:1, '%.');
  WRITELN (hist, 'Number of hits high  : ', hit_high:5,
            ' or ', realword (hit_high) * norm:4:1, '%.');
  WRITELN (hist);
  WRITELN (hist, ' Hits  Addr.  Line/ Cumul.  % 0.0               ',
                              '                         ',
                              1.0/norm:1:1);

  WRITELN (hist, '              Offset           +----------------',
                              '----------------------------');
  WRITELN (hist, name);
  i := 0;
  parcel := 0;
  current_base := 0;
  line_no := 0;
  new_line_no := 0;
  cum_per_cent := 0.0;

  WHILE i < ORD (bucket_num) DO BEGIN
    i := i + 1;
    IF buckets^[i] < 0.9 THEN BEGIN
      WRITELN (hist);
      REPEAT
        i := i + 1;
      UNTIL (i = ORD (bucket_num)) OR ELSE buckets^[i] > 0.0;
    END {IF};

    address := bucket_size * (WRD (i) - 1);
    
    WHILE map_avail AND THEN
        address >= first_address^.address DO BEGIN
      WRITELN (hist, '      ', first_address^.name);
      current_base := first_address^.address;
      first_address := first_address^.next;
    END {WHILE};

    WHILE line_nos_avail AND THEN NOT eof (map) AND THEN
                                       address >= parcel DO BEGIN
      skip_spaces;
      WHILE  (map^ < '0') OR (map^ > '9') DO BEGIN
      
        IF EOF (map) THEN BEGIN
          goto 1;
        END {IF};
        READLN (map);
        skip_spaces;
      END {WHILE};


      line_no := new_line_no;
      new_line_no := read_word;
      seg := read_hex (4);
      IF EOF (map) THEN BEGIN
        GOTO 1;
      END {IF};
      IF map^ <> ':' THEN BEGIN
        WRITELN ('Invalid map file');
      END {IF};
      get (map);
      IF EOF (map) THEN BEGIN
        GOTO 1;
      END {IF};
      offset := read_hex (3) + WRD (hex_char (map^) > 0);
      get (map);
      IF map^ <> 'H' THEN BEGIN
        WRITELN ('Invalid map file');
      END {IF};
      IF EOF (map) THEN BEGIN
        GOTO 1;
      END {IF};
      get (map);
      parcel := seg + offset;
    END {WHILE};
1:  real_per_cent := buckets^[i] * norm;
    cum_per_cent := cum_per_cent + real_per_cent;
    per_cent := ROUND ( buckets^[i] * norm_bucket);

    WRITE (hist, buckets^ [i]:6:0, ' ',
               address*16:6:16);
    IF line_no <> 0 THEN BEGIN 
      WRITE (hist, line_no:6);
      line_no := 0;
      END
    ELSE IF map_avail AND THEN first_address <> NIL THEN BEGIN
      WRITE (hist, ' #', address - first_address^.address:4:16);
      END
    ELSE BEGIN
      WRITE (hist, '      ');
    END {IF};
    
    WRITELN (hist, ' ', cum_per_cent:5:1, ' ', real_per_cent:4:1, ' |',
               '*': per_cent);
  END {WHILE};
  WRITELN (hist, '                               +-----------------',
                              '------------------');
END.
                                      