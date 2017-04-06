#!/bin/bash

bash ../run.sh \
		 --expression ./test_data/total_exp.MGD \
		 --pathway_set ./test_data/pathway_set.txt \
		 --class_info ./test_data/total_exp.MGD.sample_class.txt \
		 --output_directory ./test_result/ \
		 --start_threshold 0.05 \
		 --increase_moment 1e-15 \
		 --permutation_cutoff 0.1 \
		 --permutation_number 100000 \
		 --parallel_cores 10
