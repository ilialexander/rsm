function reflex_memory (iteration, trN, reflex_memory_flag)
% This function keeps a full history of all the inputs organized as first-order-sequence <key,value> pairs. Keeping a tallie of the frequency of each pair in 'RM.input_history_counts'.
% Unique first-order-sequence <key,value> pairs are also saved in a separate array 'RM.unique_pairs' and updated with the maximum frequency pairs under the respective 'key'.
% The maximum frequency count is also stored per each 'key' in 'RM.unique_pairs_counts'

%% Copyright (c) 2016,  Sudeep Sarkar, University of South Florida, Tampa, USA
% This work is licensed under the Attribution-NonCommercial-ShareAlike 4.0 International License.
% To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/4.0/
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
%

global SM RM

if iteration < trN
    if reflex_memory_flag && (iteration > 2)
        index=all(bsxfun(@eq,SM.inputPrevious,RM.unique_pairs(:,1:SM.N)),2);
        RM.key_pointer = find(index,1,'last');
        if RM.key_pointer
            index=all(bsxfun(@eq,SM.input,RM.input_history{1,RM.key_pointer}(:,1:SM.N)),2);
            RM.value_pointer = find(index,1,'last');
            if RM.value_pointer
                % Increase count of existing <key, value> pair
                RM.input_history_counts{1,RM.key_pointer}(RM.value_pointer) = RM.input_history_counts{1,RM.key_pointer}(RM.value_pointer) + 1;
                % Check the key column for the value with maximum count
                if RM.input_history_counts{1,RM.key_pointer}(RM.value_pointer) > RM.unique_pairs_counts(RM.key_pointer)
                    % Update unique_pairs_counts for that key
                    RM.unique_pairs_counts(RM.key_pointer) = RM.input_history_counts{1,RM.key_pointer}(RM.value_pointer);
                    % Update unique_pairs with max count
                    RM.unique_pairs(RM.key_pointer,:) = [SM.inputPrevious SM.input];
                end
            else
                % Add value and initialize count (1) to existing key
                RM.input_history{1,RM.key_pointer}(end + 1,:) = SM.input;
                RM.input_history_counts{1,RM.key_pointer}(end + 1,:) = 1;
            end
        else
           % Add new key and value to input_history and unique_pairs
           RM.input_history{1,end + 1} = SM.input;
           RM.unique_pairs(end + 1,:) = [SM.inputPrevious SM.input];
           % Initialize counts
           RM.input_history_counts{1,end + 1} = 1;
           RM.unique_pairs_counts(end + 1) = 1;
        end
    elseif reflex_memory_flag && iteration == 2
        % Initialize input_history, unique_pairs and counts
        RM.input_history{1} = SM.input;
        RM.unique_pairs = [SM.inputPrevious SM.input];
        RM.input_history_counts{1} = 1;
        RM.unique_pairs_counts = 1;
    end
else
    if RM.access
        index=all(bsxfun(@eq,SM.inputNext,RM.input_history{1,RM.key_pointer}(:,1:RM.N)),2);
        RM.value_pointer = find(index,1,'last');
        % Increase count of <key, value> pair
        RM.input_history_counts{1,RM.key_pointer}(RM.value_pointer) = RM.input_history_counts{1,RM.key_pointer}(RM.value_pointer) + 1;
        % Update unique_pairs_counts for that key
        RM.unique_pairs_counts(RM.key_pointer) = RM.unique_pairs_counts(RM.key_pointer) + 1;
    elseif RM.key_pointer
        % checks if value exist in 'RM.input_history'
        index=all(bsxfun(@eq,SM.inputNext,RM.input_history{1,RM.key_pointer}(:,1:RM.N)),2);
        RM.value_pointer = find(index,1,'last');
        if RM.value_pointer
            % Increase count of <key, value> pair
            RM.input_history_counts{1,RM.key_pointer}(RM.value_pointer) = RM.input_history_counts{1,RM.key_pointer}(RM.value_pointer) + 1;
            % Check the key column for the value with maximum count
            if RM.input_history_counts{1,RM.key_pointer}(RM.value_pointer) > RM.unique_pairs_counts(RM.key_pointer)
                % Update unique_pairs_counts for that key
                RM.unique_pairs_counts(RM.key_pointer) = RM.input_history_counts{1,RM.key_pointer}(RM.value_pointer);
                % Update unique_pairs with max count
                RM.unique_pairs(RM.key_pointer,:) = [SM.input SM.inputNext];
            end
        else
            % Adds <key, value> pair to existing 'key' column and initializes count.
            RM.input_history{1,RM.key_pointer}(end + 1,:) = SM.inputNext;
            RM.input_history_counts{1,RM.key_pointer}(end + 1,:) = 1;   
        end
    end

    if ~any(RM.key_pointer_prev)
        index=all(bsxfun(@eq,SM.inputPrevious,RM.unique_pairs(:,1:RM.N)),2);
        old_column_location = find(index,1,'last');
        if old_column_location
            % Adds <key, value> pair to existing 'key' column and initializes count.
            RM.input_history{1,old_column_location}(end + 1,:) = SM.input;
            RM.input_history_counts{1,old_column_location}(end + 1,:) = 1; 
        else
            % Create a new cell in RM.input_history and initialize the Counts
            RM.input_history{1,end + 1} = SM.input;
            RM.input_history_counts{1,end + 1} = 1;
            % Create a new entry in RM.unique_pairs and initialize unique_pairs_counts
            RM.unique_pairs(end + 1,:) = [SM.inputPrevious SM.input];
            RM.unique_pairs_counts(end + 1) = 1;
        end
    end
end