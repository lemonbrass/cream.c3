module arga;
import std::io;
import std::collections;
import std::core::mem;


def Callback = fn void!(ArgLike*);
const int ANY_PARAMS = -1; // any no. of parameters


enum ArgT {
  OPT,
  PARAM
}

struct ArgLike {
  String name;
  String desc;
  String[] params;
  int num_param;
  int count;
  Callback callback;
  ArgT type;
}

fault ParseError {
  NOT_ENOUGH_ARGUMENTS,
  INVALID_NO_OF_PARAMS
}

fn void! empty_fn(ArgLike* al) { }

fn ArgLike make_arg_opt(String name, String desc, Callback cback = &empty_fn){
  ArgLike like;
  like.type = OPT;
  like.count = 0;
  like.num_param = 0;
  like.name = name;
  like.desc = desc;
  like.callback = cback;
  return like;
}

fn ArgLike make_arg_param(String name, String desc, int no_args, Callback cback = &empty_fn){
  ArgLike like;
  like.type = PARAM;
  like.count = 0;
  like.name = name;
  like.desc = desc;
  like.callback = cback;
  like.num_param = no_args;
  return like;
}

fn void! argparse(String[] args, ArgLike*[] argtypes){
  for (int i=0; i < args.len;){
    int ret = parse_single(i, args, argtypes)!;
    i += ret;
  }
}

fn String[]! parse_params(int id, String[] args, ArgLike* argtype){
  int numargs = argtype.num_param;
  String[] str = args[id].split(",");
  int i = str.len;
  if (ANY_PARAMS != numargs && i != numargs){
    io::printfn("Error: expected <_%d_> args, got <_%d_>", argtype.num_param, i);
    return ParseError.INVALID_NO_OF_PARAMS?;
  }
  return str;
}

fn int! parse_single(int id, String[] args, ArgLike*[] argtypes){
  int ret = 1;
  foreach (i, argtype : argtypes){
    if (argtype.name != args[id]) continue;
    switch (argtype.type){
      case OPT:
        argtype.count++;
        argtype.callback(argtype)!;
        ret = 1;
      case PARAM:
        if (args.len <= id+1) return ParseError.NOT_ENOUGH_ARGUMENTS?;
        String[]! params = parse_params(id + 1, args, argtype);
        argtype.params = params!;
        argtype.count++;
        argtype.callback(argtype)!;
        ret = 2;
    }
  }
  return ret;
}
