import 'package:eskema/eskema.dart';

/// Executes the [createDecodedField] operation.
Field createDecodedField({
  required String id,
  required IValidator validator,
  required bool nullable,
  required bool optional,
}) {
  return Field(
    id: id,
    validators: [validator],
    nullable: nullable,
    optional: optional,
  );
}

/// The [DecodedMapValidator] class.
class DecodedMapValidator extends MapValidator {
  final List<IdValidator> _fields;

  /// Executes the [DecodedMapValidator] operation.
  DecodedMapValidator(this._fields, {super.name = 'eskema'}) : super(id: '');

  @override
  List<IdValidator> get fields => _fields;
}
