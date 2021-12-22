function r = randSphericalCap(coneAngleDegree, coneDir, N, RNG)

if ~exist('coneDir', 'var') || isempty(coneDir)
  coneDir = [0;0;1];
end

if ~exist('N', 'var') || isempty(N)
  N = 1;
end

if ~exist('RNG', 'var') || isempty(RNG)
  RNG = RandStream.getGlobalStream();
end

coneAngle = coneAngleDegree * pi/180;

% Generate points on the spherical cap around the north pole [1].
% [1] See https://math.stackexchange.com/a/205589/81266
z = RNG.rand(1, N) * (1 - cos(coneAngle)) + cos(coneAngle);
phi = RNG.rand(1, N) * 2 * pi;
x = sqrt(1-z.^2).*cos(phi);
y = sqrt(1-z.^2).*sin(phi);

% If the spherical cap is centered around the north pole, we're done.
if all(coneDir(:) == [0;0;1])
  r = [x; y; z];
  return;
end

% Find the rotation axis `u` and rotation angle `rot` [1]
u = normc(cross([0;0;1], normc(coneDir)));
rot = acos(dot(normc(coneDir), [0;0;1]));

% Convert rotation axis and angle to 3x3 rotation matrix [2]
% [2] See https://en.wikipedia.org/wiki/Rotation_matrix#Rotation_matrix_from_axis_and_angle
crossMatrix = @(x,y,z) [0 -z y; z 0 -x; -y x 0];
R = cos(rot) * eye(3) + sin(rot) * crossMatrix(u(1), u(2), u(3)) + (1-cos(rot))*(u * u');

% Rotate [x; y; z] from north pole to `coneDir`.
r = R * [x; y; z];

end

function y = normc(x)
y = bsxfun(@rdivide, x, sqrt(sum(x.^2)));
end