import numpy as np
import json
import re
import warnings
from typing import Tuple, Type
import os


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
        # 3d images tend to be *large*, default to single if not specified *which* float
        return np.single
    else:
        warnings.warn(f'dtype string "{dtype}" is invalid or empty; defaulting to {np.uint32}')
        return np.uint32


def mfmt_string_to_numpy_byteorder(mfmt: str) -> str:
    if any(mfmt == f for f in ['ieee-le', 'little-endian', 'le']):
        return '<'
    elif any(mfmt == f for f in ['ieee-be', 'big-endian', 'be']):
        return '>'
    else:
        raise ValueError(
            'Format could not be resolved to "little-endian" or "big-endian". See implementation for details.')

def downscale_u32_u8(image: np.ndarray, factor: float = 1.0) -> np.ndarray:
    image = image.astype(np.double)
    image = np.multiply(np.divide(image, np.max(image)*factor), 255)
    return image.astype(np.uint8)


def dB_u32_to_u8(image: np.ndarray, floor: float = 50) -> np.ndarray:
    image = np.multiply(np.log10(np.divide(image.astype(np.double), np.max(image))), 10)
    image = np.multiply(np.divide(image+floor, np.max(image+floor)), 255)
    return image.astype(np.uint8)


class Cube:
    def __init__(self, path: str, do_load: bool=False):
        if os.path.exists(path) or os.path.exists(path + '.json'):
            self.path = path

            self.name = None
            self.desc = None
            self.cube = None
            self.data = None
            self.meta = None
            self.data = {}

            self.__mfmt = None
            self.__is_loaded = False

            if do_load:
                self.load_data()
        else:
            raise ValueError(f'Path "{path}" does not exist.')

    def save(self, fmt='', path=None):
        """ Save Cube to path, in a specific format. """

        if path is None:
            path = self.path

        if fmt in ['tif', 'tiff']:
            tempCube = tifCube(path, False)
        else:
            tempCube = Cube(path, False)

        tempCube.save_data(path)

    def load_data(self):
        """ Load raw data from json/binary files. Should be overridden to support other formats! """

        self.path, _ = os.path.splitext(self.path)
        folder, file = os.path.split(self.path)

        with open(self.path + '.json') as f:
            header = json.load(f)

        self.name = header['name']
        self.desc = header['desc']
        self.meta = header['meta']

        for d in header['data']:
            if len(d.keys()) == 1:
                self.data[list(d.keys())[0]] = d
            elif all(field in d.keys() for field in ['name', 'size', 'type', 'path']):
                try:
                    mfmt = d['mfmt'].lower()
                except KeyError:
                    mfmt = 'ieee-le'
                    warnings.warn(f'Assuming default mfmt "ieee-le" for {d["path"]}')

                if any(mfmt == f for f in ['ieee-le', 'little-endian', 'le']):
                    mfmt = 'ieee-le'
                elif any(mfmt == f for f in ['ieee-be', 'big-endian', 'be']):
                    mfmt = 'ieee-be'
                else:
                    raise ValueError('Format could not be resolved to "little-endian" or "big-endian". '
                                     'See implementation for details.')

                dtype = string_to_np_dtype(d['type'])

                # These files tend to get quite big, so you might hit a memory limit if you're using an IDE.
                A = np.memmap(
                    filename=os.path.join(folder, d['path']), dtype=dtype, mode='r', shape=tuple(d['size'])
                )

                if d['name'] == 'cube':
                    self.cube = A
                else:
                    self.data[d['name']] = A

            else:
                raise ValueError(f'Unrecognized format in data field {d}.')





        pass

    def save_data(self, path):
        """ Save raw data to json/binary files. Should be overridden to support other formats! """
        pass

    def unload_data(self):
        """ Unload raw data from memory, but keep this interface """
        pass

    def _resolve_save(self, path):
        """
        Resolve file saving path
        :param path: path to save the file at
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

    def _parseMetadata(self):
        """ Parse metadata from ocmbin binary file. """
        pass

    def _checkOverlap(self) -> dict:
        """ Check byte overlap between datasets in the binary file. """
        pass

    def _rename_MD_fields(self):
        """ Rename metadata fields -> more readable. """
        pass

    def _extractData(self):
        """ Extract raw data from ocmbin binary file """
        pass

    def _readRegion(self, start, shape, dtype) -> np.ndarray:
        """ Read a region from ocmbin binary file """
        pass


class tifCube(Cube):
    def load_data(self):
        """ Load from TIFF image stack. """
        pass

    def save_data(self, path):
        """ Save to TIFF image stack """
        pass


class thorCube(Cube):
    def load_data(self):
        """ Load from Thorlabs .oct file (.zip container with XML, images & raw data) """
        pass


def loadcube(path: str, do_load=True) -> Cube:
    """ Load a Cube instance from path """

    # Default to regular Cube
    CubeClass = Cube

    if os.path.isdir(path):
        # todo:  Check if .tiff files in path
        CubeClass = tifCube
    else:
        _, ext = os.path.splitext(path)

        if ext in ['tif']:
            CubeClass = tifCube
        elif ext in ['oct']:
            CubeClass = thorCube
        elif ext in ['ocmbin', 'ocm', 'bin']:
            CubeClass = ocmCube

    return CubeClass(path, do_load=do_load)


def savecube(C: Cube, path: ''):
    """ Save Cube instance C to path """

    if not os.path.isabs(path):
        if not path is '':
            folder, _ = os.path.split(C.path)
        else:
            folder = os.getcwd()
        path = os.path.join(folder, path)

    _, ext = os.path.splitext(path)

    if ext in ['', 'json']:
        CubeClass = Cube
    elif ext in ['tif']:
        CubeClass = thorCube
    else:
        raise ValueError(f'Invalid extension {ext} in {path}')

    tempCube = CubeClass('', False)
    tempCube.name = C.name
    tempCube.desc = C.desc
    tempCube.cube = C.cube
    tempCube.data = C.data
    tempCube.meta = C.meta

    tempCube.save_data(path)