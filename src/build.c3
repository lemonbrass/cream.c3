module build;
import std::io, std::os;
import config;
import toml;
import libc;

fn void! build(Config* conf, String target) {
  StrList cmd;
  defer cmd.free();
  cmd.push("c3c");
  cmd.push("compile");
  cmd.push("-o");
  cmd.push(conf.project.name);
  cmd.push(conf.targets.get(target)!.flags);
  foreach (dir : conf.project.src_dirs.data) {
    PathList files = files_in(dir)!;
    foreach (f : files) cmd.push(f.to_new_string());
  }
  io::printfn("building: %s\n", cmd);
  //char[1024] buff;
  //SubProcess proc = process::create(cmd.array_view())!;
  //proc.join()!;
  //proc.read_stderr(&buff, 1024)!;
  //io::printn((String)(buff[0..]));
  //proc.read_stdout(&buff, 1024)!;
  //io::printn((String)(buff[0..]));
  //proc.destroy();

  DString cmdstr = toml::concat_arr(cmd.array_view(), " ");
  defer cmdstr.free();
  libc::system(cmdstr.zstr_view());

  cmd.free();
}

fn PathList! files_in(String dir){
  Path dirpath = path::new(dir)!;
  dirpath = dirpath.new_absolute()!;
  PathList files = path::new_ls(dirpath, true, true)!;
  PathList absfiles;
  defer dirpath.free();
  defer files.free();
  foreach (path : files) {
    DString pathstr;
    defer pathstr.free();
    pathstr.append_chars(dirpath.str_view());
    pathstr.append_char(path_ch());
    pathstr.append_chars(path.str_view());
    absfiles.push(path::new(pathstr.str_view())!);
  }
  return absfiles;
}
fn char path_ch() @if(env::POSIX) { 
  return  '/';
}
fn char path_ch() @if(env::WIN32) {
  return '\\';
}
