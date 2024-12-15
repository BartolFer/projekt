module;

#include <string.h>

#ifdef VSCODE_ONLY
	#include "../FileBuffer.cpp"
#endif

export module Decode.Huffman;

#ifndef VSCODE_ONLY
	import FileBuffer;
#endif


namespace BJpeg {
	export struct ValueAndLength {
		uint16_t length;
		uint8_t value;
	};
	export struct HuffmanTree {
		void reset() {
			memset(self.nodes, 0, sizeof(self.nodes));
			self._last_assigned_index = 0;
		}
		void update(uint16_t code, uint8_t length, uint8_t value) {
			uint16_t node = 0;
			for (uint8_t i = length; i > 0; --i) {
				auto bit = (code >> (i - 1)) & 1;
				auto& box = bit == 0 ? self.nodes[node].left : self.nodes[node].right_or_data;
				if (box == 0) { box = ++self._last_assigned_index; }
				node = box;
			}
			self.nodes[node] = { 0, value };
		}
		
		ValueAndLength operator [](uint16_t bits) {
			uint16_t index = 0;
			for (uint8_t depth = 0; ; ++depth) {
				auto node = self.nodes[index];
				if (node.left == 0) {
					return {depth, node.right_or_data};
				}
				index = (bits >> 15) == 0 ? node.left : node.right_or_data;
			}
		}
		
	private:
		uint16_t _last_assigned_index = 0;
	
		// might be possible with u8 by using offsets (but i couldn't be bothered to verify that)
		struct Node {               // either {0, data} or {left, right}
			uint16_t left;          // if left == 0, then next byte is data
			uint16_t right_or_data; // else, left and right are indexes of left and right nodes
		} nodes[256 + 255]; 
			// tree is full, which means that number of inner nodes = number of leaves - 1
			// there is at most 256 values (leaves) in jpg, since values are 8 bit
		
			// going sequentially through this array is equivalent to pre-order traversal
	};
}