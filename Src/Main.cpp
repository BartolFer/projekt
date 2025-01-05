depend("./Test.cpp", "./FileBuffer.cpp", "./Decode/Decoder.cpp", "./Decode/Context.cpp", "./Decode/Huffman.cpp", )

#include <iostream>

#ifdef VSCODE_ONLY
	#include "./FileBuffer.cpp"
	#include "./Decode/Decoder.cpp"
	#include "./Decode/Context.cpp"
	#include "./Decode/Huffman.cpp"
	#include "./Test.cpp"
#else
	import FileBuffer;
	import Decode;
	import Decode.Huffman;
	import Decode.Context;
	// import Context;
	import Test;
#endif

int main() {
	// #ifdef TESTING
	// 	BJpeg :: Test :: runTests();
	// #endif
	BJpeg :: InputFileBuffer file(14, "D:/temp/Zugpsitze_mountain.jpg");
	BJpeg :: Context context;
	auto res = BJpeg :: image(context, file, 0);
	FILE* context_file = fopen("D:/temp/jpg_context.txt", "w");
	fprintf(context_file, "SOF = %s %s %d\n", context.sof_data.arithmetic ? "A" : "H", context.sof_data.differential ? "d" : "n", context.sof_data.mode);
	fprintf(context_file, "X=%u y=%u r=%u p=%u\n", context.X, context.Y, context.restart_interval, context.precision);
	for (int i = 0; i < 2; ++i) {
		for (int j = 0; j < 2; ++j) {
			auto& ht = context.huffman_tree[i][j];
			fprintf(context_file, "H[%d][%d] |", i, j);
			for (int k = 0; k < 256+255; ++k) {
				fprintf(context_file, "%3u,%3u|", ht.nodes[k].left, ht.nodes[k].right_or_data);
			}
			fprintf(context_file, "\n");
		}
		fprintf(context_file, "\n");
	}
}