/**
 * @file main.c
 * @author Marek Sedláček
 * @date February 2020
 * 
 * @brief Program for testing performance of image rotation algorithm
 * 
 * This code was made for my bachelor's thesis at
 * Brno University of Technology
 */

#include "imagerotation.h"
#include <stdlib.h>
#include <stdio.h>
#include <math.h>

#ifndef M_PI
// PI (Taken from boost library)
// https://www.boost.org/doc/libs/1_56_0/boost/math/constants/constants.hpp
#define M_PI 3.14159265358979323846264338327950288419716939937510582097494459230781640628620899862803482534211706798214808651e+00
#endif
#define DEG2RAD(deg) ((deg) * M_PI / 180.0)

int main(int argc, char *argv[]){
#define WIDTH 3840
#define HEIGHT 2160
    uint8_t **img;
    uint8_t **dimg;
    img = malloc(WIDTH * sizeof(uint8_t *));
    dimg = malloc(WIDTH * sizeof(uint8_t *));
    for(long i = 0; i < WIDTH; i++){
        img[i] = malloc(HEIGHT * sizeof(uint8_t));
        dimg[i] = malloc(WIDTH * sizeof(uint8_t));
    }

    rotate_mc_image(img, dimg, WIDTH, HEIGHT, DEG2RAD(42));

    for(long i = 0; i < WIDTH; i++){
        free(img[i]);
        free(dimg[i]);
    }
    free(img);
    free(dimg);
    return 0;
}

