
args <- commandArgs(TRUE)

data <- read.table(args[1], sep=",", header=F)

col_header <- c(paste("Subpath", 1:(ncol(data)-1), sep=""),"Class")

colnames(data) <- col_header

data_rank <- as.data.frame(apply(data[,-c(ncol(data))],2,rank))

data_rank$Class <- data$Class

data_mean <- aggregate(.~Class, data=data, FUN=mean)
data_rank_mean <- aggregate(.~Class, data=data_rank, FUN=mean)


col_header <- c("Class", paste("Subpath", 1:(ncol(data)-1), sep=""))
colnames(data_mean) <- col_header
colnames(data_rank_mean) <- col_header

write.table(data_mean, args[2], sep="\t", col.names=T, row.names=F, quote=F)
write.table(data_rank_mean, args[3], sep="\t", col.names=T, row.names=F, quote=F)
