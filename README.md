Derek Hoiem
July 30, 2012 (updated July 31, 2014)

This project contains the source code and annotations for analyzing object
detectors with the PASCAL VOC 2007 dataset.  The annotations were created
by Yodsawalai Chodpathumwan in Spring 2010 and Fall 2011 as an undergraduate
RA.  The associated published paper is:

D. Hoiem, Y. Chodpathumwan, and Q. Dai, 
"Diagnosing Error in Object Detectors", ECCV 2012.


*************  How to Run  *************** 

CASE I: PASCAL VOC 2007, felzenszwalb or vedaldi detectors
1) In detectionAnalysisScript, set all flags on top to 1 (true)  
    (note: DO_SHOW_SURPRISING_MISSES is optional)
2) Set the imdir path to a valid directory of VOC images
3) Run detectionAnalysisScript in Matlab

CASE II: PASCAL VOC 2007, your own detectors
1) Create a text file of detector outfits with rows of 
   file_id conf x1 y1 x2 y2 (standard format, see readDetections.m).
   Put this file in a subdirectory within detections.
2) Add a corresponding entry to setDetectorInfo.m and update detector variable in 
   detectionAnalysisScript.
3) Perform all steps of CASE I.

CASE III: later versions of VOC
Annotations are not currently available for detailed analysis of true detections.
1) Modify setDatasetParameters.m: 
   a) Set the imdir, VOCsourcepath, and VOCset to correspond to the dataset
   b) Set objnames_extra = {};  change objnames_extra in DISPLAY_TP to 
      objnames_selected.
2) Run as in CASE I or II

Case IV: other datasets
If detections are bounding boxes and evaluation criteria is similar, use 'voc_compatible'
as detector type and update setDatasetParameters.m.  Otherwise, more modification may be
required; see details in Code_Explanation.txt.  

CREATING A REPORT
1) The tex file for a report will be created for you in results/detname/tex.  
2) Automatically remove whitespace from the figures using an Adobe Acrobat 
   batch process or this script for pdfcrop from Ross Girshick:
      #!/bin/sh
      find . -name "*.pdf" -print0 | xargs -P6 -0 -I file pdfcrop file file
3) Use a latex compiler on detectionAnalysisAutoReportTemplate to make the pdf.


*************  Description of Folders  *************** 

annotations: 
Contains annotations for objects (excluding "difficult" objects, as defined
by VOC annotations).  The file Labels.txt helps to explain the format.  
Each file also contains whether the object was detected by the Felzenszwalb
or the Vedaldi detector and the corresponding confidence, but this need not
be used.

src: 
Contains code for reading the annotations and storing them in the PASCAL VOC
record structure.  Also contains code for computing normalized average 
precision and making comparisons between different subsets of the data.

results: 
For each detector, contains tables of normalized AP for various subsets of 
data and comparison plots.

detections: 
For each detector, contains a list of all detections above some threshold
for each object.


*************  Description of Script/Functions  *************** 

detectionAnalysisScript: the main script for analysis
  TP_ANALYSIS: correlates detections with ground truth, assigns attributes
               such as occlusion and aspect to each object, and computes
               performance measures for various subsets of objects
  FP_ANALYSIS: computes fraction of top false positives due to localization
               error, confusion with similar objects, etc.; also computes
               the AP impact of false positives
  TP_DISPLAY:  creates plots showing performance of detector for different
               subsets of objects, a summary plot, a text summary of 
               characteristics of missed objects, and images of objects
               that are less confidently detected than expected 
  FP_DISPLAY:  displays statistics of the frequency and impact of false 
               positives, including creation of a table in a text file
  DO_TEX:      creates tex files for compiling a report

Other useful functions
  displayTopFP: displays most confident false positives
  displayRankedPositives: shows detection confidences of a subset of objects, 
                          from most to least confident



*************  Further Help  *************** 
Contact dhoiem@illinois.edu if there is a problem with the annotations or code.
If instructions are unclear or incomplete, please try to figure it out first and
send me a corrected version of the instructions.  If you can't figure it out,
email me, and I will help as time allows.
 


 
