module config;
import std::collections;
import std::io;
import toml;
import utils;
import test;
import deps;
import project;
import install;

def TargetMap = Map(<String, Target>);


struct Target {
  String flags;
  StringOpt build_cmd;
  StringOpt afterbuild_cmd;
}

struct Config {
  Project project;
  TargetMap targets;
  TestMap tests;
  ExternCMap ext_c;
  ExternC3Map ext_c3;
  InstallPreset install;
}

fault ConfigError {
  UNINDENTIFIED,
}


fn Config! load_file(String file) {
  String contents = readfile(file)!;
  defer contents.free();
  return load(contents);
}

fn Config! load(String data) {
  Config conf;
  TomlFile parsed = toml::parse_toml(data)!;
  defer parsed.free();
  conf.read_toml(&parsed)!;
  conf.install = install::read_toml(&&parsed.find_section("install")!)!;
  return conf;  
}

fn String! readfile(String file){
  usz size = file::get_size(file)!;
  char* ptr = malloc((size+4) * char.sizeof);
  char[] buff = ptr[0..size+4];
  File f = file::open(file, "r")!;
  f.read(buff)!;
  return (String)buff;
}

fn void! Config.read_toml(&self, TomlFile* file) {
  self.project = project::read_project(file)!;
  self.read_targets(file)!;
  self.tests = test::read_tests(file.get_subsections("test"), self.project)!;
}


fn void! Config.read_targets(&self, TomlFile* file) {
  SectionList sections = file.get_subsections("target");
  foreach (sec : sections) {
    Target target;
    target.flags = sec.find_val("flags").copy_str()!;
    DString! cmd = sec.find_val("before-build");
    target.build_cmd = utils::@from_dstr_err(cmd);
    cmd = sec.find_val("after-build");
    target.afterbuild_cmd = utils::@from_dstr_err(cmd);
    self.targets.set(sec.name.str_view(), target);
  }
}

fn void Config.print(&self) {
  io::printfn("%s {author: %s, desc: %s, vers: %s, src: %s}", self.project.name, self.project.author, self.project.description, self.project.version, self.project.src_dirs.data);

  self.targets.@each(; String name, Target t) {
    io::printfn("target %s: %s", name, t.flags);
  };
  
  self.tests.@each(; String name, Test test) {
    if (test.type == COMMAND) {
      io::printfn("Test %s: %s, %s", test.name, test.type, test.cmd);
    } else {
      io::printfn("Test %s: %s, %s", test.name, test.type, test.sources.data);
    }
  };
}

fn void Target.free(&self) {
  self.flags.free();
  self.build_cmd.str.free();
  self.afterbuild_cmd.str.free();
}

fn void Config.free(&self) {
  self.tests.@each(; String key, Test val) {
    val.free();
  };
  self.targets.@each(; String key, Target val) {
    val.free();
  };
  self.ext_c.@each(; String name, External_C ext_c) {
    ext_c.free();
  };
  self.ext_c3.@each(; String name, External_C3 ext_c3) {
    ext_c3.free();
  };
  self.project.free();
  self.targets.free();
  self.ext_c.free();
  self.ext_c3.free();
  self.project.free();
  self.install.free();
}
