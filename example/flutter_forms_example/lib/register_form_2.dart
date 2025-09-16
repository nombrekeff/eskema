import 'package:eskema/eskema.dart';
import 'package:flutter/material.dart';
import 'package:flutter_forms_example/my_validators.dart';

class RegisterForm2 extends StatefulWidget {
  const RegisterForm2({super.key});

  @override
  RegisterForm2State createState() => RegisterForm2State();
}

class RegisterForm2State extends State<RegisterForm2> {
  final _formKey = GlobalKey<FormState>();
  final _formState = RegisterFormData();

  // For simplicity, we define validators here, but they could be defined elsewhere
  // and imported as needed.

  // For validators that do not depend on other fields, we can define them as final fields.
  // For validators that depend on other fields (like confirmPassword), we use a getter.
  final nameValidator = stringLength([isInRange(8, 32)]);
  final emailValidator = isEmail();
  final passwordValidator =
      stringLength([isInRange(6, 32)]) &
      $containsNumber &
      $containsLowercase &
      $containsUppercase &
      $containsSpecialChar;

  // Domain-specific validator for confirming passwords
  // Use a getter to return a validator function to access `passwordValidator` and `formState.password`
  get confirmPasswordValidator {
    return (value) =>
        (passwordValidator & isEq(_formState.password, message: "Passwords do not match"))
            .validate(value)
            .description;
  }

  void validate() {
    final result = nameValidator.validate(_formState.name);
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
              errorText: 'aaa'
            ),
            // validator: nameValidator,
          ),
          SizedBox(height: 16),
          
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: Size(double.infinity, 48), // Make button full width
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}

/// Convenient way of holding state and validators for the form
/// In a real app, you might want to use a more robust state management solution
/// like Provider, Riverpod, Bloc, etc.
/// Use this just as a reference.
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
