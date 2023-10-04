source precincts.tcl

if {![file exists merged]} {
    exec mkdir merged
}

foreach file [glob pdfs/*.pdf] {
    #pdfs/precinct_2181007800_gunbarrel.pdf
    if {![regexp {.*precinct_(\d+).*} $file match id]} {
	puts stderr "Could not find precinct id: $file"
	continue;
    }
    set maps [glob -nocomplain maps/*${id}*.pdf]
    if {[llength $maps]==0} {
	exec cp $file merged
	puts stderr "No map file $map"
	continue
    }
    set map [lindex $maps 0]
    set fileName [file tail $file]
    puts stderr "Merging $map with $fileName"
    exec sh /Users/jeffmc/bin/pdfbox.sh  PDFMerger   "${map}" "$file" "merged/$fileName"

}
