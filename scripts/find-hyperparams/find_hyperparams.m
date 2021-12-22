params.InputSpecgramsFile = 'specgram_fbud.h5';
params.MaxEpochs = [10 20 30];
params.LearnRate = [0.005];
params.MiniBatchSize = [256];
params.TunningIterations = 7;
params.NChannels = 2;
params.InputSize = [349 150 params.NChannels];
params.WidthAngles = [15 30 45 60 75 90];
params.ScenarioName = '4cls';
params.Layers = [
    imageInputLayer(params.InputSize)

    convolution2dLayer([3 2],16,'Stride',[2 1],'BiasLearnRateFactor',2)
    reluLayer    
    crossChannelNormalizationLayer(5,'K',1)
    
    maxPooling2dLayer([3,3],'Stride',[2 2])

    groupedConvolution2dLayer([3 3],32,2,'BiasLearnRateFactor',2)
    reluLayer    
    crossChannelNormalizationLayer(5,'K',1)   

    maxPooling2dLayer([3,3],'Stride',[2 2])

    convolution2dLayer([3 3],64,'BiasLearnRateFactor',2)
    reluLayer    
    crossChannelNormalizationLayer(5,'K',1)

    groupedConvolution2dLayer([3 3],128,2,'BiasLearnRateFactor',2)
    reluLayer    
    crossChannelNormalizationLayer(5,'K',1)

    groupedConvolution2dLayer([3 3],32,2,'BiasLearnRateFactor',2)
    reluLayer    
    crossChannelNormalizationLayer(5,'K',1)

    maxPooling2dLayer([3,3],'Stride',[2 2])
    fullyConnectedLayer(256,'BiasLearnRateFactor',2)
    reluLayer    
    dropoutLayer(0.5)
    fullyConnectedLayer(128,'BiasLearnRateFactor',2)
    reluLayer    
    dropoutLayer(0.5)
    fullyConnectedLayer(4,'BiasLearnRateFactor',2)    
    softmaxLayer
    classificationLayer];


devRecordingsT = readtable('train recordings.csv', ...
    'ReadVariableNames', true, ...
    'VariableNamingRule', 'preserve');
testRecordingsT = readtable('test recordings.csv', ...
    'ReadVariableNames', true, ...
    'VariableNamingRule', 'preserve');

dsNameBase = "/";
dsNameData = strjoin([dsNameBase, "data"], "/");
dsNameLabels = strjoin([dsNameBase, "labels"], "/");
dsNameFilenames = strjoin([dsNameBase, "filenames"], "/");
dsNameLabelNames = strjoin([dsNameBase, "labelNames"], "/");
dsNameWidth = strjoin([dsNameBase, "width"], "/");

dsFilenames = h5read(params.InputSpecgramsFile, dsNameFilenames);
meta = getSampleMetadata(dsFilenames);
uniqueHRTFNames = unique(meta.HRTFs);
uniqueHRTFGroupNames = unique(meta.HRTFGroups);

data.Labels = h5read(params.InputSpecgramsFile, dsNameLabels);
data.LabelNames = h5read(params.InputSpecgramsFile, dsNameLabelNames);
data.Width = h5read(params.InputSpecgramsFile, dsNameWidth);

iSplit = 1;
trainValSplitPoint = floor(length(devRecordingsT{:, iSplit}) * 4 / 5);

devRecordings = devRecordingsT{:, iSplit};
trainRecordings = devRecordingsT{1:trainValSplitPoint, iSplit};
valRecordings = devRecordingsT{trainValSplitPoint+1:end, iSplit};
testRecordings = testRecordingsT{:, iSplit}; 

ds = H5MatrixDatastore(params.InputSpecgramsFile, dsNameData, dsNameLabels);
devDs = ds.filterDs(@(ii) any(strcmp(meta.SongNames(ii), devRecordings)));
trainDs = ds.filterDs(@(ii) any(strcmp(meta.SongNames(ii), trainRecordings)));
valDs = ds.filterDs(@(ii) any(strcmp(meta.SongNames(ii), valRecordings)));
testDs = ds.filterDs(@(ii) any(strcmp(meta.SongNames(ii), testRecordings))); 

