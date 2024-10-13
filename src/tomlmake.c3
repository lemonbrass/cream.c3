module tomlmake;
import toml;

struct TomlBuilder {
  DString content;
  SectionList sections;
  FieldList global;
}

fault TomlBuilderError {
  SECTION_NOT_FOUND
}

fn void TomlBuilder.add_section(&self, String name) {
  TomlSection sec;
  sec.name.append_chars(name);
  self.sections.push(sec);
}

fn void TomlBuilder.free(&self) {
  self.content.free();
  self.global.free();
  foreach (sec : self.sections) sec.free();
  self.sections.free();
}

fn TomlSection* TomlSection.add_field(&self, String key, String val) {
  TomlField field;
  field.key.append_chars(key);
  field.val.append_chars(val);
  self.fields.push(field);
  return self;
}

fn void TomlBuilder.add_global(&self, String key, String val) {
  TomlField f;
  f.key.append_chars(key);
  f.val.append_chars(key);
  self.global.push(f);
}

fn void! TomlBuilder.write_to(&self, String file) {

}

fn String TomlBuilder.get_string(&self) {
  self.append_fields(&self.global);
  foreach (sec : self.sections){
    self.content.appendf("[ %s ]\n", sec.name);
    self.append_fields(&sec.fields);
  }
  return self.content.str_view();
}

fn TomlSection*! TomlBuilder.get_section(&self, String name) {
  foreach (&sec : self.sections) {
    if (sec.name.str_view() == name) return sec;
  }
  return TomlBuilderError.SECTION_NOT_FOUND?;
}

fn void TomlBuilder.append_fields(&self, FieldList* sec) { 
  foreach (field : sec) {
    self.content.appendf("%s = %s\n", field.key, field.val);
  }
}
