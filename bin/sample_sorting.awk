BEGIN{
	FS=OFS="\t";
}
FILENAME==ARGV[1]{
	sample_id_unsorted_arr[$1]=FNR;
	next;
}
FILENAME==ARGV[2]{
	sample_id_sorted_arr[FNR] = sample_id_unsorted_arr[$1];
	next;
}
FILENAME==ARGV[3]{
	printf "%s%s", $1, OFS;
	for(i=1;i<NF;i++){
		printf "%s%s", $(sample_id_sorted_arr[i]+1), (i < NF-1 ? OFS : ORS);
	};
}
