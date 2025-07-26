#include "./inner/Util.hpp"
#include "./inner/MyOpenCL.hpp"
#include "./inner/JpegTypes.hpp"
#include "./inner/Decode/FileBuffer.hpp"
#include "./inner/Decode/Context.hpp"
#include "./inner/Encode/Huffman.hpp"
#include "./inner/Encode/ClContext.hpp"

namespace BJpeg {
	namespace Decode {
		u32 image(Context& context, InputFileBuffer& file, u32 index);
	}
	namespace Encode {
		ArrayWithLength<u8> image(MyOpenCL :: Buffer<RGBA> image, CLContext cl, size_t height, size_t width, QuantizationTable qtables[4], HuffmanTable htables[2][4], SamplingFactor sampling_factors[MAX_COMPONENTS]);
	}
}
