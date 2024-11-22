depend("./Test.cpp", "./FileBuffer.cpp")


#ifdef VSCODE_ONLY
	#include "./FileBuffer.cpp"
	#include "./Test.cpp"
#else
	import FileBuffer;
	import Test;
#endif

int main() {
	#ifdef TESTING
		BJpeg :: Test :: runTests();
	#endif
}