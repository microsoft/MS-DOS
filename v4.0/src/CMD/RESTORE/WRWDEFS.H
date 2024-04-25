

	/* built in 'c' functions */

	int	sprintf();
	int	printf();
	char	*strcat(char *,char *);
	int	strlen(char *);
	char	*strcpy(char *, char *);
	int	strncmp(char *,char *,unsigned int);
	int	strcmp(char *,char *);

	/* li functions */
	int	chdir(char *);
	int	mkdir(char *);

	void	search_src_disk_old(struct disk_info *,
				    struct file_info *,
				    struct disk_header_old *,
				    struct disk_header_new far *,
				    struct file_header_old *,
				    struct file_header_new far *,
				    unsigned char,
				    unsigned char,
				    unsigned long,
				    unsigned int *,
				    unsigned char *,
				    unsigned char *,
				    unsigned char *,
				    unsigned char *,
				    struct timedate *);

	void	search_src_disk_new(struct disk_info *,
				    struct file_info *,
				    struct disk_header_old *,
				    struct disk_header_new far *,
				    struct file_header_old *,
				    struct file_header_new far *,
				    unsigned char,
				    unsigned char,
				    unsigned int *,
				    unsigned long,
				    unsigned char *,
				    unsigned char *,
				    unsigned char *,
				    unsigned int *,
				    struct timedate *);


	int findfirst_new( struct file_info *,
			   unsigned int *,
			   unsigned int *,
			   unsigned char *,
			   unsigned char *,
			   unsigned int far**,
			   unsigned int far**,
			   unsigned int *,
			   unsigned char *);


	void restore_a_file(struct file_info *,
			   struct disk_info *,
			   unsigned long,
			   unsigned int *,
			   struct file_header_old *,
			   struct file_header_new far *,
			   struct disk_header_old *,
			   struct disk_header_new far *,
			   unsigned char,
			   unsigned char,
			   unsigned char *,
			   unsigned char *,
			   unsigned char *,
			   unsigned int *,
			   unsigned int *);

