module arga;
import std::io;
import std::core::mem;

enum ArgT {
  OPT,
  PARAM
}

struct ArgLike {
  String name;
  String desc;
  DString[] params;
  int num_param;
  int count;
  ArgT type;
}

fault ParseError {
  NOT_ENOUGH_ARGUMENTS,
  INVALID_NO_OF_PARAMS
}

fn ArgLike make_arg_opt(String name, String desc){
  ArgLike like;
  like.type = OPT;
  like.count = 0;
  like.num_param = 0;
  like.name = name;
  like.desc = desc;
  return like;
}

fn ArgLike make_arg_param(String name, String desc, int no_args){
  ArgLike like;
  like.type = PARAM;
  like.count = 0;
  like.name = name;
  like.desc = desc;
  like.num_param = no_args;
  return like;
}

fn void! argparse(String[] args, ArgLike*[] argtypes){
  for (int i=0; i < args.len;){
    int! ret = parse_single(i, args, argtypes);
    if (catch err = ret) return err?;
    i += ret;
  }
}

fn DString[]! parse_params(int id, String[] args, ArgLike* argtype){
  DString* str = malloc(DString.sizeof * argtype.num_param);
  int i = 0;
  foreach(ch : args[id]){
    if (i+1 > argtype.num_param) break;
    if (ch == ',') {
      i++;
      continue;
    }
    str[i].appendf("%c", ch);
  }
  if ((i+1) != argtype.num_param){
    io::printfn("Error: expected < %d > args, got < %d >", argtype.num_param, i+1);
    return ParseError.INVALID_NO_OF_PARAMS?;
  }
  return str[0..argtype.num_param];
}

fn int! parse_single(int id, String[] args, ArgLike*[] argtypes){
  int ret = 1;
  foreach (i, argtype : argtypes){
    if (argtype.name != args[id]) continue;
    switch (argtype.type){
      case OPT:
        argtype.count++;
        ret = 1;
      case PARAM:
        if (args.len <= id+1) return ParseError.NOT_ENOUGH_ARGUMENTS?;
        DString[]! params = parse_params(id + 1, args, argtype);
        if (catch err = params) return err?;
        argtype.params = params;
        argtype.count++;
        ret = 2;
    }
  }
  return ret;
}
