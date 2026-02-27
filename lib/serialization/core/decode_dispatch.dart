import 'package:eskema/serialization/core/decode_exception.dart';

typedef DecodeStringBranch<T> = T Function(String value);
typedef DecodeListBranch<T> = T Function(List<dynamic> value);
typedef DecodeMapBranch<T> = T Function(Map<String, dynamic> value);

T dispatchDecodedNode<T>({
  required dynamic node,
  required DecodeStringBranch<T> onString,
  required DecodeListBranch<T> onList,
  required DecodeMapBranch<T> onMap,
  required Object source,
  int? offset,
}) {
  if (node is String) {
    return onString(node);
  }

  if (node is List) {
    return onList(node.cast<dynamic>());
  }

  if (node is Map<String, dynamic>) {
    return onMap(node);
  }

  if (node is Map && node.keys.every((key) => key is String)) {
    return onMap(node.cast<String, dynamic>());
  }

  throw DecodeException.invalidType('String, List, or Map', source, offset);
}

typedef MatchToken = bool Function(String token);

T dispatchStructuredCall<T>({
  required MatchToken match,
  required T Function() onGrouped,
  required T Function() onMap,
  required T Function() onCall,
}) {
  if (match('(')) return onGrouped();
  if (match('{')) return onMap();
  return onCall();
}
