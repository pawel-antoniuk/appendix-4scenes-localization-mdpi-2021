summaryResults = load('../models/human-artificial/summary_human_dummy.mat', 'summaryResults').summaryResults;
summaryResultsT = struct2table(summaryResults);
summaryResultsT = summaryResultsT(:,{'Accuracy','Width','HRTFGroup','Iteration'});
summaryResultsT = sortrows(summaryResultsT, {'HRTFGroup', 'Width'});
writetable(summaryResultsT, 'human-dummy.xlsx');