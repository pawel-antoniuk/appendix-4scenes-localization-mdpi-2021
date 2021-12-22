function meta = getSampleMetadata(filenames)
    meta.SongNames = cell(1, length(filenames));
    meta.HRTFs = cell(1, length(filenames));
    meta.HRTFGroups = cell(1, length(filenames));
    meta.Scenes = cell(1, length(filenames));
    
    for iFilename = 1:length(filenames)
        filename = filenames(iFilename);
        fParts = strsplit(filename, '_');
        
        meta.SongNames{iFilename} = fParts{1};
        meta.HRTFs{iFilename} = fParts{2};
        meta.HRTFGroups{iFilename} = fParts{3};
        meta.Scenes{iFilename} = sprintf('%s_%s', fParts{4}, fParts{5});
    end
end