clc; clear; close all;

summaryResults = load('../evaluation/summary/summary_indep1.mat', 'summaryResults').summaryResults;
summaryResultsT = struct2table(summaryResults);
summaryResultsT = summaryResultsT(summaryResultsT.Width == 60 | summaryResultsT.Width == 75, :);

summaryResultsThKolnT = summaryResultsT(strcmp(summaryResultsT.HRTFGroup,'th-koln'), :);
summaryResultsThKolnT = grpstats(summaryResultsThKolnT,{'Iteration','HRTFGroup'},'mean','DataVars','Accuracy')
summaryResultsRestT = summaryResultsT(~strcmp(summaryResultsT.HRTFGroup,'th-koln'), :);
summaryResultsRestT = grpstats(summaryResultsRestT,{'Iteration','HRTFGroup'},'mean','DataVars','Accuracy')

[ah1,ap1] = adtest(summaryResultsThKolnT.mean_Accuracy);
[ah2,ap2] = adtest(summaryResultsRestT.mean_Accuracy);
[th,tp] = ttest2(summaryResultsThKolnT.mean_Accuracy,summaryResultsRestT.mean_Accuracy);
fprintf("Anderson-Darling test: p1 = %d [h1 = %d], p2 = %d [h2 = %d], \t t-test: p = %d [h = %d]\n", ...
    ap1,ah1,ap2,ah2,tp,th);