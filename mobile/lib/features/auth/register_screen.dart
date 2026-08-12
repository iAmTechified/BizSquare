import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(backgroundColor: const Color(0xFFFAFAFA), elevation: 0, leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 18), onPressed: () => context.go('/welcome'))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text('Create\naccount ✨', style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w800, color: const Color(0xFF111827), height: 1.15)),
              const SizedBox(height: 8),
              Text('Join thousands of businesses growing together', style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF6B7280))),
              const SizedBox(height: 36),
              TextFormField(decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline))),
              const SizedBox(height: 16),
              TextFormField(decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone_outlined))),
              const SizedBox(height: 16),
              TextFormField(decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.alternate_email_outlined))),
              const SizedBox(height: 16),
              TextFormField(
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined), onPressed: () => setState(() => _obscure = !_obscure)),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => context.go('/otp'), child: const Text('Create Account'))),
              const SizedBox(height: 20),
              Text('By creating an account, you agree to our Terms of Service and Privacy Policy.', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF9CA3AF), height: 1.5)),
              const SizedBox(height: 32),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('Already have an account? ', style: GoogleFonts.inter(color: const Color(0xFF6B7280))),
                GestureDetector(onTap: () => context.go('/login'), child: Text('Sign In', style: GoogleFonts.inter(color: const Color(0xFF4338CA), fontWeight: FontWeight.w600))),
              ]),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
