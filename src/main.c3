module test;
import std::io;
import arga;

fn void! onbanana(ArgLike* banana) {
  io::printfn("I'm gonna stick %s bananas in.", banana.params[0]);
}

fn void! onhelp(ArgLike* help){
  io::printn("No help for you");
}

fn void! onprint(ArgLike* print) {
  io::print("{ ");
  foreach (element : print.params){
    io::printf("%s, ", element);
  }
  io::printn(" }");
}

fn int main(String[] args)
{
  ArgLike help = arga::make_arg_opt("help", "display help", &onhelp);
  ArgLike banana = arga::make_arg_param("banana", 
                    "get <n> bananas", 1, &onbanana);
  ArgLike print = arga::make_arg_param("print", 
   "print a list of a,b,c.", arga::ANY_PARAMS, &onprint);

  ArgLike*[] list = { &help, &banana, &print };
  if (catch err = arga::argparse(args, list)){
    io::printfn("An error ocurred %s, halting", err);
    return 1;
  }
  return 0;
}

