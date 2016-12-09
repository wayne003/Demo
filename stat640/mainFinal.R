source("Pre.R")
## Generate N fold cutpoint
fold <- 10
for ( f in 1:fold)
{
    ## seprate training and cvset
    trainID <- NFold(fold,f,idpartition)$training.idx
    cvID <- NFold(fold,f,idpartition)$cvset.idx

    trset.fold <- training[trainID[1]:trainID[length(trainID)],]
    cvset.fold <- training[cvID[1]:cvID[length(cvID)],]

    trainX <- as.matrix(PreProcess(trset.fold[,33:ncol(trset.fold)]))
    trainY <- as.matrix(trset.fold[,1:32])
    fit <- glmnet(x=trainX,y=trainY,family="mgaussian",alpha=0.5,lambda=5)

    cvX <- as.matrix(PreProcess(cvset.fold[,33:ncol(cvset.fold)]))
    prdcv <- predict(fit,newx=cvX)
    
    msecv[f,1] <- mse(prdcv,cvset.fold[,1:32])
    
}

saveRDS(msecv,file="./FinalReport/BaseELMSE.rds")


library(CVST)
## Generate N fold cutpoint
fold <- 10
for ( f in 1:fold)
{
    ## seprate training and cvset
    trainID <- NFold(fold,f,idpartition)$training.idx
    cvID <- NFold(fold,f,idpartition)$cvset.idx

    trset.fold <- training[trainID[1]:trainID[length(trainID)],]
    cvset.fold <- training[cvID[1]:cvID[length(cvID)],]

    trainX <- as.matrix(trset.fold[,33:ncol(trset.fold)])
    trainY <- as.matrix(trset.fold[,1:32])

    cvX <- as.matrix(cvset.fold[,33:ncol(cvset.fold)])
    cvY <- as.matrix(cvset.fold[,1:32])
    
    for (i in 1:32)
    {
        ## train
        d = constructData(x=trainX,y=trainY[,i])
        krr_learner = constructKRRLearner()
        params = list(kernel='polydot',degree=1,offset=0,scale=1,lambda=2)
        krr_trained = krr_learner$learn(d,params)

        ## predict
        monitdCV = constructData(x=cvX, y=cvY[,i])
        pred = krr_learner$predict(krr_trained,dCV)
        pred2 = matrix(pred,ncol=1)

        if ( i == 1)
        {
            prdcv <- pred2
        } else
        {
            prdcv <- cbind(prdcv,pred2)
        }
    }
    print(paste("Fold:",f))
                
    msecv[f,1] <- mse(prdcv,cvset.fold[,1:32])
    
}

## knn

library(caret)

## Knn fit function inside PCA.R
source("PCA.R")
              
## Generate N fold cutpoint
fold <- 10
for ( f in 1:fold)
{
    ## seprate training and cvset
    trainID <- NFold(fold,f,idpartition)$training.idx
    cvID <- NFold(fold,f,idpartition)$cvset.idx

    trset.fold <- training[trainID[1]:trainID[length(trainID)],]
    cvset.fold <- training[cvID[1]:cvID[length(cvID)],]

    
    trainX <- (trset.fold[,33:ncol(trset.fold)])
    trainY <- (trset.fold[,1:32])

    
    cvX <- (cvset.fold[,33:ncol(cvset.fold)])
    cvY <- (cvset.fold[,1:32])
    
    prdcv <- knnFit(trainX,trainY,cvX)
    
    msecv[f,1] <- mse(prdcv,cvY)
    
}
