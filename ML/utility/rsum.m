function m = rsum(A)
    m = recurse_f_to_0d(A, @sum);
end