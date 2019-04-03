function mainPreAU  (inFile, outFile, displayFlag, learnFlag, learntDataFile)
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

global  SP SM TP AU data anomalyScores predictions


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
    
    xSMPrevious = [];
    %AU.inputHistory = {0};
    iteration = 1;
    %Counts = {};
    
    while iteration < trN
        x = []; % construct the binary vector x for each measurement from the data fields
        for  i=1:length(data.fields)
            j = data.fields(i);
            x = [x data.code{j}(data.value{j}(iteration),:)];
        end
        
        % train the spatialPooler
        xSM = spatialPooler (x, true, false);
        if iteration > 2
            [~,AU.colLocation] = ismember(xSMPrevious,AU.uniquePatterns(:,1:size(xSMPrevious,2)),'row');
            if any(AU.colLocation)
                [~,AU.rowLocation] = ismember(xSM,AU.inputHistory{1,AU.colLocation}(:,(size(xSM,2)+1):size(AU.uniquePatterns,2)),'row');
                if any(AU.rowLocation)
                    AU.Counts{1,AU.colLocation}(AU.rowLocation) = AU.Counts{1,AU.colLocation}(AU.rowLocation) + 1;
                else
                    AU.inputHistory{1,AU.colLocation} = [AU.inputHistory{1,AU.colLocation}; xSMPrevious xSM];
                    AU.Counts{1,AU.colLocation} = [AU.Counts{1,AU.colLocation}; 1];
                end
            else
               AU.inputHistory{1,size(AU.inputHistory,2)+1} = [xSMPrevious xSM];
               AU.Counts{1,size(AU.Counts,2)+1} = 1;
               AU.uniquePatterns = [AU.uniquePatterns; xSMPrevious xSM];
               AU.uniqueCounts = [AU.uniqueCounts; 1];
            end
        elseif iteration == 2
            AU.inputHistory{1} = [xSMPrevious xSM];
            AU.Counts{1} = 1;
            AU.uniquePatterns = [xSMPrevious xSM];
            AU.uniqueCounts = 1;
        else

        end
            
        
        %Can we reconstruct the input by inverting the process? This is
        %just for sanity check. It is NOT used for training the spatial
        %pooler
        ri = (xSM* double(SP.synapse > SP.connectPerm)) > 1;
        rError = nnz(x(1:data.nBits(1))) - nnz(ri(1:data.nBits(1)) & x(1:data.nBits(1)));
        if (rError ~= 0)
            fprintf(1, '\n (Non zero reconstruction error: %d bits) - ignore.', rError);
        end
        
        xSMPrevious = xSM;
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
data.inputCodes = [];
data.inputSDR = [];
SP.boost = ones (SM.N, 1); 
% no boosting in spatial pooler as it is being run in a non-learning mode
% next


fprintf('\n Running input of length %d through sequence memory to detect anomaly...', data.N);

%% Iterate through the input data and feed through the spatial pooler, sequence memory and temporal pooler, as needed.


time = datetime;
iteration = 1;
% x = [];
SM.input = [];
SM.inputNext = [];
automatization = 0;


%% Create Unique Patterns from array
%fprintf("\nAutomatization Access: %d",size(AU.Counts{1}))
%AU.maxCounts = max(AU.Counts{1,:});
%AU.inputHistory{1,AU.colLocation} = [AU.inputHistory{1,AU.colLocation}; xSMPrevious xSM];


