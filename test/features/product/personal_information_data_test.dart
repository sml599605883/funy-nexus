import 'package:flutter_test/flutter_test.dart';
import 'package:fund_nexus/features/product/data/personal_information_data.dart';

void main() {
  test('parses server controls, labels, and submit values', () {
    final data = PersonalInformationData.fromJson({
      'cornbraids': 'Complete your personal information.',
      'orographical': [
        {
          'culinarians': 'Education',
          'must': 'Please select education',
          'fasciitis': 'education',
          'presentableness': 'enum',
          'bobberies': 0,
          'rubicund': [
            {'emit': 'College', 'etherifying': 2},
            {'emit': 'Postgraduate', 'etherifying': 3},
          ],
          'lambadas': 0,
          'steeplechases': 'College',
        },
        {
          'culinarians': 'Email',
          'must': 'Please input email',
          'fasciitis': 'offer',
          'presentableness': 'txt',
          'bobberies': 0,
          'rubicund': const [],
          'lambadas': 1,
          'steeplechases': 'user@example.com',
        },
        {
          'culinarians': 'Residential Address',
          'must': 'Please select address',
          'fasciitis': 'residential_address',
          'presentableness': 'stage',
          'bobberies': 0,
          'rubicund': const [],
          'lambadas': 0,
          'steeplechases': '',
        },
      ],
    });

    expect(data.prompt, 'Complete your personal information.');
    expect(data.fields, hasLength(3));
    expect(data.fields[0].control, PersonalInformationControl.selection);
    expect(data.fields[0].initialDisplayValue, 'College');
    expect(data.fields[0].initialSubmitValue, '2');
    expect(data.fields[1].control, PersonalInformationControl.text);
    expect(data.fields[1].isRequired, isFalse);
    expect(data.fields[2].control, PersonalInformationControl.address);
  });

  test('parses the documented address hierarchy', () {
    final nodes = PersonalAddressNode.parseList({
      'semihobos': [
        {
          'fasciitis': '1',
          'emit': 'Region',
          'bedtimes': [
            {
              'fasciitis': '1-1',
              'emit': 'Province',
              'bedtimes': [
                {'fasciitis': '1-1-1', 'emit': 'City', 'bedtimes': const []},
              ],
            },
          ],
        },
      ],
    });

    expect(nodes.single.children.single.children.single.label, 'City');
  });

  test('parses a nested work payday option', () {
    final data = PersonalInformationData.fromJson({
      'foresight': {
        'orographical': [
          {
            'culinarians': 'Payday',
            'must': 'Please select payday',
            'fasciitis': 'opportunities',
            'presentableness': 'stepped',
            'bobberies': 0,
            'rubicund': [
              {
                'emit': 'Once a Month',
                'etherifying': 4,
                'rubicund': [
                  {'emit': 1, 'etherifying': 11},
                ],
              },
            ],
            'lambadas': 0,
            'steeplechases': 'Once a Month|1',
          },
        ],
      },
    });

    final payday = data.fields.single;
    expect(payday.options.single.children.single.label, '1');
    expect(payday.options.single.children.single.value, '11');
  });

  test('parses the current address initialization response hierarchy', () {
    final nodes = PersonalAddressNode.parseList({
      'foresight': {
        'semihobos': [
          {
            'ecclesia': 1,
            'emit': 'NCR',
            'semihobos': [
              {
                'ecclesia': 1,
                'emit': 'Metro Manila',
                'semihobos': [
                  {'ecclesia': 1350, 'emit': 'Manila'},
                ],
              },
            ],
          },
        ],
      },
    });

    expect(nodes.single.id, '1');
    expect(nodes.single.children.single.label, 'Metro Manila');
    expect(nodes.single.children.single.children.single.id, '1350');
    expect(nodes.single.children.single.children.single.label, 'Manila');
  });
}
