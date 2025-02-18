// utils/helpers.dart
int convertIdentifier(List<int> identifier) {
  return (identifier[3] << 24) |
         (identifier[2] << 16) |
         (identifier[1] << 8) |
         identifier[0];
}
