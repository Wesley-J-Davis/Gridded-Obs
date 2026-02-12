#!/bin/csh

  set ESMADIR = /discover/nobackup/rgovinda/git_motel/SLES12/v10.23.0/GEOSgcm
  set ESMADIR = /home/dao_ops/GEOSadas-5_29_5/GEOSadas
  source $ESMADIR/install/bin/g5_modules

  set FILE = $1
  /gpfsm/dnb34/dao_ops/TEST/M2_GRITAS/github_repo/M2_GRITAS/GrITAS/src/Components/gritas/GIO/n4zip.csh $FILE
