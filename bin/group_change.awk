BEGIN{
	FS=OFS="\t"
}
FILENAME==ARGV[1]{
	hash[$1]=$2;
	next
}
FILENAME==ARGV[2]{
	num=split($2,arr," ");
	if($1 in hash){
		printf "%s\t", hash[$1];
	}
	else{
		printf "%s\t", $1;
	};
	if(num > 0){
		for(i=1;i<=num;i++)
		{
			x = arr[i];
	
			printf "%s%s", (x in hash ? hash[x] : x), (i < num ? " " : ORS);
		};
	}
	else{
		printf "\n";
	}
}


	
