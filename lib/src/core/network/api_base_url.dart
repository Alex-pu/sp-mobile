String? normalizeApiBaseUrl(String input) {
  var value = input.replaceAll(RegExp(r'\s+'), '');
  if (value.isEmpty) {
    return null;
  }
  if (!value.startsWith('http://') && !value.startsWith('https://')) {
    value = 'https://$value';
  }

  final uri = Uri.tryParse(value);
  if (uri == null || uri.host.isEmpty) {
    return null;
  }

  var path = uri.path.replaceFirst(RegExp(r'/$'), '');
  if (path.isEmpty) {
    path = '/api';
  } else if (!path.endsWith('/api')) {
    path = '$path/api';
  }

  return '${uri.scheme}://${uri.authority}$path/';
}

String relativeApiPath(String path) {
  if (path.startsWith('http://') || path.startsWith('https://')) {
    return path;
  }
  return path.replaceFirst(RegExp(r'^/+'), '');
}
