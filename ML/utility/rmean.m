function m = rmean(A)
    m = recurse_f_to_0d(A, @mean);
end