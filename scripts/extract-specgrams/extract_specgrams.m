startTic = tic;

params.AudioFilenamePatterns = [
    "Repository/up-down-front-back/spat/*/*.wav"];
params.OutputBaseDir = 'fbud-specgram';
params.OutputFilename = 'specgram_fbud2.h5';
params.ProcessBatchSize = 512;
params.FrameDurationSeconds = 0.04;
params.FrameHopSeconds = 0.02;
params.NChannels = 150;
params.FLow = 100;
params.FHigh = 16000;
params.DbRange = 90;
params.NSpecgrams = 2;
params.SpecgramKey = 'pchdD';

out.FullFilename = fullfile(params.OutputBaseDir, params.OutputFilename);
out.BaseDsName = "/";
out.DsData = strjoin([out.BaseDsName "data"], "/");
out.DsLabels = strjoin([out.BaseDsName "labels"], "/");
out.DsLabelGroupNames = strjoin([out.BaseDsName "labelNames"], "/");
out.DsFilenames = strjoin([out.BaseDsName "filenames"], "/");
out.DsFullFilenames = strjoin([out.BaseDsName "fullFilenames"], "/");
out.DsWidth = strjoin([out.BaseDsName "width"], "/");
out.AxisDsName = "/axis";
out.DsAxisTime = strjoin([out.AxisDsName "time"], "/");
out.DsAxisFreq = strjoin([out.AxisDsName "freq"], "/");

if exist(out.FullFilename, 'file') == 2
    delete(out.FullFilename);
end

contents = dir(params.AudioFilenamePatterns);
audioFilenames = convertCharsToStrings({contents.name});
audioFolders = convertCharsToStrings(squeeze(split({contents.folder}, filesep)));
audioFullFilenames = fullfile({contents.folder}, {contents.name});
audioFullFilenames = convertCharsToStrings(audioFullFilenames);
nAudioFilenames = length(audioFilenames);

audioInfo = audioinfo(audioFullFilenames(1));
audio.SampleRate = audioInfo.SampleRate;
audio.Duration = audioInfo.Duration;
audio.TotalSamples = audioInfo.TotalSamples;
audio.NTimeFrames = floor(audio.Duration / params.FrameHopSeconds) - 1;

specgram.WindowHopSamples = round(params.FrameHopSeconds * audio.SampleRate);
specgram.WindowLengthSamples = round(params.FrameDurationSeconds * audio.SampleRate);
specgram.Window = hamming(specgram.WindowLengthSamples);
specgram.Size = [audio.NTimeFrames, params.NChannels, params.NSpecgrams];

previewFilename = audioFullFilenames{1};
[previewStereoSignal, ~] = audioread(previewFilename);
[tValues, fValues, ~] = createSetOfSpecgrams(previewStereoSignal, params, audio, specgram);

filenameParts = arrayfun(@(x) strsplit(x, filesep), audioFilenames, 'UniformOutput', false);
filenameParts = [filenameParts{:}];
filenameParts = arrayfun(@(x) strsplit(x, '_'), filenameParts, 'UniformOutput', false);
filenameParts = cat(1, filenameParts{:});

labels = categorical(filenameParts(:, 5));
[labelsI,labelGroupNames] = grp2idx(labels);

ensembleWidth = str2double(audioFolders(:, end));

h5create(out.FullFilename, out.DsData, [specgram.Size, length(audioFilenames)], ...
    'Chunksize', [specgram.Size, 1]);
h5create(out.FullFilename, out.DsLabels, length(audioFilenames), ...
    'Chunksize', 1);
h5create(out.FullFilename, out.DsFilenames, length(audioFilenames), ...
    'ChunkSize', 1, ...
    'Datatype', 'string');
h5create(out.FullFilename, out.DsFullFilenames, length(audioFilenames), ...
    'ChunkSize', 1, ...
    'Datatype', 'string');
h5create(out.FullFilename, out.DsWidth, length(audioFilenames), ...
    'ChunkSize', 1);
h5create(out.FullFilename, out.DsLabelGroupNames, length(labelGroupNames), ...
    'Chunksize', 1, ...
    'Datatype', 'string');
h5create(out.FullFilename, out.DsAxisTime, size(tValues));
h5create(out.FullFilename, out.DsAxisFreq, size(fValues));

h5write(out.FullFilename, out.DsLabels, labelsI);
h5write(out.FullFilename, out.DsLabelGroupNames, labelGroupNames);
h5write(out.FullFilename, out.DsFilenames, audioFilenames);
h5write(out.FullFilename, out.DsFullFilenames, audioFullFilenames);
h5write(out.FullFilename, out.DsWidth, ensembleWidth);
h5write(out.FullFilename, out.DsAxisTime, tValues);
h5write(out.FullFilename, out.DsAxisFreq, fValues);

nextStartBatchPosition = 1;

diary output.log
for iBatch = 1:ceil(nAudioFilenames / params.ProcessBatchSize)    
    batchStart = nextStartBatchPosition;
    batchEnd = min(iBatch * params.ProcessBatchSize, length(audioFilenames));
    batchSize = batchEnd - batchStart + 1;
    batchFilenames = audioFullFilenames(batchStart:batchEnd);
    batchSpecgrams = zeros([specgram.Size batchSize]);

    for iFilename = 1:batchSize
        filename = batchFilenames{iFilename};
        [stereoSignal, ~] = audioread(filename);
        [~, ~, specgrams] = createSetOfSpecgrams(stereoSignal, params, audio, specgram);
		specgrams = specgrams(:, :, 1:params.NSpecgrams);
        specgrams = normalizeSpecgrams(specgrams);
        batchSpecgrams(:, :, :, iFilename) = specgrams;
    end

    h5write(out.FullFilename, out.DsData, batchSpecgrams, ...
        [1 1 1 nextStartBatchPosition], [specgram.Size batchSize]);

    nextStartBatchPosition = nextStartBatchPosition + batchSize;

    fprintf('%d/%d [start: %d, stop: %d]\n', ...
        iBatch, ceil(nAudioFilenames / params.ProcessBatchSize), ...
        batchStart, batchEnd);
end
diary off

timeElapsed = toc(startTic);
save(fullfile(params.OutputBaseDir, 'workspace'), '-v7.3')