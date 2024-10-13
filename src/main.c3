module test;
import std::io;
import projutil;
import tomlmake;
import arga;
import toml;



fn int main(String[] args)
{
  ArgLike create_project = arga::make_arg_opt("create", "Make project", &projutil::create_proj);
  ArgLike*[] list = { &create_project };
  defer arga::free_args(list);

  if (catch err = arga::argparse(args, list)){
    io::printfn("An error ocurred %s, halting", err);
    return 1;
  }

  const String FILE = "cream.toml";
  String contents = readfile(FILE)!!;
  TomlFile f = toml::parse_toml(contents)!!;
  TomlBuilder b;
  defer b.free();
  defer contents.free();
  defer f.free();

  print_toml(&f);
  
  b.add_global("globalstuff", "\"ahahaha\"");
  b.add_section("project");
  b.get_section("project")!!
  .add_field("name", "\"idk\"")
  .add_field("author", "\"a man\"");
  io::printn(b.get_string());
  return 0;
}

fn void print_toml(TomlFile* f) {
  foreach(s : f.sections){
    io::printfn("\n%s\n", s.name);
    foreach(fi : s.fields) io::printfn("%s : %s", fi.key, fi.val);
  }
}

fn String! readfile(String file){
  usz size = file::get_size(file)!;
  char* ptr = malloc((size+4) * char.sizeof);
  char[] buff = ptr[0..size+4];
  File f = file::open(file, "r")!;
  f.read(buff)!;
  return (String)buff;
}
