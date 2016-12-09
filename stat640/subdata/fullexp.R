readData <- function()
{
    Xtr_org <<-  as.matrix(read.csv("/scratch/zz38/train_X_ecog.csv", header=F))
    Ytr_org <<-  as.matrix(read.csv("/scratch/zz38/train_Y_ecog.csv", header=F))
    save(Xtr_org,Ytr_org, file="/scratch/zz38/XYtrain.RData")
}

load("/scratch/zz38/XYtrain.RData")
library(plotly)

plot_ly(z=Ytr_org[1:334,], type="surface")

prd <- as.matrix(read.csv("../prdArray.csv",header=F))
plot_ly(z=prd,type="surface")
plot_ly(z=Ytr_org[40310:41258,],type="surface")

for (i in 1:32)
{
par(mfrow=c(2,1))
plot(prd[1:317,i],type='l',main=i)
plot(Ytr_org[1:317,i],type='l')
readline(prompt="Enter for next")
}
