#!/bin/sh
mydir=`dirname $0`
source ${BOCO}/scripts/init.sh
export ADDRESS_KEY=address_key




init_voting_history() {
    if [ ! -f "${voter_history}" ]
    then
	echo "making voter history: ${voter_history}"
	unzip -p ${datadir}/EX-002_Public_Voting_History_List_Part1.txt.zip  >${voter_history}
	unzip -p ${datadir}/EX-002_Public_Voting_History_List_Part2.txt.zip | tail -n+2 >> ${voter_history}
	unzip -p ${datadir}/EX-002_Public_Voting_History_List_Part3.txt.zip | tail -n+2 >> ${voter_history}
	unzip -p ${datadir}/EX-002_Public_Voting_History_List_Part4.txt.zip | tail -n+2 >> ${voter_history}	
    fi
}


do_voting_report() {

    ##For now just create empty files since there isn't any voter reports
    echo "VOTER_ID,MAIL_BALLOT_RECEIVE_DATE,IN_PERSON_VOTE_DATE,voted_in_2023" >${working_dir}/voted_in_${current_year}.csv
    cp ${working_dir}/voted_in_${current_year}.csv     ${working_dir}/all_voted_in_${current_year}.csv    
    return

    echo "processing voting report ${voting_report}"
    seesv  -delimiter "|"  -columns voter_id,MAIL_BALLOT_RECEIVE_DATE,IN_PERSON_VOTE_DATE \
	   -concat "MAIL_BALLOT_RECEIVE_DATE,IN_PERSON_VOTE_DATE" "" voted_in_${current_year} \
	   -trim voted_in_${current_year} \
	   -change voted_in_${current_year} "^$" false \
	   -change voted_in_${current_year} ".*[0-9]+.*" true \
	   -p ${voting_report}  > ${working_dir}/voted_in_${current_year}.csv
    seesv  -delimiter "|"   \
	    -columns voter_id,MAIL_BALLOT_RECEIVE_DATE,IN_PERSON_VOTE_DATE \
	    -concat "MAIL_BALLOT_RECEIVE_DATE,IN_PERSON_VOTE_DATE" "" voted_in_${current_year} \
	    -trim voted_in_${current_year} \
	    -change voted_in_${current_year} "^$" false \
	    -change voted_in_${current_year} ".*[0-9]+.*" true \
	    -p ${voting_report}  > ${working_dir}/all_voted_in_${current_year}.csv
}



do_prep() {
    init_voting_history
    fetch_registered_voters
    if [ "$target" != "all" ]; then
	echo "processing registered voters: ${registered_voters_file}  splits: ${splits} "
	seesv  -delimiter "|"  -notcolumns "regex:(?i)BALLOT_.*"  -concat precinct,split "." precinct_split  \
	       -ifin  split ${splits} precinct_split -notcolumns precinct_split -p ${registered_voters_file} > ${working_dir}/voters_base.csv
    else
	echo "processing registered voters: ${registered_voters_file}  splits: ALL "
	seesv  -delimiter "|"  -notcolumns "regex:(?i)BALLOT_.*"   -p ${registered_voters_file} > ${working_dir}/voters_base.csv
    fi



    echo "making ${target_voters}"
    seesv -if -pattern mail_addr1,mailing_country "^$" -copycolumns res_address mail_addr1  -endif\
	  -if -pattern mailing_city,mailing_country "^$" -copycolumns res_city mailing_city  -endif \
	  -if -pattern mailing_state,mailing_country "^$" -copycolumns res_state mailing_state  -endif\
	  -if -pattern mailing_zip,mailing_country "^$" -copycolumns res_zip_code mailing_zip  -endif\
	  -p ${working_dir}/voters_base.csv >     "${target_voters}"

    echo "making addresses"
    seesv -columns res_address,res_city,res_zip_code \
	  -change res_address " APT .*" "" \
	  -change res_address " UNIT .*" "" \
	  -change res_address " # .*" "" \
	  -trim res_address -unique res_address "" \
	  -insert "" state Colorado  \
	  -set 0 0 address  -set 1 0 city -set res_zip_code 0 zipcode \
	  -p   "${target_voters}" > $(get_working_file voters_addresses.csv)

    do_find_missing_geocode
}


