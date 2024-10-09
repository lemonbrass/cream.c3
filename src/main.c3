module test;
import std::io;
import arga;

fn int main(String[] args)
{
  ArgLike help = arga::make_arg_opt("help", "display help");
  ArgLike banana = arga::make_arg_param("banana", "get <n> bananas", 1);
  ArgLike orgy = arga::make_arg_param("orgy", "do orgy with <x,y> AI males and females", 2);
  ArgLike*[] list = { &help, &banana, &orgy };
  if (catch err = arga::argparse(args, list)){
    io::printfn("An error ocurred %s, halting", err);
    return 1;
  }
  if (help.count > 0){
    io::printn("No help for you");
  }
  if (banana.count > 0){
    io::printfn("I'm gonna stick %s bananas in.", banana.params[0]);
  }
  if (orgy.count > 0){
    io::printfn("Gays detected, couldnt start <%s x %s> orgy", orgy.params[0], orgy.params[1]);
  }
  return 0;
}

