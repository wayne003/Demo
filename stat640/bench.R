load("/scratch/zz38/org.RData")

lam=3.2
betar= betar = solve(t(X.tr.org)%*%X.tr.sel + diag(rep(lam/2*nrow(X.tr.org)),ncol(X.tr.org)))%*%t(X.tr.org)%*%Y.tr.org
Yhats = X.tst.org %*% betar

Yhat.tst = Yhats+Mu
save(Yhat.tst,file="prdkern.RData")
