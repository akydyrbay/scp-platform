import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/auth_cubit.dart';
import 'package:scp_mobile_shared/config/app_theme.dart';
import 'package:scp_mobile_shared/utils/app_validators.dart';

/// Login screen for consumer authentication
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _companyNameController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSignup = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _companyNameController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthCubit>().login(
            _emailController.text.trim(),
            _passwordController.text,
          );
    }
  }

  void _handleSignup() async {
    if (_formKey.currentState!.validate()) {
      final message = await context.read<AuthCubit>().signup(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            firstName: _firstNameController.text.trim().isEmpty 
                ? null 
                : _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim().isEmpty 
                ? null 
                : _lastNameController.text.trim(),
            companyName: _companyNameController.text.trim().isEmpty 
                ? null 
                : _companyNameController.text.trim(),
          );
      
      if (message != null && mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppTheme.successColor,
            duration: const Duration(seconds: 4),
          ),
        );
        
        // Clear form and switch to login mode
        setState(() {
          _isSignup = false;
          _formKey.currentState?.reset();
          _emailController.clear();
          _passwordController.clear();
          _firstNameController.clear();
          _lastNameController.clear();
          _companyNameController.clear();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state.isAuthenticated) {
              // Navigate to home - will be handled by main app router
            } else if (state.error != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.error!),
                  backgroundColor: AppTheme.errorColor,
                ),
              );
            }
          },
          builder: (context, state) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 60),
                    // Logo/Icon
                    Icon(
                      Icons.restaurant_menu,
                      size: 80,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(height: 24),
                    // Title
                    Text(
                      'SCP Consumer',
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isSignup ? 'Create your account' : 'Welcome back',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    // Toggle between login and signup
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _isSignup = false;
                              _formKey.currentState?.reset();
                            });
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: !_isSignup 
                                ? AppTheme.primaryColor 
                                : AppTheme.textSecondary,
                          ),
                          child: const Text('Login'),
                        ),
                        Text(
                          '|',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _isSignup = true;
                              _formKey.currentState?.reset();
                            });
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: _isSignup 
                                ? AppTheme.primaryColor 
                                : AppTheme.textSecondary,
                          ),
                          child: const Text('Sign Up'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Email field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'Enter your email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: AppValidators.validateEmail,
                    ),
                    const SizedBox(height: 16),
                    // First name field (signup only)
                    if (_isSignup)
                      TextFormField(
                        controller: _firstNameController,
                        decoration: const InputDecoration(
                          labelText: 'First Name (Optional)',
                          hintText: 'Enter your first name',
                          prefixIcon: Icon(Icons.person_outlined),
                        ),
                      ),
                    if (_isSignup) const SizedBox(height: 16),
                    // Last name field (signup only)
                    if (_isSignup)
                      TextFormField(
                        controller: _lastNameController,
                        decoration: const InputDecoration(
                          labelText: 'Last Name (Optional)',
                          hintText: 'Enter your last name',
                          prefixIcon: Icon(Icons.person_outlined),
                        ),
                      ),
                    if (_isSignup) const SizedBox(height: 16),
                    // Company name field (signup only)
                    if (_isSignup)
                      TextFormField(
                        controller: _companyNameController,
                        decoration: const InputDecoration(
                          labelText: 'Company Name (Optional)',
                          hintText: 'Enter your company name',
                          prefixIcon: Icon(Icons.business_outlined),
                        ),
                      ),
                    if (_isSignup) const SizedBox(height: 16),
                    // Password field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: 'Enter your password',
                        prefixIcon: const Icon(Icons.lock_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      validator: _isSignup
                          ? (value) {
                              if (value == null || value.isEmpty) {
                                return 'Password is required';
                              }
                              if (value.length < 8) {
                                return 'Password must be at least 8 characters';
                              }
                              return null;
                            }
                          : AppValidators.validatePassword,
                    ),
                    const SizedBox(height: 8),
                    // Forgot password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please contact support to reset your password',
                              ),
                              duration: Duration(seconds: 3),
                            ),
                          );
                        },
                        child: const Text('Forgot Password?'),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Login/Signup button
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: state.isLoading 
                            ? null 
                            : (_isSignup ? _handleSignup : _handleLogin),
                        child: state.isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(_isSignup ? 'Sign Up' : 'Login'),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Footer
                    Text(
                      'For Restaurants & Hotels',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

