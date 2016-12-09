## Load Data
## Data is preloaded by readData.R
## Load preloaded Data
load("/scratch/zz38/org.RData")


source("function.R")

## ## JIT Compiler
## require(compiler)
## enableJIT(3)

## doMC register
library(doMC)
registerDoMC(4)

#########################################
## PRE-PROCESSING
## Splicing data
## idx <- c(1:nrow(X.tr.org))
## idx.train <- idx[1:floor(0.7*length(idx))]
## idx.cv <- idx[ (floor(0.7*length(idx))+1) : floor(0.9*length(idx)) ]
## idx.tst <- idx[ (floor(0.9*length(idx))+1) : length(idx) ]
## X.tr <- X.tr.org[idx.train,]; X.cv <- X.tr.org[idx.cv,]; X.tst <- X.tr.org[idx.tst,] 
## Y.tr <- Y.tr.org[idx.train,]; Y.cv <- Y.tr.org[idx.cv,]; Y.tst <- Y.tr.org[idx.tst,]



## Data for prototyping use

X.tr <- X.tr.org[1:40309,]
Y.tr <- Y.tr.org[1:40309,]
X.cv <- X.tr.org[40310:41258,]
Y.cv <- Y.tr.org[40310:41258,]


###########################################
##       KERNEL RIDGE      
##  Fitting with kernel ridge regression, just for testing
## Uncomment if you need to fit model
#########################################

## library(CVST)

## ## Prepare data
## ### Training SET
## df.X.tr.s <- data.frame(X.tr.s)
## colnames(df.X.tr.s) <- c(1:420)
## df.training <- data.frame(Y.tr.s,df.X.tr.s)

## for ( i in 1:32)
## {
##     colnames(df.training)[i] <- paste("Y",i,sep='')
## }

## ## CV SET
## df.X.cv.s <- data.frame(X.cv.s)
## colnames(df.X.cv.s) <- c(1:420)
## df.cv <- data.frame(Y.cv.s, df.X.cv.s)

## for (i in 1:32)
## {
##     colnames(df.cv)[i] <- paste("Y",i,sep='')
## }



## ## CVST FITTING
## ## fitting 1 frequency for testing
## X.tr.s <- matrix(X.tr.s)
## Y.tr.s <- matrix(Y.tr.s)
## d = constructData(x=X.tr.s, y=Y.tr.s[,1])
## krr_learner = constructKRRLearner()
## #params = list(kernel='polydot',degree=1,offset=0,scale=1,lambda=2)
## params = list(kernel='rbfdot', sigma=100,lambda=0.01)
## krr_trained = krr_learner$learn(d, params)


## ## Predicting
## dCV = constructData(x=X.cv.s, y=Y.cv.s)
## pred = krr_learner$predict(krr_trained,dCV)
## mse(pred,df.cv[,1])





#######################################
##      RIDGE REGRESSION
#############################

## ## lam=18
## trainingX <- X.tr.s
## trainingY <- Y.tr.s
## cvsetX <- X.cv.s
## cvsetY <- Y.cv.s
## testingX <- X.tst
## yp = 32
## lam = 2.8
## load("fitl.mtx.RData")

## prd <- matrix(0,ncol=32,nrow=nrow(cvsetX))
## prdtst <- matrix(0,ncol=32,nrow=nrow(testingX))
## for (j in 1:32)
## {
##         print(paste("var:",j))
##         ## SELECTION:
##         Xsel <- fitl.mtx
##         Xsel[Xsel != 0] <- 1
##         n <- nrow(trainingX)
##         Xsel.b <- matrix(rep(Xsel[,j],n),nrow=n,byrow=T)
##         X.tr.sel <- trainingX * Xsel.b

       
##         ## Fitting
##         betar = solve(t(X.tr.sel)%*%X.tr.sel + diag(rep(lam/2*nrow(X.tr.sel)),ncol(X.tr.sel)))%*%t(X.tr.sel)%*%trainingY[,j]

##         ## prdicting
##         prd[,j] <- cvsetX %*% betar
##         prdtst[,j] <- testingX %*% betar

## print(mse(prd,cvsetY))
## }
## save(prdtst,file="prdkern.RData")


################################
##      LASSO
##############################



## n <- nrow(X.tr.s)
## yp <- ncol(Y.tr.s)
## xp <- ncol(X.tr.s)

## GRID SEARCH

## msegrid <- matrix(0,nrow=100,ncol=32)

## foreach ( par=c(1:32)) %do%
## {
##     foreach ( lambda =c(1:100) ) %do%
##         {
##             lam = lambda/10
##             if (lambda > 1 & par>1)
##             {
##                 print(paste("par:",par,",lam:",lam,'mse:',msegrid[lambda-1,par-1],sep=''))
##             }
   
   
##             fitl.mtx = as.vector(glmnet(X.tr.s,Y.tr.s[,par],family="gaussian", lambda=lam,alpha=1)$beta)
 
##             prdkern<- t( X.cv.s %*% fitl.mtx )
##             msegrid[lambda,par] <- (mse(Y.cv.s[,par],(prdkern+Mu)))

##         }
## }

## save(msegrid,file="msegrid.RData")


