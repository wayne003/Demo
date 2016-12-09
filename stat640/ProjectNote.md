## Project Log
## SEP22
Y have 32 channel, instead of fitting a giant to all of it, we can instead fitting 32 different model to it.
Branched out: MultiVariable

## SEP 25
Different methods have tried:

  * Fitting LASSO model to do model selection for 32 column of Y separately, result stored in "fitl.mtx.RData" and use the result to select the variable in a manner that filter the lasso coefficient and transform it to 0 and 1, multiply with the training dataset.
  * The resulting X matrix is then used in kernel regression.
  * So far, it worked, its better than kernel regression only. But kernel regression in general face a problem that its computational expensive, and it easily consume up to 60G of memory, and sadly thats the max possible resource for Research computing. The result is MSE 17 training from 1000 rows of data. I think it will do better with more data, but facing computational problem
  * Also, above methods have been modified for parallel computing, but the max possible dataset is 10,000 , any above will cause problem

---
Next I want to try apply PCA on X to reduce the data and then feed into kernel regression. Also, we consider other methods, such as KNN regression or step function. Even apply classification will help, but its too complicated for now.

## SEP 26

  * Have tried PCA in in caret packages, reduced X dimension into 6 (PCA=6), and cooperate with LOESS glm method, this method successfully achieve RMSE of 14.5 (give it or take) on cv set, kaggle result 16.9

## SEP 27

PCA LOG

  * PCA=2  RMSE 15.88 on CVSET
  * PCA=3  RMSE 15.90 on CVSET 
  * PCA=4  RMSE 15.80 on CVSET
  * PCA=5  RMSE 15.77 on CVSET 
  * PCA=6  RMSE 15.76 on CVSET


   ... 

The result is stored in matrix: msemtx, file='PCAmse.RData')


I'm thinking that, maybe transformation of X will be helpful, for example taking abs and then log. just a thought

## SEP 28
KNN performance is not good, PCA 80, RMSE=20 on CVSETx

PCA 6, SPAN 0.2, RMSE 15.74

The plot from previous model (gamLasso) showed that for all observation, the prediction is almost the same, that means, PCA from 420 dim to 6 dim is too much causing too much info loss, next, I'm thinking either changing it to a larger value or abondon it at all.
Next runnning KNN

## SEP 29

KNN without PCA actually gives a very good result. Fitting 10,000 rows of dataset and use the result model on CVSET which is the last 80%-90% of the dataset give a RMSE of 4.5, this is a very promising result and it looks too good to be true. However, this model takes a very long time to tune and fit. Running on subsetted dataset takes 8 hours with 16 cores on single node. The next step is to run KNN on testset, but with two different approach: one using subsetted data, one use full range of data.

## SEP 30

KNN result is still not good, but the problem is not model it self, but rather, I think its the problem of code efficiency, decided to branchout to python
KNN with nearly full subset of X gives final RMSE 16.1 on Kaggle, on own CVset gives 15.2 which is at its optimum parameter K=600
Next, I'm trying to fit kernel Ridge regression with ExpSineSquared Kernel

## OCT 16
Ridge Regression with X delayed X(t+1) and ExpSineSquared(t) together with bootstrapping have a score 15.767( lambda=2.3, Iteration=100), which is promising. Also the crossvalidation method is modified, new file is main2.R
Next step: Bagging