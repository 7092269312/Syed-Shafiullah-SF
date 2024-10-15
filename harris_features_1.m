
clc; close all; clear all;

    % Step 1: Load the input image
    [inputFileName, inputPath] = uigetfile({'*.jpg;*.png;*.bmp;*.gif;*.tiff;*.jpeg', 'Image Files (*.jpg, *.png, *.bmp, *.gif, *.tiff, *.jpeg)'}, 'Select the Input Signature Image');
    if inputFileName == 0
        errordlg('No input image selected.');
        return;
    end
    
    inputImage = imread(fullfile(inputPath, inputFileName));
    
    % Step 2: Convert the input image to grayscale (if it's not already)
    if size(inputImage, 3) == 3
        inputImageGray = rgb2gray(inputImage);  % Convert RGB to grayscale
    else
        inputImageGray = inputImage;  % Already grayscale
    end
    
    % Normalize the grayscale image for better processing
    inputImageGray = mat2gray(inputImageGray);

    % Step 3: Harris corner detection on the input image
    points1 = detectHarrisFeatures(inputImageGray);
    [features1, valid_points1] = extractFeatures(inputImageGray, points1);

    % Step 4: Select the folder containing reference images
    folderPath = uigetdir('Select the Folder Containing Signature Images');
    if folderPath == 0
        errordlg('No folder selected.');
        return;
    end
    
    % Get the list of images in the folder
    imageFiles = dir(fullfile(folderPath, '*.*'));  % Get all files in the folder
    validImages = {};  % Initialize a cell array for valid image file names
    
    % Filter to keep only image files
    for k = 1:length(imageFiles)
        [~, ~, ext] = fileparts(imageFiles(k).name);
        if any(strcmpi(ext, {'.jpg', '.png', '.bmp', '.gif', '.tiff', '.jpeg'}))
            validImages{end+1} = fullfile(folderPath, imageFiles(k).name);  % Add valid image paths
        end
    end
    
    numImages = length(validImages);
    if numImages == 0
        errordlg('No images found in the folder.');
        return;
    end
    
    % Create a figure with subplots for displaying images
    figure('Name', 'Signature Verification');
    
    % Display the grayscale input image
    subplot(2, 2, 1);  % First subplot in a 2x2 grid
    imshow(inputImageGray);
    title('Grayscale Input Image');
    
    % Display the detected Harris corners on the input image
    subplot(2, 2, 2);  % Second subplot
    imshow(inputImageGray); hold on;
    plot(points1.selectStrongest(10)); % Show strongest 10 corners
    title('Harris Corners on Input Image');
    
    % Initialize variables for comparison
    isMatchFound = false;
    bestMatchImage = [];
    
    % Step 5: Compare the input image with each valid image in the folder
    for i = 1:numImages
        % Read the current image
        currentImage = imread(validImages{i});
        
        % Convert the current image to grayscale (if it's RGB)
        if size(currentImage, 3) == 3
            currentImageGray = rgb2gray(currentImage);
        else
            currentImageGray = currentImage;
        end
        
        % Harris corner detection and feature extraction for the current image
        points2 = detectHarrisFeatures(currentImageGray);
        [features2, valid_points2] = extractFeatures(currentImageGray, points2);
        
        % Match features using Harris corner detection
        indexPairs = matchFeatures(features1, features2);
        matchedPoints1 = valid_points1(indexPairs(:, 1), :);
        matchedPoints2 = valid_points2(indexPairs(:, 2), :);
        
        % Calculate the difference metric for matching
        u = matchedPoints2.Metric - matchedPoints1.Metric;
        
        % Display matched features with both images in the same figure window
        subplot(2, 2, 3);  % Third subplot
        showMatchedFeatures(inputImage, currentImage, matchedPoints1, matchedPoints2, 'montage');
        title(['Matched Features with ', imageFiles(i).name]);
        
        % Check if a match is found
        if abs(u) <= 0.04  % Similarity threshold
            isMatchFound = true;
            bestMatchImage = currentImage;  % Store the best matching image
            break;  % Exit the loop if a match is found
        end
    end
    
    % Step 6: Display the result of the signature verification
    subplot(2, 2, 4);  % Fourth subplot
    if isMatchFound
        imshow(bestMatchImage);  % Show the matched image in color
        title('Match Found');
        msgbox('Match Found!', 'Result');
    else
        title('No Match Found');
        msgbox('No Match Found.', 'Result');
    end

