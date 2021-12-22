clc; clear; close all;

summaryResults = load('../evaluation/summary/summary_dep1.mat', 'summaryResults').summaryResults;
summaryResultsT = struct2table(summaryResults);
summaryResultsT = summaryResultsT(summaryResultsT.Width == 90, :);
stats = grpstats(summaryResultsT,{'HRTFGroup','Iteration'},'mean','DataVars',{'Accuracy'})

[ah,ap] = adtest(stats.mean_Accuracy);
[th,tp] = ttest(stats.mean_Accuracy,0.25);
fprintf("Anderson-Darling test: p = %d [h = %d], \t t-test: p = %d [h = %d]\n",ap,ah,tp,th);
