import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_logger.dart';

class AppProviderObserver extends ProviderObserver {
  const AppProviderObserver();

  @override
  void didAddProvider(
    ProviderBase<Object?> provider,
    Object? value,
    ProviderContainer container,
  ) {
    AppLogger.debug('provider:add ${_providerName(provider)}');
  }

  @override
  void didUpdateProvider(
    ProviderBase<Object?> provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    AppLogger.debug('provider:update ${_providerName(provider)}');
  }

  @override
  void didDisposeProvider(
    ProviderBase<Object?> provider,
    ProviderContainer container,
  ) {
    AppLogger.debug('provider:dispose ${_providerName(provider)}');
  }

  @override
  void providerDidFail(
    ProviderBase<Object?> provider,
    Object error,
    StackTrace stackTrace,
    ProviderContainer container,
  ) {
    AppLogger.error(
      'provider:fail ${_providerName(provider)}',
      error: error,
      stackTrace: stackTrace,
    );
  }

  String _providerName(ProviderBase<Object?> provider) {
    if (provider.name != null) return provider.name!;
    if (kDebugMode) return provider.toString();
    return provider.runtimeType.toString();
  }
}
