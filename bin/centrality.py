# centrality.py for hub_to_hub.py
import networkx as nx

# case : centrality method
# 0 - betweeness centrality
def calc_centrality(network, case):
	
	G = nx.DiGraph()

	G.add_nodes_from(network.keys())

	graph_edges=[]

	for key in network.keys():
		t = network[key].split(" ")

		if t[0] != "":
			for elem in t:
				graph_edges.append((key, elem))

	G.add_edges_from(graph_edges)
	
	centrality_dic = {}

	if case == 0:
		centrality_dic = nx.betweenness_centrality(G)
	elif case == 1:
		centrality_dic = nx.closeness_centrality(G)

	return centrality_dic