do_find_missing_geocode() {
    file="missing_addresses_${target}.csv"
    seesv    -join "address,city" "latitude,longitude" "${geocode}" "address,city" "MISSING"   \
	     -find latitude MISSING \
	     -notcolumns latitude,longitude \
	     -p  $(get_working_file voters_addresses.csv) > ${file}
    echo "missing addresses: ${file}"
    wc -l "${file}"
}


do_merge_geocode() {
    newfile="$1"
    echo "merging geocode files"
    seesv -columns "0-5" \
	  -case address,city,zipcode,state upper \
	  -p "$newfile" > tmp.csv
    seesv -p ${geocode} tmp.csv | seesv -unique "address,city" exact -p > mergedgeo.csv
    cp mergedgeo.csv  ${geocode}
    echo "the main geocode file has been updated: ${geocode}"
}



do_precincts() {
    seesv -join precinct_name active_voters ${datadir}/precincts_voters.csv precinct 0   \
	   -join precinct city ${datadir}/precincts_city.csv precinct ""   \
	   -columnsafter  neighborhood city \
	   -columnsafter  city active_voters \
	   -concat "latitude,longitude" ";" Location -notcolumns latitude,longitude \
	   -p ${precincts}> precincts_final.csv
    seesv -db "precinct.type string neighborhood.type enumeration city.type enumeration location.type latlon \
    table.icon /icons/map/marker-blue.png \
    table.defaultView map \
    table.mapLabelTemplate _quote_\${precinct} - \${neighborhood}_quote_ \
    table.id precincts table.label {Precincts}  \
    table.cansearch false \
    polygon.canlist false location.canlist false \
    polygon.type clob     polygon.size 200000 \
    precinct.cansearch true active_voters.cansearch true  neighborhood.cansearch true  city.cansearch true  location.cansearch true \
" precincts_final.csv > precinctsdb.xml
}



do_history() {
   echo "making unique voting history from history: ${voter_history} target voters: ${target_voters}"
   seesv -ifin voter_id "${target_voters}"  voter_id -p ${voter_history}  > tmp.csv
   seesv -unique  "voter_id,election_date" "" -p tmp.csv > ${unique_voter_history}

   for year in "${years[@]}"; do
       echo "\tmaking history ${year}"         
       seesv  -pattern election_date "(11/../${year})" -p ${unique_voter_history} > $(get_history_file ${year})         
   done   


   echo "\tmaking offyears"
   seesv  -pattern election_date "(11/../2017|11/../2019|11/../2021)" -p ${unique_voter_history} > $(get_history_file offyears3)   
   seesv -pattern election_date "(11/../2001|11/../2003|11/../2005|11/../2007|11/../2009|11/../2011|11/../2013|11/../2015|11/../2017|11/../2019|11/../2021)" -p ${unique_voter_history} > $(get_history_file offyears10)
}





do_counts() {
    echo "making voter counts"
    cols=VOTER_ID,count
    
    for year in "${years[@]}"; do
	seesv -countunique voter_id -columns ${cols} -set 1 0 "Voted in $year" -change "voted_in_$year" 1 true \
	      -p $(get_history_file "$year") > $(get_count_file "$year")
    done
    seesv -countunique voter_id -columns ${cols} -set 1 0 "Last 3 offyear elections" -p $(get_history_file offyears3)   > $(get_count_file offyears3)
    seesv -countunique voter_id -columns ${cols} -set 1 0 "Last 10 offyear elections" -p $(get_history_file offyears10)   > $(get_count_file offyears10)
    echo "\tmaking all count"
    seesv -countunique voter_id -columns ${cols} -set 1 0 "All elections" -p ${unique_voter_history}  >$(get_count_file all)
    echo "\tmaking primary count"
    seesv -pattern election_type Primary  -countunique voter_id -columns ${cols} -set 1 0 "Primary elections"  -p ${unique_voter_history} >$(get_count_file primary)
}



