function [timeArray, freqArray, specgrams] = ...
        createSetOfSpecgrams(stereoSignal, params, audio, specgram) 
	
	stereoSignal = stereoSignal - ones(size(stereoSignal)) * diag(mean(stereoSignal)); % Remove DC offset  
    
    leftChannelSignal = stereoSignal(:, 1);
    rightChannelSignal = stereoSignal(:, 2);
    midSignal = stereoSignal * [1; 1];
    diffSignal = stereoSignal * [1; -1];
    
    midSignal = midSignal - mean(midSignal);
    diffSignal = diffSignal - mean(diffSignal);
    
    specgrams = zeros(audio.NTimeFrames, params.NChannels, 4);
    
    [timeArray, freqArray, specgrams(:, :, 1)] = createSpecgram(...
        leftChannelSignal, params, audio, specgram);
    [~, ~, specgrams(:, :, 2)] = createSpecgram(rightChannelSignal, ...
        params, audio, specgram);
    [~, ~, specgrams(:, :, 3)] = createSpecgram(midSignal, params, audio, specgram);
    [~, ~, specgrams(:, :, 4)] = createSpecgram(diffSignal, params, audio, specgram);
end