while iteration < (data.N + 1)
    AU.tolerance = 0;
    %% Run through Spatial Pooler (SP)(without learning)    
    if ~any(SM.input)
        subtime = datetime;
        x = [];
        for  i=1:length(data.fields)
            j = data.fields(i);
            x = [x data.code{j}(data.value{j}(iteration),:)];
        end
        
        SM.input = spatialPooler (x, false, displayFlag);

        data.inputCodes = [data.inputCodes; x]; 
        data.inputSDR = [data.inputSDR; SM.input];

        % stores sequence of input to spatial pooler. This is used to
        % visualize the predicted vectors 
    end


    [~,AU.colLocation] = ismember(SM.input,AU.uniquePatterns(:,1:(size(SM.input,2))),'row');
    %fprintf ("\nAU.colLocation = %d]",AU.colLocation);
    if any(AU.colLocation)
        %% Compute anomaly score 
        % based on what was predicted as the next expected sequence memory
        % module input at last time instant. (Note: we did experiment with
        % defining anomaly based on reconstructed spatial pooler input
        % predicted signal, but it did not work well.
        %fprintf('AU.predictedInput es diferente de 0');
        AU.anomalyScore = 0;
        x = [];
        for  i=1:length(data.fields)
            j = data.fields(i);
            x = [x data.code{j}(data.value{j}(iteration+1),:)];
        end
        SM.inputNext = spatialPooler (x, false, displayFlag);

        data.inputCodes = [data.inputCodes; x]; 
        data.inputSDR = [data.inputSDR; SM.inputNext];

        %AU.anomalyScore = 1 - nnz(AU.uniquePatterns(AU.colLocation,(size(SM.input,2)+1):size(AU.uniquePatterns,2)) & SM.input)/nnz(SM.input);
        
        
        %if AU.anomalyScore == AU.tolerance
        if AU.uniquePatterns(AU.colLocation,(size(SM.input,2)+1):size(AU.uniquePatterns,2)) == SM.inputNext
            anomalyScores (iteration+1) = 0;
            automatization = automatization + 1;
            iteration = iteration + 1;
            SM.inputPrevious = SM.input;
            SM.input = SM.inputNext;

        else
            [~,AU.rowLocation] = ismember(SM.input,AU.inputHistory{1,AU.colLocation}(:,(size(SM.input,2)+1):size(AU.uniquePatterns,2)),'row');
            if any(AU.rowLocation)
                AU.Counts{1,AU.colLocation}(AU.rowLocation) = AU.Counts{1,AU.colLocation}(AU.rowLocation) + 1;
            else
                AU.inputHistory{1,AU.colLocation} = [AU.inputHistory{1,AU.colLocation}; SM.input SM.inputNext];
                AU.Counts{1,AU.colLocation} = [AU.Counts{1,AU.colLocation}; 1];
            end
            predictedInput = logical(sum(SM.cellPredicted));

            anomalyScores (iteration) = 1 - nnz(predictedInput & SM.input)/nnz(SM.input);

            %% Run the input through Sequence Memory (SM) module to compute the active
            % cells in SM and also the predictions for the next time instant.
            sequenceMemory (learnFlag);


            %%
            SM.inputPrevious = SM.input;
            SM.input = SM.inputNext;
            SM.cellActivePrevious = SM.cellActive;
            SM.cellLearnPrevious = SM.cellLearn;
            %SM.input = [];
            %x = [];

            iteration = iteration + 1;
        end
    else
        AU.inputHistory{1,size(AU.inputHistory,2)+1} = [xSMPrevious xSM];
        AU.Counts{1,size(AU.Counts,2)+1} = 1;
        AU.uniquePatterns = [AU.uniquePatterns; xSMPrevious xSM];
        AU.uniqueCounts = [AU.uniqueCounts; 1];

        predictedInput = logical(sum(SM.cellPredicted));

        anomalyScores (iteration) = 1 - nnz(predictedInput & SM.input)/nnz(SM.input);

        %% Run the input through Sequence Memory (SM) module to compute the active
        % cells in SM and also the predictions for the next time instant.
        sequenceMemory (learnFlag);


        %%
        SM.inputPrevious = SM.input;
        SM.cellActivePrevious = SM.cellActive;
        SM.cellLearnPrevious = SM.cellLearn;
        SM.input = [];
        %x = [];

        iteration = iteration + 1;
    end

    %% Temporal Pooling (TP) -- remove comments below to invoke temporal pooling.
    %     if (iteration > 150)
    %        perform only after some iterations -- pooling makes sense over
    %        a period of time.
    %         temporalPooler (true, displayFlag);
    %         TP.unionSDRhistory (mod(iteration-1, size(TP.unionSDRhistory, 1))+1, :) =  TP.unionSDR;
    %
    %     end;
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
    
    
    %%
    SM.inputPrevious = SM.input;
    SM.cellActivePrevious = SM.cellActive;
    SM.cellLearnPrevious = SM.cellLearn;
    
end
fprintf ('\nProcessing Time is: %s\n',diff([time datetime]));
fprintf ("\nAutomatization Access: %d",automatization);
fprintf('\n Running input of length %d through sequence memory to detect anomaly...done', data.N);

% Uncomment this if you want to visualize Temporal Pooler output
% imagesc(TP.unionSDRhistory); pause (0.00001);
% pause (0.0000000000001);

%% Save data
if learnFlag
    save (sprintf('Output/HTM_SM_%s.mat', outFile), ...
        'SM', 'SP', 'data', 'anomalyScores', 'predictions',...
        '-v7.3');
else
    save (sprintf('Output/HTM_SM_%s_L.mat', outFile), ...
        'SM', 'SP', 'data', 'anomalyScores', 'predictions',...
        '-v7.3');
end





