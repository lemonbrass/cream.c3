module utils;


fn String concat(String... operands) @builtin {
  DString res;
  defer res.free();
  foreach (data : operands) res.append_chars(data);
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

fn String get_platform() @builtin @if(env::DARWIN) { return "macos"; }
fn String get_platform() @builtin @if(env::WIN32) { return "windows"; }
fn String get_platform() @builtin @if(env::LINUX) { return "linux"; }
fn String get_platform() @builtin @if(env::POSIX && !env::LINUX && !env::DARWIN) { return "posixlike"; }
