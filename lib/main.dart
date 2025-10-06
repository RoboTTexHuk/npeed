import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform, HttpHeaders, HttpClient;

import 'package:appsflyer_sdk/appsflyer_sdk.dart' as af_core;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show MethodChannel, SystemChrome, SystemUiOverlayStyle, DeviceOrientation, MethodCall;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as r;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:nspeed/pushnspeed.dart' show SpeedCaptainDeck;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz_zone;

const String _kPitLoadedEventLatch = "loaded_event_sent_once";
const String kStatUrl = "https://cfd.mafiaexplorer.cfd/stat";
const String _kPitCachedFcmKey = "cached_fcm_token";

final FlutterSecureStorage pitVault = const FlutterSecureStorage();
final Logger pitLogger = Logger();
final Connectivity pitNet = Connectivity();

class NitroWire {
  Future<bool> linkUp() async {
    final grip = await pitNet.checkConnectivity();
    return grip != ConnectivityResult.none;
  }

  Future<void> pitPostJson(String lane, Map<String, dynamic> cargo) async {
    try {
      await http.post(
        Uri.parse(lane),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(cargo),
      );
    } catch (e) {
      pitLogger.e("pitPostJson fail: $e");
    }
  }
}

class GridDossier {
  String? vin;
  String? stint = "mafia-one-off";
  String? deck;
  String? deckVer;
  String? appVer;
  String? lingua;
  String? chronoZone;
  bool pushArm = true;

  Future<void> assemble() async {
    final di = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final pad = await di.androidInfo;
      vin = pad.id;
      deck = "android";
      deckVer = pad.version.release;
    } else if (Platform.isIOS) {
      final pad = await di.iosInfo;
      vin = pad.identifierForVendor;
      deck = "ios";
      deckVer = pad.systemVersion;
    }
    final kit = await PackageInfo.fromPlatform();
    appVer = kit.version;
    lingua = Platform.localeName.split('_')[0];
    chronoZone = tz_zone.local.name;
    stint = "sitdown-${DateTime.now().millisecondsSinceEpoch}";
  }

  Map<String, dynamic> toMap({String? fcm}) => {
    "fcm_token": fcm ?? 'missing_token',
    "device_id": vin ?? 'missing_id',
    "app_name": "nspeed",
    "instance_id": stint ?? 'missing_session',
    "platform": deck ?? 'missing_system',
    "os_version": deckVer ?? 'missing_build',
    "app_version": appVer ?? 'missing_app',
    "language": lingua ?? 'en',
    "timezone": chronoZone ?? 'UTC',
    "push_enabled": pushArm,
  };
}

class TurboConsigliere with ChangeNotifier {
  af_core.AppsFlyerOptions? _spec;
  af_core.AppsflyerSdk? _rack;

  String gridId = "";
  String gridPayload = "";

  void summon(VoidCallback rev) {
    final cfg = af_core.AppsFlyerOptions(
      afDevKey: "qsBLmy7dAXDQhowM8V3ca4",
      appId: "6752954951",
      showDebug: true,
      timeToWaitForATTUserAuthorization: 0,
    );
    _spec = cfg;
    _rack = af_core.AppsflyerSdk(cfg);
    _rack?.initSdk(
      registerConversionDataCallback: true,
      registerOnAppOpenAttributionCallback: true,
      registerOnDeepLinkingCallback: true,
    );
    _rack?.startSDK(
      onSuccess: () => pitLogger.i("Consigliere up"),
      onError: (int c, String m) => pitLogger.e("Consigliere err $c: $m"),
    );
    _rack?.onInstallConversionData((res) {
      gridPayload = res.toString();
      rev();
      notifyListeners();
    });
    _rack?.getAppsFlyerUID().then((v) {
      gridId = v.toString();
      rev();
      notifyListeners();
    });
  }
}

final gridDossierProvider = r.FutureProvider<GridDossier>((ref) async {
  final card = GridDossier();
  await card.assemble();
  return card;
});

final turboConsigliereProvider =
p.ChangeNotifierProvider<TurboConsigliere>(create: (_) => TurboConsigliere());

class PitPulseLoader extends StatefulWidget {
  const PitPulseLoader({Key? key}) : super(key: key);

  @override
  State<PitPulseLoader> createState() => _PitPulseLoaderState();
}

