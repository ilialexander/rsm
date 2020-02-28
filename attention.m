function attention (iteration,trN,learnFlag,displayFlag, reflex_memory_flag, temporal_pooling_flag)
%% This function is supervisor/control unit between Sequence Memory, Reflex Memory and Temporal Pooler.
% It always checks with the Reflex Memory (RM) before computing through the Sequence Memory
% iteration: is the current instance of data that is being processed
% trN: is the amount of data points selected for training
% learnFlag: invokes the learning of the Sequence Memory 
% displayFlag: shows animation of cells (turning on, bursting and predicting)
% reflex_memory_flag: invokes the Reflex Memory
% temporal_pooling_flag: invokes the Temporal Pool

% Note: The Temporal pooler is not fully implemented if invoked with the
% Reflex Memory

%% Copyright (c) 2016,  Sudeep Sarkar, University of South Florida, Tampa, USA
% This work is licensed under the Attribution-NonCommercial-ShareAlike 4.0 International License.
% To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/4.0/
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
%


global SM TP RM data anomalyScores

% Invokes RM

% time_rm = datetime;

if reflex_memory_flag
    %tic;
    RM.col_loc_index=all(bsxfun(@eq,SM.input,RM.unique_pairs(:,1:(size(SM.input,2)))),2);
    %col_loc_toc = toc; 
else
    RM.col_loc_index = 0;
end

% (iteration>trN) prevents the RM from predicting on training data because it was built with this data in the Spatial Pooler training
% any(RM.col_loc_index) is non-zero when it holds a key in the RM.unique_pairs (this key corresponds to a first-order-sequence pair)

if any(RM.col_loc_index) & (iteration>trN) & (iteration<data.N)
    %% Get the next input to validate RM prediction.
    x = [];
    for  i=1:length(data.fields)
        j = data.fields(i);
        x = [x data.code{j}(data.value{j}(iteration+1),:)];
    end
    SM.inputNext = spatialPooler (x, false, displayFlag);
    data.inputCodes = [data.inputCodes; x]; 
    data.inputSDR = [data.inputSDR; SM.inputNext];
    
    % Compare RM prediction with next input
    RM.access = isequal(RM.unique_pairs(RM.col_loc_index,(size(SM.input,2)+1):size(RM.unique_pairs,2)), SM.inputNext);
    if RM.access
        if anomalyScores (iteration) == 0
            % Prevents overriding the score calculated in the RM
        else
            predictedInput = logical(sum(SM.cellPredicted));
            SM.every_prediction(iteration,:) = predictedInput;
            anomalyScores (iteration) = 1 - nnz(predictedInput & SM.input)/nnz(SM.input);
        end

        if RM.access_previous == 1
            % Sequence memory already learned in previous iteration
        else
			SM = sequenceMemory (SM, RM, true,learnFlag,false);
        end
        anomalyScores (iteration+1) = 0;
        SM.every_prediction(iteration+1,:) = RM.unique_pairs(RM.col_loc_index,(size(SM.input,2)+1):size(RM.unique_pairs,2));

        %% RM
        %tic;
        reflex_memory (SM,RM);
        SM.cellActivePrevious = SM.cellActive;
        SM.cellLearn(:) = 0;
        SM.cellLearn(:,SM.inputNext) = 1;
        SM = updateSynapses (SM,RM);
        %rm_toc = toc;
        %RM.time(iteration+1) = rm_toc+col_loc_toc;
        RM.access = 0;
        RM.access_previous = 1; % flag to ensure propper HTM-RM Sync        
    else % if RM is not accessed
        if RM.access_previous == 1
            % Prevents overriding the score calculated in the RM
            % Only used to predict next state
            SM = sequenceMemory (SM, RM, false,false,true);
        else
			%% Compute anomaly score 
			% based on what was predicted as the next expected sequence memory
			% module input at last time instant.
            predictedInput = logical(sum(SM.cellPredicted));
            SM.every_prediction(iteration,:) = predictedInput';
            anomalyScores (iteration) = 1 - nnz(predictedInput & SM.input)/nnz(SM.input);

            %% Run the input through Sequence Memory (SM) module to compute the active
            % cells in SM and also the predictions for the next time instant.
            %tic;
            SM = sequenceMemory (SM, RM, true,learnFlag,true);
            %RM.time(iteration) = toc;
			
            if reflex_memory_flag
                %% RM
                reflex_memory (SM,RM);
            end
			
            %% Temporal Pooling (TP) -- remove comments below to invoke temporal pooling.
            if temporal_pooling_flag && (iteration > trN)
                % perform only after some iterations -- pooling makes sense over a period of time.
                temporalPooler (true, displayFlag);
                TP.unionSDRhistory (mod(iteration-1, size(TP.unionSDRhistory, 1))+1, :) =  TP.unionSDR;
            end
        end
        RM.access_previous = 0; % flag to ensure propper HTM-RM Sync
    end
else
    if RM.access_previous == 1
        % Prevents overriding the score calculated in the RM
        % Predict next state
        SM = sequenceMemory (SM, RM, false,false,true);
    else
        %% Compute anomaly score 
        % based on what was predicted as the next expected sequence memory
        % module input at last time instant.
        if anomalyScores (iteration) == 0
            % Prevents overriding the score calculated in the RM
        else
            predictedInput = logical(sum(SM.cellPredicted));
            SM.every_prediction(iteration,:) = predictedInput';
            anomalyScores (iteration) = 1 - nnz(predictedInput & SM.input)/nnz(SM.input);
        end

        %% Run the input through Sequence Memory (SM) module to compute the active
        % cells in SM and also the predictions for the next time instant.
        %tic;
        SM = sequenceMemory (SM, RM, true,learnFlag,true);
        %RM.time(iteration) = toc;

        
        %% Temporal Pooling (TP) -- remove comments below to invoke temporal pooling.
        if temporal_pooling_flag && (iteration > trN)
            % perform only after some iterations -- pooling makes sense over a period of time.
            temporalPooler (true, displayFlag);
            TP.unionSDRhistory (mod(iteration-1, size(TP.unionSDRhistory, 1))+1, :) =  TP.unionSDR;
        end

        % Skips training data
        if reflex_memory_flag && (iteration > trN) && (iteration<data.N)
            %% RM
            reflex_memory (SM,RM);
        end
    end
    RM.access_previous = 0; % flag to ensure propper HTM-RM Sync
end