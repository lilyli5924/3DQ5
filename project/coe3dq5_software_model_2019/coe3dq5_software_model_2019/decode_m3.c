//coded by Jason Thong for COE3DQ5 2019
//decoding of milestone 3 - read a .mic13 file, do lossless decoding, write a .sram_d2 file
//the output file contains pre-IDCT data and is organized the same way as the SRAM is supposed to be in hardware (see project document)
//the output is used as the input to decode_m2

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

unsigned int read_bits(FILE *fp, int length);	//function prototype

int main(int argc, char **argv) {
	int i, j, k, m, n, color, width, height, width_temp, sram_offset_address, decoded_data[64], q[15];
	char input_filename[200], output_filename[200], temp_string[100], quantization_choice;
	FILE *file_ptr;
	const int zigzag_order[] = {0, 1, 8,16, 9, 2, 3,10,17,24,32,25,18,11, 4, 5,12,19,26,33,40,48,41,34,27,20,13, 6, 7,14,21,28,
	                           35,42,49,56,57,50,43,36,29,22,15,23,30,37,44,51,58,59,52,45,38,31,39,46,53,60,61,54,47,55,62,63};
	const int Q0[] = {3,2,3,3,4,4,5,5,6,6,6,6,6,6,6};	//these indicate how many bit shifts are supposed to be done, not multiplication/division
	const int Q1[] = {3,1,1,1,2,2,3,3,4,4,4,5,5,5,5};
	const int SRAM_Y_out = 76800, SRAM_U_out = 153600, SRAM_V_out = 192000;	//starting address of where to WRITE each segment, change it for increased height and width
	unsigned short *sram;													//to avoid overwriting data due to spillover from segment to another
	
	//get input file name either from first command line argument or from the user interface (command prompt)
	if (argc<2) {
		printf("enter the input file name including the .mic13 extension: ");
		gets(input_filename);
	}
	else strcpy(input_filename, argv[1]);
	
	//get output file name either from second command line argument or from the user interface (command prompt)
	if (argc<3) {
		printf("enter the output file name including the .sram_d2 extension: ");
		gets(output_filename);
	}
	else strcpy(output_filename, argv[2]);
	
	//open input file
	file_ptr = fopen(input_filename, "rb");
	if (file_ptr==NULL) {
		printf("can't open file %s for binary reading, exiting...\n", input_filename);
		exit(1);
	}
	else printf("opened input file %s\n", input_filename);
	
	//read input file header, "deadbeef", after this, msb indicates quantization matrix, next 15 bits is width, last 16 bits is height
	i = fgetc(file_ptr);
	if (i==EOF || i!=0xde) { printf("unexpected data read from input file header, exiting...\n"); exit(1); }
	i = fgetc(file_ptr);
	if (i==EOF || i!=0xad) { printf("unexpected data read from input file header, exiting...\n"); exit(1); }
	i = fgetc(file_ptr);
	if (i==EOF || i!=0xbe) { printf("unexpected data read from input file header, exiting...\n"); exit(1); }
	i = fgetc(file_ptr);
	if (i==EOF || i!=0xef) { printf("unexpected data read from input file header, exiting...\n"); exit(1); }
	i = fgetc(file_ptr);
	j = fgetc(file_ptr);
	if (i==EOF || j==EOF) { printf("unexpected data read from input file header, exiting...\n"); exit(1); }
	quantization_choice = (i>>7) & 1;
	width = ((i & 0x7f) << 8) | (j & 0xff);		//7 lsb of i concatenated with 8 lsb of j
	i = fgetc(file_ptr);
	j = fgetc(file_ptr);
	if (i==EOF || j==EOF) { printf("unexpected data read from input file header, exiting...\n"); exit(1); }
	height = ((i & 0xff) << 8) | (j & 0xff);	//8 lsb of i concatenated with 8 lsb of j
	if ((height%8)!=0 || (width%8)!=0) { printf("error: height and width must be some multiple of 8, exiting...\n"); exit(1); }
	if (height!=240 || width!=320) printf("warning: height and width are not the expected 240 and 320, got %d and %d\n", height, width);
	if (height*width > 240*320) printf("warning: default sized Y, U, and V segments in memory are not large enough, data will get overwritten from spillover\n");
	
	//allocate virtual sram, 16 bits by 2^18 locations
	sram = (unsigned short *)malloc(sizeof(unsigned short)*262144);
	if (sram==NULL) { printf("malloc failed :(\n)"); exit(1); }
	for (i=0; i<262144; i++) sram[i] = 0;

/*
lossless decoding table:
00x: 2 bit run of zeros
010: 4 bit run of zeros
011: run of zeros to end of block
100: 9 bit value
101: 5 bit value
11x: 3 bit value
*/

	//lossless decoding and de-quantization
	for (i=0; i<15; i++) q[i] = (quantization_choice==0) ? Q0[i] : Q1[i];	//load q with the appropriate pre-defined values
	for (color=0; color<3; color++) {
		if (color==0) {
			sram_offset_address = SRAM_Y_out;
			width_temp = width;
		}
		else if (color==1) {
			sram_offset_address = SRAM_U_out;
			width_temp = width / 2;		//because of downsampling
		}
		else {
			sram_offset_address = SRAM_V_out;
			width_temp = width / 2;
		}
		//lossless decoding, no quantization
		for (i=0; i<height; i+=8) for (j=0; j<width_temp; j+=8) {	//which block of 8x8, i and j is the x and y location of the top-left pixel in the block
			for (k=0; k<64; k++) {
				m = read_bits(file_ptr, 2);	//read header, first 2 bits
				if (m==0) {	//read 00, 2 bit run of zeros
					n = read_bits(file_ptr, 2);
					n = (n==0) ? (k+4) : (k+n);	//if n==0, there are 4 zeros, else there are n zeros, assign n to ending index to which we write zeros to
					if (n>=64) { printf("unexpected error in bitstream, run of zeros goes past end of block, exiting...\n"); exit(1); }
					for ( ; k<n; k++) decoded_data[zigzag_order[k]] = 0;
					k--;	//to cancel out the outer loop update, the outer loop moves k from the last index we wrote to an index we have not yet written to
				}
				else if (m==1) {	//read 01, could be 4 bit run of zeros or run of zeros to end
					if (read_bits(file_ptr, 1)) {	//complete header is 011, zeros to end
						for ( ; k<64; k++) decoded_data[zigzag_order[k]] = 0;
					}
					else {	//complete header is 010, 4 bit run of zeros
						n = read_bits(file_ptr, 4);
						n = (n==0) ? (k+16) : (k+n);	//if n==0, there are 16 zeros, else there are n zeros, assign n to ending index to which we write zeros to
						if (n>=64) { printf("unexpected error in bitstream, run of zeros goes past end of block, exiting...\n"); exit(1); }
						for ( ; k<n; k++) decoded_data[zigzag_order[k]] = 0;
						k--;	//to cancel out the outer loop update, the outer loop moves k from the last index we wrote to an index we have not yet written to
					}
				}
				else if (m==2) {	//read 10, could be 5 or 9 bit number
					if (read_bits(file_ptr, 1)) {	//complete header is 101, 5 bit number
						n = read_bits(file_ptr, 5);
						decoded_data[zigzag_order[k]] = (n >= 16) ? (n-32) : n;
					}
					else {	//complete header is 100, 9 bit number
						n = read_bits(file_ptr, 9);
						decoded_data[zigzag_order[k]] = (n >= 256) ? (n-512) : n;
					}
				}
				else {				//read 11, 3 bit number
					n = read_bits(file_ptr, 3);
					decoded_data[zigzag_order[k]] = (n >= 4) ? (n-8) : n;
				}
			}
			//finished decoding one 8x8 block, now dequantize and write to virtual ram
			for (k=0; k<8; k++) for (m=0; m<8; m++) {
				decoded_data[8*k+m] <<= q[k+m];	//based on which diagonal we are on (k+m), shift data at row k and column m
				sram[width_temp*(i+k) + j+m + sram_offset_address] = decoded_data[8*k+m] & 0xffff;	//write to row i+k, column j+m + offset (for color) in sram
			}
		}
	}
	
	//decoding done, check that end of file reached
	if (fgetc(file_ptr)!=EOF) printf("warning: end of input file not reached where expected\n");
	fclose(file_ptr);
	
	//open output file and write virtual sram to file
	file_ptr = fopen(output_filename, "wb");
	if (file_ptr==NULL) {
		printf("can't open file %s for binary writing, exiting...\n", output_filename);
		exit(1);
	}
	else printf("opened output file %s\n", output_filename);
	for (i=0; i<262144; i++) {
		fputc((sram[i]>>8) & 0xff, file_ptr);	//write high byte first
		fputc(sram[i] & 0xff, file_ptr);		//then low byte
	}
	fclose(file_ptr);
	
	free(sram);
	printf("quantization matrix is Q%d\n", quantization_choice);
	printf("done :)\n");
	return 0;
}
//end main

unsigned int read_bits(FILE *fp, int length) {	//can read up to 32 bits at once, the bits will be placed on the least significant "length" bits of "data"
	static unsigned short buffer=0;	//buffer can hold up to 16 bits, 2 bytes are read together since SRAM is 16 bits wide
	static unsigned char count=0;	//count is number of bits in use in buffer
	unsigned int data;
	int read_char;
	
	data = 0;
	while (length>0) {
		if (count==0) {	//buffer empty, read 16 bits
			read_char = fgetc(fp);		//read high byte
			if (read_char==EOF) { printf("unexpected end of file, exiting...\n"); exit(1); }
			buffer = (read_char & 0xff) << 8;
			read_char = fgetc(fp);		//read low byte
			if (read_char==EOF) { printf("unexpected end of file, exiting...\n"); exit(1); }
			buffer |= (read_char & 0xff);
			count = 16;
		}
		count--;
		data = (data<<1) | ((buffer>>count) & 1);	//put most significant valid bit of buffer into lsb of data, note how data acts like a shift register in hardware
		length--;
	}
	return data;
}
