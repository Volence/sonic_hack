#!/usr/bin/env winescript
@ECHO OFF

REM // make sure we can write to the file s4.bin
REM // also make a backup to s4.prev.bin
IF NOT EXIST s4.bin goto LABLNOCOPY
IF EXIST s4.prev.bin
 del s4.prev.bin
IF EXIST s4.prev.bin goto LABLNOCOPY
move /Y s4.bin s4.prev.bin
IF EXIST s4.bin goto LABLERROR3
REM IF EXIST s4.prev.bin copy /Y s4.prev.bin s4.bin
:LABLNOCOPY

REM // delete some intermediate assembler output just in case
IF EXIST s4.p del s4.p
IF EXIST s4.p goto LABLERROR2
IF EXIST s4.h del s4.h
IF EXIST s4.h goto LABLERROR1

REM // clear the output window
cls

REM // run the rings conversion program
cd level/rings
rings.exe
cd ../..

REM // run the assembler
REM // -xx shows the most detailed error output
REM // -c outputs a shared file (s4.h)
REM // -A gives us a small speedup
set AS_MSGPATH=win32/msg
set USEANSI=n

REM // allow the uer to choose to print error messages out by supplying the -pe parameter
IF "%1"=="-pe" ( "win32/asw" -xx -c -A S4.asm ) ELSE "win32/asw" -xx -c -E -A S4.asm

REM // if there were errors, a log file is produced
IF EXIST s4.log goto LABLERROR4

REM // combine the assembler output into a rom
IF EXIST s4.p "win32/s4p2bin" s4.p s4.bin s4.h

REM // fix some pointers and things that are impossible to fix from the assembler without un-splitting their data
IF EXIST s4.bin "win32/fixpointer" s4.h s4.bin   off_3A294 MapRUnc_Sonic $2D 0 4   word_728C_user Obj5F_MapUnc_7240 2 2 1  

REM REM // fix the rom header (checksum)
IF EXIST s4.bin "win32/fixheader" s4.bin


REM // done -- pause if we seem to have failed, then exit
IF NOT EXIST s4.p goto LABLPAUSE
IF EXIST s4.bin exit /b
:LABLPAUSE

REM pause


exit /b

:LABLERROR1
echo Failed to build because write access to s4.h was denied.
REM pause


exit /b

:LABLERROR2
echo Failed to build because write access to s4.p was denied.
REM pause


exit /b

:LABLERROR3
echo Failed to build because write access to s4.bin was denied.
REM pause

exit /b

:LABLERROR4
REM // display a noticeable message
echo.
echo **********************************************************************
echo *                                                                    *
echo *   There were build errors/warnings. See s4.log for more details.   *
echo *                                                                    *
echo **********************************************************************
echo.
REM pause


