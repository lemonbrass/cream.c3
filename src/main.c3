module test;
import std::io;
import arga;

fn int main(String[] args)
{
  ArgOpt help = { "help", "ahahhahaha", "", OPT, 0};
  ArgOpt*[] list = { &help };
  arga::argparse(args, list)!!;
  if (help.count > 0){
    io::printn("Fack ya");
  }
  return 0;
}

