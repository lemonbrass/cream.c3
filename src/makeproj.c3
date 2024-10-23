module project;
import std::io;
import main;
import config;
import arga;
import build;
import utils;
import toml;

const String CREAM_TOML_BASIC = $embed("../resources/cream.toml.meta");
const String EXTERNAL_C_META = $embed("../resources/external.c.meta");
const String EXTERNAL_C3_META = $embed("../resources/external.c3.meta");
const String EXAMPLE_MAIN_C3 = $embed("../resources/src.main.c3");


fn void! create_proj(ArgLike* arg) {
  DString gen_toml;
  String projname = ask_ques(&gen_toml)!;
  defer projname.free();
  write_toml(projname, &gen_toml)!;
  build_filetree(projname, gen_toml.str_view())!;
  io::printfn("Generated project %s, you should probably add a better description", projname);
}

fn void! init_proj(ArgLike* arg) {
  DString gen_toml;
  String projname = ask_ques(&gen_toml)!;
  Path path = path::new(projname)!;
  defer path.free();
  path::mkdir(path)!;
  defer projname.free();
  write_toml(".", &gen_toml)!;
  build_filetree(".", gen_toml.str_view())!;
  io::printfn("Initialized project %s successfully!", projname);
}

fn String! ask_ques(DString* gen_toml) {
  io::printn("I will ask you a couple of questions for generating project.");
  String projname = prompt("What's the project name: ")!; 
  String version = prompt("What's initial version: ")!;
  String author = prompt("What's author name: ")!;
  String description = prompt("What's the project about (description): ")!;
  defer {
    version.free();
    author.free();
    description.free();
  }
  gen_toml.appendf(CREAM_TOML_BASIC, projname, version, author, description);
  return projname;
}

fn void! write_toml(String projname, DString* gen_toml) {
  DString buff;
  defer buff.free();
  buff.appendf("%s%ccream.toml", projname, path_ch());
  File cream_conf = file::open(buff.str_view(), "w")!;
  cream_conf.write(gen_toml.str_view())!;
  cream_conf.close()!;
}



fn void! build_filetree(String projname, String gen_toml) {
  Config conf = config::load(gen_toml)!;
  String build_dir = concat(projname, path_str(), conf.project.build_dir);
  Path build_path = path::new(build_dir)!;
  defer {
    build_path.free();
    build_dir.free();
  };
  path::mkdir(build_path)!;
  
  StrList sources = conf.project.src_dirs.data;
  foreach (src : sources) {  
    String src_dir = concat(projname, path_str(), src);
    Path src_path = path::new(src_dir)!;
    path::mkdir(src_path)!;
    src_path.free();
    src_dir.free();
  }

  String example_path = concat(projname, path_str(), sources[0], path_str(), "main.c3");
  defer example_path.free();
  File example = file::open(example_path, "w")!;
  example.write(EXAMPLE_MAIN_C3)!;
  example.close()!;
}

fn String! prompt(String msg) {
  io::print(msg);
  return io::readline();
}
