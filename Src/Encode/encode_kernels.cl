
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

typedef struct { u16 code, length; } CodeAndLength;
typedef CodeAndLength HuffmanTable[256];

typedef struct {
	u8 c_id;
	u8 _; //	padding
	u8 sf_y;
	u8 sf_x;
} LaneInfo;

typedef u64 CodedUnit[26];

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
	__global   RGBAF        arg(image_temp  )[]       
) {
	size_t index = get_global_linear_id();
	RGBA RGB_temp = image[index];
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
	image_temp[index] = (RGBAF) {result.x, result.y, result.z, result.w};
}

kernel void interleave_downsample/* 2: MCU_Y, MCU_X */(
	__global   RGBAF_ARR    arg(image_temp  )[]       ,
	__global   FI           arg(coefficients)[][8][8] ,
	__constant LaneInfo     arg(lane_infos  )[]       ,
	           u8x2         arg(max_sf      )         ,
	           u8           arg(mcu_length  )         ,
	           u32          arg(image_width )         
) {
	u32 const mcu_y = get_global_id(0);
	u32 const mcu_x = get_global_id(1);
	u32 const base_index = get_global_linear_id() * mcu_length;
	u32 const base_y = mcu_y * max_sf.y;
	u32 const base_x = mcu_x * max_sf.x;
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
						coefficients[base_index][0][index++].f = image_temp[y * image_width + x].arr[c_id_m1];
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
	u32 const unit_index = get_global_id(1);
	u8  const q_id = lane_infos[unit_index].c_id - 1;
	u32 const index = get_global_linear_id();
	
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
	
	int unit_index = 0;
	for (int c_id_m1 = 0; c_id_m1 < 3; ++c_id_m1) {
		i32 predictor = mcu_index == 0 ? 0 : coefficients[mcu_index * mcu_length + unit_index - mcu_length][0][0];
		LaneInfo lane_info = lane_infos[unit_index];
		for (int yy = 0; yy < lane_info.sf_y; ++yy) {
			for (int xx = 0; xx < lane_info.sf_x; ++xx) {
				i32 value = coefficients[mcu_index * mcu_length + unit_index][0][0];
				dc_temp[mcu_index * mcu_length + unit_index] = value - predictor;
				predictor = value;
				++unit_index;
			}
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

kernel void encodeHuffman/* 2: mcu_count, mcu_length */(
	__global   i32          arg(coefficients)[][8][8] ,
	__global   u32          arg(lengths     )[]       ,
	__global   CodedUnit    arg(codes       )[]       ,
	__constant LaneInfo     arg(lane_infos  )[]       ,
	__constant HuffmanTable arg(htables     )[2][4]   
) {
	u32 const mcu_index = get_global_id(0);
	u32 const unit_index = get_global_id(1);
	u32 const index = get_global_linear_id();
	u8  const c_id_m1 = lane_infos[unit_index].c_id - 1;
	
	u16 length = 0;
	#pragma region DC
	{
		i32 value = coefficients[index][0][0];
		u8 SSSS = 32 - clz(abs(value));
		CodeAndLength code_and_length = htables[0][c_id_m1][SSSS];
		u32 mask = (1U << SSSS) - 1;
		u64 code = 0
			| (code_and_length.code << (64 - code_and_length.length))
			| ((value & mask)       << (64 - code_and_length.length - SSSS))
		;
		codes[index][0] = code;
		length = code_and_length.length + SSSS;
	}
	#pragma endregion
	#pragma region AC
	{
		struct ACInfo { i32 value; u8 zeroes; u8 valid; } ac_infos[64] = {0};
		int current_index = 0;
		int last_zero = 0;
		for (int ac_index = 1; ac_index < 64; ++ac_index) {
			i32 value = coefficients[index][0][ac_index];
			if (value == 0) {
				if (ac_infos[current_index].zeroes == 15) {
					ac_infos[current_index].valid = true;
					++current_index;
				} else {
					++ac_infos[current_index].zeroes;
				}
			} else {
				ac_infos[current_index].valid = true;
				ac_infos[current_index].value = value;
				last_zero = ++current_index;
			}
		}
		for (int i = 0; i < last_zero; ++i) {
			i32 value = ac_infos[i].value;
			u8 SSSS = 32 - clz(abs(value));
			u8 RRRR = ac_infos[i].zeroes;
			CodeAndLength code_and_length = htables[1][c_id_m1][(RRRR << 4) | SSSS];
			u32 my_length = code_and_length.length + SSSS;
			u32 mask = (1U << SSSS) - 1;
			u64 code = 0
				| (code_and_length.code << (64 - code_and_length.length))
				| ((value & mask)       << (64 - code_and_length.length - SSSS))
			;
			u64 code_mask = ((1U << my_length) - 1) << (64 - my_length);
			u8 word   = length / 64;
			u8 offset = length % 64;
			code = rotate(code, (u64) 64 - offset); //	this is left rotation
			codes[index][word    ] |= code & (code_mask >> offset); //	obviously, 1st bit must be at offset from MSB
			codes[index][word + 1] |= code & (code_mask << (64 - offset)); //	obviously, must be shifted left the same amount as rotation
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
			CodeAndLength code_and_length = htables[1][c_id_m1][0];
			u32 my_length = code_and_length.length;
			u64 code = code_and_length.code << (64 - code_and_length.length);
			u64 code_mask = ((1U << my_length) - 1) << (64 - my_length);
			u8 word   = length / 64;
			u8 offset = length % 64;
			code = rotate(code, (u64) 64 - offset); //	this is left rotation
			codes[index][word    ] |= code & (code_mask >> offset); //	obviously, 1st bit must be at offset from MSB
			codes[index][word + 1] |= code & (code_mask << (64 - offset)); //	obviously, must be shifted left the same amount as rotation
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
	
	u32 const index_b = full_step - 1 + index * full_step;
	u32 const index_a = index_b - half_step;
	
	lengths[index_b] += lengths[index_a];
}
kernel void prefixSumLengths2/* 1: unit_count / full_step */(
	__global   u32          arg(lengths     )[]       ,
	           u32          arg(half_step   )         
) {
	u32 const index = get_global_id(0);
	u32 full_step = half_step * 2;
	
	//	(a, b) = (b, a + b);
	u32 const index_b = full_step - 1 + index * full_step;
	u32 const index_a = index_b - half_step;
	
	u32 temp = lengths[index_b];
	lengths[index_b] += lengths[index_a];
	lengths[index_a] = temp;
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
	
	u32 const unit_index = get_global_id(0);
	u32 const start_bit = lengths[unit_index];
	u32 const length_bit = lengths[unit_index + 1] - start_bit;
	u32 const start_bit_actual = ROUND_UP_8(start_bit);
	u32 const delta_actual = start_bit_actual - start_bit;
	u32 const length_bit_actual = length_bit - delta_actual;
	u32 const start_byte = start_bit_actual / 8;
	u32 const length_byte = length_bit_actual / 8;
	u32 const length_byte_actual = ROUND_UP_8(length_bit_actual) / 8;
	
	//	start_bit = 5; start_bit_actual = 8;
	//	delta_actual = 3;
	//	0b 11111111 00000000 11111111 00000000 11111111 00000000 11111111 00000000
	//	0b xxx11111 00000000 11111111 00000000 11111111 00000000 11111111 00000000
	//	0b 11111000 00000111 11111000 00000111 11111000 00000111 11111000 00000???
	u8 amount_to_shift = 64 - 8 - delta_actual;
	u64 mask1 = N_ONES(8 - delta_actual) << delta_actual;
	u64 mask2 = N_ONES(delta_actual) << (8 - delta_actual);
	
	for (int index = start_byte; index < length_byte; ++index) {
		int index_code = index / sizeof(64);
		u8 data = (codes[unit_index][index_code] >> amount_to_shift) & mask1;
		if (amount_to_shift == 0) {
			data |= codes[unit_index][index_code + 1] >> (64 - delta_actual);
		}
		payload[index] = data;
		amount_to_shift -= 8;
		amount_to_shift %= 64;
	}
	if (length_byte_actual > length_byte) {
		int index = length_byte;
		int index_code = index / sizeof(64);
		u8 data = (codes[unit_index][index_code] >> amount_to_shift) & mask1;
		data |= codes[unit_index + 1][0] >> (64 - (length_bit_actual % 8));
		payload[index] = data;
	}
}
