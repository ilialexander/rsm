function automatizationUnit (iteration,trN)

global  SP SM TP AU data anomalyScores predictions

if AU.access
    % Increase count of <key, value> pair
    AU.Counts{1,AU.colLocation}(AU.rowLocation) = AU.Counts{1,AU.colLocation}(AU.rowLocation) + 1;
    % Update uniqueCounts for that key
    AU.uniqueCounts(AU.colLocation) = AU.uniqueCounts(AU.colLocation) + 1;
elseif AU.colLocation
    if AU.rowLocation
        % Increase count of <key, value> pair
        AU.Counts{1,AU.colLocation}(AU.rowLocation) = AU.Counts{1,AU.colLocation}(AU.rowLocation) + 1;
        % Check the key column for the value with maximum count
        [AU.maxCount,AU.rowLocation] = max(AU.Counts{1,AU.colLocation});
        % Update uniqueCounts for that key
        AU.uniqueCounts(AU.colLocation) = AU.maxCount;
        %% [ToDo: Check if the max <key, value> pair has changed before updating it]
        % Update uniquePatterns with max count
        AU.uniquePatterns(AU.colLocation,:) = [SM.input SM.inputNext];
    else
        % Adds <key, value> pair to existing key column and initializes count.
        AU.inputHistory{1,AU.colLocation} = [AU.inputHistory{1,AU.colLocation}; SM.input SM.inputNext];
        AU.Counts{1,AU.colLocation} = [AU.Counts{1,AU.colLocation}; 1];
    end
else
    % Create a new cell in AU.inputHistory and initialize the Counts
    AU.inputHistory{1,size(AU.inputHistory,2)+1} = [SM.inputPrevious SM.input];
    AU.Counts{1,size(AU.Counts,2)+1} = 1;
    % Create a new entry in AU.uniquePatterns and initialize uniqueCounts
    AU.uniquePatterns = [AU.uniquePatterns; SM.inputPrevious SM.input];
    AU.uniqueCounts = [AU.uniqueCounts; 1];
end

