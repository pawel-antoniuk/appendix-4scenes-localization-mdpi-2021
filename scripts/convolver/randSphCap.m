function [azel,minAngle,maxAngle] = randSphCap(N, direction, capAngle)

capAngleRad = deg2rad(capAngle);
directionRad = deg2rad(direction);

z = (1 - cos(capAngleRad)).* rand(1, N) + cos(capAngleRad);
az = rand(1, N) * 2 * pi;
el = atan2(z, sqrt(1-z.^2));

[x,y,z] = sph2cart(az, el, 1);

rotx = @(t) [1 0 0; 0 cos(t) -sin(t); 0 sin(t) cos(t)];
rotz = @(t) [cos(t) -sin(t) 0; sin(t) cos(t) 0; 0 0 1];

xyz = rotz(directionRad(1)-pi/2) ...
    * rotx(directionRad(2)-pi/2) ...
    * [x; y; z];

[az,el] = cart2sph(xyz(1, :), xyz(2, :), xyz(3, :));
azel = rad2deg([az; el]');
azel(1, :) = wrapTo360(azel(1, :));
azel(2, :) = wrapTo180(azel(2, :));

directionRad = deg2rad(direction);
[dX,dY,dZ] = sph2cart(directionRad(1), directionRad(2), 1);

angles = rad2deg(acos(dot(xyz, repmat([dX; dY; dZ], 1, size(xyz,2)))));
minAngle = min(angles);
maxAngle = max(angles);
