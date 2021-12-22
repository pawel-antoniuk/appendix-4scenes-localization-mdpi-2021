load('../models/HRTF-independent/summary_indep1.mat');
labelNames = h5read('D:/fbud-specgram/specgram_fbud.h5', '/labelNames');
orderedLabelNames = {'front', 'back', 'up', 'down'};
HRTFGroups = {'sadie','tu-berlin','th-koln'};
widths = [60 90];

for iHRTFGroup = 1:length(HRTFGroups)
    for iWidth = 1:length(widths)
        name = sprintf('%d_%s',widths(iWidth),HRTFGroups{iHRTFGroup});
        fig = figure('Name',name);
        fig.Position(3:4)=[200,180];
    
        perWidthResult = summaryResults( ...
            [summaryResults.Width] == widths(iWidth) ...
            & strcmp({summaryResults.HRTFGroup},HRTFGroups(iHRTFGroup)));
        C = confusionmat( ...
            reshape([perWidthResult.TestTargets],1,[]), ...
            reshape([perWidthResult.TestPreds],1,[]));
        cm = confusionchart(C, labelNames);
        sortClasses(cm,orderedLabelNames)
        set(findall(gcf, '-property', 'FontSize'), 'FontSize', 9)
        exportgraphics(fig, ['output/cm_indep_w' ...
            name '.png'], 'Resolution', 400);
    end
end
