#!/usr/bin/env python3

"""
FILE: create_full_flash.py

DESCRIPTION:
Create a single full_flash.bin by placing components at conventional ESP offsets.

BRIEF:
Composes bootloader, partition table (optional), and application binary
into a single flash image that can be written with esptool. Pads regions
with 0xFF to align with flash layout.

AUTHOR: Kevin Thomas
CREATION DATE: October 5, 2025
UPDATE DATE: October 5, 2025
"""

import argparse
import os
import sys


def read_blob(path):
    """Read a binary blob from disk and return its contents.

    Parameters
    ----------
    path : str
        Filesystem path to the binary file to read.

    Returns
    -------
    bytes
        The raw bytes read from the file.

    Raises
    ------
    IOError
        If the file cannot be opened or read (propagates to caller).
    """
    with open(path, 'rb') as f:
        return f.read()


def main():
    """Parse arguments and create a single flash image file.

    This function performs the following steps:
    1. Parse command-line options specifying component paths and offsets.
    2. Validate presence of requested blobs and build a list of (name, path, offset).
    3. Compute the final image size and allocate a flash-shaped buffer filled with 0xFF.
    4. Write each component into the buffer at its requested offset.
    5. Optionally write the two-word ESP header at offset 0x0.
    6. Flush the resulting image to disk.
    """
    # Parse command-line arguments and defaults
    p = argparse.ArgumentParser(description='Create full_flash.bin')
    p.add_argument('--boot', help='path to bootloader.bin', default=None)
    p.add_argument('--partition', help='path to partition-table.bin', default=None)
    p.add_argument('--app', help='path to app binary (raw)', required=True)
    p.add_argument('--out', help='output path', default='full_flash.bin')
    p.add_argument('--add-header', action='store_true', help='write ESP header magic words at offset 0x0')
    p.add_argument('--boot-off', type=lambda x: int(x,0), default=0x1000)
    p.add_argument('--part-off', type=lambda x: int(x,0), default=0x8000)
    p.add_argument('--app-off', type=lambda x: int(x,0), default=0x10000)
    args = p.parse_args()

    # Collect component blobs requested by the user. Each entry is a tuple
    # (logical_name, filesystem_path, flash_offset). Missing optional blobs
    # will be ignored with a warning; the app blob is required and will abort
    # if not found.
    blobs = []
    if args.boot:
        if not os.path.isfile(args.boot):
            print('Warning: bootloader not found at', args.boot)
            args.boot = None
        else:
            # --boot-off becomes args.boot_off (argparse converts - to _)
            blobs.append(('boot', args.boot, args.boot_off))
    if args.partition:
        if not os.path.isfile(args.partition):
            print('Warning: partition table not found at', args.partition)
            args.partition = None
        else:
            blobs.append(('partition', args.partition, args.part_off))

    # The application binary is required. Bail out with an error if missing.
    if not os.path.isfile(args.app):
        print('ERROR: app binary not found at', args.app)
        sys.exit(1)
    blobs.append(('app', args.app, args.app_off))

    # Determine the final image size (end) by finding the highest used
    # address: max(offset + blob_size) across all components. We'll allocate
    # a buffer of this size and initialize it with 0xFF (erased flash state).
    end = 0
    for name, path, off in blobs:
        size = os.path.getsize(path)
        end = max(end, off + size)

    # Report what will be done
    print('Creating', args.out)
    print('Components:')
    for name, path, off in blobs:
        print(' -', name, '->', hex(off), 'size', os.path.getsize(path))

    # Create the output file and populate it.
    # 1) Fill with 0xFF to represent erased flash.
    # 2) Seek and write each binary blob at its requested flash offset.
    with open(args.out, 'wb') as outf:
        # initialize with 0xFF (flash erased state)
        outf.write(b'\xff' * end)

        # Write each component at its requested offset
        for name, path, off in blobs:
            # Read the file content into memory (small blobs expected)
            data = read_blob(path)
            outf.seek(off)
            outf.write(data)

        # Optional header used by some bare-metal examples: two 32-bit magic words
        # The header is written after the components are placed so that a
        # component intentionally located at 0x0 won't be overwritten by the
        # header write. The magic value matches some examples that perform a
        # simple boot signature test.
        if args.add_header:
            header_val = 0xaedb041d
            header_bytes = header_val.to_bytes(4, 'little') + header_val.to_bytes(4, 'little')
            outf.seek(0)
            outf.write(header_bytes)

    # Final report
    print('Wrote', args.out, 'size', os.path.getsize(args.out))
    print('\nTo flash with esptool (example):')
    print('  python -m esptool --chip esp32c3 --port <COM> write_flash 0x0', args.out)


if __name__ == '__main__':
    main()
