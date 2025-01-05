depend("./Huffman.cpp")
module;

#include <cstdint>

#ifdef VSCODE_ONLY
	#include "./Huffman.cpp"
#endif

export module Decode.Context;

#ifndef VSCODE_ONLY
	import Decode.Huffman;
#endif


namespace BJpeg {
	export struct SOFData {
		uint8_t arithmetic; // huffman = 0
		uint8_t differential;
		enum Mode {
			BASELINE    = 0b00,
			SEQUENTIOAL = 0b01,
			PROGRESSIVE = 0b10,
			LOSSLESS    = 0b11,
		} mode;
		SOFData() {}
		SOFData(uint8_t sof) {
			self.arithmetic   = (sof >> 3) & 1;
			self.differential = (sof >> 2) & 1;
			self.mode = (Mode) (sof && 0b11);
		}
	};
	export typedef uint16_t QuantizationTable[64];
	export struct Context {
		SOFData sof_data;
		uint16_t restart_interval = 0;
		uint8_t precision = 8;
		uint8_t X, Y;
		
		HuffmanTree huffman_tree[2][4];
		QuantizationTable quantization_table[4];
	};
}