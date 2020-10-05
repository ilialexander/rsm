function reflex_memory ()
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

if RM.access
    index=all(bsxfun(@eq,SM.inputNext,RM.input_history{1,RM.column_location}(:,1:RM.N)),2);
    RM.row_location = find(index,1,'last');
    % Increase count of <key, value> pair
    RM.input_history_counts{1,RM.column_location}(RM.row_location) = RM.input_history_counts{1,RM.column_location}(RM.row_location) + 1;
    % Update unique_pairs_counts for that key
    RM.unique_pairs_counts(RM.column_location) = RM.unique_pairs_counts(RM.column_location) + 1;
elseif RM.column_location
	% checks if value exist in 'RM.input_history'
    index=all(bsxfun(@eq,SM.inputNext,RM.input_history{1,RM.column_location}(:,1:RM.N)),2);
    RM.row_location = find(index,1,'last');
    if RM.row_location
        % Increase count of <key, value> pair
        RM.input_history_counts{1,RM.column_location}(RM.row_location) = RM.input_history_counts{1,RM.column_location}(RM.row_location) + 1;
        % Check the key column for the value with maximum count
        if RM.input_history_counts{1,RM.column_location}(RM.row_location) > RM.unique_pairs_counts(RM.column_location)
            % Update unique_pairs_counts for that key
            RM.unique_pairs_counts(RM.column_location) = RM.input_history_counts{1,RM.column_location}(RM.row_location);
            % Update unique_pairs with max count
            RM.unique_pairs(RM.column_location,:) = [SM.input SM.inputNext];
        end
    else
        % Adds <key, value> pair to existing 'key' column and initializes count.
        RM.input_history{1,RM.column_location}(end + 1,:) = SM.inputNext;
        RM.input_history_counts{1,RM.column_location}(end + 1,:) = 1;   
    end
else
    %Do Nothing
end

if ~any(RM.column_location_prev)
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