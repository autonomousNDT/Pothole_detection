clc;	% Clear command window.
clear;	% Delete all variables.
close all;	% Close all figure windows except those created by imtool.
workspace;	% Make sure the workspace panel is showing.



[rgbImage, storedColorMap] = imread('pothole2.jpg'); 
rgbImage = imgaussfilt(rgbImage);

	[rows, columns, numberOfColorBands] = size(rgbImage); 
	% If it's monochrome (indexed), convert it to color. 
	% Check to see if it's an 8-bit image needed later for scaling).
	if strcmpi(class(rgbImage), 'uint8')
		% Flag for 256 gray levels.
		eightBit = true;
	else
		eightBit = false;
	end
	if numberOfColorBands == 1
		if isempty(storedColorMap)
			% Just a simple gray level image, not indexed with a stored color map.
			% Create a 3D true color image where we copy the monochrome image into all 3 (R, G, & B) color planes.
			rgbImage = cat(3, rgbImage, rgbImage, rgbImage);
		else
			% It's an indexed image.
			rgbImage = ind2rgb(rgbImage, storedColorMap);
			% ind2rgb() will convert it to double and normalize it to the range 0-1.
			% Convert back to uint8 in the range 0-255, if needed.
			if eightBit
				rgbImage = uint8(255 * rgbImage);
			end
		end
    end 
    
    
    
    % Convert RGB image to HSV
	hsvImage = rgb2hsv(rgbImage);
	% Extract out the H, S, and V images individually
	hImage = hsvImage(:,:,1);
	sImage = hsvImage(:,:,2);
	vImage = hsvImage(:,:,3);
	

		valueThresholdLow = 0.05;
        
 		valueThresholdHigh = 1.0;
         
 	valueMask = (vImage <= valueThresholdLow) ;
     coloredObjectsMask = uint8(valueMask);
     smallestAcceptableArea = 10;
     coloredObjectsMask = uint8(bwareaopen(coloredObjectsMask, smallestAcceptableArea));
     
     structuringElement = strel('disk', 4);
 	coloredObjectsMask = imclose(coloredObjectsMask, structuringElement);
    
    coloredObjectsMask = imfill(logical(coloredObjectsMask), 'holes');
    
    imshow(coloredObjectsMask)
    
  
    
    %get outlines of each object
[B,L,N] = bwboundaries(coloredObjectsMask);
%get stats
stats=  regionprops(L, 'Centroid', 'Area', 'Perimeter');
Centroid = cat(1, stats.Centroid);
Perimeter = cat(1,stats.Perimeter);
Area = cat(1,stats.Area);
CircleMetric = (Perimeter.^2)./(4*pi*Area);  %circularity metric
SquareMetric = NaN(N,1);
TriangleMetric = NaN(N,1);
%for each boundary, fit to bounding box, and calculate some parameters
for k=1:N,
   boundary = B{k};
   [rx,ry,boxArea] = minboundrect( boundary(:,2), boundary(:,1));  %x and y are flipped in images
   %get width and height of bounding box
   width = sqrt( sum( (rx(2)-rx(1)).^2 + (ry(2)-ry(1)).^2));
   height = sqrt( sum( (rx(2)-rx(3)).^2+ (ry(2)-ry(3)).^2));
   aspectRatio = width/height;
   if aspectRatio > 1,  
       aspectRatio = height/width;  %make aspect ratio less than unity
   end
   SquareMetric(k) = aspectRatio;    %aspect ratio of box sides
   TriangleMetric(k) = Area(k)/boxArea;  %filled area vs box area
end
%define some thresholds for each metric
%do in order of circle, triangle, square, rectangle to avoid assigning the
%same shape to multiple objects
isCircle =   (CircleMetric < 1.15);
isTriangle = ~isCircle & (TriangleMetric < 0.61);
isSquare =   ~isCircle & ~isTriangle & (SquareMetric > 0.9);
isRectangle= ~isCircle & ~isTriangle & ~isSquare;  %rectangle isn't any of these
%assign shape to each object
whichShape = cell(N,1);  
whichShape(isCircle) = {'Circle'};
whichShape(isTriangle) = {'Triangle'};
whichShape(isSquare) = {'Square'};
whichShape(isRectangle)= {'Rectangle'};
%now label with results
RGB = label2rgb(L);
imshow(RGB); hold on;
Combined = [CircleMetric, SquareMetric, TriangleMetric];
for k=1:N,
   %display metric values and which shape next to object
   Txt = sprintf('C=%0.3f S=%0.3f T=%0.3f',  Combined(k,:));
   text( Centroid(k,1)-20, Centroid(k,2), Txt);
   text( Centroid(k,1)-20, Centroid(k,2)+20, whichShape{k});
end