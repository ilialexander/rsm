function automatizationUnit ()
% This function keeps a full history of all the inputs organized as first-order-sequence <key,value> pairs. Keeping a tallie of the frequency of each pair in 'AU.input_history_counts'.
% Unique first-order-sequence <key,value> pairs are also saved in a separate array 'AU.uniquePatterns' and updated with the maximum frequency pairs under the respective 'key'.
% The maximum frequency count is also stored per each 'key' in 'AU.uniqueCounts'


%% Copyright (c) 2016,  Sudeep Sarkar, University of South Florida, Tampa, USA
% This work is licensed under the Attribution-NonCommercial-ShareAlike 4.0 International License.
% To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/4.0/
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
%

global SM AU

%% [ToDo: Change all variable name styles from AU.Counts to AU.counts or AU.input_history_counts]
%% [ToDo: Change variable name from AU.Counts to AU.input_history_counts]

if AU.access
    % Increase count of <key, value> pair
    AU.Counts{1,AU.colLocation}(AU.rowLocation) = AU.Counts{1,AU.colLocation}(AU.rowLocation) + 1;
    % Update uniqueCounts for that key
    AU.uniqueCounts(AU.colLocation) = AU.uniqueCounts(AU.colLocation) + 1;
elseif AU.colLocation
	% checks if value exist in 'AU.inputHistory'
    if AU.rowLocation
        % Increase count of <key, value> pair
        AU.Counts{1,AU.colLocation}(AU.rowLocation) = AU.Counts{1,AU.colLocation}(AU.rowLocation) + 1;
        % Check the key column for the value with maximum count
        [AU.maxCount,AU.rowLocation] = max(AU.Counts{1,AU.colLocation});
        % Update uniqueCounts for that key
        AU.uniqueCounts(AU.colLocation) = AU.maxCount;
        % Update uniquePatterns with max count
        AU.uniquePatterns(AU.colLocation,:) = [SM.input SM.inputNext];
    else
        % Adds <key, value> pair to existing 'key' column and initializes count.
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
