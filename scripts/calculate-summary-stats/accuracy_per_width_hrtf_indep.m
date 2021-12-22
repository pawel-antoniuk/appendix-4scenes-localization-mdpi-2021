summaryResults = load('../models/HRTF-independent/summary_indep', 'summaryResults').summaryResults;
summaryResultsT = struct2table(summaryResults);
summaryResultsT = summaryResultsT(:,{'Accuracy','Width','HRTFGroup','Iteration'});
summaryResultsT = sortrows(summaryResultsT, {'HRTFGroup', 'Width'});
writetable(summaryResultsT, 'HRTF-independent.xlsx');