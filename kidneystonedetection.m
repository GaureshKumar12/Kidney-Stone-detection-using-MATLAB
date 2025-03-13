clc;
clear all;
close all;
warning off;
%% Step 1: Selecting Input Ultrasonic Image
[filename, pathname] = uigetfile('*.*', 'Pick a MATLAB code file');
filename = strcat(pathname, filename);
original_image = imread(filename);
figure;
imshow(original_image), title('Sample Image');

%% Step 2: Image Preprocessing Phase

% Convert to grayscale
gray_image = rgb2gray(original_image);
figure;
imshow(gray_image), title('Grayscale Image');
impixelinfo;

%% Step 3: Thresholding

% Binarize using a threshold value (20/255)
binary_image = imbinarize(gray_image, 20 / 255);
figure;
imshow(binary_image), title('Binary Thresholding Image');
impixelinfo;

%% Step 4: Hole Filling

% Fill holes in the binary image
filled_image = imfill(binary_image, 'holes');
figure;
imshow(filled_image), title('Holes Filled Image');

%% Step 5: Remove Small Objects

% Remove small objects from binary image
filtered_image = bwareaopen(filled_image, 1000);
figure;
imshow(filtered_image), title('Background Noise Filtered Image');

%% Step 6: Apply Mask to Original Image

% Use filtered image as a mask
PreprocessedImage = uint8(double(original_image) .* repmat(filtered_image, [1, 1, 3]));
figure;
imshow(PreprocessedImage), title("Preprocessed Image");
figure;
imshowpair(original_image, PreprocessedImage, 'montage'), title('Original and Preprocessed Image');

%% Step 7: Enhance Region of Interest

PreprocessedImage_adjust = imadjust(PreprocessedImage, [0.3 0.7], []) + 50;
figure;
imshow(PreprocessedImage_adjust);

% Convert to grayscale again after enhancement
PreprocessedImage_gray = rgb2gray(PreprocessedImage_adjust);
figure;
imshow(PreprocessedImage_gray);

% Apply median filter for noise reduction
median_filtered_image = medfilt2(PreprocessedImage_gray, [5 5]);
figure;
imshow(median_filtered_image);
impixelinfo;

%% Step 8: Final Thresholding for Stone Detection

final_filtered = median_filtered_image > 250;
figure;
imshow(final_filtered);
impixelinfo;

%% Step 9: Region of Interest Selection

% Define the Region of Interest
[r, c, ~] = size(final_filtered);
x1 = r / 2;
y1 = c / 3;

row = [x1, x1+200, x1+200, x1];
col = [y1, y1, y1+40, y1+40];

poly_image = roipoly(final_filtered, row, col);
figure;
imshow(poly_image), title('Region of Interest Poly Image');

% Apply mask to get the stone area
stone_image = final_filtered .* double(poly_image);
figure;
imshow(stone_image), title('Kidney Stone Image');

% Remove small binary objects
final_stone_image = bwareaopen(stone_image, 4);
figure;
imshow(final_stone_image);

%% Step 10: Kidney Stone Detection and Dimension Measurement

% Label connected components in the final binary image
labeledImage = bwlabel(final_stone_image);

% Measure properties of each connected component
stoneProperties = regionprops(labeledImage, 'BoundingBox', 'Area', 'MajorAxisLength', 'MinorAxisLength');

% Conversion factor from pixels to mm (set this based on your ultrasound calibration)
conversionFactor = 0.5; 

% Display dimensions of each detected stone
for k = 1:length(stoneProperties)
    % Extract bounding box dimensions (in pixels)
    boundingBox = stoneProperties(k).BoundingBox;
    width_pixels = boundingBox(3);
    height_pixels = boundingBox(4);
    
    % Convert pixel dimensions to millimeters
    width_mm = width_pixels * conversionFactor;
    height_mm = height_pixels * conversionFactor;
    
    % Display dimensions in pixels and mm
    fprintf('Stone %d dimensions: Width = %.2f pixels (%.2f mm), Height = %.2f pixels (%.2f mm)\n', ...
        k, width_pixels, width_mm, height_pixels, height_mm);
end

% Check if any stone was detected
[~, num] = bwlabel(final_stone_image);
if (num >= 1)
    disp('Stone is Detected');
else
    disp('No Stone is detected');
end

warning off;
