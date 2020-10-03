//coded by Jason Thong for COE3DQ5 2019
//encoding of image from .ppm to .mic13

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

void write_bits(FILE *fp, unsigned int data, int length);	//function prototype

int main(int argc, char **argv) {
	int i, j, k, m, n, color, width, height, jm5, jm3, jm1, jp1, jp3, jp5, quantized[64], q[15], width_temp;
	char input_filename[200], output_filename[200], temp_string[100], quantization_choice;
	double *y_image, *u_image, *v_image, *downsampled_u_image, *downsampled_v_image, red, blue, green, dct_coeff[8][8], temp_matrix[8][8], *d_ptr;
	FILE *file_ptr;
	const int zigzag_order[] = {0, 1, 8,16, 9, 2, 3,10,17,24,32,25,18,11, 4, 5,12,19,26,33,40,48,41,34,27,20,13, 6, 7,14,21,28,
	                           35,42,49,56,57,50,43,36,29,22,15,23,30,37,44,51,58,59,52,45,38,31,39,46,53,60,61,54,47,55,62,63};
	const int Q0[] = {8,4,8,8,16,16,32,32,64,64,64,64,64,64,64};
	const int Q1[] = {8,2,2,2,4,4,8,8,16,16,16,32,32,32,32};
	
	//get input file name either from first command line argument or from the user interface (command prompt)
	if (argc<2) {
		printf("enter the input file name including the .ppm extension: ");
		gets(input_filename);
	}
	else strcpy(input_filename, argv[1]);
	
	//get output file name either from second command line argument or from the user interface (command prompt)
	if (argc<3) {
		printf("enter the output file name including the .mic13 extension: ");
		gets(output_filename);
	}
	else strcpy(output_filename, argv[2]);
	
	//whether to use quantization matrix 0 or 1
	if (argc<4) {
		printf("enter 0 to use quantization matrix Q0, otherwise Q1 will be used: ");
		gets(temp_string);
		quantization_choice = (temp_string[0]=='0') ? 0 : 1;
	}
	else quantization_choice = (argv[3][0]=='0') ? 0 : 1;
	
	//open input file
	file_ptr = fopen(input_filename, "rb");
	if (file_ptr==NULL) {
		printf("can't open file %s for binary reading, exiting...\n", input_filename);
		exit(1);
	}
	else printf("opened input file %s\n", input_filename);
	
	//read and check header of image
	fscanf(file_ptr, "%s", temp_string);
	if (strcmp(temp_string, "P6")!=0) { printf("unexpected image type, expect P6, got %s, exiting...", temp_string); exit(1); }
	fscanf(file_ptr, "%d", &width);
	if (width < 0 || (width & 7)!=0) { printf("invalid width of image, must be a positive integer divisible by 8, got %d, exiting...\n", width); exit(1); }
	fscanf(file_ptr, "%d", &height);
	if (width < 0 || (width & 7)!=0) { printf("invalid height of image, must be a positive integer divisible by 8, got %d, exiting...\n", height); exit(1); }
	if (width!=320 || height!=240) printf("warning, width and height are not the expected values of 320 and 240, got %d and %d\n", width, height);
	fscanf(file_ptr, "%s", temp_string);
	if (strcmp(temp_string, "255")!=0) { printf("unexpected maximum number of colors, expect 255, got %s, exiting...", temp_string); exit(1); }
	fgetc(file_ptr);	//new line
	
	//read entire image, temporarily store red in y_image, green in u_image, blue in v_image
	y_image = (double *)malloc(sizeof(double)*width*height);
	u_image = (double *)malloc(sizeof(double)*width*height);
	v_image = (double *)malloc(sizeof(double)*width*height);
	downsampled_u_image = (double *)malloc(sizeof(double)*width*height/2);
	downsampled_v_image = (double *)malloc(sizeof(double)*width*height/2);
	if (y_image==NULL || u_image==NULL || v_image==NULL || downsampled_u_image==NULL || downsampled_v_image==NULL) { printf("malloc failed :(\n)"); exit(1); }
	for (i=0; i<height; i++) for (j=0; j<width; j++) {
		y_image[i*width+j] = (double)fgetc(file_ptr);	//red
		u_image[i*width+j] = (double)fgetc(file_ptr);	//green
		v_image[i*width+j] = (double)fgetc(file_ptr);	//blue
	}
	if (fgetc(file_ptr)!=EOF) printf("warning: not all of the data in the input ppm file was read\n");
	fclose(file_ptr);
	
	//color space conversion RGB -> YUV, each pixel is processed independently
	for (i=0; i<height; i++) for (j=0; j<width; j++) {
		red = y_image[i*width+j];		//hold on to RGB values before overwriting with the YUV values in place
		green = u_image[i*width+j];
		blue = v_image[i*width+j];
		y_image[i*width+j] = 0.257*red + 0.504*green + 0.098*blue + 16.0;
		u_image[i*width+j] = -0.148*red - 0.291*green + 0.439*blue + 128.0;
		v_image[i*width+j] = 0.439*red - 0.368*green - 0.071*blue + 128.0;
	}
	
	//horizontal downsampling of U and V
	for (i=0; i<height; i++) for (j=0; j<width; j+=2) {	//even j (columns) only
		jm5 = ((j-5) < 0) ? 0 : (j-5);		//use neighboring pixels to interpolate, but catch the out-of-bounds indexes
		jm3 = ((j-3) < 0) ? 0 : (j-3);
		jm1 = ((j-1) < 0) ? 0 : (j-1);
		jp1 = ((j+1) > (width-1)) ? (width-1) : (j+1);
		jp3 = ((j+3) > (width-1)) ? (width-1) : (j+3);
		jp5 = ((j+5) > (width-1)) ? (width-1) : (j+5);
		downsampled_u_image[i*width/2 + j/2] = 0.5 * u_image[i*width + j]
			+ 0.311 * (u_image[i*width + jm1] + u_image[i*width + jp1])
			- 0.102 * (u_image[i*width + jm3] + u_image[i*width + jp3])
			+ 0.043 * (u_image[i*width + jm5] + u_image[i*width + jp5]);
			
		downsampled_v_image[i*width/2 + j/2] = 0.5 * v_image[i*width + j]
			+ 0.311 * (v_image[i*width + jm1] + v_image[i*width + jp1])
			- 0.102 * (v_image[i*width + jm3] + v_image[i*width + jp3])
			+ 0.043 * (v_image[i*width + jm5] + v_image[i*width + jp5]);
	}
	
	//DCT (discrete cosine transform), done in blocks of 8x8
	for (i=0; i<8; i++) {	//cache the DCT coefficients
		red = (i==0) ? sqrt(1.0/8.0) : sqrt(2.0/8.0);	//the leading coefficient in front of the cosine
		for (j=0; j<8; j++) dct_coeff[i][j] = red * cos(M_PI/8.0*i*(j+0.5));
	}
	for (color=0; color<3; color++) {
		if (color==0) {			//Y
			d_ptr = y_image;	//provide a reference to the y_image array
			width_temp = width;		//original width
		}
		else if (color==1) {	//downsampled U
			d_ptr = downsampled_u_image;
			width_temp = width / 2;	//half the original width
		}
		else {					//downsampled V
			d_ptr = downsampled_v_image;
			width_temp = width / 2;	//half the original width
		}
		//now do the matrix multiplications
		for (i=0; i<height; i+=8) for (j=0; j<width_temp; j+=8) {	//i*width_temp+j is the address of the top left corner of the current 8x8 block
			for (k=0; k<8; k++) for (m=0; m<8; m++) {		//first matrix multiplication C * S, write to temp_matrix
				temp_matrix[k][m] = 0.0;
				for (n=0; n<8; n++) temp_matrix[k][m] += dct_coeff[k][n] * d_ptr[(i+n)*width_temp+j+m];	//across C, down S (row i+n, column j+m)
			}
			for (k=0; k<8; k++) for (m=0; m<8; m++) {		//second matrix multiplication (C*S) * C^T, read from temp_matrix
				d_ptr[(i+k)*width_temp+j+m] = 0.0;			//row i+k, column j+m
				for (n=0; n<8; n++) d_ptr[(i+k)*width_temp+j+m] += temp_matrix[k][n] * dct_coeff[m][n];	//across C*S, down C^T (or across C)
			}
		}
	}
	
	//open output file and write header
	file_ptr = fopen(output_filename, "wb");
	if (file_ptr==NULL) {
		printf("can't open file %s for binary writing, exiting...\n", output_filename);
		exit(1);
	}
	else printf("opened output file %s\n", output_filename);
	fputc(0xde, file_ptr);	//"deadbeef" header
	fputc(0xad, file_ptr);
	fputc(0xbe, file_ptr);
	fputc(0xef, file_ptr);
	fputc( ((quantization_choice&1)<<7) | ((width>>8)&0x7f) , file_ptr);	//msb specifies quantization matrix, 15 lsb is width
	fputc(width & 0xff, file_ptr);
	fputc((height>>8) & 0xff, file_ptr);	//16 bits for height
	fputc(height & 0xff, file_ptr);
	
/*
lossless decoding table:
00x: 2 bit run of zeros
010: 4 bit run of zeros
011: run of zeros to end of block
100: 9 bit value
101: 5 bit value
11x: 3 bit value
*/
	
	//quantization and lossless encoding - do all the Y blocks first, then U, then V, within a color, go across the blocks first, then down
	for (i=0; i<15; i++) q[i] = (quantization_choice==0) ? Q0[i] : Q1[i];	//load q with the appropriate pre-defined values
	for (color=0; color<3; color++) {
		if (color==0) {			//Y
			d_ptr = y_image;	//provide a reference to the y_image array
			width_temp = width;
		}
		else if (color==1) {	//downsampled U - half the original width
			d_ptr = downsampled_u_image;
			width_temp = width / 2;
		}
		else {					//downsampled V
			d_ptr = downsampled_v_image;
			width_temp = width / 2;
		}
		//now do the quantization and encoding
		for (i=0; i<height; i+=8) for (j=0; j<width_temp; j+=8) {
			for (k=0; k<8; k++) for (m=0; m<8; m++) {
				d_ptr[(i+k)*width_temp+j+m] /= (double)q[k+m];		//divide first, then round to nearest integer, different rounding for positive and negative
				quantized[8*k+m] = (d_ptr[(i+k)*width_temp+j+m]<0) ? (int)(d_ptr[(i+k)*width_temp+j+m]-0.5) : (int)(d_ptr[(i+k)*width_temp+j+m]+0.5);
				quantized[8*k+m] = (quantized[8*k+m] > 255) ? 255 : (quantized[8*k+m] < -256) ? -256 : quantized[8*k+m];	//clip to 9 bits signed
			}
			m=0;	//how many consecutive zeros
			for (k=0; k<64; k++) {
				if (quantized[zigzag_order[k]]==0) {
					for (n=k+1; n<64; n++) if (quantized[zigzag_order[n]]) break;
					if (n==64) {
						write_bits(file_ptr, 3, 3);		//011 - run of zeros to end header
						break;							//done encoding this 8x8 block
					}
					else if (m==15) {	//just got the 16th consecutive zero
						if (k==63) printf("error: k==63, i %d, j %d, m %d, color %d\n", i, j, m, color);	//this should never print, for debugging purposes
						m=0;
						write_bits(file_ptr, 2, 3);		//010 - long consecutive zeros header
						write_bits(file_ptr, 0, 4);		//0000 - specifies 16 zeros
					}
					else m++;
				}
				else {
					if (m) {	//previous consecutive run of zeros has just ended, but cannot be 16 zeros
						if (m<=4) {	//short run of zeros
							write_bits(file_ptr, 0, 2);			//00 - short consecutive zeros header
							write_bits(file_ptr, m & 0x3, 2);	//2 bits to specify number of consecutive zeros, 4 zeros will result in 00
						}
						else {	//long run of zeros
							write_bits(file_ptr, 2, 3);			//010 - consecutive zeros header
							write_bits(file_ptr, m & 0xf, 4);	//4 bits to specify number of consecutive zeros
						}
						m = 0;
					}
					if (quantized[zigzag_order[k]] < 4 && quantized[zigzag_order[k]] >= -4) {	//short coefficient, representable on 3 bits
						write_bits(file_ptr, 3, 2);										//11 - long coefficient header
						write_bits(file_ptr, quantized[zigzag_order[k]] & 0x7, 3);		//write the 3 bits
					}
					else if (quantized[zigzag_order[k]] < 16 && quantized[zigzag_order[k]] >= -16) {	//medium coefficient, representable on 5 bits
						write_bits(file_ptr, 5, 3);										//101 - medium coefficient header
						write_bits(file_ptr, quantized[zigzag_order[k]] & 0x1f, 5);		//write the 5 bits
					}
					else {		//long coefficient, 9 bits
						write_bits(file_ptr, 4, 3);										//100 - long coefficient header
						write_bits(file_ptr, quantized[zigzag_order[k]] & 0x1ff, 9);	//write the 9 bits
					}
				}
			}
		}
	}
	
	write_bits(file_ptr, 0, 15);	//write 15 zeros so that if the buffer is not full, this will force the last bits to be written to the file
	fclose(file_ptr);				//but if buffer is empty, another 2 bytes will not be written
	
	free(y_image);
	free(u_image);
	free(v_image);
	free(downsampled_u_image);
	free(downsampled_v_image);
	
	printf("\n\n");
	printf("quantization matrix is Q%d\n", quantization_choice);
	printf("done :)\n");
	return 0;
}
//end main

void write_bits(FILE *fp, unsigned int data, int length) {	//can write up to 32 bits at once, the least significant "length" bits of "data" will be written
	static unsigned short buffer=0;	//buffer can hold up to 16 bits, 2 bytes are written together since SRAM is 16 bits wide
	static unsigned char count=0;	//count is number of bits in use in buffer
	int i;
	
	while (length>0) {
		length--;
		buffer = (buffer<<1) | ((data>>length) & 1);	//extract bit "length-1", buffer acts like a shift register in hardware
		count++;
		if (count==16) {	//16 bits in buffer, write high byte, then low byte
			fputc((buffer>>8) & 0xff, fp);
			fputc(buffer & 0xff, fp);
			count = 0;
		}
	}
}
