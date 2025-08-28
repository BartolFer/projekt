#include <iostream>
#include <string>
#include <cstdint>
#include "../../Library/Static/include/BJpeg.hpp"
#include "../Metadata.hpp"

using namespace BJpeg;

int main(int argc, char* argv[]) {
	if (argc > 3) {
		printf("Usage: <exe> path/to/file.jpg path/to/output.rgba\n");
		exit(EXIT_FAILURE);
	}
	std :: string path      = argc >= 2 ? argv[1] : "D:/Personal/nastava/projekt/Temp/Zugpsitze_mountain.jpg";
	char const* output_path = argc >= 3 ? argv[2] : "D:/Personal/nastava/projekt/Temp/output.rgba";
	
	using namespace BJpeg;
	
	Resource<Decode :: InputFileBuffer> file(path);
	if (!file   ) { std :: cerr << "!file"    << std :: endl; return 1; }
	Resource<Decode :: Context> context;
	if (!context) { std :: cerr << "!context" << std :: endl; return 1; }
	
	auto res = Decode :: image(context, file, 0);
	defer { context.cl.buffer.image.finish(); };
	std :: cout << "res = " << res << std :: endl;
	
	if (res == 0) { return EXIT_FAILURE; }
	if (res != file.length) { return EXIT_FAILURE; }
	
	MetaData metadata = { .width = (int) context.size.x_mayor, .height = (int) context.size.y_mayor, .n_channels = 4 };
	size_t total_pixels = metadata.height * metadata.width;
	RGBA* arr = new RGBA[total_pixels];
	if (!context.cl.buffer.image.read(context.cl.queue, arr)) { clog("Failed to read result image buffer"); return EXIT_FAILURE; }
	
	FILE* output = fopen(output_path, "wb");
	if (output == nullptr) { clog("Failed to open output file %s", output_path); return EXIT_FAILURE; }
	defer { fclose(output); };
	fwrite(&metadata, sizeof(metadata), 1, output);
	fwrite(arr, sizeof(RGBA), total_pixels, output);
	printf("Created file %s\n", output_path);
	
	return 0;
}