class _PitPulseLoaderState extends State<PitPulseLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _tilt;
  late Animation<double> _rise;
  late Animation<double> _dash;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
    final curveWheelie =
    CurvedAnimation(parent: _ctrl, curve: const Cubic(0.3, 0.0, 0.2, 1.0));
    _tilt = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.38), weight: 35),
      TweenSequenceItem(tween: ConstantTween(0.38), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.38, end: 0.0), weight: 40),
    ]).animate(curveWheelie);
    _rise = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -28.0), weight: 35),
      TweenSequenceItem(tween: ConstantTween(-28.0), weight: 25),
      TweenSequenceItem(tween: Tween(begin: -28.0, end: 0.0), weight: 20),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 20),
    ]).animate(curveWheelie);
    _dash = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 70),
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 30),
    ]).animate(curveWheelie);
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.06), weight: 35),
      TweenSequenceItem(tween: ConstantTween(1.06), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 1.06, end: 1.0), weight: 40),
    ]).animate(curveWheelie);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          final dx = _dash.value * size.width * 1.2;
          final dy = _rise.value;
          return Container(
            color: Colors.black,
            alignment: Alignment.center,
            child: Transform.translate(
              offset: Offset(dx, dy),
              child: Transform.rotate(
                angle: _tilt.value,
                child: Transform.scale(
                  scale: _scale.value,
                  child: Text(
                    "NSPEED",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.redAccent.shade400,
                      fontSize: 52,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 6,
                      shadows: const [
                        Shadow(
                            color: Colors.black,
                            blurRadius: 8,
                            offset: Offset(0, 2)),
                        Shadow(
                            color: Colors.red,
                            blurRadius: 16,
                            offset: Offset(0, 0)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

@pragma('vm:entry-point')
Future<void> pitBgFcm(RemoteMessage pulse) async {
  pitLogger.i("bg-ping: ${pulse.messageId}");
  pitLogger.i("bg-payload: ${pulse.data}");
}

class NitroTokenBridge extends ChangeNotifier {
  String? _octane;
  StreamSubscription<String>? _ghost;
  final List<void Function(String)> _awaiters = [];
  String? get token => _octane;

  NitroTokenBridge() {
    const MethodChannel('com.example.fcm/token')
        .setMethodCallHandler((call) async {
      if (call.method == 'setToken') {
        final String s = call.arguments as String;
        if (s.isNotEmpty) {
          _primeToken(s);
        }
      }
    });
    _restore();
  }

  Future<void> _restore() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final cached = sp.getString(_kPitCachedFcmKey);
      if (cached != null && cached.isNotEmpty) {
        _primeToken(cached, report: false);
      } else {
        final ss = await pitVault.read(key: _kPitCachedFcmKey);
        if (ss != null && ss.isNotEmpty) {
          _primeToken(ss, report: false);
        }
      }
    } catch (_) {}
  }

  void _primeToken(String tk, {bool report = true}) async {
    _octane = tk;
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setString(_kPitCachedFcmKey, tk);
      await pitVault.write(key: _kPitCachedFcmKey, value: tk);
    } catch (_) {}
    for (final fn in List.of(_awaiters)) {
      try {
        fn(tk);
      } catch (e) {
        pitLogger.w("await-cb glitch: $e");
      }
    }
    _awaiters.clear();
    notifyListeners();
  }

  Future<void> ensureToken(Function(String token) onToken) async {
    try {
      await FirebaseMessaging.instance
          .requestPermission(alert: true, badge: true, sound: true);
      if (_octane != null && _octane!.isNotEmpty) {
        onToken(_octane!);
        return;
      }
      _awaiters.add(onToken);
    } catch (e) {
      pitLogger.e("FCM ensureToken error: $e");
    }
  }

  @override
  void dispose() {
    _ghost?.cancel();
    super.dispose();
  }
}

class GridVestibule extends StatefulWidget {
  const GridVestibule({Key? key}) : super(key: key);

  @override
  State<GridVestibule> createState() => _GridVestibuleState();
}

class _GridVestibuleState extends State<GridVestibule> {
  final NitroTokenBridge _fuel = NitroTokenBridge();
  bool _armOnce = false;
  Timer? _bail;
  bool _muteCover = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.black,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ));
    _fuel.ensureToken((sig) {
      _shotgun(sig);
    });
    _bail = Timer(const Duration(seconds: 8), () => _shotgun(''));
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _muteCover = true);
    });
  }

  void _shotgun(String sig) {
    if (_armOnce) return;
    _armOnce = true;
    _bail?.cancel();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => GridHarbor(pulse: sig),
      ),
    );
  }

  @override
  void dispose() {
    _bail?.cancel();
    _fuel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (!_muteCover) const PitPulseLoader(),
          if (_muteCover) const Center(child: PitPulseLoader()),
        ],
      ),
    );
  }
}

