# Binary file specification

For faster saving/loading, data are saved in uncompressed binary files with separate JSON header files. 
Without the header file, the binary file(s) can **not** be loaded, so it's up to the user to make sure it's not deleted. 
In previous iterations of this format the header and binary data were combined into a single file, but I don't recommend this. If you really want one file, I suggest packaging the header and binary file(s) in an archive. Without compression packaging/unpackaging takes about 2-3 seconds, with compression it can take a couple of minutes, but will also save some space.

The format, type and number of datasets per file is up to the user, but I suggest keeping it to a single 3D image per file for performance reasons in the MATLAB library.
With the utilities provided in this repository, binary files can be converted to .tif for use outside MATLAB.
The MATLAB library supports loading and saving files (both binary and .tif), while the LabVIEW library can be used for logging data from imaging setups.

## Header format

The header for a file `<file>` is saved as `<file>.json`

### Fields

```json
{
    "name": "<file>",
    "desc": "...",
    "data": [
        {...}, {...}
    ],
    "meta": {
        ...
    } 
}
```



- name: 				
  - Name of the file
- desc: 				
  - Description of the measurement
- data:  		       
  - Specification of the included datasets (see below)
- meta:				
  - Arbitrary metadata (optional)

### Data specification

All datasets are stored as arrays. For any data that is more complex, I suggest you either store it as metadata (i.e. as a JSON object) or convert it into an array. The details of this conversion can be saved in the metadata.
To have as few binary files as possible, short datasets should be saved directly to the header file. The default minimum array size is set to 307200 elements (a 640-by-480 grayscale image).

#### Short datasets

Short datasets are saved as JSON arrays:
``` json
{
	"data": [
		{
			"dataset-name": [
				"..."
			]
		}
	]
}
```
Please note that this implies that whatever format is used to encode this data into a JSON string is sufficient to represent its full range and precision. 

#### Long datasets

Long datasets are saved in separate binary files, which are described in the header:

```json
{
	"data": [
		{
			"name": "dataset-name",
			"path": "path/to/dataset",
			"size": [100,100,100],
			"type": "single",
			"mfmt": "ieee-le"
		}
	]
}

```

To load the dataset, the binary file at `"path"` can be read out with the specifications `"size"`, `"type"` and `"mfmt"`. While `"size"` is just an array of integers, the way `"type"` and `"mfmt"` are specified may differ between applications, and should be handled during loading (see the MATLAB library for the implementation).
The 3D image is the main dataset in basically all cases, so its binary file is saved in `<file>.cube` extension with `"name": "cube"` in its data description. This is important for the correct function of the MATLAB library. 
Other datasets are saved as `<file>.data1`, `<file>.data2`, etc. by default, but the extension is arbitrary as long as its specified correctly in the header.

