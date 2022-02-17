function main (inFile, outFile, displayFlag, learnFlag, learntDataFile, reflex_memory_flag, temporal_pooling_flag)
% This is the main function that (i) sets up the parameters, (ii)
% initializes the spatial pooler, and (iii) iterates through the data and
% feed it through the spatial pooler and temporal memory modules.
%
% We follow the implementation that is sketched out at
%http://numenta.com/assets/pdf/biological-and-machine-intelligence/0.4/BaMI-Temporal-Memory.pdf
%
% Not all aspects of NUPIC descrived in the link below are implemented.
% http://chetansurpur.com/slides/2014/5/4/cla-in-nupic.html#42
%
% Parameters follow the ones specified at
%https://github.com/numenta/nupic/blob/master/src/nupic/frameworks/opf/common_models/anomaly_params_random_encoder/best_single_metric_anomaly_params_tm_cpp.json
%
%% Copyright (c) 2016,  Sudeep Sarkar, University of South Florida, Tampa, USA
% This work is licensed under the Attribution-NonCommercial-ShareAlike 4.0 International License. 
% To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/4.0/
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
%
% on https://github.com/SudeepSarkar/matlabHTM

global  SP SM TP RM data anomalyScores predictions

if learnFlag
  %% Encode Input into Binary Semantic Representation 

   SP.width = 21; %21; % number of bits that are one for each state in the input.
   data = encoderNAB (inFile, SP.width);

   %% initialize parameters and data structures for spatial pooler (SP), 
   % sequence memory (SM), and temporal pooler (TP). 
   initialize;
    
    %% Learning mode for Spatial Pooler
    % We train the spatial pooler in a separate step from sequence memory
    fprintf(1, '\n Learning sparse distributed representations using spatial pooling...');
    trN = min (750, round(0.15*data.N));
    % use the first 15 percent of the data (upto a maximum of 750) samples for training the spatial pooler. 
    
    SM.inputPrevious = [];
    RM.access = [];
    iteration = 1;
    while iteration < trN
        % [ToDo: Move this to a function called 'SPOutput']
        x = []; % construct the binary vector x for each measurement from the data fields
        for  i=1:length(data.fields)
            j = data.fields(i);
            x = [x data.code{j}(data.value{j}(iteration),:)];
        end
        
        % train the spatialPooler
        SM.input = spatialPooler (x, true, false);

        % train the Reflex Memory (RM)
        reflex_memory(iteration, trN, reflex_memory_flag);
        
        %Can we reconstruct the input by inverting the process? This is
        %just for sanity check. It is NOT used for training the spatial
        %pooler
        ri = (SM.input* double(SP.synapse > SP.connectPerm)) > 1;
        rError = nnz(x(1:data.nBits(1))) - nnz(ri(1:data.nBits(1)) & x(1:data.nBits(1)));
        if (rError ~= 0)
            fprintf(1, '\n (Non zero reconstruction error: %d bits) - ignore.', rError);
        end
        
        SM.inputPrevious = SM.input;
        iteration = iteration + 1;
    end
    fprintf(1, '\n Learning sparse distributed representations using spatial pooling...done.');

%% already learnt spatial pooler and sequence memory is present in learntDataFile
else
    load (learntDataFile);
end

% Initialize plot areas
close all;
if displayFlag
   % h1 = figure; set(h1, 'Position', [10, 10000, 700, 1000]);
   % h2 = figure; set(h2, 'Position', [1000, 10000, 700, 1000]);
    
   h = figure; set(h, 'Position', [10, 10000, 1400, 1000]);
   subplot(3,2,1);
   
    
end


%% Setup arrays
predictions = zeros(3, data.N); % initialize array allocaton -- faster on matlab
SM.inputPrevious = zeros(1,SM.N);
SP.boost = ones (SM.N, 1); 
% no boosting in spatial pooler as it is being run in a non-learning mode
% next


fprintf('\n Running input of length %d through attention to detect anomaly...', data.N);

%% Iterate through the input data and feed through the spatial pooler, sequence memory and temporal pooler, as needed.
iteration = 1;
SM.input = [];
SM.inputNext = [];
anomalyScores = ones(1,data.N);
data.inputCodes = [];
data.inputSDR = [];
RM.access_previous = 0;
RM.access = [];
sm_r_time_notrn_starts = tic;
RM.key_time = zeros(1,data.N);
RM.value_time = zeros(1,data.N);

while iteration < (data.N + 1)
    %% Run through Spatial Pooler (SP)(without learning)    
    if ~any(SM.input)
        %% [ToDo: Will be processed through 'SPOutput' function]
        %% [ToDo: optimize processing the SM.input by eliminating the for loop]
        x = [];
        for  i=1:length(data.fields)
            j = data.fields(i);
            x = [x data.code{j}(data.value{j}(iteration),:)];
        end
        
        SM.input = spatialPooler (x, false, displayFlag);
        data.inputCodes = [data.inputCodes; x]; 
        data.inputSDR = [data.inputSDR; SM.inputNext];

        % stores sequence of input to spatial pooler. This is used to
        % visualize the predicted vectors 
    end

    % Check for the key
    attention (iteration, trN, learnFlag, displayFlag, reflex_memory_flag, temporal_pooling_flag);
    
    %% This part of the code is just for display of variables and plots/figures    
    if (displayFlag)
        
        if (iteration > 2)
            %figure(h2);
            subplot(3,2,[2,4,6]);
            
            displayCellAnimation;
            %figure(h1);
            visualizeHTM (iteration);
        end
        subplot(3,2,[2,4,6]); hold on;
        text(-0.5, -0.08, sprintf('SM.totalDendrites: %d, SM.totalSynapses: %d', ...
            SM.totalDendrites, SM.totalSynapses), 'fontsize', 16);
        hold off;
        pause (0.00001);
    else
        if (rem (iteration, 100) == 0) % display every 100 iterations
        fprintf(1, '\n Fraction done: %3.2f, SM.totalDendrites: %d, SM.totalSynapses: %d', ...
            iteration/data.N, SM.totalDendrites, SM.totalSynapses);
        end
    end
    
    
    SM.inputPrevious = SM.input;
    SM.input = SM.inputNext;
    SM.inputNext = [];
    SM.cellActivePrevious = SM.cellActive;
    SM.cellLearnPrevious = SM.cellLearn;
    iteration = iteration + 1;
end

key_time = RM.key_time;
value_time = RM.value_time;
sm_r_time_notrn = toc(sm_r_time_notrn_starts);
fprintf ('\nThe processing Time without trainig is: %s\n',sm_r_time_notrn);
save (sprintf('Output/time_SMRM_%s.mat',inFile(strfind(inFile,'/')+1:strfind(inFile,'.')-1)),'sm_r_time_notrn',...
    'key_time','value_time');

fprintf('\n Running input of length %d through sequence memory to detect anomaly...done', data.N);

% Uncomment this if you want to visualize Temporal Pooler output
% imagesc(TP.unionSDRhistory); pause (0.00001);
% pause (0.0000000000001);

%% Save data
if learnFlag
    save (sprintf('Output/HTM_SM_%s.mat', outFile), ...
        'SM', 'SP', 'RM', 'data', 'anomalyScores', 'predictions',...
        '-v7.3');
else
    save (sprintf('Output/HTM_SM_%s_L.mat', outFile), ...
        'SM', 'SP', 'data', 'anomalyScores', 'predictions',...
        '-v7.3');
end
