function header=open_header(file)
    A = ocmbin(file, false); % Open interface to .ocmbin file, but don't load the actual file
    A.parseMetadata();
    header = A.header;
end