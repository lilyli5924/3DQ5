//coded by Jason Thong for COE3DQ5 2019
//compare 2 ppm files, compute the PSNR

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

int main(int argc, char **argv) {
	double PSNR;
	int temp_int1, temp_int2;
	unsigned int px_count, err;
	char input_filename1[200], input_filename2[200], temp_string1[100], temp_string2[100];
	FILE *file_ptr1, *file_ptr2;
	
	//get first input file name either from first command line argument or from the user interface (command prompt)
	if (argc<2) {
		printf("enter the first input file name including the .ppm extension: ");
		gets(input_filename1);
	}
	else strcpy(input_filename1, argv[1]);
	
	//open first input file
	file_ptr1 = fopen(input_filename1, "rb");
	if (file_ptr1==NULL) {
		printf("can't open file %s for binary reading, exiting...\n", input_filename1);
		exit(1);
	}
	else printf("opened input file %s\n", input_filename1);
	
	//get second input file name either from second command line argument or from the user interface (command prompt)
	if (argc<3) {
		printf("enter the second input file name including the .ppm extension: ");
		gets(input_filename2);
	}
	else strcpy(input_filename2, argv[2]);
	
	//open second input file
	file_ptr2 = fopen(input_filename2, "rb");
	if (file_ptr2==NULL) {
		printf("can't open file %s for binary reading, exiting...\n", input_filename2);
		exit(1);
	}
	else printf("opened input file %s\n", input_filename2);
	
	//compare headers
	fscanf(file_ptr1, "%s", temp_string1);	//image type supposed to by P6
	fscanf(file_ptr2, "%s", temp_string2);
	if (strcmp(temp_string1, temp_string2)!=0) { printf("mismatch in header, image types are different, exiting...\n"); exit(1); }
	fscanf(file_ptr1, "%d", &temp_int1);	//width
	fscanf(file_ptr2, "%d", &temp_int2);
	if (strcmp(temp_string1, temp_string2)!=0) { printf("mismatch in header, widths are different %d %d, exiting...\n", temp_int1, temp_int2); exit(1); }
	fscanf(file_ptr1, "%d", &temp_int1);	//height
	fscanf(file_ptr2, "%d", &temp_int2);
	if (strcmp(temp_string1, temp_string2)!=0) { printf("mismatch in header, heights are different %d %d, exiting...\n", temp_int1, temp_int2); exit(1); }
	fscanf(file_ptr1, "%s", temp_string1);	//max number of colors supposed to by 255
	fscanf(file_ptr2, "%s", temp_string2);
	if (strcmp(temp_string1, temp_string2)!=0) { printf("mismatch in header, max num of colors are different, exiting...\n"); exit(1); }
	if (fgetc(file_ptr1)!=fgetc(file_ptr2)) { printf("mismatch in header, supposed to be a new line character, exiting...\n"); exit(1); }
	
	//compare image data
	px_count = 0;
	err = 0;
	temp_int1 = fgetc(file_ptr1);
	temp_int2 = fgetc(file_ptr2);
	while (temp_int1!=EOF && temp_int2!=EOF) {
		px_count++;
		temp_int1 -= temp_int2;			//difference
		err += temp_int1 * temp_int1;	//sum of squared error
		temp_int1 = fgetc(file_ptr1);	//load next values
		temp_int2 = fgetc(file_ptr2);
	}
	if (temp_int1!=EOF || temp_int2!=EOF) {
		printf("files are of different length, exiting...\n");
		exit(1);
	}
	
	//close files
	fclose(file_ptr1);
	fclose(file_ptr2);
	
	if (err==0) printf("files are identical\n");
	else {
		PSNR = sqrt(((double)err) / px_count);	//at this point this is the root mean squared error
		PSNR = 20.0 * log10(255.0 / PSNR);
		printf("PSNR: %lf, compared %d pixels\n", PSNR, px_count);
	}
	return 0;
}
