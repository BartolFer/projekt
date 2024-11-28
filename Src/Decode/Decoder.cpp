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
		if (file[index++] != 0xFF  ) { return DECODE_RESULT_ERR(index - 1); }   \
		if (file[index++] != marker) { return DECODE_RESULT_ERR(index - 1); }   \
	} while (false)
	// must have variables declared `DecodeResult result;` as well as `Decoder& decoder, InputFileBuffer& file, unsigned index` before call
	#define CALL_DECODE(function) do {          \
		result = (function(decoder, file, index));                    \
		if (!result.ok) { return result; }     \
		else { index = result.end_index; }     \
	} while (false)
	#define DECODE_RESULT_OK         (DecodeResult{index, true})
	#define DECODE_RESULT_ERR(index) (DecodeResult{(index), false})
	#define DECODE_FUN(name) DecodeResult name(Decoder& decoder, InputFileBuffer& file, unsigned index)
	
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
	DECODE_FUN(tables);
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
			if (file[index++] != 0xFF) { return DECODE_RESULT_ERR(index - 1); }
			switch (uint8_t m = file[index++]) {
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
	DECODE_FUN(hierarchical);
	DECODE_FUN(frame);
	DECODE_FUN(tables);
	DECODE_FUN(scan);
	DECODE_FUN(mcu);
}