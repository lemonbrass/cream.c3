module optional(<Type>);

struct Optional {
  Type data;
  bool valid;
}

fn Type Optional.get_def(&self, Type com) {
  if (self.valid) return self.data;
  return com;
}

macro Optional.@from_err(&self, #err) {
  if (catch #err) {
    self.valid = false;
  }else {
    self.data = #err!!;
    self.valid = true;
  }
}

macro Optional.@unwrap(&self, #err) {
  Type! errval = #err;
  if (catch errval) {
    self.valid = false;
  }
  if (try errval) {
    self.valid = true;
    self.data = errval;
  }
}

fn void Optional.free(&self) {
  if (self.valid) self.data.free();
}
