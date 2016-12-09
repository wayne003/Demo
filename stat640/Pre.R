## Multiple Model with Resampling (20%-60%-20%)
## Base Model: Ridge
##
## Smoothing:
##    Smooth the data using a method similiar to simple moving average, but instead of relying on the past data, we take the average as follows X(t) = 0.9*X(t+1) + 0.1*X(t-1)
##  This method is inspired by the fact that there's slight delay in brain activity responding to audio signal.
##
## Add term:
##    1) Delayed 1 , append 0 at end of X matrix
##    2) ExpSinSquared(Xt), append as column
##
## Resampling:
##    1) Resampling based on breakpoints
##    2) Weight is applied, more weight on sentences that have rare word
##
## MultiModel:
##    Cut sentence into 3 part, fit a model to each part
##
## Note:
##    ZZ: kaggle socre 15.26 (2016-Nov-5)

load("/scratch/zz38/org.RData")
source("function.R")
CVSwitch=1
lam <- rep(30,5)

## library(doMC)
## registerDoMC(3)
library(stringr)
library(parallel)

##nocores <- detectCores() - 1
##cl <- makeCluster(nocores,type='FORK')

PreProcess <- function(inData,mode="Delayed",pcaN=600)
{
    inData <- as.matrix(inData)
    if (mode=="Delayed" | mode=="DelayedPCA")
    {

	## Train
        trans <- inData


        ## Future 1
        ##trans0 <- rbind(trans,0)
        ##trans0 <- trans0[-1,]
       
        ## Combine ExpSineSquared
        trans1 <- cbind(exp(sin( trans )^2),trans)
	## trans1 <- cbind(sin(trans),cos(trans),sin(trans/2),cos(2*trans),sin(1/(trans+0.001)),trans1)
        ## trans1 <- cbind(trans1,trans^2,trans^3)
        outData0 <- trans1
                       
        if (mode=="DelayedPCA")
        {
            ## PCA
            require(caret)
            outData0.df <- createDataframe(outData0,mode=1)
            PCAProc <- preProcess(outData0.df,method='pca',pcaComp=pcaN)
            outPC <- predict(PCAProc,outData0.df)
            outData <- cbind(1,outPC)
        }
        else
        {
            outData <- cbind(1,outData0)
        }
    }
    
    return(outData)
}
    
RidgeFit <-  function(indf,lambda)
{
    Xtr <- as.matrix(PreProcess(indf[,33:ncol(indf)]))
    Ytr <- as.matrix(indf[,1:32])
    
    ## Fitting
    XTX <- t(Xtr) %*% Xtr
    beta <- solve(XTX + diag(rep(lambda/2*nrow(Xtr)),ncol(Xtr)))%*% t(Xtr) %*% Ytr
    return(beta)
}


RidgePredict <- function(indf,betar,startpt=33)
{
    ## startpt is used to adapt for dataset including Y
    Xtr <- as.matrix(PreProcess(indf[,startpt:ncol(indf)]))
    return(Xtr %*% betar)
}    


TreeFit <- function(indf,m,complex=0.01)
{
    indf <- as.data.frame(indf)
    require(rpart)
    TreeForm <- as.formula(paste("Y",m,"~.",sep=""))
    klist <- c(1:32)[-m]
    subdf <- indf[,-klist]
    return(rpart(TreeForm,data=subdf,method="anova",control=rpart.control(cp=complex)))
}

TreeFitP <- function(indf,cp=0.01,clst=cl)
{
    indf <- as.data.frame(indf)
    require(rpart)
    Tfit <- parLapply(clst,1:32,TreeFit,complex=cp,indf=indf)
    return(Tfit)
}

TreePredict <- function(indf,inmodelList,m)
{
    indf <- as.data.frame(indf)
    require(rpart)
    Tpredict <- predict(inmodelList[[m]],newdata=indf)
    return(Tpredict)
}

TreePredictP <- function(indf,inmodelList,clst=cl)
{
    indf <- as.data.frame(indf)
    require(rpart)
    TPredict <- lapply(1:32,TreePredict,indf=indf,inmodelList=inmodelList)
    TPredict.mtx <- matrix(unlist(TPredict),byrow=F,ncol=32)
    return(TPredict.mtx)
}

NFold <- function(fold=5,fold_id,inmatrix)
{
    nobs <- nrow(inmatrix)
    cut <- floor(nobs/fold)
    if ( fold_id != fold )
    {
        id_low <- cut * (fold_id -1) +1
        id_high <- cut * fold_id
    } else
    {
        id_low <- cut * (fold_id -1) +1
        id_high <- nobs
    }
    cvset_id <- id_low:id_high
    cvset <- inmatrix[cvset_id,]
    training <- inmatrix[-cvset_id,]
    return(list(training.idx=training,cvset.idx=cvset))
}    



