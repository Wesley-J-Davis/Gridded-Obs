#!/bin/csh
#set ESMADIR = /discover/nobackup/rgovinda/git_motel/SLES12/v10.23.0/GEOSgcm
#set ESMADIR = /home/dao_ops/GEOSadas-5_29_5/GEOSadas
#source $ESMADIR/install/bin/g5_modules
set FILE = $1
/home/dao_ops/operations/GIT-OPS/Gridded-Obs/MERRA2/bin/n4zip.csh $FILE
