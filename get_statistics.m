clear all; clc;
startFile = 1;
endFile = 58;
purge = 0;

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
rm_col_loc_tocs = cell(endFile,1);
rm_row_loc_tocs = cell(endFile,1);
rm_predict_tocs = cell(endFile,1);
rm_learn_tocs = cell(endFile,1);
load (sprintf('Output/rsm_statistics.mat'));

for i=startFile:endFile

    [~, name, ~] = fileparts(fileNames{i});

    load (sprintf('Output/HTM_SM_%s.mat', name), 'RM');
    
    rm_access_count{i} = RM.access_count;
    rm_col_loc_tocs{i} = RM.col_loc_toc;
    rm_row_loc_tocs{i} = RM.row_loc_toc;
    rm_predict_tocs{i} = RM.predict_toc;
    rm_learn_tocs{i} = RM.learn_toc;
    for order = 1:size(rm_access_count{i},1)
        fprintf("RM Access Counts for Dataset %d for each dataset\n Order: %d, Count %d \n", i, order, rm_access_count{i}(order,2));
    end
end

rm_access_count_trials{end+1} = rm_access_count;
rm_col_loc_toc_trials{end+1} = rm_col_loc_tocs;
rm_row_loc_toc_trials{end+1} = rm_row_loc_tocs;
rm_predict_toc_trials{end+1} = rm_predict_tocs;
rm_learn_toc_trials{end+1} = rm_learn_tocs;

if endFile == 58
    save (sprintf('Output/rsm_statistics.mat'), 'rm_access_count_trials',...
        'rm_col_loc_toc_trials', 'rm_row_loc_toc_trials',...
        'rm_predict_toc_trials', 'rm_learn_toc_trials');
end

if purge == 1
    rm_access_count_trials = {};
    rm_col_loc_toc_trials = {};
    rm_row_loc_toc_trials = {};
    rm_predict_toc_trials = {};
    rm_learn_toc_trials = {};
    save (sprintf('Output/rsm_statistics.mat'), 'rm_access_count_trials',...
        'rm_col_loc_toc_trials', 'rm_row_loc_toc_trials',...
        'rm_predict_toc_trials', 'rm_learn_toc_trials');
end

exit;
%fprintf("\n\n")

%fprintf("All max amount of active synpases over all datasets: %6.0f \n", max_active_synapses);
%fprintf("Average amount of active synpases over all datasets: %6.0f \n", mean(avg_active_synapses));