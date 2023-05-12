#!/bin/sh
mydir=`dirname $0`
source ${BOCO}/scripts/init.sh


init_voting_history() {
    if [ ! -f "${voter_history}" ]
    then
	echo "making voter history: ${voter_history}"
	unzip -p ${datadir}/Master_Voting_History_List_Part1.txt.zip  >${voter_history}
	unzip -p ${datadir}/Master_Voting_History_List_Part2.txt.zip | tail -n+2 >> ${voter_history}
	unzip -p ${datadir}/Master_Voting_History_List_Part3.txt.zip | tail -n+2>> ${voter_history}
	unzip -p ${datadir}/Master_Voting_History_List_Part4.txt.zip | tail -n+2>> ${voter_history}    
    fi
}


do_prep() {
    echo "processing voting report ${voting_report}"
    seesv  -delimiter "|"  -pattern RES_CITY BOULDER \
	   -columns voter_id,MAIL_BALLOT_RECEIVE_DATE,IN_PERSON_VOTE_DATE \
	   -concat "MAIL_BALLOT_RECEIVE_DATE,IN_PERSON_VOTE_DATE" "" voted_in_2022 \
	   -trim voted_in_2022 \
	   -change voted_in_2022 "^$" false \
	   -change voted_in_2022 ".*[0-9]+.*" true \
	   -p ${voting_report}  > voted_in_2022.csv
    seesv  -delimiter "|"   \
	    -columns voter_id,MAIL_BALLOT_RECEIVE_DATE,IN_PERSON_VOTE_DATE \
	    -concat "MAIL_BALLOT_RECEIVE_DATE,IN_PERSON_VOTE_DATE" "" voted_in_2022 \
	    -trim voted_in_2022 \
	    -change voted_in_2022 "^$" false \
	    -change voted_in_2022 ".*[0-9]+.*" true \
	    -p ${voting_report}  > all_voted_in_2022.csv

    echo "processing registered voters"
#    seesv  -delimiter "|"  -notcolumns "regex:(?i)BALLOT_.*"  -pattern res_city BOULDER  -p ${registered_voters} > voters_base.csv

    echo "splits: ${splits} ${registered_voters}"
    seesv  -delimiter "|"  -notcolumns "regex:(?i)BALLOT_.*"  -concat precinct,split "." precinct_split  \
	    -ifin  split ${splits} precinct_split -notcolumns precinct_split -p ${registered_voters} > voters_base.csv        

    echo "making ${boulder_voters}"
    seesv -if -pattern mail_addr1,mailing_country "^$" -copycolumns res_address mail_addr1  -endif\
	   -if -pattern mailing_city,mailing_country "^$" -copycolumns res_city mailing_city  -endif \
	   -if -pattern mailing_state,mailing_country "^$" -copycolumns res_state mailing_state  -endif\
	   -if -pattern mailing_zip,mailing_country "^$" -copycolumns res_zip_code mailing_zip  -endif\
	   -p voters_base.csv > ${boulder_voters}

    echo "making addresses"
    seesv -columns res_address,res_city -change res_address " APT .*" "" -change res_address " UNIT .*" "" -trim res_address -unique res_address "" -insert "" state Colorado  -set 0 0 address -set 1 0 city -p ${boulder_voters} > voters_addresses.csv
#    echo "making addresses short"
#    seesv -sample 0.01  -p voters_addresses.csv > voters_addresses_short.csv        
#    rm voters_base.csv
}


#do_prep
#exit


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
   echo "making unique voting history from history: ${voter_history} target voters: ${boulder_voters}"
   seesv -ifin voter_id ${boulder_voters}  voter_id -p ${voter_history}  > tmp.csv
   seesv -unique  "voter_id,election_date" "" -p tmp.csv > ${unique_voter_history}
   seesv  -pattern election_date "(11/../2021)" -p ${unique_voter_history} > history_2021.csv         
   seesv  -pattern election_date "(11/../2020)" -p ${unique_voter_history} > history_2020.csv
   seesv  -pattern election_date "(11/../2019)" -p ${unique_voter_history} > history_2019.csv
   seesv  -pattern election_date "(11/../2018)" -p ${unique_voter_history} > history_2018.csv   
   seesv  -pattern election_date "(11/../2017|11/../2019|11/../2021)" -p ${unique_voter_history} > history_offyears3.csv   
   seesv -pattern election_date "(11/../2001|11/../2003|11/../2005|11/../2007|11/../2009|11/../2011|11/../2013|11/../2015|11/../2017|11/../2019|11/../2021)" -p ${unique_voter_history} > history_offyears10.csv
}


