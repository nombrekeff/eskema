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
  static const valueLengthOutOfRange = 'value.length_out_of_range';
  static const valueContainsMissing = 'value.contains_missing';
  static const valuePatternMismatch = 'value.pattern_mismatch';
  static const valueCaseMismatch = 'value.case_mismatch';
  static const valueEqualMismatch = 'value.equal_mismatch';
  static const valueDeepEqualMismatch = 'value.deep_equal_mismatch';
  static const valueMembershipMismatch = 'value.membership_mismatch';
  static const valueDateOutOfRange = 'value.date_out_of_range';
  static const valueDateMismatch = 'value.date_mismatch';
  static const valueDateNotPast = 'value.date_not_past';
  static const valueDateNotFuture = 'value.date_not_future';
  static const valueFormatInvalid = 'value.format_invalid';

  // New transformers / normalizers
  static const valueSlugInvalid = 'value.slug_invalid';
  static const valueEmailNormalized = 'value.email_normalized'; // informational
  static const valueUnicodeNormalized = 'value.unicode_normalized';

  // Structure domain
  static const structureMapFieldFailed = 'structure.map_field_failed';
  static const structureUnknownKey = 'structure.unknown_key';
  static const structureListItemFailed = 'structure.list_item_failed';

  // Logic domain
  static const logicNotExpected = 'logic.not_expected';
}
