import numpy as np
import json
import re
import warnings
from typing import Tuple, Type


def string_to_np_dtype(dtype: str) -> Type[np.dtype]:
    if dtype in ['u8', 'uint8']:
        return np.uint8
    elif dtype in ['u16', 'uint16']:
        return np.uint16
    elif dtype in ['u30', 'uint32']:
        return np.uint32
    elif dtype in ['u64', 'uint64']:
        return np.uint64
    elif dtype in ['i8', 'int8']:
        return np.int8
    elif dtype in ['i16', 'int16']:
        return np.int16
    elif dtype in ['i32', 'int32']:
        return np.int32
    elif dtype in ['i64', 'int64']:
        return np.int64
    elif dtype in ['dbl', 'double']:
        return np.double
    elif dtype in ['sgl', 'single', 'float']:
        # 3d images tend to be large, default to single if not specified *which* float
        return np.single
    else:
        warnings.warn(f'dtype string "{dtype}" is invalid or empty; defaulting to {np.uint32}')
        return np.uint32


def mfmt_string_to_np_byteorder(mfmt: str) -> str:
    pass


def downscale_u32_u8(image: np.ndarray, factor: float = 1.0) -> np.ndarray:
    image = image.astype(np.double)
    image = np.multiply(np.divide(image, np.max(image)*factor), 255)
    return image.astype(np.uint8)


def dB_u32_to_u8(image: np.ndarray, floor: float = 50) -> np.ndarray:
    image = np.multiply(np.log10(np.divide(image.astype(np.double), np.max(image))), 10)
    image = np.multiply(np.divide(image+floor, np.max(image+floor)), 255)
    return image.astype(np.uint8)


class Cube:
    def __init__(self, path, do_load=False):
        self.path = path    # todo: sanity checks for path
        self.do_load = do_load

        if do_load:
            self.load_data()

    def save(self, fmt, path, options):
        """ Save Cube to path, in a specific format, with optional options. """
        pass

    def load_data(self):
        """ Load raw data from json/raw files. Should be overridden to support other formats! """
        pass

    def save_data(self):
        """ Save raw data to json/raw files. Should be overridden to support other formats! """
        pass

    def unload_data(self):
        """ Unload raw data from memory, but keep this interface """
        pass

    def resolve_save(self, path, options):
        """
        Resolve file saving path & options
        :param path: path to save the file at
        :param options: options
        """
        pass

    def zpos(self) -> np.ndarray:
        """
        Returns the vertical (Z) position vector
        :return: Z-axis position vector
        """
        pass

    def slice(self, s, axis) -> np.ndarray:
        """
        Returns a slice of the cube at position s on specified axis
        :param s: position to slice at
        :param axis: axis to slice on
        :return: image (2d numpy array)
        """
        pass


class ocmCube(Cube):
    __HEADER_SIZE__ = 8192
    __HEADER_NULL__ = re.compile('\x00')

    def load_data(self):
        """ Load raw data from ocmbin binary file. This format is deprecated. Saving not supported! """
        pass

    def parseMetadata(self):
        """ Parse metadata from ocmbin binary file. """
        pass

    def checkOverlap(self) -> dict:
        """ Check byte overlap between datasets in the binary file. """
        pass

    def rename_MD_fields(self):
        """ Rename metadata fields -> more readable. """
        pass

    def extractData(self):
        """ Extract raw data from ocmbin binary file """
        pass

    def readRegion(self, start, shape, dtype) -> np.ndarray:
        """ Read a region from ocmbin binary file """
        pass


class tifCube(Cube):
    def load_data(self):
        """ Load from TIFF image stack. """
        pass

    def save_data(self):
        """ Save to TIFF image stack """
        pass


class thorCube(Cube):
    def load_data(self):
        """ Load from Thorlabs .oct file (.zip container with XML, images & raw data) """
        pass
