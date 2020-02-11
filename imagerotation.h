#ifndef _IMAGEROTATION_H_
#define _IMAGEROTATION_H_

#include <stdint.h> 
typedef struct{
    uint8_t r;
    uint8_t g;
    uint8_t b;
    uint8_t a;
} TPixel;

void rotate_mc_image(uint8_t **src, uint8_t **dst, unsigned int width, unsigned int height, float angle);

#endif //_IMAGEROTATION_H_
