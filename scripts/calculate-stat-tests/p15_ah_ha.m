clc; clear; close all;

summaryResults = load('../evaluation/summary/summary_human_dummy1.mat', 'summaryResults').summaryResults;

summaryResultsT = struct2table(summaryResults);
summaryResultsT.HRTFGroup = strcat(summaryResultsT.HRTFGroup(:,1),'_',summaryResultsT.HRTFGroup(:,2));
summaryResultsT = summaryResultsT(summaryResultsT.Width == 15 | summaryResultsT.Width == 30, :);

allHRTFGroups = string(vertcat(summaryResultsT.HRTFGroup));
humanHRTFGroup = "hutubs_sadie";
artificialHRTFGroup = "th-koln_tu-berlin";
summaryResultsTHumanT = summaryResultsT(strcmp(allHRTFGroups, humanHRTFGroup), :);
summaryResultsTArtificialT = summaryResultsT(strcmp(allHRTFGroups, artificialHRTFGroup), :);

statsHuman = grpstats(summaryResultsTHumanT,{'Iteration','HRTFGroup'},'mean','DataVars','Accuracy')
statsArtificial = grpstats(summaryResultsTArtificialT,{'Iteration','HRTFGroup'},'mean','DataVars','Accuracy')

[ah1,ap1] = adtest(statsHuman.mean_Accuracy);
[ah2,ap2] = adtest(statsArtificial.mean_Accuracy);
[th,tp] = ttest2(statsHuman.mean_Accuracy,statsArtificial.mean_Accuracy);
fprintf("Anderson-Darling test: p1 = %d [h1 = %d], p2 = %d [h2 = %d], \t t-test: p = %d [h = %d]\n", ...
    ap1,ah1,ap2,ah2,tp,th);
