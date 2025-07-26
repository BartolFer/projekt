#include <iostream>
#include <filesystem>
#define fun
#define self (*this)
namespace MyOpenCL {
	template <typename T> struct Buffer;
}
//	#include "../Src/Util.zzc"
#include "../Src/MyOpenCL.zzc"

fun int main(int argc, char* argv[]) {
	if (argc != 2) {
		printf("Usage: <exe> path/to/x.cl\n");
		return EXIT_FAILURE;
	}
	char* path = argv[1];
	
	size_t size = std :: filesystem :: file_size(path);
	FILE* file = fopen(path, "r");
	defer { fclose(file); };
	auto cl = new char[size + 1];
	fread(cl, sizeof(char), size, file);
	
	cl_device_id device; if (!MyOpenCL :: getDeviceId(device)) { printf("Failed getting device   <%s>\n", path); return EXIT_FAILURE; }
	BJpeg :: Resource<MyOpenCL :: Context> context(device             ); if (!context) { printf("Failed creating context   <%s>\n", path); return EXIT_FAILURE; }
	BJpeg :: Resource<MyOpenCL :: Queue  > queue  (device, context    ); if (!queue  ) { printf("Failed creating queue     <%s>\n", path); return EXIT_FAILURE; }
	BJpeg :: Resource<MyOpenCL :: Program> program(device, context, cl); if (!program) { printf("Failed building program   <%s>\n", path); return EXIT_FAILURE; }
	
	printf("OK   <%s>\n", path);
}