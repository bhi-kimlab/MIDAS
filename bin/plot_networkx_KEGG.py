#!/bin/python
import xml.etree.cElementTree as ET
import networkx as nx
import sys
import csv
import matplotlib as mpl
mpl.use('Agg')
import matplotlib.pyplot as plt

def draw_plot(group_revise_dic, edge_id_list, edge_width, edge_color, edge_style, title, output_prefix):
	pos = {}
	labels ={}
	entry_labels = {}

	for node_id in group_revise_dic.keys():
		(x,y) = group_revise_dic[node_id]['xy']
		pos[node_id] = (x*4, -y*2)

		labels[node_id] =  group_revise_dic[node_id]['label']
	
		entry_labels[node_id] = node_id

	edge_list=[]
	for x in edge_id_list:
		entries = x.split("_")
		edge_list.append((entries[0], entries[1]))

	G = nx.DiGraph()
	G.add_edges_from(edge_list)

	plt.figure(figsize=(15,15))
	nx.draw_networkx(G, pos=pos, labels=labels, node_color="#BFFFBF", node_shape='s', edgelist=edge_list, width=edge_width, edge_color=edge_color, style=edge_style)

	
	plt.savefig(output_prefix + '_GeneSymbol.pdf')

#	pylab.show()

	plt.figure(figsize=(15,15))

	nx.draw_networkx(G, pos=pos, labels=entry_labels, node_color="#BFFFBF", node_shape='s', edgelist=edge_list, width=edge_width, edge_color=edge_color, style=edge_style)


	plt.savefig(output_prefix + '_EntryID.pdf')

def parse_pos_info_from_kgml(pathway_xml):

	parse_kgml_tree = ET.parse(pathway_xml)
	
	#gruop_dic
	group_dic={}
	node_dic={}
	
	for entry in parse_kgml_tree.getiterator('entry'):


		node_type = entry.get('type') 

		name = entry.get('name')
		node_id = entry.get('id')
		
		graphics = entry.find('graphics')
		node_title = graphics.get('name')

		if node_type == "map":
			continue


		if node_type == "group":
			components = entry.find('component')
			
			component_list = []
			for component in entry.getiterator('component'):
				group_dic[component.get('id')] = node_id

		if not ((node_title is None) or (len(node_title) == 0)):
			node_title = node_title.split("...")[0]
			first_node_title = node_title.split(", ")[0]
			node_title = first_node_title
		else:
			node_title = "None"

		node_x = int(graphics.get('x'))  
		node_y = int(graphics.get('y'))
							   
		node_dic[node_id]={'name': name, 'label': node_title, 'type': node_type, 'xy': (node_x, node_y)}
		

	group_revise_dic={}
	group_count_dic={}


	key_list= node_dic.keys()
	label_value_list=[]

	for x in key_list:
		label_value_list.append(node_dic[x]['label'])

	sort_index_list=[i[0] for i in sorted(enumerate(label_value_list), key=lambda x:x[1])]
	

	new_key_list=[]

	for index in sort_index_list:
		new_key_list.append(key_list[index])	

	for x in new_key_list:
		if x in group_dic:
			group_entry_element = node_dic[x]
			group_id = group_dic[x]

			concat_str=""

			if group_id in group_count_dic:
				if group_count_dic[group_id]%2 == 1:
					concat_str=";\n"
				else:
					concat_str=";"
				group_count_dic[group_id]=group_count_dic[group_id]+1
			else:
				concat_str=";"
				group_count_dic[group_id]=1

			if node_dic[group_id]['label'] ==  'None':
				node_dic[group_id]['label'] = group_entry_element['label']
			else:
				node_dic[group_id]['label'] = node_dic[group_id]['label'] + concat_str + group_entry_element['label']
		else:
			group_revise_dic[x] = node_dic[x]
	
	return	group_revise_dic

	
if __name__ == '__main__':

	pathway_xml_file=sys.argv[1]

	group_revise_dic = parse_pos_info_from_kgml(pathway_xml_file)


	#edge color & width
	edge_color_width_file = open(sys.argv[2], 'r')
	edge_color_width_reader = csv.reader(edge_color_width_file, delimiter="\t")

	next(edge_color_width_reader)

	edge_id_list=[]
	edge_color_list=[]
	edge_width_list=[]

	for row in edge_color_width_reader:
		edge_id = str(row[0])
		edge_color = str(row[1])
		edge_width = float(row[2])

		edge_id_list.append(edge_id)
		edge_color_list.append(edge_color)
		edge_width_list.append(edge_width)


	#act_iht filter from SPIA
	act_iht_filter_dic ={}
	act_iht_filter_file = open(sys.argv[3], 'r')
	act_iht_filter_reader = csv.reader(act_iht_filter_file, delimiter="\t")

	next(act_iht_filter_reader)

	for row in act_iht_filter_reader : 
		rel = str(row[0])
		beta = int(row[1])

		act_iht_filter_dic[rel]=beta

	act_iht_filter_file.close()


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

	#edge type : 1 / solid  -- -1 / dashdot  -- 0 / dotted
	edge_style_list=[]

	for x in edge_id_list:
		rel = edge_info_dic[x]
		beta = act_iht_filter_dic[rel]
		
		if beta == 1 :
			edge_style_list.append('solid')
		elif beta == -1:
			edge_style_list.append('dashdot')
		else:
			edge_style_list.append('dotted')

	for x in edge_info_dic.keys():
		if not x in edge_id_list:
			edge_id_list.append(x)
			edge_width_list.append(1.0)
			edge_color_list.append('#000000')
			edge_style_list.append('dotted')

	output_prefix=sys.argv[5]
	title=sys.argv[6]

	draw_plot(group_revise_dic, edge_id_list, edge_width_list, edge_color_list, edge_style_list, title, output_prefix)

