clear;close all;clc;

%% Read Audio
noise_type = 'speech-shaped'; % Choose noise type from 'AWGN', 'babble', 'speech-shaped'
SNR = 5;
[clean, fs] = audioread('clean speech.wav');
switch noise_type
    case 'AWGN'
        x = awgn(clean,SNR,'measured');
        noise = x-clean;
    case 'babble'
        [noise, ~] = audioread('babble noise.wav');
        N = length(clean);
        clean = clean(1:N);
        noise = noise(1:N);
        noise = noise/norm(noise).*10^(-SNR/20)*norm(clean);
        x = clean+noise; % add noise
    case 'speech-shaped'
        [noise, ~] = audioread('stationary speech-shaped noise.wav');
        N = length(clean);
        clean = clean(1:N);
        noise = noise(1:N);
        noise = noise/norm(noise).*10^(-SNR/20)*norm(clean);
        x = clean+noise; % add noise
end

%% Process
audiowrite('mixed.wav',x,fs); % write noisy signal
enhanced_speech = wiener_as('mixed.wav','enhanced_speech.wav'); 

power_clean = sum(abs(clean).^2);
power_noise = sum(abs(noise).^2);
power_noise_af = sum(abs(enhanced_speech-clean).^2);
power_enhanced = sum(abs(enhanced_speech).^2);

%% Evaluate
% SNR
snr_before = 10*log10(power_clean/power_noise);
snr_after = 10*log10(power_enhanced/power_noise_af);
snr_ip = snr_after - snr_before;
% SNR_seg
ssnr_before = segsnr(clean,x,fs);
ssnr_after = segsnr(clean,enhanced_speech,fs);
ssnr_ip = ssnr_after - ssnr_before;
% pesq
addpath PESQ;
pesq_before = pesq('clean speech.wav','mixed.wav');
pesq_after = pesq('clean speech.wav','enhanced_speech.wav');
% stoi
stoi_before = stoi(clean,x,fs);
stoi_after = stoi(clean,enhanced_speech,fs);

result_name = 'result\babble_0_hann.xls';
result = {'snr_before' 'snr_after' 'snr_ip' 'ssnr_before' 'ssnr_after' 'ssnr_ip' ...
    'pesq_before' 'pesq_after' 'stoi_before' 'stoi_after' ;...
    snr_before snr_after snr_ip ssnr_before ssnr_after ssnr_ip ...
    pesq_before pesq_after stoi_before stoi_after};
writecell(result,result_name);
%% Plot figures
t=(0:N-1)/fs;
figure(1)
subplot(321);
plot(t,clean);ylim([-1.5,1.5]);title('clean speech');xlabel('t/s');ylabel('Amplitude');
subplot(323);
plot(t,x);ylim([-1.5,1.5]);title('noisy speech');xlabel('t/s');ylabel('Amplitude');
subplot(325);
plot(t,real(enhanced_speech));ylim([-1.5,1.5]);title('enhanced speech');xlabel('t/s');ylabel('Amplitude');
subplot(322);
spectrogram(clean,256,128,256,16000,'yaxis');
subplot(324);
spectrogram(x,256,128,256,16000,'yaxis');
subplot(326);
spectrogram(enhanced_speech,256,128,256,16000,'yaxis');
