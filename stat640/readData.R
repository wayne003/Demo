## Load Data

## test
Y.tr.org <- as.matrix(read.csv('/projects/stat640/Fall2016/train_Y_ecog.csv',header=F))
X.tr.org <- as.matrix(read.csv('/projects/stat640/Fall2016/train_X_ecog.csv',header=F))
X.tst.org <- as.matrix(read.csv('/projects/stat640/Fall2016/test_X_ecog.csv',header=F))

## Mu <- mean(Y.tr.org)
## Y.tr.org <- Y.tr.org - Mu

## X.tr.org <- scale(X.tr.org, center=T)
## X.tst.org <- scale(X.tst.org, center=T)

save(X.tr.org, Y.tr.org, X.tst.org,file="/scratch/zz38/org.RData")
