module test;
import toml;
import std::collections;
import std::io;
import libc;
import config;
import utils;
import build;

const String TEST_FLAGS = "-O5";

def TestMap = HashMap(<String, Test>);
enum TestType { COMMAND, SCRIPT }

struct Test {
  TestType type;
  String name;
  Project project;
  union {
    String cmd;
    TomlList sources;
  }
}

fn TestMap! read_tests(SectionList sections, Project project) {
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
    test.project = project;
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
    self.build_scripts()!;
    String outfile = concat(".", path_str(), self.project.build_dir, path_str(), "tmp", path_str(), self.name);
    defer outfile.free();
    CInt res = libc::system((ZString) outfile);
    if (res != 0) {
      io::eprintfn("Script %s failed with exit code %s :(", outfile, res);
    }
  }
}

fn void! Test.build_scripts(&self) {
  String output = concat(self.project.build_dir, path_str(), "tmp");
  defer output.free();
  foreach (src : self.project.src_dirs.data) {
    self.sources.data.push(src);
  }
  Build buildobj = build::new_temp(output, self.sources.data, TEST_FLAGS, self.name)!;
  buildobj.build()!;
}

fn void Test.free(&self) {
  self.name.free();
  if (self.type == COMMAND) {
    self.cmd.free();
  } else {
    self.sources.free();
  }
}
