import 'package:flutter/material.dart';
import 'package:eskema/eskema.dart';
import 'package:flutter_forms_example/my_validators.dart';

class RegisterForm extends StatefulWidget {
  const RegisterForm({super.key});

  @override
  RegisterFormState createState() => RegisterFormState();
}

class RegisterFormState extends State<RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final _formState = RegisterFormData();

  // Validators
  final nameValidator = stringLength([isInRange(8, 32)]);
  final emailValidator = not($isStringEmpty) & isEmail();
  final passwordValidator =
      stringLength([isInRange(6, 32)]) &
      $containsNumber &
      $containsLowercase &
      $containsUppercase &
      $containsSpecialChar;

  // Domain-specific validator for confirming passwords
  get confirmPasswordValidator {
    // Use a getter to return a validator function to access `passwordValidator` and `formState.password`
    return (value) =>
        (passwordValidator & isEq(_formState.password, message: "Passwords do not match"))
            .validate(value)
            .description;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUnfocus,
      child: Column(
        children: [
          TextFormField(
            initialValue: _formState.name,
            onChanged: (value) {
              _formState.name = value;
            },
            decoration: InputDecoration(
              labelText: 'Enter your name',
              suffixIcon: Icon(Icons.person),
            ),
            // You can use toFunction() to convert a validator to a function validator
            validator: nameValidator.toFunction(),
          ),
          SizedBox(height: 16),
          TextFormField(
            initialValue: _formState.email,
            onChanged: (value) {
              _formState.email = value;
            },
            decoration: InputDecoration(
              labelText: 'Enter your email',
              suffixIcon: Icon(Icons.email),
            ),
            validator: emailValidator.toFunction(),
          ),
          SizedBox(height: 16),
          TextFormField(
            initialValue: _formState.password,
            onChanged: (value) {
              _formState.password = value;
            },
            decoration: InputDecoration(
              labelText: 'Enter a password',
              suffixIcon: Icon(Icons.lock),
            ),
            validator: passwordValidator.toFunction(),
          ),
          SizedBox(height: 16),
          TextFormField(
            initialValue: _formState.confirmPassword,
            onChanged: (value) {
              _formState.confirmPassword = value;
            },
            decoration: InputDecoration(
              labelText: 'Confirm your password',
              suffixIcon: Icon(Icons.lock),
            ),
            // Here we dont need to call toFunction() because the getter already returns a function
            validator: confirmPasswordValidator,
          ),
        ],
      ),
    );
  }
}

class RegisterFormData extends ValueNotifier {
  String _name = '';
  String _email = '';
  String _password = '';
  String _confirmPassword = '';

  String get name => _name;
  set name(String value) {
    _name = value;
    notifyListeners();
  }

  String get email => _email;
  set email(String value) {
    _email = value;
    notifyListeners();
  }

  String get password => _password;
  set password(String value) {
    _password = value;
    notifyListeners();
  }

  String get confirmPassword => _confirmPassword;
  set confirmPassword(String value) {
    _confirmPassword = value;
    notifyListeners();
  }

  RegisterFormData() : super(null) {
    notifyListeners();
  }
}
