#!/bin/csh  

#SBATCH --time=1:00:00
#SBATCH --constraint=cas
#SBATCH --account=g2538
#SBATCH --partition=preops

set echo

setenv TAG  merra2
#set BinDir  = /home/dao_ops/operations/M2_GRITAS/GrITAS/Linux/bin
#source $BinDir/g5_modules
module load nco

set STORAGE_DIR = /discover/nobackup/projects/gmao/merra2/data/obs/.WORK/products_revised
set RC_DIR      = /home/dao_ops/operations/GIT-OPS/Gridded-Obs/MERRA2/etc/
set HOST_DIR    = /discover/nobackup/projects/gmao/merra2/data/obs/.WORK/work_dir_wjd

set YEAR_TABLE = $1
#set SYNOP_TABLE = $2
#set HOST_DIR     = $2
#set STORAGE_DIR  = $3

set skip = 0
set TEMP_argv =  ( $argv )

set prod_date = `date -u "+%Y-%m-%dT%TZ"`
echo $prod_date

unset argv
setenv argv
set argv = ( $TEMP_argv )
# all 00 06 12 18
set SYNOP_TABLE = ( 00 06 12 18 all )
#set INSTRUMENT_TABLE = 'conv'
set METADATA_TABLE = ${RC_DIR}/metadata.tbl
set PRODUCT_TABLE  = ${RC_DIR}/M2_OPS_product_table.csv
set OBRATE_TABLE   = ${RC_DIR}/obrate_conv_product_table.csv

