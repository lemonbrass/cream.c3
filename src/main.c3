module test;
import std::io;
import projutil;
import tomlmake;
import arga;
import toml;
import config;


const String CONFIG_FILE = "cream.toml";

fn bool setup_args(String[] args) {
  ArgLike create_project = arga::make_arg_opt("create", "Make project", &projutil::create_proj);
  ArgLike*[] list = { &create_project };
  defer arga::free_args(list);

  if (catch err = arga::argparse(args, list)){
    io::printfn("An error ocurred %s, halting", err);
    return false;
  }
  return true;
}

fn int main(String[] args)
{
  if (!setup_args(args)) return 1;
  Config conf = config::load_config(CONFIG_FILE)!!;
  return 0;
}

