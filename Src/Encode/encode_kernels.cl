
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

#define MAX_MCU_LENGTH 10
#define ROUND_UP_8(x) ((x + 7) & ~7)
#define N_ONES(n) ((1 << (n)) - 1)
#define VALUE_THAT_IS_NOT_USED ((u8)0XE0)

typedef struct { u16 code, length; } CodeAndLength;
typedef CodeAndLength HuffmanTable[256];

typedef struct {
	u8 c_id;
	u8 hvalues_step;
	u8 sf_y;
	u8 sf_x;
} LaneInfo;

typedef u32 CodedUnit[52];

__constant u8 const from_zigzag[64] = { 0, 1, 8, 16, 9, 2, 3, 10, 17, 24, 32, 25, 18, 11, 4, 5, 12, 19, 26, 33, 40, 48, 41, 34, 27, 20, 13, 6, 7, 14, 21, 28, 35, 42, 49, 56, 57, 50, 43, 36, 29, 22, 15, 23, 30, 37, 44, 51, 58, 59, 52, 45, 38, 31, 39, 46, 53, 60, 61, 54, 47, 55, 62, 63, };
__constant u8 const to_zigzag[8][8] = {
	{  0,  1,  5,  6, 14, 15, 27, 28 },
	{  2,  4,  7, 13, 16, 26, 29, 42 },
	{  3,  8, 12, 17, 25, 30, 41, 43 },
	{  9, 11, 18, 24, 31, 40, 44, 53 },
	{ 10, 19, 23, 32, 39, 45, 52, 54 },
	{ 20, 22, 33, 38, 46, 51, 55, 60 },
	{ 21, 34, 37, 47, 50, 56, 59, 61 },
	{ 35, 36, 48, 49, 57, 58, 62, 63 },
};


kernel void RGB_to_YCbCr/* 2: Y, X */(
	__global   RGBA         arg(image       )[]       ,
	__global   RGBAF        arg(image_temp  )[]       ,
	           u32          arg(image_width )         ,
	           u32          arg(x_required  )         
) {
	u32 y = get_global_id(0);
	u32 x = get_global_id(1);
	RGBA RGB_temp = image[y * image_width + x];
	float3 RGB = (float3) (RGB_temp.r, RGB_temp.g, RGB_temp.b);
	float4 result;
	result.x = dot((float3) ( 0.25686190f,  0.5042455f,   0.09799913f), RGB);
	result.y = dot((float3) (-0.14823364f, -0.2909974f,   0.43923104f), RGB);
	result.z = dot((float3) ( 0.43923104f, -0.3677580f,  -0.07147305f), RGB);
	result.w = 255; //	TODO
	//	YCbCr -= (float3)(128, 128, 128);
	//	YCbCr += (float3)(16, 128, 128);
		//	both = -112, 0, 0
	result.x -= 112;
	image_temp[y * x_required + x] = (RGBAF) {result.x, result.y, result.z, result.w};
}

kernel void fillRequiredX/* 2: Y, x_required - X */(
	__global   RGBAF        arg(image_temp  )[]       ,
	           u32          arg(image_width )         ,
	           u32          arg(x_required  )         
) {
	u32 y  = get_global_id(0);
	u32 dx = get_global_id(1);
	image_temp[y * x_required + image_width + dx] = image_temp[y * x_required + image_width - 1];
}
kernel void fillRequiredY/* 2: y_required - Y, x_required */(
	__global   RGBAF        arg(image_temp  )[]       ,
	           u32          arg(image_height)         ,
	           u32          arg(x_required  )         
) {
	u32 dy = get_global_id(0);
	u32 x  = get_global_id(1);
	image_temp[(image_height + dy) * x_required + x] = image_temp[(image_height - 1) * x_required + x];
}

