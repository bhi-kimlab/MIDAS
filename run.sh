#!/bin/bash

###################
### Directories ###
###################
working_dir=`dirname $0`"/"
bin_dir=$working_dir/bin
lib_dir=$working_dir/lib


#############################
### The command line help ###
#############################

display_help(){
	echo "usage: run.sh [-h] [--expression EXPRESSION] [--pathway_set PATHWAY_SET]
		[--class_info CLASS_INFO_FILE] [--output_directory OUTPUT_DIRECTORY]
		[--start_threshold START_THRESHOLD] [--increase_moment INCREASE_MOMENT]
		[--permutation_number PERMUTATION_NUM] [--permutation_cutoff PERMUTATION_CUTOFF]
		[--parallel_cores PARALLEL_CORES] [--sorting]"
	echo ""
	echo "optional arguments:
		-h, --help
				show this help message and exit
		-e, --expression EXPRESSION
				RNA-seq gene expression data matrix file. Row is gene and Column is Sample (header is required.).
				First column is gene name. Second to last columns are expression level.
				Column must be sorted by class. If not, please add --sorting option.
		-s, --pathway_set PATHWAY_SET
				A file that contains user given pathway list. If this option is not set, 
				  default pathway list (e.g. all KEGG pathway withoug metabolism and drug) is used.
				It contains two columns: KEGG_PATHWAY_ID [TAB] Pathway_Name.
		-c, --class_info CLASS_INFO_FILE
				A file that contains class information of samples in the EXPRESSION (no header is required.).
				It contains two columns: Sample_id [TAB] Class.
				The order of sample's class information must be matched with the order of column in the EXPRESSION.
		-o, --output_directory
				Output directory for saving results.
		-t, --start_threshold START_THRESHOLD
				The threshold used to expand subpath. Initial threshold is set to START_THRESHOLD (Default: 0.05).
		-m, --increase_moment INCREASE_MOMENT
				The exponentail decaying term for tightening the threshold used to expand subpath.
				If this option is not set, INCREASE_MOMENT is autumatically determined in the process.
		-p, --permutation_cutoff PERMUTATION_CUTOFF
				The cutoff value used for permutation test. Default is 0.1.
		-b, --permutation_number PERMUTATION_NUM
				The number of permutation step to make null distribution. Default is 10,000.
		-n, --parallel_cores PARALLEL_CORES
				The number of cores used to parallel computing. Default is 1.
		--sorting
				If input data (EXPRESSION and CLASS_INFO_FILE) is not sorted by class, please add --sorting option."

		exit
}

##########################
### Default Parameters ###
##########################
EXPRESSION="NA" 
CLASS_INFO_FILE="NA" # A file that contains class information in the expression file
PATHWAY_SET="NA" # A file that contains user given pathway list
START_THRESHOLD=0.05 # Start threshold to test subpath's different activity among classes initially.
INCREASE_MOMENT="NA" # Exponential decaying term that is multiplied to the start_threshold when the subpath is expanded. 
PERMUTATION_CUTOFF=0.1 # Permutaiton Pvalue Cut-off
PERMUTATION_NUM=10000 # Permutation number
PARALLEL_CORES=1 # Number of cores for parallel computing
OUTPUT_DIRECTORY="NA"
SORTING=FALSE

################
### Function ###
################
function my_join { local IFS="$1"; shift; echo "$*";}


# Paramter Parsing
while [[ $# -ge 1 ]]
do
	key="$1"
	
	case $key in
    	-e|--expression)
	    	EXPRESSION="$2"
		    shift # past argument
			;;
	    -s|--pathway_set)
			PATHWAY_SET="$2"
			shift # past argument
			;;
		-t|--start_threshold)
			START_THRESHOLD="$2"
			shift # past argument
			;;
		-c|--class_info)
			CLASS_INFO_FILE="$2"
			shift # past argument
			;;
		-m|--increase_moment)
			INCREASE_MOMENT="$2"
			shift # past argument
			;;
		-p|--permutation_cutoff)
			PERMUTATION_CUTOFF="$2"
			shift # past argument
			;;
		-b|--permutation_number)
			PERMUTATION_NUM="$2"
			shift # past argument
			;;
		-n|--parallel_cores)
			PARALLEL_CORES="$2"
			shift # past argument
			;;
		-o|--output_directory)
			OUTPUT_DIRECTORY="$2"
			shift # past argument
			;;
		--sorting)
			SORTING=TRUE;
			;;
		-h|--help)
			display_help
			;;
		*)
			# unknown option
			echo  "Unknown parameter:" $1 $2
			echo ""
			display_help
		;;
	esac
	
	shift # past argument or value
