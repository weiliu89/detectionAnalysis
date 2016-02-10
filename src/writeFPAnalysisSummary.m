function writeFPAnalysisSummary(result, allnames, detname, fn)

animals = [3 8 10 12 13 17];    % animals without person
vehicles = [1 4 6 7 19 2 14]; % exclude bicycle motorcycle
furniture = [9 11 18]; % chair, table, sofa    
    

for k  =1:numel(allnames)
  allnames{k} = allnames{k}(1:min(5, numel(allnames{k})));
end

fid = fopen(fn, 'w');
fprintf(fid, sprintf('False positive analysis: %s\n', detname));
fprintf(fid, sprintf('%s\n', date));

fprintf(fid, '\n');
fprintf(fid, 'Impact on Performance (AP)\n');
fprintf(fid, '- means none of that kind of FP; + means only that kind of FP\n');
fprintf(fid, ['Name' repmat(' ', [1 11]) 'All\t' 'Rec\t -Loc\t fxLoc \t +Loc\t -Sim\t +Sim\t ' ...
  '-BG\t +BG\t -LocSim\n']);
for o = 1:numel(result)  
  name = repmat(' ', [1 15]); name(1:numel(result(o).name)) = upper(result(o).name);  
  improvement(o, 1:10) = [result(o).all.ap result(o).all.r(end) result(o).ignoreloc.ap result(o).fixloc.ap  result(o).onlyloc.ap ...
    result(o).ignoresimilar.ap result(o).onlysimilar.ap ...
    result(o).ignorebg.ap result(o).onlybg.ap result(o).ignorelocsim.ap];
  fprintf(fid, ['%s' repmat('%0.3f\t', [1 size(improvement,2)]) '\n'], name, improvement(o, :));
end
if numel(allnames)==20
  fprintf(fid, ['%s        \t' repmat('%0.3f\t', [1 size(improvement,2)]) '\n'], 'animals', mean(improvement(animals, :)));
  fprintf(fid, ['%s       \t' repmat('%0.3f\t', [1 size(improvement,2)]) '\n'], 'vehicles', mean(improvement(vehicles, :)));
  fprintf(fid, ['%s      \t' repmat('%0.3f\t', [1 size(improvement,2)]) '\n'], 'furniture', mean(improvement(furniture, :)));
end

if 0 % skipping APN
fprintf(fid, '\n');
fprintf(fid, 'Impact on Performance (APn)\n');
fprintf(fid, '- means none of that kind of FP; + means only that kind of FP\n');
fprintf(fid, ['Name' repmat(' ', [1 11]) 'All\t Rec\t -Loc\t \t fxLoc \t +Loc\t -Sim\t +Sim\t ' ...
  '-BG\t +BG\t -LocSim\n']);
for o = 1:numel(result)  
  name = repmat(' ', [1 15]); name(1:numel(result(o).name)) = upper(result(o).name);  
  improvement(o, 1:10) = [result(o).all.apn result(o).all.r(end) result(o).ignoreloc.apn result(o).fixloc.apn  result(o).onlyloc.apn ...
    result(o).ignoresimilar.apn result(o).onlysimilar.apn ...
    result(o).ignorebg.apn result(o).onlybg.apn result(o).ignorelocsim.apn];
  fprintf(fid, ['%s' repmat('%0.3f\t', [1 size(improvement,2)]) '\n'], name, improvement(o, :));
end
fprintf(fid, ['%s        \t' repmat('%0.3f\t', [1 size(improvement,2)]) '\n'], 'animals', mean(improvement(animals, :)));
fprintf(fid, ['%s       \t' repmat('%0.3f\t', [1 size(improvement,2)]) '\n'], 'vehicles', mean(improvement(vehicles, :)));
fprintf(fid, ['%s      \t' repmat('%0.3f\t', [1 size(improvement,2)]) '\n'], 'furniture', mean(improvement(furniture, :)));
end

for k = numel(result(1).confuse_count.total) %only writing out last case
  fprintf(fid, '\n');
  fprintf(fid, 'Top FP (%d)\n', k);
  fprintf(fid, ['Name' repmat(' ', [1 11]) 'total\t loc\t sim\t other\t bg\n']);
  for o = 1:numel(result)  
    count = result(o).confuse_count;  
    name = repmat(' ', [1 15]); name(1:numel(result(o).name)) = upper(result(o).name);  
    total = count.total(k) - count.correct(k);
    nfp(o, 1:5) = [total [count.loc(k) count.similarobj(k) count.otherobj(k) count.bg(k)]./total];
    fprintf(fid, ['%s\t%d\t' repmat('%0.3f\t', [1 4]) '\n'], name, nfp(o, 1), nfp(o, 2:end));    
  end
  if numel(allnames)==20
  fprintf(fid, ['%s        \t%d\t' repmat('%0.3f\t', [1 4]) '\n'], 'animals', round(mean(nfp(animals, 1))), mean(nfp(animals, 2:end)));  
  fprintf(fid, ['%s       \t%d\t' repmat('%0.3f\t', [1 4]) '\n'], 'vehicles', round(mean(nfp(vehicles, 1))), mean(nfp(vehicles, 2:end)));  
  fprintf(fid, ['%s      \t%d\t' repmat('%0.3f\t', [1 4]) '\n'], 'furniture', round(mean(nfp(furniture, 1))), mean(nfp(furniture, 2:end)));
  end
  
  fprintf(fid, [repmat(' ', [1 15]) repmat('%s\t', [1 numel(allnames)]) '\n'], allnames{:});
  for o = 1:numel(result)
    count = result(o).confuse_count;  
    total = count.total(k) - count.correct(k);
    name = repmat(' ', [1 15]); name(1:numel(result(o).name)) = upper(result(o).name);  
    fprintf(fid, ['%s\t' repmat('%0.3f\t', [1 numel(count.object(:, k))]) '\n'], name, count.object(:, k)'./total);
  end
      
end

fclose(fid);