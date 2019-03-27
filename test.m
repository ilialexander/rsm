clc;
clear all;
l = zeros(2,2);
d = size(l,1);
while ~isempty(l)
    l(d,:) = [];
    d = d - 1;
end

l