foreach INSTRUMENT ( `echo $INSTRUMENT_TABLE` )
  foreach YYYYMM ( `echo $YEAR_TABLE` )
    set YYYY = `echo $YYYYMM | cut -c1-4`
    set   MM = `echo $YYYYMM | cut -c5-6`
    set CurrentMonth_FirstDay  = ${YYYY}${MM}01
    set PreviousMonth_LastDay = `/home/dao_ops/bin/tick ${CurrentMonth_FirstDay} 000000 -1 0 | cut -d' ' -f1`
    set NextMonth             = `/home/dao_ops/bin/tick ${CurrentMonth_FirstDay} 000000 32 0 | cut -d' ' -f1 | cut -c1-6`
    set CurrentMonth_LastDay = `/home/dao_ops/bin/tick ${NextMonth}01 000000 -1 0 | cut -d' ' -f1`
    
    # Reformat dates
    set yyyy = `echo ${CurrentMonth_FirstDay} | cut -c1-4`
    set  mm  = `echo ${CurrentMonth_FirstDay} | cut -c5-6`
    set  dd  = `echo ${CurrentMonth_FirstDay} | cut -c7-8`
    set  CurrentMonth_FirstDay = "${yyyy}-${mm}-${dd}"
    
    set yyyy = `echo ${PreviousMonth_LastDay} | cut -c1-4`
    set   mm = `echo ${PreviousMonth_LastDay} | cut -c5-6`
    set   dd = `echo ${PreviousMonth_LastDay} | cut -c7-8`
    set PreviousMonth_LastDay = "${yyyy}-${mm}-${dd}"
    
    set yyyy = `echo ${CurrentMonth_LastDay} | cut -c1-4`
    set   mm = `echo ${CurrentMonth_LastDay} | cut -c5-6`
    set   dd = `echo ${CurrentMonth_LastDay} | cut -c7-8`
    set   CurrentMonth_LastDay = "${yyyy}-${mm}-${dd}"
    
    set YKOUNT = 0
    set IN_DIR  = $HOST_DIR/$INSTRUMENT/d/Y$YYYY/M$MM
    set c = 0
    if ( -d $IN_DIR ) then
      set c = `ls -la $IN_DIR/ | wc -l`
      if ($c != 2 ) then
        set OUT_DIR = $STORAGE_DIR/$INSTRUMENT/d/Y$YYYY/M$MM
        mkdir -p $OUT_DIR
        echo " ----------------------------"
        echo "      STARTING TIME          "
        echo "  SAT $INSTRUMENT $YYYY $MM  "
        date
        echo " ----------------------------"
        foreach HOUR ( `echo $SYNOP_TABLE` )
          if ( $HOUR == "all" ) then
            set SYNOP = "" 
          else
            set SYNOP = "_${HOUR}z"
          endif
          set kount = 0
          foreach MODE ( means obrate rms )
	    MONTHLY_PRE_COMBINED=merra2.mon_${MODE}_obs.${YYYY}${MM}${SYNOP}.nc4
	    MONTHLY_POST_COMBINED=$OUT_DIR/merra2.${INSTRUMENT}.${MODE}_obs.${YYYY}${MM}${SYNOP}.nc4

            set flag = 0
            set kount = 0
            #         echo " MODE: $MODE TIME: $HOUR"
            foreach FIELD ( `cat ${RC_DIR}/CONV_FIELD_TABLE` )
              if ( $MODE == "means" ) then
                set FIELDO =  $FIELD 
                set FIELDF = "${FIELD}_omf"
                set FIELDA = "${FIELD}_oma"
              else if ( $MODE == "obrate" ) then
                set FIELDO = "${FIELD}_${MODE}"
                set FIELDF = "${FIELD}_${MODE}_omf"
                set FIELDA = "${FIELD}_${MODE}_oma"
              else if ( $MODE == "rms" ) then
                set FIELDO = "${FIELD}_${MODE}"
                set FIELDF = "${FIELD}_${MODE}_omf"
                set FIELDA = "${FIELD}_${MODE}_oma"
              endif
              #           echo "flag: $flag"
              if ( $flag == 0 ) then
                if ( $MODE != "means" ) then
                  time ncrename -h -v ${FIELD},${FIELDO} $IN_DIR/merra2.mon_${MODE}_obs.${YYYY}${MM}${SYNOP}.nc4 -o $OUT_DIR/merra2.${INSTRUMENT}.${MODE}_obs.${YYYY}${MM}${SYNOP}.nc4
                  time ncatted -h -O -a comments,$FIELDO,o,c,"${MODE}"   $OUT_DIR/merra2.${INSTRUMENT}.${MODE}_obs.${YYYY}${MM}${SYNOP}.nc4
                else
                  echo $FIELDO
                  #time $NCKS -h $IN_DIR/merra2.mon_${MODE}_obs.${YYYY}${MM}${SYNOP}.nc4 $OUT_DIR/merra2.${INSTRUMENT}.${MODE}_obs.${YYYY}${MM}${SYNOP}.nc4
                  cp  $IN_DIR/merra2.mon_${MODE}_obs.${YYYY}${MM}${SYNOP}.nc4 $OUT_DIR/merra2.${INSTRUMENT}.${MODE}_obs.${YYYY}${MM}${SYNOP}.nc4
                  time ncatted -h -O -a comments,$FIELDO,o,c,"${MODE}"   $OUT_DIR/merra2.${INSTRUMENT}.${MODE}_obs.${YYYY}${MM}${SYNOP}.nc4
                endif
                if ( $MODE != "obrate" ) then
                  echo $FIELD $FIELDF $FIELDA
                  time ncrename -h -v ${FIELD},${FIELDF} $IN_DIR/merra2.mon_${MODE}_omf.${YYYY}${MM}${SYNOP}.nc4 -o $OUT_DIR/merra2.${INSTRUMENT}.${MODE}_omf.${YYYY}${MM}${SYNOP}.nc4
                  time ncrename -h -v ${FIELD},${FIELDA} $IN_DIR/merra2.mon_${MODE}_oma.${YYYY}${MM}${SYNOP}.nc4 -o $OUT_DIR/merra2.${INSTRUMENT}.${MODE}_oma.${YYYY}${MM}${SYNOP}.nc4
                  if ( $MODE == "rms" ) then
                    time ncatted -h -O -a comments,$FIELDF,o,c,"${MODE}_omf"   $OUT_DIR/merra2.${INSTRUMENT}.${MODE}_omf.${YYYY}${MM}${SYNOP}.nc4
                    time ncatted -h -O -a comments,$FIELDA,o,c,"${MODE}_oma"   $OUT_DIR/merra2.${INSTRUMENT}.${MODE}_oma.${YYYY}${MM}${SYNOP}.nc4
                  else
                    time ncatted -h -O -a comments,$FIELDF,o,c,"omf"   $OUT_DIR/merra2.${INSTRUMENT}.${MODE}_omf.${YYYY}${MM}${SYNOP}.nc4
                    time ncatted -h -O -a comments,$FIELDA,o,c,"oma"   $OUT_DIR/merra2.${INSTRUMENT}.${MODE}_oma.${YYYY}${MM}${SYNOP}.nc4
                  endif
                endif
              else
                if ( $MODE != "means" ) then
                  echo $FIELD $FIELDF $FIELDO
                  time ncrename -h -v ${FIELD},${FIELDO} $OUT_DIR/merra2.${INSTRUMENT}.${MODE}_obs.${YYYY}${MM}${SYNOP}.nc4
                  time ncatted -h -O -a comments,$FIELDO,o,c,"${MODE}"   $OUT_DIR/merra2.${INSTRUMENT}.${MODE}_obs.${YYYY}${MM}${SYNOP}.nc4
                else
                  time ncatted -h -O -a comments,$FIELDO,o,c,"obs"   $OUT_DIR/merra2.${INSTRUMENT}.${MODE}_obs.${YYYY}${MM}${SYNOP}.nc4
                endif
                if ( $MODE != "obrate" ) then
                  echo $FIELD $FIELDF $FIELDA
                  time ncrename -h -v ${FIELD},${FIELDF} $OUT_DIR/merra2.${INSTRUMENT}.${MODE}_omf.${YYYY}${MM}${SYNOP}.nc4
                  time ncrename -h -v ${FIELD},${FIELDA} $OUT_DIR/merra2.${INSTRUMENT}.${MODE}_oma.${YYYY}${MM}${SYNOP}.nc4
                  if ( $MODE == "rms" ) then
                    time ncatted -h -O -a comments,$FIELDF,o,c,"${MODE}_omf"   $OUT_DIR/merra2.${INSTRUMENT}.${MODE}_omf.${YYYY}${MM}${SYNOP}.nc4
                    time ncatted -h -O -a comments,$FIELDA,o,c,"${MODE}_oma"   $OUT_DIR/merra2.${INSTRUMENT}.${MODE}_oma.${YYYY}${MM}${SYNOP}.nc4
                  else
                    time ncatted -h -O -a comments,$FIELDF,o,c,"omf"   $OUT_DIR/merra2.${INSTRUMENT}.${MODE}_omf.${YYYY}${MM}${SYNOP}.nc4
                    time ncatted -h -O -a comments,$FIELDA,o,c,"oma"   $OUT_DIR/merra2.${INSTRUMENT}.${MODE}_oma.${YYYY}${MM}${SYNOP}.nc4
                  endif
                endif
              endif
              if ($MODE == "obrate" ) then
                set  LONGNAME = `/usr/bin/csh /home/dao_ops/operations/GIT-OPS/Gridded-Obs/MERRA2/bin/get_conv_longname.csh $FIELDO ${MODE}`
                echo $FIELDO  $LONGNAME
                time ncatted -h -O -a comments,$FIELDO,o,c,"${MODE}"   $OUT_DIR/merra2.${INSTRUMENT}.${MODE}_obs.${YYYY}${MM}${SYNOP}.nc4
                time ncatted -h -O -a long_name,$FIELDO,o,c,"$LONGNAME"   $OUT_DIR/merra2.${INSTRUMENT}.${MODE}_obs.${YYYY}${MM}${SYNOP}.nc4
              endif
              set flag = 1
              @ kount = $kount + 1
            end    #FIELD
            #echo "we are here"
            if ( $MODE != "obrate" ) then
              time ncrcat  -h -A $OUT_DIR/merra2.${INSTRUMENT}.${MODE}_obs.${YYYY}${MM}${SYNOP}.nc4   $OUT_DIR/merra2.${INSTRUMENT}.${YYYY}${MM}${SYNOP}.nc4
              time ncrcat  -h -A $OUT_DIR/merra2.${INSTRUMENT}.${MODE}_omf.${YYYY}${MM}${SYNOP}.nc4   $OUT_DIR/merra2.${INSTRUMENT}.${YYYY}${MM}${SYNOP}.nc4
              time ncrcat  -h -A $OUT_DIR/merra2.${INSTRUMENT}.${MODE}_oma.${YYYY}${MM}${SYNOP}.nc4   $OUT_DIR/merra2.${INSTRUMENT}.${YYYY}${MM}${SYNOP}.nc4
