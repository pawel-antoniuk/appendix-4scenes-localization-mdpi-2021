load('../models/HRTF-dependent/summary_dep_minimal_10nets.mat')
params.InputSpecgramsFile = 'specgram_fbud.h5';
data.Width = h5read(params.InputSpecgramsFile, '/width');

iSplit = 1;
devRecordingsT = readtable('train recordings.csv', ...
    'ReadVariableNames', true, ...
    'VariableNamingRule', 'preserve');
devRecordings = devRecordingsT{:, iSplit};

dsNameBase = "/";
dsNameFilenames = strjoin([dsNameBase, "filenames"], "/");
dsFilenames = h5read(params.InputSpecgramsFile, dsNameFilenames);
dsNameData = strjoin([dsNameBase, "data"], "/");
dsNameLabels = strjoin([dsNameBase, "labels"], "/");
labelNames = h5read(params.InputSpecgramsFile, '/labelNames');

meta = getSampleMetadata(dsFilenames);
ds = H5MatrixDatastore(params.InputSpecgramsFile, dsNameData, dsNameLabels);

scoreMaps = zeros([params.InputSize(1:end-1) 4 6 4 2 length(summaryResults)]);

start = tic;
for iModel = 1:length(summaryResults)
    ds.reset();

    preds = classify(summaryResults(iModel).Net, ds);
    targets = ds.Labels(ds.IndexValues);
    results = [];
    results(ds.IndexValues) = preds == targets;

    while ds.hasdata()
        [input,info] = ds.read();
        readIndex = double(info.FileName(4));
        iwidth = find(data.Width(readIndex) == params.WidthAngles);
        sampleFilename = dsFilenames(readIndex);
        sampleLabel = ds.Labels(readIndex);
        sampleLabelName = labelNames(sampleLabel);
        trueSampleLabelName = strsplit(sampleFilename,'_');
        trueSampleLabelName = trueSampleLabelName(5);
        assert(sampleLabel == input{2})       
        assert(sampleLabelName == trueSampleLabelName);

        toc(start)
        fprintf("%s,\t %d (%s)\n", ...
            sampleFilename,sampleLabel,sampleLabelName);

        score = occlusionSensitivity( ...
            summaryResults(iModel).Net, input{1}, categorical(1:4), ...
            'MaskSize', [349 10], ...
            'Stride', 1, ...
            'MaskClipping','off');
        scoreMaps(:,:,:,iwidth,input{2},results(readIndex)+1,iModel) = ...
            scoreMaps(:,:,:,iwidth,input{2},results(readIndex)+1,iModel) + score;
    end
end


