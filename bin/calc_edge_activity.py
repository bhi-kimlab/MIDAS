import networkx as nx
import sys
import csv
import matplotlib.pyplot as plt
from graph_node import Graph_node
from centrality import calc_centrality
from calc_edge_act_parallel import *

def dic_return(temp_dic, temp_key):
	result=0.0

	if temp_key in temp_dic:
		result= temp_dic[temp_key]
	else:
		result= 0.0

	return result

######################################################################
### Main part ###############
######################################################################

#arg1 : graph input file
#arg2 : expr data
#arg3 : max_exp file
#arg4 : edge info file
#arg5 : used edge status file from SPIA
#arg6 : edge weight (1 : file / 0 : no weight) (1 : ew / 0 : act_iht)
#arg7 : edge weight file (only when arg6 ==1)
#arg8 : centrality case (0 : betweeness / 1: close)
#arg9 : act_iht case (0 : A(1-B) / 1: max(A(1-B), (1-A)B))
#arg10 : edge weight output file
#arg11 : pa_id & subtype file (Pa1 c1 \n Pa2 c2)
#arg12 : pathway sas mean result file

with open(sys.argv[1], 'r') as graph_input:
	reader = csv.reader(graph_input, delimiter="\t")


	graph_dic = {}

#	print "[INFO] Make graph ..."

	for row in reader:
		s = row[0]
		t = row[1]

		graph_dic[s] = t


	#expr data read
	expr_dic = {}

	expr_file = open(sys.argv[2], 'r')

	expr_file_reader = csv.reader(expr_file, delimiter="\t")
	
	sample_num = 0

	#save expr data
	for row in expr_file_reader:
		id = str(row[0])
		val = map(float, row[1:])
		sample_num = len(val)

		expr_dic[id] = val
	
	# max_expr dic
	max_expr_dic= {}

	max_expr_file = open(sys.argv[3], 'r')
	max_expr_file_reader = csv.reader(max_expr_file, delimiter="\t")


	for row in max_expr_file_reader:
		id = str(row[0])
		val = float(row[1])

		max_expr_dic[id]=val


	#edge info file read
	edge_info_dic = {}
	
	edge_info_file = open(sys.argv[4], 'r')

	edge_info_reader = csv.reader(edge_info_file, delimiter="\t")

	next(edge_info_reader)

	for row in edge_info_reader:
		entry1 = str(row[0])
		entry2 = str(row[1])
		status = str(row[2]) #activation, inhibition, and so on

		edge_id = entry1 + "_" + entry2

		edge_info_dic[edge_id] = status

	edge_info_file.close()

	#act_iht filter from SPIA
	act_iht_filter_dic ={}
	act_iht_filter_file = open(sys.argv[5], 'r')
	act_iht_filter_reader = csv.reader(act_iht_filter_file, delimiter="\t")

	next(act_iht_filter_reader)

	for row in act_iht_filter_reader : 
		rel = str(row[0])
		beta = int(row[1])

		act_iht_filter_dic[rel]=beta

	act_iht_filter_file.close()


	# edge weight 
	edge_weight_case = int(sys.argv[6])

	edge_weight_dic={}

	if edge_weight_case == 1 :
		edge_weight_file = open(sys.argv[7], 'r')
		edge_weight_reader = csv.reader(edge_weight_file, delimiter="\t")

		for row in edge_weight_reader :
			id = str(row[0])
			val = float(row[1])
			
			edge_weight_dic[id] =val
	
	# class Graph_node Flow network
	flow_graph_dic={}	

	for key in graph_dic:
		t = graph_dic[key].split(" ")

		if t[0] != "" :
			cur_node = Graph_node("temp", 0)

			if not key in flow_graph_dic:
				cur_node_exp_level = dic_return(expr_dic,key)
				cur_node = Graph_node(key, cur_node_exp_level)
			else:
				cur_node = flow_graph_dic[key]

			for elem in t:
				down_node = Graph_node("temp", 0)

				if elem in flow_graph_dic:
					down_node = flow_graph_dic[elem]
				else:
					down_node_exp_level = dic_return(expr_dic,elem)
					down_node = Graph_node(elem, down_node_exp_level)

				cur_node.add_out_node(elem)
				down_node.add_in_node(key)
				
				flow_graph_dic[key] = cur_node
				flow_graph_dic[elem] = down_node

	# centrality 
	centrality_case = int(sys.argv[8])
	centrality_dic = calc_centrality(graph_dic, centrality_case)

	# act_iht method
	act_iht_case = int(sys.argv[9])

	# parallel cores
	p_cores = int(sys.argv[12])

	# calc edge activity
	(total_SAS_mean_results, edge_activity_dic) = calc_edge_activity_whole(flow_graph_dic, centrality_dic, edge_info_dic, act_iht_filter_dic,max_expr_dic, edge_weight_case, edge_weight_dic, act_iht_case, sample_num, p_cores)


	#uni  & act_iht output
	#uni_result_output_file=sys.argv[10] + ".uni_result.txt.MGD"
	act_iht_result_output_file=sys.argv[10] + ".act_iht_result.txt.MGD"

	#uni_result_output = open(uni_result_output_file, 'w')
	act_iht_result_output = open(act_iht_result_output_file, 'w')


	#pa_info_file
	pa_info_file = open(sys.argv[11], 'r')

	pa_info_reader = csv.reader(pa_info_file, delimiter="\t")

	pa_id_list = []
	subtype_list = []

	for row in pa_info_reader:
		pa_id = str(row[0])
		subtype = str(row[1])
		
		pa_id_list.append(pa_id)
		subtype_list.append(subtype)

	#header line
	header_line = "Edge_id" + "\t" + "\t".join(pa_id_list) + "\n"
		
	#uni_result_output.write(header_line)
	act_iht_result_output.write(header_line)


	for edge in edge_activity_dic.keys():
		#uni_result_output.write(edge + '\t'+'\t'.join(map(lambda x : str(x[0]), edge_activity_dic[edge])) + '\n')
		act_iht_result_output.write(edge + '\t'+'\t'.join(map(lambda x : str(x[1]), edge_activity_dic[edge])) + '\n')