## Fitting
## load("msegrid.RData")
## minlam <- apply(msegrid,2,which.min)
## minlam <- minlam/10
## fitl.mtx <- matrix(0,nrow=xp,ncol=yp)
## foreach (j=c(1:yp)) %do%
##     {
##         fitl.mtx[,j] <- as.vector(glmnet(X.tr,Y.tr[,j],family="gaussian", lambda=minlam[j],alpha=1)$beta)
##     }

## save(fitl.mtx,file="fitl.mtx.RData")
## ## Predicting
## prdkern <- matrix(0,nrow=nrow(X.tst),ncol=32)
## foreach (j =c(1:32) ) %do%
##     {
##         prdkern[,j] <- t( X.tst %*% fitl.mtx[,j] )
##         }

####### USE LASSO PROCESS AS VARIABLE SELECTION
###### Combine with other algorithm, proposed: gaussian kernel
## LaGauss <- function(trainingX,trainingY)
## {

##     yp = 32
##     lam = 1500
##     fitpoly <<- foreach (j = (1:yp), .combine=cbind ) %dopar%
##     {
##         print(j)
##         ## SELECTION:
##         Xsel <- fitl.mtx
##         Xsel[Xsel != 0] <- 1
##         n <- nrow(trainingX)
##         Xsel.b <- matrix(rep(Xsel[,j],n),nrow=n,byrow=T)
##         X.tr.sel <- trainingX * Xsel.b

       
##         ## Fitting
##         fit <- kernRR.fit(X.tr.sel,trainingY[,j], K=kernel.poly(X.tr.sel,X.tr.sel,d=2,c=5),lam)

##     }

##     print("Fitting Process Finished")
##     print(gc())

## }

## LaGaussPrd <- function(training,testing,cvset)
## {
##     print("Begin Prediction Process...")
##     yp=32
##     prdtst <<- foreach(j=(1:yp), .combine=cbind) %dopar%
##     {
##         print(paste("Testset,Variable:",j,";"))
##         Xsel <- fitl.mtx
##         Xsel[Xsel != 0] <- 1
##         n <- nrow(training)
##         Xsel.b <- matrix(rep(Xsel[,j],n),nrow=n,byrow=T)
##         X.tr.sel <- training * Xsel.b

## 	ntst <- nrow(testing)
## 	Xsel.tst <- matrix(rep(Xsel[,j],ntst),nrow=ntst,byrow=T)
##         X.tst.sel <- testing * Xsel.tst
         
##         ## predicting
##         prdtst <- kernRR.prd(matrix(fitpoly[,j]), K=kernel.poly(X.tr.sel, X.tst.sel,d=2,c=5))
## 	}

##     prdcv <<- foreach(j=(1:yp), .combine=cbind) %dopar%
##         {
##         print(paste("CVset,Variable:",j,";"))
##         Xsel <- fitl.mtx
##         Xsel[Xsel != 0] <- 1
##         n <- nrow(training)
##         Xsel.b <- matrix(rep(Xsel[,j],n),nrow=n,byrow=T)
##         X.tr.sel <- training * Xsel.b

##         ncv <- nrow(cvset)
##         Xsel.cv <- matrix(rep(Xsel[,j],ncv),nrow=ncv,byrow=T)
##         X.cv.sel <- cvset * Xsel.cv
                
## 	prdcv <- kernRR.prd(matrix(fitpoly[,j]), K=kernel.poly(X.tr.sel,X.cv.sel,d=2,c=5))

##         }

## }


## load("fitl.mtx.RData")
## LaGauss(X.tr.s,Y.tr.s)
## save(fitpoly,file="fitpoly.RData")

## load("fitpoly.RData")
## LaGaussPrd(X.tr.s,X.tst,X.cv.s)
## save(prdtst,file="prdtst.RData")
## save(prdcv, file="prdcv.RData")
## print(mse(prdgau,Y.cv.s))


#######################################
## SPLINE
## library("mgcv")
## trainX <- X.tr
## trainY <- Y.tr
## testX <- X.tst

## trainX <- data.frame(trainX)
## colnames(trainX) <- c(1:420)

## testX <- data.frame(testX)
## colnames(testX) <- c(1:420)

## c <- "s(trainX[,1],k=2)"
## for ( i in 2:420)
## {
##     c <- paste(c,"+s(trainX[,",i,"],k=2)",sep="")
## }


## f <- paste("trainY[,1]~",c,sep="")
## f <- as.formula(f)

## fitg <- gam(f)
## save(fitg,file="fitg.RData")
                               

#####################################################
## PCA
#####################################################


## 
library(caret)

## Creat dataframe
## The function used to create dataframe is under "funtion.R"

training.o <- createDataframe(X.tr,Y.tr,mode=0)
cvset.o <- createDataframe(X.cv,Y.cv,mode=0)
testset <- createDataframe(X.tst,0,mode=1)

## Function for PCA related method
source("PCA.R")
## PCASelection(training.o,cvset.o,range=c(80:81))
## prd <- PCAFit(training.o,cvset.o,pca=6)

trainingnew <- PreTreat(training.o)
cvsetnew <- PreTreat(cvset.o)
prd <- PCAFit(trainingnew,cvsetnew,pca=420)

## prd <- PCAPolyFit(training.o,cvset.o,pca=80)


save(prd,file="/scratch/zz38/prdcv.RData")
save.image("/scratch/zz38/PCAenv.RData")

