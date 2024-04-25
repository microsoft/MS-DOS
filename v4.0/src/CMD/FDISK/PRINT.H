
  clear_screen(0,0,24,39);
  printf("boot_ind=%d\n", part_table[temp][cur_disk].boot_ind);
    printf("start head=%d\n", part_table[temp][cur_disk].start_head);
      printf("start sec=%d\n", part_table[temp][cur_disk].start_sector);
      printf("start cyl=%d\n", part_table[temp][cur_disk].start_cyl);
	printf("sys id=%d\n", part_table[temp][cur_disk].sys_id);
	printf("end head=%d\n", part_table[temp][cur_disk].end_head);
		printf("end sec=%d\n", part_table[temp][cur_disk].end_sector);
	printf("end cyl=%d\n", part_table[temp][cur_disk].end_cyl);
	  printf("rel sec=%d\n", part_table[temp][cur_disk].rel_sec);
	     printf("num sec=%d\n", part_table[temp][cur_disk].num_sec);

		 wait_for_esc();
