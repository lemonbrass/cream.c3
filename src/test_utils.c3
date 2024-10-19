module test;
import config;
import libc;
import std::io;

fn void! run_test(String name, Config* conf) {
  Test test = conf.tests.get(name)!;
  if (test.type == COMMAND) {
    libc::system((ZString)test.command);
  }else {
    io::printn("TODO");    
  }
}