do_counts() {
    echo "making voter counts"
    cols=VOTER_ID,count
    seesv -countunique voter_id -columns ${cols} -set 1 0 "Voted in 2021" -change voted_in_2021 1 true -p history_2021.csv >count_2021.csv
    seesv -countunique voter_id -columns ${cols} -set 1 0 "Voted in 2020" -change voted_in_2020 1 true -p history_2020.csv >count_2020.csv
    seesv -countunique voter_id -columns ${cols} -set 1 0 "Voted in 2019" -change voted_in_2019 1 true -p history_2019.csv >count_2019.csv

    seesv -countunique voter_id -columns ${cols} -set 1 0 "Last 3 offyear elections" -p history_offyears3.csv   >count_offyears3.csv
    seesv -countunique voter_id -columns ${cols} -set 1 0 "Last 10 offyear elections" -p history_offyears10.csv   >count_offyears10.csv
    echo "making all count"
    seesv -countunique voter_id -columns ${cols} -set 1 0 "All elections" -p ${unique_voter_history}  >count_all.csv
    echo "making primary count"
    seesv -pattern election_type Primary  -countunique voter_id -columns ${cols} -set 1 0 "Primary elections"  -p ${unique_voter_history} >count_primary.csv
}

#do_history
#do_counts
#exit


