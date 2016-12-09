## New version
## Modification: More sophiscated cross validation
## Feature selection based on glm output (consider stepwise)

load("/scratch/zz38/org.RData")
source("function.R")

library(doMC)
registerDoMC(3)

PreProcess <- function(inData,mode="DelayedExp")
{
    if (mode=="DelayedExp")
    {
          ## Selection (abondon low alpha, add gamma)
        alh <- seq(1,420,by=6)
        hg <- seq(6,420,by=6)
        ## Train
        trans <- inData ; trans <- scale(trans) ;
        trans.hg <- trans[,hg]
        trans <- trans[,-alh]
        ## Future 1
        trans0 <- rbind(trans,0)
        trans0 <- trans0[-1,]
        ## Combine ExpSineSquared
        outData0 <- cbind(exp(sin(trans)^2),trans0)
        outData <- cbind(1,outData0)
    }
    return(outData)
}
    

######################################################

breakpoints <- read.table('train_breakpoints.txt',header=F)

dat <- createDataframe(X.tr.org,Y.tr.org,mode=0)
training <- dat[1:39110,]
testing <- dat[39111:41258,]

foreach ( l = c(1:30)) %dopar%
{
    lam <- 0.9+l/10

    mseall <- c()
    betarmat <- list()
    for ( i in 1:10)
    {
        idpartition <- DataPartition(breakpoints)
        dataset <- Reshuffle(idpartition,training,portion=0.9)

        ## Training
        Xtr <- PreProcess(dataset$training[,33:452])
        Ytr <- dataset$training[,1:32]
        
        ## CV
        Xcv <- PreProcess(dataset$cv[,33:452])
        Ycv <- dataset$cv[,1:32]

        ## Tst
        Xtst <- PreProcess(testing[,33:452])
        Ytst <- testing[,1:32]
                           
        prdcv <- matrix(0,ncol=32,nrow=nrow(Xcv))
        prdtst <- matrix(0,ncol=32,nrow=nrow(Xtst))

        ## Fitting
        Ytr <- as.matrix(Ytr)
        X.tr.sel <- Xtr
        betar <- solve(t(X.tr.sel)%*%X.tr.sel + diag(rep(lam/2*nrow(X.tr.sel)),ncol(X.tr.sel)))%*%t(X.tr.sel)%*%Ytr
        
        betarmat[[i]] <- betar
        
        if (i>1)
        {
            betar.sum <- 0
            for (j in (1:i))
            {
                betar.sum <- betar.sum + betarmat[[j]]
            }
            betar.mean <- betar.sum
            betar.mean <- betar.mean/i
        }
        else
        {
            betar.mean <- betar
        }


        ## prdicting
        prdcv <- (X.cv.sel %*% betar.mean)
        prdtst <-(X.tst.sel %*% betar.mean)
        mseall[i] <- mse(prdcv,Ycv)
        print(paste("Lambda:",lam,"Iteration:",i," MSE:",mseall[i],sep=''))
    }
    print(paste("---------> Lambda:",lam,"; Overall MSE:",max(mseall),sep=''))

}

