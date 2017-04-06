import sys
import scipy.stats as stats
import csv
from multiprocessing import Pool
import statsmodels.stats.multitest as smm
from functools import partial
import math

def split_list(val_l, sample_num_l): 
	index = 0
	result_l = []

	for i in sample_num_l:
		result_l.append(val_l[index:index+i])
		index+=i
	
	return result_l

def calc_kruskal(x, sample_num_l, alpha):
	tmp_input_l = split_list(x[1:],sample_num_l) #ignore id column

	try:
		h,p = stats.kruskal(*tmp_input_l) #run kruskal-wallist test
#		h,p = stats.f_oneway(*tmp_input_l)
	except ValueError:
		return x+[`float('nan')`]
	
	result = [`p`]

	return x+result
		


#stats.kruskal(*a)

# u,p=stats.mannwhitneyu([1,2,3,4],[5,6,7,9])

#input1 : input file
#input2 : class num (ex. 13,7,10)
#input3 : p-value
#input4 : cpu_num
#input5 : output file
#input6 : correction methods ('b', 'fdr_bh', 'hs' and so on. see statsmodels.stats.multitest.multipletests)`

with open(sys.argv[1], 'r') as f:
	reader = csv.reader(f, delimiter="\t")
	
	header_line = next(f)

	header_line = header_line.rstrip() + '\tp_value\tp.adj\n'

	sample_num_l = map(int,sys.argv[2].split(","))
	
	alpha = float(sys.argv[3])

	partial_kruskal = partial(calc_kruskal, sample_num_l=sample_num_l, alpha=alpha)
	
	pool = Pool(processes=int(sys.argv[4]))

	result = pool.map(partial_kruskal,[row for row in reader])

	p_val_list=[]

	temp_count = 0
	temp_index = 0
	temp_index_dict={}
	for elem in result:
		if elem[-1] != `float('nan')`:
			temp_index_dict[temp_count]=temp_index
			temp_index+=1
			p_val_list += [float(elem[-1])]
		temp_count+=1
	
	rej, pval_corr = smm.multipletests(p_val_list, alpha=alpha, method=sys.argv[6])[:2]

	for index in range(len(result)):
		if index in temp_index_dict:
			result[index] = result[index] + [`pval_corr[temp_index_dict[index]]`]
		else:
			result[index] = result[index] + [`float('nan')`]
	
	with open(sys.argv[5], 'w') as f_out:
#		f_out.write(header_line)
		f_out.writelines('\t'.join(i) + '\n' for i in result)
	

