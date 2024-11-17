module;
#include <iostream>

export module m.a;

export auto& af() {
	return std :: cout << "hello ";
}
