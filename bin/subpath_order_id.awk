BEGIN{
	FS=" "; OFS="\t";
	pathway_name="";
	my_index=0;
}
FILENAME==ARGV[1]{
	split($1, path_subpath_arr, ",");
	cur_pathway_name=path_subpath_arr[1];
	if(cur_pathway_name != pathway_name){
		my_index=my_index+1;
		pathway_name = cur_pathway_name
	};
	subpath_order_arr[$1]=my_index;
	my_index=my_index+1;
	next;
}
FILENAME==ARGV[2]{
	print subpath_order_arr[$1];
	next;
}

