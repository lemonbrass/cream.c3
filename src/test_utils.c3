module test;
import toml;
import std::collections;
import std::io;
import libc;

def TestMap = HashMap(<String, Test>);
enum TestType { COMMAND, SCRIPT }

struct Test {
  TestType type;
  String name;
  union {
    String cmd;
    TomlList sources;
  }
}

fn TestMap! read_tests(SectionList sections) {
  TestMap tests;
  foreach (sec : sections) {
    Test test;
    test.name = sec.name.copy_str();
    String typestr = sec.find_val("type")!.str_view();
    if (typestr == "command") {
      test.type = COMMAND;
      test.cmd = sec.find_val("command")!.copy_str();
    }
    else {
      test.type = SCRIPT;
      test.sources.read(sec.find_val("sources")!.str_view())!;
    }
    tests.set(test.name, test);
  }
  return tests;
}

fn void! Test.run(&self) {
  io::printfn("Running test %s...", self.name);
  if (self.type == COMMAND) {
    CInt res = libc::system((ZString) self.cmd);
    if (res != 0) {
      io::eprintfn("Command %s failed with exit code %s :(", self.cmd, res);
    }
  }
  else {
    io::printn("TODO");
  }
}

fn void Test.free(&self) {
  self.name.free();
  if (self.type == COMMAND) {
    self.cmd.free();
  } else {
    self.sources.free();
  }
}
