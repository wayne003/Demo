% Reconstruct Audio Stimulus from Power Estimate
%
% Given a prediction Y_hat and corresponding phase Y_phase, 
% convert back to a sound wave and play
%
% Examples: 
%
%  % Will automatically load phase data, reconstruct sound, and play it
%  % back (if audio available)
% 
%  >> reconstruct_sound(Y_hat, Y_phase); 
%
%  % To stop playback
%  >> clear sound;
%  
%  % Will reconstruct but not play sound
%  >> reconstruct_sound(Y_hat, Y_phase, 'play_sound', 0); 
%
%  % Use audiowrite to write a .wav file to disk and play with other
%  % software
%  >> r = reconstruct_sound(Y_hat, Y_phase, 'play_sound', 0); 
%  >> audiowrite('test.wav', r, 48000); 
% 
%  % Subset Y_hat and Y_phase to perform partial reconstruction
%  % E.g., to focus on a subsection of the recording
%  >> reconstruct_sound(Y_hat(300:500, :), Y_phase(300:500, :)); 
%
%  % Or to reconstruct a single sentence
%  >> endpoints = textread('endpoints.txt'); 
%  >> ix = (endpoints(5) + 1):(endpoints(6)); 
%  >> reconstruct_sound(Y_hat(ix, :), Y_phase(ix, :)); 

function recon = reconstruct_sound(varargin)
    p = inputParser; 
    
    % Power estimate is required
    addRequired(p, 'power'); 
    
    % Phase is required (but we provide)
    addRequired(p, 'phase'); 
    
    % By default play sound
    addOptional(p, 'play_sound', 1); 
            
    parse(p, varargin{:})

    % Reconstruction parameters: 
    % TODO: Make these user controllable: 
    %  - for now, need to be manually kept in sync with prep_class_data4.m
    Fs1 = 48000; % Audio sampling rate (default for 
    wlen = 480;  % Window length: 480 - audio rate / ecog rate so that X, Y can be aligned
    h = wlen;    % Hop length: hop an entire window length each time (so STFT windows won't overlap)
    nfft = wlen; % Use the maximal number of FFT bands possible
                 % (Not actually - We can actually only sample 240 freqs with 
                 %  a 480 obs window, but this makes reconstruction a bit
                 %  easier to work with (see below))
    
    % Confirm phase and power match in size
    if any(size(p.Results.power) ~= size(p.Results.phase))
        error('Size of phase and power matrices do not match!')
    end

    % Convert power back from DB to amplitude
    Y_power = 10.^(p.Results.power./10); 
    
    % Convert from polar coordinates to Cartesian and complex-ify
    [x, y] = pol2cart(p.Results.phase, sqrt(Y_power)); 
    sig = x + 1i * y; 

    % Before we invert the Fourier transform, we need
    % to reconstruct the whole transform (all frequencies). 
    % 
    % For now, let's do this simply by filling in the ignored frequencies 
    % with zeros. Later, I might try some cross-frequency smoothing
    % approaches. 
    
    FREQ_INDX = [1:31 43]; % Hard-coded. See data processing script for details. 
    
    % 241 = 480 / 2 + 1 - maximal number of frequencies
    % Same number of time points as in original signal
    sig2 = zeros(size(sig, 1), 241); 
    sig2(:, FREQ_INDX) = sig; 

    % Use the inverse Short-Time Fourier Transform on the subsetted data
    % - processing parameters described above
    %
    % Note transpose before passing to istft.m
    [recon, ~] = istft(sig2', h, nfft, Fs1); 
    
    if p.Results.play_sound
        sound(recon, Fs1); 
    end        
end