class GridViewModel with ChangeNotifier {
  final GridDossier dossier;
  final TurboConsigliere consigliere;

  GridViewModel({required this.dossier, required this.consigliere});

  Map<String, dynamic> emitDevice(String? token) => dossier.toMap(fcm: token);

  Map<String, dynamic> emitAF(String? token) {
    return {
      "content": {
        "af_data": consigliere.gridPayload,
        "af_id": consigliere.gridId,
        "fb_app_name": "nspeed",
        "app_name": "nspeed",
        "deep": null,
        "bundle_identifier": "com.efopl.nspeed",
        "app_version": "1.0.0",
        "apple_id": "6752954951",
        "fcm_token": token ?? "no_token",
        "device_id": dossier.vin ?? "no_device",
        "instance_id": dossier.stint ?? "no_instance",
        "platform": dossier.deck ?? "no_type",
        "os_version": dossier.deckVer ?? "no_os",
        "app_version": dossier.appVer ?? "no_app",
        "language": dossier.lingua ?? "en",
        "timezone": dossier.chronoZone ?? "UTC",
        "push_enabled": dossier.pushArm,
        "useruid": consigliere.gridId,
      },
    };
  }
}

class GridCourier {
  final GridViewModel pitModel;
  final InAppWebViewController Function() webGetter;

  GridCourier({required this.pitModel, required this.webGetter});

  Future<void> pushDeviceLocalStorage(String? token) async {
    final p = pitModel.emitDevice(token);
    await webGetter().evaluateJavascript(source: '''
localStorage.setItem('app_data', JSON.stringify(${jsonEncode(p)}));
''');
  }

  Future<void> pushAfSendRaw(String? token) async {
    final payload = pitModel.emitAF(token);
    final jsonString = jsonEncode(payload);
    pitLogger.i("SendRawData: $jsonString");
    await webGetter().evaluateJavascript(
      source: "sendRawData(${jsonEncode(jsonString)});",
    );
  }
}

Future<String> gridResolveFinalUrl(String startUrl, {int maxHops = 10}) async {
  final agent = HttpClient();
  agent.userAgent = 'Mozilla/5.0 (Flutter; dart:io HttpClient)';
  try {
    var current = Uri.parse(startUrl);
    for (int i = 0; i < maxHops; i++) {
      final req = await agent.getUrl(current);
      req.followRedirects = false;
      final res = await req.close();
      if (res.isRedirect) {
        final loc = res.headers.value(HttpHeaders.locationHeader);
        if (loc == null || loc.isEmpty) break;
        final next = Uri.parse(loc);
        current = next.hasScheme ? next : current.resolveUri(next);
        continue;
      }
      return current.toString();
    }
    return current.toString();
  } catch (e) {
    debugPrint("gridResolveFinalUrl error: $e");
    return startUrl;
  } finally {
    agent.close(force: true);
  }
}

