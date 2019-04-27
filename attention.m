function attention (iteration,trN,learnFlag,displayFlag)

global  SP SM TP AU data anomalyScores predictions

[~,AU.colLocation] = ismember(SM.input,AU.uniquePatterns(:,1:(size(SM.input,2))),'row');
if AU.colLocation && (iteration<data.N) && (iteration>trN)
    %% Get the next input to validate AU prediction.
    % [ToDo: Will be processed through 'SPOutput']
    x = [];
    for  i=1:length(data.fields)
        j = data.fields(i);
        x = [x data.code{j}(data.value{j}(iteration+1),:)];
    end
    SM.inputNext = spatialPooler (x, false, displayFlag);
    data.inputCodes = [data.inputCodes; x]; 
    data.inputSDR = [data.inputSDR; SM.inputNext];

    % check if value exist in inputHistory
    [~,AU.rowLocation] = ismember(SM.inputNext,AU.inputHistory{1,AU.colLocation}(:,(size(SM.inputNext,2)+1):size(AU.uniquePatterns,2)),'row');
    %fprintf("\n AU.rowLocation = %d\n",AU.rowLocation);

    % Compare AU prediction with next input
    AU.access = isequal(AU.uniquePatterns(AU.colLocation,(size(SM.input,2)+1):size(AU.uniquePatterns,2)), SM.inputNext);
    if AU.access
        if anomalyScores (iteration) == 0
            % Prevents overriding the score calculated in the AU
        else
            predictedInput = logical(sum(SM.cellPredicted));
            anomalyScores (iteration) = 1 - nnz(predictedInput & SM.input)/nnz(SM.input);
        end
%           [Done: Strengthen permanences between SM.inputPrevious (synapses) and SM.input (neurons)]
%           [Done: AU.access_previous == 1 % will check if the previous iteration was through AU or HTM for proper HTM learning]
        if AU.access_previous == 1
            % Sequence memory already learned in previous iteration
        else
            markActiveStates (); % based on x and PI_1 (prediction from past cycle)
            if learnFlag
               markLearnStates ();
               updateSynapses ();
            end
        end
        anomalyScores (iteration+1) = 0;
        %% AU
        automatizationUnit (iteration,trN);
        SM.inputPrevious = SM.input;
        SM.input = SM.inputNext;
        SM.inputNext = [];
%       [Done: Strengthen permanences between SM.input (synapses) and SM.inputNext (neurons)]
        SM.cellActivePrevious = SM.cellActive;
        SM.cellLearn(:) = 0;
        SM.cellLearn(:,SM.input) = 1;
        updateSynapses();
        AU.access = 0;
        AU.access_previous = 1; % flag to ensure propper HTM-AU Sync
    else
        %% Compute anomaly score 
        % based on what was predicted as the next expected sequence memory
        % module input at last time instant.
        if AU.access_previous == 1
            % Prevents overriding the score calculated in the AU
            %% %%%%%%%% [ToDo: Compute prediction with SM.inputNext (synapses) as an input]
            % Predict next state
            markPredictiveStates ();
        else
            %% AU
            predictedInput = logical(sum(SM.cellPredicted));
            anomalyScores (iteration) = 1 - nnz(predictedInput & SM.input)/nnz(SM.input);
            automatizationUnit (iteration,trN);
            %% Run the input through Sequence Memory (SM) module to compute the active
            % cells in SM and also the predictions for the next time instant.
            sequenceMemory (learnFlag);
        end

        SM.inputPrevious = SM.input;
        SM.input = SM.inputNext;
        AU.access_previous = 0; % flag to ensure propper HTM-AU Sync
    end
else
    if AU.access_previous == 1
        % Prevents overriding the score calculated in the AU
        %% %%%%%%%% [ToDo: Compute prediction with SM.inputNext (synapses) as an input]
        % Predict next state
        markPredictiveStates ();
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
        sequenceMemory (learnFlag);

        % Skips training data
        if iteration > trN
            %% AU
            automatizationUnit (iteration,trN);
        end
    end

    SM.inputPrevious = SM.input;
    AU.access_previous = 0; % flag to ensure propper HTM-AU Sync
    SM.input = [];
end