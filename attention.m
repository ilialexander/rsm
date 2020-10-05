function attention (iteration,trN,learnFlag,displayFlag, reflex_memory_flag, temporal_pooling_flag)
%% This function is supervisor/control unit between Sequence Memory, Reflex Memory and Temporal Pooler.
% It always checks with the Reflex Memory (RM) before computing through the Sequence Memory
% iteration: is the current instance of data that is being processed
% trN: is the amount of data points selected for training
% learnFlag: invokes the learning of the Sequence Memory 
% displayFlag: shows animation of cells (turning on, bursting and predicting)
% reflex_memory_flag: invokes the Reflex Memory
% temporal_pooling_flag: invokes the Temporal Pool

% Note: The Temporal pooler is not fully implemented if invoked with Reflex Memory

%% Copyright (c) 2016,  Sudeep Sarkar, University of South Florida, Tampa, USA
% This work is licensed under the Attribution-NonCommercial-ShareAlike 4.0 International License.
% To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/4.0/
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
%

global SM TP RM data anomalyScores

% Invokes RM
if reflex_memory_flag
    tic;
    index=all(bsxfun(@eq,SM.input,RM.unique_pairs(:,1:SM.N)),2);
    RM.key_pointer = find(index,1,'last');
    RM.col_loc_toc(iteration) = toc; 
else
    RM.key_pointer = 0;
end

% (iteration>trN) prevents the RM from predicting on training data because it was built with this data in the Spatial Pooler training
% RM.key_pointer is non-zero when it finds a key in the RM.unique_pairs (this key corresponds to a first-order-sequence pair)

if RM.key_pointer & (iteration>trN) & (iteration<data.N)
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
    tic;
    RM.access = isequal(RM.unique_pairs(RM.key_pointer,(SM.N + 1):end), SM.inputNext);
    RM.row_loc_toc(iteration) = toc;
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
            RM.temporal_order = RM.temporal_order + 1;
            rm_access_count_index = find(RM.access_count (:, 1) == RM.temporal_order);
            if rm_access_count_index
                RM.access_count(rm_access_count_index,2) = RM.access_count(rm_access_count_index,2) + 1;
            else
                RM.access_count = [RM.access_count; RM.temporal_order 1];
            end
        else
			sequenceMemory (true,learnFlag,false);
            RM.temporal_order = 1;
        end
        anomalyScores (iteration+1) = 0;
        SM.every_prediction(iteration+1,:) = RM.unique_pairs(RM.key_pointer,(SM.N + 1):end);

        %% RM
        tic;
        reflex_memory(iteration, trN, reflex_memory_flag);
        RM.predict_toc = toc;
        SM.cellActivePrevious = SM.cellActive;
        SM.cellLearn(:) = 0;
        SM.cellLearn(:,SM.inputNext) = 1;
        updateSynapses ();
        RM.access = 0;
        RM.access_previous = 1; % flag to ensure propper SM-RM Sync    
        RM.key_pointer_prev = RM.key_pointer;
        RM.access_count(1,2) = RM.access_count(1,2) +1;
    else % if RM is not accessed
        pre_sm(iteration, trN, learnFlag, temporal_pooling_flag, reflex_memory_flag);
    end
else
    pre_sm(iteration, trN, learnFlag, temporal_pooling_flag, reflex_memory_flag);
end
