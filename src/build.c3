module build;
import std::io, std::os;
import config;
import toml;
import libc;
import utils;

struct Build {
  String cmd;
  String outfile;
  Target targ;
}

fn void! Build.build(&buildobj) {
  StringOpt beforebuild = buildobj.targ.build_cmd;
  StringOpt afterbuild = buildobj.targ.afterbuild_cmd;
  if (beforebuild.valid) {
    io::printfn("Running before-build command: %s", beforebuild.str);
    libc::system((ZString)beforebuild.str);
  }
  io::printfn("Building: %s", buildobj.cmd);
  libc::system((ZString)buildobj.cmd);
  if (afterbuild.valid) {
    io::printfn("Running after-build command: %s", afterbuild.str);
    libc::system((ZString)afterbuild.str);
  }
}

fn Build! from_conf(Config* conf, String target) {
  Build build_obj;
  String outfile = utils::concat(conf.project.build_dir, path_str(), conf.project.name);
  StrList cmd;
  Target target_t = conf.targets.get(target)!;
  defer cmd.free();

  create_build_dir(outfile[0..outfile.len-conf.project.name.len-1])!;
  cmd.push("c3c");
  cmd.push("compile");
  cmd.push("-o");
  cmd.push(outfile);

  cmd.push(target_t.flags);
  foreach (dir : conf.project.src_dirs.data) {
    PathList files = files_in(dir)!;
    foreach (f : files) cmd.push(f.to_new_string());
  }
  DString cmdstr = toml::concat_arr(cmd.array_view(), " ");
  defer cmdstr.free();
  build_obj.cmd = cmdstr.copy_str();
  build_obj.targ = target_t;
  build_obj.outfile = outfile;
  return build_obj;
}

fn Build! new_temp(String tmpdir, StrList sources, String flags, String outfile) {
  Build build_obj;
  Target target_t;
  target_t.flags = flags;
  StrList cmd;
  String fulloutfile = concat(tmpdir, path_str(), outfile);;
  defer cmd.free();

  create_build_dir(tmpdir)!;
  cmd.push("c3c");
  cmd.push("compile");
  cmd.push("-o");
  cmd.push(fulloutfile);
  cmd.push(target_t.flags);

  foreach (dir : sources) {
    PathList files = files_in(dir)!;
    foreach (f : files) cmd.push(f.to_new_string());
  }

  DString cmdstr = toml::concat_arr(cmd.array_view(), " ");
  defer cmdstr.free();
  build_obj.cmd = cmdstr.copy_str();
  build_obj.targ = target_t;
  build_obj.outfile = fulloutfile;
  return build_obj;
}

fn void! create_build_dir(String dir) {
  Path outdir = path::new(dir)!;
  defer outdir.free();
  if (catch path::mkdir(outdir)) return;
}

fn PathList! files_in(String dir){
  Path dirpath = path::new(dir)!;
  dirpath = dirpath.new_absolute()!;
  PathList! files = path::new_ls(dirpath, true, true);
  if (catch err = files) {
    if (err == IoError.FILE_NOT_DIR) {
      PathList res;
      res.push(dirpath);
      return res;
    }
  }
  PathList absfiles;
  defer dirpath.free();
  foreach (path : files!) {
    DString pathstr;
    defer pathstr.free();
    pathstr.append_chars(dirpath.str_view());
    pathstr.append_char(path_ch());
    pathstr.append_chars(path.str_view());
    absfiles.push(path::new(pathstr.str_view())!);
  }
  files.free()!;
  return absfiles;
}
