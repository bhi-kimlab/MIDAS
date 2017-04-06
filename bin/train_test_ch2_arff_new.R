args <- commandArgs(TRUE)


data <- read.table(args[1], sep="\t", header=T, stringsAsFactors = F)
edges <- data[,1]
data <- data[,-1]
rownames(data) <- edges

class <- unlist(strsplit(args[2], ","))
class_number <- as.numeric(unlist(strsplit(args[3], ",")))


subpath_list <- read.table(args[4], sep="\t", header = F, stringsAsFactors = FALSE)

edges_act_mean_func <- function(x, mat){
  select_edges <- unlist(strsplit(x[1], "\\|"))
  temp_result <- as.numeric(apply(mat[select_edges,],2,mean))
  
  return(temp_result)
}


subpath_act_col_header <- paste("Rank", 1:nrow(subpath_list), sep="")

subpath_act_result <- apply(subpath_list, 1, edges_act_mean_func, mat=data)
colnames(subpath_act_result) <- subpath_act_col_header

output_data <- as.data.frame(subpath_act_result)

class_list <-rep(class[1], class_number[1])
for(i in 2:length(class_number)){
	class_list <- c(class_list, rep(class[i], class_number[i]))
}

output_data$Class <- class_list

write.table(output_data, file=args[5], sep=",", quote=F, col.names=F, row.names=F)
