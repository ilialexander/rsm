startFile = 1;
endFile = 2;
displayFlag = false;
createModelFlag = true;
reflex_memory_flag = true;
temporal_pooling_flag = false;
time = datetime;
% This function through the entore NAB dataset
%
% Copyright (c) 2016,  Sudeep Sarkar, University of South Florida, Tampa, USA
% This work is licensed under the Attribution-NonCommercial-ShareAlike 4.0 International License. 
% To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/4.0/
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
%
close all;
if displayFlag
    figure; h1 = gcf; 
end


%% Sequences are being done in parallel now
for i=startFile:endFile
    
    fid = fopen('fileList.txt', 'r');
    file_name = textscan(fid,'%*n %s',1,'delimiter','\n', 'headerlines',i-1);
    file_name = cell2mat(file_name{1});
    fclose (fid);
    close all;
    clear global;

    tic;
    [~, name, ~] = fileparts(file_name);

    %% Create Model
    if createModelFlag
        main  (file_name, name, displayFlag, true, 'none', reflex_memory_flag, temporal_pooling_flag);
    end
    
    %% Time to process
    sm_r_timing_dataset = toc;
    fprintf ('\nProcessing Time is: %s\n',sm_r_timing_dataset);
    save (sprintf('Output/time_SMRM_%s.mat',name),'sm_r_timing_dataset','-append');
    fprintf ('\n%d:iteration_finished_properly,%d\n',i);
end
