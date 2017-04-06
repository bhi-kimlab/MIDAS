BEGIN{
	FS=OFS="\t";
}
FILENAME==ARGV[1]{
	hash[$1]=$2;
	next;
}
FILENAME==ARGV[2]{
	if(FNR==1){
		next;
	}else{
		first=$1;
		second=$2;

		if(first in hash){
			first=hash[first];
		};

		if(second in hash){
			second=hash[second];
		};
		print first, second, $3;
	}
}
