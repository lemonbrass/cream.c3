module test;
import std::io;
import projutil;
import arga;
import toml;



fn int main(String[] args)
{
  ArgLike create_project = arga::make_arg_opt("create", "Make project", &projutil::create_proj);
  ArgLike*[] list = { &create_project };

  if (catch err = arga::argparse(args, list)){
    io::printfn("An error ocurred %s, halting", err);
    return 1;
  }

  arga::free_args(list);
  TomlFile f = toml::parse_toml(readfile("cream.toml"))!!;
  foreach(s : f.sections){
    io::printfn("\n%s\n", s.name);
    foreach(fi : s.fields) io::printfn("%s : %s", fi.key, fi.val);
  }
  return 0;
}

fn String! readfile(String file){
  usz size = file::get_size(file)!;
  char* ptr = malloc((size+4) * char.sizeof);
  char[] buff = ptr[0..size+4];
  File f = file::open(file, "r")!;
  f.read(buff)!;
  return (String)buff;
}
