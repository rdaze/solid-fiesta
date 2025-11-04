class AppConstants {
  static const profileName = 'laralacht';

  static String reelsMetadataPath(String profile) =>
      'assets/metadata/$profile.json';
  static String dmsMetadataPath(String profile) =>
      'assets/metadata/${profile}_dms.json';
  static String videosDirForProfile(String profile) =>
      'assets/videos/$profile/';
}