done


# Input check
if [ ${EXPRESSION} == "NA" ] || [ ${OUTPUT_DIRECTORY} == "NA" ] ; then
	echo "[Warning!] Expression data and Output directory must be provided to MIDAS."
	echo ""
	display_help
fi

mkdir -p ${OUTPUT_DIRECTORY} 

if [ ${PATHWAY_SET} == "NA" ] ; then
	echo "[Info] Pathway list is not given."
	echo "[Info] Default pathway list is used to analysis."
	echo "[Info] Default pathways: All KEGG pathways without metabolism and drug."

	PATHWAY_SET=$lib_dir/default_pathway_list.txt
fi

# sample number check
if [ `awk 'BEGIN{FS=OFS="\t"}{print NF-1;exit}' ${EXPRESSION}` != `wc -l ${CLASS_INFO_FILE} | cut -d' ' -f1` ] ; then
	echo "[Error] The number of samples in EXPRESSION and that of class information is not same."
	echo "[Error] Please check input data and parameter options. Using -h/--help option."
	exit
fi

# sample order check
if [ `diff <(awk 'BEGIN{FS=OFS="\t"}{for(i=2;i<=NF;i++){print $(i);};exit}' ${EXPRESSION}) <(cut -f1 ${CLASS_INFO_FILE}) | wc -l | cut -d' ' -f1` != "0" ] ; then
	echo "[Info] Expression data order and Class data order is not matched"
	echo "[Info] --soritng option is enforced"
	SORTING=TRUE
fi

# sorting check
if [ ${SORTING} != "TRUE" ] && [ `diff <(cut -f2 ${CLASS_INFO_FILE} | sort) <(cut -f2 ${CLASS_INFO_FILE}) | wc -l | cut -d' ' -f1` != "0" ] ; then
	echo "[Info] Input data is not sorted"
	echo "[Info] --sorting option is enforced"
	SORTING=TRUE
fi

# Sorting is required
if [ ${SORTING} == "TRUE" ] ; then
	echo "[Info] Sorting process is started ..."

	EXPRESSION_unsorted=${EXPRESSION}
	CLASS_INFO_FILE_unsorted=${CLASS_INFO_FILE}

	input_data_sorted=${OUTPUT_DIRECTORY}"/input_data_sorted/"
	mkdir -p $input_data_sorted

	CLASS_INFO_FILE=$input_data_sorted"/class_info.txt"
	sort -k2,2 ${CLASS_INFO_FILE_unsorted} > ${CLASS_INFO_FILE}

	EXPRESSION=$input_data_sorted"/input_expression.txt"
	awk -f $bin_dir/sample_sorting.awk ${CLASS_INFO_FILE_unsorted} ${CLASS_INFO_FILE} ${EXPRESSION_unsorted} > ${EXPRESSION}
fi

