#!/bin/bash
bin_dir=`dirname $0`"/"

download_dir=$1
kegg_hsa_list=$2
NUM_CPUS=$3

# kgml file save directory
kgml_dir=$download_dir/kgml
mkdir -p $kgml_dir

pathway_id_list=(`awk 'BEGIN{FS=OFS="\t"}{if($1 ~/path:/){split($1,arr,":");print arr[2]}else{print $1}}' $kegg_hsa_list`)
pathway_name_list=(`cut -f2 $kegg_hsa_list`)

# download kgml files
for((i=0;i<${#pathway_id_list[@]};i++));do
	wget "http://rest.kegg.jp/get/"${pathway_id_list[$i]}"/kgml" -O $kgml_dir"/"${pathway_id_list[$i]}".xml"
done

# make graph
graph_dir=$download_dir/kegg_graph
mkdir -p $graph_dir

expand="FALSE"
expand_suffix="entry"

count=0
for((i=0;i<${#pathway_id_list[@]};i++));do
	{
	graph_result_dir=$graph_dir"/"${pathway_id_list[$i]}
	mkdir -p $graph_result_dir
	
	given_pathway=$kgml_dir"/"${pathway_id_list[$i]}".xml"
	echo "[Info] Convert Graph: "${pathway_id_list[$i]}"/"${pathway_name_list[$i]}"... ]"

	working_result_dir=$graph_result_dir"/"${expand_suffix}"/"
	mkdir -p $working_result_dir

	given_pathway_edge_info=$working_result_dir"/edge_info_table.txt"
	given_pathway_graph=$working_result_dir"/graph.txt"
	given_pathway_convert_table=$working_result_dir"/convert_table.txt"

	Rscript $bin_dir/kegg_graph_edge_info.R $given_pathway $given_pathway_edge_info $given_pathway_graph $given_pathway_convert_table $expand
	
	given_pathway_graph_group=$given_pathway_graph".group.txt"
	given_pathway_convert_table_group=$given_pathway_convert_table".group.txt"

	#parse group infomation form KGML file
	given_pathway_group_info=$working_result_dir"/entry_group_info.txt"
	bash $bin_dir"KGML_group_parse.sh" $given_pathway > $given_pathway_group_info
	group_flag=`wc -l \$given_pathway_group_info | cut -d' ' -f1`

	#apply group infomation to graph
	if [ $group_flag -ge 1 ]; then
		awk -f $bin_dir"group_change.awk" $given_pathway_group_info $given_pathway_graph > $given_pathway_graph_group".temp"
	else
		cp $given_pathway_graph $given_pathway_graph_group".temp"
	fi

	#filtering & remove duplicates nodes in the graph
	sort -k1,1 $given_pathway_graph_group".temp" | uniq | awk 'BEGIN{FS=OFS="\t";id="";val=""}{if(id==$1){if($2 != ""){if(val!=""){val=val" "$2}else{val=$2} }}else{if(id != ""){print id,val}; id=$1;val=$2}}END{print id,val}' > $given_pathway_graph_group".temp2"

	awk -f $bin_dir"graph_downstream_gene_rm_dup.awk" $given_pathway_graph_group".temp2" > $given_pathway_graph_group

	# Entry id table convert for Group
	graph_convert_file_group_converted=$graph_convert_file".group_converted"
	
	if [ $group_flag -ge 1 ]; then
		awk -f $bin_dir"group_change.awk.table.awk" $given_pathway_group_info $given_pathway_convert_table > $given_pathway_convert_table_group
	else
		cp $given_pathway_convert_table $given_pathway_convert_table_group
	fi

	# apply group to edge info
	if [ $group_flag -ge 1 ]; then
		echo -e "Entry1\tEntry2\tEdge" > $given_pathway_edge_info".group.txt"
		awk -f $bin_dir"group_change.awk.edge_info.awk" $given_pathway_group_info $given_pathway_edge_info | sort | uniq >> $given_pathway_edge_info".group.txt"
	else
		cp $given_pathway_edge_info $given_pathway_edge_info".group.txt"
	fi

	rm -rf $given_pathway_graph_group".temp" $given_pathway_graph_group".temp2"
			
	given_pathway_graph=$given_pathway_graph_group
	given_pathway_convert_table=$given_pathway_convert_table_group
	given_pathway_edge_info=$given_pathway_edge_info".group.txt"


	mv $given_pathway_convert_table $given_pathway_convert_table".temp"
	sort -k3,3 -k1,1 $given_pathway_convert_table".temp" | uniq > $given_pathway_convert_table
	rm -rf $given_pathway_convert_table".temp"

	}&
	let count+=1; [[ $((count%$NUM_CPUS)) -eq 0 ]] && wait

done;wait

