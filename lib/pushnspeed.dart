import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:appsflyer_sdk/appsflyer_sdk.dart' show AppsFlyerOptions, AppsflyerSdk;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show MethodCall, MethodChannel, SystemUiOverlayStyle;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:timezone/data/latest.dart' as timezone_data;
import 'package:timezone/timezone.dart' as timezone;
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

// Импорты из проекта (имена оставлены, как требуют другие части приложения)
import 'main.dart' show MainHandler, WebPage, PortalView, ScreenPortal, GateVortex, ZxHubView, hvViewModel, crHarbor, MafiaHarbor, GridHarbor;

// ============================================================================
// Локальный минималистичный BLoC (без внешних зависимостей)
// ============================================================================

abstract class PitBlocBase<S> {
  final _stream = StreamController<S>.broadcast();
  late S _state;

  PitBlocBase(S initial) {
    _state = initial;
  }

  S get state => _state;
  Stream<S> get stream => _stream.stream;

  @protected
  void emit(S s) {
    _state = s;
    if (!_stream.isClosed) {
      _stream.add(s);
    }
  }

  @mustCallSuper
  void dispose() {
    _stream.close();
  }
}

// Состояние экрана (BLoC State)
class RaceDeckState {
  final bool loading;
  final String currentRoute;
  final String? fcmToken;
  final String? deviceId;
  final String? osBuild;
  final String? platform;
  final String? language;
  final String? timezoneName;
  final bool pushEnabled;
  final String? lastError;

  const RaceDeckState({
    required this.loading,
    required this.currentRoute,
    required this.pushEnabled,
    this.fcmToken,
    this.deviceId,
    this.osBuild,
    this.platform,
    this.language,
    this.timezoneName,
    this.lastError,
  });

  RaceDeckState copyWith({
    bool? loading,
    String? currentRoute,
    String? fcmToken,
    String? deviceId,
    String? osBuild,
    String? platform,
    String? language,
    String? timezoneName,
    bool? pushEnabled,
    String? lastError,
  }) {
    return RaceDeckState(
      loading: loading ?? this.loading,
      currentRoute: currentRoute ?? this.currentRoute,
      fcmToken: fcmToken ?? this.fcmToken,
      deviceId: deviceId ?? this.deviceId,
      osBuild: osBuild ?? this.osBuild,
      platform: platform ?? this.platform,
      language: language ?? this.language,
      timezoneName: timezoneName ?? this.timezoneName,
      pushEnabled: pushEnabled ?? this.pushEnabled,
      lastError: lastError,
    );
  }
}

// BLoC экрана
class RaceDeckBloc extends PitBlocBase<RaceDeckState> {
  RaceDeckBloc({required String startRoute})
      : super(RaceDeckState(
    loading: false,
    currentRoute: startRoute,
    pushEnabled: true,
  ));

  void setLoading(bool v) => emit(state.copyWith(loading: v));
  void setRoute(String r) => emit(state.copyWith(currentRoute: r));
  void setFcm(String? t) => emit(state.copyWith(fcmToken: t));
  void setDevice({
    String? id,
    String? osBuild,
    String? platform,
    String? language,
    String? tz,
  }) =>
      emit(state.copyWith(
        deviceId: id,
        osBuild: osBuild,
        platform: platform,
        language: language,
        timezoneName: tz,
      ));
  void setPushEnabled(bool b) => emit(state.copyWith(pushEnabled: b));
  void setError(String? e) => emit(state.copyWith(lastError: e));
}

// ============================================================================
// FCM Background Handler -- пиратская шхуна слушает трубу
// ============================================================================
@pragma('vm:entry-point')
Future<void> blackflag_bg_parrot(RemoteMessage msg_bottle) async {
  print("Bottle ID: ${msg_bottle.messageId}");
  print("Bottle Data: ${msg_bottle.data}");
}

// ============================================================================
// Виджет-каюта с веб-вью -- главный борт (переименовано в гоночном стиле)
// ============================================================================
class SpeedCaptainDeck extends StatefulWidget with WidgetsBindingObserver {
  String pitLane;
  SpeedCaptainDeck(this.pitLane, {super.key});

  @override
  State<SpeedCaptainDeck> createState() => _SpeedCaptainDeckState(pitLane);
}

class _SpeedCaptainDeckState extends State<SpeedCaptainDeck> with WidgetsBindingObserver {
  _SpeedCaptainDeckState(this._gridLane);

  // BLoC
  late final RaceDeckBloc _bloc;

  // WebView
  late InAppWebViewController _pitHelm;

