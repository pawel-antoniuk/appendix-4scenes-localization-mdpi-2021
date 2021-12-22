params.HRTFBaseDir = 'HRTFs';
params.OutputDir = 'HRTF-docs';

HRTFFilenames = dir(fullfile(params.HRTFBaseDir, '*', '*.sofa'));

% HRTF struct definition
HRTFs = struct;

for iHRTF = 1:length(HRTFFilenames)
    filename = HRTFFilenames(iHRTF);
    fullFilename = fullfile(filename.folder, filename.name);    
    filenameParts = split(filename.folder, filesep);

    SOFA = SOFAload(fullFilename);
    APV = SOFAcalculateAPV(SOFA);
    elevation = unique(APV(:, 2));
    
    HRTFs(iHRTF).Id = iHRTF;
    HRTFs(iHRTF).Name = filename.name;
    HRTFs(iHRTF).Corpus = filenameParts{end};
    HRTFs(iHRTF).Distance = unique(SOFA.SourcePosition(:, 3));
    HRTFs(iHRTF).ElevationResolution = max(abs(diff([[elevation] [elevation(2:end); 90]], 1, 2)));
    HRTFs = assignStruct(SOFA, HRTFs, iHRTF, 'GLOBAL_DatabaseName');
    HRTFs = assignStruct(SOFA, HRTFs, iHRTF, 'GLOBAL_DateModified');
    HRTFs = assignStruct(SOFA, HRTFs, iHRTF, 'GLOBAL_Title');
    HRTFs = assignStruct(SOFA, HRTFs, iHRTF, 'GLOBAL_Organization');
    HRTFs = assignStruct(SOFA, HRTFs, iHRTF, 'GLOBAL_DataType');
    HRTFs = assignStruct(SOFA, HRTFs, iHRTF, 'GLOBAL_AuthorContact');
    HRTFs = assignStruct(SOFA, HRTFs, iHRTF, 'GLOBAL_APIVersion');
    HRTFs = assignStruct(SOFA, HRTFs, iHRTF, 'GLOBAL_Comment');
    HRTFs = assignStruct(SOFA, HRTFs, iHRTF, 'GLOBAL_History');
    HRTFs = assignStruct(SOFA, HRTFs, iHRTF, 'GLOBAL_References');
    HRTFs = assignStruct(SOFA, HRTFs, iHRTF, 'GLOBAL_RoomType');
    HRTFs = assignStruct(SOFA, HRTFs, iHRTF, 'GLOBAL_ListenerShortName');
end

HRTFsT = struct2table(HRTFs);
writetable(HRTFsT, 'docs/HRTF.csv');

function out = assignStruct(in, out, outI, field)
    outFieldParts = split(field,'GLOBAL_');
    if length(outFieldParts) > 1
        outField = outFieldParts{2};
    else
        outField = field;
    end

    if isfield(in, field)
        out(outI).(outField) = in.(field);
    else
        out(outI).(outField) = '';
    end
end
