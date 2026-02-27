/// Centralized expectation code constants to avoid typos.
///
/// Codes follow a `domain.specific_issue` naming. Existing domains:
/// - value.*  : primitive / direct value expectations
/// - structure.* : map/list structural errors
/// - logic.* : logical/combinator wrappers
///
/// NOTE: Only add stable, publicly documented codes here. Experimental ones
/// can live near their validators until stabilized.
class ExpectationCodes {
  // General value domain
  /// The [valueLengthOutOfRange] property.
  static const valueLengthOutOfRange = 'value.length_out_of_range';

  /// The [valueContainsMissing] property.
  static const valueContainsMissing = 'value.contains_missing';

  /// The [valuePatternMismatch] property.
  static const valuePatternMismatch = 'value.pattern_mismatch';

  /// The [valueCaseMismatch] property.
  static const valueCaseMismatch = 'value.case_mismatch';

  /// The [valueEqualMismatch] property.
  static const valueEqualMismatch = 'value.equal_mismatch';

  /// The [valueDeepEqualMismatch] property.
  static const valueDeepEqualMismatch = 'value.deep_equal_mismatch';

  /// The [valueMembershipMismatch] property.
  static const valueMembershipMismatch = 'value.membership_mismatch';

  /// The [valueDateOutOfRange] property.
  static const valueDateOutOfRange = 'value.date_out_of_range';

  /// The [valueDateMismatch] property.
  static const valueDateMismatch = 'value.date_mismatch';

  /// The [valueDateNotPast] property.
  static const valueDateNotPast = 'value.date_not_past';

  /// The [valueDateNotFuture] property.
  static const valueDateNotFuture = 'value.date_not_future';

  /// The [valueFormatInvalid] property.
  static const valueFormatInvalid = 'value.format_invalid';

  // New transformers / normalizers
  /// The [valueSlugInvalid] property.
  static const valueSlugInvalid = 'value.slug_invalid';

  /// The [valueEmailNormalized] property.
  static const valueEmailNormalized = 'value.email_normalized'; // informational
  /// The [valueUnicodeNormalized] property.
  static const valueUnicodeNormalized = 'value.unicode_normalized';

  // Structure domain
  /// The [structureMapFieldFailed] property.
  static const structureMapFieldFailed = 'structure.map_field_failed';

  /// The [structureUnknownKey] property.
  static const structureUnknownKey = 'structure.unknown_key';

  /// The [structureListItemFailed] property.
  static const structureListItemFailed = 'structure.list_item_failed';

  // Logic domain
  /// The [logicNotExpected] property.
  static const logicNotExpected = 'logic.not_expected';

  /// The [typeMismatch] property.
  static var typeMismatch = 'value.type_mismatch';

  /// The [valueRangeOutOfBounds] property.
  static var valueRangeOutOfBounds = 'value.range_out_of_bounds';

  /// The [logicPredicateFailed] property.
  static var logicPredicateFailed = 'logic.predicate_failed';
}
