sh ~/bin/seesv.sh  -if -find address "$1" -change latitude "^.*\$" "$2" -change longitude "^.*\$" "$3" -endif -p geocode.csv
