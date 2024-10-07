module arga;
import std::io;

enum ArgT {
  OPT,
  PARAM
}

struct ArgOpt {
  String name;
  String desc;
  String param;
  ArgT t;
  int count;
}

fault ParseError {
  NO_PARAM
}

fn void! argparse(String[] args, ArgOpt*[] argtypes){
  for (int i=0; i < args.len;){
    int ret = parse_single(i, args, argtypes)!!;
    i += ret;
  }
}

fn int! parse_single(int id, String[] args, ArgOpt*[] argtypes){
  int ret = 1;
  foreach (i, argtype : argtypes){
    if (argtype.name != args[id]) continue;
    switch (argtype.t){
      case OPT:
        argtype.count++;
        io::printn("Hell Ya Opt!");
        ret = 1;
      case PARAM:
        if (args.len < id+1) return ParseError.NO_PARAM?;
        argtype.param = args[id+1];
        io::printn("Less Goo Param!");
        ret = 2;
    }
  }
  return ret;
}
