import networkx as nx
import sys
import csv
import matplotlib.pyplot as plt
from subpath_kruskal_pack import *
import scipy.stats as stats
from multiprocessing import Pool
import statsmodels.stats.multitest as smm
from functools import partial
import math


#arg1 : graph input file
#arg2 : filter_edge_string
#arg3 : edge_act_file
#arg4 : class number (ex. 13,7,10)
#arg5 : start_threshold
#arg6 : increase_moment

with open(sys.argv[1], 'r') as graph_input:
	reader = csv.reader(graph_input, delimiter="\t")

	graph_dic = {}

#	print "[INFO] Make graph ..."

	for row in reader:
		s = str(row[0])
		t = row[1]

		graph_dic[s] = t


	filter_edges_file = open(sys.argv[2],'r')
	filter_edges_file_reader= csv.reader(filter_edges_file)
	
	filter_list=[]
	for row in filter_edges_file_reader:
		filter_list.append(row[0])
	
	# make graph
	G = nx.Graph()

	graph_nodes = graph_dic.keys()

	G.add_nodes_from(graph_nodes)

	graph_edges = []

	for key in graph_dic:
		t = graph_dic[key].split(" ")
		if t[0] != "" :
			for elem in t:
				temp_edge_id = key + "_" + elem
				if (not(temp_edge_id in filter_list)):
					graph_edges.append((str(key),str(elem)))

	G.add_edges_from(graph_edges)

	#edge_act_file
	edge_act_file=open(sys.argv[3], 'r')
	edge_act_file_reader = csv.reader(edge_act_file, delimiter="\t")

	header = next(edge_act_file_reader)

	edge_act_dic={}

	for row in edge_act_file_reader:
		id=row[0]
		values = map(float, row[1:])

		edge_act_dic[id] = values

	# class numbers
	sample_num_l = map(int, sys.argv[4].split(","))
	
 	#run subpath mining
	result = subpath_kruskal_ver_pack_1(edge_act_dic, G, sample_num_l, float(sys.argv[5]), float(sys.argv[6]))

	for x in result:
		print "\t".join([str(len(x[1])), str(x[0]),"|".join(x[1])])

	
##############################################################

