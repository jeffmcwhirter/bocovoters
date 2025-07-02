set ::script_dir [file dirname [info script]]

if {![file exists json]} {
    exec mkdir json
}

if {![file exists pdf]} {
    exec mkdir pdf
}

package require json
proc readfile {f} {
    set fp [open $f r]
    set c [read $fp]
    close $fp
    return $c
}

proc fetch {id} {
    puts "folder:$id"
    set file "json/${id}.json"
    if {![file exists $file]} {
	puts stderr "downloading $file"
	catch {exec sh [file join $::script_dir getfolder.sh] $id $file} err
	if {![file exists $file]} {
	    puts stderr "Could not download folder info for: $id. Error: $err"
	    exit
	}	
    }



    set j [json::json2dict [readfile $file]]
    set data   [dict get  $j data]
    set results [dict get  $data results] 
    foreach item   $results {
	if {![dict exists $item entryId]} continue;
	set entryId [dict get $item entryId]
	set isEdoc [dict get $item isEdoc]
	if {$isEdoc=="true"} {
	    set name [dict get $item name]
	    puts "doc:$entryId name:$name"
	    regsub -all { +} $name {_} name
	    set pdf "pdf/$name.pdf"
	    if {![file exists $pdf]} {
		catch {exec sh [file join $::script_dir getdoc.sh] $entryId "$pdf"} err
	    }
	    if {![file exists $pdf]} {
		puts stderr "Could not download PDF info for: $entryId $name. Error: $err"
		exit
	    }	
	} else {
	    fetch $entryId
	}
    }	
}


#180916

foreach id $argv {
    fetch  $id
}

