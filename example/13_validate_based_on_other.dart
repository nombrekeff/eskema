import 'dart:async';

import 'package:eskema/eskema.dart';

class ResolveValidator extends IWhenValidator {
  final dynamic Function(Map parentObject) resolver;

  ResolveValidator({
    required this.resolver,
    super.nullable,
    super.optional,
  });

  @override
  Result validate(dynamic value, {bool exists = true}) => Result.invalid(
        value,
        expectation: Expectation(
          message: '`when` validator can only be used inside an `eskema` map validator',
          value: value,
        ),
      );

  @override
  FutureOr<Result> validateWithParent(
    dynamic value,
    Map<String, dynamic> map, {
    bool exists = true,
  }) {
    final resolverResult = resolver(map);
    if (resolverResult is Future<Result>) {
      return resolverResult.then((cr) => _evalBranch(cr, value));
    }

    return _evalBranch(resolverResult, value);
  }

  FutureOr<Result> _evalBranch(Result resolverResult, dynamic value) {
    return resolverResult.isValid ? resolverResult : Result.invalid(value);
  }

  @override
  IValidator copyWith({
    bool? nullable,
    bool? optional,
    dynamic Function(Map parentObject)? resolver,
  }) =>
      ResolveValidator(
        resolver: resolver ?? this.resolver,
        nullable: nullable ?? isNullable,
        optional: optional ?? isOptional,
      );

  @override
  FutureOr<Result> validator(value) => throw UnimplementedError();
}

IValidator resolve(dynamic Function(Map parentObject) resolver) {
  return ResolveValidator(resolver: resolver);
}

void main() {
  // 1. Define some data to validate.
  final validData1 = {
    'role': 'admin',
    'username': 'john_doe',
    'status': 'active',
    'config': {'theme': 'dark', 'notifications': true, 'required_admin_setting': 'value'}
  };

  final validData2 = {
    'role': 'user',
    'username': 'test',
    'status': 'active',
    'config': {'theme': 'dark', 'notifications': true, 'required_user_setting': 'value'}
  };

  final $role = isOneOf(['admin', 'user']);
  final $username = all([isString(), not($isStringEmpty)]);
  final $status = isString() & isOneOf(['active', 'inactive', 'pending']);

  final $commonConfig = {
    'theme': isString(),
    'notifications': isBool(),
  };
  final $adminConfig = {
    ...$commonConfig,
    'required_admin_setting': isString(),
  };
  final $userConfig = {
    ...$commonConfig,
    'required_user_setting': isString(),
  };

  final $config = resolve((parent) {
    switch (parent['role']) {
      case 'admin':
        return $adminConfig;
      case 'user':
        return $userConfig;
    }
  });

  final userValidator = eskema({
    'role': $role,
    'username': $username,
    'status': $status,
    'config': $config,
  });

  final result1 = userValidator.validate(validData1);
  final result2 = userValidator.validate(validData2);

  print(result1);
  print(result2);
}
