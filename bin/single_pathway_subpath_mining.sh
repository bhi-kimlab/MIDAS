#!/bin/bash

###################################################
#Directories#
WORK_DIR=$1"/"
bin_dir=$WORK_DIR"/bin/"
lib_dir=$WORK_DIR"/lib/"
###################################################

###################################################
#Functions#
function my_join { local IFS="$1"; shift; echo "$*"; }
###################################################

###################################################
#Parameters#
top_output_dir=$2"/"
working_result_dir=$3"/"
given_pathway=$4
expression_file=$5
sample_info_file=$6
IFS=';' read -ra option_list <<< "$7"
start_threshold=${option_list[0]}
increase_moment=${option_list[1]}
pval_cut=${option_list[2]}
permutation_num=${option_list[3]}
parallel_cores=${option_list[4]}

#Internal parameters#
expand_gene_entry=FALSE
edge_weight_act_iht_ew=0
act_iht_method=0
edge_weight_file="temp"
###################################################


###################################################
#Sample Info Preparation#

#must be sorted by expression file order & class order
subtype_num_list=(`cut -f2 $sample_info_file | uniq -c | awk '{print $1}'`)
min_subtype_num=1000000
for((i=0;i<${#subtype_num_list[@]};i++)); do
	subtype_patients_num=${subtype_num_list[$i]}
	if [ $subtype_patients_num -lt $min_subtype_num ]; then
		min_subtype_num=$(($subtype_patients_num -1))
	fi
done

subtype_start_num_list=()
accum_start=2
for((i=0;i<${#subtype_num_list[@]};i++)); do
	subtype_start_num_list+=($accum_start)
	accum_start=$((accum_start+${subtype_num_list[$i]}))
done

subtype_list=(`cut -f2 $sample_info_file | uniq -c | awk '{print $2}'`)

###################################################


###################################################
# Pathway Preparation #

# given pathway
given_pathway_name=`basename $given_pathway ".xml"` # used as result directory name
expand=$expand_gene_entry

expand_suffix="gene"

if [ "$expand" = "FALSE" ]; then
	expand_suffix="entry"
fi

pathway_dir=$top_output_dir"/kegg_pathways/kegg_graph/"$given_pathway_name"/"$expand_suffix"/"

mkdir -p $working_result_dir"/"$given_pathway_name"/"
mkdir -p $working_result_dir"/"$given_pathway_name"/"$expand_suffix"/"
working_result_dir=$working_result_dir"/"$given_pathway_name"/"$expand_suffix"/"

##
# make graph & edge info & convert table
given_pathway_edge_info=$pathway_dir"/edge_info_table.txt"
given_pathway_graph=$pathway_dir"/graph.txt"
given_pathway_convert_table=$pathway_dir"/convert_table.txt"

##
# parse group entry & convert graph contents
given_pathway_graph_group=$given_pathway_graph".group.txt"
given_pathway_convert_table_group=$given_pathway_convert_table".group.txt"

if [ "$expand" = "FALSE" ]; then

	given_pathway_graph=$given_pathway_graph_group
	given_pathway_convert_table=$given_pathway_convert_table_group
	given_pathway_edge_info=$given_pathway_edge_info".group.txt"

fi

###################################################



## Apply Data
###########################################################################################################
########################## Edge Activity ###################################################################
###########################################################################################################

centrality_case=1
spia_edge_beta=$lib_dir"/spia_edge_info.txt"
edge_weight=$edge_weight_act_iht_ew

#expression to entry/gene
entry_expr_file=$working_result_dir"/Entry_exp_file.txt"

if [ "$expand" = "FALSE" ]; then
	python $bin_dir"Gene_expr_To_Entry_ID_whole.py" $given_pathway_convert_table $expression_file $entry_expr_file
else
	python $bin_dir"Gene_expr_To_KEGG_ID_whole.py" $given_pathway_convert_table $expression_file $entry_expr_file
fi

#make maxmimum entry file
max_entry_expr_file=$working_result_dir"/Max_Entry_expr_file.txt"
awk 'BEGIN{FS=OFS="\t"}{max_val=0.0; for(i=2;i<=NF;i++){if($(i)>=max_val){max_val=$(i)}};print $1,max_val}' $entry_expr_file > $max_entry_expr_file

#edge activity output_file
Edge_act_MGD=$working_result_dir"/Edge_act.txt"
#calc edge activity
python $bin_dir"/calc_edge_activity.py" $given_pathway_graph $entry_expr_file $max_entry_expr_file $given_pathway_edge_info $spia_edge_beta $edge_weight $edge_weight_file $centrality_case $act_iht_method $Edge_act_MGD $sample_info_file $parallel_cores 

# filter unrelated edges(ex. binding)
filter_candi_edges=$working_result_dir"/filter_candi_edges.txt"
awk -f $bin_dir/filter_unrelated_edge.awk $spia_edge_beta $given_pathway_edge_info > $filter_candi_edges

#merged file 
Edge_act_MGD=$working_result_dir"/Edge_act.txt.act_iht_result.txt.MGD"

Edge_act_MGD_fiter_edge=$Edge_act_MGD".filtered"
grep -f $filter_candi_edges -v $Edge_act_MGD > $Edge_act_MGD_fiter_edge

###################################################


###################################################
# Subpath mining #
#################################
# kruskal test ########################
#################################
kruskal_dir=$working_result_dir"/subpath_mining/"
mkdir -p $kruskal_dir

subpath_mining_result=$kruskal_dir"/Subpath_mining_result.txt"

class_num_info=`my_join "," ${subtype_num_list[@]}`

#subpath mining by kruskal wallis test
python $bin_dir/kruskal_subpath_mining_ver_pac_1.py $given_pathway_graph $filter_candi_edges $Edge_act_MGD_fiter_edge $class_num_info $start_threshold $increase_moment > $subpath_mining_result

subpath_activity=$kruskal_dir"Subpath_act_whole.txt"

# make null dist
subpath_mining_result_perm=$subpath_mining_result".perm_revised.txt"
selected_size_list=(`cut -f1 $subpath_mining_result | sort -k1,1g | uniq`)
python $bin_dir/kruskal_perm_subpath_parallel.py $Edge_act_MGD_fiter_edge $class_num_info `my_join "," ${selected_size_list[@]}` $subpath_mining_result $permutation_num | sort -k4,4g -k3,3gr > $subpath_mining_result_perm

# for whole
Rscript $bin_dir/train_test_ch2_arff_new.R $Edge_act_MGD_fiter_edge `my_join "," ${subtype_list[@]}` $class_num_info $subpath_mining_result_perm $subpath_activity

###################################################
