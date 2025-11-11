import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shopping_list_app/data/in_memory_data.dart';
import 'package:shopping_list_app/models/family.dart';
import 'package:shopping_list_app/models/user.dart';
import 'package:shopping_list_app/ui/order/create_order_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CreateOrderScreen', () {
    setUp(() {
      final data = InMemoryData.instance;
      data.users.clear();
      data.families.clear();
      data.orders.clear();
      final user = User(firstName: 'A', lastName: 'B', email: 'a@b.c', password: 'pw');
      data.users.add(user);
      data.currentUser = user;
      final fam = Family(name: 'Test Fam', membersList: [user.id], ordersList: []);
      data.families.add(fam);
    });

    testWidgets('fails validation with empty name', (tester) async {
      final data = InMemoryData.instance;
      final fam = data.families.first;
      await tester.pumpWidget(MaterialApp(
        home: CreateOrderScreen(familyId: fam.id, placingUserId: data.currentUser!.id),
      ));

      // Try submit immediately
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      expect(find.text('Name is required'), findsOneWidget);

      // Fill valid name
      await tester.enterText(find.byType(TextFormField).first, 'Milk');
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      // Should pop
      expect(find.text('Create order'), findsNothing);
    });

    testWidgets('creates order with all fields', (tester) async {
      final data = InMemoryData.instance;
      final fam = data.families.first;
      await tester.pumpWidget(MaterialApp(
        home: CreateOrderScreen(familyId: fam.id, placingUserId: data.currentUser!.id),
      ));

      await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'Bread');
      await tester.enterText(find.widgetWithText(TextFormField, 'Description'), 'Whole grain');
      await tester.enterText(find.widgetWithText(TextFormField, 'Quantity'), '3');
      await tester.enterText(find.widgetWithText(TextFormField, 'Allocated sum'), '10.5');

      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      expect(data.orders.any((o) => o.name == 'Bread' && o.quantity == 3 && o.allocatedSum == 10.5), isTrue);
    });
  });
}
