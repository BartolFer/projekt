depend("./m/a.cpp", )

#include <iostream>
#include <vector>

#ifndef VSCODE_ONLY
import m.a;
#endif

template <typename T, typename... Args>
concept ConstructorArguments = requires (Args... args) {
	T(args...);
};

#include <concepts>
#include <utility>

template <typename T>
struct Coll {
	template <typename... Args>
	requires std::constructible_from<T, Args...>
	T f(Args&&... args) {
		return T(std::forward<Args>(args)...);
	}
};

struct Person {
	Person(int x, int y) {}
	
};

int main() {
	decltype(std :: cout)& o = af();
	std :: vector<Person> v;
	v.emplace_back(4, 5);
	Coll<Person> c;
	auto p = c.f(4, 5);
	o << "World\n" << -8844;
}
