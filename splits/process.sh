process() {
    echo "processing $1"
    sh ~/bin/seesv.sh -start Splits -stop Total -roll 0-20 -trim 0 -notpattern 0 "^\$" -p "$1" -o "\${name}.csv"
}


process "DP-002 City of Boulder.xls"
process "DP-002 City of Lafayette.xls"
process "DP-002 City of Longmont Ward 1.xls"
process "DP-002 City of Longmont Ward 2.xls"
process "DP-002 City of Longmont Ward 3.xls"
process "DP-002 City of Longmont.xls"
process "DP-002 City of Louisville Ward 1.xls"
process "DP-002 City of Louisville Ward 2.xls"
process "DP-002 City of Louisville Ward 3.xls"
process "DP-002 City of Louisville.xls"
process "DP-002 Town of Erie.xls"
process "DP-002 Town of Jamestown.xls"
process "DP-002 Town of Lyons.xls"
process "DP-002 Town of Nederland.xls"
process "DP-002 Town of Superior.xls"
process "DP-002 Town of Ward.xls"
