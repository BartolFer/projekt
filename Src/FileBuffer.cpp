depend("./Test.cpp")
module;

#include <iostream>
#include <cstdint>
#include <fstream>

#ifdef VSCODE_ONLY
	#include "./Test.cpp"
#endif

export module FileBuffer;

#ifndef VSCODE_ONLY
	import Test;
#endif

namespace BJpeg {
	void freadExactlly(void* dst, size_t elm_size, size_t count, FILE* file) {
		size_t amount_read = 0;
		while (amount_read < count) {
			amount_read += fread(dst, elm_size, count, file);
		}
	}

	export struct InputFileBuffer {
		unsigned const half_block_size;
		InputFileBuffer(unsigned const half_block_size_pow, std :: string&& path) 
			: half_block_size(1 << half_block_size_pow), mask(2 * half_block_size - 1), buffer(new uint8_t[2 * half_block_size]), file(fopen(path.c_str(), "rb")) {}
		uint8_t& operator [](int offset) {
			unsigned index = (self.head + offset) & self.mask;
			return self.buffer[index];
		}
		void load() {
			self.head ^= self.half_block_size;
			freadExactlly(self.buffer + self.head, 1, self.half_block_size, self.file);
		}
		~InputFileBuffer() {
			delete[] self.buffer;
			fclose(self.file);
		}
		unsigned head = 0; // 0 or half_size
	private:
		unsigned const mask;
		uint8_t* const buffer;
		// std :: ifstream file;
		FILE* const file;
	};
	
	#ifdef TESTING
		class MyTest : Test {
			char const* getDescription() { return "InputFileBuffer Test"; }
			static constexpr inline char const* const path = "./_InputFileBufferTestFile_690074.bin";
			unsigned const half_block_size_pow = 3; // 8 bytes
			static constexpr char blocks[] {
				0x11,
				0x22,
				0x33,
				0x44,
			};
			void writeHalfBlock(char data, FILE* file) {
				for (int i = 0; i < (1 << half_block_size_pow); ++i) {
					fwrite(&data, 1, 1, file);
				}
			}
			void init() {
				FILE* file = fopen(path, "wb");
				for (auto data : blocks) { writeHalfBlock(data, file); }
				fflush(file);
				fclose(file);
			}
			bool test() {
				InputFileBuffer buffer(half_block_size_pow, std :: string(path));
				for (auto data : blocks) { 
					buffer.load();
					for (int i = 0; i < (1 << half_block_size_pow); ++i) { 
						if (buffer[i] != data) {
							fprintf(stderr, "Failed because 0x%X != 0x%X [%d]\n", buffer[i], data, i);
							for (int i = 0; i < 2*(1 << half_block_size_pow); ++i) { 
								fprintf(stderr, "%02X ", buffer[i]);
							}
							fprintf(stderr, "\n h = %d", buffer.head);
							return false;
						}
					}
				}
				return true;
			}
			void finish() {
				remove(path);
			}
		} test;
	#endif
}