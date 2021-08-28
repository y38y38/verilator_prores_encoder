#ifndef __ENCODE_COMPONENT_H__
#define __ENCODE_COMPONENT_H__

uint32_t encode_slice_component_v(int16_t* pixel, uint8_t *matrix, uint8_t qscale, int block_num, struct bitstream *bitstream);

#endif


