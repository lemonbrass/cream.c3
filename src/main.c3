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
  TomlFile f = toml::parse_toml("[project]\nname=haha\nversion=0.0.1\nauthor=banana\n[wingardium]\n levioussa=true\n")!!;
  foreach(s : f.sections){
    io::printn(s.name);
    foreach(fi : s.fields) io::printfn("%s : %s", fi.key, fi.val);
  }
  return 0;
}

