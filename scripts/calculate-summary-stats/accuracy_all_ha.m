summaryResults = load('summary_human_dummy1.mat', 'summaryResults').summaryResults;

HRTFGroups = vertcat(summaryResults.HRTFGroup);
summaryResultsHuman = summaryResults( ...
    strcmp(HRTFGroups(:,1), 'hutubs') ...
    & strcmp(HRTFGroups(:,2), 'sadie'));
summaryResultsDummy = summaryResults( ...
    strcmp(HRTFGroups(:,1), 'th-koln') ...
    & strcmp(HRTFGroups(:,2), 'tu-berlin'));

summaryResultsHumanT = struct2table(summaryResultsHuman);
summaryResultsDummyT = struct2table(summaryResultsDummy);

humanStatsT = grpstats(summaryResultsHumanT,'Iteration',{'mean'},'DataVars',{'Accuracy'});
dummyStatsT = grpstats(summaryResultsDummyT,'Iteration',{'mean'},'DataVars',{'Accuracy'});

humanMean = mean(humanStatsT.mean_Accuracy);
humanStd = std(humanStatsT.mean_Accuracy);

dummyMean = mean(dummyStatsT.mean_Accuracy);
dummyStd = std(dummyStatsT.mean_Accuracy);

fprintf('human: %f(%f), \t dummy: %f(%f)\n', ...
    humanMean*100,humanStd*100, ...
    dummyMean*100,dummyStd*100);


