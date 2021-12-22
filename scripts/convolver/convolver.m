% Paweł Antoniuk 2021
% Bialystok University of Technology
% with the help of S. Zieliński

%% Initialize
clearvars; close all; clc;
SOFAstart;
SOFAgetVersion()

%% Params
params.HRTFBaseDir = 'HRTF-small';
params.RecordingsBaseDir = 'Recordings\RMSNorm 48kHz\';
params.SpatOutputDir = 'up-down-front-back\spat';
params.MetaOutputDir = 'up-down-front-back\meta';
params.FinalResultsOutputDir = 'up-down-front-back';
params.RecordingsExpectedFs = 48000;
params.RecordingLoadRange = [2.5 inf];
params.RecordingSpatRange = [0.5 7];
params.RecordingFadeTime = [0.01 0.01];
params.RecordingLevelScale = 0.9;
params.NChannels = 2;
params.EnsembleAngleWidthEps = 1e-4;
params.EnsembleAngleWidths = [15 30 45 60 75 90];
params.EnsembleDirections = [
    0 0
    -180 0
    0 90
    0 -90];
params.EnsembleSceneNames = [
    "front"
    "back"
    "up"
    "down"];
params.HATOs = containers.Map;
params.HATOs("_resampled_48000_FABIAN_HRIR_measured_HATO_10.sofa") = 10;
params.HATOs("_resampled_48000_FABIAN_HRIR_measured_HATO_40.sofa") = 40;
params.HATOs("_resampled_48000_FABIAN_HRIR_measured_HATO_50.sofa") = 50;
params.HATOs("_resampled_48000_FABIAN_HRIR_measured_HATO_310.sofa") = 310;
params.HATOs("_resampled_48000_FABIAN_HRIR_measured_HATO_320.sofa") = 320;
params.HATOs("_resampled_48000_FABIAN_HRIR_measured_HATO_350.sofa") = 350;

%% Load HRTFs and get audio filenames
HRTFs = loadHRTFs(params);
audioFilenames = dirWithoutDots(params.RecordingsBaseDir);

%% Spatialize songs
tic
nAudioFilenames = length(audioFilenames);
allSpatMetaresults = cell(nAudioFilenames, 1);


% parfor
parfor iAudioFilename = 1:nAudioFilenames
    %% Load audio tracks and spatialize them 
    audioFilename = audioFilenames(iAudioFilename);
    [tracks,trackNames] = loadAudioTracks(audioFilename, params);
    [spatResults,spatMetaresults] = spatializeSong(HRTFs, tracks, trackNames, audioFilename.name, params);
    allSpatMetaresults{iAudioFilename} = spatMetaresults;
    
    %% Postprocess results
    spatResults = posprocessSpatResults(spatResults, params);
    
    %% Save results
    saveSpatResults(spatResults, spatMetaresults, HRTFs, audioFilename, params);
    
    fprintf("Progress  [audio: %d/%d] (%s)\n", ...
        iAudioFilename, nAudioFilenames, audioFilename.name);
end

toc

%% Plot scenes summary
plotAudioScene(HRTFs, ...
    cell2mat(reshape(allSpatMetaresults, 1, 1, 1, [])), params);

%% Save workspace
save(fullfile(params.FinalResultsOutputDir, 'workspace'), '-v7.3');
saveHRTFMetadata(HRTFs, params);

