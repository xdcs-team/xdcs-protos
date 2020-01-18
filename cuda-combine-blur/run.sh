#!/bin/bash

nvcc -arch=sm_35 -rdc=true main.cu -o target/main

./target/main
