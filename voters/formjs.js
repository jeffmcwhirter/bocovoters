let precincts = {
"2181007800":"Gunbarrel",
"2181007801":"Gunbarrel",
"2181007802":"Boulder",
"2181007803":"North Broadway - Holiday",
"2184907804":"Boulder",
"2184907805":"Wonderland Lake",
"2181007806":"Rural North Boulder",
"2181007807":"Rural North Boulder",
"2181007808":"Palo Park",
"2181007809":"Boulder",
"2181007810":"Glenwood Grove - North Iris",
"2181007811":"Winding Trail",
"2181007812":"Parkside",
"2181007813":"Melody Heights",
"2184907814":"Wonderland Hills",
"2184907815":"Newlands",
"2181007816":"Old North Boulder",
"2181007817":"Old North Boulder",
"2181007818":"Glenwood Grove - North Iris",
"2181007819":"Noble Park",
"2181007820":"Boulder",
"2181007821":"Old North Boulder",
"2181007822":"Whittier",
"2181007823":"Whittier",
"2181007824":"Downtown",
"2181007825":"Whittier",
"2181007826":"Mapleton Hill",
"2184907827":"Boulder",
"2184907828":"Lower Arapahoe",
"2181007829":"Lower Arapahoe",
"2181007830":"Flagstaff",
"2181007831":"University Hill",
"2181007832":"Boulder",
"2181007833":"Baseline Sub",
"2181007834":"Baseline Sub",
"2181007835":"Arapahoe Ridge",
"2181007836":"Arapahoe Ridge",
"2181007837":"Arapahoe Ridge",
"2181007838":"Meadow Glen",
"2181007839":"Park East",
"2181007840":"Frasier Meadows",
"2181007841":"Baseline Sub",
"2181007842":"Frasier Meadows",
"2181007843":"Martin Acres",
"2184907844":"Boulder",
"2184907845":"Highland Park",
"2181007846":"Martin Acres",
"2181007847":"Martin Acres",
"2181007848":"Keewayden",
"2181007849":"Keewayden",
"2181007850":"Martin Acres",
"2181007851":"Martin Acres",
"2184907852":"Table Mesa",
"2184907853":"Boulder",
"2184907854":"Boulder",
"2184907855":"Table Mesa",
"2184907856":"Table Mesa South",
"2184907857":"Devil's Thumb - Rolling Hill"
}

let textarea = $('textarea[name="search.db_boulder_county_voters.precinct"]');
textarea.parent().append("<br><div id=formjs_generate>Generate Precinct Printing Script</div>");
$("#formjs_generate").button().click(()=>{
    let sh  = "#!/bin/sh\n"
    sh+="#\n#this needs the CAPTUREPDF env variable set pointing to capturepdf.sh\n#or to be run in the same directory as the capturepdf.sh and capturepdf.scpt files\n#\n"
    sh +="export mydir=`dirname $0`\n";
    sh+="if [ -f \"${CAPTURE_PDF_PATH}/capturepdf.sh\" ]\nthen\n";
    sh +="\tcapturepdf=${CAPTURE_PDF_PATH}/capturepdf.sh\n"
    sh+="elif [ -f \"$mydir/capturepdf.sh\" ]\nthen\n";
    sh +="\tcapturepdf=$mydir/capturepdf.sh\n"
    sh+="else\n";
    sh+="\techo \"No capturepdf.sh defined\"\n";
    sh+="\texit\n";
    sh+="fi\n";

    let url = $("#formurl").val().trim();
    url = url.replace(/search.db_boulder_county_voters.precinct=[^&]+&/,"");
    url = url +"&forprint=true";
    let input = (textarea.val() ||"").trim();
    if(input=="") {
	alert('No precincts specified');
	return;
    }
    input.split("\n").forEach(line=>{
        line = line.trim();
	if(line=="") return;
	let name = precincts[line];
	let title = 'Precinct: ' + (name?name+ ' - ':'');
	let file='precinct_'+line;
	if(name) file+='_'+Utils.makeId(name);
	file+='.pdf';
	title = title +' '+ line;
	let _url = HtmlUtils.url(url,["searchname",title,"search.db_boulder_county_voters.precinct" ,line]);
	console.log(line,title,_url);
	sh  += 'sh ${capturepdf} "' + _url + '" ' + '"' + file+'"';  
	sh += '\n';
    });
    sh+="\n";
    Utils.makeDownloadFile("precincts.sh",sh);
});
