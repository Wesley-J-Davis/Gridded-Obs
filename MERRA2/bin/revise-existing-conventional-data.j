#!/usr/bin/csh
set echo
setenv BinDir /gpfsm/dnb34/dao_ops/TEST/M2_GRITAS/github_repo/M2_GRITAS/GrITAS/Linux/bin
setenv ESMADIR /home/dao_ops/GEOSadas-5_41_3/GEOSadas
setenv GEOS_BINDIR $ESMADIR/install/bin
source $BinDir/g5_modules
module load nco
module load python/GEOSpyD/24.11.3-0/3.13
which python
echo $BASEDIR
set YEAR_TABLE = $1
## Dynamically produce a list of satellites for a given year/month
`which python` sat_list_read.py ${YEAR_TABLE}
# set SATELLITE_LIST=`cat ./dynamic_list.txt`
# echo "$SATELLITE_LIST"
# specific python version command: module spider python/GEOSpyD/24.11.3-0/3.13
set YEAR = `echo $YEAR_TABLE | cut -c 1-4`
set MONTH = `echo $YEAR_TABLE | cut -c 5-6`
set SATELLITE_LIST = $2
set FIELD = "tb"
set SYNOP_TABLE =  ( 00 06 12 18 all ) 
set RC_DIR      = /gpfsm/dnb34/dao_ops/TEST/M2_GRITAS/github_repo/M2_GRITAS/GrITAS/src/Components/gritas/GIO
set IN_DIR      = /gpfsm/dnb05/projects/p53/merra2/data/obs/products
#set IN_DIR      = /gpfsm/dnb05/projects/p53/merra2/data/obs/.WORK/products_new
set OUT_DIR     = /gpfsm/dnb05/projects/p53/merra2/data/obs/.WORK/products_revised
set LATS4D      = /discover/nobackup/projects/gmao/share/gmao_ops/opengrads/Contents/lats4d.sh

set prod_date = `date -u "+%Y-%m-%dT%TZ"`
echo $prod_date  


if ($YEAR >= 1979 && $YEAR < 1991) then
    set ExpID = d5124_m2_jan79
else if ($YEAR >= 1991 && $YEAR < 2000) then
    set ExpID = d5124_m2_jan91
else if ($YEAR >= 2000 && $YEAR < 2010) then
    set ExpID = d5124_m2_jan00
else if ($YEAR >= 2010 && $YEAR < 2021) then
    set ExpID = d5124_m2_jan10
else if ($YEAR >= 2021 && $YEAR < 2026) then
    set ExpID = d5124_m2_jan21
else
    echo "error with experiment calculation"
    exit 1
