module;

#include <concepts>

export module BJpg.Misc;

export namespace BJpg {
	template <typename T, typename... Args>
	concept IsResource = requires(T t, Args... args) {
		t.init(args...);
		{ t.finish() } noexcept;
	};
	// template <typename T, typename... Args> requires (IsResource<T, Args...>)
	// struct Resource : T {
	// 	explicit Resource(T t, Args... args) : this(t) {
	// 		self.init(args...);
	// 	}
	// 	explicit Resource(Args... args) {
	// 		self.init(args...);
	// 	}
	// 	~Resource() {
	// 		self.finish();
	// 	}
	// };
}