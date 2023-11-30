#!/bin/sh
##
## This script processes the statement of votes. It breaks apart the big spreadsheet into separate
## csv files for each race in a processed sub directory. Each csv file has the different choices as fields

##usage:
#stmt.sh <statement of votes>

set -e

mydir=`dirname $0`
#source ${BOCO}/scripts/init.sh
mydir="${BOCO}/scripts"
csv=~/bin/csv.sh 


seesv() {
    ${csv}  "$@"
}

if [ ! -d "processed" ]
then
   mkdir processed
fi


process() {
    echo "processing $1"
    seesv  -change "active_voters,total_ballots,total_votes" "," "" \
	   -change "active_voters,total_ballots,total_votes" "N/A" "NaN" \
	   -makefields choice_name "total_votes" precinct "active_voters,total_ballots" \
	   -gt total_ballots 0 \
	   -operator "total_ballots,active_voters" "turnout" "/" \
	   -decimals turnout 2 \
	   -firstcolumns precinct \
	   -columnsafter precinct  "active_voters,total_ballots,turnout" \
	   -apply "4-20" -operator "\${column},total_ballots" "\${column_name} %" "/" -decimals "\${column_name} %" 3 -notcolumns "\${column_name}" -endapply \
	   -addheader "precinct.type enum" \
	   -p ${1} > processed/${1}
}

#precinct_code,precinct_number,active_voters,contest_title,choice_name,total_ballots,total_votes,total_undervotes,total_overvotes


echo "exploding file"
seesv -headerids -set precinct_number 0 precinct -explode contest_title "$1"


#process city_of_longmont_council_member_ward_3.csv
#city_of_boulder_council_candidates.csv
#exit

for file in *.csv; do
    process "${file}"
done
