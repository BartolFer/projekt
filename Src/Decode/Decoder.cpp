depend("../FileBuffer.cpp", "../Markers.hpp", "../Context.cpp")
module;

#ifdef VSCODE_ONLY
	#include "../FileBuffer.cpp"
	#include "../Context.cpp"
	#include "./Huffman.cpp"
#endif

#include <cstdint>

#include "../Markers.hpp"

export module Context;

#ifndef VSCODE_ONLY
	import FileBuffer;
	import Context;
	import Decode.Huffman;
#endif

namespace BJpeg {
	#define DECODE_FUN_R(name) uint32_t name(Context& context, InputFileBuffer& file, uint32_t index)
	#define DECODE_FUN_V(name) uint32_t name(Context  context, InputFileBuffer& file, uint32_t index)

	#define CHECK_MARKER(marker) (                                \
		(file[index] == 0xFF && file[index + 1] == (marker))       \
		&& ((index += 2) || true)                                   \
	) // index += 2 only if above condition, but don't affect the result
	#define ASSERT_MARKER(marker) do { if (!CHECK_MARKER(marker)) { return DECODE_RESULT_ERR; } } while (0)
	#define CALL_DECODE(function) do {                 \
		result = ((function)(context, file, index));    \
		if (result == 0) { return result; }              \
		else { index = result; }                          \
	} while (0)
	#define TRY_CALL_DECODE(function)                     \
		result = ((function)(context, file, index));       \
		if (result != 0) { index = result; } // made for else after this
	
	#define DECODE_RESULT_OK  index
	#define DECODE_RESULT_ERR 0
	#define DECODE_READ_U16(var) do { (var) = DECODE_READ_U8; (var) <<= 8; var |= DECODE_READ_U8; } while (0)
	#define DECODE_READ_U8 (file[index++])
	#define DECODE_READ_U4(var1, var2) do { uint8_t var = DECODE_READ_U8; (var1) = var >> 4; (var2) = var & 0b1111; } while (0)
	
	
	DECODE_FUN_R(misc);
	DECODE_FUN_V(hierarchical);
	DECODE_FUN_V(frame);
	DECODE_FUN_V(scan);
	DECODE_FUN_R(mcu);
	
	export DECODE_FUN_V(image) {
		uint32_t result;
		ASSERT_MARKER(Marker :: SOI);
		CALL_DECODE(misc);
		if (file[index + 1] == Marker :: DHP) { CALL_DECODE(hierarchical); }
		else { CALL_DECODE(frame); }
		ASSERT_MARKER(Marker :: EOI);
		return DECODE_RESULT_OK;
	}
	
	// TODO
	DECODE_FUN_R(misc) {
		while (true) { // actually, while has something to read
			if (DECODE_READ_U8 != 0xFF) { return DECODE_RESULT_ERR; }
			uint8_t m = DECODE_READ_U8;
			uint16_t segment_length; DECODE_READ_U16(segment_length);
			switch (m) {
				case Marker :: DHT: {
					auto end_index = index + segment_length - 2;
					while (index < end_index) {
						uint8_t Tc, Th; DECODE_READ_U4(Tc, Th);
						HuffmanTree& huffman; // TODO get table ref
						huffman.reset();
						uint32_t const counts_start = index - 1; // because of 1-indexing
						uint32_t const values_start = index + 16;
						uint16_t code = 0;
						uint8_t value_index = 0;
						for (uint8_t length = 1; length <= 16; ++length) {
							uint8_t const count = file[counts_start + length];
							for (uint8_t i = 0; i < count; ++i) {
								uint8_t value = file[values_start + value_index];
								huffman.update(code, length, value);
								
								++code;
								++value_index;
							}
							code <<= 1;
						}
						index = values_start + value_index;
					}
				} break;
				case Marker :: DAC: {} break;
				case Marker :: DQT: {
					for (uint32_t end_index = index - 2 + segment_length; index < end_index; ) {
						uint8_t Pq, Tq; DECODE_READ_U4(Pq, Tq);
						// or just memcpy + index update
						for (uint8_t i = 0; i < 64; ++i) {
							if (Pq) { uint16_t q; DECODE_READ_U16(q); }
							else { DECODE_READ_U8; }
						}
					}
				} break;
				case Marker :: DRI: {
					DECODE_READ_U16(context.restart_interval);
				} break;
				case Marker :: COM: { index += segment_length - 2; } break;
				default: {
					if (Marker :: isAPP(m)) {
						index += segment_length - 2;
					} else {
						// not misc marker
						index -= 4;
					}
				} break;
			}
			return DECODE_RESULT_OK;
		}
	}
	// TODO
	DECODE_FUN_V(hierarchical);
	DECODE_FUN_V(frame) {
		uint32_t result;
		if (DECODE_READ_U8 != 0xFF) { return DECODE_RESULT_ERR; }
		// TODO
		switch (DECODE_READ_U8) {
			case Marker :: SOF0: {} break;
			case Marker :: SOF1: {} break;
			case Marker :: SOF2: {} break;
			case Marker :: SOF3: {} break;
			// case Marker :: SOF4: {} break; // doesn't exist
			case Marker :: SOF5: {} break;
			case Marker :: SOF6: {} break;
			case Marker :: SOF7: {} break;
			// case Marker :: SOF8: {} break; // doesn't exist
			case Marker :: SOF9: {} break;
			case Marker :: SOF10: {} break;
			case Marker :: SOF11: {} break;
			// case Marker :: SOF12: {} break; // doesn't exist
			case Marker :: SOF13: {} break;
			case Marker :: SOF14: {} break;
			case Marker :: SOF15: {} break;
		}
		uint16_t Lf; DECODE_READ_U16(Lf);
		context.precision = DECODE_READ_U8;
		DECODE_READ_U16(context.Y);
		DECODE_READ_U16(context.X);
		uint8_t Nf = DECODE_READ_U8;
		for (uint8_t i = 0; i < Nf; ++i) {
			uint8_t C = DECODE_READ_U8;
			uint8_t H, V; DECODE_READ_U4(H, V);
			uint8_t Tq = DECODE_READ_U8;
		}
		CALL_DECODE(misc);
		CALL_DECODE(scan); // at least 1 scan
		// DNL
		if (CHECK_MARKER(Marker :: DNL)) {
			uint16_t Ld; DECODE_READ_U16(Ld);
			uint16_t NL; DECODE_READ_U16(NL);
		}
		while (true) {
			CALL_DECODE(misc);
			TRY_CALL_DECODE(scan) else { return DECODE_RESULT_OK; }
		}
	}
	DECODE_FUN_V(scan) {
		uint32_t result;
		ASSERT_MARKER(Marker :: SOS);
		uint16_t Lf; DECODE_READ_U16(Lf);
		uint8_t  Ns = DECODE_READ_U8;
		for (uint8_t i = 0; i < Ns; ++i) {
			uint8_t Cs = DECODE_READ_U8;
			uint8_t Td, Ta; DECODE_READ_U4(Td, Ta);
		}
		uint8_t Ss = DECODE_READ_U8;
		uint8_t Se = DECODE_READ_U8;
		uint8_t Ah, Al; DECODE_READ_U4(Ah, Al);
		
		if (true /* TODO context.restart_interval */) {
			uint32_t rst = -1;
			do {
				rst = (rst + 1) & (8 - 1); // hardcoded 8
				for (uint32_t i = 0; /* i < context.restart_interval - 1 */; ++i) {
					TRY_CALL_DECODE(mcu) else { return DECODE_RESULT_OK; }
				}
			} while (CHECK_MARKER(Marker :: RST(rst)));
			return DECODE_RESULT_OK;
		} else {
			while (true) {
				TRY_CALL_DECODE(mcu) else { return DECODE_RESULT_OK; }
			}
		}
	}
	DECODE_FUN_R(mcu);
}