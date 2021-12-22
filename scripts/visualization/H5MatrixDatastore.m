classdef H5MatrixDatastore < matlab.io.Datastore & ...
        matlab.io.datastore.Shuffleable & ...
        matlab.io.datastore.Partitionable
    properties (Access = private)
        CurrentIndex double
        Filename string        
        DataLocation string
        LabelsLocation string
        MatrixSize                
    end
    
    properties (Access = public)        
        IndexValues
        Labels
    end
    
    methods
        function ds = H5MatrixDatastore(filename, dataLocation, labelsLocation)
            ds.CurrentIndex = 1;
            ds.Filename = filename;
            ds.DataLocation = dataLocation;
            ds.LabelsLocation = labelsLocation;
            hsize = h5info(ds.Filename, ds.DataLocation).Dataspace.Size;
            ds.MatrixSize = hsize(1: end-1);
            ds.IndexValues = randperm(hsize(end));
            ds.Labels = categorical(h5read(ds.Filename, ds.LabelsLocation));
            
            reset(ds);
        end
        
        function tf = hasdata(ds)
            tf = ds.CurrentIndex <= length(ds.IndexValues);
        end
        
        function [data, info] = read(ds)
            if ~hasdata(ds)
                error('The H5 file has no more data');
            end
            
            indx = ds.IndexValues(ds.CurrentIndex);
            
            dataBegin = [ones(1, numel(ds.MatrixSize)), indx];
            dataCount = [ds.MatrixSize, 1];
            data{1} = h5read(ds.Filename, ds.DataLocation, dataBegin, dataCount);
            data{2} = ds.Labels(indx);
            
            info.Size = size(data);
            info.FileName = [ds.Filename, '/', ds.DataLocation, indx];
            
            ds.CurrentIndex = ds.CurrentIndex + 1;
        end
        
        function reset(ds)
            ds.CurrentIndex = 1;
        end
        
        function dsNew = shuffle(ds)
            dsNew = copy(ds);
            dsNew.IndexValues = dsNew.IndexValues(randperm(length(dsNew.IndexValues)));
        end
        
        function subds = partition(ds, n, index)
            partitionSize =  ceil(length(ds.IndexValues) / n);
            indxBegin = (index - 1 ) * partitionSize + 1;
            indxEnd = min(index * partitionSize, length(ds.IndexValues));
            
            subds = copy(ds);

            subds.IndexValues = subds.IndexValues(indxBegin:indxEnd);
            reset(subds);
        end
        
        function [subds1, subds2] = splitDataset(ds, p)
            splitPoint = round(numel(ds.IndexValues) * p);
            subds1 = copy(ds);
            subds1.IndexValues = ds.IndexValues(1:splitPoint);
            
            subds2 = copy(ds);
            subds2.IndexValues = ds.IndexValues(splitPoint+1:end);
        end
        
        function [filteredDs, restDs] = filterDs(ds, filterFunc)
            filteredDs = copy(ds);
            filteredDs.IndexValues = [];
            restDs = copy(ds);
            restDs.IndexValues = [];
            
            for ii = ds.IndexValues
                if filterFunc(ii)
                    filteredDs.IndexValues(end + 1) = ii;
                else
                    restDs.IndexValues(end + 1) = ii;
                end
            end
        end
    end
    
    methods (Access = protected)
        function n = maxpartitions(ds)
            n = length(ds.IndexValues);
        end
    end
    
    methods (Hidden = true)
        function frac = progress(ds)
            if hasdata(ds)
                frac = (ds.CurrentIndex - 1) / length(ds.IndexValues);
            else
                frac = 1;
            end
        end
    end
end






