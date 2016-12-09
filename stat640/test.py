import numpy as np
import time

def readData():
    print("Reading Data...")
    global Xtr_org
    global Ytr_org
    global Xtst_org
    Xtr_org = np.genfromtxt('/scratch/zz38/train_X_ecog.csv',delimiter=',')
    Ytr_org = np.genfromtxt('/scratch/zz38/train_Y_ecog.csv',delimiter=',')
    Xtst_org = np.genfromtxt('/scratch/zz38/test_X_ecog.csv',delimiter=',')
    np.savez('/scratch/zz38/pyXYecog',Xtr=Xtr_org,Ytr=Ytr_org,Xtst=Xtst_org)


def loadData():
    global Xtr_org
    global Ytr_org
    global Xtst_org
    print("Loading Data...")
    npzfile = np.load('/scratch/zz38/pyXYecog.npz')
    Xtr_org = npzfile['Xtr']
    Ytr_org = npzfile['Ytr']
    Xtst_org = npzfile['Xtst']

def tableOutput(inArray):
    print("Flatting Dataset...")
    inArrayFlat = inArray.transpose().reshape(inArray.size)
    f = open('Prediction.csv','w')
    f.write('Id,Prediction\n')
    for i in range(len(inArrayFlat)):
        f.write("%d,%15f\n"%(i+1,inArrayFlat[i]))
    f.close()

def csvOutput(inArray):
    print("Saving matrix as CSV...")
    np.savetxt("prdArray.csv", inArray, delimiter=",")

    
def performPCA(inArray,pca):
    from sklearn.decomposition import PCA
    Out = PCA(n_components=pca).fit_transform(inArray)
    return Out

## Function to calculate MSE
def mse(predict,actual):
    return np.sqrt(((predict-actual) **2).mean())

# Fit KernelRidge with parameter selection based on 5-fold cross validation
## Kernel used: ExpSineSquared

def kRR(trainX,trainY,cvsetX,cvsetY):
    from sklearn.kernel_ridge import KernelRidge
    from sklearn.model_selection import GridSearchCV
    param_grid = {"alpha": [1e0, 1e-1, 1e-2, 1e-3],
                  "kernel": [ExpSineSquared(l, p)
                             for l in np.logspace(-2, 2, 10)
                             for p in np.logspace(0, 2, 10)]}
    kr = GridSearchCV(KernelRidge(), cv=5, param_grid=param_grid)
    stime = time.time()
    kr.fit(trainX, trainY)
    print("Time for KRR fitting: %.3f" % (time.time() - stime))
    prdkr = kr.predict(cvsetX)
    print("MSE on testset: %.3f:" %mse(prdkr,cvsetY))

def GPR(trainX,trainY,cvsetX,cvsetY):
    from sklearn.gaussian_process import GaussianProcessRegressor
    from sklearn.gaussian_process.kernels import WhiteKernel, ExpSineSquared
    print("GPR Processing...")
    gp_kernel = ExpSineSquared(1.0, 5.0, periodicity_bounds=(1e-2, 1e1)) \
                + WhiteKernel(1e-1)
    gpr = GaussianProcessRegressor(kernel=gp_kernel)
    stime = time.time()
    gpr.fit(trainX, trainY)
    print("Time for GPR fitting: %.3f" % (time.time() - stime))
    prdgpr = gpr.predict(cvsetX)
    print("MSE on testset: %.3f:" %mse(prdgpr,cvsetY))

def KNN(trainX,trainY,cvsetX,cvsetY,testX,cv=1):
    ## Fitting and Predicting
    print("KNN Processing...")
    from sklearn.neighbors import KNeighborsRegressor
    neigh = KNeighborsRegressor(n_neighbors=600,weights='uniform')
    neigh.fit(trainX,trainY)
    if cv==1:
        print("CrossValidation Dataset: Predicting Data...")
        prd = neigh.predict(cvsetX)
        print("MSE=%f" %mse(prd,cvsetY))
        prdcv = prd+MuArray
        return(prdcv)
    else:
        print("Test Dataset: Predicting Data...")
        prd_tst = neigh.predict(testX) + MuArray
        return(prd_tst)

