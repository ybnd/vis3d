clear all
close all
clc

fpath = iopath('test_json9', 'ocmbin_desktop', 't');

result = struct;

N = 500;

for i = 1:N
    fprintf(i)
    A = ocmbin(fpath);
    result(i).readTime = A.io_timings.dataReadTime;
    result(i).ReadRateMBs = A.io_timings.ReadRateMBs;
end

figure;
plot([result.ReadRateMBs]);



% A.export_tif('volume', 'volume')
% A.tif
% A.explore

% live_A_scan(A.cube)