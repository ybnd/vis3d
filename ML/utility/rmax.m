function m = rmax(A)
    m = recurse_f_to_0d(A, @max);
end