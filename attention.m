function attention (iteration,trN,learnFlag,displayFlag, automatization_flag, temporal_pooling_flag)
%% This function is supervisor/control unit between Sequence Memory, Automatization and Temporal Pooler.
% It always checks with the Automatization Unit (AU) before computing through the Sequence Memory
% iteration: is the current instance of data that is being processed
% trN: is the amount of data points selected for training
% learnFlag: invokes the learning of the Sequence Memory 
% displayFlag: shows animation of cells (turning on, bursting and predicting)
% automatization_flag: invokes the Automatization Unit
% temporal_pooling_flag: invokes the Temporal Pool

% Note: The Temporal pooler is not fully implemented if invoked with Automatization

%% Copyright (c) 2016,  Sudeep Sarkar, University of South Florida, Tampa, USA
% This work is licensed under the Attribution-NonCommercial-ShareAlike 4.0 International License.
% To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/4.0/
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
%


global SM TP AU data anomalyScores

% Invokes AU
if automatization_flag
    [~,AU.column_location] = ismember(SM.input,AU.unique_pairs(:,1:(size(SM.input,2))),'row');
else
    AU.column_location = 0;
end

% (iteration>trN) prevents the AU from predicting on training data because it was built with this data in the Spatial Pooler training
% AU.column_location is non-zero when it finds a key in the AU.unique_pairs (this key corresponds to a first-order-sequence pair)

if AU.column_location && (iteration>trN) && (iteration<data.N)
    %% Get the next input to validate AU prediction.
    x = [];
    for  i=1:length(data.fields)
        j = data.fields(i);
        x = [x data.code{j}(data.value{j}(iteration+1),:)];
    end
    SM.inputNext = spatialPooler (x, false, displayFlag);
    data.inputCodes = [data.inputCodes; x]; 
    data.inputSDR = [data.inputSDR; SM.inputNext];

    % check if value exist in input_history
	% AU.row_location is used in the automatizationUnit
    [~,AU.row_location] = ismember(SM.inputNext,AU.input_history{1,AU.column_location}(:,(size(SM.inputNext,2)+1):size(AU.unique_pairs,2)),'row');

    % Compare AU prediction with next input
    AU.access = isequal(AU.unique_pairs(AU.column_location,(size(SM.input,2)+1):size(AU.unique_pairs,2)), SM.inputNext);
    if AU.access
        if anomalyScores (iteration) == 0
            % Prevents overriding the score calculated in the AU
        else
            predictedInput = logical(sum(SM.cellPredicted));
            anomalyScores (iteration) = 1 - nnz(predictedInput & SM.input)/nnz(SM.input);
        end

        if AU.access_previous == 1
            % Sequence memory already learned in previous iteration
        else
			sequenceMemory (true,learnFlag,false);
        end
        anomalyScores (iteration+1) = 0;
        %% AU
        automatizationUnit ();
        SM.cellActivePrevious = SM.cellActive;
        SM.cellLearn(:) = 0;
        SM.cellLearn(:,SM.inputNext) = 1;
        updateSynapses();
        AU.access = 0;
        AU.access_previous = 1; % flag to ensure propper HTM-AU Sync
    else % if AU is not accessed
        if AU.access_previous == 1
            % Prevents overriding the score calculated in the AU
            % Only used to predict next state
            sequenceMemory (false,false,true);
        else
			%% Compute anomaly score 
			% based on what was predicted as the next expected sequence memory
			% module input at last time instant.
            predictedInput = logical(sum(SM.cellPredicted));
            anomalyScores (iteration) = 1 - nnz(predictedInput & SM.input)/nnz(SM.input);

            %% Run the input through Sequence Memory (SM) module to compute the active
            % cells in SM and also the predictions for the next time instant.
            sequenceMemory (true,learnFlag,true);
			
            if automatization_flag
                %% AU
                automatizationUnit ();
            end
			
            %% Temporal Pooling (TP) -- remove comments below to invoke temporal pooling.
            if temporal_pooling_flag && (iteration > trN)
                % perform only after some iterations -- pooling makes sense over a period of time.
                temporalPooler (true, displayFlag);
                TP.unionSDRhistory (mod(iteration-1, size(TP.unionSDRhistory, 1))+1, :) =  TP.unionSDR;
            end
        end
        AU.access_previous = 0; % flag to ensure propper HTM-AU Sync
    end
else
    if AU.access_previous == 1
        % Prevents overriding the score calculated in the AU
        % Predict next state
        sequenceMemory (false,false,true);
    else
        %% Compute anomaly score 
        % based on what was predicted as the next expected sequence memory
        % module input at last time instant.
        if anomalyScores (iteration) == 0
            % Prevents overriding the score calculated in the AU
        else
            predictedInput = logical(sum(SM.cellPredicted));
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
        if automatization_flag && (iteration > trN) && (iteration<data.N)
            %% AU
            automatizationUnit ();
        end
    end
    AU.access_previous = 0; % flag to ensure propper HTM-AU Sync
end