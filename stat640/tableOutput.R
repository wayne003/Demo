# Load predicted data Y
load("prdkern.RData")
Yhat_tab <- matrix(Yhat.tst,ncol=1)
Ycsv <- data.frame(Id=c(1:(dim(Yhat_tab)[1])),Prediction=as.vector(Yhat_tab))
write.csv(Ycsv,file="Prediction.csv",row.names=F)