kernel void interleave_downsample/* 2: MCU_Y, MCU_X */(
	__global   RGBAF_ARR    arg(image_temp  )[]       ,
	__global   FI           arg(coefficients)[][8][8] ,
	__constant LaneInfo     arg(lane_infos  )[]       ,
	           u8x2         arg(max_sf      )         ,
	           u8           arg(mcu_length  )         ,
	           u32          arg(x_required  )         
) {
	u32 const mcu_y = get_global_id(0);
	u32 const mcu_x = get_global_id(1);
	u32 const MCU_X = get_global_size(1);
	u32 const base_index = (mcu_y * MCU_X + mcu_x) * mcu_length;
	u32 const base_y = mcu_y * max_sf.y * 8;
	u32 const base_x = mcu_x * max_sf.x * 8;
	int index = 0; //	hacky, but not bad
	for (int c_id_m1 = 0; c_id_m1 < 3; ++c_id_m1) {
		u8 sf_y = lane_infos[c_id_m1].sf_y;
		u8 sf_x = lane_infos[c_id_m1].sf_x;
		for (int unit_y = 0; unit_y < sf_y; ++unit_y) {
			for (int unit_x = 0; unit_x < sf_x; ++unit_x) {
				for (int yy = 0; yy < 8; ++yy) {
					u32 y = base_y + unit_y * 8 + yy * max_sf.y / sf_y;
					for (int xx = 0; xx < 8; ++xx) {
						u32 x = base_x + unit_x * 8 + xx * max_sf.x / sf_x;
						coefficients[base_index][0][index++].f = image_temp[y * x_required + x].arr[c_id_m1];
					}
				}
			}
		}
	}
}

kernel void dct_quantization_zigzag/* 2: mcu_count, mcu_length */(
	__global   FI           arg(coefficients)[][8][8] ,
	__constant u16          arg(qtables     )[4][8][8],
	__constant LaneInfo     arg(lane_infos  )[]       
) {
	u32 const mcu_index = get_global_id(0);
	u32 const lane_id = get_global_id(1);
	u32 const mcu_length = get_global_size(1);
	u8  const q_id = lane_infos[lane_id].c_id == 1 ? 0 : 1;
	u32 const index = mcu_index * mcu_length + lane_id;
	
	__private float temp[8][8];
	
	for (int v = 0; v < 8; ++v) {
		float cv = v == 0 ? M_SQRT1_2_F : 1;
		for (int u = 0; u < 8; ++u) {
			float cu = u == 0 ? M_SQRT1_2_F : 1;
			float sum = 0;
			for (int yy = 0; yy < 8; ++yy) {
				for (int xx = 0; xx < 8; ++xx) {
					sum += coefficients[index][yy][xx].f * costau((float) (2 * yy + 1) * v / 32) * costau((float) (2 * xx + 1) * u / 32);
				}
			}
			temp[v][u] = cu * cv * sum / 4;
		}
	}
	
	
	for (int i = 0; i < 64; ++i) {
		coefficients[index][0][i].i = round(temp[0][from_zigzag[i]] / qtables[q_id][0][i]);
	}
}

kernel void deltaDC1/* 1: mcu_count */(
	__global   i32          arg(coefficients)[][8][8] ,
	__global   i32          arg(dc_temp     )[]       ,
	__constant LaneInfo     arg(lane_infos  )[]       ,
	           u8           arg(mcu_length  )         
) {
	u32 const mcu_index = get_global_id(0);
	
	int lane_id = 0;
	for (int c_id_m1 = 0; c_id_m1 < 3; ++c_id_m1) {
		LaneInfo lane_info = lane_infos[c_id_m1];
		u8 amount_in_mcu = lane_info.sf_y * lane_info.sf_x;
		i32 predictor = mcu_index == 0 ? 0 : coefficients[mcu_index * mcu_length - mcu_length + lane_id + amount_in_mcu - 1][0][0];
		for (int i = 0; i < amount_in_mcu; ++i) {
			i32 value = coefficients[mcu_index * mcu_length + lane_id][0][0];
			dc_temp[mcu_index * mcu_length + lane_id] = value - predictor;
			predictor = value;
			++lane_id;
		}
	}
	
	//	dc_temp[index] = coefficients[index + 1][0][0] - coefficients[index][0][0];
}
kernel void deltaDC2/* 1: unit_count */(
	__global   i32          arg(coefficients)[][8][8] ,
	__global   i32          arg(dc_temp     )[]       
) {
	u32 const index = get_global_id(0);
	coefficients[index][0][0] = dc_temp[index];
}