DataPartition <- function(breakpoints)
{
    ## Create index accroding to breakpoints
    ## Output list, with each member being a data chunk (sentence)
    nchunck <- nrow(breakpoints)
    
    breakpoints0 <- rbind(0,breakpoints)
    idx.partition <<- list()

    ## Cut word (5 WORD 20%)
    Wid <- matrix(nrow=nchunck,ncol=2*5)

    ## Structure of Wid
    ##
    ## -----------------------------------------------
    ## 1 | Word1 start | Word 1 end | Word 2 start |...
    ## -----------------------------------------------
    
    ## Generate cut point
    for ( i in 1:nchunck)
    {
        distance0 <-  abs( breakpoints0[i+1,1] - breakpoints0[i,1] )
        distance <- c()
        distance[1] <- 0
        distance[2] <- floor(distance0*0.20)
        distance[3] <- floor(distance0*0.40)
        distance[4] <- floor(distance0*0.60)
        distance[5] <- floor(distance0*0.80)
        distance[6] <- floor(distance0*1)


        for ( j in 1:5)
        {
            
            Wid[i,2*j-1] <- breakpoints0[i,1] + distance[j] +1 
            Wid[i,2*j] <- breakpoints0[i,1] + distance[j+1]
        }
    

    }

    ## Adjust for end point
    Wid[,5*2] <- breakpoints[,1]
    return(Wid)
}


ObsJoin <- function(inid,indf)
{
    ## Assume its nx2 dimension
    ## to avoid condition statement
    outid <- inid[1,1]:inid[1,2]
    for ( i in 2:nrow(inid) )
    {
        ## print(i)
        temp <- inid[i,1]:inid[i,2]
        outid <- c(outid,temp)
    }
    outdf <- indf[outid,]
    return(outdf)
}


######################################################

keep <- c(3,4,6,9,10,11,12,14,15,16,21,22,24,25,26,29,33,34,36,40,41,48,55,56,57,59,70,72,73,76,78,79,80,81,82,84,85,86,92,93,94,97,99,101,104,105,106,109
               ,111,122,123,125,129,137,138,139,143,144,148,149,150,151,153,154,155,156,162,163,164,169,171,173,174,175,176,179,180,195,199,205,206,207,208,209
               ,210,211,212,213,214,215,216,217,218,219,221,223,224,226,231,232,233,234,239,240,241,243,244,246,249,250,265,275,276,277,278,279,280,289,291,293
               ,296,302,307,313,314,318,319,328,335,341,345,346,347,348,349,350,354,355,358,362,363,364,365,371,372,373,381,385,390,401,403,404,405,407,409,410
               ,411,413)
        
## Training Scale per sentence
breakpoints.tr <- read.table('train_breakpoints.txt',header=F)

perX.tr <- PerScaleX(X.tr.org[,keep],breakpoints.tr)
colnames(perX.tr) <- str_replace(colnames(perX.tr),"[A-Z]|[a-z]","X")
training <- createDataframe(perX.tr,Y.tr.org,mode=0)
colnames(training)[33:ncol(training)] <- colnames(perX.tr)

## Testing Scale per sentece
breakpoints.tst <- read.table('test_breakpoints.txt',header=F)
testingX <- PerScaleX(X.tst.org[,keep], breakpoints.tst)
colnames(testingX) <- str_replace(colnames(testingX),"[A-Z]|[a-z]","X")

## Reference data ( kaggle score 15.73 ) DO NOT ABUSE!!
Yref <- matrix(read.csv('/scratch/zz38/Prediction3.csv',header=T)[,2],ncol=1)
                                        


msestst <- msetst <- msecv <- c()

## Sampling weights
train_sentences <- read.table("/scratch/zz38/train_sentences.txt",header=F)
wordtable <- apply(train_sentences,2,table)
## small1 <- names(which(wordtable$V1<10)) 
small2 <- names(which(wordtable$V2<11)) 
small3 <- names(which(wordtable$V3<10))
small4 <- names(which(wordtable$V4<10))
small5 <- names(which(wordtable$V5<5))


weights <- 0.1
## weights <- ifelse(train_sentences$V1 %in% small1, weights+0.05 ,weights )
## weights <- ifelse(train_sentences$V2 %in% small2, weights+0.2 ,weights )
weights <- ifelse(train_sentences$V3 %in% small3, weights+0.2 ,weights )
weights <- ifelse(train_sentences$V4 %in% small4, weights+0.2 ,weights )
weights <- ifelse(train_sentences$V5 %in% small5, weights+0.6 ,weights )
weights <- matrix(weights,ncol=1)

CorResultTrain <- readRDS('/scratch/zz38/CorResultTrain.rds')

msecv <- matrix(0,nrow=10,ncol=1)

## Gerate index Matrix (sentences cut point) including word cut
idpartition <- DataPartition(breakpoints.tr)
