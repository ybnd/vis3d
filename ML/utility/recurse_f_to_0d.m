function out = recurse_f_to_0d(A, f, varargin)
    tmp = A;
    while ~isequal(size(tmp), [1,1])
        tmp = f(tmp, varargin{:});
    end
    out = tmp;
end