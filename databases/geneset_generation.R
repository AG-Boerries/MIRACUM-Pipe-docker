library(GSA)

args <- commandArgs(trailingOnly = TRUE)
hallmarks <- args[1]
gmt <- GSA.read.gmt(hallmarks)
genesets <- gmt$genesets
names <- data.frame(Names = gmt$geneset.names, Descriptions = gmt$geneset.descriptions)
names(genesets) <- names$Names
hallmarksOfCancer <- genesets
save(hallmarksOfCancer, file = "hallmarksOfCancer_GeneSets.RData")