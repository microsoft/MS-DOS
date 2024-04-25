/*************************************************************/
/* DISPLAY.C ROUTINES                                        */
/*************************************************************/
void     display(char far *);
void     number_in_msg(XFLOAT,unsigned);
void     percent_in_msg(unsigned,unsigned);                             /* AN000 */
void     string_in_msg(char far *,unsigned);                            /* AN000 */
void     volume_in_msg(char far *,unsigned);                            /* AN000 */

/*************************************************************/
/* VIDEO.C ROUTINES                                          */
/*************************************************************/
void     clear_screen(unsigned,unsigned,unsigned,unsigned);
void     init_video_information(void);
void     reset_video_information(void);
void     get_video_attribute(void);                                     /* AN006 */


/*************************************************************/
/* DISKOUT.C ROUTINES                                        */
/*************************************************************/
void     write_info_to_disk(void);
char     write_master_boot_to_disk(unsigned char);
char     write_ext_boot_to_disk(char,unsigned char);


/*************************************************************/
/* PARTINFO.C ROUTINES                                       */
/*************************************************************/
char     find_free_partition(void);
char     find_partition_type(unsigned char);
XFLOAT   get_partition_size(unsigned char);
char     find_active_partition(void);
char     find_partition_location(unsigned char);
char     find_free_ext(void);
char     find_logical_drive(void);
char     get_num_logical_dos_drives(void);
char     find_ext_drive(char);
char     find_previous_drive(char);

/*************************************************************/
/* MAKEPART.C ROUTINES                                       */
/*************************************************************/
void     make_partition(unsigned,char,unsigned char,char);
char     make_volume(unsigned,char);

/*************************************************************/
/* INPUT.C ROUTINES                                          */
/*************************************************************/
char     get_num_input(char,char,unsigned,unsigned);
char     get_yn_input(char,unsigned,unsigned);
char     wait_for_ESC(void);
unsigned get_large_num_input(unsigned,unsigned,unsigned,char far *,unsigned,char far *);
char     get_alpha_input(char,char,unsigned,unsigned,char,char);
char     get_char_input(void);
void     get_string_input(unsigned,unsigned,char far *);


/*************************************************************/
/* SPACE.C ROUTINES                                          */
/*************************************************************/
char     find_part_free_space(char);
void     sort_part_table(char);
char     find_ext_free_space(void);
void     sort_ext_table(char);


/*************************************************************/
/* INT13.C ROUTINES                                          */
/*************************************************************/
char     get_disk_info(void);
char     read_boot_record(unsigned,unsigned char,unsigned char,unsigned char);         /* AC000 */
char     write_boot_record(unsigned,unsigned char);
unsigned verify_tracks(char,char);
char     get_drive_parameters(unsigned char);
void     DiskIo(union REGS *,union REGS *, struct SREGS *);

/*************************************************************/
/* VDISPLAY.C ROUTINES                                       */
/*************************************************************/
char     volume_display(void);

/*************************************************************/
/* TDISPLAY.C ROUTINES                                       */
/*************************************************************/
char     table_display(void);
char     table_drive_letter(void);

/*************************************************************/
/* FDISK.C ROUTINES                                          */
/*************************************************************/
void     main(int,char * []);
void     load_logical_drive(char,unsigned char);
void     init_partition_tables(void);
char     check_valid_environment(void);
void     reboot_system(void);
void     display_volume_information(void);
void     display_partition_information(void);
void     volume_delete(void);
void     ext_delete(void);
void     delete_partition(void);
void     dos_delete(void);
void     change_active_partition(void);
void     volume_create(void);
void     ext_create_partition(void);
void     input_dos_create(void);
void     dos_create_partition(void);
void     create_partition(void);
void     do_main_menu(void);
void     internal_program_error(void);
void     reboot(void);

/*************************************************************/
/* CONVERT ROUTINES                                          */
/*************************************************************/
void     get_volume_string(char,char *);                                /* AN000 */
unsigned mbytes_to_cylinders(XFLOAT,char);                              /* AN004 */
XFLOAT   percent_to_cylinders(unsigned,XFLOAT);                         /* AN000 */
XFLOAT   cylinders_to_mbytes(unsigned,char);                            /* AN004 */
unsigned cylinders_to_percent(unsigned,unsigned);                       /* AN000 */
char     dos_upper(char);                                               /* AN000 */
char     check_yn_input(char);                                          /* AN000 */
FLAG     get_fs_and_vol(char);                                          /* AN000 */
FLAG     check_format(char);                                            /* AN002 */

/*************************************************************/
/* PARSE ROUTINES                                            */
/*************************************************************/
char     parse_command_line(int,char * []);                             /* AN000 */
void     parse_init(void);                                              /* AN000 */
void     check_disk_validity(void);                                     /* AN000 */
void     process_switch(void);                                          /* AN000 */
void     parse(union REGS *, union REGS *);                             /* AN000 */
void     Parse_msg(int,int,unsigned char);                              /* AN010 */


/*************************************************************/
/* MESSAGES ROUTINES                                         */
/*************************************************************/
char     preload_messages(void);                                        /* AN000 */
void     display_msg(int,int,int,int *,char,char);                      /* AN000 AC014 */
void     sysloadmsg(union REGS *, union REGS *);                        /* AN000 */
void     sysdispmsg(union REGS *, union REGS *);                        /* AN000 */
void     sysgetmsg(union REGS *, struct SREGS *, union REGS *);         /* AN012 */
char     get_yes_no_values(void);                                       /* AN012 */


/*************************************************************/
/* C ROUTINES                                                */
/*************************************************************/

int      getch(void);
void     putch(int);

int      int86x(int, union REGS *, union REGS *, struct SREGS *);
int      int86(int, union REGS *, union REGS *);
int      intdos(union REGS *, union REGS *);

