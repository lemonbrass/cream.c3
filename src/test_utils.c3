module test;
import toml;
import std::collections;

def TestList = List(<Test>);
enum TestType { COMMAND, SCRIPT }

struct Test {
  TestType type;
  String name;
  union {
    String cmd;
    TomlList sources;
  }
}

fn TestList! read_tests(SectionList sections) {
  TestList tests;
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
    tests.push(test);
  }
  return tests;
}

fn void Test.free(&self) {
  self.name.free();
  if (self.type == COMMAND) {
    self.cmd.free();
  } else {
    self.sources.free();
  }
}
