module testing;
import std::io;
import libc;

fn void test() @extern("test") @export {
	io::printn("Test passed lol!");
	libc::exit(0);
}
