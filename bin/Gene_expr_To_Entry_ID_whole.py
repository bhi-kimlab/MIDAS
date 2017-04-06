import sys
import csv
from operator import add

def convert_expr(x):
	expr = 0.0

	if x != "NA":
		expr = float(x)

	return(expr)


#argv1 : gene_entry
#argv2 : gene_expr
#argv3 : output

with open(sys.argv[1], 'r') as entry_file:
	entry_reader = csv.reader(entry_file, delimiter="\t")

	expr_file = open(sys.argv[2], 'r')

	expr_reader = csv.reader(expr_file, delimiter="\t")

	entry_dic={}

	entry_expr_dic={}

	for line in entry_reader:
		gene = line[0]
		entry = line[2]

		if gene in entry_dic:
			entry_list = entry_dic[gene]

			if not entry in entry_list:
				entry_list.append(entry)
				entry_dic[gene] = entry_list

		else:
			entry_dic[gene] = [entry]

		entry_expr_dic[entry] = (0, [])

	expr_dic={}
	
	expr_reader.next() #ignore header

	sample_num = 0

	for line in expr_reader:
		gene = line[0]
		#exprs = [0.0] * (len(line)-1)
		sample_num = len(line)-1

		exprs = map(convert_expr, line[1:])

#		if line[1] != "NA" :
#			expr = float(line[1])
		
		if gene in entry_dic:
			entry_list = entry_dic[gene]

			for entry in entry_list:
				elem = entry_expr_dic[entry]
				elem_num = elem[0] + 1
				elem_sum = []
				if elem_num == 1 :
					elem_sum = exprs
				else:
					elem_sum = map(add, elem[1], exprs)

				entry_expr_dic[entry] = (elem_num, elem_sum)

	out = open(sys.argv[3], 'w')
	
	for key in entry_expr_dic.keys():
		entry = key
		exprs = [0.0]*sample_num	

		if entry_expr_dic[key][0] != 0:
			accum_num = entry_expr_dic[key][0]
			exprs = map(lambda x : x/accum_num,  entry_expr_dic[key][1])
		
		out.write(str(entry) + "\t" + '\t'.join([`x` for x in exprs]) +"\n")

	expr_file.close()
	out.close()
