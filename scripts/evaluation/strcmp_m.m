function out=strcmp_m(a,b)
    sel = cellfun(@(c)strcmp(c,b),a,'UniformOutput',false);
    sel = any(vertcat(sel{:}),2);
    out = a(sel);
end