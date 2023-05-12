#!/bin/sh
mydir=`dirname $0`
source ${mydir}/init.sh

year=2021

${csv} -delimiter "|"  -cleaninput -dots ${dots} \
       -c "precinct,yob" \
       -func age "${year}-_yob" \
       -summary precinct age "" avg \
       -decimals age_avg  0 \
       -join precinct latitude,longitude ${datadir}/boco_precincts.csv  precinct NaN \
       -join precinct neighborhood ${datadir}/precinct_neighborhoods.csv  precinct "" \
       -p ${datadir}/ce-068-${year}.txt.zip > precinct_ages_${year}.csv

${csv}  -addheader "neighborhood.type string precinct.type string age_avg.label {Average Age}" \
       -p  precinct_ages_${year}.csv >  precinct_ages_data_${year}.csv

stage_local precinct_ages_data_${year}.csv




