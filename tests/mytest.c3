module testing;
import std::io;

fn void test() @extern("test") {
	io::printn("Test passed lol!");
}
