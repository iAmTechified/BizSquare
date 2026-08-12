import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});
  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _controllers = List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(backgroundColor: const Color(0xFFFAFAFA), elevation: 0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text('Verify your\nnumber 📱', style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w800, color: const Color(0xFF111827), height: 1.15)),
              const SizedBox(height: 8),
              Text('Enter the 4-digit code sent to your phone', style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF6B7280))),
              const SizedBox(height: 48),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(4, (i) => SizedBox(
                  width: 68, height: 68,
                  child: TextFormField(
                    controller: _controllers[i],
                    focusNode: _focusNodes[i],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    inputFormatters: [LengthLimitingTextInputFormatter(1), FilteringTextInputFormatter.digitsOnly],
                    style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700),
                    decoration: InputDecoration(
                      counterText: '',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF4338CA), width: 2)),
                    ),
                    onChanged: (val) {
                      if (val.isNotEmpty && i < 3) FocusScope.of(context).requestFocus(_focusNodes[i + 1]);
                    },
                  ),
                )),
              ),
              const SizedBox(height: 40),
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => context.go('/create-profile'), child: const Text('Verify Code'))),
              const SizedBox(height: 20),
              Center(child: TextButton(
                onPressed: () {},
                child: RichText(text: TextSpan(
                  text: "Didn't receive a code? ",
                  style: GoogleFonts.inter(color: const Color(0xFF6B7280)),
                  children: [TextSpan(text: 'Resend', style: GoogleFonts.inter(color: const Color(0xFF4338CA), fontWeight: FontWeight.w600))],
                )),
              )),
            ],
          ),
        ),
      ),
    );
  }
}
