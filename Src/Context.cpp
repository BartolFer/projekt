module;

#include <cstdint>

export module Context;

namespace BJpeg {
	export struct Context {
		uint16_t restart_interval = 0;
		uint8_t precision = 8;
		uint8_t X, Y;
		
		HuffmanTable huffman_table;
		ArithmeticData arithmetic_data;
		QuantizationTable quantization_table;
	};
	export struct HuffmanTable {};
	export struct ArithmeticData {};
	export struct QuantizationTable {};
}