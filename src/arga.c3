module arga;
import std::io;
import std::collections;
import std::core::mem;


def Callback = fn void!(ArgLike*);
const int ANY_PARAMS = -1; // any no. of parameters


enum ArgT {
  OPT,
  PARAM,
  CPARAM // Confusing Param
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
  INVALID_NO_OF_PARAMS,
  INVALID_ARGUMENT
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

fn void free_args(ArgLike*[] list){
  foreach (arg : list) {
    if (arg.params.ptr != null) free(arg.params);
  }
}

fn ArgLike make_arg_cparam(String name, String desc, int no_args, Callback cback = &empty_fn){
  ArgLike like;
  like.type = CPARAM;
  like.count = 0;
  like.name = name;
  like.desc = desc;
  like.callback = cback;
  like.num_param = no_args;
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
  bool is_any = ANY_PARAMS == ANY_PARAMS;
  int i = str.len;
  if (is_any && i != numargs){
    io::printfn("Error: expected <_%d_> args seperated by ',', got <_%d_>", argtype.num_param, i);
    return ParseError.INVALID_NO_OF_PARAMS?;
  }
  return str;
}

fn bool contains(ArgLike*[] argtypes, String arg) {
  bool result = false;
  foreach (argtype : argtypes) {
    result = result || (argtype.name == arg);
  }
  return result;
}

fn ArgLike*! match_argt(String name, ArgLike*[] argtypes){
  foreach(argt : argtypes) {
    if (argt.name == name) return argt;
  }
  return ParseError.INVALID_ARGUMENT?;
}

fn String[]! parse_cparams(int id, String[] args, ArgLike* argtype, ArgLike*[] argtypes) {
  List(<String>) strs;
  usz act_num = args.len - id;
  int numargs = argtype.num_param;
  bool is_any = numargs == ANY_PARAMS;
  foreach (i, arg : args[id..]){
    if (!is_any && i > numargs) break;
    if (contains(argtypes, arg)) break;
    strs.push(arg);
  }
  String[] str_params = strs.to_new_array();
  strs.free();
  if (!is_any && act_num != numargs) {
    io::printfn("Error: expected <_%d_> args, got <_%d_>", 
                                          argtype.num_param, act_num);
    return ParseError.INVALID_NO_OF_PARAMS?;
  }
  return str_params;
}

fn int! parse_single(int id, String[] args, ArgLike*[] argtypes){
  int ret = 1;
  foreach (i, argtype : argtypes){
    if (args[id] == "-h" && id+1 < args.len) {
      ArgLike* help_arg = match_argt(args[id+1], argtypes)!;
      io::printfn("%s :  %s", help_arg.name, help_arg.desc);
      ret = 2;
      break;
    }
    if (argtype.name != args[id]) continue;
    switch (argtype.type){
      case OPT:
        argtype.count++;
        argtype.callback(argtype)!;
        ret = 1;
      case PARAM:
        String[]! params = parse_params(id + 1, args, argtype);
        argtype.params = params!;
        argtype.count++;
        argtype.callback(argtype)!;
        ret = 2;
      case CPARAM:
        String[] params = parse_cparams(id+1, args, argtype, argtypes)!;
        argtype.params = params;
        argtype.count++;
        argtype.callback(argtype)!;
        ret = 1 + argtype.params.len;
    }
  }
  return ret;
}