do_demographics() {
    echo "cleaning up the demographics"
#	-rand latitude 39.983 40.042  -rand longitude -105.303 -105.216 \
#	-notcolumns latitude,longitude \
    seesv -notcolumns "regex:(?i).*veteran.*" \
	  -between latitude 39.955 40.1 \
	  -between longitude -105.3777 -105.155 \
	  -concat "latitude,longitude" ";" Location -notcolumns latitude,longitude \
	  -columns "address,location,\
ACS Demographics/Median age/Total/Value, \
ACS Economics/Number of households/Total/Value, \
ACS Economics/Median household income/Total/Value, \
regex:(?i).*Percentage \
"    \
-operator "\
ACS Demographics/Population by age range/Male: Under 5 years/Percentage, \
ACS Demographics/Population by age range/Male: 5 to 9 years/Percentage, \
ACS Demographics/Population by age range/Male: 10 to 14 years/Percentage,\
ACS Demographics/Population by age range/Male: 15 to 17 years/Percentage" "Male under 18" "+" \
-operator "\
ACS Demographics/Population by age range/Male: 18 and 19 years/Percentage, \
ACS Demographics/Population by age range/Male: 20 years/Percentage, \
ACS Demographics/Population by age range/Male: 21 years/Percentage, \
ACS Demographics/Population by age range/Male: 22 to 24 years/Percentage, \
ACS Demographics/Population by age range/Male: 25 to 29 years/Percentage" "Male 18 to 30" "+" \
-operator "\
ACS Demographics/Population by age range/Male: 30 to 34 years/Percentage, \
ACS Demographics/Population by age range/Male: 35 to 39 years/Percentage, \
ACS Demographics/Population by age range/Male: 40 to 44 years/Percentage, \
ACS Demographics/Population by age range/Male: 45 to 49 years/Percentage, \
ACS Demographics/Population by age range/Male: 50 to 54 years/Percentage, \
ACS Demographics/Population by age range/Male: 55 to 59 years/Percentage" "Male 30 to 60" "+" \
-operator "\
ACS Demographics/Population by age range/Male: 60 and 61 years/Percentage, \
ACS Demographics/Population by age range/Male: 62 to 64 years/Percentage, \
ACS Demographics/Population by age range/Male: 65 and 66 years/Percentage, \
ACS Demographics/Population by age range/Male: 67 to 69 years/Percentage, \
ACS Demographics/Population by age range/Male: 70 to 74 years/Percentage, \
ACS Demographics/Population by age range/Male: 75 to 79 years/Percentage,\
ACS Demographics/Population by age range/Male: 80 to 84 years/Percentage, \
ACS Demographics/Population by age range/Male: 85 years and over/Percentage" "Male 60 plus" "+" \
-operator "\
ACS Demographics/Population by age range/Female: Under 5 years/Percentage, \
ACS Demographics/Population by age range/Female: 5 to 9 years/Percentage, \
ACS Demographics/Population by age range/Female: 10 to 14 years/Percentage,\
ACS Demographics/Population by age range/Female: 15 to 17 years/Percentage" "Female under 18" "+" \
-operator "\
ACS Demographics/Population by age range/Female: 18 and 19 years/Percentage, \
ACS Demographics/Population by age range/Female: 20 years/Percentage, \
ACS Demographics/Population by age range/Female: 21 years/Percentage, \
ACS Demographics/Population by age range/Female: 22 to 24 years/Percentage, \
ACS Demographics/Population by age range/Female: 25 to 29 years/Percentage" "Female 18 to 30" "+" \
-operator "\
ACS Demographics/Population by age range/Female: 30 to 34 years/Percentage, \
ACS Demographics/Population by age range/Female: 35 to 39 years/Percentage, \
ACS Demographics/Population by age range/Female: 40 to 44 years/Percentage, \
ACS Demographics/Population by age range/Female: 45 to 49 years/Percentage, \
ACS Demographics/Population by age range/Female: 50 to 54 years/Percentage, \
ACS Demographics/Population by age range/Female: 55 to 59 years/Percentage" "Female 30 to 60" "+" \
-operator "\
ACS Demographics/Population by age range/Female: 60 and 61 years/Percentage, \
ACS Demographics/Population by age range/Female: 62 to 64 years/Percentage, \
ACS Demographics/Population by age range/Female: 65 and 66 years/Percentage, \
ACS Demographics/Population by age range/Female: 67 to 69 years/Percentage, \
ACS Demographics/Population by age range/Female: 70 to 74 years/Percentage, \
ACS Demographics/Population by age range/Female: 75 to 79 years/Percentage,\
ACS Demographics/Population by age range/Female: 80 to 84 years/Percentage, \
ACS Demographics/Population by age range/Female: 85 years and over/Percentage" "Female 60 plus" "+" \
-operator "Male under 18,Female under 18" "Age under 18" average \
-notcolumns "Male under 18,Female under 18" \
-operator "Male 18 to 30,Female 18 to 30" "Age 18 to 30" average \
-notcolumns "Male 18 to 30,Female 18 to 30"  \
-operator "Male 30 to 60,Female 30 to 60" "Age 30 to 60" average \
-notcolumns "Male 30 to 60,Female 30 to 60" \
-operator "Male 60 plus,Female 60 plus" "Age 60 plus" average \
-notcolumns "Male 60 plus,Female 60 plus"  \
-notcolumns "regex:(?i).*/Female.*" -notcolumns "regex:(?i).*/Male.*"  \
-operator "ACS Economics/Household income/Less than \$10_000/Percentage" "Income less than 10000" "+" \
-operator "\
ACS Economics/Household income/\$10_000 to \$14_999/Percentage, \
ACS Economics/Household income/\$15_000 to \$19_999/Percentage, \
ACS Economics/Household income/\$20_000 to \$24_999/Percentage, \
ACS Economics/Household income/\$25_000 to \$29_999/Percentage" "Income 10000 to 30000" + \
-operator "\
ACS Economics/Household income/\$30_000 to \$34_999/Percentage, \
ACS Economics/Household income/\$35_000 to \$39_999/Percentage, \
ACS Economics/Household income/\$40_000 to \$44_999/Percentage, \
ACS Economics/Household income/\$45_000 to \$49_999/Percentage, \
ACS Economics/Household income/\$50_000 to \$59_999/Percentage,\
ACS Economics/Household income/\$60_000 to \$74_999/Percentage,  \
ACS Economics/Household income/\$75_000 to \$99_999/Percentage" "Income  30000 to 100000" + \
-operator "\
ACS Economics/Household income/\$100_000 to \$124_999/Percentage, \
ACS Economics/Household income/\$125_000 to \$149_999/Percentage, \
ACS Economics/Household income/\$150_000 to \$199_999/Percentage, \
ACS Economics/Household income/\$200_000 or more/Percentage" "Income 100000 plus" + \
-operator "ACS Demographics/Race and ethnicity/Hispanic or Latino/Percentage" "Percent Hispanic" "+" \
-operator "ACS Demographics/Median age/Total/Value" "Median age" "+" \
-operator "ACS Families/Household type by household/Family households/Percentage" "Percent family household" "+" \
-operator "ACS Families/Household type by household/Nonfamily households/Percentage" "Percent non family household" "+" \
-operator "ACS Housing/Ownership of occupied units/Owner occupied/Percentage" "Percent owner occupied" "+" \
-operator "ACS Housing/Ownership of occupied units/Renter occupied/Percentage" "Percent renter occupied" "+" \
-operator " \
ACS Housing/Value of owner_occupied housing units/Less than \$10_000/Percentage, \
ACS Housing/Value of owner_occupied housing units/\$10_000 to \$14_999/Percentage, \
ACS Housing/Value of owner_occupied housing units/\$15_000 to \$19_999/Percentage, \
ACS Housing/Value of owner_occupied housing units/\$20_000 to \$24_999/Percentage, \
ACS Housing/Value of owner_occupied housing units/\$25_000 to \$29_999/Percentage, \
ACS Housing/Value of owner_occupied housing units/\$30_000 to \$34_999/Percentage, \
ACS Housing/Value of owner_occupied housing units/\$35_000 to \$39_999/Percentage, \
ACS Housing/Value of owner_occupied housing units/\$40_000 to \$49_999/Percentage, \
ACS Housing/Value of owner_occupied housing units/\$50_000 to \$59_999/Percentage, \
ACS Housing/Value of owner_occupied housing units/\$60_000 to \$69_999/Percentage, \
ACS Housing/Value of owner_occupied housing units/\$70_000 to \$79_999/Percentage, \
ACS Housing/Value of owner_occupied housing units/\$80_000 to \$89_999/Percentage, \
ACS Housing/Value of owner_occupied housing units/\$90_000 to \$99_999/Percentage, \
ACS Housing/Value of owner_occupied housing units/\$100_000 to \$124_999/Percentage, \
ACS Housing/Value of owner_occupied housing units/\$125_000 to \$149_999/Percentage, \
ACS Housing/Value of owner_occupied housing units/\$150_000 to \$174_999/Percentage, \
ACS Housing/Value of owner_occupied housing units/\$175_000 to \$199_999/Percentage, \
ACS Housing/Value of owner_occupied housing units/\$200_000 to \$249_999/Percentage, \
ACS Housing/Value of owner_occupied housing units/\$250_000 to \$299_999/Percentage, \
ACS Housing/Value of owner_occupied housing units/\$300_000 to \$399_999/Percentage, \
ACS Housing/Value of owner_occupied housing units/\$400_000 to \$499_999/Percentage" "House value to 500000" "+" \
-operator " \
ACS Housing/Value of owner_occupied housing units/\$500_000 to \$749_999/Percentage, \
ACS Housing/Value of owner_occupied housing units/\$750_000 to \$999_999/Percentage" "House value 500000 to 1 million" "+" \
-operator " \
ACS Housing/Value of owner_occupied housing units/\$1_000_000 to \$1_499_999/Percentage, \
ACS Housing/Value of owner_occupied housing units/\$1_500_000 to \$1_999_999/Percentage, \
ACS Housing/Value of owner_occupied housing units/\$2_000_000 or more/Percentage"  "House value greater 1 million" "+" \
-scale "age_under_18,age_18_to_30,age_30_to_60,age_60_plus,income_less_than_10000,income_10000_to_30000,income_30000_to_100000,income_100000_plus,percent_hispanic,percent_family_household,percent_non_family_household,percent_owner_occupied,percent_renter_occupied,house_value_to_500000,house_value_500000_to_1_million,house_value_greater_1_million" 0 100 0 \
-round "age_under_18,age_18_to_30,age_30_to_60,age_60_plus,income_less_than_10000,income_10000_to_30000,income_30000_to_100000,income_100000_plus,percent_hispanic,percent_family_household,percent_non_family_household,percent_owner_occupied,percent_renter_occupied,house_value_to_500000,house_value_500000_to_1_million,house_value_greater_1_million" \
-notcolumns "regex:(?i).*Housing/.*" \
-notcolumns "regex:(?i).* structure/.*" \
-notcolumns "ACS Demographics/Median age/Total/Value" \
-notcolumns "regex:(?i).*/household.*" \
-notcolumns "regex:(?i).*household/.*" \
-notcolumns "regex:(?i).*households/.*" \
-notcolumns "regex:(?i).*ethnicity/.*" \
-notcolumns "regex:(?i).*income/.*" \
-p  ${geocodio} >  voters_geocode_trim.csv
}



