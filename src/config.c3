module config;
import std::collections;
import std::io;
import toml;
import utils;
import test;

const String PROJ_BUILD_DIR = "build/";

def TargetMap = Map(<String, Target>);
def ExternCList = List(<External_C>);
def ExternC3List = List(<External_C3>);


struct External_C3 {
  String name;        // required
  String url;         // required
  String commit_id;   // required
  TomlList libs;
  String clone_flags;
  String build_opt;
  bool force_link;
}

struct External_C {
  String name;        // required
  String url;         // required
  String commit_id;   // required
  String build_cmd;   // required
  TomlList libs;      // required
  String output_dir;  // defaults to build
  String clone_flags;
  bool link_switch;   // defaults to false
}

struct Project {
  String name;
  String author;
  String description;
  String version;
  String build_dir;
  TomlList src_dirs;
}

struct Target {
  String flags;
  StringOpt build_cmd;
  StringOpt afterbuild_cmd;
}

struct Config {
  Project project;
  TargetMap targets;
  ExternCList ext_c;
  ExternC3List ext_c3;
  TestMap tests;
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
  self.read_project(file)!;
  self.read_targets(file)!;
  self.tests = test::read_tests(file.get_subsections("test"), self.project)!;
}

fn void! Config.read_project(&self, TomlFile* file) {
  String name = file.get_val("project", "name")!;
  String desc = file.get_val("project", "description")!;
  String vers = file.get_val("project", "version")!;
  String author = file.get_val("project", "author")!;
  String src_dirs = file.get_val("project", "sources")!;
  String! errbuild_dir = file.get_val("project", "build-directory");
  StringOpt build_dir = utils::@from_err(errbuild_dir);
  self.project.build_dir = build_dir.get_def("build/").path_strip();
  self.project.name = name;
  self.project.description = desc;
  self.project.author = author;
  self.project.version = vers;
  self.project.src_dirs.read(src_dirs)!;
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

fn void Project.free(&self) {
  self.name.free();
  self.author.free();
  self.description.free();
  self.src_dirs.free();
}

fn void Target.free(&self) {
  self.flags.free();
  self.build_cmd.str.free();
  self.afterbuild_cmd.str.free();
}

fn void External_C.free(&self) {
  self.name.free();      
  self.url.free();
  self.commit_id.free(); 
  self.build_cmd.free(); 
  self.libs.free();     
  self.output_dir.free();
  self.clone_flags.free();
}

fn void External_C3.free(&self) {
  self.name.free();      
  self.url.free();
  self.commit_id.free(); 
  self.build_opt.free(); 
  self.libs.free();     
  self.clone_flags.free();
}

fn void Config.free(&self) {
  self.targets.@each(; String key, Target val) {
    val.free();
  };
  self.tests.@each(;String name, Test test) {
    test.free();
  };
  foreach (ext_c : self.ext_c) ext_c.free();
  foreach (ext_c3 : self.ext_c3) ext_c3.free();
  self.targets.free();
  self.ext_c.free();
  self.ext_c3.free();
  self.project.free();
}
