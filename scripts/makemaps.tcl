source precincts.tcl

foreach tuple $precincts {
    foreach {id name} $tuple break
    set title "";
    if {$name!=""} {
	set title "$title $name - $id"
    } else  {
	set title "$title $id"
    }    
    set fileName  "map_[string tolower $title].pdf"
    regsub -all {[  -]+} $fileName {_} fileName
    regsub -all {__+} $fileName {_} fileName    

    set title "Precinct: $title"

    regsub -all { } $title "%20" title
    puts $title
    set url "https://localhost:8430/repository/entry/show?entryid=d298bc52-70cf-4cf3-8a4c-f84559a0ed90&db.search=Search&db.view=map&search.db_precincts.precinct=${id}&groupsortdir=desc&searchname=${title}&forprint=true&simplemap=true&mapheight=500&mapprops=strokeColor%3D%23000%0AstrokeWidth%3D4%0AfillColor%3Dtransparent" 
    exec sh capturepdf.sh "$url" "$fileName" -dir maps -delay 1
}
