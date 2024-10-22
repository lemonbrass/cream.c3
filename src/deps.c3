module deps;
import std::collections, std::io;
import toml;
import config;
import utils;

def ExternDepsMap = HashMap(<String, ExternDep>);

ExternDepsMap resolved;


enum DependencyType {C, C3}

struct ExternDep {
  String name;     
  String url;      
  String hash;
  String build_cmd;
  String commit_id;
  StringOpt clone_flags;
  TomlList libs;   
  DependencyType type;
  ExternDepsMap children;
}


fn void ExternDep.free(&self) {
  self.name.free();      
  self.url.free();
  self.commit_id.free(); 
  self.build_cmd.free(); 
  self.libs.free();     
  self.clone_flags.free();
}

fn String calc_hash(String commitid, String url) {return "";}

fn void! ExternDepsMap.read_c(&self, TomlFile* toml) {
  SectionList extern_c = toml.get_subsections("extern-c");
  foreach (dep : extern_c) {
    DString commitid = dep.find_val("commit-id")!;
    DString url = dep.find_val("url")!;
    DString build_cmd = dep.find_val("build-command")!;
    DString libs = dep.find_val("libs")!;
    DString! clone_flags = dep.find_val("clone-flags");

    ExternDep extdep;
    extdep.name = dep.name.copy_str();
    extdep.commit_id = commitid.copy_str();
    extdep.url = url.copy_str();
    extdep.hash = calc_hash(commitid.str_view(), url.str_view());
    extdep.libs.read(libs.str_view())!;
    extdep.type = C;
    extdep.clone_flags.@unwrap(clone_flags.copy_str());
    self.set(extdep.hash, extdep);
  }
}

fn void! ExternDepsMap.read_c3(&self, TomlFile* toml) {
  
}

fn bool has_resolved(String hash) {
  ExternDep! res = resolved.get(hash);
  if (catch res) return false;
  return true;
}

fn void! ExternDep.resolve(&self) {
  self.children.@each(;String hash, ExternDep dep) {
    dep.resolve()!;
  };
  if (has_resolved(self.hash)) return;
  
  // logic

  resolved.set(self.hash, *self);
  io::printfn("Resolved: %s", self.name);
}
