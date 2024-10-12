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

fn bool StringStream.is_whitespace(&self) {
  if (self.curr() == '\n' || self.curr() == ' ' || self.curr() == '\t') return true;
  return false;
}

fn bool StringStream.is_multistr(&data) => (data.id+2 < data.data.len && (data.data[data.id..data.id+2] == "\"\"\""));

fn char StringStream.get(&self, usz id) @operator([]) {
  return self.data[id];
}

fn char StringStream.curr(&self) {
  if (self.id < self.data.len) {
    return self.data[self.id];
  }
  return '\0';
}

fn bool StringStream.is_ok(&self) => self.data.len > self.id;

fn void StringStream.remove_whitespace(&self) {
  while (self.is_ok()) {
    char ch = self.curr();
    if (self.is_whitespace()) {
      self.id++;
    } else if (ch == '#') {
      while (self.curr() != '\n' && self.is_ok()) {
        self.id++;
      }
    } else {
      break;
    }
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
  while (sstream.is_ok()) {
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

  while (data.is_ok() && data.curr() != '[') {
    data.remove_whitespace();
    if (!data.is_ok()) break;
    TomlField! f = parse_field(data);
    if (catch f) break;
    if (f.key != "") fields.push(f);
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

  while (data.is_ok() && data.curr() != '=') {
    name.append_char(data.curr());
    data.id++;
    if (data.curr() == '=') break;
    data.remove_whitespace();
  }
  data.id++;
  data.remove_whitespace();
  parse_field_value(&value, data);
  f.key = name.copy_str();
  f.val = value.copy_str();
  return f;
}

fn void parse_field_value(DString* value, StringStream* data) {
  data.remove_whitespace();
  bool is_str = data.curr() == '"';
  bool is_multistr = data.is_multistr();
  if (is_str && !is_multistr) data.id++;

  while (is_str && !is_multistr) {
    value.append_char(data.curr());
    data.id++;
    if (data.curr() == '\n') return; // ERROR
    if (data.curr() == '"') {
      data.id++;
      data.remove_whitespace();
      return;
    }
  }

  if (is_multistr) data.id+=3;

  while (data.is_ok() && is_multistr) {
    value.append_char(data.curr());
    data.id++;
    if (data.is_ok() && data.curr() == '"') {
      data.id += 3;
      return;
    }
  }

  while (data.is_ok() && !is_multistr && !is_str) {
    value.append_char(data.curr());
    data.id++;
    if (data.curr() == '\n') return;
  }
}

fn String! get_val(TomlFile* file, String secname, String keyaddr) {
  if (secname == "") {
    return find_val_from_sec(&file.global, keyaddr);
  }
  TomlSection section = find_section(file, secname)!;
  return find_val_from_sec(&section, keyaddr);
}
