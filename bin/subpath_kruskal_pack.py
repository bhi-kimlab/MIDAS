import heapq
from operator import add
import scipy.stats as stats
import statsmodels.stats.multitest as smm
import math
import sys

def split_list(val_l, sample_num_l): 
	index = 0
	result_l = []

	for i in sample_num_l:
		result_l.append(val_l[index:index+i])
		index+=i
	
	return result_l

# max expand & threshold & incre threshold
def subpath_kruskal_ver_pack_1(edge_act_dic, G, sample_num_l, start_val, incre_moment):
	# kruskal_dic calculation
	kruskal_dic={}
	kruskal_kw_dic={}

	# edge check_dic
	edge_check_dic={}

	# Total edge number
	total_edge_num = len(edge_act_dic)

	for edge in edge_act_dic.keys():
		tmp_input_l = split_list(edge_act_dic[edge], sample_num_l)
		
		p=0.0
		kru_val=0.0
		try:
			kru_val,p=stats.kruskal(*tmp_input_l) #run kruskal-wallist test
		except ValueError:
			p = 1.0

		kruskal_dic[edge] = p
		kruskal_kw_dic[edge] = kru_val
		edge_check_dic[edge] = True

	# make heap by kruskal p-value
	h=[]

	for edge in kruskal_dic.keys():
		temp_value = kruskal_dic[edge]
		heapq.heappush(h, (temp_value, edge))


	# remain_edge_num
	remain_edge_num = total_edge_num


	# result list
	result_subpath_list=[]

	while remain_edge_num > 0 :
		current_max_edge_info = heapq.heappop(h)
		current_edge = current_max_edge_info[1]
		current_pval = current_max_edge_info[0]
		
		remain_edge_num-=1

		#used check
		edge_check_dic[current_edge] = False
	
		#adjacency_edge_list
		adja_edge_list=[]

		temp_vertexs = current_edge.split("_")

		#vertext_list
		cur_vertex_list = temp_vertexs


		for x in temp_vertexs:
			temp_edge_list = list(G.edges(x))
			for elem in temp_edge_list:
				temp_edge_id = elem[0] + "_" + elem[1]
				
				if (not(temp_edge_id in adja_edge_list)) and (temp_edge_id in edge_act_dic) and (temp_edge_id != current_edge) :
					if (edge_check_dic[temp_edge_id]):
						adja_edge_list.append(temp_edge_id)

				temp_edge_id = elem[1] + "_" + elem[0]

				if (not(temp_edge_id in adja_edge_list)) and (temp_edge_id in edge_act_dic) and (temp_edge_id != current_edge) :
					if (edge_check_dic[temp_edge_id]):
						adja_edge_list.append(temp_edge_id)

		# loop variable
		expand_flag = True
	
		# temp selected edge
		temp_select_edge_list = [current_edge]

		max_info_kw_val=kruskal_kw_dic[current_edge]
		min_pval = current_pval
		cur_edge_act = edge_act_dic[current_edge]
		
		max_edge_act = cur_edge_act
	

		threshold=start_val/incre_moment

		while(expand_flag) :
			expand_flag = False
			
			threshold=threshold*incre_moment

			temp_expand_edge_id=""
				
			inner_min_pval=1.0
			inner_max_info_edge_act=cur_edge_act
			inner_kw_val= 0.0

			for elem in adja_edge_list:
				new_edge_act = map(add, cur_edge_act, edge_act_dic[elem])
				new_input_l = split_list(new_edge_act, sample_num_l)
				new_pval=0.0
				new_kru_val=0.0

				try:
					new_kru_val,new_pval=stats.kruskal(*new_input_l) #run kruskal-wallist test
				except ValueError:
					new_pval = 1.0


				if new_pval <= min_pval:
					temp_expand_edge_id=elem
					min_pval = new_pval
					max_info_kw_val = new_kru_val
					max_edge_act = new_edge_act
					expand_flag=True
					inner_min_pval = new_pval
					inner_max_info_edge_act=new_edge_act
	
				elif new_pval <= inner_min_pval:
					temp_expand_edge_id=elem
					inner_max_info_edge_act=new_edge_act
					inner_min_pval = new_pval
					inner_kw_val = new_kru_val
		
			if not expand_flag :		
				if inner_min_pval <= threshold:
					min_pval = inner_min_pval
					max_info_kw_val = inner_kw_val
					max_edge_act = inner_max_info_edge_act
					expand_flag=True
		
			if expand_flag :
				edge_check_dic[temp_expand_edge_id] = False
				remain_edge_num-=1
				cur_edge_act = max_edge_act			
				temp_select_edge_list.append(temp_expand_edge_id)

				#remove selected adjacent edge
				adja_edge_list.remove(temp_expand_edge_id)
			
				#remove edge from heap
				temp_select_pval = kruskal_dic[temp_expand_edge_id]

				h.remove((temp_select_pval, temp_expand_edge_id))

				#expand adjacent edges
				candi_expand_vertexs = temp_expand_edge_id.split("_")		
	
				for x in candi_expand_vertexs:
					if (not (x in cur_vertex_list)) :
						cur_vertex_list.append(x)

						temp_edge_list = list(G.edges(x))

						for elem in temp_edge_list:
							temp_edge_id = elem[0] + "_" + elem[1]
				
							if (not(temp_edge_id in adja_edge_list)) and (temp_edge_id in edge_act_dic) and (temp_edge_id != temp_expand_edge_id) :
								if (edge_check_dic[temp_edge_id]):
									adja_edge_list.append(temp_edge_id)
	
							temp_edge_id = elem[1] + "_" + elem[0]
	
							if (not(temp_edge_id in adja_edge_list)) and (temp_edge_id in edge_act_dic) and (temp_edge_id != temp_expand_edge_id) :
								if (edge_check_dic[temp_edge_id]):
									adja_edge_list.append(temp_edge_id)

		result_subpath_list.append((max_info_kw_val, temp_select_edge_list))		

		heapq.heapify(h)	

	return result_subpath_list

