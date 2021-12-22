function bestFitAngles = findBestFitAngle(anglesToFit, desiredAngles, ...
    directionAngles, capWidth)

desDirAngDiff = min( ...
    mod(desiredAngles(1, :) - directionAngles(1), 360), ...
    mod(desiredAngles(1, :) - directionAngles(1), 360));
desiredAngles = desiredAngles(desDirAngDiff <= capWidth);

bestFitAngles = zeros(size(anglesToFit));

for iAngle = 1:length(anglesToFit)
    minAngDiff = 720;
    angleToFit = anglesToFit(iAngle);
    for desiredAngle = desiredAngles
        angDiff = abs(rad2deg(angdiff(deg2rad(angleToFit), deg2rad(desiredAngle))));
        if angDiff < minAngDiff
            bestFitAngles(iAngle) = desiredAngle;
            minAngDiff = angDiff;
        end
    end
end

