typedef uchar  u8;
typedef ushort u16;
typedef uint   u32;
typedef ulong  u64;

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

// started as [Ns][bb2 - b1]
kernel void decodeHuffman1(__global u8 payload[], u32 b1, u32 B2, __constant HuffmanTree trees[2][4], u8 huf_id, __global u32 lanes[], u32 lane_width, __constant u8 lane_indexes[]) {
	u8  C = get_global_id(0);
	u32 i = get_global_id(1);
	u32 bbi = b1 + i;
	u32 bb = bbi;
	u32 lane_index = lane_indexes[C] * lane_width + i;
	__constant HuffmanTreeNode* huf_dc = trees[0][huf_id];
	__constant HuffmanTreeNode* huf_ac = trees[1][huf_id];
	#pragma region DC
		u32 B = bb >> 3;
		if (B >= B2) {
			lanes[lane_index] = LANE_ERROR_VALUE;
			return;
		}
		u32 b = bb & 8;
		// u16 code word = a<<(b1+8) | b<<b1 | c<<(b1-8)
		u16 code = 0U
			| ((u16) payload[B+0] << (b + 8))
			| ((u16) payload[B+1] << (b + 0))
			| ((u16) payload[B+2] >> (8 - b))
		;
		u8Pair d_s = decodeHuffman(huf_dc, code);
		if (d_s.x == 17) {
			lanes[lane_index] = LANE_ERROR_VALUE;
			return;
		}
		// TODO store symbol
		bb += d_s.x + d_s.y;
	#pragma endregion
	
	#pragma region AC
		for (int ac_count = 0; ac_count < 63; ) {
			u32 B = bb >> 3;
			if (B >= B2) {
				lanes[lane_index] = LANE_ERROR_VALUE;
				return;
			}
			u32 b = bb & 8;
			// u16 code word = a<<(b1+8) | b<<b1 | c<<(b1-8)
			u16 code = 0U
				| ((u16) payload[B+0] << (b + 8))
				| ((u16) payload[B+1] << (b + 0))
				| ((u16) payload[B+2] >> (8 - b))
			;
			u8Pair d_s = decodeHuffman(huf_dc, code);
			if (d_s.x == 17) {
				lanes[lane_index] = LANE_ERROR_VALUE;
				return;
			}
			// TODO store symbol
			if (d_s.y == 0x00) {
				// TODO rest are 0
				ac_count = 63;
			} else if (d_s.y == 0xF0) {
				// TODO next 16 are 0
				ac_count += 16;
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
kernel void decodeRaiseN(__global u32 lanes[], u32 lane_width, u8 prev_size_pow, u8 lanes_count) {
	u8  x = get_global_id(0);
	u32 i = get_global_id(1);
	u8  lane_id = x * (1U << (prev_size_pow + 1)) % lanes_count;
	u8  next_id = lane_id + (1U << prev_size_pow);
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
kernel void decodeLower(__global u32 lanes[], u32 lane_width, u8 size_pow, u8 lanes_count, __global u32 positions[]) {
	u8  x = get_global_id(0);
	u32 i = get_global_id(1);
	u8  lane_id = x * (1U << (size_pow+1)) % lanes_count;
	u8  next_id = lane_id + (1U << size_pow);
	u32 row_width = lanes_count * lane_width;
	
	u32 p = lane_id * lane_width + i;
	u32 pos = positions[p];
	if (pos == LANE_ERROR_VALUE) { return; }
	u32 row_base = size_pow * row_width;
	u32 a = row_base + lane_id * lane_width + i;
	u32 data = lanes[a];
	// if (data == LANE_ERROR_VALUE) { return; }
	u32 q = next_id * lane_width + i + data;
	positions[q] = pos + (1U << size_pow);
}

kernel void initializeBufferU32(__global u32 buffer[], u32 value) {
	buffer[get_global_id(0)] = value;
}
