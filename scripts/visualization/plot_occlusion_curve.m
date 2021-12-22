scenariosFilenames = dir('../models/visualization/*.mat');

widthSelected = [1 2 3 4 5 6];
sceneCombinations = {
    [3 1]
    [4 2]};
locations = {'southeast','northeast'};

for iScenario = 1:length(scenariosFilenames)
    for iWidth = widthSelected
        for iSceneCombination = 1:length(sceneCombinations)
            sceneCombination = sceneCombinations{iSceneCombination};
    
            scenariosFullFilename = fullfile( ...
                scenariosFilenames(iScenario).folder, ...
                scenariosFilenames(iScenario).name);
        
            load(scenariosFullFilename)
            
            params.InputSpecgramsFile = 'specgram_fbud.h5';
            timeValues = h5read(params.InputSpecgramsFile, '/axis/time');
            freqValues = h5read(params.InputSpecgramsFile, '/axis/freq');
            labelNames = h5read(params.InputSpecgramsFile, '/labelNames');
            
            f = figure;
            f.Position = [0 0 280 350];
            tiledlayout(2,2);
            colors = {'r','g','b','c'};

            I = scoreMaps(:,:,sceneCombination,iWidth,:,:,:);        
            I = mean(I, [5 6]);
            IcurveMeanTime = mean(I,1);            
            IcurveMean = squeeze(mean(IcurveMeanTime,7));  

            SEM = squeeze(std(IcurveMeanTime,[],7)/sqrt(size(IcurveMeanTime,7)));
            SEM = reshape(SEM,size(SEM,1),1,[]);
            ts = tinv([0.025  0.975],size(IcurveMeanTime,7)-1);
            ts = reshape(ts,1,[]);
            CI = abs(ts.*SEM);
        
            maxVal = max(reshape(IcurveMean,size(IcurveMean,1),1,[]) + CI,[],"all");
            minVal = min(reshape(IcurveMean,size(IcurveMean,1),1,[]) - CI,[],"all");
            IcurveMean = (IcurveMean - minVal) ./ (maxVal - minVal);
            CI = CI ./ (maxVal - minVal);
            boundedline(freqValues/1000,IcurveMean,CI,'alpha');

            ylim([0 1])
            axis xy
            pbaspect([1 1 1])
            set(gca, 'XMinorTick', 'on', 'YMinorTick', 'on', 'TickLength', [0.02 0.025])
            grid on
        
            xticks(linspace(0,16,9))
            xlabel('Frequency [kHz]')
            ylabel('\rm{Importance}')
            legend(labelNames(sceneCombination) + " (mean, 95% CI)", ...
                'Location',locations{iSceneCombination});
        
            [pathstr, name, ext] = fileparts(scenariosFullFilename);

            set(findall(gcf,'-property','FontSize'),'FontSize',8)
            exportgraphics(f, ...
                sprintf("output/output_occlusion_curve_%d_%s_%s_%d.png", ...
                    iModel, ...
                    name, ...
                    strjoin(labelNames(sceneCombination),"-"), ...
                    params.WidthAngles(iWidth)), ...
                'Resolution',400);
        end
    end
end
