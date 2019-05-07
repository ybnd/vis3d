clear all
close all
clc

fpath = iopath('try_scan.bin', 'tryscans', 's');

A = ocmbin(fpath);
A.export_tif(false);