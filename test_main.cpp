#include <iostream>
#include <verilated.h>
#include <verilated_fst_c.h> 
#include "Vwrapper.h"
#include "test_utility.h"
#include <math.h>



int time_counter = 0;
int encoder_main(int argc, char **argv);

int main(int argc, char** argv) {
	
	Verilated::commandArgs(argc, argv);

#if 1
	encoder_main(argc, argv);
	printf("encode end\n");
	return 0;
#endif

	int ret = init_param(argc, argv);
	if (ret <0) {
		return -1;
	}

	// Instantiate DUT
	Vwrapper *dut = new Vwrapper();
	// Trace DUMP ON
	Verilated::traceEverOn(true);
	VerilatedFstC* tfp = new VerilatedFstC;

	dut->trace(tfp, 100);  // Trace 100 levels of hierarchy
	tfp->open("simx.fst");

	// Format
	init_test(dut);

	reset_test(dut);

	// Reset Time
	while (time_counter < 10) {
		toggle_clock(dut);
		tfp->dump(time_counter);
		time_counter++;
	}
	// Release reset
	unreset_test(dut);

	while (time_counter < 74 && !Verilated::gotFinish()) {
		toggle_clock(dut);
		if (dut->CLOCK) {
			posedge_clock(dut);
		}
		// Evaluate DUT
		dut->eval();
		if (dut->CLOCK) {
			posedge_clock_result(dut);
		}
		tfp->dump(time_counter);  // 波形ダンプ用の記述を追加
		time_counter++;

	}

	end_test(dut);
	dut->final();
	tfp->close(); 
}