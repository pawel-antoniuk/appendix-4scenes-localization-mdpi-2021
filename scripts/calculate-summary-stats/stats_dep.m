load('summary_dep1.mat');
labelNames = h5read('specgram_fbud.h5', '/labelNames');
widths = unique([summaryResults.Width]);

allIterations = unique([summaryResults.Iteration]);
iWidth = 1;
Ts = table;

allTestTargets = [];
allTestPreds = [];

for iteration = allIterations
    perWidthResult = summaryResults( ...
        [summaryResults.Width] == widths(iWidth) ...
        & [summaryResults.Iteration] == iteration);
    statsout = confusionmatStats( ...
        reshape([perWidthResult.TestTargets],1,[]), ...
        reshape([perWidthResult.TestPreds],1,[]));
    
    T = table(labelNames, statsout.precision, statsout.recall, statsout.Fscore, ...
        'VariableNames',{'Label', 'Precision','Recall','F1'});
    Ts = [Ts; T];
end

Tstats = grpstats(Ts,'Label',{'mean','std'});
Tstats.mean_Precision = Tstats.mean_Precision * 100;
Tstats.std_Precision = Tstats.std_Precision * 100;
Tstats.mean_Recall = Tstats.mean_Recall * 100;
Tstats.std_Recall = Tstats.std_Recall * 100;
Tstats.mean_F1 = Tstats.mean_F1 * 100;
Tstats.std_F1 = Tstats.std_F1 * 100;
Tstats

