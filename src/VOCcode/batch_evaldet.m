VOCinit;

classes = VOCopts.classes;
num_classes = length(classes);
aps = zeros(num_classes, 1);
parfor i = 1:num_classes
    [~,~,aps(i)] = VOCevaldet(VOCopts, 'comp4', classes{i}, false);
end

disp(aps');
disp(mean(aps));