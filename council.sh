#!/bin/sh
mydir=`dirname $0`
source ${mydir}/init.sh


${csv} -deheader \
    -merge "dan_williams,lauren_folkerts,nicole_speer,matt_benjamin" "Progressives" average,min,max \
    -merge "mark_wallach,michael_christy,tara_winer,steve_rosenblum" "PLAN" average,min,max \
    -columns precinct_name,turnout,active_voters,total_ballots,progressives_average,progressives_min,progressives_max,plan_average,plan_min,plan_max,latitude,longitude \
    -decimals 1-10 2 \
    -join precinct neighborhood ${datadir}/precinct_neighborhoods.csv  precinct_name "" \
    -join precinct age_avg ${datadir}/precinct_ages_2021.csv precinct_name 0 \
    -columnsafter precinct_name neighborhood,age_avg \
    -addheader "plan_(.*).label {PLAN \$1} progressives_(.*).label {Progressives \$1} age_avg.label {Average Age} precinct_name.type string" \
    -p city_of_boulder_council_candidates.csv > council_slates_2021.csv


stage_local council_slates_2021.csv





