BEGIN{
	FS=OFS="\t";
}
FNR == NR{
	hash[$1]=$2;
	next
}
FNR < NR{
	if($3 in hash){
		print $1,$2,hash[$3];
	}
	else{
		print $0;
	}
}
