function convert_id(num, dic, fix_str, index_str,pos, color, width,    i)
{	
	if(pos == 0){
		for(i=1;i<=num;i++){
			print fix_str"_"dic[index_str, i], color, width;
		}
	}
	else{
		for(i=1;i<=num;i++){
			print dic[index_str,i]"_"fix_str, color, width;
		}
	}
}


BEGIN{
	FS=OFS="\t";
}
FILENAME==ARGV[1]{
	if($2 in group_dic){
		my_index=group_dic_num[$2]+1;
		group_dic_num[$2]=my_index;
		group_change_dic[$2,my_index]=$1;
	}
	else{
		group_dic[$2]=$1;
		group_dic_num[$2]=1;
		group_change_dic[$2,1]=$1;
	};
	next;
}
FILENAME==ARGV[2]{
	if(FNR>1){
		if($1 in group_dic){
			if($2 in group_dic){
				num=group_dic_num[$1];
				for(i=1;i<=num;i++){
					fix_str=group_change_dic[$1,i];
					convert_id(group_dic_num[$2], group_change_dic, fix_str, $2, 0, $3, $4);
				};
			}
			else{
				convert_id(group_dic_num[$1], group_change_dic, $2, $1, 1, $3, $4)
			}
		}
		else{
			if($2 in group_dic){
				convert_id(group_dic_num[$2], group_change_dic, $1, $2, 0, $3,$4)
			}
			else{
				print $1"_"$2, $3, $4;
			}
		};
	}
	else
	{
		print "ID", "EdgeColor", "EdgeWidth";
	}
}

