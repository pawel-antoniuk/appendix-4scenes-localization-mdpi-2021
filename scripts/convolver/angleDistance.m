function d = angleDistance(a, b)
    d = distance('gc', flip(a, 2), flip(b, 2));
    % d = sqrt((a(:,1)-b(:,1)).^2 + (a(2,1)-b(:,2)).^2);
    % [ax,ay,az] = sph2cart(a(:, 1), a(:, 2), 1);
    % [bx,by,bz] = sph2cart(b(:, 1), b(:, 2), 1);
    % d = sqrt((ax-bx).^2 + (ay-by).^2 + (az-bz).^2);
end