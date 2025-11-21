import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/navigation/tv_focus_manager.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/jellyfin/jellyfin_client.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _serverUrlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  final _serverFocusNode = FocusNode();
  final _usernameFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  bool _isLoading = false;
  bool _isServerValid = false;
  String? _errorMessage;
  String? _serverName;

  @override
  void dispose() {
    _serverUrlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _serverFocusNode.dispose();
    _usernameFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _validateServer() async {
    final url = _serverUrlController.text.trim();
    if (url.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final client = ref.read(jellyfinClientProvider);
    client.configure(serverUrl: url);

    final serverInfo = await client.getPublicSystemInfo();

    setState(() {
      _isLoading = false;
      if (serverInfo != null) {
        _isServerValid = true;
        _serverName = serverInfo['ServerName'];
      } else {
        _errorMessage = 'Could not connect to server';
        _isServerValid = false;
      }
    });
  }

  Future<void> _login() async {
    if (!_isServerValid) {
      await _validateServer();
      if (!_isServerValid) return;
    }

    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty) {
      setState(() => _errorMessage = 'Please enter username');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final client = ref.read(jellyfinClientProvider);
    final result = await client.authenticate(username, password);

    setState(() => _isLoading = false);

    if (result.success) {
      if (mounted) {
        context.go('/home');
      }
    } else {
      setState(() => _errorMessage = result.error ?? 'Login failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 500,
            padding: const EdgeInsets.all(48),
            child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'STREAMFLIX',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 48),

              // Title
              const Text(
                'Connect to Jellyfin',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Server URL Field
              TextField(
                controller: _serverUrlController,
                focusNode: _serverFocusNode,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Server URL',
                  hintText: 'http://192.168.1.100:8096',
                  labelStyle: const TextStyle(color: Colors.white70),
                  suffixIcon: _isServerValid
                      ? const Icon(Icons.check_circle, color: AppColors.success)
                      : null,
                ),
                onSubmitted: (_) => _validateServer(),
              ),

              if (_serverName != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Connected to: $_serverName',
                  style: const TextStyle(
                    color: AppColors.success,
                    fontSize: 12,
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Username Field
              TextField(
                controller: _usernameController,
                focusNode: _usernameFocusNode,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Username',
                  labelStyle: TextStyle(color: Colors.white70),
                ),
                onSubmitted: (_) => _passwordFocusNode.requestFocus(),
              ),

              const SizedBox(height: 16),

              // Password Field
              TextField(
                controller: _passwordController,
                focusNode: _passwordFocusNode,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Password',
                  labelStyle: TextStyle(color: Colors.white70),
                ),
                onSubmitted: (_) => _login(),
              ),

              const SizedBox(height: 24),

              // Error Message
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              // Login Button
              TVFocusable(
                onSelect: _isLoading ? null : _login,
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: _isLoading ? AppColors.primary.withOpacity(0.5) : AppColors.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Sign In',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
          ),
        ),
      ),
    );
  }
}
