function []=plotAngles(frontAzi,backAzi,txtTitle)
% Plot audio objects and angle sectors
% Removing underscore signes in the title
txtTitle(find(txtTitle == '_')) = ' ';

%% Figure - FB
figure
set(gcf, 'Position', [10, 525, 450,400])

% Plotting sectors
sctRadius = 4;
rho = [0 sctRadius];
theta = [-pi/6 -pi/6];
polarplot(theta,rho,'k--');
title(txtTitle);
hold on
theta = [pi/6 pi/6];
polarplot(theta,rho,'k--');
theta = [5*pi/6 5*pi/6];
polarplot(theta,rho,'k--');
theta = [-5*pi/6 -5*pi/6];
polarplot(theta,rho,'k--');

% Plotting audio objects
r = 3;
colors = lines(64);
polarPlot = polarplot(deg2rad(frontAzi),r,'o', ...
        'MarkerFaceColor',colors(1,:),'MarkerEdgeColor',colors(1,:)); 
% polarPlot = polarplot(deg2rad(backAzi),r,'o', ...
%         'MarkerFaceColor',colors(1,:),'MarkerEdgeColor',colors(1,:)); 
rlim([0 4]);

% Plotting listener's head
polarplot(0,0,'ko','MarkerSize',24,'MarkerFaceColor','white');
polarplot(0,0.43,'k^','MarkerSize',6,'MarkerFaceColor','white');

% Finalizing plots
hold off
ax = gca;
ax.ThetaZeroLocation = 'top';
ax.RTickLabel = []; 
ax.ThetaTickLabel = {0 30 60 90 120 150 180 ...
    -150 -120 -90 -60 -30};


%% Figure - BF
figure
set(gcf, 'Position', [10, 40, 450,400])

% Plotting sectors
sctRadius = 4;
rho = [0 sctRadius];
theta = [-pi/6 -pi/6];
polarplot(theta,rho,'k--');
title(txtTitle);
hold on
theta = [pi/6 pi/6];
polarplot(theta,rho,'k--');
theta = [5*pi/6 5*pi/6];
polarplot(theta,rho,'k--');
theta = [-5*pi/6 -5*pi/6];
polarplot(theta,rho,'k--');

% Plotting audio objects
r = 3;
colors = lines(64);
% polarPlot = polarplot(deg2rad(frontAzi),r,'o', ...
%         'MarkerFaceColor',colors(2,:),'MarkerEdgeColor',colors(2,:)); 
polarPlot = polarplot(deg2rad(backAzi),r,'o', ...
        'MarkerFaceColor',colors(1,:),'MarkerEdgeColor',colors(1,:)); 
rlim([0 4]);

% Plotting listener's head
polarplot(0,0,'ko','MarkerSize',24,'MarkerFaceColor','white');
polarplot(0,0.43,'k^','MarkerSize',6,'MarkerFaceColor','white');

% Finalizing plots
hold off
ax = gca;
ax.ThetaZeroLocation = 'top';
ax.RTickLabel = []; 
ax.ThetaTickLabel = {0 30 60 90 120 150 180 ...
    -150 -120 -90 -60 -30};


