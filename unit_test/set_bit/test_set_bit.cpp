
#include <iostream>
#include <verilated.h>
#include "Vset_bit.h"



struct vals {
	uint32_t enable;
	uint32_t val;
	uint32_t size_of_bit;
	uint32_t flush_bit;
};
#if 0
struct vals test_data [] = {
{1, 0x260, 14, 0},
{1, 0x5a5a5a5a, 32, 0},
{1, 0x55, 		 8, 0},
{1, 0x55, 		 7, 0},
{1, 0x555, 		16, 0},

{1, 0x5a5a5a5a, 11, 0},
{1, 0x5a5a5a5a,  7, 0},
{1, 0x5a5a5a5a,  1, 0},
{1, 0x2,  2, 0},
{1, 0x5a5a5a5a,  1, 0},

{1, 0x2,  3, 0},
{1, 0x2,  2, 0},
{1, 0x0,  1, 0},
{1, 0x2,  2, 0},
{1, 0x2,  2, 1},
{1, 0x2,  2, 1},
};
#endif


#define TABLE_NUM	(32)
struct vals test_data [TABLE_NUM] = {
{1, 0x260, 14,0},
{1,0x2e, 8,0},
{1,0x3c, 8,0},
{1,0x3e, 8,0},
{1,0x99, 12,0},
{1,0x43, 10,0},
{1,0x60, 10,0},
{1,0x11, 6,0},
{1,0x17, 6,0},
{1,0xe, 4,0},
{1,0x5f, 10,0},
{1,0x1f, 6,0},
{1,0x5a, 10,0},
{1,0x28, 8,0},
{1,0x85, 12,0},
{1,0x35, 8,0},
{1,0x8, 4,0},
{1,0x1b, 9,0},
{1,0x2e, 8,0},
{1,0x29, 8,0},
{1,0x3e, 8,0},
{1,0xab, 12,0},
{1,0xd9, 12,0},
{1,0xb3, 12,0},
{1,0x32, 8,0},
{1,0xe, 4,0},
{1,0x19, 6,0},
{1,0x13, 6,0},
{1,0x17, 6,0},
{1,0x1c, 6,0},
{1,0x31, 8,0},
{1,0x1b, 6,0},
};

int main(int argc, char** argv) {
	int time_counter = 0;

	Verilated::commandArgs(argc, argv);

	Vset_bit *dut = new Vset_bit();
	// Trace DUMP ON
	Verilated::traceEverOn(true);

	// Format
	dut->reset_n = 0;
	dut->clock = 0;

	// Reset Time
	while (time_counter < 10) {
		dut->clock = !dut->clock; // Toggle clock
		dut->eval();
		time_counter++;
	}
	// Release reset
	dut->reset_n = 1;
	time_counter = 0;
	while (time_counter < TABLE_NUM && !Verilated::gotFinish()) {
		dut->clock = !dut->clock; // Toggle clock
		if (dut->clock) {
				dut->enable = 			test_data[time_counter%TABLE_NUM].enable;
				dut->val = 			test_data[time_counter%TABLE_NUM].val;
				dut->size_of_bit =  test_data[time_counter%TABLE_NUM].size_of_bit;
				dut->flush_bit =    test_data[time_counter%TABLE_NUM].flush_bit;
			time_counter++;
		}

		// Evaluate DUT
		dut->eval();
		if (dut->clock) {
			printf("enable %.016llx\n", dut->enable);
			printf("val %.016llx\n", dut->val);
			printf("size_of_bit %d\n", dut->size_of_bit);
			printf("flush_bit %llx\n", dut->flush_bit);
			printf("output_enable_byte %x\n", dut->output_enable_byte);
			printf("output_val %.016llx\n", dut->output_val);
			printf("tmp_buf_bit_offset %x\n", dut->tmp_buf_bit_offset);
			printf("tmp_bit %llx\n", dut->tmp_bit);
			printf("tmp_byte %llx\n", dut->tmp_byte);
			printf("-------------\n");
			
		}
//		time_counter++;
	}

	dut->final();
}