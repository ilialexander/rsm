function RM = reflex_memory (SM,RM)
% This function keeps a full history of all the inputs organized as first-order-sequence <key,value> pairs. Keeping a tallie of the frequency of each pair in 'AU.input_history_counts'.
% Unique first-order-sequence <key,value> pairs are also saved in a separate array 'AU.unique_pairs' and updated with the maximum frequency pairs under the respective 'key'.
% The maximum frequency count is also stored per each 'key' in 'AU.unique_pairs_counts'


%% Copyright (c) 2016,  Sudeep Sarkar, University of South Florida, Tampa, USA
% This work is licensed under the Attribution-NonCommercial-ShareAlike 4.0 International License.
% To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/4.0/
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
%

if RM.access
    RM.row_loc_index=all(bsxfun(@eq,SM.inputNext,RM.input_history{1,RM.col_loc_index}(:,(size(SM.inputNext,2)+1):size(RM.unique_pairs,2))),2);
    % Increase count of <key, value> pair
    RM.input_history_counts{1,RM.col_loc_index}(RM.row_loc_index) = RM.input_history_counts{1,RM.col_loc_index}(RM.row_loc_index) + 1;
    % Update unique_pairs_counts for that key
    RM.unique_pairs_counts(RM.col_loc_index) = RM.unique_pairs_counts(RM.col_loc_index) + 1;
elseif RM.col_loc_index
	% checks if value exist in 'RM.input_history'
    RM.row_loc_index=all(bsxfun(@eq,SM.inputNext,RM.input_history{1,RM.col_loc_index}(:,(size(SM.inputNext,2)+1):size(RM.unique_pairs,2))),2);
    if any(RM.row_loc_index)
        % Increase count of <key, value> pair
        RM.input_history_counts{1,RM.col_loc_index}(RM.row_loc_index) = RM.input_history_counts{1,RM.col_loc_index}(RM.row_loc_index) + 1;
        % Check the key column for the value with maximum count
        if RM.input_history_counts{1,RM.col_loc_index}(RM.row_loc_index) > RM.unique_pairs_counts(RM.col_loc_index)
            % Update unique_pairs_counts for that key
            RM.unique_pairs_counts(RM.col_loc_index) = RM.input_history_counts{1,RM.col_loc_index}(RM.row_loc_index);
            % Update unique_pairs with max count
            RM.unique_pairs(RM.col_loc_index,:) = [SM.input SM.inputNext];
        end
    else
        % Adds <key, value> pair to existing 'key' column and initializes count.
        RM.input_history{1,RM.col_loc_index} = [RM.input_history{1,RM.row_loc_index}; SM.input SM.inputNext];
        RM.input_history_counts{1,RM.col_loc_index} = [RM.input_history_counts{1,RM.col_loc_index}; 1];
    end
else
    % Create a new cell in RM.input_history and initialize the Counts
    RM.input_history{1,size(RM.input_history,2)+1} = [SM.inputPrevious SM.input];
    RM.input_history_counts{1,size(RM.input_history_counts,2)+1} = 1;
    % Create a new entry in RM.unique_pairs and initialize unique_pairs_counts
    RM.unique_pairs = [RM.unique_pairs; SM.inputPrevious SM.input];
    RM.unique_pairs_counts = [RM.unique_pairs_counts; 1];
end
