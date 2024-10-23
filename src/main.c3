module main;
import std::io;
import project;
import tomlmake;
import arga;
import toml;
import config;
import libc;
import build;

Config conf;
const String CONFIG_FILE = "cream.toml";

fn bool setup_args(String[] args) {
  ArgLike create_project = arga::make_arg_opt("create", "Make project", &project::create_proj);
  ArgLike init_project = arga::make_arg_opt("init", "Initialize project in cwd", &project::init_proj);
  ArgLike*[] list = { &create_project, &init_project };
  defer arga::free_args(list);

  if (catch err = arga::argparse(args, list)){
    io::printfn("An error ocurred %s, halting", err);
    return false;
  }
  return true;
}

fn void! onbuild(ArgLike* arg) {
  Build build = build::from_conf(&conf, arg.params[0])!;
  build.build()!;
  build.free();
}

fn void! ontest(ArgLike* arg) {
  conf.tests.get(arg.params[0])!.run()!;
}

fn void! oninstall(ArgLike* arg) {
  if (conf.install.valid) conf.install.data.install()!;
}

fn bool setup_conf_args(String[] args) {
  ArgLike build = arga::make_arg_cparam("build", "Build the project", 1, &onbuild);
  ArgLike test = arga::make_arg_cparam("test", "Test the project", 1, &ontest);
  ArgLike install = arga::make_arg_opt("install", "Run install command", &oninstall);
  ArgLike*[] list = { &build, &test, &install };
  defer arga::free_args(list);

  if (catch err = arga::argparse(args, list)){
    io::printfn("An error ocurred %s, halting", err);
    return false;
  }
  return true;
}


fn int main(String[] args)
{
  if (!setup_args(args)) return 1;

  Path path = path::new(CONFIG_FILE)!!;
  defer path.free();
  if (path::exists(path))
  {
    conf = config::load_file(CONFIG_FILE)!!;
    setup_conf_args(args);
    conf.free();
  }
  return 0;
}

