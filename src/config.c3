module config;
import std::collections;
import std::io;
import toml;

def StrList = List(<String>);
def ExternCList = List(<External_C>);
def ExternC3List = List(<External_C3>);


struct External_C3 {
  String name;
  String url;
  String build_opt;
  String clone_flags;
  bool force_link;
}

struct External_C {
  String name;
  String url;
  String build_cmd;
  String clone_flags;
  String output_dir;
  StrList libs;
  bool link_switch;
}

struct Config {
  ExternCList ext_c;
  ExternC3List ext_c3;
}

fn Config! load_config(String file) {
  Config conf;
  String contents = readfile(file)!;
  TomlFile parsed = toml::parse_toml(contents)!;
  parsed.print_toml();
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
