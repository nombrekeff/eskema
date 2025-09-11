import 'package:flutter/material.dart';
import 'package:eskema/eskema.dart';

class RegisterForm extends StatefulWidget {
  const RegisterForm({super.key});

  @override
  RegisterFormState createState() => RegisterFormState();
}

class RegisterFormState extends State<RegisterForm> {
  // Create a global key that uniquely identifies the Form widget
  // and allows validation of the form.
  //
  // Note: This is a `GlobalKey<FormState>`,
  // not a GlobalKey<MyCustomFormState>.
  final _formKey = GlobalKey<FormState>();

  final formState = RegisterFormData();

  final nameValidator = stringLength([
    isInRange(8, 32),
  ], message: "Name must be between 8 and 32 characters");
  final emailValidator = not($isStringEmpty) & isEmail();
  final passwordValidator =
      stringLength([isInRange(6, 32)]) &
      stringMatches(RegExp(r'[0-9]'), message: "Must contain numbers") &
      stringMatches(RegExp(r'[a-z]'), message: "Must contain lowercase letters") &
      stringMatches(RegExp(r'[A-Z]'), message: "Must contain uppercase letters") &
      stringMatches(RegExp(r'[^A-Za-z0-9]'), message: "Must contain special characters");

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUnfocus,
      child: Column(
        children: [
          TextFormField(
            initialValue: formState.name,
            onChanged: (value) {
              formState.name = value;
            },
            decoration: InputDecoration(
              labelText: 'Enter your name',
              suffixIcon: Icon(Icons.person),
            ),
            validator: nameValidator.toForm(),
          ),
          SizedBox(height: 16),
          TextFormField(
            initialValue: formState.email,
            onChanged: (value) {
              formState.email = value;
            },
            decoration: InputDecoration(
              labelText: 'Enter your email',
              suffixIcon: Icon(Icons.email),
            ),
            validator: emailValidator.toForm(),
          ),
          SizedBox(height: 16),
          TextFormField(
            initialValue: formState.password,
            onChanged: (value) {
              formState.password = value;
            },
            decoration: InputDecoration(
              labelText: 'Enter a password',
              suffixIcon: Icon(Icons.lock),
            ),
            validator: passwordValidator.toForm(),
          ),
          SizedBox(height: 16),
          TextFormField(
            initialValue: formState.confirmPassword,
            onChanged: (value) {
              formState.confirmPassword = value;
            },
            decoration: InputDecoration(
              labelText: 'Confirm your password',
              suffixIcon: Icon(Icons.lock),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter some text';
              }
              return null;
            },
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