%% --- ROUTINES ---
% Load HRTFs routine
function HRTFs = loadHRTFs(params)
    HRTFFilenames = dir(fullfile(params.HRTFBaseDir, '*', '*.sofa'));
    
    % HRTF struct definition
    HRTFs = struct('Id', [], ...
        'Name', [], ...
        'Folder', [], ...
        'HRTFGroup', [], ...
        'SOFA', [], ...
        'Position', [], ...
        'Distance', [], ...
        'HATO', []);
    HRTFGroupData = containers.Map;
    
    for iHRTF = 1:length(HRTFFilenames)
        filename = HRTFFilenames(iHRTF);
        fullFilename = fullfile(filename.folder, filename.name);
        
        HRTFs(iHRTF) = loadHRTF(iHRTF, fullFilename, params);   
        
        if HRTFs(iHRTF).SOFA.Data.SamplingRate ~= params.RecordingsExpectedFs
            [loadStatus,HRTFs(iHRTF)] = tryLoadResampledHRTF(iHRTF, ...
                HRTFs(iHRTF), params);
            if ~loadStatus
                resampleAndSave(HRTFs(iHRTF), params);
                [loadStatus,HRTFs(iHRTF)] = tryLoadResampledHRTF(iHRTF, ...
                    HRTFs(iHRTF), params);
                
                if ~loadStatus
                    error('Cannot find previously resampled HRTF');
                end
            end
        end
        
        if ~isKey(HRTFGroupData, HRTFs(iHRTF).HRTFGroup)
            HRTFGroupData(HRTFs(iHRTF).HRTFGroup) = [];
        end
        
        for jHRTF = HRTFGroupData(HRTFs(iHRTF).HRTFGroup)
            if length(HRTFs(iHRTF).Position) ~= length(HRTFs(jHRTF).Position) ...
                    || ~all(HRTFs(iHRTF).Position == HRTFs(jHRTF).Position, 'all')
                warning('[%s][%s] Inconsistent source positions with %s', ...
                    HRTFs(iHRTF).HRTFGroup, ...
                    HRTFs(iHRTF).Name, ...
                    HRTFs(jHRTF).Name);
            end
        end
    
        HRTFGroupData(HRTFs(iHRTF).HRTFGroup) = [...
            HRTFGroupData(HRTFs(iHRTF).HRTFGroup) iHRTF];   
        
        fprintf('[%s][%s] azimuth: [%d, %d]; elevation: [%d, %d]; distance: %d\n', ...
            HRTFs(iHRTF).HRTFGroup, ...
            HRTFs(iHRTF).Name, ...
            min(HRTFs(iHRTF).Position(:, 1)), ...
            max(HRTFs(iHRTF).Position(:, 1)), ...
            min(HRTFs(iHRTF).Position(:, 2)), ...
            max(HRTFs(iHRTF).Position(:, 2)), ...
            HRTFs(iHRTF).Distance);
        
        if length(HRTFs(iHRTF).Distance) > 1
            error('Multiple distances in single HRTF are not supported');
        end
        
        if HRTFs(iHRTF).SOFA.Data.SamplingRate ~= params.RecordingsExpectedFs
            error('[%s][%s] Resampling from %d Hz to %d Hz', ...
                HRTF.HRTFGroup, HRTF.Name, ...
                HRTF.SOFA.Data.SamplingRate, ...
                params.RecordingsExpectedFs);
        end
    end
end


% Try load resampled HRTF routine
function [loadStatus,HRTF] = tryLoadResampledHRTF(id, HRTF, params)
    resampledSOFAdir = fullfile(params.HRTFBaseDir, ...
        ['_resampled_' num2str(params.RecordingsExpectedFs)], ...
        HRTF.HRTFGroup);
    resampledSOFAfilename = ['_resampled_' ...
        num2str(params.RecordingsExpectedFs) '_' HRTF.Name];
    fullSOFAfilename = fullfile(resampledSOFAdir, resampledSOFAfilename);
    
    if ~exist(fullSOFAfilename, 'file')
        loadStatus = false;
    else
        loadStatus = true;
        HRTF = loadHRTF(id, fullSOFAfilename, params);
    end
end


% Load HRTF routine
function HRTF = loadHRTF(id, filename, params)
    listing = dir(filename);
    fullFilename = fullfile(listing.folder, listing.name);
    filenameParts = split(listing.folder, filesep);
    SOFA = SOFAload(fullFilename);
    APV = SOFAcalculateAPV(SOFA);
    
    HRTF.Id = id;
    HRTF.Name = listing.name;
    HRTF.Folder = listing.folder;
    HRTF.HRTFGroup = filenameParts{end};
    HRTF.SOFA = SOFA;
    % HRTF.Position = HRTF.SOFA.SourcePosition(:, 1:2);
    HRTF.Position = APV(:, 1:2);
    HRTF.Distance = unique(HRTF.SOFA.SourcePosition(:, 3));

    if(isKey(params.HATOs, HRTF.Name))
        HRTF.HATO = params.HATOs(HRTF.Name);
    else
        HRTF.HATO = 0;
    end
    
    % If the number of samples is odd, remove the last sample
    % It fixes the problem with SOFA-based convolution
    % (S. Zieliński)
    if mod(HRTF.SOFA.API.N, 2) ~= 0
        tmpIR = HRTF.SOFA.Data.IR(:, :, 1:end-1); % Remove last sample
        HRTF.SOFA.Data.IR = tmpIR;
        HRTF.SOFA.API.N = size(tmpIR, 3);
    end    
