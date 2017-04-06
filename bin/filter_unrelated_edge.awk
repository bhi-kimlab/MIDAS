BEGIN{
	FS=OFS="\t";
}
FILENAME==ARGV[1]{
	if(FNR >1){
		arr[$1]=$2;
	};
	next;
}
FILENAME==ARGV[2]{
	if(FNR > 1){
		if(arr[$3] == 0){
			print $1"_"$2;
		}
	};
	next;
}