do_joins() {
    echo "doing joins"
    infile=${boulder_voters}
    cp ${infile} working.csv

    seesv -join precinct_name precinct_turnout_2019 ${datadir}/precincts_turnout.csv precinct 0 -p working.csv > tmp.csv
    mv tmp.csv working.csv

    seesv -join 0 voted_in_2022 voted_in_2022.csv voter_id false        -p working.csv > tmp.csv
    mv tmp.csv working.csv

    seesv -join 0 1 count_2021.csv voter_id false        -p working.csv > tmp.csv
    mv tmp.csv working.csv

    seesv -join 0 1 count_2020.csv voter_id false        -p working.csv > tmp.csv
    mv tmp.csv working.csv

    seesv -join 0 1 count_2019.csv voter_id false        -p working.csv > tmp.csv
    mv tmp.csv working.csv    

    seesv -join 0 1 count_offyears3.csv voter_id 0        -p working.csv > tmp.csv
    mv tmp.csv working.csv

    seesv -join 0 1 count_offyears10.csv voter_id 0        -p working.csv > tmp.csv
    mv tmp.csv working.csv

    seesv -join 0 1  count_all.csv voter_id 0          -p working.csv > tmp.csv
    mv tmp.csv working.csv

    seesv -join 0 1 count_primary.csv voter_id 0          -p working.csv > tmp.csv
    mv tmp.csv working.csv    



#    seesv -join 0 1 count_municipal.csv voter_id 0          -p working.csv > tmp.csv
#    mv tmp.csv working.csv
#join the precincts
    seesv -join 0 1 ${precincts} precinct  ""         -p working.csv > tmp.csv
    mv tmp.csv working.csv
#join the  demographics

#create a new column and remove the UNIT and APT suffix to do the join with the geocoded addresses
    seesv -copy res_address res_address_trim -change res_address_trim " APT .*" "" -change res_address_trim " UNIT .*" "" -p working.csv > tmp.csv
    mv tmp.csv working.csv


    do_join_demographics working.csv tmp.csv
    mv tmp.csv working.csv


##Delete the temp address
    seesv -notcolumns res_address_trim -p working.csv > tmp.csv

    mv tmp.csv voters_joined.csv
    rm working.csv
}




