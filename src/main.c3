module test;
import std::io;
import projutil;
import arga;



fn int main(String[] args)
{
  ArgLike create_project = arga::make_arg_opt("create", "Make project", &projutil::create_proj);
  ArgLike*[] list = { &create_project };

  if (catch err = arga::argparse(args, list)){
    io::printfn("An error ocurred %s, halting", err);
    return 1;
  }

  arga::free_args(list);
  return 0;
}