kernel void gatherHuffmanValues/* 1: mcu_count */(
	__global   i32          arg(coefficients)[][8][8] ,
	__global   u8           arg(hvalues_dc_0)[]       ,
	__global   u8           arg(hvalues_dc_1)[]       ,
	__global   u8           arg(hvalues_ac_0)[]       ,
	__global   u8           arg(hvalues_ac_1)[]       ,
	__constant LaneInfo     arg(lane_infos  )[]       ,
	           u8           arg(mcu_length  )         
) {
	u32 const mcu_index = get_global_id(0);
	
	u8 lane_id = 0;
	{ //	C1
		__global u8* dc = hvalues_dc_0 + mcu_index * lane_infos[0].hvalues_step;
		__global u8* ac = hvalues_ac_0 + mcu_index * lane_infos[0].hvalues_step * 63;
		u8 const c_id_m1 = 0;
		u8 sf_y = lane_infos[c_id_m1].sf_y;
		u8 sf_x = lane_infos[c_id_m1].sf_x;
		for (int unit_y = 0; unit_y < sf_y; ++unit_y) {
			for (int unit_x = 0; unit_x < sf_x; ++unit_x, ++lane_id, ac += 63) {
				u32 index = mcu_index * mcu_length + lane_id;
				{ //	DC
					i32 value = coefficients[index][0][0];
					u8 SSSS = 32 - clz(abs(value));
					*dc++ = SSSS;
				}
				{ //	AC
					u8 RRRR = 0;
					u8 last_nonzero = 0;
					for (u8 ac_index = 0; ac_index < 63; ++ac_index) {
						i32 value = coefficients[index][0][ac_index + 1];
						if (value == 0) {
							if (RRRR == 15) {
								ac[ac_index] = 0xF0;
								RRRR = 0;
							} else {
								ac[ac_index] = VALUE_THAT_IS_NOT_USED;
								++RRRR;
							}
						} else {
							u8 SSSS = 32 - clz(abs(value));
							ac[ac_index] = RRRR << 4 | SSSS;
							RRRR = 0;
							last_nonzero = ac_index;
						}
					}
					if (last_nonzero == 62) { continue; }
					ac[last_nonzero + 1] = 0x00;
					for (u8 ac_index = last_nonzero + 2; ac_index < 63; ++ac_index) {
						ac[ac_index] = VALUE_THAT_IS_NOT_USED;
					}
				}
			}
		}
	}
	{ //	C2 & C3
		__global u8* dc = hvalues_dc_1 + mcu_index * lane_infos[1].hvalues_step;
		__global u8* ac = hvalues_ac_1 + mcu_index * lane_infos[1].hvalues_step * 63;
		__attribute__((opencl_unroll_hint(2)))
		for (u8 c_id_m1 = 1; c_id_m1 < 3; ++c_id_m1) {
			u8 sf_y = lane_infos[c_id_m1].sf_y;
			u8 sf_x = lane_infos[c_id_m1].sf_x;
			for (int unit_y = 0; unit_y < sf_y; ++unit_y) {
				for (int unit_x = 0; unit_x < sf_x; ++unit_x, ++lane_id, ac += 63) {
					u32 index = mcu_index * mcu_length + lane_id;
					{ //	DC
						i32 value = coefficients[index][0][0];
						u8 SSSS = 32 - clz(abs(value));
						*dc++ = SSSS;
					}
					{ //	AC
						u8 RRRR = 0;
						u8 last_nonzero = 0;
						for (u8 ac_index = 0; ac_index < 63; ++ac_index) {
							i32 value = coefficients[index][0][ac_index + 1];
							if (value == 0) {
								if (RRRR == 15) {
									ac[ac_index] = 0xF0;
									RRRR = 0;
								} else {
									ac[ac_index] = VALUE_THAT_IS_NOT_USED;
									++RRRR;
								}
							} else {
								u8 SSSS = 32 - clz(abs(value));
								ac[ac_index] = RRRR << 4 | SSSS;
								RRRR = 0;
								last_nonzero = ac_index;
							}
						}
						if (last_nonzero == 62) { continue; }
						ac[last_nonzero + 1] = 0x00;
						for (u8 ac_index = last_nonzero + 2; ac_index < 63; ++ac_index) {
							ac[ac_index] = VALUE_THAT_IS_NOT_USED;
						}
					}
				}
			}
		}
	}
}
kernel void radixSort_createAB/* 1: hvalues.length - 1 */(
	__global   u8           arg(hvalues     )[]       ,
	__global   u32          arg(A           )[]       , //	rmember to initialize first element //	we can save space by allocating only the largest array and reusing it
	__global   u32          arg(B           )[]       , //	rmember to initialize first element //	we can save space by allocating only the largest array and reusing it
	           u8           arg(pow         )         
) {
	u32 index = get_global_id(0);
	u32 n_m1 = get_global_size(0);
	A[index + 1   ] = !((hvalues[index    ] >> pow) & 1);
	B[n_m1 - index] =   (hvalues[index + 1] >> pow) & 1 ;
	//	A[index] = hvalues[index];
	//	B[n_m1 - index] = 0b10000 + pow;
}
kernel void radixSort_prefixSum1/* 1: hvalues.length / full_step */(
	__global   u32          arg(A           )[]       ,
	__global   u32          arg(B           )[]       ,
	           u32          arg(half_step   )         
) {
	u32 const index = get_global_id(0);
	u32 full_step = half_step * 2;
	
	u32 const index_b = full_step + index * full_step - 1;
	u32 const index_a = index_b - half_step;
	
	A[index_b] += A[index_a];
	B[index_b] += B[index_a];
}
kernel void radixSort_prefixSum2/* 1: (hvalues.length - half_step) / full_step, if hvalues.length > half_step */(
	__global   u32          arg(A           )[]       ,
	__global   u32          arg(B           )[]       ,
	           u32          arg(half_step   )         
) {
	u32 const index = get_global_id(0);
	u32 full_step = half_step * 2;
	
	u32 const index_a = full_step + index * full_step - 1;
	u32 const index_b = index_a + half_step;
	
	A[index_b] += A[index_a];
	B[index_b] += B[index_a];
}
kernel void radixSort_rearange/* 1: hvalues.length */(
	__global   u8           arg(hvalues     )[]       ,
	__global   u8           arg(hvalues_dst )[]       ,
	__global   u32          arg(A           )[]       ,
	__global   u32          arg(B           )[]       ,
	           u8           arg(pow         )         
) {
	u32 const index = get_global_id(0);
	u32 const n_m1 = get_global_size(0) - 1;
	u32 const index_dst = hvalues[index] >> pow & 1 ? n_m1 - B[n_m1 - index] : A[index];
	hvalues_dst[index_dst] = hvalues[index];
}

