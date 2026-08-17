import 'package:flutter_test/flutter_test.dart';
import 'package:sp_mobile/src/core/network/api_base_url.dart';

void main() {
  test('normalizes render backend URL', () {
    expect(
      normalizeApiBaseUrl('https://sp-backend-1-d1iy.onrender.com'),
      'https://sp-backend-1-d1iy.onrender.com/api',
    );
  });

  test('removes accidental whitespace and URL junk', () {
    expect(
      normalizeApiBaseUrl('https://sp-backend-1-d1iy.onrender.com/ api?#'),
      'https://sp-backend-1-d1iy.onrender.com/api',
    );
  });

  test('normalizes production domain without scheme', () {
    expect(
      normalizeApiBaseUrl('pos.sasalink.co.ke'),
      'https://pos.sasalink.co.ke/api',
    );
  });

  test('keeps api path and removes accidental query and fragment', () {
    expect(
      normalizeApiBaseUrl('https://pos.sasalink.co.ke/api?#'),
      'https://pos.sasalink.co.ke/api',
    );
  });

  test('converts absolute api paths to base-url relative paths', () {
    expect(relativeApiPath('/auth/setup/status'), 'auth/setup/status');
  });
}
