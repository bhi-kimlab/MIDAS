# About output

MIDAS generates differentially activated subpaths from multi-class RNA-seq data. In output directory, several direcoties and files are included.

```
Output Directory/
	|- kegg_pathways/
		|- kgml/
		|- kegg_graph/

	|- single_pathway_analysis/
	|- Summary_result/
```

# kegg_pathways/
This folder contains KEGG pathway xml files and converted directed graphs.
It consists of two sub directories.

* kgml/ : contains KEGG pathway xml files
* kegg_graph/ : contains converted directed graphs and node-gene convert tables.

# single_pathway_analysis/
This folder contains a single target pathway analysis results. Each target pathways is saved in KEGG pathway ID folder. For example,
```
single_pathway_analysis/
	|- hsa04110/
	|- hsa04310/
	|- hsa04390/
	|- ...
```
In each target pathway folder, all mined subpaths (significant + non-significant) are located.

# Summary_result/
This folder is a main result of MIDAS. It contains determined subpaths on a given statistical threshold. GO term analysis and drawing subpaths on KEGG patwhway are also included.

```
Summary_result/
	|- Subpath_Merged_result.txt
	|- Subpath_Merged_result.txt.significant.txt
	|- Subpath_Merged_result.txt.significant.annotation.txt
	|- Subpath_Merged_result.txt.significant.txt.GO_analysis.txt
	|- Subpath_activity_Merged_whole_result.txt
	|- Subpath_activity_Merged_whole_result.txt.mean_table.txt
	|- Subpath_activity_Merged_whole_result.txt.mean_rank_table.txt
	|- Subpath_activity_Merged_whole_result.txt.mean_table.txt.significant.txt
	|- Subpath_activity_Merged_whole_result.txt.mean_rank_table.txt.significant.txt
	|- networkx_figure/
	|- cytoscape/
```

* Subpath_Merged_result.txt: 
		Total selected subpaths (signficnat + non-significant)
* **Subpath_Merged_result.txt.significant.txt**: Only contains statistically significant subpaths
* **Subpath_Merged_result.txt.significant.annotation.txt**: More informative format of **Subpath_Merged_result.txt.significant.txt**. It helps users understand what genes are involved and how they are linked to a particular subpath.
* Subpath_Merged_result.txt.significant.txt.GO_analysis.txt: GO term analysis of determined subpaths
* Subpath_activity_Merged_whole_result.txt: subpath activity of each sample. Comma separated file. Row is sample and column is all subpaths activity. Last column is class label.
* Subpath_activity_Merged_whole_result.txt.mean_table.txt: Average value of subpaths activity by class.
* Subpath_activity_Merged_whole_result.txt.mean_rank_table.txt: Average rank of subpath activity order by class.
* Subpath_activity_Merged_whole_result.txt.mean_table.txt.significant.txt: Only contains significant subpaths.
* Subpath_activity_Merged_whole_result.txt.mean_rank_table.txt.significant.txt: Only contains significant subpaths.
* *networkx_figure/*: visualization of selected subpaths. Two kinds of figure are provided. One is that node label is entry id. The another is that node label is gene symbol (KEGG display name). See these figures with Subpath_Merged_result.txt.significant.annotation.txt (Recommand). Due to python library limitation, figure quality is not good.
* *cytoscape/*: It contains input for cytoscape to draw more quality figures. See docs/cytoscape_draw_manual.pdf