end


% Resample and save routine
function HRTF = resampleAndSave(HRTF, params)    
    fprintf('[%s][%s] Resampling from %d Hz to %d Hz\n', ...
        HRTF.HRTFGroup, HRTF.Name, ...
        HRTF.SOFA.Data.SamplingRate, ...
        params.RecordingsExpectedFs);
    
    HRTF.SOFA = SOFAresample(HRTF.SOFA, params.RecordingsExpectedFs);
    
    resampledSOFAdir = fullfile(params.HRTFBaseDir, ...
        ['_resampled_' num2str(params.RecordingsExpectedFs)], ...
        HRTF.HRTFGroup);
    resampledSOFAfilename = ['_resampled_' ...
        num2str(params.RecordingsExpectedFs) '_' HRTF.Name];
    
    if ~exist(resampledSOFAdir, 'dir')
        mkdir(resampledSOFAdir);
    end
    
    fullSOFAfilename = fullfile(resampledSOFAdir, resampledSOFAfilename);
    HRTF.SOFA = SOFAsave(fullSOFAfilename, HRTF.SOFA, 0);
end


% Resample SOFA routine
function Obj = SOFAresample(Obj, targetFs)    
    currentFs = Obj.Data.SamplingRate;
    
    if currentFs == targetFs
        return
    end
    
    % Based on HRTFsamplingRateConverter10.m (S. Zieliński)
    M = size(Obj.Data.IR,1); % Number of measurements
    N = size(Obj.Data.IR,3); % Length of measurements
    IR = Obj.Data.IR;
    IR2 = zeros(M, 2, round(targetFs / currentFs * N));
    
    for ii = 1:M
        ir = squeeze(IR(ii, :, :))';
        iririr = [ir; ir; ir];
        iririr2 = resample(iririr, targetFs, currentFs);
        N2 = round(length(iririr2)/3);
        ir2 = iririr2(N2+1:2*N2, :);
        IR2(ii, :, :) = ir2';
    end
    
    Obj.Data.IR = IR2;
    Obj.Data.SamplingRate = targetFs;
    Obj=SOFAupdateDimensions(Obj);
end


% load tracks routine
function [tracks,trackNames] = loadAudioTracks(audioFilename, params)
    songName = fullfile(audioFilename.folder, audioFilename.name);
    trackFilenames = dir(fullfile(songName, '*.wav'));
    audioInfo = audioinfo(fullfile(trackFilenames(1).folder, ...
        trackFilenames(1).name));
    totalSamples = audioInfo.TotalSamples ...
        - params.RecordingLoadRange(1) * params.RecordingsExpectedFs;
    tracks = zeros(totalSamples, length(trackFilenames));
    
    for iTrackFilename = 1:length(trackFilenames)
        trackPath = fullfile(trackFilenames(iTrackFilename).folder, ...
            trackFilenames(iTrackFilename).name);
        [track,Fs] = audioread(trackPath, ...
            params.RecordingLoadRange * params.RecordingsExpectedFs + [1 0]);
        
        if Fs ~= params.RecordingsExpectedFs
            error('Track frequency is not expected frequency');
        end
        
        tracks(:, iTrackFilename) = track;
    end

    trackNames = {trackFilenames.name};
end