Future<void> gridPostStat({
  required String event,
  required int timeStart,
  required String url,
  required int timeFinish,
  required String appSid,
  int? firstPageLoadTs,
}) async {
  try {
    final finalUrl = await gridResolveFinalUrl(url);
    final payload = {
      "event": event,
      "timestart": timeStart,
      "timefinsh": timeFinish,
      "url": finalUrl,
      "appleID": "6752954951",
      "open_count": "$appSid/$timeStart",
    };
    final res = await http.post(
      Uri.parse("$kStatUrl/$appSid"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(payload),
    );
    debugPrint("_postStat status=${res.statusCode} body=${res.body}");
  } catch (e) {
    debugPrint("_postStat error: $e");
  }
}

abstract class GridEvent extends Equatable {
  const GridEvent();
  @override
  List<Object?> get props => [];
}

class GridInitRequested extends GridEvent {
  final String? fcmToken;
  const GridInitRequested({this.fcmToken});
}

class GridSendLoadedOnce extends GridEvent {
  final String url;
  final int timeStart;
  final String appSid;
  final int? firstPageLoadTs;
  const GridSendLoadedOnce({
    required this.url,
    required this.timeStart,
    required this.appSid,
    this.firstPageLoadTs,
  });
}

abstract class GridState extends Equatable {
  const GridState();
  @override
  List<Object?> get props => [];
}

class GridInitial extends GridState {}

class GridLoading extends GridState {}

class GridReady extends GridState {
  final Map<String, dynamic> deviceMap;
  const GridReady(this.deviceMap);
  @override
  List<Object?> get props => [deviceMap];
}

class GridError extends GridState {
  final String message;
  const GridError(this.message);
  @override
  List<Object?> get props => [message];
}

class GridBloc extends Bloc<GridEvent, GridState> {
  final GridDossier dossier;
  final TurboConsigliere consigliere;
  final Future<void> Function({
  required String event,
  required int timeStart,
  required String url,
  required int timeFinish,
  required String appSid,
  int? firstPageLoadTs,
  }) postStat;
  bool _loadedSent = false;

  GridBloc({
    required this.dossier,
    required this.consigliere,
    required this.postStat,
  }) : super(GridInitial()) {
    on<GridInitRequested>(_onInit);
    on<GridSendLoadedOnce>(_onLoadedOnce);
  }

  Future<void> _onInit(GridInitRequested e, Emitter<GridState> emit) async {
    emit(GridLoading());
    try {
      if (dossier.vin == null) {
        await dossier.assemble();
      }
      final map = dossier.toMap(fcm: e.fcmToken);
      emit(GridReady(map));
    } catch (err) {
      emit(GridError("Init error: $err"));
    }
  }

  Future<void> _onLoadedOnce(GridSendLoadedOnce e, Emitter<GridState> emit) async {
    if (_loadedSent) return;
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      await postStat(
        event: "Loaded",
        timeStart: e.timeStart,
        timeFinish: now,
        url: e.url,
        appSid: e.appSid,
        firstPageLoadTs: e.firstPageLoadTs,
      );
      _loadedSent = true;
    } catch (err) {
      pitLogger.e("GridSendLoadedOnce error: $err");
    }
  }
}

class GridHarbor extends StatefulWidget {
  final String? pulse;
  const GridHarbor({super.key, required this.pulse});

  @override
  State<GridHarbor> createState() => _GridHarborState();
}

class _GridHarborState extends State<GridHarbor> with WidgetsBindingObserver {
  late InAppWebViewController _dock;
  bool _spinner = false;
  final String _gridAxis = "https://api.reversgear.center/";
  final GridDossier _rig = GridDossier();
  final TurboConsigliere _boss = TurboConsigliere();
  int _rev = 0;
  DateTime? _napAt;
  bool _scrim = false;
  double _warmMeter = 0.0;
  late Timer _warmT;
  final int _warmSec = 6;
  bool _cover = true;
  bool _loadedSent = false;
  int? _firstLoadTs;
  GridCourier? _runner;
  GridViewModel? _vm;
  String _currUrl = "";
  var _startStamp = 0;

  final Set<String> _proto = {
    'tg',
    'telegram',
    'whatsapp',
    'viber',
    'skype',
    'fb-messenger',
    'sgnl',
    'tel',
    'mailto',
    'bnl',
  };

