#!/bin/csh -f

#SBATCH --constraint=mil
#SBATCH --account=g2538
#SBATCH --partition=preops

set echo

limit stacksize unlimited
set RootDir = /discover/nobackup/dao_ops/TEST/M2_GRITAS/github_repo/M2_GRITAS/GrITAS
set RC_DIR      = ${RootDir}/src/Components/gritas/GIO
set BinDir  = ${RootDir}/Linux/bin
source $BinDir/g5_modules

csh -vx ${RC_DIR}/gritas2means.csh ${YEAR_TABLE} -r ${METRIC}
#csh -vx ${RC_DIR}/gritas2means.csh 201801 -r means
#csh -vx ${RC_DIR}/daoit_gritas2means.csh 201801 -r means