endif
set OBS_DIR 	= /home/dao_ops/$ExpID/run/.../archive/obs
set WAVELENGTH_TABLES = ${RC_DIR}/WAVELENGTH_TABLES
set METADATA_TABLE = ${RC_DIR}/metadata.tbl     
set PRODUCT_TABLE = ${RC_DIR}/M2_OPS_product_table.csv
foreach INSTRUMENT ( `echo $SATELLITE_LIST ` )
	set TARGET_DIR = "${IN_DIR}/${INSTRUMENT}/d/Y${YEAR}/M${MONTH}"
	    
	mkdir -p ${OUT_DIR}/${INSTRUMENT}/d/Y${YEAR}/M${MONTH}
	
	# Extract values from lookup tables
	# Title
	set title 		= "`grep Title ${METADATA_TABLE} | cut -d: -f2` ${INSTRUMENT}"
	# ShortName
	set shortname 		= `grep $INSTRUMENT ${PRODUCT_TABLE} | cut -d, -f3`
	# LongName
	set longname 		= `grep $INSTRUMENT ${PRODUCT_TABLE} | cut -d, -f2`
	# VersionID
	set versionid 		= `grep VersionID ${METADATA_TABLE} | cut -d: -f2`
	# Format
	set format 		= `grep Format ${METADATA_TABLE} | cut -d: -f2`
	# ProcessingLevel
	set processing_lev 	= `grep ProcessingLevel ${METADATA_TABLE} | cut -d: -f2`
	# Conventions
	set conventions 	= `grep Conventions ${METADATA_TABLE} | cut -d: -f2`
	# Source
	set dsource 		= `grep Source ${METADATA_TABLE} | cut -d: -f2`
	# DataSetQuality
	set quality 		= `grep DataSetQuality ${METADATA_TABLE} | cut -d: -f2`
	# Special Comment
	set comment 		= `grep Comment ${METADATA_TABLE} | cut -d: -f2`
	# RelatedURL
	set url 		= `grep RelatedURL ${METADATA_TABLE} | cut -d: -f2-3`
	# MapProjection
	set projection 		= `grep MapProjection ${METADATA_TABLE} | cut -d: -f2-3`
	# Datum
	set datum 		= `grep Datum ${METADATA_TABLE} | cut -d: -f2-3`
	# IdentifierProductDOIAuthority
	set doiauthority 	= `grep IdentifierProductDOIAuthority ${METADATA_TABLE} | cut -d: -f2-3`
	# IdentifierProductDOI
	set doi 		= `grep $INSTRUMENT ${PRODUCT_TABLE} | cut -d, -f4`
	
	if ( $FIELD == "tb" ) then
		set LABEL = "brightness temperature"
	else
		set LABEL = "$FIELD"
	endif
	
	set ln_mean_obs = "$INSTRUMENT $LABEL mean observations"
	set ln_mean_oma = "$INSTRUMENT $LABEL mean O-minus-A"
	set ln_mean_omf = "$INSTRUMENT $LABEL mean O-minus-F"
	set ln_mean_bias = "$INSTRUMENT $LABEL mean bias"
	
	set ln_nobs_obs = "$INSTRUMENT $LABEL number observations"
	set ln_nobs_oma = "$INSTRUMENT $LABEL number O-minus-A"
	set ln_nobs_omf = "$INSTRUMENT $LABEL number O-minus-F"
	set ln_nobs_bias = "$INSTRUMENT $LABEL number bias"
	set ln_stdv_obs = "$INSTRUMENT $LABEL square root of variance observations"
	set ln_stdv_oma = "$INSTRUMENT $LABEL square root of variance O-minus-A"
	set ln_stdv_omf = "$INSTRUMENT $LABEL square root of variance O-minus-F"
	set ln_stdv_bias = "$INSTRUMENT $LABEL square root of variance bias"
	
	set CurrentMonth_FirstDay  	=  ${YEAR}${MONTH}01 
	set PreviousMonth_LastDay 	= `${GEOS_BINDIR}/tick ${CurrentMonth_FirstDay} 000000 -1 0 | cut -d' ' -f1`
	set NextMonth             	= `${GEOS_BINDIR}/tick ${CurrentMonth_FirstDay} 000000 32 0 | cut -d' ' -f1 | cut -c1-6`
	set CurrentMonth_LastDay 	= `${GEOS_BINDIR}/tick ${NextMonth}01 000000 -1 0 | cut -d' ' -f1`
	
	foreach HOUR ( `echo $SYNOP_TABLE` )
		if ( $HOUR == "all" ) then
			set SYNOP = ""
		else
			set SYNOP = "_${HOUR}z"
		endif
		
		set infile  = merra2.${INSTRUMENT}.${YEAR}${MONTH}${SYNOP}.nc4
	        set outfile  = merra2.${INSTRUMENT}.${YEAR}${MONTH}${SYNOP}
	
		# FIXES DIMENSION ISSUE WITH LEV/LEVELS LON/LONGITUDE LAT/LATITUDE
	        $LATS4D \
	                -i  ${IN_DIR}/${INSTRUMENT}/d/Y${YEAR}/M${MONTH}/${infile} \
	                -o ${OUT_DIR}/${INSTRUMENT}/d/Y${YEAR}/M${MONTH}/${outfile} -zrev
		
		# FIXES SATELLITE LEVEL=UP ISSUE
		$RC_DIR/run_ncrcat.csh  ${OUT_DIR}/${INSTRUMENT}/d/Y${YEAR}/M${MONTH}/${outfile}.nc
		
	
		# TEST FIX FOR COMMENTS/UNITS
	
	        foreach MODE ( mean nobs stdv )
		        if (  $MODE != "nobs" ) then
	                        time ncatted -h -O -a comments,${MODE}_bias,m,c,"bias" $OUT_DIR/${INSTRUMENT}/d/Y${YEAR}/M${MONTH}/${outfile}.nc
	                        time ncatted -h -O -a units,${MODE}_bias,m,c,"K" $OUT_DIR/${INSTRUMENT}/d/Y${YEAR}/M${MONTH}/${outfile}.nc
	                endif
	
	                time ncatted -h -O -a comments,${MODE}_obs,m,c,"obs" $OUT_DIR/${INSTRUMENT}/d/Y${YEAR}/M${MONTH}/${outfile}.nc
	                time ncatted -h -O -a units,${MODE}_obs,m,c,"K" $OUT_DIR/${INSTRUMENT}/d/Y${YEAR}/M${MONTH}/${outfile}.nc
	
	                if (  $MODE != "nobs" ) then
	
	                        time ncatted -h -O 	-a comments,${MODE}_oma,m,c,"oma" 	$OUT_DIR/${INSTRUMENT}/d/Y${YEAR}/M${MONTH}/${outfile}.nc
	                        time ncatted -h -O 	-a units,${MODE}_oma,m,c,"K" 		$OUT_DIR/${INSTRUMENT}/d/Y${YEAR}/M${MONTH}/${outfile}.nc
	
	                        time ncatted -h -O 	-a comments,${MODE}_omf,m,c,"omf" 	$OUT_DIR/${INSTRUMENT}/d/Y${YEAR}/M${MONTH}/${outfile}.nc
	                        time ncatted -h -O 	-a units,${MODE}_omf,m,c,"K" 		$OUT_DIR/${INSTRUMENT}/d/Y${YEAR}/M${MONTH}/${outfile}.nc
	                endif

        	        time ncrcat -h -A $WAVELENGTH_TABLES/merra2.${INSTRUMENT}.freq_wave.*.nc4 $OUT_DIR/${INSTRUMENT}/d/Y${YEAR}/M${MONTH}/${outfile}.nc
		end
	
		# TIME STAMPS FOR GLOBAL METADATA
	
	        if ( $HOUR  == "00" ) then
	
	                set yyyy 			= `echo ${PreviousMonth_LastDay} | cut -c1-4`
	                set mm   			= `echo ${PreviousMonth_LastDay} | cut -c5-6`
	                set dd   			= `echo ${PreviousMonth_LastDay} | cut -c7-8`
	                set begin_date 			= "${yyyy}-${mm}-${dd}"
	                set yyyy 			= `echo ${YEAR_TABLE} | cut -c1-4`
	                set mm  			= `echo ${YEAR_TABLE} | cut -c5-6`
	                set dd                          = `echo ${CurrentMonth_LastDay} | cut -c7-8`
	                set end_date 			= "${yyyy}-${mm}-${dd}"
	                set begin_time 			= "21:00:00.000000"
	                set end_time 			= "02:59:59.999999"
			set HOUR0			= "00"
	
		else if ( $HOUR == "06" ) then
	
	                set yyyy                        = `echo ${YEAR_TABLE} | cut -c1-4`
	                set mm                          = `echo ${YEAR_TABLE} | cut -c5-6`		
			set dd				= `echo ${CurrentMonth_FirstDay} | cut -c7-8`
			set begin_date 			= "${yyyy}-${mm}-${dd}"
	                set dd                          = `echo ${CurrentMonth_LastDay} | cut -c7-8`	
			set end_date 			= "${yyyy}-${mm}-${dd}"	
			set begin_time 			= "03:00:00.000000"	
			set end_time 			= "08:59:59.999999"
			set HOUR0			= "06"
	
		else if ( $HOUR == 12 ) then
	                set yyyy                        = `echo ${YEAR_TABLE} | cut -c1-4`
	                set mm                          = `echo ${YEAR_TABLE} | cut -c5-6`
	                set dd                          = `echo ${CurrentMonth_FirstDay} | cut -c7-8`
	                set begin_date 			= "${yyyy}-${mm}-${dd}"
	                set dd                          = `echo ${CurrentMonth_LastDay} | cut -c7-8`
	                set end_date 			= "${yyyy}-${mm}-${dd}"
	                set begin_time 			= "09:00:00.000000"
	                set end_time 			= "14:59:59.999999"
			set HOUR0			= "12"
		else if ( $HOUR == 18 ) then
	                set yyyy                        = `echo ${YEAR_TABLE} | cut -c1-4`
	                set mm                          = `echo ${YEAR_TABLE} | cut -c5-6`
	                set dd                          = `echo ${CurrentMonth_FirstDay} | cut -c7-8`
	                set begin_date 			= "${yyyy}-${mm}-${dd}"
	                set dd          		= `echo ${CurrentMonth_LastDay} | cut -c7-8`
	                set end_date 			= "${yyyy}-${mm}-${dd}"
	                set begin_time 			= "15:00:00.000000"
	                set end_time 			= "20:59:59.999999"
			set HOUR0			= "18"
		endif
	
        	if ( "$HOUR" == "all" ) then
	                set HOUR0 = "00"
		        set CurrentMonth_FirstDay 	= ${YEAR}${MONTH}01
	                set PreviousMonth_LastDay 	= `${GEOS_BINDIR}/tick ${CurrentMonth_FirstDay} 000000 -1 0 | cut -d' ' -f1`
	                set yyyy                        = `echo ${PreviousMonth_LastDay} | cut -c1-4`
	                set mm                          = `echo ${PreviousMonth_LastDay} | cut -c5-6`
	                set dd                          = `echo ${PreviousMonth_LastDay} | cut -c7-8`
	                set begin_date                  = "${yyyy}-${mm}-${dd}"
	                set yyyy                        = `echo ${YEAR_TABLE} | cut -c1-4`
	                set mm                          = `echo ${YEAR_TABLE} | cut -c5-6`
			set dd		= `echo ${CurrentMonth_LastDay} | cut -c7-8`
	                set end_date 	= "${yyyy}-${mm}-${dd}"
	                set granule 	= "$OUT_DIR/${INSTRUMENT}/d/Y${YEAR}/M${MONTH}/merra2.${INSTRUMENT}.${YEAR}${MONTH}.nc"
	                set granuleid 	= merra2.${INSTRUMENT}.${YEAR}${MONTH}.nc4
	                set begin_time 	= "21:00:00.000000"
	                set end_time 	= "20:59:59.999999"
	                echo $granule
		else	
        	        set granule 	= "$OUT_DIR/${INSTRUMENT}/d/Y${YEAR}/M${MONTH}/merra2.${INSTRUMENT}.${YEAR}${MONTH}${SYNOP}.nc"
	                set granuleid 	= merra2.${INSTRUMENT}.${YEAR}${MONTH}${SYNOP}.nc4
	                echo $granule
	        endif
	
	        ncatted -h -O ${granule} \
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
	                -a long_name,mean_obs,o,c,"${ln_mean_obs}" \
	                -a long_name,mean_oma,o,c,"${ln_mean_oma}" \
	                -a long_name,mean_omf,o,c,"${ln_mean_omf}" \
	                -a long_name,mean_bias,o,c,"${ln_mean_bias}" \
	                -a long_name,nobs_obs,o,c,"${ln_nobs_obs}" \
	                -a long_name,stdv_obs,o,c,"${ln_stdv_obs}" \
	                -a long_name,stdv_oma,o,c,"${ln_stdv_oma}" \
	                -a long_name,stdv_omf,o,c,"${ln_stdv_omf}" \
	                -a long_name,stdv_bias,o,c,"${ln_stdv_bias}" \
	                -a _FillValue,mean_obs,o,f,"1.e+15" \
	                -a _FillValue,mean_oma,o,f,"1.e+15" \
	                -a _FillValue,mean_omf,o,f,"1.e+15" \
	                -a _FillValue,mean_bias,o,f,"1.e+15" \
	                -a _FillValue,nobs_obs,o,f,"1.e+15" \
	                -a _FillValue,stdv_obs,o,f,"1.e+15" \
	                -a _FillValue,stdv_oma,o,f,"1.e+15" \
	                -a _FillValue,stdv_omf,o,f,"1.e+15" \
	                -a _FillValue,stdv_bias,o,f,"1.e+15" \
	                -a units,nobs_obs,o,c,"count" \
	                -a long_name,time,o,c,"time" \
            		-a begin_time,time,o,c,"${HOUR0}:00:00" \
            		-a begin_date,time,o,c,${CurrentMonth_FirstDay} \
	                -a standard_name,time,o,c,"time" \
	                -a calendar,time,o,c,"standard" \
	                -a units,time,o,c,"minutes since ${CurrentMonth_FirstDay} ${HOUR0}:00:00" \
			-a standard_name,frequency,o,c,"sensor_band_central_radiation_frequency" \
			-a standard_name,wavelength,o,c,"sensor_band_central_radiation_wavelength"
	 
			${RC_DIR}/run_n4zip.csh $granule  
			
	end
end
