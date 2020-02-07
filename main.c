#include "imagerotation.h"
#include <stdlib.h>
#include <stdio.h>
#include <math.h>

#ifndef M_PI
#define M_PI 3.14159265358979323846264338327950288419716939937510582097494459230781640628620899862803482534211706798214808651e+00
#endif
#define DEG2RAD(deg) ((deg) * M_PI / 180.0)

int main(int argc, char *argv[]){
#define WIDTH 40
#define HEIGHT 40
    uint8_t **img;
    uint8_t **dimg;
    img = malloc(WIDTH * sizeof(uint8_t *));
    dimg = malloc(WIDTH * sizeof(uint8_t *));
    for(long i = 0; i < WIDTH; i++){
        img[i] = malloc(HEIGHT * sizeof(uint8_t));
        dimg[i] = malloc(WIDTH * sizeof(uint8_t));
    }


    for(int x = 0; x < WIDTH/2; x++){
        for(int y = 0; y < HEIGHT; y++){
            img[x][y] = 1;
        }
    }

    rotate_mc_image(img, dimg, WIDTH, HEIGHT, DEG2RAD(90));

    for(int x = 0; x < WIDTH; x++){
        for(int y = 0; y < HEIGHT; y++){
            printf("%c ", img[x][y] ? 'o' : '_');
        }
        printf("\n");
    }


    printf("\n");

    for(int x = 0; x < WIDTH; x++){
        for(int y = 0; y < HEIGHT; y++){
            printf("%c ", dimg[x][y] ? 'o' : '_');
        }
        printf("\n");
    }

    for(long i = 0; i < WIDTH; i++){
        free(img[i]);
        free(dimg[i]);
    }
    free(img);
    free(dimg);
    return 0;
}

