depend("../FileBuffer.cpp", "../Markers.hpp")
module;

#ifdef VSCODE_ONLY
	#include "../FileBuffer.cpp"
#endif

#include "../Markers.hpp"

export module Decoder;

#ifndef VSCODE_ONLY
	import FileBuffer;
#endif

namespace BJpeg {
	#define ASSERT_MARKER(marker) do {                                          \
		if (DECODE_READ_U8 != 0xFF  ) { return DECODE_RESULT_ERR(index - 1); }   \
		if (DECODE_READ_U8 != marker) { return DECODE_RESULT_ERR(index - 1); }   \
	} while (false)
	// must have variables declared `DecodeResult result;` as well as `Decoder& decoder, InputFileBuffer& file, unsigned index` before call
	#define CALL_DECODE(function) do {          \
		result = (function(decoder, file, index));                    \
		if (!result.ok) { return result; }     \
		else { index = result.end_index; }     \
	} while (0)
	// must have variables declared `DecodeResult result;` as well as `Decoder& decoder, InputFileBuffer& file, unsigned index` before call
	#define TRY_CALL_DECODE(function) do {          \
		result = (function(decoder, file, index));                    \
		if (!result.ok) { result.ok = true; return result; }     \
		else { index = result.end_index; }     \
	} while (0)
	#define DECODE_RESULT_OK         (DecodeResult{index, true})
	#define DECODE_RESULT_ERR(index) (DecodeResult{(index), false})
	#define DECODE_FUN(name) DecodeResult name(Decoder& decoder, InputFileBuffer& file, unsigned index)
	#define DECODE_READ_U16(var) do { (var) = DECODE_READ_U8; (var) <<= 8; var |= DECODE_READ_U8; } while (0)
	#define DECODE_READ_U8 (file[index++])
	#define DECODE_READ_U4(var1, var2) do { uint8_t var = DECODE_READ_U8; (var1) = var >> 4; (var2) = var & 0b1111; } while (0)
	
	export struct DecodeResult {
		unsigned end_index;
		bool ok;
		
		// just an idea
		// static DecodeResult Ok (unsigned index) { return DecodeResult{index, true}; }
		// static DecodeResult Err(unsigned index) { return DecodeResult{index, false}; }
	};
	
	export struct Decoder {};
	
	DECODE_FUN(tables);
	DECODE_FUN(hierarchical);
	DECODE_FUN(frame);
	DECODE_FUN(scan);
	DECODE_FUN(mcu);
	
	export DECODE_FUN(image) {
		DecodeResult result;
		ASSERT_MARKER(Marker :: SOI);
		CALL_DECODE(tables);
		if (file[index + 1] == Marker :: DHP) { CALL_DECODE(hierarchical); }
		else { CALL_DECODE(frame); }
		ASSERT_MARKER(Marker :: EOI);
		return DECODE_RESULT_OK;
	}
	
	// TODO
	DECODE_FUN(tables) {
		while (true) { // actually, while has something to read
			if (DECODE_READ_U8 != 0xFF) { return DECODE_RESULT_ERR(index - 1); }
			switch (uint8_t m = DECODE_READ_U8) {
				case Marker :: DHT: {} break;
				case Marker :: DAC: {} break;
				case Marker :: DQT: {} break;
				case Marker :: DRI: {} break;
				case Marker :: COM: {} break;
				default: {
					if (Marker :: isAPP(m)) {
						
					} else {
						// nothing to read
						index -= 2;
						return DECODE_RESULT_OK;
					}
				} break;
			}
		}
	}
	// TODO
	DECODE_FUN(hierarchical);
	DECODE_FUN(frame) {
		DecodeResult result;
		if (DECODE_READ_U8 != 0xFF) { return DECODE_RESULT_ERR(index - 1); }
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
		uint8_t  P = DECODE_READ_U8;
		uint16_t Y; DECODE_READ_U16(Y);
		uint16_t X; DECODE_READ_U16(X);
		uint8_t  Nf = DECODE_READ_U8;
		for (uint8_t i = 0; i < Nf; ++i) {
			uint8_t C = DECODE_READ_U8;
			uint8_t H, V; DECODE_READ_U4(H, V);
			uint8_t Tq = DECODE_READ_U8;
		}
		CALL_DECODE(tables);
		CALL_DECODE(scan); // at least 1 scan
		// DNL
		if (file[index] == 0xFF && file[index + 1] == Marker :: DNL) {
			index += 2;
			uint16_t Ld; DECODE_READ_U16(Ld);
			uint16_t NL; DECODE_READ_U16(NL);
		}
		while (true /* exits when scan fails */) {
			CALL_DECODE(tables);
			TRY_CALL_DECODE(scan);
		}
	}
	DECODE_FUN(scan);
	DECODE_FUN(mcu);
}