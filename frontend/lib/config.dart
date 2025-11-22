class AppConfig {
  /// Altere para TRUE quando quiser usar o emulador
  /// Altere para FALSE quando quiser usar o celular/navegador
  static const bool useEmulator = false;

  /// IP do emulador Android
  static const String emulatorBaseUrl = 'http://10.0.2.2:3000';

  /// IP da sua rede local
  static const String localBaseUrl = 'http://192.168.100.12:3000';

  /// URL final usada pela API
  static String get baseUrl {
    return useEmulator ? emulatorBaseUrl : localBaseUrl;
  }
}
