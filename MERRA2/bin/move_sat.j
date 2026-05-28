#!/usr/bin/csh

set echo
set nonomatch
set Date  = $1
set SYNOP = $2
set ExpID = $3


set YYYY = `echo $YEAR_TABLE | cut -c 1-4`


set WORK_DIR   = /discover/nobackup/projects/gmao/merra2/data/obs/.WORK/raw_obs_wjd
#set OBS_DIR     = /home/dao_ops/$ExpID/run/.../archive/obs
set OBS_DIR     = /discover/nobackup/projects/gmao/merra2/data/obs_dmf/GEOSadas-5_12_4/$ExpID/obs/

#set INSTRUMENT_TABLE = "airs_aqua"
#set INSTRUMENT_TABLE = `cat  $RC_DIR/instrument.list`
#set YEAR_TABLE = ( 201802 )

echo " ------ START TIME ------  " $Date
           date
echo " ---------------------------"
set YYYY = `echo $Date | cut -c 1-4`
set   MM = `echo $Date | cut -c 5-6`
mkdir -p $WORK_DIR/$INSTRUMENT_TABLE/$Date

ls -1 $OBS_DIR/Y${YYYY}/M${MM}/D*/H${SYNOP}/*${INSTRUMENT}*${Hour}z*ods
set ods_Files = `ls -1 $OBS_DIR/Y$YYYY/M$MM/D*/H${SYNOP}/*${INSTRUMENT}*`
# d5124_m2_jan10.diag_airs_aqua.20180101_00z.ods
echo $ods_Files

foreach FILE ( $ods_Files )
  echo $FILE
  #dmget $FILE 
  #wait
  rsync -av $FILE $WORK_DIR/$INSTRUMENT/$Date
end
