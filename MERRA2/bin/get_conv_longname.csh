#!/bin/csh
set RC_DIR      = /home/dao_ops/operations/GIT-OPS/Gridded-Obs/MERRA2/etc

set lkount = 1
set FIELD = $1
set TYPE = $2
set kount = `grep $FIELD ${RC_DIR}/${TYPE}_conv_product_table.csv | cut -d, -f2 | wc -l`

if ( $kount == 1 ) set LABEL =  `grep $FIELD ${RC_DIR}/${TYPE}_conv_product_table.csv | cut -d, -f2`
if ( $kount > 1 ) then
  set LABEL = `grep $FIELD ${RC_DIR}/${TYPE}_conv_product_table.csv | cut -d"=" -f2  | cut -d";" -f${kount}`           
endif
echo $LABEL