def RDG(trainX,trainY,cvsetX,cvsetY,testX,cv=1):
    from sklearn.linear_model import Ridge
    print("Ridge Regression Fitting..")
    rdg = Ridge(alpha=2*len(trainY),fit_intercept=True)
    rdg.fit(trainX,trainY)
    if cv==1:
        print("CrossValidation Dataset: Predicting Data...")
        prd = rdg.predict(cvsetX)
        print("MSE=%f" %mse(prd,cvsetY))
        prdcv = prd+MuArray
        return(prdcv)
    else:
        print("Test Dataset: Predicting Data...")
        prd_tst = rdg.predict(testX) + MuArray
        return(prd_tst)

def LASSO(trainX,trainY,cvsetX,cvsetY,testX,cv=1):
    from sklearn.linear_model import Lasso
    print("LASSO Fitting..")
    lso = Lasso(alpha=1.5)
    lso.fit(trainX,trainY)
    if cv==1:
        print("CrossValidation Dataset: Predicting Data...")
        prd = lso.predict(cvsetX)
        print("MSE=%f" %mse(prd,cvsetY))
        prdcv = prd+MuArray
        return(prdcv)
    else:
        print("Test Dataset: Predicting Data...")
        prd_tst = lso.predict(testX) + MuArray
        return(prd_tst)

def moving_average(a):
    import pandas as pd
    s = pd.Series(a)
    out = s.cumsum() / pd.Series(np.arange(1, len(s)+1), s.index)
    return(np.array(out))

def sinSignal(inX):
    from scipy.stats import zscore
    print("Transform to Sine Cose Periodic Form...")
    X00 = zscore(inX)
    X0 = np.sin(X00)
    X1 = np.exp(X0)
    X2 = np.square(X1)

    #X = np.append(X0, np.sin(X0/2), axis=1)
    #X = np.append(X, np.cos(2*X0), axis=1)
    #X = np.append(XX1,XX2, axis=1)
    X = np.append(inX,X2,axis=1)
    return(X)

def PCASel(trainX,targetX):
    print("PCA transforming...")
    from sklearn.decomposition import PCA
    pca = PCA(n_components=np.rint(trainX.shape[1]*0.9).astype(int))
    pca.fit(trainX)
    print(pca.explained_variance_ratio_) 
    Xnew = pca.fit_transform(targetX)
    return(Xnew)

def main():

    ## Global Variable
    global MuArray
    ## readData()
    loadData()

    for pcanum in range(80,81):
        print("PCA:",pcanum)
        Xtr_PCA = performPCA(Xtr_org,pcanum)
        Xtst_PCA = performPCA(Xtst_org,pcanum)

        ## Centering and scaling
        from sklearn import preprocessing
        Xtr_scaled = preprocessing.scale(Xtr_PCA)
        Xtst_scaled = preprocessing.scale(Xtst_PCA)

        Mu = Ytr_org.mean()
        MuArray = 0
        ## MuArray = np.array(Mu)
        Ytr_centered = Ytr_org - MuArray

        ## Subsetting dataset
        Xtr_s = Xtr_scaled[1:40000,:]
        Ytr_s = Ytr_centered[1:40000,:]

        Xcv_s = Xtr_scaled[40310:41258,:]
        Ycv_s = Ytr_centered[40310:41258,:]

        # Xtst_s = Xtr_scaled[36138:41258,:]
        # Ytst_s = Ytr_centered[36138:41258,:]




        # Xtr_s0 = Xtr_s
        # Xcv_s0 = Xcv_s

        Xtr_s0 = sinSignal(Xtr_scaled)
        Xcv_s0 = sinSignal(Xcv_s)
        Xtst_s0 = sinSignal(Xtst_scaled)

        # Xtr_sel = PCASel(Xtr_s0,Xtr_s0)
        # Xcv_sel = PCASel(Xtr_s0,Xcv_s0)

        prd = RDG(Xtr_s0,Ytr_centered,Xcv_s0,Ycv_s,Xtst_s0,cv=0)
        tableOutput(prd)
        csvOutput(prd)

        

if __name__ == "__main__":
    main()