fprintf("all \t\t\t%d\n├─dev \t\t\t%d (%.2f%%)\n│   ├─train \t%d (%.2f%%)\n│   └─val \t\t%d (%.2f%%)\n└─test \t\t%d (%.2f%%)\n", ...
    length(ds.IndexValues), ... % all
    length(devDs.IndexValues), 100 * length(devDs.IndexValues) / length(ds.IndexValues), ...        % dev
    length(trainDs.IndexValues), 100 * length(trainDs.IndexValues) / length(devDs.IndexValues), ... % train
    length(valDs.IndexValues), 100 * length(valDs.IndexValues) / length(devDs.IndexValues), ...     % val
    length(testDs.IndexValues), 100 * length(testDs.IndexValues) / length(ds.IndexValues));         % test

assert(numel(intersect( ...
    unique(meta.SongNames(trainDs.IndexValues)), ...
    unique(meta.SongNames(testDs.IndexValues)))) == 0);
assert(numel(intersect( ...
    unique(meta.SongNames(trainDs.IndexValues)), ...
    unique(meta.SongNames(valDs.IndexValues)))) == 0);
assert(numel(intersect( ...
    unique(meta.SongNames(valDs.IndexValues)), ...
    unique(meta.SongNames(testDs.IndexValues)))) == 0);
assert(numel(intersect( ...
    trainDs.IndexValues, ...
    testDs.IndexValues)) == 0);

tunningResults = struct;
tunningCombs = allcomb(params.LearnRate, params.MiniBatchSize, params.MaxEpochs);

for iTunningIteration = 1:params.TunningIterations
    for iTunningComb = 1:size(tunningCombs, 1)
        learnRate = tunningCombs(iTunningComb, 1);
        miniBatchSize = tunningCombs(iTunningComb, 2);
        maxEpochs = tunningCombs(iTunningComb, 3);
    
        options = trainingOptions('adam', ...
            'MaxEpochs', maxEpochs, ...
            'InitialLearnRate', learnRate, ...
            'MiniBatchSize', miniBatchSize, ...
            'Shuffle', 'every-epoch', ...
            'VerboseFrequency', 1000, ...
            'ValidationFrequency', 200, ...
            'LearnRateSchedule', 'piecewise', ...
            'LearnRateDropPeriod', 10, ...
        	'LearnRateDropFactor', 0.5, ...
            'ValidationData', valDs);
    
        [net, info] = trainNetwork(trainDs, params.Layers, options);
        tunningResults(iTunningIteration, iTunningComb).Net = net;
        tunningResults(iTunningIteration, iTunningComb).Info = info;
        tunningResults(iTunningIteration, iTunningComb).LearnRate = learnRate;
        tunningResults(iTunningIteration, iTunningComb).MiniBatchSize = miniBatchSize;
        tunningResults(iTunningIteration, iTunningComb).MaxEpochs = maxEpochs;
        tunningResults(iTunningIteration, iTunningComb).ValidationLoss = info.FinalValidationLoss;
        tunningResults(iTunningIteration, iTunningComb).ValidationAccuracy = info.FinalValidationAccuracy;
        tunningResults(iTunningIteration, iTunningComb).OutputNetworkIteration = info.OutputNetworkIteration;

        fprintf("learnRate: %f,\t miniBatchSize: %d,\t accuracy: %f,\t loss: %f\n", ...
            learnRate, miniBatchSize, ...
            info.ValidationAccuracy(tunningResults(iTunningIteration, iTunningComb).OutputNetworkIteration), ...
            info.ValidationLoss(tunningResults(iTunningIteration, iTunningComb).OutputNetworkIteration));

%         testPreds = classify(net, testDs);
%         testTargets = testDs.Labels(testDs.IndexValues);
%         testAccuracy = nnz(testPreds == testTargets) / length(testDs.IndexValues);
%         fprintf('global acc: %f\n', testAccuracy);
    end % end for tunningComb
end