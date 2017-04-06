# calc_edge_act_parallel.py
import csv
from graph_node import Graph_node
from multiprocessing import Pool
from functools import partial

def dic_return(temp_dic, temp_key):
	result = 0.0

	if(temp_key in temp_dic):
		result = temp_dic[temp_key]
	else:
		result = 0.0
	
	return result

def func_edge_activity(cur_exp, down_exp, cur_centrality, down_centrality, edge_weight_case,beta, max_cur_exp_val, max_down_exp_val, cur_node_z_sig, ds_node_z_sig, act_iht_case):
	result=0.0

	if (cur_exp + down_exp) != 0.0:
		result = ((cur_exp * cur_centrality + down_exp * down_centrality)**2)/(2.0*(cur_exp + down_exp))

	act_iht_result = 0.0

	if edge_weight_case == 0 :
		down_act_iht_result = 0.0
		up_act_iht_result = 0.0

		if beta == -1 :
			revised_down_exp = max_down_exp_val - down_exp
			
			if (cur_exp + revised_down_exp) != 0.0:
				down_act_iht_result = ((cur_exp * cur_centrality + revised_down_exp * down_centrality)**2)/(2.0*(cur_exp + revised_down_exp))
		else:
			down_act_iht_result =  result


		if act_iht_case == 1:
			if beta == -1 :
				revised_cur_exp = max_cur_exp_val - cur_exp

				if  (revised_cur_exp + down_exp) != 0.0:
					up_act_iht_result = ((revised_cur_exp*cur_centrality + down_exp * down_centrality)**2)/(2.0*(revised_cur_exp + down_exp))
			else:
				up_act_iht_result = result

			act_iht_result = max(up_act_iht_result, down_act_iht_result)
		else :
			act_iht_result = down_act_iht_result
	
	else:
		down_act_iht_result = 0.0
		up_act_iht_result = 0.0

		if beta == -1 :
			down_act_iht_result = (1.0+cur_node_z_sig) * (1.0 - ds_node_z_sig) * result # + / - for -|
		else:
			down_act_iht_result = (1.0+cur_node_z_sig) * (1.0 + ds_node_s_sig) * result # + / + for ->

		if act_iht_case == 1:
			if beta == -1 :
				up_act_iht_result = (1.0-cur_node_z_sig) * (1.0 + ds_node_s_sig) * result # - / + for -|
			else:
				up_act_iht_result = (1.0-cur_node_z_sig) * (1.0 - ds_node_s_sig) * result # - / - for ->
		
			act_iht_result = max(up_act_iht_result, down_act_iht_result)
		else:
			act_iht_result = down_act_iht_result

	return (result, act_iht_result)

def inner_calc_edge_act(tup, graph, centrality_dic, max_exp_dic, edge_weight_case, edge_weight_dic, act_iht_method_case, sample_num):
	cur_node_id = tup[0]
	ds_node_id = tup[1]
	beta = tup[2]

	#cur node info
	cur_node_centrality = dic_return(centrality_dic,cur_node_id)
	cur_node = graph[cur_node_id]
	cur_node_expression = cur_node.get_exp_level()
	max_cur_exp_val = dic_return(max_exp_dic, cur_node_id)

	cur_node_z_sig = 0.0
	if edge_weight_case == 1:
		cur_node_z_sig = dic_return(edge_weight_dic,cur_node_id)


	edge_id = cur_node_id + '_' + ds_node_id

	#downstream node info
	ds_node = graph[ds_node_id]
	max_down_exp_val = dic_return(max_exp_dic,ds_node_id)
	ds_node_centrality = dic_return(centrality_dic,ds_node_id)
	ds_node_expression = ds_node.get_exp_level() # list

	ds_node_z_sig = 0.0
	
	if edge_weight_case == 1:
		ds_node_z_sig = dic_return(edge_weight_dic,ds_node_id)
		
	edge_act_result_list = map(lambda x,y : func_edge_activity(x, y, cur_node_centrality, ds_node_centrality, edge_weight_case, beta, max_cur_exp_val, max_down_exp_val, cur_node_z_sig, ds_node_z_sig,act_iht_method_case), cur_node_expression, ds_node_expression) 
	
	return (edge_id, edge_act_result_list)
	
def calc_edge_activity_whole(graph, centrality_dic,edge_info, act_iht_filter,  max_exp_dic, edge_weight_case, edge_weight_dic, act_iht_method_case, sample_num, p_cores):
	## main func ##
	out_dic = {}

	total_num = 0.0;

	total_SAS_sum_results = [(0.0, 0.0)]*sample_num;


	##parallel##
	#make inputs for parallel processing
	pool = Pool(processes=p_cores)

	cur_ds_node_list=[]

	for cur_node_id in graph.keys():
		cur_node = graph[cur_node_id]
		downstream_node_list = cur_node.get_out_nodes()

		for ds_node_id in downstream_node_list:
			edge_id = cur_node_id + '_' + ds_node_id

			rel = edge_info[edge_id]

			beta = act_iht_filter[rel]
			
			if beta != 0:
				cur_ds_node_list.append((cur_node_id, ds_node_id, beta))


	partial_inner_calc_edge_act=partial(inner_calc_edge_act, graph = graph, centrality_dic=centrality_dic, max_exp_dic=max_exp_dic, edge_weight_case=edge_weight_case, edge_weight_dic=edge_weight_dic, act_iht_method_case=act_iht_method_case, sample_num=sample_num)

	out_dic = dict(pool.map(partial_inner_calc_edge_act, cur_ds_node_list))
	
	####################################################


	for edge in out_dic.keys():
		edge_act_result_list = out_dic[edge]
		total_SAS_sum_results = map(lambda x,y : ((x[0]+y[0]),(x[1]+y[1])), total_SAS_sum_results, edge_act_result_list)
	
	total_num = len(out_dic.keys())

	total_SAS_mean_results = map(lambda x : (x[0]/total_num, x[1]/total_num), total_SAS_sum_results)

	return (total_SAS_mean_results, out_dic)


