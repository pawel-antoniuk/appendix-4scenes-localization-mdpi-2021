clc; clear; close all;

summaryResultsDep = load('../evaluation/summary/summary_dep1.mat', 'summaryResults').summaryResults;
summaryResultsDepT = struct2table(summaryResultsDep);
summaryResultsDepT = summaryResultsDepT(summaryResultsDepT.Width == 15, :);
statsDep = grpstats(summaryResultsDepT,{'HRTFGroup','Iteration'},'mean','DataVars',{'Accuracy'})

summaryResultsIndep = load('../evaluation/summary/summary_indep1.mat', 'summaryResults').summaryResults;
summaryResultsIndepT = struct2table(summaryResultsIndep);
summaryResultsIndepT = summaryResultsIndepT(summaryResultsIndepT.Width == 15, :);
statsIndep = grpstats(summaryResultsIndepT,{'HRTFGroup','Iteration'},'mean','DataVars',{'Accuracy'})

[ah1,ap1] = adtest(statsDep.mean_Accuracy);
[ah2,ap2] = adtest(statsIndep.mean_Accuracy);
[th,tp] = ttest2(statsDep.mean_Accuracy,statsIndep.mean_Accuracy);
fprintf("Anderson-Darling test: p1 = %d [h1 = %d], p2 = %d [h2 = %d], \t t-test: p = %d [h = %d]\n", ...
    ap1,ah1,ap2,ah2,tp,th);
