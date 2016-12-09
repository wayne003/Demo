## This file is used to subsetting the project data so that its small enough for prototyping

ProjectPath <- "/projects/stat640/Fall2016/"

YtrCon = file(paste(ProjectPath,'train_Y_ecog.csv',sep=''),'r')
XtrCon = file(paste(ProjectPath,'train_X_ecog.csv',sep=''),'r')

Y.tr.org <- read.csv(YtrCon,nrows=500)
X.tr.org <- read.csv(XtrCon,nrows=500)

save(Y.tr.org, file="./subdata/Ysubdata.RData")
save(X.tr.org, file="./subdata/Xsubdata.RData")

