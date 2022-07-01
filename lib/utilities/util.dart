// dynamic parsed to boolean
bool? parseBool(value) {
  bool isTrue =
      (value == 1 || value == '1' || value == 'true' || value == true);
  bool isFalse =
      (value == 0 || value == '0' || value == 'false' || value == false);
  if (isTrue) {
    return true;
  } else if (isFalse) {
    return false;
  } else {
    return null;
  }
}

DateTime? parseDate(value) {
  if (value == '' || value == 'null' || value == null) {
    return null;
  } else {
    return DateTime.parse(value.substring(0, 10));
  }
}

dynamic nullToZerro(value) {
  if (value == null || value == 'null') {
    return 0;
  } else {
    return value;
  }
}

bool stringNotNull(String? value) {
  return value != 'null' && value != '' && value != null;
}
