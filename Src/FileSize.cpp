module;

// #if defined (__unix__) || (defined (__APPLE__) && defined (__MACH__))
// 	#include <sys/stat.h>
// #elif defined(WIN32) || defined(_WIN32) || defined(__WIN32__) || defined(__NT__)
// 	#include "windows.h"
// #else
// 	#error "Unknown OS"
// #endif

export module FileSize;

export size_t getFileSize(FILE*)