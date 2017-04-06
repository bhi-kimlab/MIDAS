BEGIN{
	FS=OFS="\t";
}
FILENAME==ARGV[1]{
	if($3 in entry_gene_arr){
		entry_gene_arr[$3]=entry_gene_arr[$3]";"$1;
		entry_count_arr[$3]=entry_count_arr[$3]+1;
	}else{
		entry_gene_arr[$3]=$1;
		disp_entry_arr[$3]=$1;
		entry_count_arr[$3]=1;
	};
	next;
}
FILENAME==ARGV[2]{
	if($2 in group_dic){
		group_dic[$2]=group_dic[$2]";"$1;
	}else{
		group_dic[$2]=$1;
	};
	next;
}
FILENAME==ARGV[3]{
	if(FNR>1){
		rel_dic[$1]=$2;
	};
	next;
}
FILENAME==ARGV[4]{
	edge_info_dic[$1]=rel_dic[$2];
	next;
}
FILENAME==ARGV[5]{
	split($1, temp_pathway, ":");
	path_name_arr[temp_pathway[2]]=$2;
	next;
}
FILENAME==ARGV[6]{
	print "[Rank"FNR"]";

	split($1, pathway_subpath, ",");
	pathway = pathway_subpath[1];
	subpath = pathway_subpath[2];


	n = split(subpath, edge_arr, "|");

	id_subpath_str="";
	disp_subpath_str="";

	for(i=1;i<=n;i++){
		split(edge_arr[i], elem_arr, "_");

		for(j=1;j<=2;j++){
			entry = elem_arr[j];
			if(!(entry in entry_arr)){
				if(pathway"|"entry in group_dic){
					m=split(group_dic[pathway"|"entry], temp_group_arr, ";");
					save_str="";
					for(k=1;k<=m;k++){
						if(k==1){
							save_str = entry_gene_arr[temp_group_arr[k]];
							temp_disp_arr[entry]=disp_entry_arr[temp_group_arr[k]];
						}else{
							save_str = save_str" | "entry_gene_arr[temp_group_arr[k]];
							temp_disp_arr[entry]=temp_disp_arr[entry]"|"disp_entry_arr[temp_group_arr[k]];
						};
					};
					entry_arr[entry] = save_str;
				}else{
					entry_arr[entry] = entry_gene_arr[pathway"|"entry];
					temp_disp_arr[entry] = disp_entry_arr[pathway"|"entry];
				}
			};
		};
		arrow=(edge_info_dic[pathway"|"edge_arr[i]] == 1 ? "->" : "-|");

		id_subpath_str=id_subpath_str""elem_arr[1]""arrow""elem_arr[2]""(i<n ? " & " : "");
		disp_subpath_str=disp_subpath_str""temp_disp_arr[elem_arr[1]]""arrow""temp_disp_arr[elem_arr[2]]""(i<n ? " & " : "");
		
		delete elem_arr;
	};

	print "Subpath (encoded by Entry ID):";
	print id_subpath_str;
	print ;
	print "Subpath (encoded by KEGG Display GeneSymbol):";
	print disp_subpath_str;
	print ;
	for(x in entry_arr){
		m=split(entry_arr[x],temp_arr1," | ");
		for(i=1;i<=m;i++){
			n=split(temp_arr1[i], temp_arr2, ";");
			for(j=1;j<=n;j++){
				if(!(temp_arr2[j] in gene_count_arr)){
					gene_count_arr[temp_arr2[j]]="";
				};
			};
		};
	};
	
	print "Pathway: ", path_name_arr[pathway];	
	print "Size:", $2;
	print "Included Entry Number:", length(entry_arr);
	print "Included Gene Number:", length(gene_count_arr);
	print "Krustal-Wallis Static:", $3;
	print "Permuation P-value:", $4;
	printf "\n";
	print "<Annotation>"
	for(x in entry_arr){
		print x,":",entry_arr[x];
	};
	printf "\n";
	printf "\n";
	delete gene_count_arr;
	delete temp_disp_arr;
	delete entry_arr;
}
