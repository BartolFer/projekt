typedef uchar  u8;
typedef ushort u16;
typedef uint   u32;
typedef ulong  u64;
typedef uint2  u32x2;
typedef char  i8;
typedef short i16;
typedef int   i32;
typedef long  i64;
typedef int2  i32x2;

typedef struct {
	u16 left;
	u16 right_or_data;
} HuffmanTreeNode;
typedef HuffmanTreeNode HuffmanTree[256 + 255 + 1];
typedef ushort2 u16Pair;
typedef uchar2 u8Pair;
u8Pair decodeHuffman(__constant HuffmanTree huf, u16 code) {
	u16 index = 0;
	HuffmanTreeNode node = huf[0];
	u8 res_depth = 0;
	__attribute__((opencl_unroll_hint(16)))
	for (u8 depth = 0; depth < 16; ++depth) {
		if (node.left != 0) {
			index = (code >> 15) == 0 ? node.left : node.right_or_data;
			node = huf[index];
			code <<= 1;
			++res_depth;
		}
	}
	if (node.left != 0) {
		++res_depth; // = 17
	}
	return (u8Pair) {res_depth, (u8)node.right_or_data};
}

#define LANE_ERROR_VALUE UINT_MAX
typedef struct {
	u8 c_id;
	u8 dc_huf;
	u8 ac_huf;
	u8 y;
	u8 x;
	u8 _6;
	u8 _7;
	u8 _8;
} LaneInfo;

#define MAX_COMPONENTS 4
typedef struct {
	// commputation
	u16 predictor;
	// from frame header
	u8 sampling_factor_x;
	u8 sampling_factor_y;
	u8 quantization_table;
	// from scan header
	u8 dc_entropy_table;
	u8 ac_entropy_table;
	u8 _padding;
} ComponentData;

#define READ_3B (0U                            \
	| ((u32) payload[B + 0] << 020)            \
	| ((u32) payload[B + 1] << 010)            \
	| ((u32) payload[B + 2] << 000)            \
)

// started as [Ns][bb2 - b1]
kernel void decodeHuffman1(
	__global u8 payload[], 
	u32 B2, 
	__constant HuffmanTree trees[2][4], 
	__constant LaneInfo lane_infos[], 
	__global u32 lanes[], 
	u32 lane_width, 
	__constant u8 lane_indexes[]
) {
	u8  C = get_global_id(0);
	u32 i = get_global_id(1);
	u32 bbi = i;
	u32 bb = bbi;
	
	u8 lane_id = lane_indexes[C];
	LaneInfo lane_info = lane_infos[lane_id];
	u32 lane_index = lane_id * lane_width + i;
	__constant HuffmanTreeNode* huf_dc = trees[0][lane_info.dc_huf];
	__constant HuffmanTreeNode* huf_ac = trees[1][lane_info.ac_huf];
	#pragma region DC
		u32 B = bb >> 3;
		u32 b = bb & 7;
		if (B >= B2) {
			lanes[lane_index] = LANE_ERROR_VALUE;
			return;
		}
		// u16 code word = a<<(b1+8) | b<<b1 | c<<(b1-8)
		//    .b
		// aaaaaaaa aaaaaaaa aaaaaaaa
		u16 code = READ_3B >> (8 - b);
		u8Pair d_s = decodeHuffman(huf_dc, code);
		if (d_s.x == 17) {
			lanes[lane_index] = LANE_ERROR_VALUE;
			return;
		}
		bb += d_s.x + d_s.y;
	#pragma endregion
	
	#pragma region AC
		for (int ac_count = 0; ac_count < 63; ) {
			u32 B = bb >> 3;
			u32 b = bb & 7;
			if (B >= B2) {
				lanes[lane_index] = LANE_ERROR_VALUE;
				return;
			}
			// u16 code word = a<<(b1+8) | b<<b1 | c<<(b1-8)
			u16 code = READ_3B >> (8 - b);
			u8Pair d_s = decodeHuffman(huf_ac, code);
			if (d_s.x == 17) {
				lanes[lane_index] = LANE_ERROR_VALUE;
				return;
			}
			if (d_s.y == 0x00) {
				// rest are 0
				ac_count = 63;
			// } else if (d_s.y == 0xF0) {
			// 	// next 16 are 0
			// 	ac_count += 16;
			} else {
				u8 RRRR = d_s.y >> 4;
				ac_count += RRRR + 1;
			}
			bb += d_s.x + (d_s.y & 0x0F);
		}
	#pragma endregion
	lanes[lane_index] = bb - bbi;
}
// on 2^n-th level start only every gcd(HV, 2^n) unit
// though i don't need gcd, it is surelly 2^k (k<n). So start at 1(2) and double if divisible
// where HV = sum(H*V)

