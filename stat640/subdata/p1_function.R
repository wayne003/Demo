## Function for problem2
## What it has?
### Data sampling and spliting
### Kernel Functions
### Kernel Ridge Regression Functions
require(compiler)
enableJIT(3)

resample.data <- function(indata)
{
    ## This function is used to resample and resplit data into train,cv,test, it is designed to interact with global env.
    
    rdidx <<- sample(1:nrow(indata)) 
    id.train <<- rdidx[1:floor(0.6*length(rdidx))]
    id.cv <<- rdidx[ (floor(0.6*length(rdidx))+1) : ( floor(0.8*length(rdidx)) ) ]
    id.test <<- rdidx[ (floor(0.8*length(rdidx))+1) : (length(rdidx)) ]

    training <<- indata[id.train,]
    cv <<- indata[id.cv,]
    tst <<- indata[id.test,]

    Y_tr <<- as.numeric(training[,1]); Y_tr<- Y_tr-mean(Y_tr)
    X_tr <<- as.matrix(training[,-1]); X_tr<- scale(X_tr,center=T,scale=T)

    Y_cv <<- as.numeric(cv[,1]); Y_cv <- Y_cv-mean(Y_cv)
    X_cv <<- as.matrix(cv[,-1]); X_cv <- X_cv-mean(X_cv)


    Y_tst <<- as.numeric(tst[,1]); Y_tst <- Y_tst-mean(Y_tst)
    X_tst <<- as.matrix(tst[,-1]); X_tst <- X_tst-mean(X_tst)
}

## Kernel function
## linear kernel k = xx, this kernel is used to test algorithm, the result should be the same as ridge regression
kernel.linear <- function(X1,X2)
{
    K <- X1 %*% t(X2)
    return(K)
}

## Polynomial Kernel
library(expm) 
kernel.poly <- function(X1,X2,d=2,c=1)
{
    K <- (c + X1 %*% t(X2) ) ^ d
    return(K)
} 

## Gaussian Kernel
kernel.gaussian <- function(X1,X2,sigma=2)
{
    K <- matrix(0,ncol=dim(X2)[1],nrow=dim(X2)[1])
    for (i in 1:dim(X2)[1])
    {
        for (j in 1:i)
        {
            s <- sum( (X1[i,]-X2[j,]) ^2)
            K[i,j] <- exp(-s/sigma)
        }
    }
    K <- K + t(K)
    return (K)
}

## Exponential Kernel
kernel.exp <- function(X1,X2,sigma=2)
{
    K <- matrix(0,ncol=dim(X2)[1],nrow=dim(X2)[1])
    for (i in 1:dim(X2)[1])
    {
        for (j in 1:i)
        {
            s <- sum(X1[i,] %*% X2[j,])
            K[i,j] <- exp(s)
        }
    }
    K <- K + t(K)
    return (K)
}


## Function to fit kernel RR

kernRR.fit <- function(X,Y,K=kernel.linear(X,X),lambda=1)
{
    
    alpha <- solve( (K + lambda * diag(nrow(K))) ) %*% Y 
    return(alpha)
}

kernRR.prd <- function(alpha,K=kernel.linear(X.test,X))
{
    prd <- t(alpha[1:dim(K)[1],]) %*% K
    return(t(prd))
}                          


## Function to calculate MSE
mse <- function(prd,tru)
{
    m <- mean( (prd-tru)^2 )
    return(sqrt(m))
}

## Function for LS, Ridge Bestsubset etc.
## LS, Ridge, Bestsubset,Lasso,elastic, adaptive lasso,MC+
    
library(ncvreg)
library(glmnet)

bunchreg <- function(X,Y,lam=rep(1,6))
{
      
    betals = solve(t(X)%*%X)%*%t(X)%*%Y
    betar = solve(t(X)%*%X + diag(rep(lam[1]/2*nrow(ozone),8)))%*%t(X)%*%Y
    fitl = glmnet(x=X,y=Y,family="gaussian",lambda=lam[2],alpha=1)
    fital = glmnet(x=X,y=Y,family="gaussian",lambda=lam[3],alpha=1,penalty.factor=1/abs(betals))
    fitel = glmnet(x=X,y=Y,family="gaussian",lambda=lam[4],alpha=.5)
    fitscad = ncvreg(X,Y,family="gaussian",penalty="SCAD",lambda=lam[5])
    fitmcp = ncvreg(X,Y,family="gaussian",penalty="MCP",lambda=lam[6])
    mat = cbind(betals,betar,as.matrix(fitl$beta),as.matrix(fital$beta),as.matrix(fitel$beta),fitscad$beta[-1],fitmcp$beta[-1])
    colnames(mat) = c("LS","Ridge","Lasso","A-Lasso","EL","SCAD","MC+")
    return(mat)
}


prdreg <- function(beta,X,Y.test)
{
    ## beta dimension: P x 1
    ## X dim: n x p
    ## Y test: testing data (response)
    prd <- (X %*% beta)
    rmse <- mse(prd,Y.test)
    return(list(prd=prd,mse=rmse))
}

## Best subset required library
library(MASS)
library(leaps)

