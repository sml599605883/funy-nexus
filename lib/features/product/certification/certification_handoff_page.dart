import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fund_nexus/core/session/session_store.dart';
import 'package:fund_nexus/features/product/certification/face_verification_page.dart';
import 'package:fund_nexus/features/product/certification/identity_selection_page.dart';
import 'package:fund_nexus/features/product/certification/personal_information_page.dart';

class CertificationHandoffPage extends StatelessWidget {
  const CertificationHandoffPage({
    required this.productId,
    required this.step,
    super.key,
  });

  final String productId;
  final String step;

  @override
  Widget build(BuildContext context) {
    if (step == 'public') {
      return IdentitySelectionPage(productId: productId);
    }
    if (step == 'personal') {
      return PersonalInformationPage(productId: productId);
    }
    if (step == 'face') {
      final session = context.read<SessionStore>();
      return FaceVerificationPage(
        productId: productId,
        orderNumber: session.productDetailOrderNumber,
        promptMessage: session.productDetailFaceGuidance,
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Complete your information')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.assignment_outlined, size: 48),
            const SizedBox(height: 16),
            const Text(
              'A verification step is required before you can continue.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Back'),
            ),
          ],
        ),
      ),
    );
  }
}
