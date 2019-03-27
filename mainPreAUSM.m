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

global  SP SM TP data AU anomalyScores predictions

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
    for iteration = 1:trN
        x = []; % construct the binary vector x for each measurement from the data fields
        for  i=1:length(data.fields)
            j = data.fields(i);
            x = [x data.code{j}(data.value{j}(iteration),:)];
        end
        
        % train the spatialPooler
        xSM = spatialPooler (x, true, false);
        
        %Can we reconstruct the input by inverting the process? This is
        %just for sanity check. It is NOT used for training the spatial
        %pooler
        ri = (xSM* double(SP.synapse > SP.connectPerm)) > 1;
        rError = nnz(x(1:data.nBits(1))) - nnz(ri(1:data.nBits(1)) & x(1:data.nBits(1)));
        if (rError ~= 0)
            fprintf(1, '\n (Non zero reconstruction error: %d bits) - ignore.', rError);
        end
    
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
SM.inputPrevious = zeros(SM.N, 1);
data.inputCodes = [];
data.inputSDR = [];
SP.boost = ones (SM.N, 1);
%AU.inputHistory = zeros(1,(2*SM.N));

% no boosting in spatial pooler as it is being run in a non-learning mode
% next. 


fprintf('\n Running input of length %d through sequence memory to detect anomaly...', data.N);

%% Iterate through the input data and feed through the spatial pooler, sequence memory and temporal pooler, as needed.

iteration = 1;
x = [];
automatization = 0;
automatizationunit = [];
AU.index = [];
lol = [];

load (sprintf('Output/AUIndex_%s.mat', outFile));

while iteration < (data.N + 1)
    %% Run through Spatial Pooler (SP)(without learning)    
    %x = [];
    if ~any(x)
        for  i=1:length(data.fields)
            j = data.fields(i);
            x = [x data.code{j}(data.value{j}(iteration),:)];
        end
    end
    SM.input = spatialPooler (x, false, displayFlag);
      
    %% Collects encoded events for statistical analisis to implement AU
    %inputSM(iteration,:) = SM.input;
    %save (sprintf('Output/inputSM_%s.mat', outFile),'inputSM'); 
    %%
    
    data.inputCodes = [data.inputCodes; x]; 
    data.inputSDR = [data.inputSDR; SM.input];
    
    % stores sequence of input to spatial pooler. This is used to
    % visualize the predicted vectors 
    
    %% AU
     if ismember(iteration-1,[20,294,296,491,601,603,759])
         lol = [lol; SM.inputPrevious SM.input];
         %fprintf("\nWhy is not printing\n")
     end
    
    
    if iteration < data.N
        AU.tolerance = 0;
        if ismember(iteration+1,indices)
            automatizationunit = [automatizationunit;
                                  SM.inputPrevious SM.input];
            predictedInput = logical(sum(SM.cellPredicted));

            anomalyScores (iteration) = 1 - nnz(predictedInput & SM.input)/nnz(SM.input);

            %% Run the input through Sequence Memory (SM) module to compute the active
            % cells in SM and also the predictions for the next time instant.
            sequenceMemory (learnFlag);

            %%
            SM.inputPrevious = SM.input;
            SM.cellActivePrevious = SM.cellActive;
            SM.cellLearnPrevious = SM.cellLearn; 

            iteration = iteration + 1;
            x = [];
        end
        if any(automatizationunit)
            AU.index = ismember(automatizationunit(:,1:size(SM.input,2)),SM.input,'rows');
        end
        if any(AU.index)
            %AU.index = ismember(automatizationunit(:,1:size(SM.input,2)),SM.input,'rows');
            AU.predictedInput = automatizationunit(find(AU.index,1),:);
            %^fprintf ("automatizationunit: %d \n",size(automatizationunit));
            if any(AU.predictedInput)
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
                SM.input = spatialPooler (x, false, displayFlag);

                data.inputCodes = [data.inputCodes; x]; 
                data.inputSDR = [data.inputSDR; SM.input];
                %fprintf ("automatizationunit: %d \n",size(AU.predictedInput));
                AU.anomalyScore = 1 - nnz(AU.predictedInput((size(SM.input,2)+1):size(AU.predictedInput,2)) & SM.input)/nnz(SM.input);

                if AU.anomalyScore == AU.tolerance
                    anomalyScores (iteration+1) = AU.anomalyScore;
                    automatization = automatization + 1;
                    fprintf ("Automatization Access: %d \n",automatization);
                    iteration = iteration + 2;
                    x = [];
                    SM.inputPrevious = SM.input;
                else
                    predictedInput = logical(sum(SM.cellPredicted));

                    anomalyScores (iteration) = 1 - nnz(predictedInput & SM.input)/nnz(SM.input);

                    %% Run the input through Sequence Memory (SM) module to compute the active
                    % cells in SM and also the predictions for the next time instant.
                    sequenceMemory (learnFlag);


                    %%
                    SM.inputPrevious = SM.input;
                    SM.cellActivePrevious = SM.cellActive;
                    SM.cellLearnPrevious = SM.cellLearn; 

                    iteration = iteration + 1;
                    x = [];
                end
            else
                predictedInput = logical(sum(SM.cellPredicted));

                anomalyScores (iteration) = 1 - nnz(predictedInput & SM.input)/nnz(SM.input);

                %% Run the input through Sequence Memory (SM) module to compute the active
                % cells in SM and also the predictions for the next time instant.
                sequenceMemory (learnFlag);


                %%
                SM.inputPrevious = SM.input;
                SM.cellActivePrevious = SM.cellActive;
                SM.cellLearnPrevious = SM.cellLearn; 

                iteration = iteration + 1;
                x = [];
            end
        else
            %fprintf('AU.predictedInput es el conjunto vacio');

            predictedInput = logical(sum(SM.cellPredicted));

            anomalyScores (iteration) = 1 - nnz(predictedInput & SM.input)/nnz(SM.input);

            %% Run the input through Sequence Memory (SM) module to compute the active
            % cells in SM and also the predictions for the next time instant.
            sequenceMemory (learnFlag);
            
            
            %%
            SM.inputPrevious = SM.input;
            SM.cellActivePrevious = SM.cellActive;
            SM.cellLearnPrevious = SM.cellLearn; 
            
            iteration = iteration + 1;
            x = [];
        end
    else
        %fprintf('AU.predictedInput es el conjunto vacio');

        predictedInput = logical(sum(SM.cellPredicted));

        anomalyScores (iteration) = 1 - nnz(predictedInput & SM.input)/nnz(SM.input);

        %% Run the input through Sequence Memory (SM) module to compute the active
        % cells in SM and also the predictions for the next time instant.
        sequenceMemory (learnFlag);


        %%
        SM.inputPrevious = SM.input;
        SM.cellActivePrevious = SM.cellActive;
        SM.cellLearnPrevious = SM.cellLearn; 

        iteration = iteration + 1;
        x = [];
    end
    
    %% Temporal Pooling (TP) -- remove comments below to invoke temporal pooling.
    %     if (iteration > 150)
    %        perform only after some iterations -- pooling makes sense over
    %        a period of time.
    %          (true, displayFlag);
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
    
    
   
end

%save (sprintf('Output/AU.ocurrences_%s.mat', outFile),'l');

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





