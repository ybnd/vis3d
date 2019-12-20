function out = recurse_f_to_0d(A, f, varargin)
    tmp = A;
    while ~isscalar(tmp)
        tmp = f(tmp, varargin{:});
    end
    out = tmp;
end