# calculate increase moment
if [ ${INCREASE_MOMENT} == "NA" ] ; then
	echo "[Info] Increase_moment is not given."
	echo "[Info] Automatically determined by class number ans sample number"

	each_gene_pval_list=${OUTPUT_DIRECTORY}"/temp_gene_pval_list.txt"
	class_num_list=(`cut -f2 ${CLASS_INFO_FILE} | uniq -c | cut -f1`)
	python $bin_dir/calc_increase_moment.py ${EXPRESSION} `my_join "," ${class_num_list[@]}` 0.05 ${PARALLEL_CORES} $each_gene_pval_list 'fdr_bh' 0
	
	total_num=`wc -l $each_gene_pval_list | cut -d' ' -f1`
	INCREASE_MOMENT=`awk -v total_num 'BEGIN{FS=OFS="\t";select_num=int(total_num*0.25);}{if(FNR==select_num){cut_val=$1;exit}}END{increase_moment=1.0;while(1){if(increase_moment < cut_val){print increase_moment;exit}else{increase_moment=increase_moment*0.1}}}' <(awk 'BEGIN{FS=OFS="\t"}{if($1 == "nan"){print 1.0;}else{print $1}}' $each_gene_pval_list | sort -k1,1g)`

	rm -rf $each_gene_pval_list
fi

echo "[Info] Setting Parameters"
echo "[Info] Input expression data: " ${EXPRESSION}
echo "[Info] Class information: " ${CLASS_INFO_FILE}
echo "[Info] User given pathway set: " ${PATHWAY_SET}
echo "[Info] Start_threshold: " ${START_THRESHOLD}
echo "[Info] Increase_moment: " ${INCREASE_MOMENT}
echo "[Info] Permutation Number: " ${PERMUTATION_NUM}
echo "[Info] Permutation Cutoff: " ${PERMUTATION_CUTOFF}
echo "[INfo] Parallel Cores: " ${PARALLEL_CORES}


#############################
######## Start MIDAS ########
#############################

echo "----------------------------------------------------------------------------"

# Load user given pathway list
user_given_pathway_list=(`cut -f1 ${PATHWAY_SET} | sed -e 's/path://'`)
pathway_name_list=(`cut -f2 ${PATHWAY_SET}`)

