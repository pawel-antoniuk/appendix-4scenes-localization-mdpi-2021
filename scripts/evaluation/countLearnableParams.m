function n = countLearnableParams(net)
      n = 0;
    for iLayer = 1:length(net.Layers)
        layer = net.Layers(iLayer);
        className = class(layer);
        className = split(className, '.');
        className = className{end};
        
        switch className
            case 'Convolution2DLayer'
                n = n + numel(layer.Weights) + numel(layer.Bias);
            case 'BatchNormalization'
                n = n + numel(layer.Offset) + numel(layer.Scale);
            case 'FullyConnectedLayer'
                n = n + numel(layer.Weights) + numel(layer.Bias);
        end
    end
end