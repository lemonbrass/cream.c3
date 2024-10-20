module deps;
import std::collections;
import toml;
import utils;

def ExternCMap = HashMap(<String, External_C>);
def ExternC3Map = HashMap(<String, External_C3>);


struct External_C3 {
  String name;        // required
  String url;         // required
  String commit_id;   // required
  TomlList libs;
  String clone_flags;
  String build_opt;
  bool force_link;
}

struct External_C {
  String name;        // required
  String url;         // required
  String commit_id;   // required
  String build_cmd;   // required
  TomlList libs;      // required
  String output_dir;  // defaults to build
  String clone_flags;
  bool link_switch;   // defaults to false
}


fn void External_C.free(&self) {
  self.name.free();      
  self.url.free();
  self.commit_id.free(); 
  self.build_cmd.free(); 
  self.libs.free();     
  self.output_dir.free();
  self.clone_flags.free();
}

fn void External_C3.free(&self) {
  self.name.free();      
  self.url.free();
  self.commit_id.free(); 
  self.build_opt.free(); 
  self.libs.free();     
  self.clone_flags.free();
}

