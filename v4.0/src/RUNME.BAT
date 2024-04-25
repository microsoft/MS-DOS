echo off
cls
echo      **********************************************************************
echo      *                                                                    *
echo      *                      MS-DOS 4.00 Build Notes                       *
echo      *                                                                    *
echo      *     The following steps must be taken to ensure a proper and       *
echo      *     complete build of the MS-DOS 4.00 sources.                     *
echo      *                                                                    *
echo      *  1.) Build environment setup, the setenv.bat batch file provided   *
echo      *      will automate this process. This batch file must be modified  *
echo      *      to reflect the individual build environment, ie the drive     *
echo      *      volume and path.                                              *
echo      *                                                                    *
echo      *  2.) The nmake utility is used to build the MS-DOS 4.00 sources.   *
echo      *      the global build is started by invoking nmake at the top-     *
echo      *      most directory level. Individual modules are built by         *
echo      *      changing to the particular directory and running nmake.       *
echo      *      Useful Nmake switches:                                        *
echo      *                                                                    *
echo      *   NMAKE -I                            : Ignore build errors.       *
echo      *   NMAKE -I -X - Redirect to FILENAME  : Redirects stdout-stderr    *
echo      *                                                                    *
echo      *  3.) After the build is complete the cpy.bat batch file can be     *
echo      *      used to gather the binaries. The cpy.bat file will copy the   *
echo      *      binaries to the directory specified on the command line.      *
echo      *      For example:                                                  *
echo      *                                                                    *
echo      *      To use cpy.bat to copy the binaries to the bin directory on   *
echo      *      C: drive you would use the following command:                 *
echo      *                                                                    *
echo      *      cpy c:\bin                                                    *
echo      *                                                                    *
echo      *                                                                    *
echo      **********************************************************************
echo on