kernel void initCountsLarge/* 1: hvalues.length */(
	__global   u32          arg(counts_large)[]       
) {
	counts_large[get_global_id(0)] = 1;
}
kernel void initCounts/* 2: 4, 256 */(
	__global   u32          arg(last_writers)[4][256] ,
	__global   u32          arg(counts      )[4][256]  
) {
	last_writers[get_global_id(0)][get_global_id(1)] = 0;
	counts      [get_global_id(0)][get_global_id(1)] = 0;
}
kernel void countOccurances1/* 1: hvalues.length / full_step */(
	__global   u8           arg(hvalues     )[]       ,
	__global   u32          arg(counts_large)[]       ,
	           u32          arg(half_step   )         
) {
	u32 const index = get_global_id(0);
	u32 full_step = half_step * 2;
	
	u32 const index_b = full_step + index * full_step - 1;
	u32 const index_a = index_b - half_step;
	
	if (hvalues[index_a] == hvalues[index_b]) {
		counts_large[index_b] += counts_large[index_a];
	}
}
kernel void countOccurances2/* 1: (hvalues.length + half_step) / full_step */(
	__global   u8           arg(hvalues     )[]       ,
	__global   u32          arg(counts_large)[]       ,
	__global   u32          arg(last_writers)[4][256] ,
	__global   u32          arg(counts      )[4][256] ,
	           u8           arg(id          )         , //	id = binary(DC/AC, Y/CbCr)
	           u32          arg(half_step   )         
) {
	u32 const index = get_global_id(0);
	u32 full_step = half_step * 2;
	
	u32 const index_a = index * full_step - 1;
	u32 const index_b = index_a + half_step;

	u32 const count = counts_large[index_b];
	u8  const value = hvalues     [index_b];
	u32 const current     = counts      [id][value];
	u32 const last_writer = last_writers[id][value];
	
	if (last_writer > index_b) { return; }
	
	
	counts      [id][value] += count;
	last_writers[id][value] = index_b;
}

