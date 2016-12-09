##############################################
Data Description for Neural Speech Decoding Competition
Stat 640 / 444
Fall 2016
Genevera Allen
############################################

###############################
Files that you have been given:

-train_X_ecog.csv - a 41258 (time) x 420 (nodes by freq) matrix of
 training data (ECoG recordings); nodes by freq are stored in
 column-major order; convert these back to a tensor in Matlab via the
 following: Xmat = csvread('train_X_ecog.csv'); Xten =
 reshape(Xmat,size(Xmat,1),70,6); 

-train_Y_ecog.csv - a 41258 (time) x 32 (freq) matrix of the power
 spectrum for the speech recording; this is the response that you are
 trying to predict

-train_Y_phase_ecog.csv - a 41258 (time) x 32 (freq) matrix of the
 phase for the speech recording; you will not be predicting this; it
 is only needed to reconstruct the audio files for your predictions

-test_X_ecog.csv - a 20797 (time) x 420 (nodes by freq) matrix of
 test data (ECoG recordings); nodes by freq are stored in
 column-major order; convert these back to a tensor in Matlab via the
 following: Xmat = csvread('test_X_ecog.csv'); Xten =
 reshape(Xmat,size(Xmat,1),70,6); 

-reconstruct_sound.m (and dependencies istft.m & stft.m) - Matlab
 files to help you convert the power spectrum and phase info to an
 audio file that you can listen to.

-electrode_names.txt - a file containing the 70 electrode names

-freq_names.txt - a file containing the names of the 6 frequency bands
 along with their starting and ending points  

-train_breakpoints.txt - a vector of length 140 denoting the time
 point where each sentence ends and the audio has been spliced
 together

-test_breakpoints.txt - a vector of length 70 denoting the time
 point where each sentence ends and the audio has been spliced
 together

-train_sentence.txt - a text file with the 140 training sentences.

-benchmark_ridge.m - a Matlab script to compute the ridge regression
 benchmark solution that is posted to the Kaggle leaderboard

-README_ecog.txt - this file!
############################################

############################################
How to Submit an Entry to Kaggle:

Submissions to the Kaggle leaderboard must be of a specific form.
Submissions should be a matrix with two
columns, "Id" and "Prediction", in .csv format.    The "Id" is a
unique numeric Kaggle identifier from 1 to 665504 (20797 time points *
32 frequencies in column-major order) and the "Prediction" is your
predicted power spectrum of the audio signal.  A Matlab script for the
ridge regression benchmark as well as code to format a Kaggle
submission is given in benchmark_ridge.m
#######################################################################

#######################################################################
Further Information on Data Pre-processing:
(Provided by Michael Weylandt - Thanks, Michael!)

## ECOG Data ($X$)

The ECOG data was provided by Muge Ozker (BCM, Beauchamp Lab) as a $210
\times 70 \times 106 \times 601$ 4D tensor. This corresponds to an
experimental design consisting of: 

* 210 trials (3 groups of 70 trials)
* 70 nodes
* 106 frequencies
* 601 time points (though most trials are significantly shorter)

In each trial, the patient was played an audio recording of a short
English-language sentence (*e.g.*, 'Doris ordered twelve white cats'),
followed by a 'target word' (*e.g.*, 'prefers'). The patient then
indicated whether the target word appeared in the sentence. In roughly
half the trials, the audio recording had accompanying video (of the
person saying the sentence); in the other half, a static image of a
face was presented. We have indicators of whether video was supplied,
but did not include it as part of the competition data. I do not
believe that we have an indicator of whether the patient correctly
determined whether the target word was in the sentence. The trials
were performed over 3 different sessions of 70 sentences per session
(no repeats).  

Recordings were taken at 100 Hz (*i.e.*, a sample every 10ms or 0.01s)
for approximately 1.5s before the beginning of the audio recording
utill the end of the recording. The longest audio recording was
approximately 4.5s, corresponding to a total of 601 time points. The
ECOG output was transformed to the spectral domain using standard
multi-taper techniques to obtain 106 frequencies, ranging from
approximately 0.95 Hz to 200 Hz,  at each of the 70 ECOG nodes and
each of the (up to) 601 time points. For shorter stimuli, the
transformed data was padded with `NaN` to 601 time points. The power
of the spectral representation was converted to DB and reported; the
phase information was discarded.  

To prepare this data for class use, the 106 frequencies were reduced
to 6 bands by averaging over all frequencies within the band 

Band Name  | Lower Bound | Upper Bound
-----------|-------------|------------
Delta      | 2.05        | 3.94
Theta      | 5.04        | 6.92
Alpha      | 8.03        | 11.96
Beta       | 16.06       | 23.93
Low Gamma  | 30.07       | 53.99
High Gamma | 70.05       | 179.93

yielding a $210 \times 70 \times 6 \times 601$ tensor. Finally, the
tensor was matricized along its first axis by removing the 1.5s
pre-stimulus period, concatenating the stimulus periods, and removing
the `NaN` padding; this yielded a $70 \times 6 \times 62055$ 3-mode tensor.  


## Audio Data ($Y$)

The audio data was extracted from the 210 raw audio files. 

The audio files were truncated to align with the corresponding $X$
data and transformed to the spectral domain using a *Short Time
Fourier Transform* routine taken from [Mathworks
FileExchange](https://www.mathworks.com/matlabcentral/fileexchange/45197-short-time-fourier-transformation--stft--with-matlab-implementation).  

The STFT was performed on non-overlappling windows of 480
observations, where 480 was chosen to align the audio and ECOG
samples[^2]. This results in a maximal set of 241 frequencies.[^3] Of
these frequencies, the 32 with the highest power were chosen[^f] and
the remaining 209 were dropped. Finally, the power at these 32
frequencies was converted to DB and arranged in a $62055 \times 32$
matrix aligned with the $X$-tensor.[^4] 


[^2]: The raw audio was recorded at 48000 Hz while the ECOG data was
sampled at 100 Hz. Taking the ratio, we obtain a window length of $480
= 48000 \text{ Hz} / 100 \text{ Hz}$.  

[^3]: 480 observations give 240 distinct non-zero frequencies plus an
additional 0 (constant baseline) term.  

[^f]: The chosen frequencies run from 0 Hz to 3000 Hz (inclusive) in
equally spaced units of 100 Hz and an additional frequency at 4200
Hz. This provides relatively uniform coverage of the major range of
human vocal speech: see, *e.g.*, the entry on 'Voice Frequency' in
*Federal Standard 1037C: Glossary of Telecommunications Terms*,
available at <http://www.its.bldrdoc.gov/fs-1037/fs-1037c.htm>. 

[^4]:  The phase of the spectral representation of this signal was
recorded and stored separately for reconstruction; it is not part of
the 'official' competition data.  

## Final Processing

Finally, the joined $X$ and $Y$ tensors were split following the 140th
trials to create contiguous training and test sets.   

