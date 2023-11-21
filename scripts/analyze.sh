#!/bin/sh
mydir=`dirname $0`
#source ${BOCO}/scripts/init.sh
mydir="${BOCO}/scripts"
csv=~/bin/csv.sh 

#change this if you use a different database
total_voters=74582
dbentry=666a1696-3c1b-4908-ac66-4a848a6d2dea


year=2023

fromdate="${year}-09-01"
host="https://boulderdata.org/repository"
datearg="search.db_boulder_county_voters.voted_date_fromdate"
all_prefix="registered_voters_by"

url="${host}/entry/show?entryid=${dbentry}&db.search=Search&db.view=csv&max=500000&groupsortdir=asc"

if [ ! -d "processed" ]
then
   mkdir processed
fi

seesv() {
    ${csv}  -cleaninput  "$@"
}



function fetch() {
    if [ ! -f "${1}" ]
    then
	echo "fetching $1"
	wget  -q --no-verbose -O "${1}" "${2}"
	if [ "$3" == "true" ]; then
	    change_age "${1}"
	fi
	if [ "$4" == "true" ]; then
	    change_date "${1}"
	fi	
    fi
}

function change_date() {
    seesv -dateformat "yyyy-MM-dd" "" -formatdate voted_date  -sortby voted_date up date  -p "${1}" > foo.csv
    mv foo.csv  "${1}"
}

function change_age() {
    seesv -change birth_year_range "<1930.0" "1930 and under" -sortby birth_year_range up string -p "$1" > foo.csv
    mv foo.csv "$1"
}

function add_header() {
    seesv -addheader "birth_year_range.type enum default.type double precinct.type enum voted_date.type date" -p "${1}" > processed/$1
}




fetch ${all_prefix}_age_${year}.csv "${url}&group_by=birth_year_range&agglabel0=registered_voters" true
##add the %
seesv -insert "" total ${total_voters} \
      -operator registered_voters,total percent "/" -notcolumns total \
      -decimals percent 2 \
      -p ${all_prefix}_age_${year}.csv > foo.csv
mv foo.csv  ${all_prefix}_age_${year}.csv 

fetch ${all_prefix}_precinct_${year}.csv "${url}&group_by=precinct&agglabel0=registered_voters"
seesv -gt registered_voters 10\
      -sortby registered_voters down numeric\
      -p ${all_prefix}_precinct_${year}.csv >foo.csv
mv foo.csv ${all_prefix}_precinct_${year}.csv

fetch ${all_prefix}_precinct_age_${year}.csv "${url}&group_by=precinct&group_by=birth_year_range&agglabel0=registered_voters" true


##get rid of these since we change them in place and the script can't be reentrant
rm -f voted_precinct_age_date_${year}.csv voted_age_date_${year}.csv  




fetch voted_precinct_${year}.csv "${url}&${datearg}=${fromdate}&group_by=precinct&agglabel0=voters"

fetch voted_precinct_age_${year}.csv "${url}&${datearg}=${fromdate}&group_by=precinct&group_by=birth_year_range&agglabel0=voters" true

fetch voted_age_${year}.csv "${url}&${datearg}=${fromdate}&group_by=birth_year_range&agglabel0=voters" true

fetch tmp1.csv "${url}&${datearg}=${fromdate}&group_by=voted_date&agglabel0=voters"
seesv -dateformat "yyyy-MM-dd" "" -formatdate voted_date  -sortby voted_date up date  -p tmp1.csv > voted_date_${year}.csv

fetch tmp2.csv "${url}&${datearg}=${fromdate}&group_by=birth_year_range&group_by=voted_date&agglabel0=voters"
seesv -dateformat "yyyy-MM-dd" "" -formatdate voted_date -sortby voted_date up date -p tmp2.csv > voted_age_date_${year}.csv 
change_age voted_age_date_${year}.csv

fetch voted_precinct_age_date_${year}.csv "${url}&${datearg}=${fromdate}&group_by=precinct&group_by=birth_year_range&group_by=voted_date&agglabel0=voters" true true

echo "making fields"
seesv -concat "precinct,voted_date" - unique \
      -makefields birth_year_range voters unique precinct,voted_date \
      -notcolumns unique -firstcolumns voted_date,precinct,1930_and_under \
      -p voted_precinct_age_date_${year}.csv > foo.csv
mv foo.csv voted_precinct_age_date_${year}.csv


seesv -concat "voted_date,birth_year_range" - unique \
      -makefields birth_year_range voters voted_date "" \
      -p voted_age_date_${year}.csv > foo.csv
mv foo.csv voted_age_date_${year}.csv 

echo "making turnout"
seesv -join birth_year_range voters voted_age_${year}.csv birth_year_range NaN \
      -commands ${mydir}/analyzeturnout.txt \
      -p ${all_prefix}_age_${year}.csv > turnout_age_${year}.csv

seesv -join precinct voters voted_precinct_${year}.csv precinct NaN \
      -commands ${mydir}/analyzeturnout.txt \
      -p ${all_prefix}_precinct_${year}.csv > turnout_precinct_${year}.csv

seesv -join "precinct,birth_year_range" voters voted_precinct_age_${year}.csv "precinct,birth_year_range" NaN \
      -commands ${mydir}/analyzeturnout.txt \
      -p ${all_prefix}_precinct_age_${year}.csv > turnout_precinct_age_${year}.csv

echo "adding headers"
for file in *.csv; do
    add_header "${file}"
done




rm processed/tmp*
