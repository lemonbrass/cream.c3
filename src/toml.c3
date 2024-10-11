module toml;
import std::collections;
import std::io;

def SectionList = List(<TomlSection>);
def FieldList = List(<TomlField>);

struct TomlField {
  String val;
  String key;
}

struct TomlSection {
  String      name;
  TomlField[] fields;
}

struct TomlFile {
  TomlSection   global;
  TomlSection[] sections;
}

struct StringStream {
  String data;
  usz    id;
}

fault TomlError {
  SECTION_NOT_FOUND,
  INVALID_SYNTAX,
  KEY_NOT_FOUND,
  INVALID_SECTION,
  INVALID_FIELD,
  INTERNAL
}

fn char StringStream.get(&self, int id) @operator([]) {
  if (id < 0) return self.data[self.id];
  return self.data[id];
}

fn char StringStream.curr(&self) {
  if (self.id < self.data.len) {
    return self.data[self.id];
  }
  return '\0';
}

fn void StringStream.remove_whitespace(&self) {
  while (self.data.len > self.id && (self.curr() == ' ' || self.curr() == '\t' || self.curr() == '\n')) {
    self.id++;
  }
}

fn TomlSection! find_section(TomlFile* file, String name) {
  foreach (sec : file.sections) {
    if (sec.name == name) return sec;
  }
  return TomlError.SECTION_NOT_FOUND?;
}

fn String! find_val_from_sec(TomlSection* sec, String key) {
  foreach (field : sec.fields) {
    if (field.key == key) return field.val;
  }
  return TomlError.KEY_NOT_FOUND?;
}

fn void! try_parse(StringStream* sstream, SectionList* section, FieldList* fields) {
  sstream.remove_whitespace();
  if (sstream.curr() == '[') {
    sstream.id++;
    section.push(parse_section(sstream)!);
  } else {
    fields.push(parse_field(sstream)!);
  }
}

fn TomlFile! parse_toml(String data) {
  StringStream sstream = {data, 0};
  TomlFile file;
  SectionList sections;
  FieldList global_fields;
  defer sections.free();
  defer global_fields.free();
  while (sstream.data.len >= sstream.id) {
    sstream.remove_whitespace();
    try_parse(&sstream, &sections, &global_fields)!;
  }
  file.global.fields = global_fields.to_new_array();
  file.sections = sections.to_new_array();
  return file;
}

fn TomlSection! parse_section(StringStream* data) {
  DString name;
  FieldList fields;
  defer name.free();
  defer fields.free();
  char ch = data.curr();
  data.remove_whitespace();

  while (ch != ']') {
    data.id++;
    name.append_char(ch);
    if (ch == '\n') {
      return TomlError.INVALID_SECTION?;
    }
    ch = data.curr();
  }
  data.id++;

  while (data.data.len > data.id && data.curr() != '[') {
    data.remove_whitespace();
    TomlField! f = parse_field(data);
    if (catch f) break;
    fields.push(f);
  }

  TomlSection sec;
  sec.name = name.copy_str();
  sec.fields = fields.to_new_array();
  return sec;
}

fn TomlField! parse_field(StringStream* data) {
  if (data.curr() == '[') return TomlError.INTERNAL?;
  TomlField f;
  DString name;
  DString value;
  defer name.free();
  defer value.free();
  
  while (data.data.len > data.id && data.curr() != '=') {
    name.append_char(data.curr());
    data.id++;
    if (data.curr() == '=') break;
    data.remove_whitespace();
  }
  data.id++;
  data.remove_whitespace();
  
  while (data.data.len > data.id && data.curr() != '\n') {
    value.append_char(data.curr());
    data.id++;
  }
  f.key = name.copy_str();
  f.val = value.copy_str();
  return f;
}

fn String! get_val(TomlFile* file, String secname, String keyaddr) {
  if (secname == "") {
    return find_val_from_sec(&file.global, keyaddr);
  }
  TomlSection section = find_section(file, secname)!;
  return find_val_from_sec(&section, keyaddr);
}
