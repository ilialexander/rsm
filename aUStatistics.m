function aUStatistics (startFile, endFile)
%startFile = 1;
%endFile = 1;
% This function does statistical analisys to demonstrate the need of authomatization
% to improve speed.

% We count the SM.input/SDR that connect directly to the same
% next input.

% Then we calculate how many different events can an observation lead to.
% This will be compared to the amount of times that the observation happens.
% There should be a ratio to consider between this two parameters.

fid = fopen('fileList.txt', 'r');
i = 1;
while ~feof(fid)
    fscanf(fid, '%d ', 1); % skip the line count in the first column
    fileNames{i} = fscanf(fid, '%s ', 1);
    i = i+1;
end
fclose (fid);

for i=startFile:endFile
%     clear global;
    
    [~, name, ~] = fileparts(fileNames{i});
        
    %% Read saved run data --
    % see data field record structure in main.m and other variables stored in the mat file
    
    load (sprintf('Output/inputSM_%s.mat', name));
    
    consecutive1 = [inputSM(1:(size(inputSM,1)-1),:) inputSM(2:size(inputSM,1),:)];
    
    [Au, ~, ic] = unique(consecutive1, 'rows', 'stable');
    Counts = accumarray(ic, 1);
    uniqueSequences = sortrows([Counts Au],'descend');
    
    [Aua, ~, ica] = unique(consecutive1(:,1:2048), 'rows', 'stable');
    Countsa = accumarray(ica, 1);
    uniqueSequencesA = sortrows([Countsa Aua],'descend');
    similarsequences = [zeros(size(Counts)) uniqueSequences];
  
    m = 1;
    l = 1;
    j = 1;
    while j<size(similarsequences,1)+1
        jtemp = j;
        for k=(j+1):size(similarsequences,1)
            if similarsequences(j,3:2050) == similarsequences(k,3:2050)
                similarsequences = [similarsequences(1:j,:);
                                    l similarsequences(k,2:end);
                                    similarsequences(j+1:end,:)];
                similarsequences(k+1,:) = [];
                j = j + 1;
            end
        end
        m = m + 1;
        l = l + 1;
        
        if j == jtemp
            similarsequences = [similarsequences;
                                0 similarsequences(j,2:end)];
            similarsequences(j,:) = [];
            l = l - 1;
            j = j - 1;
        end
       
        if m > size(similarsequences,1)
                break;
        end
        j = j + 1;
    end    
    similarsequences = [similarsequences(:,1) ones(size(Counts)) ones(size(Counts)) similarsequences(:,2:end)];
    automatizationunit = [];    
    for n=1:size(uniqueSequencesA,1)
        for o=1:size(similarsequences,1)
            if similarsequences(o,5:2052)==uniqueSequencesA(n,2:2049)
                similarsequences(o,2) = 100*(similarsequences(o,4)/uniqueSequencesA(n,1));
                similarsequences(o,3) = uniqueSequencesA(n,1);
            end
            if o==size(similarsequences,1)
                break;
            end
            if (similarsequences(o,1) == 0)
               similarsequences(o,1) = similarsequences(o+1,1);
            end
        end
    end

%    fid=fopen(sprintf('Output/statisticsInputSM_%s_%s.txt',sprintf('%d',i), name),'w');
%    fprintf(fid, 'Dataset Size: %-30d\n',size(inputSM,1));
%    fprintf(fid, '%-20s %-25s %-20s %-15s\n', ["Initial Event", "Percentage of A->X", "Frequency of A", "Frequency of A->X"]);
    for p=1:size(similarsequences,1)
%        fprintf(fid,'%-20f %-25f %-20f %-15f\n', similarsequences(p,1),similarsequences(p,2),similarsequences(p,3),similarsequences(p,4));
        if (similarsequences(p,2) >= 50) && (similarsequences(p,4) >= 3)
            automatizationunit = [automatizationunit; similarsequences(p,:)];
        end
    end
%    fclose(fid);

    save (sprintf('Output/AU_%s.mat', name), 'automatizationunit');

end