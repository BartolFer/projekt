#include <iostream>
#include <string>
#include <cstdint>
#include "../../Library/Static/include/BJpeg.hpp"
#include "../Metadata.hpp"

using namespace BJpeg;

bool parseSF(char const* arg, SamplingFactor sampling_factors[]);

int main(int argc, char* argv[]) {
	if (argc > 5) {
		printf("Usage: <exe> path/to/file.rgba path/to/definitions/jpg path/to/output.jpg sampling_factors\n");
		exit(EXIT_FAILURE);
	}
	char const* path        = argc >= 2 ? argv[1] : "D:/Personal/nastava/projekt/Temp/output.rgba";
	std :: string def_path  = argc >= 3 ? argv[2] : "D:/Personal/nastava/projekt/Temp/Zugpsitze_mountain.def.jpg";
	char const* output_path = argc >= 4 ? argv[3] : "D:/Personal/nastava/projekt/Temp/Zugpsitze_mountain.out.jpg";
	char const* sfs         = argc >= 5 ? argv[4] : "";
	
	FILE* file_rgba = fopen(path, "rb");
	if (!file_rgba) { printf("Failed to open file %s\n", path); }
	defer { fclose(file_rgba); };
	
	MetaData metadata;
	if (fread(&metadata, sizeof(metadata), 1, file_rgba) != 1) {
		printf("Failed to read metadata from file %s\n", path);
		return EXIT_FAILURE;
	}
	size_t total_pixels = metadata.height * metadata.width;
	RGBA* arr = new RGBA[total_pixels];
	if (fread(arr, sizeof(RGBA), total_pixels, file_rgba) != total_pixels) {
		printf("Failed to read image data from file %s\n", path);
		return EXIT_FAILURE;
	}
	
	Resource<Encode :: CLContext> cl;
	Resource<MyOpenCL :: Buffer<RGBA>> image(cl.context, /* CL_MEM_HOST_WRITE_ONLY | */ CL_MEM_READ_ONLY, total_pixels);
	if (!image) { std :: cerr << "!image" << std :: endl; return EXIT_FAILURE; }
	if (!image.write(cl.queue, arr)) { std :: cerr << "!image.write" << std :: endl; return EXIT_FAILURE; }
	
	QuantizationTable qtables[4];
	
	if (!Encode :: ReadJpegDef(def_path, qtables)) {
		std :: cerr << "Failed to read JPEG definitions from " << def_path << std :: endl;
		return EXIT_FAILURE;
	}
	
	//	SamplingFactor sampling_factors[MAX_COMPONENTS] = {{ 1, 1 }, { 2, 2 }, { 2, 2 }};
	//	SamplingFactor sampling_factors[MAX_COMPONENTS] = {{ 2, 2 }, { 1, 1 }, { 1, 1 }};
	SamplingFactor sampling_factors[MAX_COMPONENTS] = {{ 1, 1 }, { 1, 1 }, { 1, 1 }};
	if (!parseSF(sfs, sampling_factors)) { std :: cerr << "invalid SF" << std :: endl;  return EXIT_FAILURE; }
	
	auto res = Encode :: image(image, cl, metadata.height, metadata.width, qtables, sampling_factors);
	std :: cout << "res len = " << res.length << std :: endl;
	if (!res) { return EXIT_FAILURE; }
	defer { res.finish(); };
	
	FILE* output = fopen(output_path, "wb");
	if (output == nullptr) { clog("Failed to open output file %s", output_path); return EXIT_FAILURE; }
	defer { fclose(output); };
	fwrite(res.array, sizeof(res[0]), res.length, output);
	printf("Created file %s\n", output_path);
	
	return 0;
}
bool parseSF(char const* arg, SamplingFactor sampling_factors[]) {
	signed char sf_y = 1, sf_x = 1;
	if (arg[0] == '\0') { return true; }
	if (arg[1] == '\0') {
		sf_y = sf_x = arg[0] - '0';
	} else if (arg[2] != '\0') {
		return false;
	} else {
		sf_y = arg[0] - '0';
		sf_x = arg[1] - '0';
	}
	if (!(0 <= sf_y && sf_y <= 9)) { return false; }
	if (!(0 <= sf_x && sf_x <= 9)) { return false; }
	if (sf_y * sf_x + 1 + 1 > MAX_MCU_LENGTH) { return false; }
	
	sampling_factors[0].y = sf_y;
	sampling_factors[0].x = sf_x;
	return true;
}
