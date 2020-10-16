function pre_sm(iteration, trN, learnFlag, temporal_pooling_flag, reflex_memory_flag)

global SM RM anomalyScores data

if RM.access_previous
    % Prevents overriding the score calculated in the RM
    % Only used to predict next state
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
end

if RM.key_pointer & (iteration>trN) & (iteration<data.N)
    if ~RM.access_previous && reflex_memory_flag
        %% RM
        reflex_memory(iteration, trN, reflex_memory_flag);
    end
    RM.key_pointer_prev = RM.key_pointer;
else
    % Skips training data
    if ~RM.access_previous & reflex_memory_flag & (iteration > trN) & (iteration<data.N)
        %% RM
        reflex_memory(iteration, trN, reflex_memory_flag);
    end
    RM.key_pointer_prev = 0;
end

RM.access_previous = 0; % flag to ensure propper SM-RM Sync