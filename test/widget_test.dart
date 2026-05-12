import 'package:flutter_test/flutter_test.dart';
import 'package:rs_monitoring_app/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MemoryAsyncStorage extends GotrueAsyncStorage {
  final Map<String, String> _data = {};

  @override
  Future<String?> getItem({required String key}) async => _data[key];

  @override
  Future<void> setItem({required String key, required String value}) async {
    _data[key] = value;
  }

  @override
  Future<void> removeItem({required String key}) async {
    _data.remove(key);
  }
}

void main() {
  setUpAll(() async {
    await Supabase.initialize(
      url: 'https://adexqoztgljywbsedsth.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFkZXhxb3p0Z2xqeXdic2Vkc3RoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg0ODk1NjQsImV4cCI6MjA5NDA2NTU2NH0.e7cr3vGf9QmrjgmwYsdobYrRTwYk4Pp1aM9u26NTPRk',
      authOptions: FlutterAuthClientOptions(
        localStorage: const EmptyLocalStorage(),
        pkceAsyncStorage: _MemoryAsyncStorage(),
        detectSessionInUri: false,
      ),
    );
  });

  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const NeuroLifeApp());
    expect(find.text('NeuroLife'), findsOneWidget);
  });
}
