#!/bin/csh 

#SBATCH --partition=preops
module load nco
umask 022

#set IN_DIR     = $1
#set OUT_DIR    = $2
set NYMD       = $1
set SYNOP_TABLE = $2
set INSTRUMENT = $3
set skip = 0
set YYYY = `echo $NYMD | cut -c1-4`
set   MM = `echo $NYMD | cut -c5-6`

set TEMP_argv =  ( $argv )

set prod_date = `date -u "+%Y-%m-%dT%TZ"`
echo $prod_date
/bin/rm -f $OUT_DIR/*pid*

set RootDir = /home/dao_ops/operations/GIT-OPS/Gridded-Obs/MERRA2
set RC_DIR      = ${RootDir}/etc
set WAVELENGTH_TABLES = ${RC_DIR}/WAVELENGTH_TABLES

set METADATA_TABLE = ${RC_DIR}/metadata.tbl
set PRODUCT_TABLE  = ${RC_DIR}/M2_OPS_hourly_product_table.csv

set CurrentMonth_FirstDay  = ${YYYY}${MM}01
set PreviousMonth_LastDay = `/usr/bin/perl /home/dao_ops/bin/tick ${CurrentMonth_FirstDay} 000000 -1 0 | cut -d' ' -f1`
set NextMonth             = `/usr/bin/perl /home/dao_ops/bin/tick ${CurrentMonth_FirstDay} 000000  32 0 | cut -d' ' -f1 | cut -c1-6`
set CurrentMonth_LastDay = `/usr/bin/perl /home/dao_ops/bin/tick ${NextMonth}01 000000 -1 0 | cut -d' ' -f1`

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

foreach HOUR ( `echo $SYNOP_TABLE` )
    if ( $HOUR == "all" ) then
        set SYNOP = "" 
    else
        set SYNOP = "_${HOUR}z"
    endif
    set kount = 0
    
    set file  = merra2.${INSTRUMENT}.${YYYY}${MM}${SYNOP}.nc4
    
    foreach MODE ( mean nobs stdv )
        if (  $MODE != "nobs" ) then
            time ncrename -h -O -v ${FIELD},${MODE}_bias $IN_DIR/merra2.${INSTRUMENT}.${MODE}3d_bias_p.${YYYY}${MM}${SYNOP}.nc4 $OUT_DIR/merra2.${INSTRUMENT}.${MODE}3d_bias_p.${YYYY}${MM}${SYNOP}.nc4
            time ncatted -h -O -a comments,,m,c,"bias" $OUT_DIR/merra2.${INSTRUMENT}.${MODE}3d_bias_p.${YYYY}${MM}${SYNOP}.nc4
            time ncatted -h -O -a units,${MODE}_bias,m,c,"K" $OUT_DIR/merra2.${INSTRUMENT}.${MODE}3d_bias_p.${YYYY}${MM}${SYNOP}.nc4
        endif

        time ncrename -h -O -v ${FIELD},${MODE}_obs  $IN_DIR/merra2.${INSTRUMENT}.${MODE}3d_obs_p.${YYYY}${MM}${SYNOP}.nc4 $OUT_DIR/merra2.${INSTRUMENT}.${MODE}3d_obs_p.${YYYY}${MM}${SYNOP}.nc4
        time ncatted -h -O -a comments,,m,c,"obs" $OUT_DIR/merra2.${INSTRUMENT}.${MODE}3d_obs_p.${YYYY}${MM}${SYNOP}.nc4
        time ncatted -h -O -a units,${MODE}_obs,m,c,"K" $OUT_DIR/merra2.${INSTRUMENT}.${MODE}3d_obs_p.${YYYY}${MM}${SYNOP}.nc4

        if (  $MODE != "nobs" ) then
            time ncrename -h -O -v ${FIELD},${MODE}_oma  $IN_DIR/merra2.${INSTRUMENT}.${MODE}3d_oma_p.${YYYY}${MM}${SYNOP}.nc4 $OUT_DIR/merra2.${INSTRUMENT}.${MODE}3d_oma_p.${YYYY}${MM}${SYNOP}.nc4
            time ncatted -h -O -a comments,,m,c,"oma" $OUT_DIR/merra2.${INSTRUMENT}.${MODE}3d_oma_p.${YYYY}${MM}${SYNOP}.nc4
            time ncatted -h -O -a units,${MODE}_oma,m,c,"K" $OUT_DIR/merra2.${INSTRUMENT}.${MODE}3d_oma_p.${YYYY}${MM}${SYNOP}.nc4
            time ncrename -h -O -v ${FIELD},${MODE}_omf $IN_DIR/merra2.${INSTRUMENT}.${MODE}3d_omf_p.${YYYY}${MM}${SYNOP}.nc4 $OUT_DIR/merra2.${INSTRUMENT}.${MODE}3d_omf_p.${YYYY}${MM}${SYNOP}.nc4
            time ncatted -h -O -a comments,,m,c,"omf" $OUT_DIR/merra2.${INSTRUMENT}.${MODE}3d_omf_p.${YYYY}${MM}${SYNOP}.nc4
            time ncatted -h -O -a units,${MODE}_omf,m,c,"K" $OUT_DIR/merra2.${INSTRUMENT}.${MODE}3d_omf_p.${YYYY}${MM}${SYNOP}.nc4
            if ( $kount == 0 ) time ncrcat -h -O $OUT_DIR/merra2.${INSTRUMENT}.${MODE}3d_bias_p.${YYYY}${MM}${SYNOP}.nc4 $OUT_DIR/${file}
            if ( $kount > 0 ) time ncrcat -h -A $OUT_DIR/merra2.${INSTRUMENT}.${MODE}3d_bias_p.${YYYY}${MM}${SYNOP}.nc4 $OUT_DIR/${file}
        endif

        time ncrcat -h -A $OUT_DIR/merra2.${INSTRUMENT}.${MODE}3d_obs_p.${YYYY}${MM}${SYNOP}.nc4 $OUT_DIR/${file}

        if (  $MODE != "nobs" ) then
            time ncrcat -h -A $OUT_DIR/merra2.${INSTRUMENT}.${MODE}3d_oma_p.${YYYY}${MM}${SYNOP}.nc4 $OUT_DIR/${file}
            time ncrcat -h -A $OUT_DIR/merra2.${INSTRUMENT}.${MODE}3d_omf_p.${YYYY}${MM}${SYNOP}.nc4 $OUT_DIR/${file}
        endif

       @ kount = $kount + 1
        
    end    #MODE
    time ncrcat -h -A $WAVELENGTH_TABLES/merra2.${INSTRUMENT}.freq_wave.*.nc4 $OUT_DIR/${file}

    #               UPDATE GLOBAL METADTA
    # Extract values from lookup tables
    #   echo " skip $skip"
    if ( $skip == 0 ) then
        # Title
        set title = "MERRA-2 Hourly Gridded Innovations and Observations  Conventional"
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
        
        set LABEL = "$FIELD"
        
        if ( $HOUR  == "00" ) then
            echo "00"
            set  begin_date = ${PreviousMonth_LastDay}
            set  end_date = ${CurrentMonth_LastDay}
            set  begin_time = "21:00:00.000000"
            set  end_time = "02:59:59.999999"
	    set HOUR0   = "21"

        else if ( $HOUR == "06" ) then
            echo "06"
            set  begin_date=${CurrentMonth_FirstDay}
            set  end_date = ${CurrentMonth_LastDay}
            set  begin_time = "03:00:00.000000"
            set  end_time = "08:59:59.999999"
            set HOUR0   = "03"

        else if ( $HOUR == 12 ) then
            echo "12"
            set  begin_date = ${CurrentMonth_FirstDay}
            set  end_date = ${CurrentMonth_LastDay}
            set  begin_time = "09:00:00.000000"
            set  end_time = "14:59:59.999999"
            set HOUR0   = "09"

        else if ( $HOUR == 18 ) then
            echo "18"
            set  begin_date = ${CurrentMonth_FirstDay}
            set  end_date = ${CurrentMonth_LastDay}
            set  begin_time = "15:00:00.000000"
            set  end_time = "20:59:59.999999"
            set HOUR0   = "15"

        endif

        if ( "$HOUR" == "all" ) then
            set HOUR0   = "00"
            set  granule = "$OUT_DIR/merra2.${INSTRUMENT}.${NYMD}.nc4"
            set  granuleid = merra2.${INSTRUMENT}.${NYMD}.nc4
            set  begin_date = ${PreviousMonth_LastDay}
            set  end_date = ${CurrentMonth_LastDay}
            set  begin_time = "21:00:00.000000"
            set  end_time = "20:59:59.999999"
            echo $granule
        else
            set granule =  $OUT_DIR/merra2.${INSTRUMENT}.${NYMD}${SYNOP}.nc4
            set granuleid = merra2.${INSTRUMENT}.${NYMD}${SYNOP}.nc4
            echo $granule
        endif
        
        echo " Adding metta data"
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
            -a WorthernmostLatitude,global,d,c, \
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

	     ${RootDir}/bin/run_n4zip.csh $granule
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
