Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await bootstrap();

  runApp(const GameHelperApp());
}