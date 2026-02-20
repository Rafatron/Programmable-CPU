#include <stdio.h>
#include <string.h>
#include "functions.c"
#include "directives.c"

#define FILELINES 1024
#define LINESIZE 20
#define REGSIZE 8
#define LIKENCOMMENTS 250

typedef struct {
    DIRECTIVE dir;
    int ARG1:8;
    int ARG2:4;
    int ARG3:4;
} COMMAND;

char FILENAME[100];
char file[FILELINES][LINESIZE+1]; //list containing all the file lines
void init() {for (int i = 0; i<FILELINES; i++) strcpy(file[i], "\0");} //initialized file

void readfile(char fn[100]);
void writefile();
COMMAND breakDirective(char in[LINESIZE+1]);

int main(int, char *argv[]) {
    init();
    readfile(argv[2]);
    writefile();
    puts("succesfully encoded");
    return 0;
}

COMMAND breakDirective(char in[LINESIZE+1]) {
    COMMAND * out = malloc(sizeof(COMMAND)); //makes pointer to COMMAND
    char strdir[4][REGSIZE+1] = {{0}};       // makes a string array to hold all inputs
    char * token = strtok(in, " ");          // tokens at " "

    for (int i = 0; i<4; i++) {              // for all of my 4 inputs
        if (token!=NULL) strcpy(strdir[i], token); //if token not null (have not reached end of line)
        else strcpy(strdir[i], "000");              // if end of line has been reached substitude with 0
        token = strtok(NULL, " ");                  // go to next argument
    }

    if      (!strcmp(strdir[0],  "ADD")) {out->dir= ADD;} //table to check the opcode necesary
    else if (!strcmp(strdir[0],  "SUB")) {out->dir= SUB;}
    else if (!strcmp(strdir[0],  "AND")) {out->dir= AND;}
    else if (!strcmp(strdir[0],   "OR")) {out->dir=  OR;}
    else if (!strcmp(strdir[0],  "XOR")) {out->dir= XOR;}
    else if (!strcmp(strdir[0],  "NOT")) {out->dir= NOT;}
    else if (!strcmp(strdir[0],  "MOV")) {out->dir= MOV;}
    else if (!strcmp(strdir[0],  "JMP")) {out->dir= JMP;}
    else if (!strcmp(strdir[0],  "JPN")) {out->dir= JPN;}
    else if (!strcmp(strdir[0], "JPNZ")) {out->dir=JPNZ;}
    else if (!strcmp(strdir[0],  "CMP")) {out->dir= CMP;}
    else if (!strcmp(strdir[0],  "NOP")) {out->dir= NOP;}
    else if (!strcmp(strdir[0], "LBSH")) {out->dir=LBSH;}
    else if (!strcmp(strdir[0], "RBSH")) {out->dir=RBSH;}
    else if (!strcmp(strdir[0], "DISP")) {out->dir=DISP;}
    else {out->dir=NOP;}

    out->ARG1 = atoi(strdir[1]); //numerical arguments
    out->ARG2 = atoi(strdir[2]);
    out->ARG3 = atoi(strdir[3]);


    return *out;
}

void readfile(char fn[100]) {
    strcpy(FILENAME, fn);

    FILE * in = fopen(FILENAME, "r");
    memcpy(FILENAME+strlen(FILENAME)-5, "\0", 1); //removing extension from filename by adding a terminator \0 where the . is this ensures it makes a .lc file with the same name as the .asmm file

    int i = 0;
    char line[LIKENCOMMENTS] = {0};
    char *index = NULL;
    while (fscanf(in, "%[^\n]\n", line)!=EOF) { //reads untill newline and cosumes it
        if(!strcmp(line,";")) strcpy(file[i], "NOP\0"); //if line is ';' (space) replace it with the NOP directive
        else {
            index = strchr(line, ';');              //pointer to the semicolon char
            *index='\0';                            //change semicolon to terminator
            strcpy(file[i], line);                  //copy line to file read
        }

        i++;
    }
}

void writefile() {
    sprintf(FILENAME, "%s.lc", FILENAME);
    FILE * output = fopen(FILENAME, "w");

    char buffer[100], opcode[5], arg1[9], arg2[5], arg3[5], argj[17];
    for(int i=0; strcmp(file[i], "EOF"); i++) {
        COMMAND out = breakDirective(file[i]);
        strcpy(opcode, ITS(out.dir, 4));
        strcpy(arg1, ITS(out.ARG1, 8));
        strcpy(arg2, ITS(out.ARG2, 4));
        strcpy(arg3, ITS(out.ARG3, 4));
        strcpy(argj, ITS(out.ARG1-1, 16));

        if (out.dir==JMP || out.dir==JPN || out.dir==JPNZ) {
            sprintf(buffer, "%s%s", opcode, argj);
        } else sprintf(buffer, "%s%s%s%s", opcode, arg1, arg2, arg3);

        fprintf(output, "%s\n", buffer);
    }
}