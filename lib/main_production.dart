import 'package:gearguard/app/app.dart';
import 'package:gearguard/bootstrap.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  await bootstrap(() async {
    final prefs = await SharedPreferences.getInstance();
    return App(prefs: prefs);
  });
}
