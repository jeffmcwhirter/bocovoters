#!/bin/sh
set -e

export mydir=`dirname $0`
export datadir=${mydir}/data
export csv=~/bin/csv.sh 
export scpgeode=~/source/ramadda/bin/scpgeode.sh
export staging=~/staging
export dots=5000

boulder_voters=voters_boulder.csv
voter_history=voter_history.csv
unique_voter_history=voter_history_unique.csv
precincts=${datadir}/boco_precincts.csv
geocodio=${datadir}/voters_addresses_geocodio.csv.zip


#fetch the Master_Voting_History_List_Part[1-N].txt from the url and copy them
#into a source subdirectory from where you are running the voters.sh script
export voter_history_url=https://bcelections.sharefile.com/home/shared/fo740e74-18fd-486c-8bc4-0794c4bbd2ff
voter_history_p=4bC!Erlction!$

new=bC!Erlction!$

export voting_report_url=https://election.boco.solutions/ElectionDataPublicFiles/CE-068_Voters_With_Ballots_List_Public.zip
export voting_report_file=ce-068-2022.txt
export voting_report=${datadir}/${voting_report_file}.zip


export registered_voters_url=https://election.boco.solutions/ElectionDataPublicFiles/CE-VR011B_EXTERNAL.zip
export registered_voters_file=registered_voters_2022.txt
export registered_voters=${datadir}/${registered_voters_file}.zip
export splits_2021=${datadir}/boulder_splits_2021.csv
export splits_2022=${datadir}/boulder_splits_2022.csv

export splits=${splits_2022}

#Old 2021 precincts
#export registered_voters=${datadir}/ce-vr011b.txt.zip
#export splits=${datadir}/boulder_splits_2021.csv

mkdir -p ${staging}

seesv() {
    ${csv}  -cleaninput -dots  ${dots}  "$@"
}


fetch_voting_report() {
    echo "fetching voter report"
    wget  -q -O CE-068_Voters_With_Ballots_List_Public.zip ${voting_report_url}
    mkdir -p tmp
    cd tmp
    jar -xvf ../CE-068_Voters_With_Ballots_List_Public.zip
    ls CE-068*
    mv CE-068* ${voting_report_file}
    jar -cvMf ${voting_report_file}.zip ${voting_report_file}
    mv ${voting_report_file}.zip ${datadir}
    cd ..
    rm CE-068_Voters_With_Ballots_List_Public.zip
    echo "Updated: ${voting_report_file}"
}


fetch_registered_voters() {
    echo "fetching registered voters"
    wget  -O tmp.zip ${registered_voters_url}
    mkdir -p tmp
    cd tmp
    jar -xvf ../tmp.zip
    mv CE-VR011B_EXTERNAL* ${registered_voters_file}
    jar -cvMf ${registered_voters_file}.zip ${registered_voters_file}
    echo "Moving registered_voters.txt.zip to ${registered_voters}"
    mv ${registered_voters_file}.zip "${registered_voters}"
    cd ..
    rm tmp.zip
}

#fetch_registered_voters
#exit

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
	sh ${scpgeode} 50.112.99.202 $var /home/ec2-user/staging
	echo "$var"
    done


}

release_plugin() {
    for var in "$@"
    do
	echo "Releasing plugin: $var"
	cp $var ~/.ramadda/plugins/
	sh ~/source/ramadda/bin/scpgeode.sh 50.112.99.202  $var plugins
   done
}