do_demographics() {
    if [ ! -f "tmp/voters_geocode_trim.csv" ]
    then
	echo "cleaning up the demographics" 
	seesv -columns "address,city,state,latitude,longitude" \
	      -p  ${geocodio} >  tmp/voters_geocode_trim.csv
    fi
}	





do_joins() {
    echo "doing joins"
    cp "${target_voters}" working.csv


    echo "\tjoining 2020 turnout"
    seesv -join precinct_name precinct_turnout_2020 ${datadir}/precincts_turnout_2020.csv precinct 0 -p working.csv > tmp.csv
    mv tmp.csv working.csv

    echo "\tjoining voted in"
    seesv -join 0 "voted_in_${current_year}" "${working_dir}/voted_in_${current_year}.csv" voter_id false        -p working.csv > tmp.csv
    mv tmp.csv working.csv

    echo "\tjoining voting history"
    for year in "${years[@]}"; do
	seesv -join voter_id 1 $(get_count_file "$year") voter_id false        -p working.csv > tmp.csv
	mv tmp.csv working.csv
    done

    seesv -join voter_id 1 $(get_count_file offyears3) voter_id 0        -p working.csv > tmp.csv
    mv tmp.csv working.csv

    seesv -join voter_id 1  $(get_count_file offyears10) voter_id 0        -p working.csv > tmp.csv
    mv tmp.csv working.csv

    seesv -join voter_id 1  $(get_count_file all) voter_id 0          -p working.csv > tmp.csv
    mv tmp.csv working.csv

    seesv -join 0 1 $(get_count_file primary) voter_id 0          -p working.csv > tmp.csv
    mv tmp.csv working.csv    

#join the precincts
    echo "\tjoining precincts"
    seesv -join 0 1 ${precincts} precinct  ""         -p working.csv > tmp.csv
    mv tmp.csv working.csv
#join the  demographics

    echo "\tdoing geocode join"

#create a new column and remove the UNIT and APT suffix to do the join with the geocoded addresses
    seesv -copy res_address ${ADDRESS_KEY} -change ${ADDRESS_KEY} " APT .*" "" -change ${ADDRESS_KEY} " UNIT .*" "" -p working.csv > tmp.csv
    mv tmp.csv working.csv

    seesv    -join "address,city" "latitude,longitude" "${geocode}" "${ADDRESS_KEY},res_city" "NaN"   -p working.csv > tmp.csv
    mv tmp.csv working.csv


##Delete the temp address
    seesv -notcolumns ${ADDRESS_KEY} -p working.csv > tmp.csv


    mv tmp.csv ${working_dir}/voters_joined.csv
    rm working.csv
}


do_final() {
    echo "making final"
    seesv  \
	    -notcolumns county,preference,uocava,uocava_type,issue_method,split \
	    -set county_regn_date 0 registration_date  \
	    -set vr_phone 0 phone -set voter_name 0 name  -set yob 0 birth_year \
	    -ranges birth_year "Birth year range" 1930 10 \
	    -columnsafter birth_year birth_year_range \
	    -set res_address 0 address -set res_city 0 city -set res_state 0 state \
	    -set res_zip_code 0 zip_code -set res_zip_plus 0 zip_plus \
	    -columnsbefore first_name  name,party,status,status_reason,gender,address,city,state,zip_code \
	    -columnsbefore city  street_name,neighborhood \
	    -concat street_name,street_type " " "full street name" \
	    -columnsafter street_name full_street_name \
	    -columnsafter precinct precinct_turnout_2020 \
	    -even address -set even 0 "Address even" \
	    -notpattern address "1731 HAWTHORN AVE" \
	    -p  ${working_dir}/voters_joined.csv > voters_${target}.csv
}

do_db() {
    echo "making db"
    seesv -db "file:${BOCO}/voters/db.properties" "voters_${target}.csv" > boulder_county_voters_db.xml
    release_plugin boulder_county_voters_db.xml
}


do_release() {
    stage_ramadda  "voters_${target}.csv"
}



do_all() {
    do_prep
    do_history
    do_counts
    do_voting_report
    do_joins
    do_final
#    do_db
    do_release
}


process_voter_args "$@"
do_all
