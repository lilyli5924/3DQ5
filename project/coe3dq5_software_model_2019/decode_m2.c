//coded by Jason Thong for CoE3DQ5 2012
//decoding of milestone 2 - read a .sram_d2 file, do IDCT (inverse discrete cosine transform), write a .sram_d1 file
//the output file contains YUV data (downsampled U and V) and is organized the same way as the SRAM is supposed to be in hardware (see project document)
//the output is used as the input to decode_m1

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

int main(int argc, char **argv) {
	int i, j, k, m, n, color, width, height, width_temp, sram_offset_address_read, sram_offset_address_write, idct_coeff[8][8], temp_matrix1[8][8], temp_matrix2[8][8];
	char input_filename[200], output_filename[200];
	double double_tmp1, double_tmp2;
	FILE *file_ptr;
	const int SRAM_Y_in = 76800, SRAM_U_in = 153600, SRAM_V_in = 192000;	//starting address of where to READ each segment
	const int SRAM_Y_out = 0, SRAM_U_out = 38400, SRAM_V_out = 57600;		//starting address of where to WRITE each segment
	unsigned short *sram;
	
	//it is ASSUMED that the image width is 320 and the height is 240, if you increase these values make sure to change the values of
	//SRAM_Y_in, SRAM_Y_out, SRAM_U_in, etc. otherwise some data will be overwritten (spillover from one segment to another) or data will write outside of the memory
	width = 320;
	height = 240;
	
	//get input file name either from first command line argument or from the user interface (command prompt)
	if (argc<2) {
		printf("enter the input file name including the .sram_d2 extension: ");
		gets(input_filename);
	}
	else strcpy(input_filename, argv[1]);
	
	//get output file name either from second command line argument or from the user interface (command prompt)
	if (argc<3) {
		printf("enter the output file name including the .sram_d1 extension: ");
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
	
	//allocate virtual sram, 16 bits by 2^18 locations, then read from input file
	sram = (unsigned short *)malloc(sizeof(unsigned short)*262144);
	if (sram==NULL) { printf("malloc failed :(\n)"); exit(1); }
	for (i=0; i<262144; i++) {
		j = fgetc(file_ptr);
		k = fgetc(file_ptr);
		if (j==EOF || k==EOF) { printf("unexpected end of file, sram file should be EXACTLY 512 KB, exiting...\n"); exit(1); }
		sram[i] = ((j & 0xff) << 8) | (k & 0xff);
	}
	if (fgetc(file_ptr)!=EOF) printf("warning: end of input file not reached where expected\n");
	fclose(file_ptr);
	
	//initialize IDCT coefficients, comment out the printf's is desired...
	printf("fixed-point IDCT coefficients:\n");
	for (i=0; i<8; i++) {
		double_tmp1 = (i==0) ? sqrt(1.0/8.0) : sqrt(2.0/8.0);
		for (j=0; j<8; j++) {
			idct_coeff[i][j] = (int)( double_tmp1 * cos(i*M_PI*(j+0.5)/8.0) * 4096.0 );
			printf("%7d ", idct_coeff[i][j]);
		}
		printf("\n");
	}
	
	//IDCT
	for (color=0; color<3; color++) {
		if (color==0) {			//Y
			sram_offset_address_read = SRAM_Y_in;
			sram_offset_address_write = SRAM_Y_out;
			width_temp = width;		//original width
		}
		else if (color==1) {	//downsampled U
			sram_offset_address_read = SRAM_U_in;
			sram_offset_address_write = SRAM_U_out;
			width_temp = width / 2;	//half the original width
		}
		else {					//downsampled V
			sram_offset_address_read = SRAM_V_in;
			sram_offset_address_write = SRAM_V_out;
			width_temp = width / 2;	//half the original width
		}
		for (i=0; i<height; i+=8) for (j=0; j<width_temp; j+=8) {	//i*width_temp+j+offset_read is the read address of the top left corner of the current 8x8 block
			
			//fetch data from sram into temp_matrix1
			for (k=0; k<8; k++) for (m=0; m<8; m++) {
				temp_matrix1[k][m] = sram[ (i+k)*width_temp + j+m + sram_offset_address_read ];
				temp_matrix1[k][m] = (temp_matrix1[k][m] >= 32768) ? (temp_matrix1[k][m]-65536) : temp_matrix1[k][m];	//sign extension, "sram" in software is unsigned
			}
			
			//first matrix multiplication S' * C, write to temp_matrix2
			for (k=0; k<8; k++) for (m=0; m<8; m++) {
				temp_matrix2[k][m] = 0;
				for (n=0; n<8; n++) temp_matrix2[k][m] += temp_matrix1[k][n] * idct_coeff[n][m];	//across S', down C
				temp_matrix2[k][m] >>= 8;	//after first matrix multiplication, divide by 256 and then cast result as integer (equivalent to cutting of 8 lsb)
			}
			
			//second matrix multiplication C^T * (S' * C), write to temp_matrix1
			for (k=0; k<8; k++) for (m=0; m<8; m++) {
				temp_matrix1[k][m] = 0;
				for (n=0; n<8; n++) temp_matrix1[k][m] += idct_coeff[n][k] * temp_matrix2[n][m];	//across C^T (or down C), down (S' * C)
				temp_matrix1[k][m] >>= 16;	//after second matrix multiplication, divide by 65536 and then cast result as integer (equivalent to cutting of 16 lsb)
				temp_matrix1[k][m] = (temp_matrix1[k][m]<0) ? 0 : ((temp_matrix1[k][m]>255) ? 255 : temp_matrix1[k][m]);	//clip the final answer to 8 bits unsigned
			}
			
			//write back to sram, note 2 pieces of 8-bit data are stored in each location (SRAM is 16 bits wide), this YUV data is unsigned
			for (k=0; k<8; k++) for (m=0; m<8; m+=2) {	//first piece of data goes in high byte
				sram[ ((i+k)*width_temp + j+m) / 2 + sram_offset_address_write ] = ((temp_matrix1[k][m] & 0xff) << 8) | (temp_matrix1[k][m+1] & 0xff);
			}
		}
	}
	
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
	printf("done :)\n");
	return 0;
}