do_join_demographics() {
    echo "doing demographics join"
    seesv    -join address ".*" voters_geocode_trim.csv res_address_trim "0"    -notcolumns address -p $1 > $2
}



#do_joins
#exit



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
	    -columnsafter  city  location  \
	    -concat street_name,street_type " " "full street name" \
	    -columnsafter street_name full_street_name \
	    -columnsafter precinct precinct_turnout_2019 \
	    -even address \
	    -set even 0 "Address even" \
	    -notpattern address "1731 HAWTHORN AVE" \
	    -p  voters_joined.csv > voters_final.csv
}

#do_final
#exit

do_db() {
    echo "making db"
    seesv -db "file:${BOCO}/voters/db.properties" voters_final.csv > bocovotersdb.xml
}



do_release() {
    release_plugin bocovotersdb.xml 
    stage_ramadda  voters_final.csv 
}

#do_db
#release_plugin bocovotersdb.xml 
#exit


do_all() {
    init_voting_history
    fetch_voting_report
    fetch_registered_voters
    echo "**** do_demographics"
    do_demographics
    echo "**** do_prep"
    do_prep
    echo "**** do_history"
    do_history
    echo "**** do_counts"
    do_counts
    do_joins
    echo "**** do_final"
    do_final
    do_db
    do_release
}


do_all
