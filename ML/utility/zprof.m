function [Iz] = zprof(C, coo, pixel)
     [Nx,Ny,~] = size(C);
     
    switch nargin
        case 1
            coo = [floor(Nx/2), floor(Ny/2)];
            pixel = false;
        case 2
            pixel = false;
    end
    
    if pixel
       
        coo_in = coo;
        coo(2) = coo_in(1);
        coo(1) = Nx - coo_in(2);
    end
    
    if length(coo) ~= 2
%         warning('Invalid z-profile coordinate')
        
        [~,~,Nz] = size(C);
        Iz = zeros(1,Nz);
    else
        try
            Iz = permute( C(coo(1),coo(2),:), [3,2,1] );
        catch
            [~,~,Nz] = size(C);
            Iz = zeros(1,Nz);
        end
    end
    
    Iz = double(Iz);
end