module build;
import std::io, std::os;
import config;
import toml;
import libc;
import utils;

fn void! build(Config* conf, String target) {
  String outfile = utils::concat(conf.project.build_dir, path_str(), conf.project.name);
  create_build_dir(conf)!;
  StrList cmd;
  defer cmd.free();
  defer outfile.free();
  cmd.push("c3c");
  cmd.push("compile");
  cmd.push("-o");
  cmd.push(outfile);
  Target target_t = conf.targets.get(target)!;
  cmd.push(target_t.flags);
  foreach (dir : conf.project.src_dirs.data) {
    PathList files = files_in(dir)!;
    foreach (f : files) cmd.push(f.to_new_string());
  }
  io::printfn("building: %s\n", cmd);
  DString cmdstr = toml::concat_arr(cmd.array_view(), " ");
  defer cmdstr.free();
  if (target_t.build_cmd.valid) {
    ZString befcmd = target_t.build_cmd.str.zstr_copy();
    io::printfn("Running before-cmd: %s", befcmd);
    libc::system(befcmd);
    free(befcmd);
  }
  libc::system(cmdstr.zstr_view());
  if (target_t.afterbuild_cmd.valid) {
    ZString aftcmd = target_t.afterbuild_cmd.str.zstr_copy();
    io::printfn("Running after-cmd: %s", aftcmd);
    libc::system(aftcmd);
    free(aftcmd);
  }
}

fn void! create_build_dir(Config* conf) {
  Path outdir = path::new(conf.project.build_dir)!;
  defer outdir.free();
  if (catch path::mkdir(outdir)) return;
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
