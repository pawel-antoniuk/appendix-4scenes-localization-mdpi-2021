summaryResults = load('../models/human-artificial/summary_human_dummy.mat', 'summaryResults').summaryResults;
widths = unique([summaryResults.Width]);
allHRTFGroups = string(vertcat(summaryResults.HRTFGroup));
HRTFGroups = unique(allHRTFGroups,'rows');

plotStyles = ["k-^", "k--s", "k-.v", "k:d"];
plotOffsets = [-1 1];

f = figure;

for iHRTFGroup = 1:size(HRTFGroups,1)
    means = zeros(1, length(widths));
    stdDevs = zeros(1, length(widths));
    for iWidth = 1:length(widths)
        width = widths(iWidth);
        HRTFGroup = HRTFGroups(iHRTFGroup,:);
        mask = [summaryResults.Width] == width ...
            & ismember(allHRTFGroups, HRTFGroup,'rows')';
        means(iWidth) = mean([summaryResults(mask).Accuracy]);
        stdDevs(iWidth) = std([summaryResults(mask).Accuracy]);
    end

    p = errorbar(widths + plotOffsets(iHRTFGroup), means * 100, stdDevs * 100, plotStyles(iHRTFGroup));
    p.MarkerSize = 5;
    p.MarkerFaceColor = 'k';
    hold on;
end

xlim([10 95])
ylim([45 100])
ylabel('Accuracy [%]')
xlabel('Ensemble Width')
xticks(widths)
xticklabels("\pm" + widths + "°")
hleg = legend(["Human Heads (";"Artificial Heads ("] + upper(join(HRTFGroups,', ')) + [")";")"]);
title(hleg,'HRTFs Used for Testing')
grid on
hold off;

exportgraphics(gca,'output/accuracy_per_width_hrtf_ha_ah.png','Resolution',400);

