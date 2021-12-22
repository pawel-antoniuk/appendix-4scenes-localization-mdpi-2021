summaryResults = load('../models/HRTF-independent/summary_indep', 'summaryResults').summaryResults;
summaryResultsT = struct2table(summaryResults);
stats = grpstats(summaryResultsT,{'Width','Iteration'},'mean','DataVars',{'Accuracy'});
stats = stats([stats.Width] == 15,:);
stats = grpstats(stats,{'Width'},{'mean','std'},'DataVars','mean_Accuracy');
stats.mean_mean_Accuracy * 100
stats.std_mean_Accuracy * 100



