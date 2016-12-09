## This Script is used mainly for PCA

## Using CARET packeges,
## Default method is Local Polynomial Regression
## Consult CARET packages for more info
## http://topepo.github.io/caret/available-models.html


## Assuming data is preprocess to be a dataframe
PCASelection <- function(training,cvset, range=c(2:60))
    {
        msemtx <- matrix(nrow=length(range),ncol=2) ## two column, first to store PCA number, second to store RMSE
        idmse <- 1 ## initialize counter, for storing result
        for (pca in range) ## DO NOT apply foreach here, will cause error since "train" already empolyed foreach
            {
                ## create preprocess object
                preProc <<- preProcess(training[,33:dim(training)[2]],method="pca",pcaComp=pca)

                ## calculate PCs for training data
                trainPC <<- predict(preProc,training[,33:dim(training)[2]])

                ## calculate PCs for CV set data
                cvPC <<- predict(preProc, cvset[,33:dim(training)[2]])

                ## Fitting and Predicting circulation
                ## prdcv <- matrix(0,nrow=nrow(cvset), ncol=32)
                # prdtst <- matrix(0,nrow=nrow(testing), ncol=32)

                prdcv <- PCAFit(training,cvset,pca)
                ## prd <- prd + Mu ## NOT necessary since Y is pretreated for cvset
                print(mse(prdcv,cvset[,1:32]))

                ## Store result
                msemtx[idmse,1] <- pca
                msemtx[idmse,2] <- mse(prdcv,cvset[,1:32])
                               
                modelFit <- NULL ## CLEAN UP, don't know why, but necessary otherwise get error message if run again

                idmse <- idmse+1
             }

        save(msemtx, file='PCAmse.RData')

        }

PCAFit <- function(training,cvset,pca)
{
 ## create preprocess object
                preProc <- preProcess(training[,33:dim(training)[2]],method="pca",pcaComp=pca)

                ## calculate PCs for training data
                trainPC <- predict(preProc,training[,33:dim(training)[2]])

                ## calculate PCs for CV set data
                cvPC <- predict(preProc, cvset[,33:dim(training)[2]])

                ## Fitting and Predicting circulation
                prdcv <- matrix(0,nrow=nrow(cvset), ncol=32)
                # prdtst <- matrix(0,nrow=nrow(testing), ncol=32)
                for (j in (1:32))
                {
                    print(paste("PCA:",pca,"  Variable:",j))
                    modelFit <- train(training[,j] ~. , method='ridge',data=trainPC)
                    prdcv[,j] <- predict(modelFit,cvPC)
                    ##prdtst[,j] <- predict(modelFit,testPC)
                    modelFit <- NULL
                }
                ## prd <- prd + Mu ## NOT necessary since Y is pretreated for cvset
    print(mse(prdcv,cvset[,1:32]))
    
    return(prdcv)
}    

knnFit <- function(trX,trY,testX)
{
    prdcv <- matrix(0,nrow=nrow(testX), ncol=32)
                ## prdtst <- matrix(0,nrow=nrow(testing), ncol=32)
                for (j in (1:32))
                {
                    training <- data.frame(Y=trY[,j],trX)
                    print(paste(" Variable:",j))
                    modelFit <- train(Y ~. , method='knn',data=training)
                    prdcv[,j] <- predict(modelFit,testX)
                                       
                }
                ## prd <- prd + Mu ## NOT necessary since Y is pretreated for cvset
    ## print(mse(prdcv,cvset[,1:32]))
    
    return(prdcv)
}

PCAPolyFit <- function(training,cvset,pca)
{
    ## create preprocess object
    preProc <- preProcess(training[,33:dim(training)[2]],method="pca",pcaComp=pca)

    ## calculate PCs for training data
    trainPC <- predict(preProc,training[,33:dim(training)[2]])

    ## calculate PCs for CV set data
    cvPC <- predict(preProc, cvset[,33:dim(training)[2]])

    ## Fitting and Predicting circulation
    prdcv <- matrix(0,nrow=nrow(cvset), ncol=32)
                                        # prdtst <- matrix(0,nrow=nrow(testing), ncol=32)
    for (j in (1:32))
    {
        print(paste("PCA:",pca,"  Variable:",j))
        modelFit <- train(training[,j] ~. , method='krlsPoly',data=trainPC,tuneGrid=expand.grid(degree=2, lambda=2))
        prdcv[,j] <- predict(modelFit,cvPC)
        ##prdtst[,j] <- predict(modelFit,testPC)
        modelFit <- NULL
    }
    ## prd <- prd + Mu ## NOT necessary since Y is pretreated for cvset
    print(mse(prdcv,cvset[,1:32]))
    
    return(prdcv)
}

PreTreat <- function(inX)
{
    bindX = exp(sin(inX[33:dim(inX)[2]])^2)
    outX = cbind(inX,bindX)
    return(outX)
}
