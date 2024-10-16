module utils;

struct StringOpt {
  bool valid;
  String str;
}

fn String StringOpt.get_def(&self, String com) {
  if (self.valid) return self.str;
  return com;
}

fn String* StringOpt.get(&self) {
  if (self.valid) return &self.str;
  return null;
}

macro StringOpt @from_err(#err) {
  if (catch #err) return {false, ""};
  return {true, #err!!};
}

macro StringOpt @from_dstr_err(#err) {
  if (catch #err) return {false, ""};
  return {true, #err!!.copy_str()};
}

fn String concat(String... operands) @builtin {
  DString res;
  defer res.free();
  foreach (str : operands) res.append_chars(str);
  return res.copy_str();
}


fn char path_ch() @if(env::POSIX) @builtin { 
  return  '/';
}
fn char path_ch() @if(env::WIN32) @builtin {
  return '\\';
}

fn String path_str() @if(env::POSIX) @builtin { 
  return  "/";
}
fn char path_str() @if(env::WIN32) @builtin {
  return "\\";
}

fn String String.path_strip(str) @builtin {
  if (str[str.len-1]==path_ch()) str = str[0..str.len-2];
  return str;
}
