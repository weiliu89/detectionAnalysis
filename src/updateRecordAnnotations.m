function rec = updateRecordAnnotations(rec, annotationpath, cls)

%[gids,gxmin,gymin,gxmax,gymax]=textread(sprintf(gttrdetpath,cls),'%s %f %f %f %f');
[data, labels] = readGtData(sprintf(annotationpath, cls));


%[gtids,imgsize,objsize,objrel,objcat,diff,trun,occl,view,part,group,ground,note]=...
%    textread(gtfn,'%s %f %f %f %s %d %d %d %s %s %d %s %s');
anni = 0;
for r = 1:numel(rec)
  for o = 1:numel(rec(r).objects)
    if strcmp(rec(r).objects(o).class, cls)
      if ~rec(r).objects(o).difficult
        anni = anni + 1;
        
        bbox = rec(r).objects(o).bbox;
        if (bbox(3)-bbox(1)+1)*(bbox(4)-bbox(2)+1)~=data(anni, end-1)
          keyboard;
        end
        
        occ = data(anni, 3);
        if strcmp(cls, 'diningtable')
          parts = data(anni, 4:5);
          view = data(anni, 6:7);
        else
          parts = data(anni, 4:end-7);
          view = data(anni, end-6:end-2);
        end
        
        
        rec(r).objects(o).details = getDetailStructure(cls, occ, view, parts, bbox);

      end
    end
  end
end

function d = getDetailStructure(cls, occ, view, parts, bb)

d = struct('occ_level', [], 'side_visible', [], 'part_visible', [], ...
  'bbox_area', [], 'bbox_aspectratio', []);
d.occ_level = occ+1; % = {1: none, 2:low, 3:medium, 4:high
if strcmp(cls, 'diningtable')
  d.side_visible = struct('side', view(1), 'top', view(2));
elseif strcmp(cls, 'bicycle')
  d.side_visible = struct('bottom', view(1), 'front', view(2), ...
    'rear', view(3), 'top', view(4), 'side', view(5));
else  
  d.side_visible = struct('bottom', view(1), 'front', view(2), ...
    'rear', view(3), 'side', view(4), 'top', view(5));
end
  
%   if strcmp(cls, 'aeroplane') || strcmp(cls, 'chair') || strcmp(cls, 'boat')
%   d.side_visible = struct('bottom', view(1), 'front', view(2), ...
%     'top', view(3), 'side', view(4), 'rear', view(5));
% elseif strcmp(cls, 'cat') || strcmp(cls, 'bird') || strcmp(cls, 'bicycle')
%   d.side_visible = struct('bottom', view(1), 'front', view(2), ...
%     'rear', view(3), 'side', view(4), 'top', view(5));
% end

d.bbox_area = (bb(3)-bb(1)+1)*(bb(4)-bb(2)+1);
d.bbox_aspectratio = (bb(3)-bb(1)+1)./(bb(4)-bb(2)+1);


switch cls
  case 'aeroplane'
    pname = {'body', 'head', 'tail', 'wing'};
  case 'bicycle'
    pname = {'body', 'handlebars', 'seat', 'wheel'};
  case 'boat'
    pname = {'body', 'cabin', 'mast', 'paddle', 'sail', 'window'};
  case 'bird'
    pname = {'body', 'face', 'beak', 'leg', 'tail', 'wing'};
  case 'cat'
    pname = {'body', 'ear', 'face', 'leg', 'tail'};
  case 'chair'
    pname = {'backrest', 'cushion', 'handrest', 'leg'};
  case 'diningtable'
    pname = {'tableleg', 'tabletop'};
  otherwise 
    error('unknown class');
end
for k = 1:numel(pname)
  d.part_visible.(pname{k}) = parts(k);
end

np = 0;
partnames = fieldnames(d.part_visible);
for k = 1:numel(partnames)
  np = np+d.part_visible.(partnames{k});
end
if np~=sum(parts)
  error('part missassignment')
end