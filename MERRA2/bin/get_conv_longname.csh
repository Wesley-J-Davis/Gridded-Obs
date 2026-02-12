#!/bin/csh
set RootDir = /gpfsm/dnb34/dao_ops/TEST/M2_GRITAS/github_repo/M2_GRITAS
set RC_DIR      = ${RootDir}/GrITAS/src/Components/gritas/GIO

set lkount = 1
set FIELD = $1
set TYPE = $2
set kount = `grep $FIELD ${RC_DIR}/${TYPE}_conv_product_table.csv | cut -d, -f2 | wc -l`

if ( $kount == 1 ) set LABEL =  `grep $FIELD ${RC_DIR}/${TYPE}_conv_product_table.csv | cut -d, -f2`
if ( $kount > 1 ) then
  set LABEL = `grep $FIELD ${RC_DIR}/${TYPE}_conv_product_table.csv | cut -d"=" -f2  | cut -d";" -f${kount}`           
endif
echo $LABEL
