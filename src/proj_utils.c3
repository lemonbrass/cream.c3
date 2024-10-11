module projutil;

import std::io;
import arga;


fn void! create_proj(ArgLike* arg) {
  io::printn("I will ask you a couple of questions for generating project.");
  String projname = prompt("What's the project name: ")!; 
  String version = prompt("What's initial version: ")!;
  String author = prompt("Type author name: ")!;
  io::printfn("Generated project %s", projname);
}

fn String! prompt(String msg) {
  io::print(msg);
  return io::readline();
}
