load('../models/HRTF-dependent/summary_dep_results_only.mat');
labelNames = h5read('specgram_fbud.h5', '/labelNames');
widths = unique([summaryResults.Width]);

orderedLabelNames = {'front', 'back', 'up', 'down'};

for iWidth = 1:length(widths)
    fig = figure('Name', num2str(widths(iWidth)));
    fig.Position(3:4)=[200,180];

    perWidthResult = summaryResults([summaryResults.Width] == widths(iWidth));
    C = confusionmat( ...
        reshape([perWidthResult.TestTargets],1,[]), ...
        reshape([perWidthResult.TestPreds],1,[]));
    cm = confusionchart(C, labelNames);
    sortClasses(cm,orderedLabelNames)
    set(findall(gcf, '-property', 'FontSize'), 'FontSize', 9)
    exportgraphics(fig, ['output/cm_w' ...
        num2str(widths(iWidth)) '.png'], 'Resolution', 400);
end

fig = figure('Name', num2str(widths(iWidth)));
fig.Position(3:4)=[200,180];
C = confusionmat(...
    reshape([summaryResults.TestTargets],1,[]), ...
    reshape([summaryResults.TestPreds],1,[]));
cm = confusionchart(C,labelNames);
sortClasses(cm,orderedLabelNames)
exportgraphics(fig, ['output/cm_all.png'], 'Resolution', 400);
