function [bestFitAngles,bestFitAnglesI] = findBestFitAnglePairs(...
    anglePairsToFit, desiredAnglePairs, directionAngles, ...
    capWidth, capWidthEps)

%     desDirAngSub = angleDistance(desiredAnglePairs,directionAngles);
%     anglesInAreaIdx = find(desDirAngSub <= capWidth + capWidthEps);
%     desiredAnglePairs = desiredAnglePairs(anglesInAreaIdx, :);
    
    a = repelem(anglePairsToFit, size(desiredAnglePairs, 1), 1);
    b = repmat(desiredAnglePairs, size(anglePairsToFit, 1), 1);
    dist1 = angleDistance(a, b);
    dist2 = reshape(dist1, size(desiredAnglePairs, 1), size(anglePairsToFit, 1));
    [~,minDistI] = min(dist2, [], 1);
    bestFitAngles = desiredAnglePairs(minDistI, :);
    bestFitAnglesI = minDistI;
end




