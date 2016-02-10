function dataset_params = setDatasetParameters(dataset)
% dataset_params = setDatasetParameters(dataset)
%
% Sets machine-specific and datset-specific parameters such as image paths.
%
% Required parameters: 
%   imdir: directory containing images
%   objnames_all{nclasses}: names for each object class, order specifies
%     index for each class
%   objnames_extra{nclasses}: names of classes for more detailed analysis
%     (may only be relevant for VOC2007); if not available, set to {}
%   similar_classes{ngroups}: set of equivalence sets such that any pair of
%     classes in an equivalence set is considered similar (symmetric binary
%     confusion matrix can be encoded as a set of pairs); sets consist of
%     indices into classes given by objnames_all
%  summary_sets{nsets}: sets of indices that will be used to summarize 
%     stastics 
%  summary_setnames{nsets}: names of each set (e.g., animal)

switch lower(dataset)
  case 'voc'
    dataset_params.imset = 'test';  % set used for analysis
    dataset_params.imdir = '/home/dhoiem/data/pascal07/VOCdevkit/VOC2007/JPEGImages/'; % needs to be set for your computer
    dataset_params.VOCsourcepath = './VOCcode';  % change this for later VOC versions
    dataset_params.VOCset = 'VOC2007';
    addpath(dataset_params.VOCsourcepath);
    dataset_params.annotationdir = '../annotations';
    dataset_params.objnames_extra = {'aeroplane', 'bicycle', 'bird', 'boat', 'cat', ...
      'chair', 'diningtable'}; % required parameter: specify objects with extra annotation -- set to empty set if not using VOC2007
    dataset_params.confidence_threshold = -Inf; % minimum confidence to be included in analysis (e.g., set to 0.01 to improve speed)

    % all object names
    dataset_params.objnames_all = {'aeroplane', 'bicycle', 'bird', 'boat', 'bottle', 'bus', 'car', ...
       'cat', 'chair', 'cow', 'diningtable', 'dog', 'horse', 'motorbike', 'person', ...
       'pottedplant', 'sheep', 'sofa', 'train', 'tvmonitor'}; 
    
    % specify sets of similar objects
    animals = [3 8 10 12 13 15 17];    % animals + person (15)
    vehicles1 = [1 4 6 7 19 2 14]; % all vehicles (may want to exclude bicycle motorcycle)
    vehicles2 = [2 14]; % bicycle motorcycle
    furniture = [9 11 18]; % chair, table, sofa    
    airobjects = [1 3]; % bird, airplane
    dataset_params.similar_classes = {animals, vehicles1, vehicles2, furniture, airobjects}; 

    % specify summary sets
    dataset_params.summary_sets = cat(2, {[3 8 10 12 13 17], [1 4 6 7 19 2 14], [9 11 18]});        
    dataset_params.summary_setnames = {'animals', 'vehicles', 'furniture'};    
    
    % localization criteria
    dataset_params.iuthresh_weak = 0.1;  % intersection/union threshold
    dataset_params.idthresh_weak = 0;    % intersection/det_area threshold   
    dataset_params.iuthresh_strong = 0.5;  % intersection/union threshold
    dataset_params.idthresh_strong = 0;    % intersection/det_area threshold 
    
end

