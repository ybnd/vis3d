# vis3d

Basic 3d image visualization for OCT and OCM data.

### Getting started

1. Clone (or [download](https://github.com/ybnd/vis3d/archive/master.zip)) this package to your MATLAB project folder

2. Make sure the `vis3d` directory is included in your MATLAB path

   - Copy `startup.m` to the root directory of your project

   - If you already have a `startup.m` script, add the following line to it:

     ```matlab
     addpath(genpath('vis3d/ML'));
     ```
3. Thorlabs' MATLAB OCT API is not included in this repository because its licensing terms are unknown. To work with Thorlabs' `.oct` files, include this package in `vis3d/__external`.

4. You should be done! There's a [tutorial](ML/examples/tutorial.md) with some super small example images.

