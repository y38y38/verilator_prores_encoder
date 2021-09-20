#ifndef __ENCODE_COMPONENT_H__
#define __ENCODE_COMPONENT_H__

uint32_t encode_slice_component_v(int16_t* y_pixel,int16_t* cb_pixel,int16_t* cr_pixel, uint8_t *y_matrix, uint8_t *c_matrix, uint8_t qscale, int block_num, struct bitstream *bitstream);

#endif


