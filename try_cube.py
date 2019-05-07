from py.ocmbin import ocmbin, downscale_u32_u8, dB_u32_to_u8
import cv2
import numpy as np
import matplotlib.pyplot as plt

A = ocmbin('test.bin')

cube = A.cube
# cube = A.cube.newbyteorder('S')

x = 250
y = 250
z = 75

floor = 45

cubeslice1 = dB_u32_to_u8(cube[x, :, :], floor)
cubeslice2 = dB_u32_to_u8(cube[:, y, :], floor)
cubeslice3 = dB_u32_to_u8(cube[:, :, z], floor)

plt.close()

plt.figure()
plt.imshow(cubeslice1, cmap=plt.get_cmap('gray'))

plt.figure()
plt.imshow(cubeslice2, cmap=plt.get_cmap('gray'))

plt.figure()
plt.imshow(cubeslice3, cmap=plt.get_cmap('gray'))
plt.show()

print('done.')