echo "[Info] Target Pathways: ${user_given_pathway_list[@]}"
echo "[Info] The number of target pathways: " ${#user_given_pathway_list[@]}
echo "[Info] Download KEGG pathway files."
echo "[Info] Start the conversion process from a single pathway to a directed graph ..."
echo "[Info] Error will be occured due to GeneSymbol convertion of included pathways in the target pathway."
echo "[Info] Included pathways cannot be converted GeneSymbol. So \"Error in FUN(X[[i]], ...) : subscript out of bounds\" is printed. Don't worry!!!"

kegg_download_dir=${OUTPUT_DIRECTORY}"/kegg_pathways/"
bash $bin_dir/kegg_kgml_download.sh $kegg_download_dir ${PATHWAY_SET} ${PARALLEL_CORES}
echo "[Info] Done."


#####################################
### Single pathway subpath mining ###
#####################################
echo "----------------------------------------------------------------------------"
echo "[Info] Calculate edge activty & determine differentially activated subpaths"

# determine subpaths in each pathway from given pathway list
single_pathway_result_dir=${OUTPUT_DIRECTORY}"/single_pathway_analysis/"
mkdir -p $single_pathway_result_dir


for((i=0;i<${#user_given_pathway_list[@]};i++)); do
	echo "[Info] Target Pathway: " ${user_given_pathway_list[$i]}"/"${pathway_name_list[$i]}
	bash $bin_dir/single_pathway_subpath_mining.sh  $working_dir ${OUTPUT_DIRECTORY} $single_pathway_result_dir ${user_given_pathway_list[$i]}".xml" ${EXPRESSION} ${CLASS_INFO_FILE} ${START_THRESHOLD}";"${INCREASE_MOMENT}";"${PERMUTATION_CUTOFF}";"${PERMUTATION_NUM}";"${PARALLEL_CORES}
	echo "[Info] Done."
done

###########################################
### Total Pathway analysis for subpaths ###
###########################################
# whole data set analysis#
expand_gene_entry="FALSE"
expand_suffix="entry"

pack_result_dir=${OUTPUT_DIRECTORY}"/Summary_result/"
mkdir -p $pack_result_dir

subpaths_MGD=$pack_result_dir"Subpath_Merged_result.txt"

echo "----------------------------------------------------------------------------"
echo "[Info] Summarize subpath mining results of each pathway ..."
subpath_activity_list=()
for((i=0;i<${#user_given_pathway_list[@]};i++));do
	pathway_result_dir=$single_pathway_result_dir"/"${user_given_pathway_list[$i]}"/"$expand_suffix"/"
	kruskal_dir=$pathway_result_dir"/subpath_mining/"
	
	subpath_mining_result=$kruskal_dir"/Subpath_mining_result.txt"
	subpath_mining_result_perm=$subpath_mining_result".perm_revised.txt"
		
	while IFS='' read -r line || [[ -n "$line" ]]; do
		echo ${pathway_name_list[$i]}","$line >> $subpaths_MGD".temp"
	done < $subpath_mining_result_perm

	subpath_activity_data=$kruskal_dir"Subpath_act_whole.txt"
		
	subpath_activity_list+=($subpath_activity_data)
done

rm -rf $subpaths_MGD
echo -e "Subpath\tSubpath_length\tKruskal_Wallis_statistic\tPermutation_p_vale" > $subpaths_MGD
cat $subpaths_MGD".temp" | tr ' ' '\t' | sort -k4,4g -k3,3gr | cut -f5 --complement >> $subpaths_MGD

subpath_order_list=(`awk -f $bin_dir/subpath_order_id.awk $subpaths_MGD".temp" $subpaths_MGD`)

# make merged subpath activity file
subpath_act_whole_MGD=$pack_result_dir"Subpath_activity_Merged_whole_result.txt"

paste -d ',' ${subpath_activity_list[@]}  > $subpath_act_whole_MGD".temp"

awk -v sample_order=`my_join "," ${subpath_order_list[@]}` -f $bin_dir/subpath_act_whole_column_reorder.awk $subpath_act_whole_MGD".temp" > $subpath_act_whole_MGD

# remove temp files
rm -rf $subpaths_MGD".temp" $subpath_act_whole_MGD".temp"

echo "[Info] Done."

# determine significant subpaths
echo "[Info] Determine significant subpaths ..."

total_subpath_num=`wc -l $subpaths_MGD | cut -d' ' -f1`
pval_cut_num=`awk -v threshold=${PERMUTATION_CUTOFF} 'BEGIN{FS=OFS="\t"}{if(FNR>1){if($4 < threshold){print $0}else{exit}}else{print $0}}' $subpaths_MGD | tee $subpaths_MGD".significant.txt" | wc -l | cut -d' ' -f1`

echo "[Info] MIDAS determine "$(($pval_cut_num-1)) "subpaths."
echo "[Info] Results are saved in "$subpaths_MGD".significant.txt"


##########################
### subpath annotation ###
##########################

#prepare files for subpath annotation
Merged_Entry_Gene_file=$pack_result_dir"MGD_convert_table.txt"
rm -rf $Merged_Entry_Gene_file

entry_file_suffix=".txt"
if [ "$expand_gene_entry" = "FALSE" ]; then
	entry_file_suffix=".txt.group.txt"
fi

for((i=0;i<${#user_given_pathway_list[@]};i++));do
	pathway_dir=${OUTPUT_DIRECTORY}"/kegg_pathways/kegg_graph/${user_given_pathway_list[$i]}/"$expand_suffix"/"
	entry_file=$pathway_dir"convert_table"$entry_file_suffix
		
	if [ "$expand_gene_entry" = "FALSE" ]; then
		awk -v pathway_name=${pathway_name_list[$i]} 'BEGIN{FS=OFS="\t"}{print $1,$2, pathway_name"|"$3}' $entry_file >> $Merged_Entry_Gene_file
	else
		awk -v pathway_name=${pathway_name_list[$i]} 'BEGIN{FS=OFS="\t"}{print $1,$3, pathway_name"|hsa:"$2}' $entry_file >> $Merged_Entry_Gene_file
	fi
done

total_edge_file=$pack_result_dir"/total_edge_info.txt"
rm -rf $total_edge_file
each_edge_info_file="edge_info_table.txt"

if [ "$expand_gene_entry" = "FALSE" ]; then
	each_edge_info_file="edge_info_table.txt.group.txt"
fi

for((i=0;i<${#user_given_pathway_list[@]};i++));do

	pathway_dir=${OUTPUT_DIRECTORY}"/kegg_pathways/kegg_graph/${user_given_pathway_list[$i]}/"$expand_suffix"/"
	
	temp_edge_info_file=$pathway_dir"/"$each_edge_info_file
	
	awk -v pathway=${pathway_name_list[$i]} 'BEGIN{FS=OFS="\t"}{if(FNR>1){print pathway"|"$1"_"$2, $3}}' $temp_edge_info_file >> $total_edge_file

done

entry_group_info="entry_group_info.txt"

total_entry_group_info=$pack_result_dir"/total_entry_group_info.txt"
rm -rf $total_entry_group_info

convert_table_no_group_MGD=$pack_result_dir"/MGD_convert_table_no_group.txt"

rm -rf $convert_table_no_group_MGD

for((i=0;i<${#user_given_pathway_list[@]};i++));do
	pathway_dir=${OUTPUT_DIRECTORY}"/kegg_pathways/kegg_graph/${user_given_pathway_list[$i]}/"$expand_suffix"/"

	awk -v pathway=${pathway_name_list[$i]} 'BEGIN{FS=OFS="\t"}{print pathway"|"$1, pathway"|"$2}' $pathway_dir"/"$entry_group_info >> $total_entry_group_info

	awk -v pathway=${pathway_name_list[$i]} 'BEGIN{FS=OFS="\t"}{print $1,$2, pathway"|"$3}' $pathway_dir"/convert_table.txt" >> $convert_table_no_group_MGD
done

# selected pathway annotation
echo "[Info] Significant subpaths annotation is saved in" $subpaths_MGD".significant.annotation.txt"
awk -f $bin_dir/subpath_annotation.awk <(sort -k3,3 -k1,1 $convert_table_no_group_MGD | uniq) <(sort -k2,2 -k1,1 $total_entry_group_info | uniq) $lib_dir/spia_edge_info.txt $total_edge_file ${PATHWAY_SET} <(tail -n+2 $subpaths_MGD".significant.txt") > $subpaths_MGD".significant.annotation.txt"



# GO term analysis
echo "[Info] Perfome GO term analysis for selected subpaths"
echo "[Info] Go terms of significatn subpaths are saved in" $subpaths_MGD".significant.txt.GO_analysis.txt"
#GO analysis
awk -f $bin_dir/go_extract_entry_count.awk $Merged_Entry_Gene_file $lib_dir/HGNC_GeneSymbol_GO_ID.txt <(tail -n+2 $subpaths_MGD".significant.txt") > $subpaths_MGD".significant.txt.GO_count.txt"

awk -f $bin_dir/go_explain.awk $lib_dir/GO_content.txt ${PATHWAY_SET} $subpaths_MGD".significant.txt.GO_count.txt" > $subpaths_MGD".significant.txt.GO_analysis.txt"

rm -rf $subpaths_MGD".significant.txt.GO_count.txt"



echo "[Info] Make input for subpath visualization using Cytoscape"
#pval cut color 
color_codes=(`python $bin_dir/color_gradient.py 'gist_rainbow' $(($pval_cut_num-1))`)

subpaths_MGD_pval_cut_for_cytoscape=$subpaths_MGD".significant.for_cytoscape.txt"

tail -n+2  $subpaths_MGD".significant.txt" | awk -v colors=`my_join "," ${color_codes[@]}` -v width_start=5.0 -v width_end=2.0 -f $bin_dir/make_subpath_color_width.awk > $subpaths_MGD_pval_cut_for_cytoscape

cytoscape_dir=$pack_result_dir"/cytoscape/"
mkdir -p $cytoscape_dir

networkx_dir=$pack_result_dir"/networkx_figure/"
mkdir -p $networkx_dir

for((i=0;i<${#user_given_pathway_list[@]};i++));do
	pathway_result_dir=$single_pathway_result_dir"/"${user_given_pathway_list[$i]}"/"$expand_suffix"/"
	pathway_dir=${OUTPUT_DIRECTORY}"/kegg_pathways/kegg_graph/${user_given_pathway_list[$i]}/"$expand_suffix"/"
	kgml_dir=${OUTPUT_DIRECTORY}"/kegg_pathways/kgml/"

	awk 'BEGIN{FS=OFS="\t"; print "Entry1", "Entry2", "EdgeColor", "EdgeWidth";}
	FILENAME==ARGV[1]{
		arr[$1"_"$2]=$3","$4;
		next;
	}
	FILENAME==ARGV[2]{
		if(FNR>1){
		if($1"_"$2 in arr){
			split(arr[$1"_"$2], sub_arr,",");
			print $1,$2, sub_arr[1],sub_arr[2];
		}
		else{
			print $0;
		}
		}
	}' <(awk -v pathway=${pathway_name_list[$i]} 'BEGIN{FS=OFS="\t"}{if($1==pathway){print $2,$3,$4,$5}}' $subpaths_MGD_pval_cut_for_cytoscape) <(cut -f1 $pathway_result_dir/Edge_act.txt.act_iht_result.txt.MGD.filtered | awk 'BEGIN{FS=OFS="\t"}{split($1,arr,"_");print arr[1],arr[2],"#000000",1.0}') > $pack_result_dir"/"${user_given_pathway_list[$i]}"_for_cytoscape.txt"
	
	awk 'BEGIN{FS=OFS="\t"}{if(FNR==1){print "EdgeID", "EdgeColor", "EdgeWidth"}else{print $1"_"$2, $3,$4}}' $pack_result_dir"/"${user_given_pathway_list[$i]}"_for_cytoscape.txt" > $networkx_dir"/"${user_given_pathway_list[$i]}"_for_networkx.txt"

	if [ "$expand_gene_entry" = "FALSE" ]; then	
		awk -f $bin_dir/group_to_entry_ver_id.awk $pathway_dir"/entry_group_info.txt" $pack_result_dir"/"${user_given_pathway_list[$i]}"_for_cytoscape.txt" > $cytoscape_dir"/"${user_given_pathway_list[$i]}"_for_cytoscape.txt.no_group.txt"
	else
		mv $pack_result_dir"/"${user_given_pathway_list[$i]}"_for_cytoscape.txt" $cytoscape_dir"/"${user_given_pathway_list[$i]}"_for_cytoscape.txt.no_group.txt"
	fi
	rm -rf  $pack_result_dir"/"${user_given_pathway_list[$i]}"_for_cytoscape.txt"


	networkx_input=$networkx_dir"/"${user_given_pathway_list[$i]}"_for_networkx.txt"
	networkx_output=$networkx_dir"/"${user_given_pathway_list[$i]}

	#draw subpath figures // Warning! These figures are not good quality.
	python $bin_dir/plot_networkx_KEGG.py $kgml_dir"/"${user_given_pathway_list[$i]}".xml" $networkx_input $lib_dir/spia_edge_info.txt $pathway_dir"/edge_info_table.txt.group.txt" $networkx_output  ${pathway_name_list[$i]}

done

rm -rf $subpaths_MGD_pval_cut_for_cytoscape

echo "[Info] Summarize subpath activity by class: mean value & mean-rank value."
#mean table
Rscript $bin_dir/whole_act_mean_table.R $subpath_act_whole_MGD $subpath_act_whole_MGD".mean_table.txt" $subpath_act_whole_MGD".mean_rank_table.txt"

head -n $(($pval_cut_num -1)) $subpath_act_whole_MGD".mean_table.txt" > $subpath_act_whole_MGD".mean_table.txt.significant.txt"
head -n $(($pval_cut_num -1)) $subpath_act_whole_MGD".mean_rank_table.txt" > $subpath_act_whole_MGD".mean_rank_table.txt.significant.txt"

rm -rf $total_entry_group_info $total_edge_file $Merged_Entry_Gene_file $convert_table_no_group_MGD
