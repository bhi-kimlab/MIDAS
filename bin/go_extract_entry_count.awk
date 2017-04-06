BEGIN{
	FS=OFS="\t";
}
FILENAME==ARGV[1]{
	entry=$3;
	gene=$1;

	if(entry in entry2Gene_arr){
		new_genes = entry2Gene_arr[entry]","gene;
		entry2Gene_arr[entry] = new_genes;
	}else{
		entry2Gene_arr[entry] = gene;
	};
	next;
}
FILENAME==ARGV[2]{
	gene=$1;
	go_id=$2;

	if(gene in gene_go_arr){
		gene_go_arr[gene] = gene_go_arr[gene]","go_id;
	}else{
		gene_go_arr[gene] = go_id;
	};
	next;
}
FILENAME==ARGV[3]{
	split($1, pathway_subpath, ",");
	pathway=pathway_subpath[1];
	subpath=pathway_subpath[2];

	m=split(subpath, edge_arr, "|");

	delete gene_save_arr;
	delete go_save_arr;
	delete entry_save_arr;

	for(i=1;i<=m;i++){
		split(edge_arr[i],entry_arr,"_");
		
		for(j=1;j<=2;j++){
			entry = pathway"|"entry_arr[j];
	
			if(!(entry in entry_save_arr)){
				entry_save_arr[entry]="";
			}else{
				continue;
			};
			delete temp_go_save_arr;

			gene_symbols = entry2Gene_arr[entry];
			gene_num = split(gene_symbols, gene_symbol_arr, ",");

			for(k=1;k<=gene_num;k++){
				gene_id = gene_symbol_arr[k];
				if(!(gene_id in gene_save_arr)){
					gene_save_arr[gene_id]="";
				};
				go_ids = gene_go_arr[gene_id];
				go_num = split(go_ids, go_id_arr, ",");
				
				for(l=1;l<=go_num;l++){
					go_id = go_id_arr[l];
					if(!(go_id in temp_go_save_arr)){
						temp_go_save_arr[go_id]=1;
					}else{
						temp_go_save_arr[go_id]=temp_go_save_arr[go_id]+1;
					};
				}
			};

			for(x in temp_go_save_arr){
				if(temp_go_save_arr[x] >= (gene_num/2)){
					if(x in go_save_arr){
						go_save_arr[x] = go_save_arr[x] + 1;
					}else{
						go_save_arr[x] =1;
					};
				}
			}
		}
	};

	delete go_sort_arr;
	max_count=0;
	for(x in go_save_arr){
		count = go_save_arr[x];
		if(!(count in go_sort_arr)){
			go_sort_arr[count]=x;
		}else{
			go_sort_arr[count]=go_sort_arr[count]","x;
		};
		if(max_count < count){
			max_count = count;
		};
	};

	printf "%s%s%s", $1, OFS, length(entry_save_arr);

	for(i=max_count;i>0;i--){
		if(i in go_sort_arr){
			m=split(go_sort_arr[i], go_print_arr, ",");
			for(j=1;j<=m;j++){
				printf "%s%s", OFS, i"/"go_print_arr[j];
			};
		};
	};
	printf "\n";

}
