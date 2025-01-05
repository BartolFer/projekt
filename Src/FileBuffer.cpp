depend("./Test.cpp")
module;


#include <stdio.h>
#include <string>
#include <cstdint>
// #include <fstream>
#include <filesystem>

#ifdef VSCODE_ONLY
	#pragma once
	#include "./Test.cpp"
#endif

export module FileBuffer;

#ifndef VSCODE_ONLY
	import Test;
#endif

namespace BJpeg {
	size_t freadExactlly(void* dst, size_t elm_size, size_t count, FILE* file) {
		size_t amount_read = 0;
		while (amount_read < count) {
			amount_read += fread(dst, elm_size, count, file);
			if (feof(file)) { break; }
		}
		return amount_read;
	}
	
	#ifdef TESTING
		class MyTest;
	#endif

	// TODO EOF detection?
	// (at the moment, if someone tries to get data past the end, they will get some garbage value that was already in the buffer!
	// out-of-bounds access is not possible!)
	// we could leave it to the decoder (e.g. to check EOF before each entropy coded segment)
	export struct InputFileBuffer {
		unsigned const half_block_size;
		InputFileBuffer(unsigned const half_block_size_pow, std :: string&& path) 
			: half_block_size(1 << half_block_size_pow), mask(2 * half_block_size - 1), buffer(new uint8_t[2 * half_block_size]), file_size(std :: filesystem :: file_size(path)), file(fopen(path.c_str(), "rb")) {
		}
		uint8_t const& operator [](int offset) {
			if (offset >= self.file_size) { throw EOF; /* TODO */ }
			if (offset >= self.tail) { self.load(); }
			unsigned index = offset & self.mask;
			return self.buffer[index];
		}
		void load() {
			self.head ^= self.half_block_size;
			self.tail += freadExactlly(self.buffer + self.head, 1, self.half_block_size, self.file);
		}
		~InputFileBuffer() {
			delete[] self.buffer;
			fclose(self.file);
		}
		#ifdef TESTING
			friend class MyTest;
		#endif
	private:
		unsigned head = 0; // 0 or half_size
		size_t tail = 0;
		unsigned const mask;
		uint8_t* const buffer;
		size_t file_size;
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
				int index = 0;
				for (auto data : blocks) { 
					buffer.load();
					for (int i = 0; i < (1 << half_block_size_pow); ++i, ++index) { 
						if (buffer[index] != data) {
							fprintf(stderr, "Failed because 0x%X != 0x%X [%d]\n", buffer[index], data, i);
							for (int i = 0; i < 2*(1 << half_block_size_pow); ++i) { 
								fprintf(stderr, "%02X ", buffer[index]);
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