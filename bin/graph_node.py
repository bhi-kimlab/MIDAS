# graph_node.py for hub_to_hub.py

class Graph_node:
	id = "0"
	in_degree = 0
	out_degree = 0

	in_nodes =[]
	out_nodes = []

	exp_level = 0.0

	upstream_flow = 0.0
	downstream_flow = 0.0
	downstream_flow_split_list=[]
	visit_nodes_num = 0

	visit_check = False

	capacity = 0.0

	def __init__(self, id, exp_level):
		self.id = id
		self.in_degree = 0
		self.out_degree = 0
		self.in_nodes =[]
		self.out_nodes = []
		self.exp_level = exp_level
		self.upstream_flow = 0.0
		self.downstream_flow = 0.0
		self.visit_nodes_num = 0
		self.downstream_flow_split_list=[]
		self.capacity = 0.0
	
	def set_capacity(self, capacity):
		self.capacity = capacity

	def get_capacity(self):
		return self.capacity

	def set_downstream_flow_split_list(self, split_list):
		self.downstream_flow_split_list = split_list

	def get_downstream_flow_split_list(self):
		return self.downstream_flow_split_list

	def get_id(self):
		return self.id

	def get_visit_check(self):
		return self.visit_check

	def set_visit_check(self):
		self.visit_check = True

	def add_in_node(self, node):
		self.in_degree += 1
		self.in_nodes.append(node)
	
	def add_out_node(self, node):
		self.out_degree += 1
		self.out_nodes.append(node)

	def increase_visit(self):
		self.visit_nodes_num +=1

	def get_visit_num(self):
		return self.visit_nodes_num

	def get_in_nodes(self):
		return self.in_nodes

	def get_out_nodes(self):
		return self.out_nodes

	def get_in_degree(self):
		return self.in_degree

	def get_out_degree(self):
		return self.out_degree

	def set_upstream_flow(self, flow):
		self.upstream_flow += flow
	
	def set_downstream_flow(self, flow):
		self.downstream_flow += flow

	def get_upstream_flow(self):
		return self.upstream_flow

	def get_downstream_flow(self):
		return self.downstream_flow

	def get_exp_level(self):
		return self.exp_level


