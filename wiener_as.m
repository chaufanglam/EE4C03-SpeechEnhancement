function [enhanced_speech, fs, nbits] = wiener_as(filename,outfile)

%
%  Implements the Wiener filtering algorithm based on a priori SNR estimation [1].
% 
%  Usage:  wiener_as(noisyFile, outputFile)
%           
%         infile - noisy speech file in .wav format
%         outputFile - enhanced output file in .wav format

%         
%  Example call:  wiener_as('sp04_babble_sn10.wav','out_wien_as.wav');
%
%  References:
%   [1] Scalart, P. and Filho, J. (1996). Speech enhancement based on a priori 
%       signal to noise estimation. Proc. IEEE Int. Conf. Acoust. , Speech, Signal 
%       Processing, 629-632.
%   
% Authors: Yi Hu and Philipos C. Loizou
% Modified by : Zhaofeng Lin
%
% Copyright (c) 2006 by Philipos C. Loizou
% $Revision: 0.0 $  $Date: 10/09/2006 $
%-------------------------------------------------------------------------

if nargin<2
   fprintf('Usage: wiener_as(noisyfile.wav,outFile.wav) \n\n');
   return;
end

[noisy_speech, fs]= audioread(filename);
enhanced_speech = zeros(length(noisy_speech),1);
aInfo = audioinfo(filename);
nbits = aInfo.BitsPerSample; % 16 bits resolution
% column vector noisy_speech

%% set parameter values
a_dd= 0.98; % smoothing factor in priori update
frame_dur= 20; % frame duration (20ms Hamming Window)
L= frame_dur* fs/ 1000; % L is frame length (160 for 8k sampling rate)
hamming_win= hanning( L); % hamming window
U= ( hamming_win'* hamming_win)/ L; % normalization factor

% first 120 ms is noise only
len_120ms= fs/ 1000* 120;
first_120ms= noisy_speech( 1: len_120ms);

%% use Welch's method to estimate power spectrum with Hamming window and 50% overlap
nsubframes= floor( len_120ms/ (L/ 2))- 1;  % 50% overlap
noise_ps= zeros( L, 1); %noise power spectrum
n_start= 1; 
for j= 1: nsubframes
    noise= first_120ms( n_start: n_start+ L- 1);
    noise= noise.* hamming_win;
    noise_fft= fft( noise, L); %noise FFT
    noise_ps= noise_ps+ ( abs( noise_fft).^ 2)/ (L* U);
    n_start= n_start+ L/ 2; 
end
noise_ps= noise_ps/ nsubframes;

% number of noisy speech frames 
len1= L/ 2; % with 50% overlap
nframes= floor( length( noisy_speech)/ len1)- 1; 
n_start= 1; 

for j= 1: nframes
    noisy= noisy_speech( n_start: n_start+ L- 1);
    noisy= noisy.* hamming_win;
    noisy_fft= fft( noisy, L);
    noisy_ps= ( abs( noisy_fft).^ 2)/ (L* U);
    
    if (j== 1) % initialize posteri
        posteri= noisy_ps./ noise_ps; % posteriori SNR
        posteri_prime= posteri- 1; 
        posteri_prime( find( posteri_prime< 0))= 0;
        priori= a_dd+ (1-a_dd)* posteri_prime; %a priori SNR
    else
        posteri= noisy_ps./ noise_ps; %postriori SNR
        posteri_prime= posteri- 1;
        posteri_prime( find( posteri_prime< 0))= 0;
        priori= a_dd* (G_prev.^ 2).* posteri_prev+(1-a_dd)* posteri_prime; %a priori SNR
    end
    
    G= sqrt( priori./ (1+ priori)); % gain function
   
    enhanced= ifft( noisy_fft.* G, L);
        
    if (j== 1)
        enhanced_speech( n_start: n_start+ L/2- 1)= ...
            enhanced( 1: L/2);
    else
        enhanced_speech( n_start: n_start+ L/2- 1)= ...
            overlap+ enhanced( 1: L/2);  
    end
    
    overlap= enhanced( L/ 2+ 1: L);
    n_start= n_start+ L/ 2; 
    
    G_prev= G; 
    posteri_prev= posteri;
    
end

enhanced_speech( n_start: n_start+ L/2- 1)= overlap; 

audiowrite( outfile, enhanced_speech, fs, 'BitsPerSample', nbits);
end