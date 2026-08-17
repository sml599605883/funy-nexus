import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fund_nexus/app/layout/app_responsive.dart';
import 'package:fund_nexus/core/session/session_store.dart';
import 'package:fund_nexus/features/product/certification/widgets/personal_information_address_sheet.dart';
import 'package:fund_nexus/features/product/certification/personal_information_page.dart';
import 'package:fund_nexus/features/product/data/personal_information_data.dart';
import 'package:fund_nexus/features/product/data/product_repository.dart';

void main() {
  testWidgets('renders fields and values returned by the personal-info API', (
    tester,
  ) async {
    await tester.pumpWidget(_page());
    await tester.pumpAndSettle();

    expect(find.text('Basic identity information'), findsOneWidget);
    expect(find.text('Gender'), findsOneWidget);
    expect(find.text('Education'), findsOneWidget);
    expect(find.text('Marriage Status'), findsOneWidget);
    expect(find.text('Type of Residence'), findsOneWidget);
    expect(find.text('Home Phone Number'), findsOneWidget);
    expect(find.text('Address Input'), findsOneWidget);
    expect(find.text('Complete Address'), findsOneWidget);
    expect(find.text('Reason for Loan'), findsOneWidget);
    expect(find.text('female'), findsOneWidget);
    expect(find.text('College'), findsOneWidget);
    expect(find.text('Upload'), findsOneWidget);
  });

  testWidgets('updates a server option from the choice panel', (tester) async {
    await tester.pumpWidget(_page());
    await tester.pumpAndSettle();

    final education = find.byKey(const Key('personalInformation-education'));
    await tester.ensureVisible(education);
    await tester.tap(education);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Postgraduate'));
    await tester.pumpAndSettle();

    expect(find.text('Postgraduate'), findsOneWidget);
  });

  testWidgets('dismisses the keyboard when tapping the page blank area', (
    tester,
  ) async {
    await tester.pumpWidget(_page());
    await tester.pumpAndSettle();

    final phone = find.byKey(const Key('personalInformationInput-home_phone'));
    await tester.ensureVisible(phone);
    await tester.tap(phone);
    await tester.pump();
    expect(_hasFocusedTextField(tester), isTrue);

    final dismissArea = tester.getRect(
      find.byKey(const Key('personalInformationDismissKeyboard')),
    );
    await tester.tapAt(dismissArea.topLeft + const Offset(2, 2));
    await tester.pump();

    expect(_hasFocusedTextField(tester), isFalse);
  });

  testWidgets(
    'cancelling a choice panel keeps input content and focus cleared',
    (tester) async {
      await tester.pumpWidget(_page());
      await tester.pumpAndSettle();

      final address = find.byKey(
        const Key('personalInformationInput-complete_address'),
      );
      await tester.ensureVisible(address);
      await tester.tap(address);
      await tester.enterText(address, 'Keep this value');
      await tester.pump();

      final education = find.byKey(const Key('personalInformation-education'));
      await tester.ensureVisible(education);
      await tester.tap(education);
      await tester.pumpAndSettle();
      expect(_hasFocusedTextField(tester), isFalse);
      expect(
        find.byKey(const Key('certificationSingleSelectDialog')),
        findsOneWidget,
      );

      await tester.tapAt(const Offset(1, 1));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('certificationSingleSelectDialog')),
        findsNothing,
      );
      expect(find.text('Keep this value'), findsOneWidget);
      expect(_hasFocusedTextField(tester), isFalse);
    },
  );

  testWidgets('uses the cached guidance before the API prompt', (tester) async {
    await tester.pumpWidget(_page(guidance: 'Use the cached guidance.'));
    await tester.pumpAndSettle();

    expect(find.text('Use the cached guidance.'), findsOneWidget);
    expect(find.text('Use the API prompt.'), findsNothing);
    expect(
      tester
          .getSize(find.byKey(const Key('personalInformationGuidance')))
          .height,
      closeTo(800 * 57 / 375, 0.01),
    );
  });

  testWidgets('uses the API prompt when no cached guidance exists', (
    tester,
  ) async {
    await tester.pumpWidget(_page());
    await tester.pumpAndSettle();

    expect(find.text('Use the API prompt.'), findsOneWidget);
  });

  testWidgets('overlaps the form card with the centered progress panel', (
    tester,
  ) async {
    await tester.pumpWidget(_page());
    await tester.pumpAndSettle();

    final progress = tester.getRect(
      find.byKey(const Key('personalInformationProgress')),
    );
    final formCard = tester.getRect(
      find.byKey(const Key('personalInformationFormCard')),
    );
    final scale = 800 / 375;

    expect(progress.left, closeTo(16 * scale, 0.01));
    expect(formCard.left, closeTo(16 * scale, 0.01));
    expect(formCard.top, closeTo(progress.bottom - 27 * scale, 0.01));
  });

  testWidgets('preloads address options and reuses them when the field opens', (
    tester,
  ) async {
    final gateway = _PersonalInformationGateway(addressNodes: _addressNodes);
    await tester.pumpWidget(_page(gateway: gateway));
    await tester.pumpAndSettle();

    expect(gateway.addressLoadCount, 1);
    final address = find.byKey(
      const Key('personalInformation-residential_address'),
    );
    await tester.ensureVisible(address);
    await tester.tap(address);
    await tester.pumpAndSettle();

    expect(gateway.addressLoadCount, 1);
    expect(
      find.byKey(const Key('personalInformationAddressSelectionSheet')),
      findsOneWidget,
    );
  });

  testWidgets('selects all address levels and closes after the municipality', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    String? selected;

    await tester.pumpWidget(
      MaterialApp(
        home: ResponsiveScope(
          child: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                selected = await showPersonalInformationAddressOptionsSheet(
                  context: context,
                  nodes: _addressNodes,
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(
      tester.getSize(
        find.byKey(const Key('personalInformationAddressSelectionSheet')),
      ),
      const Size(375, 464),
    );
    await tester.tap(find.text('NCR').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Metro Manila').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Manila').last);
    await tester.pumpAndSettle();

    expect(selected, 'NCR-Metro Manila-Manila');
    expect(
      find.byKey(const Key('personalInformationAddressSelectionSheet')),
      findsNothing,
    );
  });
}

bool _hasFocusedTextField(WidgetTester tester) => tester
    .widgetList<EditableText>(find.byType(EditableText))
    .any((field) => field.focusNode.hasFocus);

Widget _page({String guidance = '', PersonalInformationGateway? gateway}) {
  final sessionStore = SessionStore(_TestSessionPersistence())
    ..cacheProductDetailIdentityGuidance(guidance);
  return MaterialApp(
    home: MultiRepositoryProvider(
      providers: [
        RepositoryProvider<SessionStore>.value(value: sessionStore),
        RepositoryProvider<PersonalInformationGateway>.value(
          value: gateway ?? _PersonalInformationGateway(),
        ),
      ],
      child: const ResponsiveScope(
        child: PersonalInformationPage(productId: 'product'),
      ),
    ),
  );
}

class _PersonalInformationGateway implements PersonalInformationGateway {
  _PersonalInformationGateway({
    this.addressNodes = const <PersonalAddressNode>[],
  });

  final List<PersonalAddressNode> addressNodes;
  int addressLoadCount = 0;

  @override
  Future<PersonalInformationData> fetchPersonalInformation(
    String productId,
  ) async {
    return PersonalInformationData.fromJson({
      'cornbraids': 'Use the API prompt.',
      'orographical': [
        _field(
          title: 'Gender',
          saveKey: 'gender',
          type: 'enum',
          value: 'female',
          options: [
            {'emit': 'female', 'etherifying': 1},
            {'emit': 'male', 'etherifying': 2},
          ],
        ),
        _field(
          title: 'Education',
          saveKey: 'education',
          type: 'enum',
          value: 'College',
          options: [
            {'emit': 'High school', 'etherifying': 1},
            {'emit': 'College', 'etherifying': 2},
            {'emit': 'Postgraduate', 'etherifying': 3},
          ],
        ),
        _field(
          title: 'Marriage Status',
          saveKey: 'marriage',
          type: 'enum',
          value: 'Single',
          options: [
            {'emit': 'Single', 'etherifying': 1},
            {'emit': 'Married', 'etherifying': 2},
          ],
        ),
        _field(
          title: 'Type of Residence',
          saveKey: 'residence',
          type: 'enum',
          value: 'Owned',
          options: [
            {'emit': 'Owned', 'etherifying': 1},
            {'emit': 'Rented', 'etherifying': 2},
          ],
        ),
        _field(
          title: 'Home Phone Number',
          saveKey: 'home_phone',
          type: 'txt',
          value: '',
          placeholder: 'Please enter',
          numeric: 1,
        ),
        _field(
          title: 'Address Input',
          saveKey: 'residential_address',
          type: 'citySelect',
          value: '',
        ),
        _field(
          title: 'Complete Address',
          saveKey: 'complete_address',
          type: 'txt',
          value: '',
          placeholder: 'Please enter',
        ),
        _field(
          title: 'Reason for Loan',
          saveKey: 'use_of_funds',
          type: 'enum',
          value: '',
          options: [
            {'emit': 'Medical', 'etherifying': 1},
            {'emit': 'Education', 'etherifying': 2},
          ],
        ),
      ],
    });
  }

  @override
  Future<List<PersonalAddressNode>> fetchPersonalInformationAddresses() async {
    addressLoadCount++;
    return addressNodes;
  }

  @override
  Future<void> savePersonalInformation({
    required String productId,
    required Map<String, String> fields,
  }) async {}
}

const _addressNodes = [
  PersonalAddressNode(
    id: '1',
    label: 'NCR',
    children: [
      PersonalAddressNode(
        id: '2',
        label: 'Metro Manila',
        children: [PersonalAddressNode(id: '3', label: 'Manila', children: [])],
      ),
    ],
  ),
];

Map<String, Object> _field({
  required String title,
  required String saveKey,
  required String type,
  required String value,
  List<Map<String, Object>> options = const [],
  String placeholder = 'Please select',
  int numeric = 0,
}) {
  return {
    'culinarians': title,
    'must': placeholder,
    'fasciitis': saveKey,
    'presentableness': type,
    'bobberies': numeric,
    'rubicund': options,
    'lambadas': 0,
    'steeplechases': value,
  };
}

class _TestSessionPersistence implements SessionPersistence {
  @override
  Future<String?> readPhone() async => null;

  @override
  Future<String?> readSessionId() async => null;

  @override
  Future<void> writePhone(String? phone) async {}

  @override
  Future<void> writeSessionId(String? sessionId) async {}
}
