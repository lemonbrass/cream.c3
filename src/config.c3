module config;
import std::collections;
import std::io;
import toml;

def StrList = List(<String>);
def ExternCList = List(<External_C>);
def ExternC3List = List(<External_C3>);


struct External_C3 {
  String name;        // required
  String url;         // required
  String commit_id;   // required
  String clone_flags;
  String build_opt;
  bool force_link;
}

struct External_C {
  String name;        // required
  String url;         // required
  String commit_id;   // required
  String build_cmd;   // required
  StrList libs;       // required
  String output_dir;  // defaults to build
  String clone_flags;
  bool link_switch;   // defaults to false
}

struct Project {
  String name;
  String author;
  String description;
  String version;
}

struct Config {
  Project project;
  ExternCList ext_c;
  ExternC3List ext_c3;
}

fault ConfigError {
  UNINDENTIFIED,
}

fn Config! load_config(String file) {
  Config conf;
  String contents = readfile(file)!;
  TomlFile parsed = toml::parse_toml(contents)!;
  parsed.print_toml();
  
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
  String name = file.get_val("project", "name")!;
  String desc = file.get_val("project", "description")!;
  String vers = file.get_val("project", "version")!;
  String author = file.get_val("project", "author")!;
  self.project.name = name;
  self.project.description = desc;
  self.project.author = author;
  self.project.version = vers;
}

fn void Config.print(&self) {
  io::printfn("%s {author: %s, desc: %s, vers: %s}", self.project.name, self.project.author, self.project.description, self.project.version);
}

