module project;
import toml;
import utils;

const String PROJ_BUILD_DIR = "build/";

struct Project {
  String name;
  String author;
  String description;
  String version;
  String build_dir;
  TomlList src_dirs;
}

fn Project! read_project(TomlFile* file) {
  Project proj;
  proj.name = file.get_val("project", "name")!;
  proj.description = file.get_val("project", "description")!;
  proj.version = file.get_val("project", "version")!;
  proj.author = file.get_val("project", "author")!;
  String src_dirs = file.get_val("project", "sources")!;
  String! errbuild_dir = file.get_val("project", "build-directory");
  StringOpt build_dir = utils::@from_err(errbuild_dir);
  proj.build_dir = build_dir.get_def("build/").path_strip();
  proj.src_dirs.read(src_dirs)!;
  return proj;
}

fn void Project.free(&self) {
  self.name.free();
  self.author.free();
  self.description.free();
  self.src_dirs.free();
}

