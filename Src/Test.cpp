module;

#include <vector>
#include <iostream>

export module Test;

namespace BJpeg {
	#ifdef TESTING
		export struct Test {
			virtual char const* getDescription() = 0;
			virtual bool test() = 0;
			
			virtual void init() {}
			virtual void finish() {}
			
			Test() {
				Test :: tests.push_back(this);
			}
			
			static void runTests() {
				for (auto test : tests) {
					test->init();
					if (!test->test()) {
						std :: cerr << "\n\t\t" << "Test <" << test->getDescription() << "> failed" << std :: endl;
					}
					test->finish();
				}
				std :: cerr << "\n\t\t" << "Finished with " << tests.size() << " tests" << std :: endl;
			}
		private:
			static inline std :: vector<Test*> tests;
		};
	#endif
}