class LinkUtils {
  static String sanitizeUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final queryParameters = Map<String, String>.from(uri.queryParameters);

      // Common tracking parameters to remove
      final trackingParameters = [
        'utm_source',
        'utm_medium',
        'utm_campaign',
        'utm_term',
        'utm_content',
        'fbclid',
        'gclid',
        'mc_cid',
        'mc_eid',
        '_hsenc',
        '_hsmi',
        'hsCtaTracking',
      ];

      for (var param in trackingParameters) {
        queryParameters.remove(param);
      }

      final sanitizedUri = uri.replace(queryParameters: queryParameters);
      var result = sanitizedUri.toString();

      // Remove trailing '?' if no query parameters remain
      if (queryParameters.isEmpty && result.endsWith('?')) {
        result = result.substring(0, result.length - 1);
      }

      return result;
    } catch (e) {
      // Return original URL if parsing fails
      return url;
    }
  }
}