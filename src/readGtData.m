function [data, labels] = readGtData(name)
% [data, labels] = readGtData(name)

fid = fopen(name);
line = fgetl(fid);
labels = strtokAll(line);
%line = fgetl(fid);
data = zeros(10E6, numel(labels));

n = 0;
while true
    line = fgetl(fid);
    if ~ischar(line), break, end
    if isempty(line), continue; end;
    n = n +1;
    data(n, :) = str2num(line);
end
data = data(1:n, :);
fclose(fid);

function strs = strtokAll(str)
strs = {};
rest = str;
while true
    [first, rest] = strtok(rest);
    strs{end+1} = first;
    if isempty(rest)
        break;
    end
end

