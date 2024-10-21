module install;
import std::collections, std::io;
import config;
import utils;
import libc;
import toml;


struct InstallPreset {
  String platform_cmd;
  StringOpt override_cmd;
}

fault InstallError {INSTALL_FAILED}

fn void! InstallPreset.install(&self) {
  String command = self.override_cmd.get_def(self.platform_cmd);
  io::printfn("Running install command: %s", command);
  CInt res = libc::system((ZString) command);
  if (res != 0) return InstallError.INSTALL_FAILED?;
}

fn InstallPreset! read_toml(TomlSection* install) {
  InstallPreset installer;
  DString! overridecmd = install.find_val("for-all");
  if (try overridecmd) {
    installer.override_cmd.data = overridecmd.copy_str();
    installer.override_cmd.valid = true;
    return installer;
  }

  installer.platform_cmd = read_specific_platf(install)!;
  return installer;
}

fn String! read_specific_platf(TomlSection* install) {
  return install.find_val(get_platform())!.copy_str();
}

fn void InstallPreset.free(&self) {
  self.override_cmd.free();
  self.platform_cmd.free();
} 