  // Девайс/FCM
  String? _nitroParrot; // FCM token
  String? _vinCode; // device id
  String? _buildCode; // os build
  String? _gridKind; // android/ios
  String? _gridLang; // locale/lang
  String? _zoneClock; // timezone name
  bool _pushArmed = true; // push enabled

  // Стейт
  bool _crewBusy = false;
  bool _gateOpen = true;
  String _gridLane;
  DateTime? _lastDockTime;

  // AppsFlyer (если понадобится дальше — поля сохранены)
  AppsflyerSdk? _afSpyglass;
  String _afChest = "";
  String _afId = "";

  // Внешние гавани (tg/wa/bnl)
  final Set<String> _harborHosts = {
    't.me',
    'telegram.me',
    'telegram.dog',
    'wa.me',
    'api.whatsapp.com',
    'chat.whatsapp.com',
    'bnl.com',
    'www.bnl.com',
  };
  final Set<String> _harborSchemes = {'tg', 'telegram', 'whatsapp', 'bnl'};

  @override
  void initState() {
    super.initState();

    // Инициализация BLoC
    _bloc = RaceDeckBloc(startRoute: _gridLane);

    WidgetsBinding.instance.addObserver(this);

    FirebaseMessaging.onBackgroundMessage(blackflag_bg_parrot);

    _armParrotFCM();
    _scanGridRig();
    _wirePitFCM();
    _bindCrowBell();

    // Доп. отложки, как в исходном
    Future.delayed(const Duration(seconds: 2), () {});
    Future.delayed(const Duration(seconds: 6), () {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bloc.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState tide) {
    if (tide == AppLifecycleState.paused) {
      _lastDockTime = DateTime.now();
    }
    if (tide == AppLifecycleState.resumed) {
      if (Platform.isIOS && _lastDockTime != null) {
        final now = DateTime.now();
        final drift = now.difference(_lastDockTime!);
        if (drift > const Duration(minutes: 25)) {
          _hardReloadToHarbor();
        }
      }
      _lastDockTime = null;
    }
  }

  void _hardReloadToHarbor() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => GridHarbor(pulse: '',),
        ),
            (route) => false,
      );
    });
  }

  // --------------------------------------------------------------------------
  // FCM wire (foreground handlers)
  // --------------------------------------------------------------------------
  void _wirePitFCM() {
    FirebaseMessaging.onMessage.listen((RemoteMessage bottle) {
      if (bottle.data['uri'] != null) {
        _pitHop(bottle.data['uri'].toString());
      } else {
        _returnToGrid();
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage bottle) {
      if (bottle.data['uri'] != null) {
        _pitHop(bottle.data['uri'].toString());
      } else {
        _returnToGrid();
      }
    });
  }

  void _pitHop(String newLane) async {
    if (_pitHelm != null) {
      await _pitHelm.loadUrl(urlRequest: URLRequest(url: WebUri(newLane)));
      _bloc.setRoute(newLane);
    }
  }

  void _returnToGrid() async {
    Future.delayed(const Duration(seconds: 3), () {
      if (_pitHelm != null) {
        _pitHelm.loadUrl(urlRequest: URLRequest(url: WebUri(_gridLane)));
      }
    });
  }

  // --------------------------------------------------------------------------
  // FCM boot and token
  // --------------------------------------------------------------------------
  Future<void> _armParrotFCM() async {
    try {
      FirebaseMessaging deck = FirebaseMessaging.instance;
      await deck.requestPermission(alert: true, badge: true, sound: true);
      _nitroParrot = await deck.getToken();
      _bloc.setFcm(_nitroParrot);
    } catch (e) {
      debugPrint("FCM boot error: $e");
      _bloc.setError("FCM init error");
    }
  }

  // --------------------------------------------------------------------------
  // Device dossier
  // --------------------------------------------------------------------------
  Future<void> _scanGridRig() async {
    try {
      final spy = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final a = await spy.androidInfo;
        _vinCode = a.id;
        _gridKind = "android";
        _buildCode = a.version.release;
      } else if (Platform.isIOS) {
        final i = await spy.iosInfo;
        _vinCode = i.identifierForVendor;
        _gridKind = "ios";
        _buildCode = i.systemVersion;
      }
      final pkg = await PackageInfo.fromPlatform();
      _gridLang = Platform.localeName.split('_')[0];
      _zoneClock = timezone.local.name;

      _bloc.setDevice(
        id: _vinCode,
        osBuild: _buildCode,
        platform: _gridKind,
        language: _gridLang,
        tz: _zoneClock,
      );
    } catch (e) {
      debugPrint("Ship Gizmo Error: $e");
      _bloc.setError("Device info error");
    }
  }

  /// Привязываем колокол -- обработчик взаимодействия нотификаций из платформы
  void _bindCrowBell() {
    MethodChannel('com.example.fcm/notification').setMethodCallHandler((MethodCall call) async {
      if (call.method == "onNotificationTap") {
        final Map<String, dynamic> bottle = Map<String, dynamic>.from(call.arguments);
        print("URI from mast: ${bottle['uri']}");
        if (bottle["uri"] != null && !bottle["uri"].toString().contains("Нет URI")) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => SpeedCaptainDeck(bottle["uri"])),
                (route) => false,
          );
        }
      }
    });
  }

  // =========================
  // Утилиты гавани
  // =========================

  bool _looksLikeBottleMail(Uri u) {
    final s = u.scheme;
    if (s.isNotEmpty) return false;
    final raw = u.toString();
    return raw.contains('@') && !raw.contains(' ');
  }

  Uri _craftMailto(Uri u) {
    final full = u.toString();
    final bits = full.split('?');
    final who = bits.first;
    final qp = bits.length > 1 ? Uri.splitQueryString(bits[1]) : <String, String>{};
    return Uri(
      scheme: 'mailto',
      path: who,
      queryParameters: qp.isEmpty ? null : qp,
    );
  }

  bool _isOuterHarbor(Uri u) {
    final sch = u.scheme.toLowerCase();
    if (_harborSchemes.contains(sch)) return true;

    if (sch == 'http' || sch == 'https') {
      final h = u.host.toLowerCase();
      if (_harborHosts.contains(h)) return true;
    }
    return false;
  }

  Uri _mapOuterToHttp(Uri u) {
    final sch = u.scheme.toLowerCase();

    if (sch == 'tg' || sch == 'telegram') {
      final qp = u.queryParameters;
      final domain = qp['domain'];
      if (domain != null && domain.isNotEmpty) {
        return Uri.https('t.me', '/$domain', {
          if (qp['start'] != null) 'start': qp['start']!,
        });
      }
      final path = u.path.isNotEmpty ? u.path : '';
      return Uri.https('t.me', '/$path', u.queryParameters.isEmpty ? null : u.queryParameters);
    }

    if (sch == 'whatsapp') {
      final qp = u.queryParameters;
      final phone = qp['phone'];
      final text = qp['text'];
      if (phone != null && phone.isNotEmpty) {
        return Uri.https('wa.me', '/${_digitsOnly(phone)}', {
          if (text != null && text.isNotEmpty) 'text': text,
        });
      }
      return Uri.https('wa.me', '/', {if (text != null && text.isNotEmpty) 'text': text});
    }

    if (sch == 'bnl') {
      final newPath = u.path.isNotEmpty ? u.path : '';
      return Uri.https('bnl.com', '/$newPath', u.queryParameters.isEmpty ? null : u.queryParameters);
    }

    return u;
  }

  Future<bool> _openMailInWeb(Uri m) async {
    final g = _gmailCourse(m);
    return await _openInHarbor(g);
  }

  Uri _gmailCourse(Uri m) {
    final qp = m.queryParameters;
    final params = <String, String>{
      'view': 'cm',
      'fs': '1',
      if (m.path.isNotEmpty) 'to': m.path,
      if ((qp['subject'] ?? '').isNotEmpty) 'su': qp['subject']!,
      if ((qp['body'] ?? '').isNotEmpty) 'body': qp['body']!,
      if ((qp['cc'] ?? '').isNotEmpty) 'cc': qp['cc']!,
      if ((qp['bcc'] ?? '').isNotEmpty) 'bcc': qp['bcc']!,
    };
    return Uri.https('mail.google.com', '/mail/', params);
  }

  Future<bool> _openInHarbor(Uri u) async {
    try {
      if (await launchUrl(u, mode: LaunchMode.inAppBrowserView)) return true;
      return await launchUrl(u, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('openInHarbor squall: $e; url=$u');
      try {
        return await launchUrl(u, mode: LaunchMode.externalApplication);
      } catch (e2) {
        return false;
      }
    }
  }

  String _digitsOnly(String s) => s.replaceAll(RegExp(r'[^0-9+]'), '');

  // ========================================================================
  // UI
  // ========================================================================
  @override
  Widget build(BuildContext context) {
    // держим привязку колокола, как было задумано
    _bindCrowBell();

    final isNight = MediaQuery.of(context).platformBrightness == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isNight ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: StreamBuilder<RaceDeckState>(
          stream: _bloc.stream,
          initialData: _bloc.state,
          builder: (context, snap) {
            final st = snap.data ?? _bloc.state;
            _gridLane = st.currentRoute; // синхронизируем
            _crewBusy = st.loading;

            return Stack(
              children: [
                InAppWebView(
                  initialSettings: InAppWebViewSettings(
                    javaScriptEnabled: true,
                    disableDefaultErrorPage: true,
                    mediaPlaybackRequiresUserGesture: false,
                    allowsInlineMediaPlayback: true,
                    allowsPictureInPictureMediaPlayback: true,
                    useOnDownloadStart: true,
                    javaScriptCanOpenWindowsAutomatically: true,
                    useShouldOverrideUrlLoading: true,
                    supportMultipleWindows: true,
                  ),
                  initialUrlRequest: URLRequest(url: WebUri.uri(Uri.parse(_gridLane))),
                  onWebViewCreated: (controller) {
                    _pitHelm = controller;

                    _pitHelm.addJavaScriptHandler(
                      handlerName: 'onServerResponse',
                      callback: (args) {
                        print("JS Args: $args");
                        try {
                          return args.reduce((v, e) => v + e);
                        } catch (_) {
                          return args.toString();
                        }
                      },
                    );
                  },
                  onLoadStart: (controller, uri) async {
                    _bloc.setLoading(true);
                    if (uri != null) {
                      if (_looksLikeBottleMail(uri)) {
                        try {
                          await controller.stopLoading();
                        } catch (_) {}
                        final mailto = _craftMailto(uri);
                        await _openMailInWeb(mailto);
                        return;
                      }
                      final s = uri.scheme.toLowerCase();
                      if (s != 'http' && s != 'https') {
                        try {
                          await controller.stopLoading();
                        } catch (_) {}
                      }
                    }
                  },
                  onLoadStop: (controller, uri) async {
                    await controller.evaluateJavascript(source: "console.log('Ahoy from JS!');");
                    _bloc.setLoading(false);
                    if (uri != null) _bloc.setRoute(uri.toString());
                  },
                  onLoadError: (controller, uri, code, msg) async {
                    _bloc.setLoading(false);
                    _bloc.setError("InAppWebView error $code: $msg");
                  },
                  onReceivedError: (controller, request, error) async {
                    _bloc.setLoading(false);
                    _bloc.setError("WebResourceError: ${error.description}");
                  },
                  onReceivedHttpError: (controller, request, errorResponse) async {
                    // HTTP ошибки тоже можно логировать
                  },
                  shouldOverrideUrlLoading: (controller, nav) async {
                    final uri = nav.request.url;
                    if (uri == null) return NavigationActionPolicy.ALLOW;

                    if (_looksLikeBottleMail(uri)) {
                      final mailto = _craftMailto(uri);
                      await _openMailInWeb(mailto);
                      return NavigationActionPolicy.CANCEL;
                    }

                    final sch = uri.scheme.toLowerCase();
                    if (sch == 'mailto') {
                      await _openMailInWeb(uri);
                      return NavigationActionPolicy.CANCEL;
                    }

                    if (_isOuterHarbor(uri)) {
                      await _openInHarbor(_mapOuterToHttp(uri));
                      return NavigationActionPolicy.CANCEL;
                    }

                    if (sch != 'http' && sch != 'https') {
                      return NavigationActionPolicy.CANCEL;
                    }

                    return NavigationActionPolicy.ALLOW;
                  },
                  onCreateWindow: (controller, req) async {
                    final u = req.request.url;
                    if (u == null) return false;

                    if (_looksLikeBottleMail(u)) {
                      final m = _craftMailto(u);
                      await _openMailInWeb(m);
                      return false;
                    }

                    final sch = u.scheme.toLowerCase();
                    if (sch == 'mailto') {
                      await _openMailInWeb(u);
                      return false;
                    }

                    if (_isOuterHarbor(u)) {
                      await _openInHarbor(_mapOuterToHttp(u));
                      return false;
                    }

                    if (sch == 'http' || sch == 'https') {
                      controller.loadUrl(urlRequest: URLRequest(url: u));
                    }
                    return false;
                  },
                ),

                // Индикатор загрузки
                if (_crewBusy)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black87,
                      child: Center(
                        child: CircularProgressIndicator(
                          backgroundColor: Colors.grey.shade800,
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                          strokeWidth: 6,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}