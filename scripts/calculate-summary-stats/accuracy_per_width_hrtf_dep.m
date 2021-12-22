summaryResults = load('../models/HRTF-dependent/summary_dep_results_only.mat', 'summaryResults').summaryResults;
summaryResultsT = struct2table(summaryResults);
summaryResultsT = summaryResultsT(:,{'Accuracy','Width','HRTFGroup','Iteration'});
writetable(summaryResultsT, 'HRTF-dependent.xlsx');