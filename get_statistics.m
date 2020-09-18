clear all; clc;
startFile = 1;
endFile = 1;
fid = fopen('fileList.txt', 'r');
i = 1;
while ~feof(fid)
    fscanf(fid, '%d ', 1); % skip the line count in the first column
    fileNames{i} = fscanf(fid, '%s ', 1);
    i = i+1;
end
fclose (fid);
%fprintf(1, '\n %d files to process in total', i);
close all;


rm_access_count = cell(endFile,1);

for i=startFile:endFile

    [~, name, ~] = fileparts(fileNames{i});

    load (sprintf('Output/HTM_SM_%s.mat', name), 'RM');
    
    rm_access_count{i} = RM.access_count;
    for order = 1:size(rm_access_count{i},1)
        fprintf("RM Access Counts for Dataset %d for each dataset\n Order: %d, Count %d \n", i, order, rm_access_count{i}(order,2));
    end
end

%fprintf("\n\n")

%fprintf("All max amount of active synpases over all datasets: %6.0f \n", max_active_synapses);
%fprintf("Average amount of active synpases over all datasets: %6.0f \n", mean(avg_active_synapses));