module toml;
import std::collections;
import std::io;

def SectionList = List(<TomlSection>);
def FieldList = List(<TomlField>);
def StreamLambda = fn void! (StringStream*);
def StrList = List(<String>);

struct TomlField {
  DString val;
  DString key;
}

struct TomlSection {
  DString    name;
  FieldList fields;
}

struct TomlFile {
  TomlSection global;
  SectionList sections;
}

struct StringStream {
  String data;
  usz    id;
}

struct TomlList {
  StrList data;
}

fault TomlError {
  SECTION_NOT_FOUND,
  INVALID_SYNTAX,
  KEY_NOT_FOUND,
  INVALID_SECTION,
  INVALID_FIELD,
  UNEXPECTED_EOF,
  INTERNAL
}

fn bool char.is_whitespace(self) {
  if (self == '\n' || self == ' ' || self == '\t') return true;
  return false;
}

fn bool String.is_empty(&self) {
  return self.trim() == "";
}

fn bool StringStream.is_whitespace(&self) {
  return self.curr().is_whitespace();
}


fn bool StringStream.is_multistr(&data) => (data.id+2 < data.data.len && (data.data[data.id..data.id+2] == "\"\"\""));

fn bool StringStream.is_ok(&self) {
  return self.data.len > self.id && self.curr() != '\0';
}


fn char StringStream.get(&self, usz id) @operator([]) {
  return self.data[id];
}


fn char StringStream.curr(&self) {
  if (self.id < self.data.len) {
    return self.data[self.id];
  }
  return '\0';
}

/**
* 
* @require $defined(sstream.curr()) && $defined(sstream.id)
*
**/
macro @till_delim(sstream, delim; @body(curr)) {
  while (sstream.curr() != delim) {
    @body(sstream.curr());
  }
} 

fn void StringStream.remove_whitespace(&self) {
  while (self.is_whitespace() || self.curr() == '#') {
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

fn void TomlFile.print_toml(&f) {
  foreach(s : f.sections){
    io::printf("\n%s\n", s.name);
    foreach(fi : s.fields) io::printfn("%s : %s", fi.key, fi.val);
  }
}



fn TomlFile! parse_toml(String data) {
  StringStream sstream = {data, 0};
  TomlFile file;
  @till_delim(sstream, '\0'; char ch){
    sstream.remove_whitespace();
    try_parse(&sstream, &file)!;
    if (!sstream.is_ok()) return file;
  };
  return file;
}

fn void! try_parse(StringStream* sstream, TomlFile* file) {
  sstream.remove_whitespace();
  if (sstream.curr() == '[') {
    sstream.id++;
    file.sections.push(parse_section(file, sstream)!);
  } else {
    TomlField! field = parse_field(file, sstream);
    if (catch err = field) {
      if (err == TomlError.INTERNAL) {
        return;
      }
      return err?;
    }
    file.global.fields.push(field);
  }
}



fn TomlSection! parse_section(TomlFile* file, StringStream* data) {
  TomlSection sec;
  data.remove_whitespace();

  @till_delim(data, ']'; char curr) {
    if (!curr.is_whitespace()) sec.name.append_char(curr);
    data.id++;
  };
  
  data.id++;

  @till_delim(data, '\0'; char curr) {
    TomlField! f = parse_field(file, data);
    if (catch err = f) {
      if (err == TomlError.INTERNAL) return sec;
      return err?;
    }
    sec.fields.push(f);
    data.remove_whitespace();
    if (data.curr() == '[') return sec;
  };
  return sec;
}



fn TomlField! parse_field(TomlFile* file, StringStream* data) {
  data.remove_whitespace();
  TomlField f;
  @till_delim(data, '='; char ch){
    if (!ch.is_whitespace()) f.key.append_char(ch);
    if (ch == '\0') return TomlError.INTERNAL?;
    data.id++;
  };

  data.id++;
  data.remove_whitespace();
  parse_field_value(&f.val, data);
  return f;
}



fn void parse_field_value(DString* value, StringStream* data) {
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





fn DString! TomlSection.find_val(&sec, String key) {
  foreach (field : sec.fields) {
    if (field.key.str_view().trim() == key) return field.val;
  }
  return TomlError.KEY_NOT_FOUND?;
}


fn TomlSection! TomlFile.find_section(&file, String name) {
  foreach (sec : file.sections) {
    if (sec.name.str_view().trim() == name) return sec;
  }
  return TomlError.SECTION_NOT_FOUND?;
}


fn String! TomlFile.get_val(&file, String secname, String keyaddr) {
  if (secname == "") {
    return (file.global.find_val(keyaddr)!).copy_str();
  }
  TomlSection section = file.find_section(secname.trim())!;
  return (section.find_val(keyaddr)!).copy_str();
}

fn DString concat_arr(String[] str, String delim = "") {
  DString res;
  foreach (s : str) {
    res.append_chars(s);
    res.append_chars(delim);
  }
  return res;
}

fn SectionList TomlFile.get_subsections(&self, String of) {
  String[] initials = of.split(".");
  SectionList sections;
  foreach (sec : self.sections) {
    String[] fullname = sec.name.str_view().split(".");
    if (fullname.len <= initials.len) continue;
    if (fullname[0..initials.len-1] == initials) {
      // remove the initials from section name as they are already known
      sec.name = concat_arr(fullname[initials.len..]);
      sections.push(sec);
    }
  }
  return sections;
}

/*
fn void! TomlList.read(&self, String list) {
  list = list[1..]; // skip [
  bool was_str;
  bool is_str;
  DString buff;
  defer buff.free();
  foreach (ch : list) {
    if (ch == ',' || ch == ']') {
      self.data.push(buff.copy_str());
      buff.clear();
    }
    if (!is_str && ch == '"') {
      is_str = true;
      was_str = true;
    }
    if (is_str && ch == '"') is_str = false;
    if (is_str || !was_str) buff.append_char(ch);
  }
}
*/

fn void! TomlList.read(&self, String list) {
  list = list[1..];
  bool was_str = false;
  bool is_str = false;
  DString buff;
  defer buff.free();

  foreach (ch : list) {
    if (ch == ',' || ch == ']') {
      if (!buff.str_view().is_empty() || was_str) {
        self.data.push(buff.copy_str());
        buff.clear();
      }
      was_str = false;
      continue;
    }

    if (!is_str && ch == '"') {
      is_str = true;
      was_str = true;
      continue;
    }

    if (is_str && ch == '"') {
      is_str = false;
      continue;
    }

    if (is_str || (!was_str && ch != ' ')) {
      buff.append_char(ch);
    }
  }
}

fn void TomlList.free(&self) {
  foreach (str : self.data) str.free();
  self.data.free();
}

fn void TomlField.free(&self) {
  self.val.free();
  self.key.free();
}

fn void TomlSection.free(&self) {
  foreach (f : self.fields) f.free();
  self.fields.free();
  self.name.free();
}

fn void TomlFile.free(&self) {
  foreach(sec : self.sections) sec.free();
  self.global.free();
}
