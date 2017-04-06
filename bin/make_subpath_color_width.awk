BEGIN{
	FS=OFS="\t";
	num=split(colors, color_arr,","); 
	step=(width_start-width_end)/num;
} 
{ 
	split($1, pathway_subpath, ","); 
	pathway=pathway_subpath[1]; 
	subpath=pathway_subpath[2]; 
	cur_width=width_start-step*(NR-1); 
	cur_color=color_arr[NR]; 	
	n=split(subpath, subpath_arr, "|"); 
	
	for(i=1;i<=n;i++){
		split(subpath_arr[i], entry_arr, "_");
		print pathway, entry_arr[1], entry_arr[2], cur_color, cur_width;
	};
}
