summaryResults = load('../models/HRTF-dependent/summary_dep_results_only.mat', 'summaryResults').summaryResults;

widths = unique([summaryResults.Width]);
HRTFGroups = unique([summaryResults.HRTFGroup]);

plotStyles = ["k-^", "k--s", "k-.v", "k:d"];
plotOffsets = [2 1 -1 0];

f = figure;

for iHRTFGroup = 1:length(HRTFGroups)
    means = zeros(1, length(widths));
    stdDevs = zeros(1, length(widths));
    for iWidth = 1:length(widths)
        width = widths(iWidth);
        HRTFGroup = HRTFGroups(iHRTFGroup);
        mask = [summaryResults.Width] == width ...
            & strcmp([summaryResults.HRTFGroup], HRTFGroup);
        means(iWidth) = mean([summaryResults(mask).Accuracy]);
        stdDevs(iWidth) = std([summaryResults(mask).Accuracy]);
    end

    p = errorbar(widths + plotOffsets(iHRTFGroup), means * 100, stdDevs * 100, plotStyles(iHRTFGroup));
    p.MarkerSize = 5;
    p.MarkerFaceColor = 'k';
    hold on;
end

xlim([10 95])
ylim([58 100])
ylabel('Accuracy [%]')
xlabel('Ensemble Width')
xticks(widths)
xticklabels("\pm" + widths + "°")
legend(upper(HRTFGroups))
grid on
hold off;

exportgraphics(gca,'output/accuracy_per_width_hrtf_dep.png','Resolution',400);

