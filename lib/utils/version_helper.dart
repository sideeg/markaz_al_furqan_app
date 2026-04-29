// Path: lib/utils/version_helper.dart

class VersionHelper {
  /// Returns true if currentVersion < requiredVersion (semantic version comparison)
  static bool isUpdateRequired(String currentVersion, String requiredVersion) {
    if (currentVersion.isEmpty || requiredVersion.isEmpty) return false;

    final currentParts = currentVersion.split('.').map(int.tryParse).toList();
    final requiredParts = requiredVersion.split('.').map(int.tryParse).toList();

    final maxLength = currentParts.length > requiredParts.length
        ? currentParts.length
        : requiredParts.length;

    for (int i = 0; i < maxLength; i++) {
      final currentPart = i < currentParts.length ? (currentParts[i] ?? 0) : 0;
      final requiredPart =
          i < requiredParts.length ? (requiredParts[i] ?? 0) : 0;

      if (currentPart < requiredPart) return true;
      if (currentPart > requiredPart) return false;
    }

    return false; // Versions are equal
  }
}