kernel void encodeHuffman/* 2: mcu_count, mcu_length */(
	__global   i32          arg(coefficients)[][8][8] ,
	__global   u32          arg(lengths     )[]       ,
	__global   CodedUnit    arg(codes       )[]       ,
	__constant LaneInfo     arg(lane_infos  )[]       ,
	__constant HuffmanTable arg(htables     )[2][4]   
) {
	u32 const mcu_index = get_global_id(0);
	u32 const lane_id = get_global_id(1);
	u8  const mcu_length = get_global_size(1);
	u32 const index = mcu_index * mcu_length + lane_id;//	
	//	get_global_linear_id();
	u8  const h_id = lane_infos[lane_id].c_id == 1 ? 0 : 1;
	
	for (int i = 0; i < sizeof(CodedUnit) / sizeof(codes[0][0]); ++i) {
		codes[index][i] = 0;
	}
	
	//	lengths[index + 1] = 1000 * mcu_index + lane_id;
	//	return; 
	//	if (mcu_index == 0 && lane_id == 2) {
	//		lengths[index + 1] = 3;
	//		return;
	//	} else {
	//		lengths[index + 1] = 1;
	//		return;
	//	}
	
	u16 length = 0;
	#pragma region DC
	{
		i32 value = coefficients[index][0][0];
		u8 SSSS = 32 - clz(abs(value));
		if (value < 0) { --value; }
		CodeAndLength code_and_length = htables[0][h_id][SSSS];
		u32 mask = (1U << SSSS) - 1;
		u32 code = 0
			| (code_and_length.code << (32 - code_and_length.length))
			| ((value & mask)       << (32 - code_and_length.length - SSSS))
		;
		codes[index][0] = code;
		length = code_and_length.length + SSSS;
	}
	#pragma endregion
	#pragma region AC
	{
		struct ACInfo { i32 value; u8 zeroes; /* u8 valid; */ } ac_infos[64] = {0};
		int current_index = 0;
		int last_zero = 0;
		for (int ac_index = 1; ac_index < 64; ++ac_index) {
			i32 value = coefficients[index][0][ac_index];
			if (value == 0) {
				if (ac_infos[current_index].zeroes == 15) {
					//	ac_infos[current_index].valid = true;
					++current_index;
				} else {
					++ac_infos[current_index].zeroes;
				}
			} else {
				//	ac_infos[current_index].valid = true;
				ac_infos[current_index].value = value;
				last_zero = ++current_index;
			}
		}
		for (int i = 0; i < last_zero; ++i) {
			i32 value = ac_infos[i].value;
			u8 SSSS = 32 - clz(abs(value));
			if (value < 0) { --value; }
			u8 RRRR = ac_infos[i].zeroes;
			CodeAndLength code_and_length = htables[1][h_id][RRRR << 4 | SSSS];
			u32 my_length = code_and_length.length + SSSS;
			u32 mask = (1U << SSSS) - 1;
			u32 code = 0
				| (code_and_length.code << (32 - code_and_length.length))
				| ((value & mask)       << (32 - code_and_length.length - SSSS))
			;
			u32 code_mask = ((1U << my_length) - 1) << (32 - my_length);
			u8 word   = length / 32;
			u8 offset = length % 32;
			code = rotate(code, (u32) 32 - offset); //	rotate is left rotation, so this is actually right rotation by `offset` bits
			codes[index][word    ] |= code & (code_mask >> offset); //	obviously, 1st bit must be at offset from MSB
			codes[index][word + 1] |= code & (code_mask << 1 << (31 - offset)); //	obviously, must be shifted left the same amount as rotation
				//	lets say we have 8 bits, offset 3, my_length = 4
				//	code      = 10100000
				//	rotated   = 00010100
				//	code_mask = 11100000
				//	[word    ]  00011100
				//	[word + 1]  00000000
				//	lets say we have 8 bits, offset 6, my_length = 5
				//	code      = 10101000
				//	rotated   = 10100010
				//	code_mask = 11111000
				//	[word    ]  00000011
				//	[word + 1]  11100000
			length += my_length;
		}
		if (ac_infos[last_zero].zeroes) {
			CodeAndLength code_and_length = htables[1][h_id][0];
			u32 my_length = code_and_length.length;
			u32 code = code_and_length.code << (32 - code_and_length.length);
			u32 code_mask = ((1U << my_length) - 1) << (32 - my_length);
			u8 word   = length / 32;
			u8 offset = length % 32;
			code = rotate(code, (u32) 32 - offset); //	rotate is left rotation, so this is actually right rotation by `offset` bits
			codes[index][word    ] |= code & (code_mask >> offset); //	obviously, 1st bit must be at offset from MSB
			codes[index][word + 1] |= code & (code_mask << 1 << (31 - offset)); //	obviously, must be shifted left the same amount as rotation
			length += my_length;
		}
	}
	#pragma endregion
	lengths[index + 1] = length;
}