// started as [X][bb2 - b1]
kernel void decodeRaise(
	__global u32 lanes[], 
	u32 lane_width, 
	u8 lanes_count, 
	u8 prev_size_pow
) {
	u8  x = get_global_id(0);
	u32 i = get_global_id(1);
	u8  lane_id = x * (1U << (prev_size_pow + 1)) % lanes_count;
	u8  next_id = (lane_id + (1U << prev_size_pow)) % lanes_count;
	u32 row_width = lanes_count * lane_width;
	
	u32 prev_base = prev_size_pow * row_width;
	u32  row_base = prev_base + row_width;
	u32 a = prev_base + lane_id * lane_width + i;
	u32 c =  row_base + lane_id * lane_width + i;
	
	u32 data = lanes[a];
	if (data == LANE_ERROR_VALUE) { lanes[c] = LANE_ERROR_VALUE; return; }
	if (i + data >= lane_width)   { lanes[c] = LANE_ERROR_VALUE; return; }
	u32 b = prev_base + next_id * lane_width + i + data;
	u32 next = lanes[b];
	if (next == LANE_ERROR_VALUE) { lanes[c] = LANE_ERROR_VALUE; return; }
	lanes[c] = data + next;
}
kernel void decodeLower(
	__global u32 positions[], 
	__global u32 lanes[], 
	u32 lane_width, 
	u8 lanes_count, 
	u8 size_pow
) {
	u8  x = get_global_id(0);
	u32 i = get_global_id(1);
	u8  lane_id = x * (1U << (size_pow+1)) % lanes_count;
	u8  next_id = (lane_id + (1U << size_pow)) % lanes_count;
	u32 row_width = lanes_count * lane_width;
	
	u32 p = lane_id * lane_width + i;
	u32 pos = positions[p];
	if (pos == LANE_ERROR_VALUE) { return; }
	u32 row_base = size_pow * row_width;
	u32 a = row_base + lane_id * lane_width + i;
	u32 data = lanes[a];
	if (data == LANE_ERROR_VALUE) { return; }
	u32 q = next_id * lane_width + i + data;
	positions[q] = pos + (1U << size_pow);
}
kernel void positionsToIndexes(
	__global u32 positions[], 
	__global u32x2 indexes[], 
	u32 lane_width
) {
	u32 lane_id = get_global_id(0);
	u32 i       = get_global_id(1);
	
	u32 p = lane_id * lane_width + i;
	u32 pos = positions[p];
	if (pos == LANE_ERROR_VALUE) { return; }
	indexes[pos] = (u32x2)(lane_id, i);
}
kernel void decodeHuffman2(
	__global u8 payload[], 
	__constant HuffmanTree trees[2][4], 
	__constant LaneInfo lane_infos[], 
	u32 lane_width, 
	__global u32x2 indexes[], 
	__global i16 coefficients[][64]
) {
	u32 pos = get_global_id(0);
	u32x2 id = indexes[pos];
	u32 lane_id = id.x;
	u32 i       = id.y;
	// u32 p = lane_id * lane_width + i;
	LaneInfo lane_info = lane_infos[lane_id];
	u32 dc_huf = lane_info.dc_huf;
	u32 lane_index = lane_id * lane_width + i;
	__constant HuffmanTreeNode* huf_dc = trees[0][dc_huf];
	__constant HuffmanTreeNode* huf_ac = trees[1][dc_huf];
	// TODO coefficients_index
	u32 coefficients_index = pos; // TODO + offset in image
	__global i16* res = coefficients[coefficients_index];
	
	for (int i = 0; i < 64; ++i) {
		res[i] = 0;
	}
	
	u32 bbi = i;
	u32 bb = bbi;
	#pragma region DC
		u32 B = bb >> 3;
		u32 b = bb & 7;
		// u16 code word = a<<(b1+8) | b<<b1 | c<<(b1-8)
		u16 code = READ_3B >> (8 - b);
		u8Pair d_s = decodeHuffman(huf_dc, code);
		// TODO store symbol
		// TODO read d_s.y bits
		// store +- (1 << d_s.y) + those bits (but transformed)
		bb += d_s.x;
		u8 SSSS = d_s.y;
		if (SSSS != 0) {
			u32 B = bb >> 3;
			u32 b = bb & 7;
			// SSSS == 14;
			//    .b
			// 00000000 aaaaaaaa aaaaaaaa aaaaaaaa
			//             _____ ________ _------>
			// ______ ________                    
			//                     ______ ________
			// b + SSSS + ? = 24
			i16 data = READ_3B << (b + 8) >> (32 - SSSS);
			if ((data & (1U << (SSSS - 1))) == 0) {
				// negative
				data = data - (1 << SSSS) + 1;
			}
			res[0] = data;
			bb += SSSS;
		}
	#pragma endregion
	
	#pragma region AC
		for (int ac_count = 1; ac_count < 64; ) {
			u32 B = bb >> 3;
			u32 b = bb & 7;
			// u16 code word = a<<(b1+8) | b<<b1 | c<<(b1-8)
			u16 code = READ_3B >> (8 - b);
			u8Pair d_s = decodeHuffman(huf_ac, code);
			// TODO store symbol
			if (d_s.y == 0x00) {
				// rest are 0
				ac_count = 64;
			// } else if (d_s.y == 0xF0) {
			// 	// next 16 are 0
			// 	ac_count += 16;
			} else {
				u8 RRRR = d_s.y >> 4;
				u8 SSSS = d_s.y & 0x0F;
				if (SSSS != 0) {
					u32 B = bb >> 3;
					u32 b = bb & 7;
					// SSSS == 14;
					//    .b
					// 00000000 aaaaaaaa aaaaaaaa aaaaaaaa
					//             _____ ________ _------>
					// ______ ________                    
					//                     ______ ________
					// b + SSSS + ? = 24
					i16 data = READ_3B << (b + 8) >> (32 - SSSS);
					if ((data & (1U << (SSSS - 1))) == 0) {
						// negative
						data = data - (1 << SSSS) + 1;
					}
					res[ac_count + RRRR] = data;
					bb += SSSS;
				}
				ac_count += RRRR + 1;
			}
			bb += d_s.x;
		}
	#pragma endregion
}

//	kernel void TODO +scan

kernel void initializeBufferU32(__global u32 buffer[], u32 value) {
	buffer[(u32)get_global_id(0)] = value;
}

