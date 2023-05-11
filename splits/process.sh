process() {
    echo "processing $1"
    sh ~/bin/seesv.sh -start Splits -stop Total -roll 0-20 -trim 0 -notpattern 0 "^\$" -p "$1" -o "\${name}.csv"
}

process city_of_boulder.xls
process city_of_lafayette.xls
process city_of_longmont.xls
process city_of_longmont_ward_1.xls
process city_of_longmont_ward_2.xls
process city_of_longmont_ward_3.xls
process city_of_louisville.xls
process city_of_louisville_ward_1.xls
process city_of_louisville_ward_2.xls
process city_of_louisville_ward_3.xls
process town_of_erie.xls
process town_of_jamestown.xls
process town_of_lyons.xls
process town_of_nederland.xls
process town_of_superior.xls
process town_of_ward.xls
