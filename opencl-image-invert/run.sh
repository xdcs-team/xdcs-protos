#!/bin/bash

echo "Compiling the program"
gcc main.c -lOpenCL -o main
./main
