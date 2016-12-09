Yhat = csvread("/scratch/zz38/sentence1.csv" );
Yphase = csvread('train_Y_phase_ecog.csv');
Yhat = Yhat(2:end,1:end);
YphaseSen = Yphase(1:317,:);
r =reconstruct_sound(Yhat,YphaseSen);
## audiowrite('test.wav', r, 48000);
