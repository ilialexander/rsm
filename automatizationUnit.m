%function automatizationUnit(startFile, endFile)
startFile = 1;
endFile = 1;
% This function does statistical analisys to demonstrate the need of authomatization
% to improve speed.

% We count the SM.input/SDR that connect directly to the same
% next input.

% Then we calculate how many different events can an observation lead to.
% This will be compared to the amount of times that the observation happens.
% There should be a ratio to consider between this two parameters.

fid = fopen('fileList.txt', 'r');
i = 1;
while ~feof(fid)
    fscanf(fid, '%d ', 1); % skip the line count in the first column
    fileNames{i} = fscanf(fid, '%s ', 1);
    i = i+1;
end
fclose (fid);

for i=startFile:endFile

    [~, name, ~] = fileparts(fileNames{i});
        
    %% Read saved run data --
    % see data field record structure in main.m and other variables stored in the mat file
    load (sprintf('Output/AU_%s.mat', name));
    load (sprintf('Output/inputSM_%s.mat', name));
    indices = [];
    for j = 1:size(automatizationunit,1)
        consecutive = [inputSM(1:(size(inputSM,1)-1),:) inputSM(2:size(inputSM,1),:)];
        index = ismember(consecutive,automatizationunit(j,5:size(automatizationunit,2)),'row');
        indices = [indices find(index,1)];
        save (sprintf('Output/AUIndex_%s.mat', name), 'indices');
    end

end