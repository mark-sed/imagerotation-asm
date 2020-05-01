/**
 * @file imagerotation.h
 * @author Marek Sedláček
 * @date February 2020
 * 
 * @brief Header file for imagerotation module
 * 
 * This code was made for my bachelor's thesis at
 * Brno University of Technology
 */

#ifndef _IMAGEROTATION_H_
#define _IMAGEROTATION_H_

#include <stdint.h> 

/**
 * Function for monochromatic image rotation by arbitrary angle
 * @param src source image
 * @param dst image to which will be rotated image saved
 * @param width width of the image
 * @param height height of the image
 * @param angle angle in radians by which the image will be rotated 
 */
void rotate_mc_image(uint8_t **src, uint8_t **dst, unsigned int width, unsigned int height, float angle);

#endif //_IMAGEROTATION_H_
