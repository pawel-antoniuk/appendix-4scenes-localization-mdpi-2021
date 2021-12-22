clc; clear; close all;

summaryResults = load('../evaluation/summary/summary_dep1.mat', 'summaryResults').summaryResults;
summaryResultsT = struct2table(summaryResults);
summaryResultsT = summaryResultsT(summaryResultsT.Width == 15 | summaryResultsT.Width == 30, :);

summaryResultsTSADIE = summaryResultsT(strcmp(summaryResultsT.HRTFGroup,'sadie'), :);
summaryResultsTSADIE = grpstats(summaryResultsTSADIE,{'Iteration','HRTFGroup'},'mean','DataVars','Accuracy')
summaryResultsTRest = summaryResultsT(~strcmp(summaryResultsT.HRTFGroup,'sadie'), :);
summaryResultsTRest = grpstats(summaryResultsTRest,{'Iteration','HRTFGroup'},'mean','DataVars','Accuracy')

[ah1,ap1] = adtest(summaryResultsTSADIE.mean_Accuracy);
[ah2,ap2] = adtest(summaryResultsTRest.mean_Accuracy);
[th,tp] = ttest2(summaryResultsTSADIE.mean_Accuracy,summaryResultsTRest.mean_Accuracy);
fprintf("Anderson-Darling test: p1 = %d [h1 = %d], p2 = %d [h2 = %d], \t t-test: p = %d [h = %d]\n", ...
    ap1,ah1,ap2,ah2,tp,th);
