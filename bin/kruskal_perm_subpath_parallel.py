import networkx as nx
import sys
import csv
import matplotlib.pyplot as plt
import scipy.stats as stats
from multiprocessing import Pool
import statsmodels.stats.multitest as smm
from functools import partial
import math
import random
from operator import add


def split_list(val_l, sample_num_l): 
	index = 0
	result_l = []

	for i in sample_num_l:
		result_l.append(val_l[index:index+i])
		index+=i
	
	return result_l


def make_null_dist(x, total_edge_num, sample_number, sample_num_l, edge_act_dic, edge_index_dic):
	def split_list(val_l, sample_num_l): 
		index = 0
		result_l = []

		for i in sample_num_l:
			result_l.append(val_l[index:index+i])
			index+=i
	
		return result_l	
	
	random_select_edges = random.sample(xrange(0, total_edge_num), x)
	new_random_subpath_act = [0.0] * sample_number

	for edge_index in random_select_edges:
		temp_edge_act = edge_act_dic[edge_index_dic[edge_index]]

		new_random_subpath_act = map(add, new_random_subpath_act, temp_edge_act)
	
#	new_random_subpath_act = map(lambda x : x/len(random_select_edges), new_random_subpath_act)

	new_input_l = split_list(new_random_subpath_act, sample_num_l)

	new_k=0.0
	new_p=0.0

	try:
		new_k,new_p = stats.kruskal(*new_input_l)
	
	except ValueError:
		new_k=0.0

	return new_k


#arg1 : edge_act_file
#arg2 : class number (ex. 13,7,10)
#arg3 : selected sizes (ex 1,2,3,4,6,7)
#arg4 : selected subpaths (ex. 3 (size) \t  120 (kw value) \t 3_1|1_2 (subpath))
#arg5 : permutaiton number

with open(sys.argv[1], 'r') as edge_act_file:
	random.seed()

	edge_act_file_reader = csv.reader(edge_act_file, delimiter="\t")

	header = next(edge_act_file_reader)

	edge_act_dic={}

	#index for random sampling
	my_index=0

	edge_index_dic={}

	sample_number = 0

	for row in edge_act_file_reader:
		id=row[0]
		values = map(float, row[1:])
		sample_number = len(values)

		edge_act_dic[id] = values
		
		edge_index_dic[my_index]=id

		my_index=my_index+1
	
	#total edges
	total_edge_num = len(edge_act_dic)

	# class numbers
	sample_num_l = map(int, sys.argv[2].split(","))
	
	# selected sizeds
	selected_size_list = map(int, sys.argv[3].split(","))
	
	# selected subpaths
	selected_subpath_dic={}

	for x in selected_size_list:
		selected_subpath_dic[x]=[]
	
	subpath_file = open(sys.argv[4], 'r')
	subpath_file_reader = csv.reader(subpath_file, delimiter="\t")

	for row in subpath_file_reader:
		s_size = int(row[0])
		s_kw_val = float(row[1])
		s_subpath = row[2]
	
		dic_elem = selected_subpath_dic[s_size]
		dic_elem.append([s_kw_val, s_subpath])
		selected_subpath_dic[s_size] = dic_elem

	# permutaiton num
	perm_num = int(sys.argv[5])

	# pval list
	pval_list=[]

	# result
	result = []

	# core setting
	num_cores = 10

	pool = Pool(processes=num_cores)

	#partial
	partial_null_dist = partial(make_null_dist, total_edge_num=total_edge_num, sample_number=sample_number, sample_num_l=sample_num_l, edge_act_dic=edge_act_dic, edge_index_dic=edge_index_dic)


	for x in selected_size_list :
		
		new_k_list = [0.0] * perm_num
		new_p_list = [0.0] * perm_num

		new_k_list = pool.map(partial_null_dist, [x for j in range(perm_num)])

		selected_size_subpaths = selected_subpath_dic[x]

		for elem in selected_size_subpaths:
			elem_kw_val = elem[0]
			elem_subpath = elem[1]

			over_same_number = len([k for k in new_k_list if k >= elem_kw_val])
			
			perm_pval = float(over_same_number) / float(perm_num)

			pval_list.append(perm_pval)

			result.append([elem_subpath, `x`, `elem_kw_val`, `perm_pval`])
	

	rej, pval_adj, alphacSidak, alphacBonf = smm.multipletests(pval_list, alpha=0.05, method='fdr_bh')
	
	for index in range(len(result)):
		result[index] = result[index] + [`float(pval_adj[index])`]	

	for elem in result:
		print '\t'.join(elem)
