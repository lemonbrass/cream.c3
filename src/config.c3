module config;
import std::collections;
import std::io;
import toml;
import utils;
import test;
import deps;
import project;
import install;
import optional;

def TargetMap = Map(<String, Target>);
def StringOpt = Optional(<String>);
def InstallerOpt = Optional(<InstallPreset>);

struct Target {
  String flags;
  StringOpt build_cmd;
  StringOpt afterbuild_cmd;
}

struct Config {
  Project project;
  TargetMap targets;
  TestMap tests;
  ExternDepsMap ext_deps;
  InstallerOpt install;
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
  InstallPreset! install = install::read_toml(&&parsed.find_section("install")!);
  conf.install.@unwrap(install);
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
  self.ext_deps.read_c(file)!;
}

fn void! Config.read_targets(&self, TomlFile* file) {
  SectionList sections = file.get_subsections("target");
  foreach (sec : sections) {
    Target target;
    target.flags = sec.find_val("flags").copy_str()!;
    DString! cmd = sec.find_val("before-build");
    target.build_cmd.@unwrap(cmd.copy_str());
    cmd = sec.find_val("after-build");
    target.afterbuild_cmd.@unwrap(cmd.copy_str());
    self.targets.set(sec.name.str_view(), target);
  }
}

fn void Config.print(&self) {
  io::printfn("%s {author: %s, desc: %s, vers: %s, src: %s}", self.project.name, self.project.author, self.project.description, self.project.version, self.project.src_dirs.data);

  self.targets.@each(; String name, Target t) {
    io::printfn("target %s: %s", name, t.flags);
  };

  self.ext_deps.@each(; String hash, ExternDep t) {
    io::printfn("Dependency %s: %s & %s", t.name, t.type, t.hash);
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
  self.build_cmd.free();
  self.afterbuild_cmd.free();
}

fn void Config.free(&self) {
  self.tests.@each(; String key, Test val) {
    val.free();
  };
  self.targets.@each(; String key, Target val) {
    val.free();
  };
  self.ext_deps.@each(; String name, ExternDep ext_c) {
    ext_c.free();
  };
  self.project.free();
  self.targets.free();
  self.ext_deps.free();
  self.project.free();
  self.install.free();
}
