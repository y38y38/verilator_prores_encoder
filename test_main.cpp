#include <iostream>
#include <verilated.h>
//#include <verilated_fst_c.h> 
#include "Vwrapper.h"
#include "test_utility.h"
#include <math.h>



int time_counter = 0;
int encoder_main(int argc, char **argv);

int main(int argc, char** argv) {
	
	Verilated::commandArgs(argc, argv);

#if 1
	encoder_main(argc, argv);
	//printf("encode end\n");
//	return 0;
#endif

	int ret = init_param(argc, argv);
	if (ret <0) {
		return -1;
	}

	// Instantiate DUT
	Vwrapper *dut = new Vwrapper();
	// Trace DUMP ON
	Verilated::traceEverOn(true);
//	VerilatedFstC* tfp = new VerilatedFstC;

//	dut->trace(tfp, 100);  // Trace 100 levels of hierarchy
//	tfp->open("simx.fst");

	// Format
	init_test(dut);

	reset_test(dut);

	// Reset Time
	while (time_counter < 10) {
		toggle_clock(dut);
//		tfp->dump(time_counter);
		time_counter++;
	}
	// Release reset
	unreset_test(dut);
	//printf("loop\n");
	while (is_run(time_counter) && !Verilated::gotFinish()) {
//			printf("2 DcCoeff %d\n", dut->INPUT_DC_DATA);
//			printf("2 previousDCCoeff %d\n", dut->PREVIOUSDCOEFF);
		toggle_clock(dut);
//			printf("3 DcCoeff %d\n", dut->INPUT_DC_DATA);
//			printf("3 previousDCCoeff %d\n", dut->PREVIOUSDCOEFF);
		if (dut->CLOCK) {
//			printf("4 DcCoeff %d\n", dut->INPUT_DC_DATA);
//			printf("4 previousDCCoeff %d\n", dut->PREVIOUSDCOEFF);
			posedge_clock(dut);
		}
//			printf("5 DcCoeff %d\n", dut->INPUT_DC_DATA);
//			printf("5 previousDCCoeff %d\n", dut->PREVIOUSDCOEFF);
		// Evaluate DUT
		//printf("b dc_coeff %d\n", dut->INPUT_DC_DATA);
		dut->eval();
		//printf("a dc_coeff %d\n", dut->INPUT_DC_DATA);
		if (dut->CLOCK) {
//		printf("1 DcCoeff %d\n", dut->INPUT_DC_DATA);
//		printf("1 previousDCCoeff %d\n", dut->PREVIOUSDCOEFF);
			posedge_clock_result(dut);
		}
//		tfp->dump(time_counter);  // 波形ダンプ用の記述を追加
		time_counter++;
//return 0;
	}
//return 0;
	end_test(dut);
	dut->final();
//	tfp->close(); 
}