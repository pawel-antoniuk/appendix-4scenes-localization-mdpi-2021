params.InputSpecgramsFile = 'specgram_fbud.h5';
params.MaxEpochs = 30;
params.LearnRate = [0.001];
params.MiniBatchSize = [256];
params.EvaluationIterations = 4;
params.NChannels = 2;
params.InputSize = [349 150 params.NChannels];
params.WidthAngles = [15 30 45 60 75 90];
params.ScenarioName = '4cls';
params.HRTFTrainTestScenarios = [
    "hutubs" "sadie"
    "th-koln" "tu-berlin"];

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

evaluationResults = struct;   
for iEvaluationIteration = 1:params.EvaluationIterations
    for iHRTFScenario = 1:size(params.HRTFTrainTestScenarios,1)
        selHRTFGrps = strcmp_m(uniqueHRTFGroupNames, ...
            params.HRTFTrainTestScenarios(iHRTFScenario,:));

        devDs = ds.filterDs(@(ii) any(strcmp(meta.SongNames(ii), devRecordings)));
        devDs = devDs.filterDs(@(ii) ~any(strcmp(meta.HRTFGroups(ii), selHRTFGrps)));
    
        testDs = ds.filterDs(@(ii) any(strcmp(meta.SongNames(ii), testRecordings))); 
        testDs = testDs.filterDs(@(ii) any(strcmp(meta.HRTFGroups(ii), selHRTFGrps)));
        
        fprintf("HRTF Group: %s\n", selHRTFGrps{:});
        fprintf("all \t\t\t%d\n├─dev \t\t\t%d (%.2f%%)\n└─test \t\t%d (%.2f%%)\n", ...
            length(ds.IndexValues), ... % all
            length(devDs.IndexValues), 100 * length(devDs.IndexValues) / length(ds.IndexValues), ...        % dev
            length(testDs.IndexValues), 100 * length(testDs.IndexValues) / length(ds.IndexValues));         % test
        
        assert(numel(intersect( ...
            unique(meta.SongNames(devDs.IndexValues)), ...
            unique(meta.SongNames(testDs.IndexValues)))) == 0);
        assert(numel(intersect( ...
            unique(meta.HRTFGroups(devDs.IndexValues)), ...
            unique(meta.HRTFGroups(testDs.IndexValues)))) == 0);
        
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
        fprintf('acc: %f\n', testAccuracy);
    
        evaluationResults(iEvaluationIteration,iHRTFScenario).Net = net;
        evaluationResults(iEvaluationIteration,iHRTFScenario).Info = info;
        evaluationResults(iEvaluationIteration,iHRTFScenario).LearnRate = params.LearnRate;
        evaluationResults(iEvaluationIteration,iHRTFScenario).MiniBatchSize = params.MiniBatchSize;
        evaluationResults(iEvaluationIteration,iHRTFScenario).MaxEpochs = params.MaxEpochs;
        evaluationResults(iEvaluationIteration,iHRTFScenario).TestAccuracy = testAccuracy;
        evaluationResults(iEvaluationIteration,iHRTFScenario).HRTFGroup = selHRTFGrps;
    end
end



