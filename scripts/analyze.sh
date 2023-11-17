#!/bin/sh
mydir=`dirname $0`

export year=2023
export fromdate="${year}-09-01"
export dbentry=666a1696-3c1b-4908-ac66-4a848a6d2dea
export host="https://boulderdata.org/repository"
export datearg="search.db_boulder_county_voters.voted_date_fromdate"


export url="${host}/entry/show?entryid=${dbentry}&db.search=Search&db.view=csv&max=500000&groupsortdir=desc&dbsortby1=full_street_name&dbsortdir1=asc&dbsortby2=address_even&dbsortby3=address&dbsortdir3=asc"



function fetch() {
    echo "fetching $1"
    wget  -q --no-verbose -O "${1}" "${2}" 
}



fetch all_precinct_${year}.csv "${url}&group_by=precinct"
fetch all_precinct_age_${year}.csv "${url}&group_by=precinct&group_by=birth_year_range"

fetch voted_precinct_${year}.csv "${url}&${datearg}=${fromdate}&group_by=precinct"
fetch voted_precinct_age_${year}.csv "${url}&${datearg}=${fromdate}&group_by=precinct&group_by=birth_year_range"
fetch voted_precinct_age_date_${year}.csv "${url}&${datearg}=${fromdate}&group_by=precinct&group_by=birth_year_range&group_by=voted_date"


#wget  -O test.csv "${url}&${datearg}=2023-09-01&group_by=precinct"
