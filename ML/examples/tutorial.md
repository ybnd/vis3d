# vis3d tutorial

You can follow along with [example.m](example.m) . Make sure MATLAB is 'pointed' to the `vis3d` directory!

### Loading 3d image files

The default file format in `vis3d` is json/binary, and consists of a .json header file and one or more binary files.
This is also the format the OCM setup spits out.

The header file (`example.json`) contains all of the metadata associated with the image, as well as references to any binary files. The 'cube file' (`example.cube`) contains the binary data of our 3d image. Of course if you lose/delete either of these files, the data will be lost forever. So don't!

To open a json/binary file, execute

```matlab
A = loadcube('<path/to/exaples/example>')
```

This newborn `A` is a instance of the [Cube](../cube/Cube.m) class and contains the 3d image as a regular array, and has a number of useful methods to work with the image or explore it.
The function [`loadcube`](../loadcube.m) infers the format of a 3d image based on its file extension. When the path has no extension, as was the case in the previous section, it will try to load a json/binary file.

To load .tif stack instead, we can call it as:

```matlab
A = loadcube('<path/to/examples/example.tif>')
```

Two other file formats are also supported:

*  Files ending in .bin, this is an older version of json/binary where everything is squished into one binary file. Useful if you'd want to open old files from 2017-2019.
* .oct files generated by Thorlabs OCT systems. 

There is no way to save files in these formats with `vis3d`, and there shouldn't be.

### Looking at 3d images

There are two main methods to display 3d images in `vis3d`: `Cube.sf` (slice figure)  and `Cube.of` (ortographic figure)
* `sf` lets you slice through the cube in a single direction
* `of` lets you slice through the cube in three orthogonal directions

You can open these figures by executing

```matlab
% Slice figures
A.sf; A.sf('yz'); 

% Orthographic figure
A.of; 
```

You can navigate the cube by scrolling. To scroll the XZ and YZ views in `Cube.of`, scroll while pressing down <Shift> and <Alt>.  Alternatively, you can also click and drag within the XY, YZ and XZ views to navigate.

#### InteractiveMethods

These figures contain menu boxes where you can select a *slice method* and a *postprocess method*. These methods determine how portions of the 3d image are extracted from the array `A.cube`.  They're called *InteractiveMethods* since you can swap and modify their parameters on the fly.

The most basic *slice method*, `slice`, just slices a part of the cube an index of one of the axes of the cube. Other slice methods such as `blur_slice` modify the raw data by blurring it and combining information from multiple slices to generate an image.

These slice images are then further modified by a *postprocess method*. In this way, you can adjust the brightness, contrast, ... of the image without actually modifying the raw data. For example, `dBs_global` transforms the slice image to a shifted decibel representation, applies a lower and upper cutoff, and finally rescales this image so that the minimum and maximum value of `A.cube` map to 0 and 1 respectively.

New *slice* and *postprocess methods* can be defined by adding them in [`interactive_methods.m`](../interactive_methods.m); there you can also define additional parameters, which will then be accessible in `Cube.sf` and `Cube.of`.

##### Interacting with InteractiveMethods over the command line

*InteractiveMethods* can also be addressed over the command line, which can be useful when calling `of` or `sf` from a script when you already know which settings you want.

For instance, to select `blur_slice` and `dBs_local`, execute

```matlab
A.im_select('blur_slice', 'dBs_local')
```

Furthermore, you can get and set the parameters with `Cube.im_set` and `Cube.im_get`. For example, the following command sets `XY sigma` to ten times `Z sigma`

```matlab
A.im_set('XY sigma', 10 * A.im_get('Z sigma'))
```

If you open a new figure now, you'll see these changes in effect.

Notice that all parameter and method names are listed in  `interactive_methods.m` and must match exactly for this to work! If you add new *InteractiveMethods*, make sure that parameters you may want to address like this have unique names. Otherwise, results will probably be unexpected.

### Working with regions of interest

The `CubeROIs` class provides some functionality to define *regions of interest* within a 3d image. In this example we'll use a subclass of `CubeROIs`, `region_thickness`, which implements some methods to compute distances between peaks in the depth profile of an ROI. 

The 3d image used in the previous sections contains two layers of 'spheres'; with `region_thickness` we can calculate the distance between them. After executing

```matlab
B = region_thickness(A);
B.select;
```

a slice figure appears, but this time you can also select rectangles in the image with the cursor. For each selection, the `ROI` class computes a binary representation of the selected part, assuming that the part we're interested higher-intensity. This binary image is then used to mask off the ROI and calculate its average depth profile.

The resulting profiles and distances can be evaluated with

```matlab
B.profiles;
d = B.distances;
```

### Modifying 3d images

The actual 3d image is directly accessible in `A.cube`, and can be modified in any way a regular MATLAB matrix can be modified. 

### Saving 3d image files

Use the `savecube` function to save any changes to disk. As with 'loadcube', this function will look at the extension of the path you're saving to to deteemine whether to save json/binary files or a .tif file.

```matlab
% Save as json/binary
savecube(A, [folder '\example']);

% Save as .tif
savecube(A, [folder '\example.tif']);
```

