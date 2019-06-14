import numpy as np
import json
import re
import warnings
from typing import Tuple, Type


def string_to_np_dtype(dtype: str) -> Type[np.dtype]:
    if dtype == 'u8' or dtype == 'uint8':
        return np.uint8
    elif dtype == 'u16' or dtype == 'uint16':
        return np.uint16
    elif dtype == 'u32' or dtype == 'uint32':
        return np.uint32
    elif dtype == 'u64' or dtype == 'uint64':
        return np.uint64
    elif dtype == 'i8' or dtype == 'int8':
        return np.int8
    elif dtype == 'i16' or dtype == 'int16':
        return np.int16
    elif dtype == 'i32' or dtype == 'int32':
        return np.int32
    elif dtype == 'i64' or dtype == 'int64':
        return np.int64
    elif dtype == 'dbl' or dtype == 'double' or dtype == 'float':
        return np.double
    elif dtype == 'sgl' or dtype == 'single':
        return np.single
    else:
        warnings.warn(f'dtype string "{dtype}" is invalid or empty; defaulting to {np.uint32}')
        return np.uint32


def downscale_u32_u8(image: np.ndarray, factor: float = 1.0) -> np.ndarray:
    image = image.astype(np.double)
    image = np.multiply(np.divide(image, np.max(image)*factor), 255)
    return image.astype(np.uint8)


def dB_u32_to_u8(image: np.ndarray, floor: float = 50) -> np.ndarray:
    image = np.multiply(np.log10(np.divide(image.astype(np.double), np.max(image))), 10)
    image = np.multiply(np.divide(image+floor, np.max(image+floor)), 255)
    return image.astype(np.uint8)


class ocmbin:
    __HEADER_SIZE__ = 8192
    __HEADER_NULL__ = re.compile('\x00')

    def __init__(self, path: str, do_load: True):
        pass

        self.path = path

        if not hasattr(self, 'is_loaded'):
            self.is_loaded = False

            # Metadata
            self.metadata = None
            self.datasets = None
            self.overlap = None

            # Data
            self.cube = None
            self.cube_reduced = None
            self.position = None
            self.data = None

        if do_load:
            self.load_data()

    def load_data(self):
        if not self.is_loaded:
            if self.metadata is None:
                self.parse_metadata()
                self.check_overlap()

            self.extract_data()

            self.is_loaded = True

    def unload_data(self):
        if self.is_loaded:
            # Release data, keep metadata
            self.cube = None
            self.cube_reduced = None
            self.position = None
            self.data = None

            self.is_loaded = True

    def read_header(self):
        with open(self.path, 'rb') as f:
            f.seek(0,0)
            header = f.read(self.__HEADER_SIZE__)
            header = header.decode('UTF-8').strip()
            header = self.__HEADER_NULL__.sub('', header)
            return header

    def parse_metadata(self):
        header = self.read_header()
        self.metadata = json.JSONDecoder().decode(header)

        self.datasets = [dataset['Name'] for dataset in self.metadata['Data']]

    def check_overlap(self):
        pass

        self.overlap = {}

        for i, dataset in enumerate(self.datasets):
            self.overlap[dataset] = self.metadata['Data'][i]['Position']['LastByte'] > \
                                    self.metadata['Data'][i]['Position']['StopByte']

            self.overlap[dataset] = {
                'overbyte': self.metadata['Data'][i]['Position']['LastByte'] -
                            self.metadata['Data'][i]['Position']['StopByte'],
                'allocated':    self.metadata['Data'][i]['Position']['StopByte'] - \
                                self.metadata['Data'][i]['Position']['StartByte'],
                'written':      self.metadata['Data'][i]['Position']['LastByte'] - \
                                self.metadata['Data'][i]['Position']['StartByte'],

            }

    def extract_data(self, load_mode: str = 'read'):
        self.data = {}

        # Extract all datasets
        for i, dataset in enumerate(self.datasets):
            self.data[dataset] = self.read_region(
                self.metadata['Data'][i]['Position']['StartByte'],
                tuple(self.metadata['Data'][i]['Size']),
                load_mode,
                string_to_np_dtype(self.metadata['Data'][i]['dtype'])
            )

        # Handle main datasets, 'cube' and 'position'
        if 'cube' in self.data.keys():
            self.cube = self.data['cube']

        if 'position' in self.data.keys():
            self.position = self.data['position']

            # Convert uint32 nm to float µm
            self.position = self.position.astype(np.double) / 1e3

    def read_region(self, start: int, shape: Tuple[int, int, int],
                    load_mode: str = 'read', dtype: Type[np.dtype] = np.uint32) -> np.ndarray:
        dimensions = len(shape)
        count = int(np.prod(shape))

        if load_mode == 'memmap':
            # Memmap region of binary file
            raise NotImplementedError
        else:
            # Read into memory
            with open(self.path, 'rb') as f:
                f.seek(start, 0)  # Go to 'StartByte'
                data = np.fromfile(f, dtype=dtype, count=count)

                if dimensions == 1:
                    return data
                elif dimensions == 2:
                    data = data.reshape(shape)
                    return data.transpose()
                elif dimensions == 3:
                    fixed_shape = (shape[2], shape[1], shape[0])
                    data = data.reshape(fixed_shape).newbyteorder('<')
                    return data.transpose((2, 1, 0))  # Transpose to X*Y*Z  todo: double-check!
                else:
                    raise NotImplementedError(f'Invalid dataset shape: {shape}; must be either 1-, 2-, or 3-dimensional')
