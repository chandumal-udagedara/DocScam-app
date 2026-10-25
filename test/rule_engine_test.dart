import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:doc_scam_mobile_app/checker/rule_engine.dart';
import 'package:doc_scam_mobile_app/checker/normaliser.dart';

void main() {
  late RuleEngine engine;

  setUpAll(() {
    final json = jsonDecode(
        File('assets/content/scam-patterns.json').readAsStringSync());
    engine = RuleEngine(ScamPatternPack.fromJson(json as Map<String, dynamic>));
  });

  group('normalisation', () {
    test('folds homoglyphs used to evade keyword matching', () {
      // Cyrillic а and о
      expect(normalise('Аustralia Pоst'), 'Australia Post');
    });

    test('strips zero-width characters', () {
      expect(normalise('gift​card'), 'giftcard');
    });

    test('collapses whitespace', () {
      expect(normalise('  pay   now \n today '), 'pay now today');
    });
  });

  group('host extraction', () {
    test('strips www and lowercases', () {
      expect(extractHosts('go to https://WWW.Auspost.com.au/track'),
          ['auspost.com.au']);
    });

    test('subdomain of an allowed domain is allowed', () {
      expect(hostMatchesAny('track.auspost.com.au', ['auspost.com.au']), isTrue);
    });

    test('lookalike domain is not allowed', () {
      expect(hostMatchesAny('auspost-redelivery.icu', ['auspost.com.au']),
          isFalse);
    });
  });

  group('corroboration gate', () {
    test('a real bank alert naming the bank does not flag', () {
      final r = engine.check(
          'CommBank: A payment of \$84.50 to WOOLWORTHS was made on your card '
          'ending 8821. If this wasn\'t you, call us on the number on the back '
          'of your card.');
      expect(r.signalCount, 0,
          reason: 'naming a bank is not itself suspicious');
    });

    test('a real myGov notification does not flag', () {
      final r = engine.check(
          'myGov: You have a new message in your myGov Inbox. '
          'Sign in at my.gov.au to read it.');
      expect(r.signalCount, 0);
    });

    test('impersonation plus urgency plus bad link does flag', () {
      final r = engine.check(
          'myGov: Your account has been locked. Verify immediately: '
          'http://mygov-secure.icu/verify');
      expect(r.flags.map((f) => f.rule.id), contains('impersonation.gov'));
      expect(r.signalCount, greaterThan(1));
    });
  });

  group('family impersonation needs two markers', () {
    test('a genuine text from your kid does not flag', () {
      final r = engine.check('Hi Mum, running late, be there about 7.');
      expect(r.signalCount, 0);
    });

    test('hi-mum scam with new number and lost phone flags', () {
      final r = engine.check(
          'Hi Mum, I dropped my phone and this is my new number. '
          'Can you help with a bill?');
      expect(r.flags.map((f) => f.rule.id), contains('family.impersonation'));
    });
  });

  group('contract', () {
    test('result never exposes a verdict', () {
      final r = engine.check('anything at all');
      // If someone adds an isScam getter, this test should be the thing that
      // makes them justify it. See DR-001.
      expect(r.runtimeType.toString(), 'CheckResult');
      expect(r.foundNothing, isTrue);
    });

    test('low severity rules never report alone', () {
      final r = engine.check('Have a look at https://example.com/thing');
      expect(r.flags, isEmpty,
          reason: 'a bare link is not a red flag');
    });
  });
}
