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
<<<<<<< HEAD
    index=all(bsxfun(@eq,SM.input,RM.unique_pairs(:,1:SM.N)),2);
    RM.column_location = find(index,1,'last');
=======
    tic;
    index=all(bsxfun(@eq,SM.input,RM.unique_pairs(:,1:(size(SM.input,2)))),2);
    RM.column_location = find(index,1,'last');
    RM.col_loc_toc(iteration) = toc; 
>>>>>>> 641b3a1b13c9c4deb0400edd92ecd164674ab87e
else
    RM.column_location = 0;
end

% (iteration>trN) prevents the RM from predicting on training data because it was built with this data in the Spatial Pooler training
% RM.column_location is non-zero when it finds a key in the RM.unique_pairs (this key corresponds to a first-order-sequence pair)

if RM.column_location & (iteration>trN) & (iteration<data.N)
    %% Get the next input to validate RM prediction.
    x = [];
    for  i=1:length(data.fields)
        j = data.fields(i);
        x = [x data.code{j}(data.value{j}(iteration+1),:)];
    end
    SM.inputNext = spatialPooler (x, false, displayFlag);
    
    % Compare RM prediction with next input
<<<<<<< HEAD
    RM.access = isequal(RM.unique_pairs(RM.column_location,(SM.N + 1):end), SM.inputNext);
=======
    tic;
    RM.access = isequal(RM.unique_pairs(RM.column_location,(size(SM.input,2)+1):size(RM.unique_pairs,2)), SM.inputNext);
    RM.row_loc_toc(iteration) = toc;
>>>>>>> 641b3a1b13c9c4deb0400edd92ecd164674ab87e
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
			sequenceMemory (true,learnFlag,false);
        end
        anomalyScores (iteration+1) = 0;
        SM.every_prediction(iteration+1,:) = RM.unique_pairs(RM.column_location,(SM.N + 1):end);

        %% RM
<<<<<<< HEAD
=======
        tic;
>>>>>>> 641b3a1b13c9c4deb0400edd92ecd164674ab87e
        reflex_memory ();
        RM.predict_toc = toc;
        SM.cellActivePrevious = SM.cellActive;
        SM.cellLearn(:) = 0;
        SM.cellLearn(:,SM.inputNext) = 1;
        updateSynapses ();
<<<<<<< HEAD
=======
        %RM.time(iteration+1) = rm_toc+col_loc_toc;
>>>>>>> 641b3a1b13c9c4deb0400edd92ecd164674ab87e
        RM.access = 0;
        RM.access_previous = 1; % flag to ensure propper SM-RM Sync    
        RM.column_location_prev = RM.column_location;
        RM.access_count(iteration) = 1;
    else % if RM is not accessed
        if RM.access_previous == 1
            % Prevents overriding the score calculated in the RM
            % Only used to predict next state
            sequenceMemory (false,false,true);
        else
			%% Compute anomaly score 
			% based on what was predicted as the next expected sequence memory
			% module input at last time instant.
            predictedInput = logical(sum(SM.cellPredicted));
            SM.every_prediction(iteration,:) = predictedInput';
            anomalyScores (iteration) = 1 - nnz(predictedInput & SM.input)/nnz(SM.input);

            %% Run the input through Sequence Memory (SM) module to compute the active
            % cells in SM and also the predictions for the next time instant.
            sequenceMemory (true,learnFlag,true);
			
            if reflex_memory_flag
                %% RM
                tic;
                reflex_memory ();
                RM.learn_toc(iteration) = toc;
            end
			
            %% Temporal Pooling (TP) -- remove comments below to invoke temporal pooling.
            if temporal_pooling_flag && (iteration > trN)
                % perform only after some iterations -- pooling makes sense over a period of time.
                temporalPooler (true, displayFlag);
                TP.unionSDRhistory (mod(iteration-1, size(TP.unionSDRhistory, 1))+1, :) =  TP.unionSDR;
            end
        end
        RM.access_previous = 0; % flag to ensure propper SM-RM Sync
        RM.column_location_prev = RM.column_location;
    end
else
    if RM.access_previous == 1
        % Prevents overriding the score calculated in the RM
        % Predict next state
        sequenceMemory (false,false,true);
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
        sequenceMemory (true,learnFlag,true);
        
        %% Temporal Pooling (TP) -- remove comments below to invoke temporal pooling.
        if temporal_pooling_flag && (iteration > trN)
            % perform only after some iterations -- pooling makes sense over a period of time.
            temporalPooler (true, displayFlag);
            TP.unionSDRhistory (mod(iteration-1, size(TP.unionSDRhistory, 1))+1, :) =  TP.unionSDR;
        end

        % Skips training data
        if reflex_memory_flag && (iteration > trN) && (iteration<data.N)
            %% RM
            tic;
            reflex_memory ();
            RM.learn_toc(iteration) = toc;
        end
    end
    RM.access_previous = 0; % flag to ensure propper SM-RM Sync
    RM.column_location_prev = 0;
end