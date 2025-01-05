depend("../FileBuffer.cpp", "./Context.cpp")
module;

// #ifdef VSCODE_ONLY
// 	#include "../FileBuffer.cpp"
// 	#include "./Context.cpp"
// 	#include "./Huffman.cpp"
// #endif

#include <iostream>
#include <cstdint>

// #include "../Markers.hpp"

export module Decode;

#ifndef VSCODE_ONLY
	import FileBuffer;
	import Decode.Context;
	import Decode.Huffman;
#endif
		// int printf(const char *__format, ...);

namespace BJpeg {
	#define DECODE_FUN(name) uint32_t name(Context& context, InputFileBuffer& file, uint32_t index)

	// #define CHECK_MARKER(marker) (                                \
	// 	(file[index] == 0xFF && file[index + 1] == (marker))       \
	// 	&& ((index += 2) || true)                                   \
	// ) // index += 2 only if above condition, but don't affect the result
	// #define ASSERT_MARKER(marker) do { if (!CHECK_MARKER(marker)) { return DECODE_RESULT_ERR; } } while (0)
	// #define CALL_DECODE(function) do {                 \
	// 	result = ((function)(context, file, index));    \
	// 	if (result == 0) { return result; }              \
	// 	else { index = result; }                          \
	// } while (0)
	// #define TRY_CALL_DECODE(function)                     \
	// 	result = ((function)(context, file, index));       \
	// 	if (result != 0) { index = result; } // made for else after this
	
	#define DECODE_RESULT_OK  index
	// #define DECODE_RESULT_ERR 0
	// #define DECODE_READ_U16(var) do { (var) = DECODE_READ_U8; (var) <<= 8; var |= DECODE_READ_U8; } while (0)
	// #define DECODE_READ_U8 (file[index++])
	// #define DECODE_READ_U4(var1, var2) do { uint8_t var = DECODE_READ_U8; (var1) = var >> 4; (var2) = var & 0b1111; } while (0)
	
	// namespace {
	// 	DECODE_FUN(misc);
	// 	DECODE_FUN(hierarchical);
	// 	DECODE_FUN(frame);
	// 	DECODE_FUN(scan);
	// 	DECODE_FUN(mcu);
	// }
	
	export int image(Context& context, InputFileBuffer& file, unsigned index) {
		return 0;
	}
	// export DECODE_FUN(image) {
	// 	// printf("a\n");
	// 	uint32_t result;
	// 	ASSERT_MARKER(Marker :: SOI);
	// 	CALL_DECODE(misc);
	// 	if (file[index + 1] == Marker :: DHP) { CALL_DECODE(hierarchical); }
	// 	else { CALL_DECODE(frame); }
	// 	ASSERT_MARKER(Marker :: EOI);
	// 	return DECODE_RESULT_OK;
	// }
	
	// namespace {
	// 	DECODE_FUN(misc) {
	// 		while (true) { // actually, while has something to read
	// 			if (DECODE_READ_U8 != 0xFF) { return DECODE_RESULT_ERR; }
	// 			uint8_t m = DECODE_READ_U8;
	// 			uint16_t segment_length; DECODE_READ_U16(segment_length);
	// 			switch (m) {
	// 				case Marker :: DHT: {
	// 					auto end_index = index + segment_length - 2;
	// 					while (index < end_index) {
	// 						uint8_t table_class, table_dest; DECODE_READ_U4(table_class, table_dest);
	// 						if (table_class > 1 || table_dest > 3) { return DECODE_RESULT_ERR; }
	// 						HuffmanTree& huffman = context.huffman_tree[table_class][table_dest];
	// 						huffman.reset();
	// 						uint32_t const counts_start = index - 1; // because of 1-indexing
	// 						uint32_t const values_start = index + 16;
	// 						uint16_t code = 0;
	// 						uint8_t value_index = 0;
	// 						for (uint8_t length = 1; length <= 16; ++length) {
	// 							uint8_t const count = file[counts_start + length];
	// 							for (uint8_t i = 0; i < count; ++i) {
	// 								uint8_t value = file[values_start + value_index];
	// 								huffman.update(code, length, value);
									
