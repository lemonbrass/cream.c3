module projutil;
import std::io;
import arga;

const String CREAM_TOML_BASIC = $embed("../resources/cream.toml.meta");
const String EXTERNAL_C_META = $embed("../resources/external.c.meta");
const String EXTERNAL_C3_META = $embed("../resources/external.c3.meta");


fn void! create_proj(ArgLike* arg) {
  io::printn("I will ask you a couple of questions for generating project.");
  String projname = prompt("What's the project name: ")!; 
  String version = prompt("What's initial version: ")!;
  String author = prompt("What's author name: ")!;
  String description = prompt("What's the project about (description): ")!;
  DString gen_toml;
  DString buff;
  defer {
    gen_toml.free();
    projname.free();
    version.free();
    author.free();
    description.free();
    buff.free();
  }
  gen_toml.appendf(CREAM_TOML_BASIC, projname, version, author, description);
  
  Path path = path::new(projname)!;
  path::mkdir(path)!;
  path.free();
  
  buff.appendf("%s/cream.toml", projname);
  File cream_conf = file::open(buff.str_view(), "w")!;

  cream_conf.write(gen_toml.str_view())!;
  
  io::printfn("Generated project %s, you should probably add a better description", projname);
}

fn String! prompt(String msg) {
  io::print(msg);
  return io::readline();
}