% Spatialize all audio trakcs routine
% spatResults shape (width, HRTF, dir, sample, ch)
function [outSpatResults,outSpatMetaResults] = spatializeSong(HRTFs, tracks, trackNames, audioName, params)    
    sz = [size(params.EnsembleAngleWidths, 2), length(HRTFs)];
    dur = params.RecordingSpatRange(2) * params.RecordingsExpectedFs;
    outSpatResults = zeros([sz size(params.EnsembleDirections, 1) dur params.NChannels]);
    outSpatMetaResults = cell(sz);
    trackNamesParts = split(trackNames, '.wav');
    trackNames = trackNamesParts(:, :, 1);
    
    for comb = allcomb(...
            1:length(params.EnsembleAngleWidths), ...
            1:length(HRTFs))'
        cComb = num2cell(comb);
        [iWidth,iHRTF] = cComb{:};
        
        % get the previous width
        if iWidth == 1
            prevensembleAngleWidth = -1;
        else
            prevensembleAngleWidth = params.EnsembleAngleWidths(iWidth - 1);
        end

        ensembleAngleWidth = params.EnsembleAngleWidths(iWidth);

        metaResults = getSceneMetaresult(ensembleAngleWidth, ...
            prevensembleAngleWidth, HRTFs(iHRTF), audioName, ...
            trackNames, params);          
        
        spatResults = spatializeAudioTracks(...
            tracks, HRTFs(iHRTF), metaResults, params);

        outSpatResults(iWidth,iHRTF,:,:,:) = spatResults;
        outSpatMetaResults(iWidth,iHRTF) = {reshape(metaResults, 1, 1, [])};
        
        fprintf('Progress  [width %d/%d, HRTF %d/%d]\n', ...
            iWidth, ...
            size(params.EnsembleAngleWidths, 2), ...
            iHRTF, ...
            length(HRTFs));        
    end
    
    outSpatMetaResults = cell2mat(outSpatMetaResults);
end

