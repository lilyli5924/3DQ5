Readme for COE3DQ5 Project Software Model 2019
Written by Jason Thong and Nicola Nicolici

IMPORTANT: The software model provides an exact specification of what computation is done in the project, it says nothing about what hardware resources will perform the computation and what clock cycle the computations and/or reads/writes from/to memory will occur. Also, computation may be re-organized. We may choose to compute x*(y+z) in software whereas in hardware it may be easier to do it as x*z+x*y, for example.

This directory contains the following C source files:

bmp_to_ppm.c
compare_ppm.c
decode_m1.c
decode_m2.c
decode_m3.c
encode_all.c

Each of these files compile independently. The codes are written in ANSI C and have been tested with the GCC compiler under Mac OS, Linux and Cygwin under Windows. They SHOULD compile and run on other platforms.

To compile with gcc: gcc source_name.c -lm -o executable_name

When running the software from the terminal, the names of the input/output files as well as other parameters can be provided as command line arguments. For example,

./bmp_to_ppm picture.bmp picture.ppm

(to use a terminal under Windows, launch Cygwin).

The above command specifies that the input file is picture.bmp and the output file is picture.ppm. Please refer to the source code to see which command line argument is used for what. If command line arguments are not provided, you will be prompted during run-time to supply the necessary file names/parameters through the standard input.

The data flow of the project is as follows:

bmp_to_ppm:
This converts a .bmp file to a .ppm file. The data in a .ppm file is organized as R0, G0, B0, R1, G1, B2, etc. and the pixel order goes across first, then down (like lab 5 experiment 2a and experiment 4a).

encode_all:
This encodes the .ppm file to a .mic13 file (McMaster Image Compression, revision 13). The details of encoding are provided in the project document. As a summary, first we do color space conversion, then downsampling of U and V, then IDCT on 8x8 blocks, and finally lossless decoding and quantization. You will not need to implement any of this in hardware.

decode_m3:
This is a reference for milestone 3 in hardware. The .mic13 file is lossless decoded and dequantization is applied, the result is a .sram_d2 file. This file serves as the input for milestone 2 (this file is organized exactly like the SRAM, so in the testbench it can be used to initialize the SRAM for milestone 2). Also, this file can be used to verify milestone 3 is working properly in hardware (testbench).

decode_m2:
This is a reference for milestone 2 in hardware. The .sram_d2 file contains pre-IDCT data. We compute the IDCT on this data and the result is written to a .sram_d1 file. Again, this is organized like the SRAM in hardware, which makes it easy to initialize and compare the final data in the SRAM in a testbench.

decode_m1:
This is a reference for milestone 1 in hardware. The .sram_d1 file contains YUV data, but the U and V are still downsampled versions. Horizontal interpolation is done to upsample the odd columns of U and V (from the even columns, each row is processed independently). Finally, for each pixel independently, the YUV data is converted to RGB and the data is written back to the SRAM.

compare_ppm:
This is NOT part of the data flow in the project. Note that due to downsampling and quantization, the compression is LOSSY, which means the decoded .ppm and original .ppm will probably not be exactly the same. This program compare_ppm computes the PSNR between 2 ppm images (see project document for details).

process_all.sh:

This script compiles all the sources and it runs all the executables for all the .bmp files in the working directory.

clean_all.sh:

This script cleans all the intermediate files and it leaves only the sources and the .bmp  files in the working directory.

Hardware design:

UART is used to initialize the SRAM, see lab 5 experiment 4a. After data is processed and written back to the SRAM, a state machine like the one in lab 5 experiment 4a is used to read from the SRAM and display on the VGA monitor. This backbone and the corresponding testbench is given to you already.

As a final note, during the project, the first hardware you will design is that which processes data closest to the final RGB values. Milestone 1 is the last stage of decoding. As you progress through the project, you will process data further back from the final data and therefore milestone 3 is the first stage of decoding.
