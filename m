rm -rf obj_dir
#verilator --cc  --exe  --trace-fst --trace-params --trace-structs --trace-underscore  -CFLAGS -DDEBUG -LDFLAGS -lpthread \
verilator --cc  --exe   \
	-Ivlc -Idct -Iquantization -Ibitstream -Iconfig -Isequencer -Imem -Iheader \
	-CFLAGS -DDEBUG -LDFLAGS -lpthread \
    wrapper.sv \
	-exe test_main.cpp \
	test_utility.cpp \
	encode_component.c \
	encoder_main.c \
	bitstream.c \
	dct.c \
	debug.c \
	frame.c \
	slice.c \
	vlc.c

make -C obj_dir -f Vwrapper.mk

