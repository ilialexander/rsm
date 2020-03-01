function SM = sequenceMemory (SM, RM, mark_active_flag, learnFlag, predict_flag)

    if mark_active_flag
        SM = markActiveStates (SM); % based on x and PI_1 (prediction from past cycle)
    end
    
    if learnFlag
       SM = markLearnStates (SM);
       SM = updateSynapses (SM,RM);
    end

    if predict_flag
        % Predict next state
        SM.cellPredictedPrevious = SM.cellPredicted;   
        SM = markPredictiveStates (SM);
    end
   
end