function metaResults = getSceneMetaresult(ensembleAngleWidth, ...
    prevensembleAngleWidth, HRTF, audioName, trackNames, params)

    ensembleDirections = params.EnsembleDirections;

    if(isKey(params.HATOs, HRTF.Name))
        HATO = params.HATOs(HRTF.Name);
        ensembleDirections = ensembleDirections + [HATO 0];
    end

    while true
        randTrackAngles = randSphCap(length(trackNames), [0 0], ...
            ensembleAngleWidth);
        [angles,~] = findBestFitAnglePairs(randTrackAngles, ...
            HRTF.Position, [0 0], ensembleAngleWidth, ...
            params.EnsembleAngleWidthEps);

        dists = angleDistance(angles, [0 0]);
        maxAngle = max(dists);
        
        if maxAngle > prevensembleAngleWidth
            break
        end
    end

    metaResults = struct;
    for iEnsembleDirection = 1:size(ensembleDirections,1)
        ensembleDirection = ensembleDirections(iEnsembleDirection, :);

        [x,y,z] = sph2cart(deg2rad(randTrackAngles(:, 1)), deg2rad(randTrackAngles(:, 2)), 1);        
        rXYZ = [x y z]';
        if params.EnsembleSceneNames(iEnsembleDirection) == "back"
            rXYZ =  [1 -1 1]' .* rXYZ;
        elseif params.EnsembleSceneNames(iEnsembleDirection) == "down"
            rXYZ =  [1 1 -1]' .* rXYZ;
        end
        rXYZ =  rotz(ensembleDirection(1)) * roty(-ensembleDirection(2)) * rXYZ;
        [az,el] = cart2sph(rXYZ(1, :), rXYZ(2, :), rXYZ(3, :));
        ensembleRandTrackAngles = rad2deg([az;el]');
        
        ensembleRandTrackAngles(:, 1) = wrapTo360(ensembleRandTrackAngles(:, 1));
        ensembleRandTrackAngles(:, 2) = wrapTo180(ensembleRandTrackAngles(:, 2));
        [angles,anglesI] = findBestFitAnglePairs(ensembleRandTrackAngles, ...
            HRTF.Position, ensembleDirection, ensembleAngleWidth, ...
            params.EnsembleAngleWidthEps);
        metaResults(iEnsembleDirection).FittedHRTFAngles = angles;
        metaResults(iEnsembleDirection).FittedHRTFAnglesI = anglesI;     
        metaResults(iEnsembleDirection).RandTrackAngles = ensembleRandTrackAngles;

        if(isKey(params.HATOs, HRTF.Name))
            metaResults(iEnsembleDirection).HATO = params.HATOs(HRTF.Name);
        else
            metaResults(iEnsembleDirection).HATO = 0;
        end

        metaResults(iEnsembleDirection).AudioName = audioName;
        metaResults(iEnsembleDirection).TrackNames = trackNames;
        metaResults(iEnsembleDirection).HRTFId = HRTF.Id;
    end
end


% Spatialize audio routine
function spatResults = spatializeAudioTracks(...
    tracks, HRTF, metaResults, params)   

    spatResults = [];
    
    for iMetaresults = 1:length(metaResults)
        metaResult = metaResults(iMetaresults);
        spatResult = [];
        
        for iTrack = 1:size(tracks, 2)
            track = tracks(:, iTrack);
            iAngles = metaResult.FittedHRTFAnglesI(iTrack);
            spatTrack = [
                conv(squeeze(HRTF.SOFA.Data.IR(iAngles, 1, :)), track) ...
                conv(squeeze(HRTF.SOFA.Data.IR(iAngles, 2, :)), track)];

            if isempty(spatResult)
                spatResult = zeros(size(spatTrack));
            end            
            spatResult = spatResult + spatTrack;
        end
        
        spatResult = trimAndFadeSignal(spatResult, params);

        if isempty(spatResults)
            spatResults = zeros([length(metaResults) size(spatResult)]);
        end
        spatResults(iMetaresults, :, :) = spatResult;
    end
end


% Trim and fade signal routine
function y = trimAndFadeSignal(x, params)    
    range = params.RecordingSpatRange * params.RecordingsExpectedFs - [0 1];
    y = x(range(1):sum(range), :);
    
    env = envGen(params.RecordingFadeTime(1), ...
        params.RecordingSpatRange(2), ...
        params.RecordingFadeTime(2), ...
        params.RecordingsExpectedFs, 2, 'sinsq')';
    y = y .* env;
end


% Postprocess spatialization results routine
function spatResults = posprocessSpatResults(spatResults, params)    
    % Peak normalization and scaling
    peakLevel = max(abs(spatResults), [], [3 4 5]);
    spatResults = params.RecordingLevelScale * spatResults ./ peakLevel;
    
    % DC equalization
    spatResults = spatResults - mean(spatResults, 4);
end


% Save spatialization results routine
% spatResults shape (width, HRTF, dir, sample, ch)
function spatResults = saveSpatResults(spatResults, spatMetaresults, ...
    HRTFs, audioFilename, params)
    
    if ~exist(params.SpatOutputDir, 'dir')
        mkdir(params.SpatOutputDir);
    end
    
    if ~exist(params.MetaOutputDir, 'dir')
        mkdir(params.MetaOutputDir);
    end
    
    for comb = allcomb(...
            1:length(params.EnsembleAngleWidths), ...
            1:length(HRTFs), ...
            1:size(params.EnsembleDirections, 1))'

        cComb = num2cell(comb);
        [iWidth,iHRTF,iensembleDirection] = cComb{:};
        
        spatFilename = getOutputFilename(...
            iWidth, iensembleDirection, HRTFs, iHRTF, ...
            audioFilename, params);
        
        spatParentDir = fullfile(params.SpatOutputDir, ...
            num2str(params.EnsembleAngleWidths(iWidth)));
        metaParentDir = fullfile(params.MetaOutputDir, ...
            num2str(params.EnsembleAngleWidths(iWidth)));
        fullSpatFilename = fullfile(spatParentDir, spatFilename + '.wav');
        fullMetaFilename = fullfile(metaParentDir, ...
            spatFilename + '-spatMetaresults');
        
        if ~exist(spatParentDir, 'dir')
            mkdir(spatParentDir);
        end
        
        if ~exist(metaParentDir, 'dir')
            mkdir(metaParentDir);
        end
        
        spatOut = squeeze(spatResults(iWidth, iHRTF, ...
            iensembleDirection, :, :));
        audiowrite(fullSpatFilename, spatOut, ...
            params.RecordingsExpectedFs, ...
            'BitsPerSample', 32);
        save(fullMetaFilename, 'spatMetaresults', 'params', '-v7.3');
    end
end

% Get output filename routine
function [filename,parentDir] = getOutputFilename(iWidth, ...
    iensembleDirection, ...
    HRTFs, iHRTF, ...
    audioFilename, params)
    
    HRTFGroup = HRTFs(iHRTF).HRTFGroup;
    sceneName = params.EnsembleSceneNames(iensembleDirection);
    ensembleDirection = params.EnsembleDirections(iensembleDirection, :);
    ensembleAngleWidth = params.EnsembleAngleWidths(iWidth);
    
    filename = sprintf("%s_hrtf%d_%s_scene%d_%s_az%d_el%d_width%d", ...
        audioFilename.name, ...
        HRTFs(iHRTF).Id, ...
        HRTFGroup, ...
        iensembleDirection, ...
        sceneName, ...
        ensembleDirection(1), ...
        ensembleDirection(2), ...
        ensembleAngleWidth);
end


% Drawning routine
% spatMetaresults shape (width, HRTF, dir, audio)
function plotAudioScene(HRTFs, spatMetaresults, params)
    
    if ~exist(params.FinalResultsOutputDir, 'dir')
        mkdir(params.FinalResultsOutputDir);
    end
    
    HRTFGroups = convertCharsToStrings(unique({HRTFs.HRTFGroup}));
    
    for iHRTFGroup = 1:length(HRTFGroups)
        fig = figure('Position', [0, 0, 1400, 1200]);
        
        HRTFGroupName = HRTFGroups(iHRTFGroup);    
        HRTFidx = strcmp({HRTFs.HRTFGroup}, HRTFGroupName);
        
        for iWidth = 1:length(params.EnsembleAngleWidths)
            for iensembleDirection = 1:size(params.EnsembleDirections, 1)
                ensembleAngleWidth = params.EnsembleAngleWidths(iWidth);
                ensembleDirection = params.EnsembleDirections(iensembleDirection, :);

                
                for iHRTF = find(HRTFidx)
                    selectedSpatMetaresults = spatMetaresults(...
                        iWidth, iHRTF, iensembleDirection, :);
                    spatMetaresult = reshape(selectedSpatMetaresults, 1, []);
        
                    fittedHRTFAngles = cat(1,spatMetaresult.FittedHRTFAngles);
                    randTrackAngles = cat(1,spatMetaresult.RandTrackAngles);
        
                    m = length(params.EnsembleAngleWidths);
                    n = size(params.EnsembleDirections, 1);
                    subplot(m, n, n * (iWidth - 1) + iensembleDirection);
        
                    HRTFpos = unique(cat(1, HRTFs(iHRTF).Position), 'rows');
                    [C,G] = groupcounts(fittedHRTFAngles);
                    fittedHRTFAngles = [G{:}];
                    C = 5 + 60 * normalize(C, 'range'); 

                    if(isKey(params.HATOs, HRTFs(iHRTF).Name))
                        HATO = params.HATOs(HRTFs(iHRTF).Name);
                        HRTFpos = HRTFpos - [HATO 0];
                        fittedHRTFAngles = fittedHRTFAngles - [HATO 0];
                        randTrackAngles = randTrackAngles - [HATO 0];
                    end

                    [x, y, z] = sph2cart(deg2rad(HRTFpos(:, 1)), ...
                        deg2rad(HRTFpos(:, 2)), 1); 
                    scatter3(x, y, z, 1, 'k.');          

                    hold on
                    [x, y, z] = sph2cart(deg2rad(fittedHRTFAngles(:, 1)), ...
                        deg2rad(fittedHRTFAngles(:, 2)), 1); 
                    scatter3(x, y, z, C, C, 'filled');                                                 
       
                    [x, y, z] = sph2cart(...
                        deg2rad(randTrackAngles(:, 1)), ...
                        deg2rad(randTrackAngles(:, 2)), 1);        
                    
                    h = scatter3(x, y, z, 20, 'filled', 'b');
                    set(h, 'MarkerEdgeAlpha', 0.05, 'MarkerFaceAlpha', 0.05);                    
                end
                hold off
    
                title(sprintf("width %d°, scene '%s' (%d°, %d°)", ...
                    ensembleAngleWidth, ...
                    params.EnsembleSceneNames(iensembleDirection), ...
                    ensembleDirection(1), ensembleDirection(2)));
                xlim([-1.25 1.25])
                ylim([-1.25 1.25])
                zlim([-1.25 1.25])
                pbaspect([1 1 1])                    
                xlabel('x')
                ylabel('y')
                zlabel('z')
                colormap jet;  
                cb = colorbar; ylabel(cb, 'Count');
            end
        end
        
        sgtitle(HRTFGroupName);
        
        saveas(fig, fullfile(params.FinalResultsOutputDir, ...
            HRTFGroupName + '.png'));
    end

end

function saveHRTFMetadata(HRTFs, params)
    T = struct2table(HRTFs);
    T = T(:, {'Id', 'Name', 'HRTFGroup', 'Distance', 'HATO'});
    filename = fullfile(params.FinalResultsOutputDir, 'HRTFs.csv');
    writetable(T, filename);
end
