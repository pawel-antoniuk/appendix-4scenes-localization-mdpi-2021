function c = angleAbsDiff(a, b)
c = rem(a - b, 360);
if a < 360
    a = a + 360;
end
if b < 360
    b = b + 360;
end
a = 360 - a;
c = abs(a - b);
end