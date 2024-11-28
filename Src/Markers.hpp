#pragma once
#include <cstdint>

namespace BJpeg {
	namespace Marker {
		// Start Of Frame markers, non-differential, Huffman coding
		
		// Baseline DCT
		constexpr inline uint8_t SOF0 = 0xC0; 
		// Extended sequential DCT
		constexpr inline uint8_t SOF1 = 0xC1; 
		// Progressive DCT
		constexpr inline uint8_t SOF2 = 0xC2; 
		// Lossless (sequential)
		constexpr inline uint8_t SOF3 = 0xC3; 
		
		// Start Of Frame markers, differential, Huffman coding
		
		// Differential sequential DCT
		constexpr inline uint8_t SOF5 = 0xC5; 
		// Differential progressive DCT
		constexpr inline uint8_t SOF6 = 0xC6; 
		// Differential lossless (sequential)
		constexpr inline uint8_t SOF7 = 0xC7; 
		
		// Start Of Frame markers, non-differential, arithmetic coding
		
		// Reserved for JPEG extensions
		constexpr inline uint8_t JPG = 0xC8; 
		// Extended sequential DCT
		constexpr inline uint8_t SOF9 = 0xC9; 
		// Progressive DCT
		constexpr inline uint8_t SOF10 = 0xCA; 
		// Lossless (sequential)
		constexpr inline uint8_t SOF11 = 0xCB; 

		// Start Of Frame markers, differential, arithmetic coding
		
		// Differential sequential DCT
		constexpr inline uint8_t SOF13 = 0xCD; 
		// Differential progressive DCT
		constexpr inline uint8_t SOF14 = 0xCE; 
		// Differential lossless (sequential)
		constexpr inline uint8_t SOF15 = 0xCF; 
		
		// other
		
		// Define Huffman table(s)
		constexpr inline uint8_t DHT = 0xC4; 
		// Define arithmetic coding conditioning(s)
		constexpr inline uint8_t DAC = 0xCC; 
		
		// RSTn Restart with modulo 8 count n
		constexpr inline uint8_t RST(uint8_t n) { return 0xD0 + n; }
		// RSTn Restart with modulo 8 count n
		constexpr inline bool isRST(uint8_t rst) { return 0xD0 <= rst && rst <= 0xD7; }
		
		// Start of image
		constexpr inline uint8_t SOI = 0xD8; 
		// End of image
		constexpr inline uint8_t EOI = 0xD9; 
		// Start of scan
		constexpr inline uint8_t SOS = 0xDA; 
		// Define quantization table(s)
		constexpr inline uint8_t DQT = 0xDB; 
		// Define number of lines
		constexpr inline uint8_t DNL = 0xDC; 
		// Define restart interval
		constexpr inline uint8_t DRI = 0xDD; 
		// Define hierarchical progression
		constexpr inline uint8_t DHP = 0xDE; 
		// Expand reference component(s)
		constexpr inline uint8_t EXP = 0xDF; 
		
		// APPn Reserved for application segments 
		constexpr inline uint8_t APP(uint8_t n) { return 0xE0 + n; }
		// APPn Reserved for application segments 
		constexpr inline bool isAPP(uint8_t app) { return 0xE0 <= app && app <= 0xEF; }
		
		// JPGn Reserved for JPEG extensions
		constexpr inline uint8_t JPGn(uint8_t n) { return 0xF0 + n; }
		// JPGn Reserved for JPEG extensions
		constexpr inline uint8_t isJPGn(uint8_t jpg) { return 0xF0 <= jpg && jpg <= 0xFD; }
		
		// Comment
		constexpr inline uint8_t COM = 0xFE; 
		
		// For temporary private use in arithmetic coding
		constexpr inline uint8_t TEM = 0x01; 
		
		// idk
		constexpr inline uint8_t FFF = 0xFF; 
	};
}