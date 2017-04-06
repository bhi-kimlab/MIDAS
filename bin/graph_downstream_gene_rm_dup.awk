BEGIN{
	FS=OFS="\t";
}
{
	num=split($2, arr, " ");
	downs="";

	if(num > 0){
		for(i=1;i<=num;i++){
			if(!(arr[i] in arr2)){
				if(downs==""){
					downs=arr[i];
				}
				else{
					downs=downs" "arr[i];
				};
				arr2[arr[i]]="";
			};
			if(!(arr[i] in total_down_arr)){
				total_down_arr[arr[i]]="";
			}
		}
	}
	else{
		check_node_arr[$1]="";
	};
	delete arr;
	delete arr2;
	graph_arr[$1]=downs;
}
END{
	for(x in graph_arr){
		if(x in check_node_arr){
			if(!(x in total_down_arr)){
				continue
			}
		};
		downs=graph_arr[x];
		num=split(downs, down_arr, " ");
		if(num > 0){
			printf "%s%s", x, OFS;
			for(i=1;i<=num;i++){
				printf "%s%s", down_arr[i], (i < num ? " " : ORS);
			};
		}
		else{
			print x,"";
		}
	}
}
