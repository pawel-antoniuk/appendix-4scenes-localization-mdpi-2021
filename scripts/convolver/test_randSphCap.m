N = 500;
capAngle = 90;

z = zeros(N, 1);
plt = plot3(z, z, z, 'r.', 'MarkerSize', 4);
xlim([-1.25 1.25])
ylim([-1.25 1.25])
zlim([-1.25 1.25])
pbaspect([1 1 1])

for az = 0:10:720    
    el = 0;
    
    razel = deg2rad(randSphCap(N, [az el], capAngle));
    [x,y,z] = sph2cart(razel(:, 1), razel(:, 2), 1);
    plt.XData = x;
    plt.YData = y;
    plt.ZData = z;

    pause(0.1);
    sgtitle(sprintf("azimuth: %d elevation: %d", az, el));
end

for az = 0:10:360    
    for el = 0:10:360
        razel = deg2rad(randSphCap(N, [az el], capAngle));
        [x,y,z] = sph2cart(razel(:, 1), razel(:, 2), 1);
        plt.XData = x;
        plt.YData = y;
        plt.ZData = z;

        pause(0.1);
        sgtitle(sprintf("azimuth: %d elevation: %d", az, el));
    end
end