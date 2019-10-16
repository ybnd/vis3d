function m = rmedian(A)
    m = recurse_f_to_0d(A, @median);
end