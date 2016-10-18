clc;	% Clear command window.
clear;	% Delete all variables.
close all;	% Close all figure windows except those created by imtool.
workspace;	% Make sure the workspace panel is showing.



[rgbImage, storedColorMap] = imread('pothole3.jpg'); 
rgbImage = imgaussfilt(rgbImage);

hsvImage = rgb2hsv(rgbImage);
	vImage = hsvImage(:,:,3);
    
    valueThresholdLow = 0.2
		valueThresholdHigh = 1.0;
        
        valueMask = (vImage <= valueThresholdLow) ;
          coloredObjectsMask = uint8(valueMask);
          
   smallestAcceptableArea =255;
     coloredObjectsMask = bwareaopen(coloredObjectsMask, smallestAcceptableArea);
        imshow(coloredObjectsMask)
[B,L,N] = bwboundaries(coloredObjectsMask);

stats=  regionprops(L, 'Centroid', 'Area', 'Perimeter');
Centroid = cat(1, stats.Centroid);
Perimeter = cat(1,stats.Perimeter);
Area = cat(1,stats.Area);