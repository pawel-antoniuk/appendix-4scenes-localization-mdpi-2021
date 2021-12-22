params.InputSpecgramsFile = 'specgram_fbud.h5';
params.MaxEpochs = 30;
params.LearnRate = 0.001;
params.MiniBatchSize = 256;
params.EvaluationIterations = 7;
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
devRecordings = devRecordingsT{:, iSplit};
testRecordings = testRecordingsT{:, iSplit}; 

ds = H5MatrixDatastore(params.InputSpecgramsFile, dsNameData, dsNameLabels);
devDs = ds.filterDs(@(ii) any(strcmp(meta.SongNames(ii), devRecordings)));
testDs = ds.filterDs(@(ii) any(strcmp(meta.SongNames(ii), testRecordings))); 

fprintf("all \t\t\t%d\n├─dev \t\t\t%d (%.2f%%)\n└─test \t\t%d (%.2f%%)\n", ...
    length(ds.IndexValues), ... % all
    length(devDs.IndexValues), 100 * length(devDs.IndexValues) / length(ds.IndexValues), ...        % dev
    length(testDs.IndexValues), 100 * length(testDs.IndexValues) / length(ds.IndexValues));         % test

assert(numel(intersect( ...
    unique(meta.SongNames(devDs.IndexValues)), ...
    unique(meta.SongNames(testDs.IndexValues)))) == 0);
assert(numel(intersect( ...
    devDs.IndexValues, ...
    testDs.IndexValues)) == 0);

trainingResults = struct;

for iEvaluationIteration = 1:params.EvaluationIterations
    options = trainingOptions('adam', ...
        'MaxEpochs', params.MaxEpochs, ...
        'InitialLearnRate', params.LearnRate, ...
        'MiniBatchSize', params.MiniBatchSize, ...
        'Shuffle', 'every-epoch', ...
        'VerboseFrequency', 200, ...
        'LearnRateSchedule', 'piecewise', ...
        'LearnRateDropPeriod', 10, ...
    	'LearnRateDropFactor', 0.5);

    [net, info] = trainNetwork(devDs, params.Layers, options);
    
    testPreds = classify(net, testDs);
    testTargets = testDs.Labels(testDs.IndexValues);
    testAccuracy = nnz(testPreds == testTargets) / length(testDs.IndexValues);
    fprintf('test acc: %f\n', testAccuracy);    

    trainingResults(iEvaluationIteration).Net = net;
    trainingResults(iEvaluationIteration).Info = info;
    trainingResults(iEvaluationIteration).LearnRate = params.LearnRate;
    trainingResults(iEvaluationIteration).MiniBatchSize = params.MiniBatchSize;
    trainingResults(iEvaluationIteration).MaxEpochs = params.MaxEpochs;
    trainingResults(iEvaluationIteration).TestAccuracy = testAccuracy;
end