#************************ makefile for dev\driver ************************

msg	=..\..\messages
dos	=..\..\dos
inc	=..\..\inc
hinc	=..\..\h

#
#######################	dependencies begin here. #########################
#

all: driver.sys

driver.ctl: driver.skl  $(msg)\$(COUNTRY).msg

driver.obj: driver.asm  $(inc)\msbds.inc $(inc)\versiona.inc \
            $(inc)\parse.asm $(inc)\psdata.inc \
            driver.ctl $(inc)\sysmsg.inc $(inc)\msgserv.asm

driver.sys: driver.obj driver.lnk
        link @driver.lnk
        exe2bin driver.exe driver.sys
        del driver.exe
