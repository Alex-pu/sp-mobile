class AppConfig {
  static const defaultApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:5000/api',
  );

  static const neonAuthUrl = String.fromEnvironment(
    'NEON_AUTH_URL',
    defaultValue:
        'https://ep-tiny-surf-ayijej8k.neonauth.c-5.us-east-2.aws.neon.tech/neondb/auth',
  );
}