	// 								++code;
	// 								++value_index;
	// 							}
	// 							code <<= 1;
	// 						}
	// 						index = values_start + value_index;
	// 					}
	// 				} break;
	// 				case Marker :: DAC: {
	// 					// not implemented
	// 					index += segment_length - 2;
	// 				} break;
	// 				case Marker :: DQT: {
	// 					for (uint32_t end_index = index - 2 + segment_length; index < end_index; ) {
	// 						uint8_t Pq, Tq; DECODE_READ_U4(Pq, Tq);
	// 						if (Tq > 3) { return DECODE_RESULT_ERR; }
	// 						uint16_t* table = context.quantization_table[Tq];
	// 						// or just memcpy + index update // but not actually (it complicates things, but is done once per image (not worth it))
	// 						if (Pq == 0) { for (uint8_t i = 0; i < 64; ++i) { table[i] = DECODE_READ_U8; } } 
	// 						else         { for (uint8_t i = 0; i < 64; ++i) { DECODE_READ_U16(table[i]); } }
	// 					}
	// 				} break;
	// 				case Marker :: DRI: {
	// 					DECODE_READ_U16(context.restart_interval);
	// 				} break;
	// 				case Marker :: COM: { index += segment_length - 2; } break;
	// 				default: {
	// 					if (Marker :: isAPP(m)) {
	// 						index += segment_length - 2;
	// 					} else {
	// 						// not a misc marker
	// 						index -= 4;
	// 					}
	// 				} break;
	// 			}
	// 			return DECODE_RESULT_OK;
	// 		}
	// 	}
	// 	DECODE_FUN(hierarchical) {
	// 		/// std :: cerr << "Hierarchical mode not supported\n";
	// 		return DECODE_RESULT_ERR;
	// 		uint32_t result;
	// 		ASSERT_MARKER(Marker :: DHP);
	// 		uint16_t Lf; DECODE_READ_U16(Lf);
	// 		context.precision = DECODE_READ_U8;
	// 		DECODE_READ_U16(context.Y);
	// 		DECODE_READ_U16(context.X);
	// 		uint8_t Nf = DECODE_READ_U8;
	// 		for (uint8_t i = 0; i < Nf; ++i) {
	// 			uint8_t C = DECODE_READ_U8;
	// 			uint8_t H, V; DECODE_READ_U4(H, V);
	// 			uint8_t Tq = DECODE_READ_U8;
	// 		}
	// 		while (true) {
	// 			CALL_DECODE(misc);
	// 			if (CHECK_MARKER(Marker :: EXP)) {
	// 				uint16_t Le; DECODE_READ_U16(Le);
	// 				uint8_t Eh, Ev; DECODE_READ_U4(Eh, Ev);
	// 			}
	// 			TRY_CALL_DECODE(frame) else { return DECODE_RESULT_OK; }
	// 		}
	// 	}
	// 	DECODE_FUN(frame) {
	// 		uint32_t result;
	// 		if (DECODE_READ_U8 != 0xFF) { return DECODE_RESULT_ERR; }
	// 		// TODO
	// 		uint8_t marker = DECODE_READ_U8;
	// 		if (!Marker :: isSOF(marker)) { return DECODE_RESULT_ERR; }
	// 		context.sof_data = SOFData(marker);
	// 		uint16_t Lf; DECODE_READ_U16(Lf);
	// 		context.precision = DECODE_READ_U8;
	// 		DECODE_READ_U16(context.Y);
	// 		DECODE_READ_U16(context.X);
	// 		uint8_t Nf = DECODE_READ_U8;
	// 		for (uint8_t i = 0; i < Nf; ++i) {
	// 			uint8_t C = DECODE_READ_U8;
	// 			uint8_t H, V; DECODE_READ_U4(H, V);
	// 			uint8_t Tq = DECODE_READ_U8;
	// 		}
	// 		CALL_DECODE(misc);
	// 		CALL_DECODE(scan); // at least 1 scan
	// 		// DNL
	// 		if (CHECK_MARKER(Marker :: DNL)) {
	// 			/// std :: cerr << "DNL not supported\n";
	// 			return DECODE_RESULT_ERR;
	// 			uint16_t Ld; DECODE_READ_U16(Ld);
	// 			uint16_t NL; DECODE_READ_U16(NL);
	// 		}
	// 		while (true) {
	// 			CALL_DECODE(misc);
	// 			TRY_CALL_DECODE(scan) else { return DECODE_RESULT_OK; }
	// 		}
	// 	}
	// 	#define DBG_BUFFER_LEN (4000 * 2200)
	// 	// static auto dbg_buffer = new uint8_t[DBG_BUFFER_LEN];
	// 	DECODE_FUN(scan) {
	// 		uint32_t result;
	// 		ASSERT_MARKER(Marker :: SOS);
	// 		uint16_t Lf; DECODE_READ_U16(Lf);
	// 		uint8_t  Ns = DECODE_READ_U8;
	// 		for (uint8_t i = 0; i < Ns; ++i) {
	// 			uint8_t Cs = DECODE_READ_U8;
	// 			uint8_t Td, Ta; DECODE_READ_U4(Td, Ta);
	// 		}
	// 		uint8_t Ss = DECODE_READ_U8;
	// 		uint8_t Se = DECODE_READ_U8;
	// 		uint8_t Ah, Al; DECODE_READ_U4(Ah, Al);
			
			
	// 		/// static FILE* dbg_file = fopen("D:/temp/scan_data.bin", "wb");
	// 		for (int i = 0; i < DBG_BUFFER_LEN; ) {
	// 			uint8_t x = DECODE_READ_U8;
	// 			if (x == 0xFF) {
	// 				uint8_t marker = DECODE_READ_U8;
	// 				if (marker == 0x00) {
	// 					// goto normal_flow;
	// 				} else if (Marker :: isRST(marker)) {
	// 					continue;
	// 				} else {
	// 					index -= 2;
	// 					return DECODE_RESULT_OK;
	// 				}
	// 			}
	// 			/// fwrite(&x, 1, 1, dbg_file);
	// 			// dbg_buffer[i++] = x;
	// 		}
	// 		// if (context.restart_interval) {
	// 		// 	uint32_t rst = -1;
	// 		// 	do {
	// 		// 		rst = (rst + 1) & (8 - 1); // hardcoded 8
	// 		// 		for (uint32_t i = 0; i < context.restart_interval - 1; ++i) {
	// 		// 			TRY_CALL_DECODE(mcu) else { return DECODE_RESULT_OK; }
	// 		// 		}
	// 		// 	} while (CHECK_MARKER(Marker :: RST(rst)));
	// 		// 	TRY_CALL_DECODE(mcu) else { return DECODE_RESULT_OK; }
	// 		// 	return DECODE_RESULT_OK;
	// 		// } else {
	// 		// 	while (true) {
	// 		// 		TRY_CALL_DECODE(mcu) else { return DECODE_RESULT_OK; }
	// 		// 	}
	// 		// }
	// 		return DECODE_RESULT_OK;
	// 	}
	// 	DECODE_FUN(mcu);
	// }
}