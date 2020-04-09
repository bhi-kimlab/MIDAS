wants <- c("KEGGgraph", "org.Hs.eg.db")
has <- wants %in% rownames(installed.packages())
if(any(!has)) install.packages(wants[!has])
  
library(KEGGgraph)
library(org.Hs.eg.db)

args <-commandArgs(TRUE)

#functions
#####################################
get_edge_info_table <- function(x){
  act_iht <- "None"
  result = tryCatch({
  act_iht <- getName(getSubtype(x)[[1]])
  }, error = function(e) NULL
  )
  entry <- getEntryID(x)
  
  return(c(entry, act_iht))
}
#####################################


#parameters
#####################################
input <- args[1]
output_edge_info <- args[2]
output_graph <- args[3]
output_convert_table <- args[4]
expand <- args[5]
expand_bool <- if(expand=="FALSE"){FALSE}else{TRUE}
#####################################

cat("[INFO] Read Pathway ...\n")
#convert Pathway to Graph (no extend)
input_Graph <- parseKGML2Graph(input, expandGenes=expand_bool)
input_pathway <- parseKGML(input)

#Nodes & Edges
input_Graph_Nodes <- nodes(input_Graph)
input_Graph_Edges <- edges(input_Graph)

cat("[INFO] Convert to Graph ...\n")
for(node in input_Graph_Nodes)
{
  temp = paste(input_Graph_Edges[[node]], collapse = " ")
  temp2 = paste(node, temp, sep="\t")
  write(temp2, file=output_graph, append=TRUE)
}

#Edge Info table
cat("[INFO] Make Edge Info table ...\n")

Edge_info <- getKEGGedgeData(input_Graph)
Edge_info_table <- t(sapply(Edge_info, get_edge_info_table))

write.table(Edge_info_table, file=output_edge_info, sep="\t", quote=F, row.names = F)



input_pathway_nodes <- nodes(input_pathway)

nodes_num <- length(input_pathway_nodes)

cat("[INFO] Make covert table ...\n")
for(i in 1:nodes_num){
  result = tryCatch({
    entry_num = getEntryID(input_pathway_nodes[[i]])
    kegg_id_list = getKEGGID(input_pathway_nodes[[i]])
    
    gene_symbol_list = sapply(mget(kegg_id_list, org.Hs.egSYMBOL, ifnotfound=NA), "[[",1)
    
    write(paste(paste(gene_symbol_list, kegg_id_list, entry_num, sep="\t"), collapse="\n"), output_convert_table, append=TRUE)
  }, error = function(e) NULL,
   finally = next
  )
}
