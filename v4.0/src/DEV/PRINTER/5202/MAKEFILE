#********************** Makefile for Printer\5202.CPI **********************

inc	=..\..\..\inc
dos	=..\..\..\dos
hinc	=..\..\..\h
msg	=..\..\..\message

#
######################### Dependencies Begin Here ##########################
#

all: 5202.cpi

5202.obj:  5202.asm  $(inc)\copyrigh.inc makefile


5202.cpi:  5202.obj
          link 5202;
          exe2bin 5202 5202.cpi
          del 5202.exe

