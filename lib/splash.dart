import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:omiku/widgets/appUI/app_center_frame.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    debugPrint("Splash screen initialized");
  //  FlutterTelegramAuth.init(
    //  clientId: '8903710651',
    //  redirectUri:
      //    'https://app3836040070-login.tg.dev/tglogin', // From BotFather
    //  scopes: ["profile", "phone"],
   // );
    _navigateToHome();
  }


  Future<void> _navigateToHome() async {
    debugPrint("Waiting for 5 seconds before navigation...");
    await Future.delayed(const Duration(seconds: 5));

   // final idTok = await store.record('idToken').get(db) as String;
   // final user = FlutterTelegramAuth.getLocalUserFromToken(idTok);
    if (!mounted) return;

    debugPrint("Navigating to DataLoadingScreen...");
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) {
          // if ( idTok == "") {
          //   return TelegramLoginPage(tok: "");
          // } else if (user == null) {
          //   return TelegramLoginPage(tok: "");
          // } else {
            return CenterContentPanel(isMobileLayout: true,);
         // }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Lottie.asset("assets/lottie/splash.json")),
    );
  }

}
