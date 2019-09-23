function automatizationUnit ()
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

global SM AU

if AU.access
    % Increase count of <key, value> pair
    AU.input_history_counts{1,AU.column_location}(AU.row_location) = AU.input_history_counts{1,AU.column_location}(AU.row_location) + 1;
    % Update unique_pairs_counts for that key
    AU.unique_pairs_counts(AU.column_location) = AU.unique_pairs_counts(AU.column_location) + 1;
elseif AU.column_location
	% checks if value exist in 'AU.input_history'
    if AU.row_location
        % Increase count of <key, value> pair
        AU.input_history_counts{1,AU.column_location}(AU.row_location) = AU.input_history_counts{1,AU.column_location}(AU.row_location) + 1;
        % Check the key column for the value with maximum count
        tic
        [max_count,AU.row_location] = max(AU.input_history_counts{1,AU.column_location});
        toc
        tic
        
        
        % Update unique_pairs_counts for that key
        AU.unique_pairs_counts(AU.column_location) = max_count;
        % Update unique_pairs with max count
        AU.unique_pairs(AU.column_location,:) = [SM.input SM.inputNext];
    else
        % Adds <key, value> pair to existing 'key' column and initializes count.
        AU.input_history{1,AU.column_location} = [AU.input_history{1,AU.column_location}; SM.input SM.inputNext];
        AU.input_history_counts{1,AU.column_location} = [AU.input_history_counts{1,AU.column_location}; 1];
    end
else
    % Create a new cell in AU.input_history and initialize the Counts
    AU.input_history{1,size(AU.input_history,2)+1} = [SM.inputPrevious SM.input];
    AU.input_history_counts{1,size(AU.input_history_counts,2)+1} = 1;
    % Create a new entry in AU.unique_pairs and initialize unique_pairs_counts
    AU.unique_pairs = [AU.unique_pairs; SM.inputPrevious SM.input];
    AU.unique_pairs_counts = [AU.unique_pairs_counts; 1];
end
