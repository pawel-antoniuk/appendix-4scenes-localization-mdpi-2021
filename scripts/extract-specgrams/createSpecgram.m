function [timeArray, freqArray, specgram] = createSpecgram(inputSignal, params, audio, specgram)
	maxDuration = audio.TotalSamples / audio.SampleRate;
    inputSignal = inputSignal(1:audio.Duration * audio.TotalSamples / maxDuration);
    
    key = params.SpecgramKey;
    
%     Create a spectrum array (spectrogram)
    powerHzScaleFactor = 0.5 * audio.SampleRate * sum(specgram.Window.^2);
    frames = v_enframe(inputSignal, specgram.Window, specgram.WindowHopSamples);
    spectrumArray = abs(v_rfft(frames, specgram.WindowLengthSamples, 2)) .^ 2 / powerHzScaleFactor;
    
%     Time params
    pSampleFrequency = audio.SampleRate / specgram.WindowHopSamples;
    pFirstSampleTime = 0.5 * (specgram.WindowLengthSamples + 1) / audio.SampleRate;
    pHop = audio.SampleRate / specgram.WindowLengthSamples;
    pFs = [pSampleFrequency, pFirstSampleTime, pHop];
    
%     Freqency params
    pFStep = (params.FHigh - params.FLow)/(params.NChannels - 1);
    pFRange = [params.FLow pFStep params.FHigh];
    
%     Create the final spectrogram using filter bank
    [timeArray, freqArray, specgram] = v_spgrambw(spectrumArray, pFs, ...
        key, 200, pFRange, params.DbRange);
end