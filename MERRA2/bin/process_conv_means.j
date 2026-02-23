#!/bin/csh -f

#SBATCH --constraint=mil
#SBATCH --account=g2538
#SBATCH --partition=preops

set echo
set YEAR_TABLE = $1
set METRIC     = $2
echo "$YEAR_TABLE $METRIC"
limit stacksize unlimited
set RootDir     = /home/dao_ops/operations/GIT-OPS/Gridded-Obs/MERRA2/bin
#set BinDir      = /discover/nobackup/dao_ops/TEST/M2_GRITAS/github_repo/M2_GRITAS/GrITAS/Linux/bin
#set BinDir      = $BIN_DIR
#source $BinDir/g5_modules

csh -vx ${RootDir}/gritas2means.csh ${YEAR_TABLE} -r ${METRIC}
#csh -vx ${RC_DIR}/gritas2means.csh 201801 -r means
#csh -vx ${RC_DIR}/daoit_gritas2means.csh 201801 -r means