#              time ncatted -h -O -a _FillValue,,d,,       $OUT_DIR/merra2.${INSTRUMENT}.${YYYY}${MM}${SYNOP}.nc4
#              time ncatted -h -O -a fmissing_value,,d,,  $OUT_DIR/merra2.${INSTRUMENT}.${YYYY}${MM}${SYNOP}.nc4
              /bin/rm $OUT_DIR/merra2.${INSTRUMENT}.${MODE}_obs.${YYYY}${MM}${SYNOP}.nc4
              /bin/rm $OUT_DIR/merra2.${INSTRUMENT}.${MODE}_omf.${YYYY}${MM}${SYNOP}.nc4
              /bin/rm $OUT_DIR/merra2.${INSTRUMENT}.${MODE}_oma.${YYYY}${MM}${SYNOP}.nc4
            else
              time ncrcat  -h -A $OUT_DIR/merra2.${INSTRUMENT}.${MODE}_obs.${YYYY}${MM}${SYNOP}.nc4   $OUT_DIR/merra2.${INSTRUMENT}.${YYYY}${MM}${SYNOP}.nc4
              /bin/rm $OUT_DIR/merra2.${INSTRUMENT}.${MODE}_obs.${YYYY}${MM}${SYNOP}.nc4
            endif
          end    #MODE
          foreach FILE ( `/bin/ls -1 $OUT_DIR/*${SYNOP}.nc4` )
            foreach FIELD ( `cat ${RC_DIR}/CONV_FINAL_TABLE.csv` )       
              set LABEL = `grep $FIELD -w ${RC_DIR}/longname_conv_product_table.csv | cut -d, -f2`
              set UNITS = `grep $FIELD -w ${RC_DIR}/longname_conv_product_table.csv | cut -d, -f3`
              set min = `grep -w $FIELD  ${RC_DIR}/minmax_conv_product_table.csv | cut -d, -f2`
              set max = `grep -w $FIELD ${RC_DIR}/minmax_conv_product_table.csv | cut -d, -f3`
              ncatted -h  -a long_name,$FIELD,o,c,"$LABEL" $FILE
              ncatted -h  -a units,$FIELD,o,c,"$UNITS" $FILE
              ncatted -h  -a vmin,$FIELD,o,c,"$min" $FILE
              ncatted -h  -a vmax,$FIELD,o,c,"$max" $FILE
              ncatted -h -O -a _FillValue,$FIELD,o,f,"1.e+15" $FILE
              ncatted -h -O -a fmissing_value,$FIELD,d,,   $FILE
              ncatted -h -O -a missing_value,$FIELD,d,,   $FILE
              ncatted -h -O -a eulaVlliF_,$FIELD,d,,   $FILE
	      
            end
          end
          #               UPDATE GLOBAL METADTA
          # Extract values from lookup tables
          #   echo " skip $skip"
          if ( $skip == 0 ) then
            # Title
            set title = "`grep Title ${METADATA_TABLE} | cut -d: -f2` ${INSTRUMENT}"
            # ShortName
            set shortname = `grep $INSTRUMENT ${PRODUCT_TABLE} | cut -d, -f3`
            # LongName
            set  longname = `grep $INSTRUMENT ${PRODUCT_TABLE} | cut -d, -f2`
            # VersionID
            set versionid = `grep VersionID ${METADATA_TABLE} | cut -d: -f2`
            # Format
            set format = `grep Format ${METADATA_TABLE} | cut -d: -f2`
            # ProcessingLevel
            set  processing_lev = `grep ProcessingLevel ${METADATA_TABLE} | cut -d: -f2`
            # Conventions
            set conventions = `grep Conventions ${METADATA_TABLE} | cut -d: -f2`
            # Source
            set  dsource = `grep Source ${METADATA_TABLE} | cut -d: -f2`
            # DataSetQuality
            set quality = `grep DataSetQuality ${METADATA_TABLE} | cut -d: -f2`
            # Special Comment
            set comment = `grep Comment ${METADATA_TABLE} | cut -d: -f2`
            # RelatedURL 
            set url = `grep RelatedURL ${METADATA_TABLE} | cut -d: -f2-3`
            # MapProjection
            set projection = `grep MapProjection ${METADATA_TABLE} | cut -d: -f2-3`
            # Datum
            set datum = `grep Datum ${METADATA_TABLE} | cut -d: -f2-3`
            # These need to be NEW values.  Delete the old names.
            
            # IdentifierProductDOIAuthority
            set doiauthority = `grep IdentifierProductDOIAuthority ${METADATA_TABLE} | cut -d: -f2-3`
            # IdentifierProductDOI
            set doi = `grep $INSTRUMENT ${PRODUCT_TABLE} | cut -d, -f4`
            # NEXT:
            # Adjust "units" for observation attributes.  Change from "none" to "count".
            # Build new long names for each variable.
  
            set LABEL = "$FIELD"
            if ( $HOUR  == "00" ) then
              echo "00"
              set begin_date = ${PreviousMonth_LastDay}
              set end_date = ${CurrentMonth_LastDay}
              set  begin_time = "21:00:00.000000"
              set  end_time = "02:59:59.999999"
              set HOUR0   = "21"

            else if ( $HOUR == "06" ) then
              echo "06"
              set  begin_date=${CurrentMonth_FirstDay}
              set  end_date = ${CurrentMonth_LastDay}
              set  begin_time = "03:00:00.000000"
              set end_time = "08:59:59.999999"
              set HOUR0   = "03"

            else if ( $HOUR == 12 ) then
              echo "12"
              set   begin_date = ${CurrentMonth_FirstDay}
              set  end_date = ${CurrentMonth_LastDay}
              set  begin_time = "09:00:00.000000"
              set end_time = "14:59:59.999999"
              set HOUR0   = "09"

            else if ( $HOUR == 18 ) then
              echo "18"
              set  begin_date = ${CurrentMonth_FirstDay}
              set end_date = ${CurrentMonth_LastDay}
              set begin_time = "15:00:00.000000"
              set end_time = "20:59:59.999999"
              set HOUR0   = "15"

            endif

            if ( "$HOUR" == "all" ) then
              set HOUR0   = "00"
              set  granule = "$OUT_DIR/merra2.${INSTRUMENT}.${YYYY}${MM}.nc4"
              set  granuleid = merra2.${INSTRUMENT}.${YYYY}${MM}.nc4
              set  begin_date = ${PreviousMonth_LastDay}
              set  end_date = ${CurrentMonth_LastDay}
              set  begin_time = "21:00:00.000000"
              set  end_time = "20:59:59.999999"
              echo $granule
            else
              set granule =  $OUT_DIR/merra2.${INSTRUMENT}.${YYYY}${MM}${SYNOP}.nc4
              set granuleid = merra2.${INSTRUMENT}.${YYYY}${MM}${SYNOP}.nc4
              echo $granule
            endif
            echo " Adding metadata"
            ncatted -h  -O ${granule}   \
              -a Title,global,o,c,"${title}" \
              -a ShortName,global,o,c,"${shortname}" \
              -a LongName,global,o,c,"${longname}" \
              -a VersionID,global,o,c,"${versionid}" \
              -a Format,global,o,c,"${format}" \
              -a ProcessingLevel,global,o,c,"${processing_lev}" \
              -a Conventions,global,o,c,"${conventions}" \
              -a Source,global,o,c,"${dsource}" \
              -a DataSetQuality,global,o,c,"${quality}" \
              -a Comment,global,o,c,"${comment}" \
              -a RelatedURL,global,o,c,"${url}" \
              -a MapProjection,global,o,c,"${projection}" \
              -a Datum,global,o,c,"${datum}" \
              -a ProductionDateTime,global,o,c,"${prod_date}" \
              -a NorthernmostLatitude,global,d,c, \
              -a Filename,global,o,c,"$granuleid" \
              -a SpatialCoverage,global,o,c,"global" \
              -a Institution,global,o,c,"NASA Global Modeling and Assimilation Office" \
              -a WesternmostLongitude,global,o,c,"-180.0" \
              -a EasternmostLongitude,global,o,c,"179.375" \
              -a SouthernmostLatitude,global,d,c, \
              -a SouthernmostLatitude,global,o,c,"-90.0" \
              -a NorthernmostLatitude,global,d,c, \
              -a NorthernmostLatitude,global,o,c,"90.0" \
              -a LatitudeResolution,global,o,c,"0.5" \
              -a LongitudeResolution,global,o,c,"0.625" \
              -a DataResolution,global,o,c,"0.5x0.625" \
              -a identifier_product_doi_authority,global,d,c, \
              -a IdentifierProductDOIAuthority,global,o,c,"${doiauthority}" \
              -a identifier_product_doi,global,d,c, \
              -a IdentifierProductDOI,global,o,c,"${doi}" \
              -a IdentifierProductDOI,global,o,c,"${doi}" \
              -a GranuleID,global,o,c,"${granuleid}" \
              -a RangeBeginningDate,global,o,c,"${begin_date}" \
              -a RangeBeginningTime,global,o,c,"${begin_time}" \
              -a RangeEndingDate,global,o,c,"${end_date}" \
              -a RangeEndingTime,global,o,c,"${end_time}" \
              -a begin_time,time,o,c,"${HOUR0}:00:00" \
              -a begin_date,time,o,c,${CurrentMonth_FirstDay} \
              -a standard_name,time,o,c,"time" \
              -a standard_name,lat,o,c,"latitude" \
              -a standard_name,lon,o,c,"longitude" \
              -a calendar,time,o,c,"standard" \
              -a units,time,o,c,"minutes since ${CurrentMonth_FirstDay} ${HOUR0}:00:00"
            /home/dao_ops/operations/GIT-OPS/Gridded-Obs/MERRA2/bin/run_n4zip.csh $granule
          endif   # skipping meta data
          echo " ----------------------------"
          echo "      $SYNOP  TIME           "
          echo "      $INSTRUMENT $YYYY $MM  "
          date
          echo " ----------------------------"
          #        end
          echo " ----------------------------"
          echo "      ENDING  TIME           "
          date
          echo " ----------------------------"
        end    # HOUR
      endif   # directory empty check
    endif   # directory check
    /bin/rm $OUT_DIR/*${SYNOP}*tmp
  end      # YYYYMM
end       # INSTRUMENT
