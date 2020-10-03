//coded by Jason Thong for CoE3DQ5 2012
//decoding of milestone 1 - read a .sram_d1 file, do IDCT (inverse discrete cosine transform), write a .sram_d0 file
//the output file contains RGB data (formatted as {R0 G0}, {B0 R1}, {G1 B1}, ...) and is organized the same way as the SRAM is supposed to be in hardware 
//(see project document), also an output ppm file is provided

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(int argc, char **argv) {
	int i, j, k, jm5, jm3, jm1, jp1, jp3, jp5, width, height, y_val, u_val, v_val;
	int *y, *u, *v, idct_coeff[8][8], temp_matrix1[8][8], temp_matrix2[8][8];
	char input_filename[200], output_filename[200], output_filename2[200];
	double double_tmp1, double_tmp2;
	FILE *file_ptr;
	const int SRAM_Y_in = 0, SRAM_U_in = 38400, SRAM_V_in = 57600;	//starting address of where to READ each segment
	const int SRAM_RGB_out = 146944;								//starting address of where to WRITE
	unsigned short *sram;
	
	//it is ASSUMED that the image width is 320 and the height is 240, if you increase these values make sure to change the values of
	//SRAM_Y_in, SRAM_RGB_out, etc. otherwise some data will be overwritten (spillover from one segment to another) or data will write outside of the memory
	width = 320;
	height = 240;
	
	//get input file name either from first command line argument or from the user interface (command prompt)
	if (argc<2) {
		printf("enter the input file name including the .sram_d1 extension: ");
		gets(input_filename);
	}
	else strcpy(input_filename, argv[1]);
	
	//get .sram_d0 output file name either from second command line argument or from the user interface (command prompt)
	if (argc<3) {
		printf("enter the SRAM output file name including the .sram_d0 extension: ");
		gets(output_filename);
	}
	else strcpy(output_filename, argv[2]);
	
	//get .ppm output file name either from third command line argument or from the user interface (command prompt)
	if (argc<4) {
		printf("enter the PPM output file name including the .ppm extension: ");
		gets(output_filename2);
	}
	else strcpy(output_filename2, argv[3]);
	
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
	
	//extract Y, even U, and even V from SRAM into arrays
	y = (int *)malloc(sizeof(int)*width*height);
	u = (int *)malloc(sizeof(int)*width*height);
	v = (int *)malloc(sizeof(int)*width*height);
	if (y==NULL || u==NULL || v==NULL) { printf("malloc failed :(\n)"); exit(1); }
	for (i=0; i<height; i++) for (j=0; j<width; j+=2) {						//extract Y
		y[i*width+j] = (sram[(i*width+j)/2 + SRAM_Y_in] >> 8) & 0xff;		//high byte from SRAM goes to even indexes
		y[i*width+j+1] = sram[(i*width+j)/2 + SRAM_Y_in] & 0xff;		//low byte from SRAM goes to odd indexes
	}
	for (i=0; i<height; i++) for (j=0; j<width/2; j+=2) {					//extract downsampled U - even indexes only
		u[i*width+2*j] = (sram[(i*width/2+j)/2 + SRAM_U_in] >> 8) & 0xff;	//high byte from SRAM goes to indexes 0, 4, 8, ... (divided by 2 result would be even)
		u[i*width+2*j+2] = sram[(i*width/2+j)/2 + SRAM_U_in] & 0xff;	//low byte from SRAM goes to indexes 2, 6, 10, ... (divided by 2 result would be odd)
	}
	for (i=0; i<height; i++) for (j=0; j<width/2; j+=2) {					//extract downsampled V - same like U
		v[i*width+2*j] = (sram[(i*width/2+j)/2 + SRAM_V_in] >> 8) & 0xff;
		v[i*width+2*j+2] = sram[(i*width/2+j)/2 + SRAM_V_in] & 0xff;
	}
	
	//upsample the odd column U and V
	for (i=0; i<height; i++) for (j=1; j<width; j+=2) {
		jm5 = ((j-5) < 0) ? 0 : (j-5);		//use neighboring pixels to interpolate, but catch the out-of-bounds indexes
		jm3 = ((j-3) < 0) ? 0 : (j-3);		//note all of these 6 indexes must be even
		jm1 = ((j-1) < 0) ? 0 : (j-1);
		jp1 = ((j+1) > (width-2)) ? (width-2) : (j+1);
		jp3 = ((j+3) > (width-2)) ? (width-2) : (j+3);
		jp5 = ((j+5) > (width-2)) ? (width-2) : (j+5);
		u[i*width+j] = (159 * (u[i*width+jp1] + u[i*width+jm1]) - 52 * (u[i*width+jp3] + u[i*width+jm3]) + 21 * (u[i*width+jp5] + u[i*width+jm5]) + 128) >> 8;
		v[i*width+j] = (159 * (v[i*width+jp1] + v[i*width+jm1]) - 52 * (v[i*width+jp3] + v[i*width+jm3]) + 21 * (v[i*width+jp5] + v[i*width+jm5]) + 128) >> 8;
		
		//debug hook, uncomment and modify as needed
		/*
		if (i==0 && j==1) {	//i is what row, j is what column (output indexing, check for odd values of j)
			printf("upsampling debug on row %d, pixel %d\n", i, j);
			printf("source values for u:\n");
			printf("offset -5: %d (%x hex)\n", u[i*width+jm5], u[i*width+jm5]);
			printf("offset -3: %d (%x hex)\n", u[i*width+jm3], u[i*width+jm3]);
			printf("offset -1: %d (%x hex)\n", u[i*width+jm1], u[i*width+jm1]);
			printf("offset +1: %d (%x hex)\n", u[i*width+jp1], u[i*width+jp1]);
			printf("offset +3: %d (%x hex)\n", u[i*width+jp3], u[i*width+jp3]);
			printf("offset +5: %d (%x hex)\n", u[i*width+jp5], u[i*width+jp5]);
			printf("upsampled value is %d (%x hex)\n", u[i*width+j], u[i*width+j]);
		}
		*/
	}
	
	//color space conversion - overwrite Y with red, U with green, and V with blue
	for (i=0; i<height*width; i++) {
		y_val = y[i] - 16;
		u_val = u[i] - 128;
		v_val = v[i] - 128;
		y[i] = (76284 * y_val + 104595 * v_val) >> 16;					//red
		u[i] = (76284 * y_val - 25624 * u_val - 53281 * v_val) >> 16;	//green
		v[i] = (76284 * y_val + 132251 * u_val) >> 16;					//blue
		
		y[i] = (y[i] < 0) ? 0 : ((y[i] > 255) ? 255 : y[i]);			//clipping final result to 8 bits unsigned
		u[i] = (u[i] < 0) ? 0 : ((u[i] > 255) ? 255 : u[i]);
		v[i] = (v[i] < 0) ? 0 : ((v[i] > 255) ? 255 : v[i]);
		
		//debug hook, uncomment and modify as needed
		/*
		if (i==0) {	//i goes across picture then down, so row = i/width and column = i%width
			printf("color space conversion debug on pixel %d (row %d, column %d)\n", i, i/width, i%width);
			printf("incoming values (before subtraction):\n");
			printf("Y %d (%x hex)\n", y_val + 16, y_val + 16);	//undo the earlier -16
			printf("U %d (%x hex)\n", u_val + 128, u_val + 128);
			printf("V %d (%x hex)\n", v_val + 128, v_val + 128);
			printf("output values (after clipping):\n");
			printf("R %d (%x hex)\n", y[i], y[i]);
			printf("G %d (%x hex)\n", u[i], u[i]);
			printf("B %d (%x hex)\n", v[i], v[i]);
		}
		*/
	}
	
	//write RGB data to SRAM in the same format as PPM: {R0 G0}, {B0 R1}, {G1 B1}, etc.
	j = SRAM_RGB_out;	//sram write address, increments 3 times for every 2 pixels
	for (i=0; i<height*width; i+=2) {	//need to process 2 pixels (6 pieces of data) together, as two 8-bit values are packed in the same SRAM location
		sram[j++] = ((y[i] & 0xff) << 8) | (u[i] & 0xff);		//R0 on high byte, G0 on low byte
		sram[j++] = ((v[i] & 0xff) << 8) | (y[i+1] & 0xff);		//B0 on high byte, R1 on low byte
		sram[j++] = ((u[i+1] & 0xff) << 8) | (v[i+1] & 0xff);	//G1 on high byte, B1 on low byte
	}
	
	//open SRAM output file and write virtual sram to file
	file_ptr = fopen(output_filename, "wb");
	if (file_ptr==NULL) {
		printf("can't open file %s for binary writing, exiting...\n", output_filename);
		exit(1);
	}
	else printf("opened SRAM output file %s\n", output_filename);
	for (i=0; i<262144; i++) {
		fputc((sram[i]>>8) & 0xff, file_ptr);	//write high byte first
		fputc(sram[i] & 0xff, file_ptr);		//then low byte
	}
	fclose(file_ptr);
	
	//open PPM output file and write a ppm image
	file_ptr = fopen(output_filename2, "wb");
	if (file_ptr==NULL) {
		printf("can't open file %s for binary writing, exiting...\n", output_filename2);
		exit(1);
	}
	else printf("opened PPM output file %s\n", output_filename2);
    fprintf(file_ptr, "P6\n%d %d\n255\n", width, height);	//header
	for (i=0; i<height*width; i++) {
		fputc(y[i], file_ptr);	//red
		fputc(u[i], file_ptr);	//green
		fputc(v[i], file_ptr);	//blue
	}
	fclose(file_ptr);

	free(y);
	free(u);
	free(v);
	free(sram);
	printf("done :)\n");
	return 0;
}
