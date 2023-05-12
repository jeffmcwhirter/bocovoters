#!/bin/sh
mydir=`dirname $0`
source ${BOCO}/scripts/init.sh
bins="18,25,35,45,55,65,75"
#bins="18,22,30,40,50,60,70"
#bins="18,19,20,21,22,23,24,25,35,45,55,65,75"
#bins="18,19,20,21,30,50,70"
#bins="18-100:1"

file_prefix_age=histogram_age
file_prefix_precinct=histogram_precinct


make_boulder_ballots() {
    year="$1"
    yy="$2"
    thesplits="${splits_2021}"
    if [ "$year" == "2022" ]; then
	thesplits="${splits_2022}"
    fi
    ballots=ballots_sent_${year}.csv
    precinct_histogram=${file_prefix_precinct}_${year}.csv    
    echo "making $year boulder ballots with file ${ballots} and splits ${thesplits}"
    seesv  -delimiter "|"  \
	   -c "precinct,split,yob,MAIL_BALLOT_RECEIVE_DATE,IN_PERSON_VOTE_DATE,RES_ADDRESS" \
	   -concat precinct,split "." full_precinct \
	   -ifin split ${thesplits}  full_precinct \
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


do_histogram() {
    year="$1"
    yy="$2"
    ballots=ballots_sent_${year}.csv
    age_histogram=${file_prefix_age}_${year}.csv
    precinct_histogram=${file_prefix_precinct}_${year}.csv    
    if [ ! -f ${ballots} ]
    then
	echo "making ${ballots}"
	make_boulder_ballots $1 $2
    fi

    precincts=".*(${precincts})\$" 
    precincts=".*" 
    echo "making $year histogram precints=${precincts} ${ballots}"


    seesv  -pattern precinct "${precincts}" \
	   -histogram age "${bins}"  "voted" "count,sum" \
	   -insert 0  year $year \
	   -round voted_sum  \
	   -set voted_count 0 "Registered Voters" \
	   -set voted_sum 0 "Number Voted" \
	   -func "Turnout" "100*(_number_voted/_registered_voters)" \
	   -decimals "turnout" 1 \
	   -p ${ballots} > ${age_histogram}


    seesv  -pattern precinct "${precincts}" \
	   -summary precinct voted  "" "count,sum" \
	   -insert 0  year $year \
	   -round voted_sum  \
	   -set voted_count 0 "Registered Voters" \
	   -set voted_sum 0 "Number Voted" \
	   -func "Turnout" "100*(_number_voted/_registered_voters)" \
	   -decimals "turnout" 1 \
	   -p ${ballots} > ${precinct_histogram}

    seesv -addheader "" -p ${age_histogram} > voting_age_ranges_${year}.csv
    stage_local voting_age_ranges_${year}.csv
}




do_turnout() {
    seesv -append  1 ${file_prefix_age}_2016.csv ${file_prefix_age}_2017.csv ${file_prefix_age}_2018.csv ${file_prefix_age}_2019.csv ${file_prefix_age}_2020.csv ${file_prefix_age}_2021.csv ${file_prefix_age}_2022.csv > tmp.csv

    seesv -makefields age_range turnout year "" \
	   -addheader "default.unit %  year.type string year.unit {} year.format yyyy" -p tmp.csv >boulder_age_turnout.csv
    seesv -makefields age_range registered_voters year "" \
	   -addheader "year.type string  year.format yyyy" -p tmp.csv >boulder_age_registered_voters.csv    
    seesv -makefields age_range number_voted year "" \
	   -addheader "year.type string year.format yyyy" -p tmp.csv >boulder_age_voted.csv
    stage_local boulder_age_*.csv

}    


do_diff() {
    year1=$1
    year2=$2
    to=boulder_voting_${year1}_${year2}.csv
    echo "Making difference between ${year1} and ${year2}"
    seesv -columns age_range,number_voted \
	   -join age_range  number_voted ${file_prefix_age}_${year2}.csv age_range 0 \
	   -set 1 0 "${year1} Votes" \
	   -set  2 0 "${year2} Votes" \
	   -func "Difference" "_${year2}_votes-_${year1}_votes" \
	   -func "Percent Change" "100*(_${year2}_votes-_${year1}_votes)/_${year1}_votes" \
	   -round percent_change \
	   -addheader "percent_change.unit %" \
	   -p ${file_prefix_age}_${year1}.csv > $to
    stage_local $to
}


do_cat_all() {
    file="$1"
    columns="registered_voters,number_voted,turnout"
    join_column=age_range
    default_value=0
    if [ "$file" == "histogram_precinct" ]; then
	join_column=precinct
    fi
    

    echo "FILE:$file"
    seesv -join ${join_column}  "${columns}"  ${file}_2017.csv   ${join_column} $default_value  \
	  -join ${join_column}  "${columns}"  ${file}_2018.csv   ${join_column} $default_value  \
	  -join ${join_column}  "${columns}"  ${file}_2019.csv   ${join_column} $default_value \
	  -join ${join_column}  "${columns}"  ${file}_2020.csv   ${join_column} $default_value \
	  -join ${join_column}  "${columns}"  ${file}_2021.csv   ${join_column} $default_value \
	  -join ${join_column}  "${columns}"  ${file}_2022.csv   ${join_column} $default_value \
	  -p ${file}_2016.csv  > tmp.csv
}

do_all() {
    file="$1"
    col="$2"
    label="$3"
    echo "making all $col"
    do_cat_all ${file}
    seesv -set 2 0 "2016 Registered Voters"   -set 3 0 "2016 Number Voted" -set 4 0 "2016 Turnout" \
	  -set 5 0 "2017 Registered Voters"   -set 6 0 "2017 Number Voted" -set 7 0 "2017 Turnout" \
	  -set 8 0 "2018 Registered Voters"   -set 9 0 "2018 Number Voted" -set 10 0 "2018 Turnout" \
	  -set 11 0 "2019 Registered Voters"   -set 12 0 "2019 Number Voted" -set 13 0 "2019 Turnout" \
	  -set 14 0 "2020 Registered Voters"   -set 15 0 "2020 Number Voted" -set 16 0 "2020 Turnout" \
	  -set 17 0 "2021 Registered Voters"   -set 18 0 "2021 Number Voted" -set 19 0 "2021 Turnout" \
	  -set 20 0 "2022 Registered Voters"   -set 21 0 "2022 Number Voted" -set 22 0 "2022 Turnout" \
	  -columns "1,2-20:3,3-21:3,4-22:3" \
	  -set 0 0 "${label}" \
	  -addheader "(\\\d\\\d\\\d\\\d).*.label \$1 ${col}.type string .*number_voted.group {Number Voted} .*turnout.group Turnout .*registered_voters.group {Registered Voters} " \
	  -p tmp.csv > ${col}_all.csv
}



do_all_age() {
    do_all ${file_prefix_age} age_range "Age Range"
    stage_local age_range_all.csv
}

do_all_precinct() {
    do_all ${file_prefix_precinct} precinct Precinct
    seesv -deheader -join precinct neighborhood ${datadir}/precinct_neighborhoods.csv precinct "" \
	   -columnsafter precinct neighborhood \
	   -addheader "(\\\d\\\d\\\d\\\d).*.label \$1 ${col}.type string .*number_voted.group {Number Voted} .*turnout.group Turnout .*registered_voters.group {Registered Voters} " \
	   -p precinct_all.csv > tmp.csv
    mv tmp.csv precinct_all.csv
    stage_local precinct_all.csv
}




do_histogram 2016 16
do_histogram 2017 17
do_histogram 2018 18
do_histogram 2019 19
do_histogram 2020 20
do_histogram 2021 21
do_histogram 2022 22
do_turnout
do_diff 2019 2021
do_diff 2017 2021
do_diff 2022 2020
do_all_age
do_all_precinct
exit

