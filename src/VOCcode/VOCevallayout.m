function [rec,prec,ap] = VOCevallayout(VOCopts,id,draw)

% load test set
[imgids,objids]=textread(sprintf(VOCopts.layout.imgsetpath,VOCopts.testset),'%s %d');

% load ground truth objects
n=0;
tic;
for i=1:length(imgids)
    % display progress
    if toc>1
        fprintf('layout pr: load %d/%d\n',i,length(imgids));
        drawnow;
        tic;
    end
    
    % read annotation
    rec=PASreadrecord(sprintf(VOCopts.annopath,imgids{i}));
    
    % extract object
    n=n+1;
    gt(n)=rec.objects(objids(i));
end

% load results

fprintf('layout pr: loading results...\n');
xml=VOCreadxml(sprintf(VOCopts.layout.respath,id));

% test detections by decreasing confidence

[t,si]=sort(-str2double({xml.results.layout.confidence}));
nd=numel(si);

det=false(n,1);
tp=zeros(nd,1);
fp=zeros(nd,1);

for di=1:nd
    
    if di==6
        drawnow
    end
    
    % display progress
    if toc>1
        fprintf('layout pr: compute: %d/%d\n',di,nd);
        drawnow;
        tic;
    end
    
    % match result to ground truth object
    d=xml.results.layout(di);
    ii=strmatch(d.image,imgids,'exact');
    oi=ii(objids(ii)==str2num(d.object));
    
    if isempty(oi)
        warning('unrecognized layout: image %s, object %s',d.image,d.object);
        continue
    end
    
    % assign true/false positive

    if det(oi)
        fp(di)=1; % multiple detection
    else        
        o=gt(oi);            
        % num detected parts = num gt parts?
        if length(o.part)==length(d.part)            
            op=zeros(size(o.part));
            dp=zeros(size(d.part));
            for k=1:VOCopts.nparts
                op(strmatch(VOCopts.parts{k},{o.part.class},'exact'))=k;
                dp(strmatch(VOCopts.parts{k},{d.part.class},'exact'))=k;
            end                       
            % bag of detected parts = bag of gt parts?
            if all(sort(op)==sort(dp))
                % find possible matches (same type + overlap)
                M=zeros(length(op));
                for k=1:length(dp)
                    bb=str2double({d.part(k).bndbox.xmin d.part(k).bndbox.ymin ...
                                    d.part(k).bndbox.xmax d.part(k).bndbox.ymax});
                    for l=find(op==dp(k))
                        bbgt=o.part(l).bbox;
                        bi=[max(bb(1),bbgt(1)) ; max(bb(2),bbgt(2)) ; min(bb(3),bbgt(3)) ; min(bb(4),bbgt(4))];
                        iw=bi(3)-bi(1)+1;
                        ih=bi(4)-bi(2)+1;
                        if iw>0 & ih>0                
                            % compute overlap as area of intersection / area of union
                            ua=(bb(3)-bb(1)+1)*(bb(4)-bb(2)+1)+...
                               (bbgt(3)-bbgt(1)+1)*(bbgt(4)-bbgt(2)+1)-...
                               iw*ih;
                            ov=iw*ih/ua;
                            M(k,l)=ov>=VOCopts.minoverlap;                            
                        end
                    end
                end   
                % valid assignments for all part types?
                tp(di)=1;
                for k=1:VOCopts.nparts
                    v=(op==k);
                    % each part matchable and sufficient matches?
                    if ~(all(any(M(:,v)))&&sum(any(M(:,v),2))>=sum(v))
                        tp(di)=0;
                        fp(di)=1;
                        break
                    end
                end
            else
                fp(di)=1; % wrong bag of parts
            end
        else
            fp(di)=1; % wrong number of parts
        end

        if tp(di)
            det(oi)=1;
        end        
    end
end

% compute precision/recall

fp=cumsum(fp);
tp=cumsum(tp);
v=tp+fp>0;
rec=tp(v)/n;
prec=tp(v)./(fp(v)+tp(v));

% compute average precision

ap=0;
for t=0:0.1:1
    p=max(prec(rec>=t));
    if isempty(p)
        p=0;
    end
    ap=ap+p/11;
end

if draw
    % plot precision/recall
    plot(rec,prec,'-');
    grid;
    xlabel 'recall'
    ylabel 'precision'
    title(sprintf('subset: %s, AP = %.3f',VOCopts.testset,ap));
end
