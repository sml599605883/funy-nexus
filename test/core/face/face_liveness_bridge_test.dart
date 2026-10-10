import 'package:flutter_test/flutter_test.dart';
import 'package:fund_nexus/core/face/face_liveness_bridge.dart';

void main() {
  test('accepts a liveness result when it carries an image and liveness id', () {
    const result = FaceLivenessResult(
      success: false,
      code: 3001,
      message: 'completed',
      image: 'base64-image',
      livenessId: 'liveness-42',
    );

    expect(result.hasUploadableData, isTrue);
  });

  test('rejects a liveness result missing the image or liveness id', () {
    const missingImage = FaceLivenessResult(
      success: true,
      code: 0,
      message: '',
      image: '   ',
      livenessId: 'liveness-42',
    );
    const missingLivenessId = FaceLivenessResult(
      success: true,
      code: 0,
      message: '',
      image: 'base64-image',
      livenessId: '',
    );

    expect(missingImage.hasUploadableData, isFalse);
    expect(missingLivenessId.hasUploadableData, isFalse);
  });
}
