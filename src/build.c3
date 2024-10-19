module build;
import std::io, std::os;
import config;
import toml;
import libc;
import utils;

struct Build {
  String outfile;
  String outdir;
  StrList cmd;
  Target target;
}

fn void! Build.build(&self) {
  DString cmd_dstr = toml::concat_arr(self.cmd.array_view(), " ");
  defer cmd_dstr.free();
  ZString zcmd = cmd_dstr.copy_zstr();
  defer free(zcmd);
  io::printfn("Building: %s\n", self.cmd);

  Target target = self.target;
  io::printfn("%s, %s", target.build_cmd, target.afterbuild_cmd);
  libc::system((ZString)target.build_cmd);
  io::printn("");
  libc::system(zcmd);
  io::printn("");
  io::printn((ZString)target.afterbuild_cmd);
  io::printn("");

  io::printfn("Finished building...");
}

fn Build! fetch_build(Config* conf, String target) {
  Build build;
  build.outfile = utils::concat(conf.project.build_dir, path_str(), conf.project.name);

  create_build_dir(conf)!;
  build.cmd.push("c3c");
  build.cmd.push("compile");
  build.cmd.push("-o");
  build.cmd.push(build.outfile);

  Target target_t = conf.targets.get(target)!;
  build.cmd.push(target_t.flags);
  
  foreach (dir : conf.project.src_dirs.data) {
    PathList files = files_in(dir)!;
    foreach (f : files) {
      build.cmd.push(f.to_new_string());
    }
  }

  return build;
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