kernel void prefixSumLengths1/* 1: unit_count / full_step */(
	__global   u32          arg(lengths     )[]       ,
	           u32          arg(half_step   )         
) {
	u32 const index = get_global_id(0);
	u32 full_step = half_step * 2;
	
	u32 const index_b = full_step + index * full_step;
	u32 const index_a = index_b - half_step;
	
	lengths[index_b] += lengths[index_a];
}
kernel void prefixSumLengths2/* 1: (unit_count - half_step) / full_step, if unit_count > half_step */(
	__global   u32          arg(lengths     )[]       ,
	           u32          arg(half_step   )         
) {
	u32 const index = get_global_id(0);
	u32 full_step = half_step * 2;
	
	u32 const index_a = full_step + index * full_step;
	u32 const index_b = index_a + half_step;
	
	lengths[index_b] += lengths[index_a];
}

kernel void concatCodes/* 1: unit_count */(
	__global   u32          arg(lengths     )[]       ,
	__global   CodedUnit    arg(codes       )[]       ,
	__global   u8           arg(payload     )[]       
) {
	//	we will write some bytes
	//	we will start on the one that is fully ours, and finish on the one that is at least partially
	//	e.g. if we start at bit 0, then we start at 1st byte
	//	if we start at bit 1, then we start at 2nd byte
	//	if we start at bit 7, then we start at 2nd byte
	//	if we start at bit 8, then we start at 2nd byte
	//	if we start at bit 9, then we start at 3rd byte
	//	
	//	and if we finish on bit 14 (last written was 13), then last written byte is 2nd
	//	
	//	if we finish in the middle of the byte, then we are responsible for writting 1st part of the 1st byte of the next code
	//	i.e. we fill our last byte with what is in the next code
	//	also be sure that there is enough in the next code
	//	also, codes and lengths should be initialized with 1 more last element length >=8, code 0xFF...
	
	u32 const unit_index = get_global_id(0); // - get_global_offset(0);
	u32 const start_bit = lengths[unit_index];                          //	start_bit >= 0
	u32 const length_bit = lengths[unit_index + 1] - start_bit;         //	length_bit > 0
	u32 const start_bit_actual = ROUND_UP_8(start_bit);                 //	start_bit + 8 > start_bit_actual >= start_bit
	//	bbx TODO uncomment when finished with bbx bb8a012d-0c86-4b16-8f75-bc722937dde6
	if (start_bit + length_bit <= start_bit_actual) { return; }
	u32 const delta_actual = start_bit_actual - start_bit;              //	length_bit > delta_actual && 0 <= delta_actual < 8
	u32 const length_bit_actual = length_bit - delta_actual;            //	length_bit_actual > 0
	u32 const start_byte = start_bit_actual / 8;                        //	start_byte * 8 == start_bit_actual
	u32 const length_byte = length_bit_actual / 8;                      //	length_byte >= 0, but 0 is ok, since we do handle u to ceil(length_bit_actual / 8)
	//	bbx bb8a012d-0c86-4b16-8f75-bc722937dde6
	//	if (start_bit + length_bit <= start_bit_actual) { 
	//		codes[unit_index][0] = 0xCCCCCCCC;
	//		codes[unit_index][1] = 0xCCCCCCCC;
	//		codes[unit_index][2] = 0xCCCCCCCC;
	//		return; 
	//	} else {
	//		codes[unit_index][0] = start_byte;
	//		codes[unit_index][1] = length_byte;
	//		codes[unit_index][2] = start_byte + length_byte;
	//		return; 
	//	}
	
	//	TODO check/fix this comment
	//	//	start_bit = 5; start_bit_actual = 8;
	//	//	delta_actual = 3;
	//	//	0b 11111111 00000000 11111111 00000000 11111111 00000000 11111111 00000000
	//	//	0b xxx11111 00000000 11111111 00000000 11111111 00000000 11111111 00000000
	//	//	0b 11111000 00000111 11111000 00000111 11111000 00000111 11111000 00000???
	
	for (u32 index_code = 0, index = 0; index < length_byte; ++index_code) {
		__attribute__((opencl_unroll_hint(4)))
		for (int amount_to_shift = 32 - 8; amount_to_shift >= 0 && index < length_byte; amount_to_shift -= 8, ++index) {
			u8 data = codes[unit_index][index_code] << delta_actual >> amount_to_shift;
			if (/* delta_actual != 0 && */ amount_to_shift == 0) {
				//	data |= codes[unit_index][index_code + 1] >> (32 - delta_actual); //	 << delta_actual >> 32;
				//	data |= codes[unit_index][index_code + 1] >> 31;//>> (32 - delta_actual); //	 << delta_actual >> 32;
				//	ok, for some reason, when you right-shift by 32, it does nothing
				data |= codes[unit_index][index_code + 1] >> 16 >> (16 - delta_actual); //	 << delta_actual >> 32;
			}
			payload[start_byte + index] = data;
			//	payload[start_byte + index] = unit_index;
		}
	}
	//	u8 amount_to_shift = 32 - 8;
	//	
	//	for (u32 index = 0; index < length_byte; ++index) {
	//		u32 index_code = index / sizeof(u32);
	//		u8 data = codes[unit_index][index_code] >> delta_actual << delta_actual >> amount_to_shift;
	//		if (amount_to_shift < 8) {
	//			data |= codes[unit_index][index_code + 1] >> (32 - delta_actual);
	//		}
	//		payload[start_byte + index] = data;
	//		amount_to_shift -= 8;
	//		amount_to_shift %= 32;
	//	}
	
	if (length_bit_actual % 8 != 0) {
		u32 my_bit_length = length_bit_actual % 8;
		i32 required_bit_length = 8 - my_bit_length;
		u32 index = length_byte;
		u32 index_code = index / sizeof(u32);
		u8 amount_to_shift = 32 - 8 - 8 * (index % sizeof(u32));
		u8 data = codes[unit_index][index_code] << delta_actual >> amount_to_shift;
		if (/* delta_actual != 0 && */ amount_to_shift == 0) {
			//	data |= codes[unit_index][index_code + 1] >> (32 - delta_actual); //	 << delta_actual >> 32;
			//	data |= codes[unit_index][index_code + 1] >> 31;//>> (32 - delta_actual); //	 << delta_actual >> 32;
			//	ok, for some reason, when you right-shift by 32, it does nothing
			data |= codes[unit_index][index_code + 1] >> 16 >> (16 - delta_actual); //	 << delta_actual >> 32;
		}

		for (int their_index = unit_index + 1; required_bit_length > 0; ++their_index) {
			u32 their_length_bit = lengths[their_index + 1] - lengths[their_index];
			data |= codes[their_index][0] >> (32 - required_bit_length);
			//	data = their_index - unit_index;
			//	break;
			//	data = codes[their_index][0];
			//	data = required_bit_length;
			required_bit_length -= their_length_bit;
		}
		payload[start_byte + index] = data;
		//	payload[start_byte + index] = unit_index;
		
	}
}
