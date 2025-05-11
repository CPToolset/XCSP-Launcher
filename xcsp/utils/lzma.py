import lzma
import shutil

def decompress_lzma_file(input_path, output_path):
    with lzma.open(input_path, 'rb') as compressed_file:
        with open(output_path, 'wb') as decompressed_file:
            shutil.copyfileobj(compressed_file, decompressed_file)