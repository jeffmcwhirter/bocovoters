#!/bin/sh
set -e

export mydir=`dirname $0`

export csv=~/bin/csv.sh 
export scpgeode=~/source/ramadda/bin/scpgeode.sh

export tmpdir=tmp
export datadir=${BOCO}/data
export splitsdir=${BOCO}/splits
export staging=~/staging
export dots=5000

export  targets=("city_of_boulder" "city_of_lafayette" "city_of_longmont" "city_of_longmont_ward_1" "city_of_longmont_ward_2" "city_of_longmont_ward_3" "city_of_louisville" "city_of_louisville_ward_1" "city_of_louisville_ward_2" "city_of_louisville_ward_3" "town_of_erie" "town_of_jamestown" "town_of_lyons" "town_of_nederland" "town_of_superior" "town_of_ward")

mkdir -p ${tmpdir}
mkdir -p ${staging}

function get_working_dir() {
    mkdir -p ${target}
    local fileresult=${target}
    echo "$fileresult"
}

function get_tmp_file() {
    local  working=tmp/${1}
    echo "$working"
}

function get_working_file() {
    local  working=$(get_working_dir)/${1}
    echo "$working"
}


function get_count_file() {
#    local  myresult=$(get_working_file "count_${1}.csv")
    local  myresult=$(get_tmp_file "count_${1}.csv")
    echo "$myresult"
}

function get_history_file() {
#    local  myresult=$(get_working_file "history_${1}.csv")
    local  myresult=$(get_tmp_file "history_${1}.csv")
    echo "$myresult"
}


precinctsmap=${datadir}/boulder_precincts_2022.geojson
precincts=${datadir}/boco_precincts.csv
geocodio=${datadir}/voters_addresses_geocodio.csv.zip
geocode=${datadir}/geocode.csv

export current_year=2023
years_set="2022,2021,2020,2019,2018"
# Split the string_set into an array using comma as the delimiter
IFS=',' read -ra years <<< "$years_set"



export voting_report_url=https://election.boco.solutions/ElectionDataPublicFiles/CE-068_Voters_With_Ballots_List_Public.zip
export voting_report_file="ce-068-${current_year}.txt"
export voting_report=${datadir}/${voting_report_file}.zip


export registered_voters_url=https://election.boco.solutions/ElectionDataPublicFiles/CE-VR011B_EXTERNAL.zip
export registered_voters_file=$(get_tmp_file "registered_voters.txt")



export splits_2021=${splitsdir}/boulder_splits_2021.csv
export target=city_of_boulder
export splits_2022=${splitsdir}/${target}.csv
export splits=${splits_2022}



#voter history comes from the below URL. Unzip the file and zip up each
#EX-002_Public_Voting_History_List_Part[1-4].txt  file and put them in the bocovoters/data directory
#https://bouldercounty.gov/elections/maps-and-data/data-access/#Master-Voter-History-Data-File
voter_history=$(get_tmp_file "voter_history.csv")
unique_voter_history=$(get_tmp_file "voter_history_unique.csv")


process_voter_args() {
    while [[ $# -gt 0 ]]
    do
	arg=$1
	case $arg in
        -target)
	    shift
	    target=$1
	    init_globals
	    shift
	    if [ "$target" != "all" ]; then
		echo "using splits file: ${splits}"
		if [ ! -f "${splits}" ]
		then
		    s=""
		    for string in "${targets[@]}"; do
			s="$s $string"
		    done
		    echo "Error: unknown splits file:${splits}"
		    echo "Can be one of: ${s}"
		    exit
		fi
	    fi
            ;;
	-clean)
	    echo 'cleaning'
	    rm -r -f missing_addresses*
	    rm -r -f voters_*.csv
	    rm -r -f precincts*
	    rm -r -f boulder_county_voters_db.xml
	    rm -r -f tmp/*
	    if [ ! -d "junk" ]
	    then
	       mkdir  junk
	    fi
	    rm -r -f  junk/*
	    for t in "${targets[@]}"; do
		if [  -d "${t}" ]
		then
		    mv -f  "${t}" junk/
		fi
	    done
	    echo 'done cleaning'
	    shift
	    ;;
	-prep)
	    do_prep
	    shift
	    ;;
	-quit)
	    exit
	    ;;
	-mergegeo)
	    shift
	    do_merge_geocode $1
	    exit
	    shift
	    ;;
	-fetchreport)
	    fetch_voting_report
	    shift
	    ;;
	-call)
	    shift
	    init_globals
	    $1
	    exit
	    ;;
	-all)
	    for name in "${targets[@]}"; do
		echo "Processing ${name}"
		target="${name}"
		init_globals
		do_all
	    done
	    exit
	    ;;
	*)
	    echo "Unknown argument:$arg"
	    echo "usage: \n\t-target <target> \n\t-prep\n\t-mergegeo <new file>\n\t-fetchreport\n\t-all\n\t-quit"
	    exit 1
	    ;;
	esac
    done

    init_globals

}

init_globals() {
    export splits="${splitsdir}/${target}.csv"
    export target_voters=$(get_working_file target_voters.csv)
    export working_dir=$(get_working_dir)
}


seesv() {
    ${csv}  -cleaninput -dots  "tab${dots}"  "$@"
}


#
#The voting report shows whether voters have voted yet in the current election
#
fetch_voting_report() {
    echo "fetching voter report"
    wget  -q -O ${tmpdir}/CE-068_Voters_With_Ballots_List_Public.zip ${voting_report_url}
    cd ${tmpdir}
    jar -xvf CE-068_Voters_With_Ballots_List_Public.zip
    ls CE-068*.txt
    mv CE-068*.txt ${voting_report_file}
    jar -cvMf ${voting_report_file}.zip ${voting_report_file}
    cd ..
    mv ${tmpdir}/${voting_report_file}.zip ${datadir}
    rm ${tmpdir}/CE-068_Voters_With_Ballots_List_Public.zip
    echo "Updated: ${voting_report_file}"
}


fetch_registered_voters() {
    if [ ! -f "${registered_voters_file}" ]
    then
	echo "fetching registered voters"
	wget  -O tmp.zip ${registered_voters_url}
	unzip -o  tmp.zip -d tmp
	mv tmp/CE-VR011B_EXTERNAL* ${registered_voters_file}
	zip -j  ${registered_voters_file}.zip ${registered_voters_file}
	echo "Moving registered_voters.txt.zip to ${datadir}"
	mv "${registered_voters_file}.zip" "${datadir}/${registered_voters}"
	rm tmp.zip
    fi
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



