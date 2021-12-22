function plt = plotGroupedAnglePairs(allAnglePairs, selectedAnglePairs)

[C,G] = groupcounts(selectedAnglePairs);
selectedAnglePairs = [G{:}];
C = 5 + 60 * normalize(C, 'range');

if ~isempty(allAnglePairs)
    [x, y, z] = sph2cart(deg2rad(allAnglePairs(:, 1)), ...
        deg2rad(allAnglePairs(:, 2)), 1); 
    scatter3(x, y, z, 1, 'k.');
    hold on
end

[x, y, z] = sph2cart(deg2rad(selectedAnglePairs(:, 1)), ...
    deg2rad(selectedAnglePairs(:, 2)), 1); 
plt = scatter3(x, y, z, C, C, 'filled');
cb = colorbar; ylabel(cb, 'Count');
colormap jet;
% text(x,y,z,num2str(C));
hold off 

xlim([-1.25 1.25])
ylim([-1.25 1.25])
zlim([-1.25 1.25])
pbaspect([1 1 1])

xlabel('x')
ylabel('y')
zlabel('z')