  final Set<String> _dwell = {
    't.me',
    'telegram.me',
    'telegram.dog',
    'wa.me',
    'api.whatsapp.com',
    'chat.whatsapp.com',
    'm.me',
    'signal.me',
    'bnl.com',
    'www.bnl.com',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _firstLoadTs = DateTime.now().millisecondsSinceEpoch;
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _cover = false);
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() {
        _scrim = true;
      });
    });
    _boot();
  }

  Future<void> _pullLoadedFlag() async {
    final sp = await SharedPreferences.getInstance();
    _loadedSent = sp.getBool(_kPitLoadedEventLatch) ?? false;
  }

  Future<void> _putLoadedFlag() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kPitLoadedEventLatch, true);
    _loadedSent = true;
  }

  Future<void> postLoadedOnce({required String url, required int timestart}) async {
    if (_loadedSent) {
      return;
    }
    try {
      context.read<GridBloc>().add(GridSendLoadedOnce(
        url: url,
        timeStart: timestart,
        appSid: _boss.gridId,
        firstPageLoadTs: _firstLoadTs,
      ));
      await _putLoadedFlag();
    } catch (e) {
      pitLogger.e("postLoadedOnce via Bloc error: $e");
    }
  }

  void _boot() {
    _igniteWarm();
    _armFcm();
    _boss.summon(() => setState(() {}));
    _bindCrowBell();
    _prepRig();
    Future.delayed(const Duration(milliseconds: 500), () async {
      try {
        context.read<GridBloc>().add(GridInitRequested(fcmToken: widget.pulse));
      } catch (e) {
        pitLogger.w("Bloc init not available: $e");
      }
    });
    Future.delayed(const Duration(seconds: 6), () async {
      await _shipRig();
      await _shipBoss();
    });
  }

  void _armFcm() {
    FirebaseMessaging.onMessage.listen((msg) {
      final link = msg.data['uri'];
      if (link != null) {
        _hop(link.toString());
      } else {
        _spinUp();
      }
    });
    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      final link = msg.data['uri'];
      if (link != null) {
        _hop(link.toString());
      } else {
        _spinUp();
      }
    });
  }
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

  Future<void> _prepRig() async {
    try {
      await _rig.assemble();
      await _askPerm();
      _vm = GridViewModel(dossier: _rig, consigliere: _boss);
      // webGetter позже станет доступен после onWebViewCreated
      await _pullLoadedFlag();
    } catch (e) {
      pitLogger.e("prep-gear-fail: $e");
    }
  }

  Future<void> _askPerm() async {
    FirebaseMessaging steam = FirebaseMessaging.instance;
    await steam.requestPermission(alert: true, badge: true, sound: true);
  }

  void _hop(String link) async {
    if (mounted && _dock != null) {
      await _dock.loadUrl(urlRequest: URLRequest(url: WebUri(link)));
    }
  }

  void _spinUp() async {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _dock != null) {
        _dock.loadUrl(urlRequest: URLRequest(url: WebUri(_gridAxis)));
      }
    });
  }

  Future<void> _shipRig() async {
    pitLogger.i("TOKEN ship ${widget.pulse}");
    if (!mounted) return;
    setState(() => _spinner = true);
    try {
      await _runner?.pushDeviceLocalStorage(widget.pulse);
    } finally {
      if (mounted) setState(() => _spinner = false);
    }
  }

  Future<void> _shipBoss() async {
    await _runner?.pushAfSendRaw(widget.pulse);
  }

  void _igniteWarm() {
    int ticks = 0;
    _warmMeter = 0.0;
    _warmT = Timer.periodic(const Duration(milliseconds: 100), (t) {
      if (!mounted) return;
      setState(() {
        ticks++;
        _warmMeter = ticks / (_warmSec * 10);
        if (_warmMeter >= 1.0) {
          _warmMeter = 1.0;
          _warmT.cancel();
        }
      });
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.paused) {
      _napAt = DateTime.now();
    }
    if (s == AppLifecycleState.resumed) {
      if (Platform.isIOS && _napAt != null) {
        final now = DateTime.now();
        final dur = now.difference(_napAt!);
        if (dur > const Duration(minutes: 25)) {
          _regrid();
        }
      }
      _napAt = null;
    }
  }

  void _regrid() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => GridHarbor(pulse: widget.pulse),
        ),
            (route) => false,
      );
    });
  }

  Future<void> _forceLandscape() async {
    await SystemChrome.setPreferredOrientations(
      [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight],
    );
  }

  Future<void> _forcePortrait() async {
    await SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown],
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _warmT.cancel();
    super.dispose();
  }

  bool _isBareMail(Uri u) {
    final s = u.scheme;
    if (s.isNotEmpty) return false;
    final raw = u.toString();
    return raw.contains('@') && !raw.contains(' ');
  }

  Uri _mailize(Uri u) {
    final full = u.toString();
    final parts = full.split('?');
    final email = parts.first;
    final qp =
    parts.length > 1 ? Uri.splitQueryString(parts[1]) : <String, String>{};
    return Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: qp.isEmpty ? null : qp,
    );
  }

  bool _isPlatformish(Uri u) {
    final s = u.scheme.toLowerCase();
    if (_proto.contains(s)) return true;
    if (s == 'http' || s == 'https') {
      final h = u.host.toLowerCase();
      if (_dwell.contains(h)) return true;
      if (h.endsWith('t.me')) return true;
      if (h.endsWith('wa.me')) return true;
      if (h.endsWith('m.me')) return true;
      if (h.endsWith('signal.me')) return true;
    }
    return false;
  }

  Uri _httpize(Uri u) {
    final s = u.scheme.toLowerCase();
    if (s == 'tg' || s == 'telegram') {
      final qp = u.queryParameters;
      final domain = qp['domain'];
      if (domain != null && domain.isNotEmpty) {
        return Uri.https('t.me', '/$domain', {
          if (qp['start'] != null) 'start': qp['start']!,
        });
      }
      final path = u.path.isNotEmpty ? u.path : '';
      return Uri.https(
          't.me', '/$path', u.queryParameters.isEmpty ? null : u.queryParameters);
    }
    if ((s == 'http' || s == 'https') && u.host.toLowerCase().endsWith('t.me')) {
      return u;
    }
    if (s == 'viber') {
      return u;
    }
    if (s == 'whatsapp') {
      final qp = u.queryParameters;
      final phone = qp['phone'];
      final text = qp['text'];
      if (phone != null && phone.isNotEmpty) {
        return Uri.https('wa.me', '/${_digits(phone)}',
            {if (text != null && text.isNotEmpty) 'text': text});
      }
      return Uri.https('wa.me', '/', {if (text != null && text.isNotEmpty) 'text': text});
    }
    if ((s == 'http' || s == 'https') &&
        (u.host.toLowerCase().endsWith('wa.me') ||
            u.host.toLowerCase().endsWith('whatsapp.com'))) {
      return u;
    }
    if (s == 'skype') {
      return u;
    }
    if (s == 'fb-messenger') {
      final path =
      u.pathSegments.isNotEmpty ? u.pathSegments.join('/') : '';
      final id = u.queryParameters['id'] ??
          u.queryParameters['user'] ??
          path;
      if (id.isNotEmpty) {
        return Uri.https(
            'm.me', '/$id', u.queryParameters.isEmpty ? null : u.queryParameters);
      }
      return Uri.https(
          'm.me', '/', u.queryParameters.isEmpty ? null : u.queryParameters);
    }
    if (s == 'sgnl') {
      final ph = u.queryParameters['phone'];
      final un = u.queryParameters['username'];
      if (ph != null && ph.isNotEmpty) {
        return Uri.https('signal.me', '/#p/${_digits(ph)}');
      }
      if (un != null && un.isNotEmpty) {
        return Uri.https('signal.me', '/#u/$un');
      }
      final path = u.pathSegments.join('/');
      if (path.isNotEmpty) {
        return Uri.https(
            'signal.me', '/$path', u.queryParameters.isEmpty ? null : u.queryParameters);
      }
      return u;
    }
    if (s == 'tel') {
      return Uri.parse('tel:${_digits(u.path)}');
    }
    if (s == 'mailto') {
      return u;
    }
    if (s == 'bnl') {
      final newPath = u.path.isNotEmpty ? u.path : '';
      return Uri.https('bnl.com', '/$newPath',
          u.queryParameters.isEmpty ? null : u.queryParameters);
    }
    return u;
  }

  Future<bool> _webMail(Uri mailto) async {
    final u = _gmailize(mailto);
    return await _webOpen(u);
  }

  Uri _gmailize(Uri m) {
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

  Future<bool> _webOpen(Uri u) async {
    try {
      if (await launchUrl(u, mode: LaunchMode.inAppBrowserView)) return true;
      return await launchUrl(u, mode: LaunchMode.externalApplication);
    } catch (e) {
      try {
        return await launchUrl(u, mode: LaunchMode.externalApplication);
      } catch (_) {
        return false;
      }
    }
  }

  String _digits(String s) => s.replaceAll(RegExp(r'[^0-9+]'), '');

  @override
  Widget build(BuildContext context) {
    _bindCrowBell();
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            if (_cover)
              const PitPulseLoader()
            else
              Container(
                color: Colors.black,
                child: Stack(
                  children: [
                    InAppWebView(
                      key: ValueKey(_rev),
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
                        transparentBackground: true,
                      ),
                      initialUrlRequest: URLRequest(url: WebUri(_gridAxis)),
                      onWebViewCreated: (c) {
                        _dock = c;
                        _vm ??= GridViewModel(dossier: _rig, consigliere: _boss);
                        _runner ??=
                            GridCourier(pitModel: _vm!, webGetter: () => _dock);
                        _dock.addJavaScriptHandler(
                          handlerName: 'onServerResponse',
                          callback: (args) async {
                            try {
                              bool isLandscape =
                                  args.isNotEmpty &&
                                      args[0] is Map &&
                                      (args[0]['savedata']?.toString() ?? '') ==
                                          "true";
                              if (    (args[0]['savedata']?.toString() ?? '') ==
                                  "false") {
                                await _forceLandscape();
                              }
                            } catch (_) {}
                            if (args.isEmpty) return null;
                            try {
                              return args.reduce((curr, next) => curr + next);
                            } catch (_) {
                              return args.first;
                            }
                          },
                        );
                      },
                      onLoadStart: (c, u) async {
                        setState(() {
                          _startStamp =
                              DateTime.now().millisecondsSinceEpoch;
                        });
                        setState(() => _spinner = true);
                        final v = u;
                        if (v != null) {
                          if (_isBareMail(v)) {
                            try {
                              await c.stopLoading();
                            } catch (_) {}
                            final mailto = _mailize(v);
                            await _webMail(mailto);
                            return;
                          }
                          final sch = v.scheme.toLowerCase();
                          if (sch != 'http' && sch != 'https') {
                            try {
                              await c.stopLoading();
                            } catch (_) {}
                          }
                        }
                      },
                      onLoadError: (controller, url, code, message) async {
                        final now = DateTime.now().millisecondsSinceEpoch;
                        final ev =
                            "InAppWebViewError(code=$code, message=$message)";
                        await gridPostStat(
                          event: ev,
                          timeStart: now,
                          timeFinish: now,
                          url: url?.toString() ?? '',
                          appSid: _boss.gridId,
                          firstPageLoadTs: _firstLoadTs,
                        );
                        if (mounted) setState(() => _spinner = false);
                      },
                      onReceivedHttpError:
                          (controller, request, errorResponse) async {
                        final now = DateTime.now().millisecondsSinceEpoch;
                        final ev =
                            "HTTPError(status=${errorResponse.statusCode}, reason=${errorResponse.reasonPhrase})";
                        await gridPostStat(
                          event: ev,
                          timeStart: now,
                          timeFinish: now,
                          url: request.url?.toString() ?? '',
                          appSid: _boss.gridId,
                          firstPageLoadTs: _firstLoadTs,
                        );
                      },
                      onReceivedError:
                          (controller, request, error) async {
                        final now = DateTime.now().millisecondsSinceEpoch;
                        final desc = (error.description ?? '').toString();
                        final ev =
                            "WebResourceError(code=${error}, message=$desc)";
                        await gridPostStat(
                          event: ev,
                          timeStart: now,
                          timeFinish: now,
                          url: request.url?.toString() ?? '',
                          appSid: _boss.gridId,
                          firstPageLoadTs: _firstLoadTs,
                        );
                      },
                      onLoadStop: (c, u) async {
                        await c.evaluateJavascript(
                            source: "console.log('Harbor up!');");
                        await _shipRig();
                        await _shipBoss();
                        setState(() {
                          _currUrl = u.toString();
                        });
                        Future.delayed(const Duration(seconds: 20), () {
                          postLoadedOnce(
                            url: _currUrl.toString(),
                            timestart: _startStamp,
                          );
                        });
                        if (mounted) setState(() => _spinner = false);
                      },
                      shouldOverrideUrlLoading: (c, action) async {
                        final uri = action.request.url;
                        if (uri == null) {
                          return NavigationActionPolicy.ALLOW;
                        }
                        if (_isBareMail(uri)) {
                          final mailto = _mailize(uri);
                          await _webMail(mailto);
                          return NavigationActionPolicy.CANCEL;
                        }
                        final sch = uri.scheme.toLowerCase();
                        if (sch == 'mailto') {
                          await _webMail(uri);
                          return NavigationActionPolicy.CANCEL;
                        }
                        if (sch == 'tel') {
                          await launchUrl(uri,
                              mode: LaunchMode.externalApplication);
                          return NavigationActionPolicy.CANCEL;
                        }
                        if (_isPlatformish(uri)) {
                          final web = _httpize(uri);
                          if (web.scheme == 'http' || web.scheme == 'https') {
                            await _webOpen(web);
                          } else {
                            try {
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri,
                                    mode: LaunchMode.externalApplication);
                              } else if (web != uri &&
                                  (web.scheme == 'http' ||
                                      web.scheme == 'https')) {
                                await _webOpen(web);
                              }
                            } catch (_) {}
                          }
                          return NavigationActionPolicy.CANCEL;
                        }
                        if (sch != 'http' && sch != 'https') {
                          return NavigationActionPolicy.CANCEL;
                        }
                        return NavigationActionPolicy.ALLOW;
                      },
                      onCreateWindow: (c, req) async {
                        final uri = req.request.url;
                        if (uri == null) return false;
                        if (_isBareMail(uri)) {
                          final mailto = _mailize(uri);
                          await _webMail(mailto);
                          return false;
                        }
                        final sch = uri.scheme.toLowerCase();
                        if (sch == 'mailto') {
                          await _webMail(uri);
                          return false;
                        }
                        if (sch == 'tel') {
                          await launchUrl(uri,
                              mode: LaunchMode.externalApplication);
                          return false;
                        }
                        if (_isPlatformish(uri)) {
                          final web = _httpize(uri);
                          if (web.scheme == 'http' || web.scheme == 'https') {
                            await _webOpen(web);
                          } else {
                            try {
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri,
                                    mode: LaunchMode.externalApplication);
                              } else if (web != uri &&
                                  (web.scheme == 'http' ||
                                      web.scheme == 'https')) {
                                await _webOpen(web);
                              }
                            } catch (_) {}
                          }
                          return false;
                        }
                        if (sch == 'http' || sch == 'https') {
                          c.loadUrl(urlRequest: URLRequest(url: uri));
                        }
                        return false;
                      },
                      onDownloadStartRequest: (c, req) async {
                        await _webOpen(req.url);
                      },
                    ),
                    Visibility(
                      visible: !_scrim,
                      child: const PitPulseLoader(),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class GridHelp extends StatefulWidget {
  const GridHelp({super.key});

  @override
  State<GridHelp> createState() => _GridHelpState();
}

class _GridHelpState extends State<GridHelp> with WidgetsBindingObserver {
  InAppWebViewController? _nav;
  bool _spin = true;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            InAppWebView(
              initialFile: 'assets/index.html',
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                supportZoom: false,
                disableHorizontalScroll: false,
                disableVerticalScroll: false,
              ),
              onWebViewCreated: (c) => _nav = c,
              onLoadStart: (c, u) => setState(() => _spin = true),
              onLoadStop: (c, u) async => setState(() => _spin = false),
              onLoadError: (c, u, code, msg) => setState(() => _spin = false),
            ),
            if (_spin) const PitPulseLoader(),
          ],
        ),
      ),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(pitBgFcm);
  if (Platform.isAndroid) {
    await InAppWebViewController.setWebContentsDebuggingEnabled(true);
  }
  // По умолчанию пусть будет портрет — далее переключаем динамически
  await SystemChrome.setPreferredOrientations(
    [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown],
  );
  tz_data.initializeTimeZones();
  final dossier = GridDossier();
  final consigliere = TurboConsigliere();
  runApp(
    p.MultiProvider(
      providers: [
        turboConsigliereProvider,
      ],
      child: r.ProviderScope(
        child: MultiBlocProvider(
          providers: [
            BlocProvider<GridBloc>(
              create: (_) => GridBloc(
                dossier: dossier,
                consigliere: consigliere,
                postStat: ({
                  required String event,
                  required int timeStart,
                  required int timeFinish,
                  required String url,
                  required String appSid,
                  int? firstPageLoadTs,
                }) async {
                  await gridPostStat(
                    event: event,
                    timeStart: timeStart,
                    timeFinish: timeFinish,
                    url: url,
                    appSid: appSid,
                    firstPageLoadTs: firstPageLoadTs,
                  );
                },
              ),
            ),
          ],
          child: const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: GridVestibule(),
          ),
        ),
      ),
    ),
  );
}