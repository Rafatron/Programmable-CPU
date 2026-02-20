#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

#define ROMLINES 1024 //numbers of lines in rom
#define DIRSIZE 20 //how big the directives are

int STI(char * string) { //handy for turning bit-string into integers
    int length = strlen(string);
    int sum = 0;
    for (int i = 0; i<length; i++) sum += string[length-1-i]=='0' ? 0 : pow(2,i);
    return sum;
}

char * ITS(int num, int bits) { //int to string (bit)
    char * string = calloc(bits+1, sizeof(char));
    for (int i = 0; i < bits; i++) {
        // Extract the bit at position (numBits - 1 - i) to ensure MSB comes first
        string[i] = ((num >> (bits - 1 - i)) & 1) +'0'; //moving the bit-string checking the last bit each time 10(1010)->1->10->101->1010
    }

    return string;
}

void DECDIR(char * string, int * OPCODE, int * ARGVAL, int * ARGREG_1, int * ARGREG_2, int * ARGJ) { //reads 20 bit long directives and breaks them down
    char OPCODE_STR[5]   = {0};
    char ARGVAL_STR[9]   = {0};
    char ARGREG_1_STR[5] = {0};
    char ARGREG_2_STR[5] = {0};
    char JMP_STR[17]     = {0};

    memcpy(OPCODE_STR, string, 4);
    memcpy(ARGVAL_STR, string+4, 8);
    memcpy(ARGREG_1_STR, string+12, 4);
    memcpy(ARGREG_2_STR, string+16, 4);
    memcpy(JMP_STR, string+4, 16);

    *OPCODE = STI(OPCODE_STR);
    *ARGVAL = STI(ARGVAL_STR);
    *ARGREG_1 = STI(ARGREG_1_STR);
    *ARGREG_2 = STI(ARGREG_2_STR);
    *ARGJ = STI(JMP_STR);
}

void readProgram(char ROM[ROMLINES][DIRSIZE+1], char * filename) {
    FILE * in = fopen(filename, "r");
    if (in==NULL) puts("FILE NOT FOUND OR COULD NOT BE OPENED");

    int i = 0;
    char line[21];
    while (fscanf(in, "%s", line)!=EOF) {
        strcpy(ROM[i], line);
        i++;
    }
}