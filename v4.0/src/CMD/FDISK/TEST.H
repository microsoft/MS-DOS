test()

BEGIN

int	i;
int	x;

	       for (i=0;i<24;i++)
		  BEGIN
		   for (x=0;x <2; x++)
		      BEGIN
	       ext_part_entry[i][x].boot_ind = 0;
	       ext_part_entry[i][x].start_head = 0;
	       ext_part_entry[i][x].start_sector = 0;
	       ext_part_entry[i][x].start_cyl = 0;
	       ext_part_entry[i][x].sys_id = 0;
	       ext_part_entry[i][x].end_head = 0;
	       ext_part_entry[i][x].end_sector = 0;
	       ext_part_entry[i][x].end_cyl = 0;
	       ext_part_entry[i][x].rel_sec = 0;
	       ext_part_entry[i][x].num_sec = 0;
		      END
		  END
	       return;
END
