function m = rprod(A)
    m = recurse_f_to_0d(A, @prod);
end