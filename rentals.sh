#!/bin/sh
mydir=`dirname $0`
source ${mydir}/init.sh


if [ ! -f ballots_sent_2021.csv ]
then
    make_boulder_ballots 2021 21
fi 

${csv} -dots 100 -ifmatchesfile "^\${value}.*" main_address ${datadir}/Boulder_Rental_Housing.csv res_address \
       -c res_address \
       -p ballots_sent_2021.csv 

exit

${csv} -notpattern res_address "(?i)( APT| UNIT| HALL| BSMT| FRNT| LOT | RM | UPPR| BLDG|#| STE | LOWR| ROOM|HOTEL)" \
       -c res_address \
       -change res_address "^\\d+ " "" \
       -p ballots_sent_2021.csv > boulder_voter_houses.csv








