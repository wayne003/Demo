                                        # Load Data
load("Xsubdata.RData")
load("Ysubdata.RData")
## X.tr.org, Y.tr.org
Y.tr.org <- as.matrix(Y.tr.org)
X.tr.org <- as.matrix(X.tr.org)
X.tr.org <- scale(X.tr.org,center=T)
Mu <- mean(as.matrix(Y.tr.org))
X.tr.org <- abs(X.tr.org)
par(mfrow=c(3,1))
plot(X.tr.org[,1],type='l')
lines(X.tr.org[,2],type='l',col=2)
lines(X.tr.org[,3],type='l',col=3)
lines(X.tr.org[,4],type='l',col=4)
lines(X.tr.org[,5],type='l',col=5)
lines(X.tr.org[,6],type='l',col=6)

plot(X.tr.org[,7],type='l')
lines(X.tr.org[,8],type='l',col=2)
lines(X.tr.org[,9],type='l',col=3)
lines(X.tr.org[,10],type='l',col=4)
lines(X.tr.org[,11],type='l',col=5)
lines(X.tr.org[,12],type='l',col=6)


lam=18
X.tr.sel <- X.tr.org[,1:6]
 betar = solve(t(X.tr.sel)%*%X.tr.sel + diag(rep(lam/2*nrow(X.tr.sel)),ncol(X.tr.sel)))%*%t(X.tr.sel)%*%Y.tr.org[,1]

        ## prdicting
        prd <- X.tr.sel %*% betar
plot(prd,type='l')


plot((Y.tr.org[,1]),type='l')

par(mfrow=c(1,1))
pairs(X.tr.org[,1:6],Y.tr.org[,1])

#### try some basic algorithm
library("mgcv")
Y.tr.org <- as.matrix(Y.tr.org)
X.tr.org <- as.matrix(X.tr.org)

trainX <- X.tr.org[1:500,]
trainY <- Y.tr.org[1:500,]
testX <- X.tr.org[101:200,]
testY <- Y.tr.org[101:200,]

c <- "s(trainX[,1],k=2)"
for ( i in 2:140)
{
    c <- paste(c,"+s(trainX[,",i,"],k=2)",sep="")
}

c
f <- paste("trainY[,1]~",c,sep="")
f <- as.formula(f)
f
fitg <- gam(f)
summary(fitg)
plot(fitg,shade=T)



for (i in 30:100){
    plot(((X.tr.org[,i])^-1),Y.tr.org[,1])
    readline(prompt=paste("Column:",i,",Hit return for next"))
}
x <- c(1:10)
y <- x^-1

plot(y~x)



for (i in 1:32)
{
    ix <- i*20
    plot(Y.tr.org[,i],type='l')
    readline()
}

Ydf <- data.frame(value=as.vector(Y.tr.org))
for (i in 1:32)
{
    n <- nrow(Y.tr.org)
    Ydf$Freq[ ((i-1)*n+1) : (i*n)] <- i
    Ydf$Ts[ ((i-1)*n+1) : (i*n)] <- c(1:n)
    }



plot_ly(z=Y.tr.org,type="surface")

load("../prdkern.RData")

plot_ly(z=prd, type="surface")

## Moving Average Smoothing
bk <- c(110,175,250,285,334)
for( i in (1:32))
{
    plot(rollmean(diff(Y.tr.org[,i],3),5),type='l',main=paste("channel:",i))
    abline(v=334,col="RED",lwd=2)
    abline(v=bk,col="BLUE")
    readline()
}


## Kernel Smoothing?
for( i in (1:32))
{
    krn <- ksmooth(x=c(1:500),y=(diff(Y.tr.org[,i],5)),kernel="normal",bandwidth=30)
    plot(krn$y,type='l',main=i)
    abline(v=334,col="BLACK",lwd=2)
    abline(v=bk,col="BLUE")
    abline(v=findPeaks(krn$y,thresh=0),col="RED")
    readline()
}

## Channel Averaging
Yave <- apply(Y.tr.org,1,mean)
krn2 <- ksmooth(x=c(1:500),y=Yave,kernel="normal",bandwidth=30)
plot(krn2$y,type='l')
abline(v=bk,col="BLUE")
abline(v=findPeaks(krn2$y),col="RED")


    plot(apply(X.tr.org,1,sum),type='l',main=paste("channel:",i))
    abline(v=334,col="RED")
    abline(v=bk,col="BLUE")


fit <- lm(Y.tr.org~X.tr.org)
prdtest <- predict(fit,as.data.frame(X.tr.org))

plot(x=c(1:500),prdtest)


## Find peak
library(quantmod)
