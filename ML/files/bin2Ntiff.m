function bin2Ntiff(I, out_path)    
    I = permute(I,[2,1,3]);
    factor = (2^16-1)/double(max(max(max(I))));    
    I16 = double(I .* factor);    
    [~,~,Nz] = size(I16);
    
    I16 = double(I16 / max(max(max(I16))));
    
    mkdir(out_path);
    
    for i = 1:Nz
        A = I(:,:,i);
        t = Tiff([out_path filesep num2str(i) '.tiff'], 'w');
        tagstruct.ImageLength = size(A,1); 
        tagstruct.ImageWidth = size(A,2);
        tagstruct.Photometric = Tiff.Photometric.MinIsBlack;
        tagstruct.SampleFormat = Tiff.SampleFormat.UInt;
        tagstruct.BitsPerSample = 32;
        tagstruct.SamplesPerPixel = 1;
        tagstruct.RowsPerStrip    = 16;
        tagstruct.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky; 
        tagstruct.Software = 'MATLAB'; 
        
        setTag(t,tagstruct)
        
        write(t, A);
        close(t)

%         imwrite(A,[out_path filesep num2str(i) '.png']);

    end

    
end