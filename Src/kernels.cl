typedef uchar   u8;
typedef uchar2  u8x2;
typedef ushort  u16;
typedef ushort2 u16x2;
typedef uint    u32;
typedef ulong   u64;
typedef uint2   u32x2;
typedef char  i8;
typedef short i16;
typedef int   i32;
typedef long  i64;
typedef int2  i32x2;
typedef union {float f; i32 i;} FI;
typedef struct { u8 r, g, b, a; } RGBA;
typedef struct { float r, g, b, a; } RGBAF;
typedef struct { u8 arr[4]; } RGBA_ARR;
typedef struct { float arr[4]; } RGBAF_ARR;

#define costau(...) cospi(2.0f * (__VA_ARGS__))

#define x2(type, y, x, ...) ((type ## x2) ((x), (y)))

typedef struct {
	u16 left;
	u16 right_or_data;
} HuffmanTreeNode;
typedef HuffmanTreeNode HuffmanTree[256 + 255 + 1];
u8x2 decodeHuffman(__constant HuffmanTree huf, u16 code) {
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
	return (u8x2) (res_depth, (u8)node.right_or_data);
}

#define LANE_ERROR_VALUE UINT_MAX
typedef struct {
	u8 c_id;
	u8 dc_huf;
	u8 ac_huf;
	u8 q_id;
	u8 sf_y;
	u8 sf_x;
	u8 start_in_mcu;
	u8 amount_in_mcu;
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

__constant u8 const from_zigzag[64] = { 0, 1, 8, 16, 9, 2, 3, 10, 17, 24, 32, 25, 18, 11, 4, 5, 12, 19, 26, 33, 40, 48, 41, 34, 27, 20, 13, 6, 7, 14, 21, 28, 35, 42, 49, 56, 57, 50, 43, 36, 29, 22, 15, 23, 30, 37, 44, 51, 58, 59, 52, 45, 38, 31, 39, 46, 53, 60, 61, 54, 47, 55, 62, 63, };

#define TAU (2 * M_PI_F)

// started as [Ns][bb2 - b1]
kernel void decodeHuffman1(
	__global u8 payload[], 
	u32 B2, 
	__constant HuffmanTree trees[2][4], 
	__constant LaneInfo lane_infos[], 
	__global u32 lanes[], 
	u32 lane_width, 
	__constant u8 lane_indexes[] // do I need this? (couldn't get_global_id(0) be lane_id?)
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
		u8x2 d_s = decodeHuffman(huf_dc, code);
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
			u8x2 d_s = decodeHuffman(huf_ac, code);
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
	u32 i = get_global_id(0);
	u32 pos = positions[i];
	if (pos == LANE_ERROR_VALUE) { return; }
	u8  lane_id = pos % lanes_count;
	
	u32 row_width = lanes_count * lane_width;
	u32 row_base = size_pow * row_width;
	u32 a = row_base + lane_id * lane_width + i;
	u32 data = lanes[a];
	if (data == LANE_ERROR_VALUE) { return; }
	u32 next_i = i + data;
	positions[next_i] = pos + (1U << size_pow);
}
kernel void positionsToIndexes(
	__global u32 positions[], 
	__global u32 indexes[]
) {
	u32 i = get_global_id(0);
	
	u32 pos = positions[i];
	if (pos == LANE_ERROR_VALUE) { return; }
	indexes[pos] = i;
}
kernel void decodeHuffman2(
	__global u8 payload[], 
	__constant HuffmanTree trees[2][4], 
	__constant LaneInfo lane_infos[], 
	u32 lane_width, 
	u8 lanes_count, 
	__global u32 indexes[], 
	__global i32 coefficients[][64]
) {
	u32 pos = get_global_id(0);
	u32 i = indexes[pos];
	u8 lane_id = pos % lanes_count;
	// u32 p = lane_id * lane_width + i;
	LaneInfo lane_info = lane_infos[lane_id];
	u32 lane_index = lane_id * lane_width + i;
	__constant HuffmanTreeNode* huf_dc = trees[0][lane_info.dc_huf];
	__constant HuffmanTreeNode* huf_ac = trees[1][lane_info.ac_huf];
	// TODO coefficients_index
	u32 coefficients_index = pos; // TODO + offset in image
	__global i32* res = coefficients[coefficients_index];
	
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
		u8x2 d_s = decodeHuffman(huf_dc, code);
		u32 _bbx = b;
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
			i32 data = READ_3B << (b + 8) >> (32 - SSSS);
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
			int bbx = ac_count;
			u32 B = bb >> 3;
			u32 b = bb & 7;
			// u16 code word = a<<(b1+8) | b<<b1 | c<<(b1-8)
			u16 code = READ_3B >> (8 - b);
			u8x2 d_s = decodeHuffman(huf_ac, code);
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
					i32 data = READ_3B << (b + 8) >> (32 - SSSS);
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

kernel void prepareMCUs(
	__global i32 coefficients[][8][8], 
	__constant LaneInfo lane_infos[], 
	u8 mcu_length
) {
	//	maybe use remaining 3 fields to store start + amount 
	//	and on CPU compute that stuff and begin only those components that are needed
	u8 lane_id = get_global_id(0);
	u32 i = get_global_id(1);
	LaneInfo lane_info = lane_infos[lane_id];
	i32 accumulator = 0;
	u32 mcu_base = i * mcu_length + lane_info.start_in_mcu;
	for (u8 j = 0; j < lane_info.amount_in_mcu; ++j) {
		accumulator += coefficients[mcu_base + j][0][0];
		coefficients[mcu_base + j][0][0] = accumulator;
	}
}

inline void addMCUsToRight(
	__global i32 coefficients[][8][8],
	__constant LaneInfo lane_infos[], 
	u32 a_index,
	u32 b_index,
	u8 mcu_length
) {
	//	i will generate this function dynamically
	
	//	or not
	u16 last_component_id = ~0;
	i32 a = 0x363f;
	for (int i = mcu_length - 1; i >= 0; --i) {
		LaneInfo lane_info = lane_infos[i];
		if ((u16)lane_info.c_id != last_component_id) {
			last_component_id = lane_info.c_id;
			a = coefficients[a_index + i][0][0];
		}
		coefficients[b_index + i][0][0] += a;
	}
}
kernel void prefixSum1(
	__global i32 coefficients[][8][8],
	__constant LaneInfo lane_infos[], 
	u32 half_size/* _pow? */,
	u8 mcu_length
) {
	u32 i = get_global_id(0);
	u32 b_index = mcu_length * ((i + 1) * half_size * 2 - 1);
	u32 a_index = b_index - half_size * mcu_length;
	addMCUsToRight(coefficients, lane_infos, a_index, b_index, mcu_length);
}
kernel void prefixSum2(
	__global i32 coefficients[][8][8],
	__constant LaneInfo lane_infos[], 
	u32 half_size/* _pow? */,
	u8 mcu_length
) {
	u32 i = get_global_id(0);
	u32 b_index = mcu_length * (half_size + (i + 1) * half_size * 2 - 1);
	u32 a_index = b_index - half_size * mcu_length;
	addMCUsToRight(coefficients, lane_infos, a_index, b_index, mcu_length);
}

kernel void unzigzag_quantization_dct/* 1 */(
	__global FI coefficients[][8][8],
	__constant u16 quantization_table[4][8][8],
	__constant LaneInfo lane_infos[], 
	u8 mcu_length
) {
	u32 index = get_global_id(0);
	u8 const lane_id = index % mcu_length;
	u8 const q_id = lane_infos[lane_id].q_id;
	__private FI unzigzaged[8][8]; // wierdly, this might be able to be __local
	
	for (int i = 0; i < 64; ++i) {
		unzigzaged[0][from_zigzag[i]].i = coefficients[index][0][i].i;
	}
	
	for (int i = 0; i < 8; ++i) {
		for (int j = 0; j < 8; ++j) {
			unzigzaged[i][j].f = (float) unzigzaged[i][j].i * quantization_table[q_id][i][j];
		}
	}
	//	for (int i = 0; i < 8; ++i) {
	//		for (int j = 0; j < 8; ++j) {
	//			unzigzaged[i][j].f = (float) coefficients[index][i][j].i;
	//		}
	//	}
	
	for (int y = 0; y < 8; ++y) {
		for (int x = 0; x < 8; ++x) {
			float sum = 0;
			for (int v = 0; v < 8; ++v) {
				float cv = v == 0 ? M_SQRT1_2_F : 1;
				for (int u = 0; u < 8; ++u) {
					float cu = u == 0 ? M_SQRT1_2_F : 1;
					sum += cv * cu * unzigzaged[v][u].f * costau((float) (2*x+1) * u / 32) * costau((float) (2*y+1) * v / 32);
				}
			}
			coefficients[index][y][x].f = sum / 4;
		}
	}
	//	coefficients[index][0][0].f = get_global_size(0);
}

kernel void uninterleave_upsample/* 2 */(
	__global float      coefficients[][8][8], 
	__global RGBAF_ARR  image_temp[],
	__constant LaneInfo lane_infos[], 
	u8x2                max_sf,
	u32x2               image_size,
	u8                  mcu_length,
	u32                 mcu_per_line,
	u8                  component_count
) {
	//	this kernel is just copying stuff from one place to another (multiple anothers)
	//	SF(h, w)
	//	(y, x) -> downsample -> (YY, yy, XX, xx) -> 
	
	//	A A B C C D
	//	A A B 
	
	//	A A B B C C D D
	//	A A B B C C D D
	
	//	for component in mcu {
	//		for (is, js) in range(max_sf) {
	//			locate data unit based on (is, js) and sf
	//			locate dst based (is, js) and global xy
	//			for (yy, xx) in range(8)² {
	//				get data [yy, xx] from data unit
	//				copy to dst
	//			}
	//		}
	//	}
	
	u32x2 mcu_yx = x2(u32, 
		get_global_id(0),
		get_global_id(1),
	);
	u32 mcu_index = mcu_yx.y * mcu_per_line + mcu_yx.x;
	u32x2 base = x2(u32,
		mcu_yx.y * max_sf.y * 8,
		mcu_yx.x * max_sf.x * 8,
	);
	//	width = max_sf.x * mcu_per_line
	//	y_global_base * max_sf.y
	//	u32 mcu_per_line = image_size.x / 8 / max_sf.x;
	//	we will copy [index] -> [mcu_yx.y * max_sf.y * 8 + ...][-||-] = [... * width + ...]
	
	//	MCU is responsible for area of height max_sf.y * 8 and width max_sf.x * 8
	u8 lane_id = 0;
	u32 data_unit_base = mcu_index * mcu_length + 0; //	TODO calculate data_unit_base
	for (int component_index = 0; component_index < component_count; ++component_index) {
		u8x2 component_sf = x2(u8, 
			lane_infos[lane_id].sf_y,
			lane_infos[lane_id].sf_x,
		); //	TODO
		for (int yy = 0; yy < max_sf.y * 8; ++yy) {
			//	TODO calculate y and source (in mcu)
			u32 y_of_data_unit_in_mcu = yy / 8 / (max_sf.y / component_sf.y);
			for (int xx = 0; xx < max_sf.x * 8; ++xx) {
				u8 c_id = lane_infos[lane_id].c_id; //	TODO
				//	TODO calculate x and source (in mcu)
				u32 x_of_data_unit_in_mcu = xx / 8 / (max_sf.x / component_sf.x);
				u32 data_unit_index = y_of_data_unit_in_mcu * (max_sf.x / component_sf.x) + x_of_data_unit_in_mcu;
				u32 src_index = data_unit_base + data_unit_index;
				u32 dst_index = (base.y + yy) * image_size.x + (base.x + xx);
				image_temp[dst_index].arr[c_id] = coefficients[src_index][yy / (max_sf.y / component_sf.y) % 8][xx / (max_sf.x / component_sf.x) % 8]; //	TODO this is float[0->1] -> u8 //	when do we do YCbCr -> RGB?
			}
		}
		data_unit_base += component_sf.y * component_sf.x;
		lane_id += component_sf.y * component_sf.x;
	}
}
kernel void YCbCr_to_RGB/* 2 */(
	__global RGBAF    image_temp[],
	__global RGBA     image[],
	u32               image_width
) {
	int i = get_global_id(0);
	int j = get_global_id(1);
	RGBAF YCbCr_temp = image_temp[i * image_width + j];
	float3 YCbCr = (float3) (YCbCr_temp.r, YCbCr_temp.g, YCbCr_temp.b);
	YCbCr -= (float3)(16, 128, 128);
	RGBAF result;
	result.r = dot((float3) (1.164f,  0.000f,  1.596f), YCbCr); if (result.r < 0) { result.r = 0; } else if (result.r > 255) { result.r = 255; }
	result.g = dot((float3) (1.164f, -0.392f, -0.813f), YCbCr); if (result.g < 0) { result.g = 0; } else if (result.g > 255) { result.g = 255; }
	result.b = dot((float3) (1.164f,  2.017f,  0.000f), YCbCr); if (result.b < 0) { result.b = 0; } else if (result.b > 255) { result.b = 255; }
	result.a = 255; //	TODO
	image[i * image_width + j] = (RGBA) {result.r, result.g, result.b, result.a};
}

kernel void initializeBufferU32(__global u32 buffer[], u32 value) {
	buffer[(u32)get_global_id(0)] = value;
}

