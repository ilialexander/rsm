function sequenceMemory (mark_active_flag, learnFlag, predict_flag)

global  SM 
    if mark_active_flag
        markActiveStates (); % based on x and PI_1 (prediction from past cycle)
    end
    
    if learnFlag
       markLearnStates ();
       updateSynapses ();
    end

    if predict_flag
        % Predict next state
        SM.cellPredictedPrevious = SM.cellPredicted;   
        markPredictiveStates ();
    end
   
end

