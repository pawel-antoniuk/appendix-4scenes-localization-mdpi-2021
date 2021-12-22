function outAng = angSub(ang1, ang2)

outAng = min(mod(ang1 - ang2, 360), mod(ang2 - ang1, 360));