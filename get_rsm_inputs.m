load ('rsm_inputs.mat')

minicolumns = zeros(size(data.inputSDR,1),40);

for i=1:size(data.inputSDR,1)
    minicolumns(i,:) = find(data.inputSDR(i,:));
end

csvwrite('minicolumns.txt',minicolumns.');