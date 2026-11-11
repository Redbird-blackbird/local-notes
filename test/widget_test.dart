import 'package:flutter_test/flutter_test.dart';
import 'package:local_notes/main.dart';
import 'package:local_notes/services/vault_service.dart';

void main() {
  testWidgets('LocalNotesApp loads successfully with curated vault', (WidgetTester tester) async {
    final vaultService = VaultService();
    await vaultService.initialize();

    await tester.pumpWidget(LocalNotesApp(vaultService: vaultService));
    await tester.pumpAndSettle();

    // Verify app title or welcome note exists
    expect(find.text('Local Notes'), findsWidgets);
    expect(find.text('Welcome to Local Notes'), findsWidgets);
  });
}
