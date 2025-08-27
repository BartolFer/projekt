#include <iostream>
#include <filesystem>
#define fun
#define self (*this)
namespace MyOpenCL {
	template <typename T> struct Buffer;
}
//	#include "../Src/Util.zzc"
#include "../../Src/MyOpenCL.zzc"
	
fun int main(int argc, char* argv[]) {
	if (argc != 2) {
		printf("Usage: <exe> path/to/x.cl\n");
		return EXIT_FAILURE;
	}
	char* path = argv[1];
	
	size_t size = std :: filesystem :: file_size(path);
	//	printf("size = %zu\n", size);
	FILE* file = fopen(path, "r");
	defer { fclose(file); };
	auto cl = new char[size + 1];
	defer { delete[] cl; };
	size_t readed = fread(cl, sizeof(char), size, file);
	cl[readed] = '\0';
	//	printf("<%s>\nsize = %zu but c thinks: %zu and readed = %zu\n", cl + size, size, strlen(cl), readed);
	
	cl_device_id device; if (!MyOpenCL :: getDeviceId(device)) { printf("Failed getting device   <%s>\n", path); return EXIT_FAILURE; }
	BJpeg :: Resource<MyOpenCL :: Context> context(device             ); if (!context) { printf("Failed creating context   <%s>\n", path); return EXIT_FAILURE; }
	BJpeg :: Resource<MyOpenCL :: Queue  > queue  (device, context    ); if (!queue  ) { printf("Failed creating queue     <%s>\n", path); return EXIT_FAILURE; }
	BJpeg :: Resource<MyOpenCL :: Program> program(device, context, cl); 
	if (!program) { 
		char log[1024] = { 0 };
		size_t actual_size = 0;
		auto err = clGetProgramBuildInfo(program.program, device, CL_PROGRAM_BUILD_LOG, 1023, log, &actual_size);
		printf("reading log returned: %d  size of log: %zu\n", err, actual_size);
		if (err == CL_SUCCESS) { printf("<%.1023s>\n", log); }
		printf("Failed building program   <%s>\n", path); 
		return EXIT_FAILURE;
	}
	
	printf("OK   <%s>\n", path);
}