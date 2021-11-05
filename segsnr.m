function [segSNR] = segsnr(clean_speech,enhanced,fs)

N = 25*fs/1000; %length of the segment in terms of samples
M = fix(size(clean_speech,1)/N); %number of segments
% segSNR = zeros(size(enhanced));
segSNR = 0;
    for m = 0:M-1
        sum1 =0;
        sum2 =0;
        for n = m*N +1 : m*N+N
            sum1 = sum1 +sum(abs(clean_speech(n)).^2);
            sum2 = sum2 +sum(abs(enhanced(n) - clean_speech(n)).^2);
        end
        r = 10*log10(sum1/sum2);
        if r>35
            r = 35;
        elseif r < -10
            r = -10;
        end
       
        segSNR = segSNR +r;
    end
    segSNR= segSNR/M;