BEGIN{
	FS=OFS="\t";
}
FILENAME==ARGV[1]{
	go_term_arr[$1]=$2;
	go_domain_arr[$1]=$4;
	next;
}
FILENAME==ARGV[2]{
	split($1, temp_pathway, ":");
	path_name_arr[temp_pathway[2]]=$2;
	next;
}
FILENAME==ARGV[3]{
	entry_count = $2;
	threshold= entry_count/2;
	if(entry_count <= 2){
		threshold = 2;
	};

	split($1,pathway_subpath,",");

	print "[Rank"FNR"]"
	print "----------------------------------------------"
	print "Pathway :", path_name_arr[pathway_subpath[1]];
	print "Total Entry Count :", entry_count;
	print "----------------------------------------------"
	print "Count", "GO ID", "GO Term", "GO Domain";
	
	for(i=3;i<=NF;i++){
		split($(i), count_go_id, "/");
		temp_count = count_go_id[1];
		temp_go_id = count_go_id[2];

		if(temp_count >= threshold){
			print temp_count, temp_go_id, go_term_arr[temp_go_id], go_domain_arr[temp_go_id];
		}else{
			break
		}
	};
	printf "\n";
}

