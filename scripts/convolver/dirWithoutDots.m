function items = dirWithoutDots(path)
items = dir(path);
items = items(~ismember({items.name},{'.','..'}));
