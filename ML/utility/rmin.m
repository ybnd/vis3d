function m = rmin(A)
    m = recurse_f_to_0d(A, @min);
end