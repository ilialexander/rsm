%% Benchmarks in .txt file
benchmarks = {'Twitter', 1, 10;
    'Traffic',          11, 17;
    'Known Cause',      18, 24;
    'AWS Cloud Watch',  25, 41;
    'Ad Exchange',      42, 47;
    'Artificial',       48, 58;
    'Every',             1, 58};

for datasets = 1:length(benchmarks)
    fprintf("\n\n%s benchmark computed", benchmarks{datasets,1})
    startFile = benchmarks{datasets,2};
    endFile = benchmarks{datasets,3};
    bootstrapping (startFile, endFile, false)
end
