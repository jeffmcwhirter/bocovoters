#!/bin/sh
export mydir=`dirname $0`
export datadir=${mydir}/data
export csv=~/bin/csv.sh 
export scpgeode=/Users/jeffmc/source/ramadda/bin/scpgeode.sh
export staging=~/staging
export dots=5000
export voting_report_url=https://election.boco.solutions/ElectionDataPublicFiles/CE-068_Voters_With_Ballots_List_Public.zip
ex=4bC!Erlction!$


mkdir -p ${staging}
set -e

fetch_voting_report() {
    echo "fetching voter report"
    wget  -O CE-068_Voters_With_Ballots_List_Public.zip ${voting_report_url}
    mkdir -p tmp
    cd tmp
    jar -xvf ../CE-068_Voters_With_Ballots_List_Public.zip
    mv CE-068* ce-068-2021.txt
    jar -cvf ce-068-2021.txt.zip ce-068-2021.txt
    mv ce-068-2021.txt.zip ${datadir}
    cd ..
    rm CE-068_Voters_With_Ballots_List_Public.zip
}



stage_local() {
    for var in "$@"
    do
	echo "Staging local: $var"
	cp $var ${staging}
    done
}

stage_ramadda() {
    for var in "$@"
    do
	echo "Staging to ramadda: $var"
	sh ${scpgeode} 50.112.99.202 $var staging
	echo "$var"
    done


}

release_plugin() {
    for var in "$@"
    do
	echo "Releasing plugin: $var"
	cp $var ~/.ramadda/plugins/
	sh /Users/jeffmc/source/ramadda/bin/scpgeode.sh 50.112.99.202  $var plugins
   done
}


make_boulder_ballots() {
    year="$1"
    yy="$2"
    ballots=ballots_sent_${year}.csv
    precinct_histogram=${file_prefix_precinct}_${year}.csv    
    echo "making $year boulder ballots"
#	   -ifin precinct ${datadir}/boulder_precincts.csv  precinct \
    ${csv} -cleaninput -dots ${dots} -delimiter "|"  \
	   -c "precinct,split,yob,MAIL_BALLOT_RECEIVE_DATE,IN_PERSON_VOTE_DATE,RES_ADDRESS" \
	   -concat precinct,split "." full_precinct \
	   -ifin split ${datadir}/boulder_splits.csv  full_precinct \
	   -concat "MAIL_BALLOT_RECEIVE_DATE,IN_PERSON_VOTE_DATE" "," "voted_date" \
	   -change voted_date "," "" \
	   -change voted_date "-${yy}$" "-${year}" \
	   -change voted_date "OCT" "10" \
	   -change voted_date "NOV" "11" \
	   -change voted_date "(..)-(..)-(....)" "\$3-\$2-\$1" \
	   -change voted_date "(..)/(..)/(....)" "\$3-\$1-\$2" \
	   -func age "${year}-_yob" \
	   -insert "" voted 0 \
	   -if -notpattern voted_date "" -setcol "" "" voted 1 -endif \
	   -p  ${datadir}/ce-068-${year}.txt.zip > ${ballots}
}    
