import 'package:dart_osc/dart_osc.dart';
import 'package:test/test.dart';

void main() {
  group('OSC Pattern Matching', () {
    group('Basic Pattern Matching', () {
      test('should match exact address patterns', () {
        final OscAddressPattern pattern =
            OscAddressPattern('/oscillator/4/frequency');
        final OscAddress address = OscAddress('/oscillator/4/frequency');
        expect(pattern.matches(address), isTrue);
      });

      test('should not match different address patterns', () {
        final OscAddressPattern pattern =
            OscAddressPattern('/oscillator/4/frequency');
        final OscAddress address = OscAddress('/oscillator/5/frequency');
        expect(pattern.matches(address), isFalse);
      });

      test('should not match patterns with different part counts', () {
        final OscAddressPattern pattern = OscAddressPattern('/oscillator/4');
        final OscAddress address = OscAddress('/oscillator/4/frequency');
        expect(pattern.matches(address), isFalse);
      });

      test('should match root pattern', () {
        final OscAddressPattern pattern = OscAddressPattern('/');
        final OscAddress address = OscAddress('/');
        expect(pattern.matches(address), isTrue);
      });

      test('should not match empty patterns', () {
        final OscAddressPattern pattern = OscAddressPattern('/test');
        final OscAddress address = OscAddress('/');
        expect(pattern.matches(address), isFalse);
      });
    });

    group('Wildcard Pattern Matching', () {
      group('Question Mark (?) - Single Character', () {
        test('should match single character with ?', () {
          final OscAddressPattern pattern =
              OscAddressPattern('/oscillator/?/frequency');
          expect(
              pattern.matches(OscAddress('/oscillator/1/frequency')), isTrue);
          expect(
              pattern.matches(OscAddress('/oscillator/2/frequency')), isTrue);
          expect(
              pattern.matches(OscAddress('/oscillator/a/frequency')), isTrue);
          expect(
              pattern.matches(OscAddress('/oscillator/Z/frequency')), isTrue);
        });

        test('should not match multiple characters with ?', () {
          final OscAddressPattern pattern =
              OscAddressPattern('/oscillator/?/frequency');
          expect(
              pattern.matches(OscAddress('/oscillator/12/frequency')), isFalse);
          expect(
              pattern.matches(OscAddress('/oscillator/ab/frequency')), isFalse);
          expect(
              pattern.matches(OscAddress('/oscillator//frequency')), isFalse);
        });

        test('should match multiple ? wildcards', () {
          final OscAddressPattern pattern = OscAddressPattern('/??/test');
          expect(pattern.matches(OscAddress('/ab/test')), isTrue);
          expect(pattern.matches(OscAddress('/12/test')), isTrue);
          expect(pattern.matches(OscAddress('/a1/test')), isTrue);
        });

        test('should not match when ? count differs', () {
          final OscAddressPattern pattern = OscAddressPattern('/??/test');
          expect(pattern.matches(OscAddress('/a/test')), isFalse);
          expect(pattern.matches(OscAddress('/abc/test')), isFalse);
        });

        test('should match ? at beginning of part', () {
          final OscAddressPattern pattern = OscAddressPattern('/?est');
          expect(pattern.matches(OscAddress('/test')), isTrue);
          expect(pattern.matches(OscAddress('/best')), isTrue);
          expect(pattern.matches(OscAddress('/rest')), isTrue);
        });

        test('should match ? at end of part', () {
          final OscAddressPattern pattern = OscAddressPattern('/tes?');
          expect(pattern.matches(OscAddress('/test')), isTrue);
          expect(pattern.matches(OscAddress('/tesa')), isTrue);
          expect(pattern.matches(OscAddress('/tes1')), isTrue);
        });

        test('should match ? in middle of part', () {
          final OscAddressPattern pattern = OscAddressPattern('/te?t');
          expect(pattern.matches(OscAddress('/test')), isTrue);
          expect(pattern.matches(OscAddress('/teat')), isTrue);
          expect(pattern.matches(OscAddress('/te1t')), isTrue);
        });
      });

      group('Asterisk (*) - Multiple Characters', () {
        test('should match zero characters with *', () {
          final OscAddressPattern pattern =
              OscAddressPattern('/oscillator/*/frequency');
          expect(pattern.matches(OscAddress('/oscillator//frequency')), isTrue);
        });

        test('should match single character with *', () {
          final OscAddressPattern pattern =
              OscAddressPattern('/oscillator/*/frequency');
          expect(
              pattern.matches(OscAddress('/oscillator/1/frequency')), isTrue);
          expect(
              pattern.matches(OscAddress('/oscillator/a/frequency')), isTrue);
        });

        test('should match multiple characters with *', () {
          final OscAddressPattern pattern =
              OscAddressPattern('/oscillator/*/frequency');
          expect(
              pattern.matches(OscAddress('/oscillator/123/frequency')), isTrue);
          expect(
              pattern.matches(OscAddress('/oscillator/abc/frequency')), isTrue);
          expect(pattern.matches(OscAddress('/oscillator/test123/frequency')),
              isTrue);
        });

        test('should match entire part with *', () {
          final OscAddressPattern pattern = OscAddressPattern('/*/frequency');
          expect(pattern.matches(OscAddress('/oscillator/frequency')), isTrue);
          expect(pattern.matches(OscAddress('/synth/frequency')), isTrue);
          expect(pattern.matches(OscAddress('/anything123/frequency')), isTrue);
        });

        test('should match * at beginning of part', () {
          final OscAddressPattern pattern = OscAddressPattern('/*est');
          expect(pattern.matches(OscAddress('/test')), isTrue);
          expect(pattern.matches(OscAddress('/best')), isTrue);
          expect(pattern.matches(OscAddress('/longest-test')), isTrue);
        });

        test('should match * at end of part', () {
          final OscAddressPattern pattern = OscAddressPattern('/test*');
          expect(pattern.matches(OscAddress('/test')), isTrue);
          expect(pattern.matches(OscAddress('/test1')), isTrue);
          expect(pattern.matches(OscAddress('/testing')), isTrue);
        });

        test('should match * in middle of part', () {
          final OscAddressPattern pattern = OscAddressPattern('/te*st');
          expect(pattern.matches(OscAddress('/test')), isTrue);
          expect(pattern.matches(OscAddress('/te123st')), isTrue);
          expect(pattern.matches(OscAddress('/teABCst')), isTrue);
        });

        test('should match multiple * wildcards', () {
          final OscAddressPattern pattern = OscAddressPattern('/*/*');
          expect(pattern.matches(OscAddress('/a/b')), isTrue);
          expect(pattern.matches(OscAddress('/oscillator/frequency')), isTrue);
          expect(pattern.matches(OscAddress('/long-name/another-long-name')),
              isTrue);
        });
      });

      group('Mixed Wildcards', () {
        test('should match combination of ? and *', () {
          final OscAddressPattern pattern =
              OscAddressPattern('/oscillator/?*/frequency');
          expect(
              pattern.matches(OscAddress('/oscillator/1/frequency')), isTrue);
          expect(
              pattern.matches(OscAddress('/oscillator/1a/frequency')), isTrue);
          expect(pattern.matches(OscAddress('/oscillator/1abc/frequency')),
              isTrue);
          expect(pattern.matches(OscAddress('/oscillator/a123/frequency')),
              isTrue);
        });

        test('should not match when required character is missing', () {
          final OscAddressPattern pattern =
              OscAddressPattern('/oscillator/?*/frequency');
          expect(
              pattern.matches(OscAddress('/oscillator//frequency')), isFalse);
        });

        test('should match complex wildcard patterns', () {
          final OscAddressPattern pattern = OscAddressPattern('/*/?/test*');
          expect(pattern.matches(OscAddress('/abc/1/test')), isTrue);
          expect(pattern.matches(OscAddress('/long/a/testing')), isTrue);
          expect(pattern.matches(OscAddress('/x/z/test123')), isTrue);
        });
      });
    });

    group('Character Class Pattern Matching', () {
      group('Basic Character Classes [abc]', () {
        test('should match characters in class', () {
          final OscAddressPattern pattern =
              OscAddressPattern('/oscillator/[123]/frequency');
          expect(
              pattern.matches(OscAddress('/oscillator/1/frequency')), isTrue);
          expect(
              pattern.matches(OscAddress('/oscillator/2/frequency')), isTrue);
          expect(
              pattern.matches(OscAddress('/oscillator/3/frequency')), isTrue);
        });

        test('should not match characters not in class', () {
          final OscAddressPattern pattern =
              OscAddressPattern('/oscillator/[123]/frequency');
          expect(
              pattern.matches(OscAddress('/oscillator/4/frequency')), isFalse);
          expect(
              pattern.matches(OscAddress('/oscillator/a/frequency')), isFalse);
          expect(
              pattern.matches(OscAddress('/oscillator/0/frequency')), isFalse);
        });

        test('should match alphabetic character class', () {
          final OscAddressPattern pattern = OscAddressPattern('/test/[abc]');
          expect(pattern.matches(OscAddress('/test/a')), isTrue);
          expect(pattern.matches(OscAddress('/test/b')), isTrue);
          expect(pattern.matches(OscAddress('/test/c')), isTrue);
          expect(pattern.matches(OscAddress('/test/d')), isFalse);
        });

        test('should match mixed character class', () {
          final OscAddressPattern pattern = OscAddressPattern('/test/[a1B]');
          expect(pattern.matches(OscAddress('/test/a')), isTrue);
          expect(pattern.matches(OscAddress('/test/1')), isTrue);
          expect(pattern.matches(OscAddress('/test/B')), isTrue);
          expect(pattern.matches(OscAddress('/test/b')), isFalse);
          expect(pattern.matches(OscAddress('/test/2')), isFalse);
        });

        test('should handle single character in class', () {
          final OscAddressPattern pattern = OscAddressPattern('/test/[x]');
          expect(pattern.matches(OscAddress('/test/x')), isTrue);
          expect(pattern.matches(OscAddress('/test/y')), isFalse);
        });
      });

      group('Character Ranges [a-z]', () {
        test('should match character ranges', () {
          final OscAddressPattern pattern = OscAddressPattern('/test/[1-3]');
          expect(pattern.matches(OscAddress('/test/1')), isTrue);
          expect(pattern.matches(OscAddress('/test/2')), isTrue);
          expect(pattern.matches(OscAddress('/test/3')), isTrue);
          expect(pattern.matches(OscAddress('/test/0')), isFalse);
          expect(pattern.matches(OscAddress('/test/4')), isFalse);
        });

        test('should match alphabetic ranges', () {
          final OscAddressPattern pattern = OscAddressPattern('/test/[a-c]');
          expect(pattern.matches(OscAddress('/test/a')), isTrue);
          expect(pattern.matches(OscAddress('/test/b')), isTrue);
          expect(pattern.matches(OscAddress('/test/c')), isTrue);
          expect(pattern.matches(OscAddress('/test/d')), isFalse);
          expect(pattern.matches(OscAddress('/test/A')), isFalse);
        });

        test('should match uppercase ranges', () {
          final OscAddressPattern pattern = OscAddressPattern('/test/[A-C]');
          expect(pattern.matches(OscAddress('/test/A')), isTrue);
          expect(pattern.matches(OscAddress('/test/B')), isTrue);
          expect(pattern.matches(OscAddress('/test/C')), isTrue);
          expect(pattern.matches(OscAddress('/test/a')), isFalse);
          expect(pattern.matches(OscAddress('/test/D')), isFalse);
        });

        test('should handle multiple ranges in same class', () {
          final OscAddressPattern pattern =
              OscAddressPattern('/test/[a-cA-C1-3]');
          expect(pattern.matches(OscAddress('/test/a')), isTrue);
          expect(pattern.matches(OscAddress('/test/b')), isTrue);
          expect(pattern.matches(OscAddress('/test/A')), isTrue);
          expect(pattern.matches(OscAddress('/test/1')), isTrue);
          expect(pattern.matches(OscAddress('/test/d')), isFalse);
          expect(pattern.matches(OscAddress('/test/4')), isFalse);
        });

        test('should handle minus at end of class (literal minus)', () {
          final OscAddressPattern pattern = OscAddressPattern('/test/[abc-]');
          expect(pattern.matches(OscAddress('/test/a')), isTrue);
          expect(pattern.matches(OscAddress('/test/-')), isTrue);
          expect(pattern.matches(OscAddress('/test/d')), isFalse);
        });
      });

      group('Negated Character Classes [!abc]', () {
        test('should not match characters in negated class', () {
          final OscAddressPattern pattern = OscAddressPattern('/test/[!abc]');
          expect(pattern.matches(OscAddress('/test/a')), isFalse);
          expect(pattern.matches(OscAddress('/test/b')), isFalse);
          expect(pattern.matches(OscAddress('/test/c')), isFalse);
        });

        test('should match characters not in negated class', () {
          final OscAddressPattern pattern = OscAddressPattern('/test/[!abc]');
          expect(pattern.matches(OscAddress('/test/d')), isTrue);
          expect(pattern.matches(OscAddress('/test/1')), isTrue);
          expect(pattern.matches(OscAddress('/test/Z')), isTrue);
        });

        test('should handle negated ranges', () {
          final OscAddressPattern pattern = OscAddressPattern('/test/[!1-3]');
          expect(pattern.matches(OscAddress('/test/1')), isFalse);
          expect(pattern.matches(OscAddress('/test/2')), isFalse);
          expect(pattern.matches(OscAddress('/test/3')), isFalse);
          expect(pattern.matches(OscAddress('/test/0')), isTrue);
          expect(pattern.matches(OscAddress('/test/4')), isTrue);
          expect(pattern.matches(OscAddress('/test/a')), isTrue);
        });

        test('should handle exclamation point not at beginning (literal)', () {
          final OscAddressPattern pattern = OscAddressPattern('/test/[a!b]');
          expect(pattern.matches(OscAddress('/test/a')), isTrue);
          expect(pattern.matches(OscAddress('/test/!')), isTrue);
          expect(pattern.matches(OscAddress('/test/b')), isTrue);
          expect(pattern.matches(OscAddress('/test/c')), isFalse);
        });
      });

      group('Complex Character Classes', () {
        test('should match character classes at different positions', () {
          final OscAddressPattern pattern =
              OscAddressPattern('/[abc]/test/[123]');
          expect(pattern.matches(OscAddress('/a/test/1')), isTrue);
          expect(pattern.matches(OscAddress('/b/test/2')), isTrue);
          expect(pattern.matches(OscAddress('/c/test/3')), isTrue);
          expect(pattern.matches(OscAddress('/d/test/1')), isFalse);
          expect(pattern.matches(OscAddress('/a/test/4')), isFalse);
        });

        test('should combine character classes with other wildcards', () {
          final OscAddressPattern pattern = OscAddressPattern('/*/[abc]/test?');
          expect(pattern.matches(OscAddress('/anything/a/test1')), isTrue);
          expect(pattern.matches(OscAddress('/x/b/testZ')), isTrue);
          expect(pattern.matches(OscAddress('/long/c/testA')), isTrue);
          expect(pattern.matches(OscAddress('/x/d/test1')), isFalse);
        });
      });
    });

    group('String Alternative Pattern Matching {foo,bar}', () {
      test('should match strings in alternative list', () {
        final OscAddressPattern pattern =
            OscAddressPattern('/oscillator/{1,2,3}/frequency');
        expect(pattern.matches(OscAddress('/oscillator/1/frequency')), isTrue);
        expect(pattern.matches(OscAddress('/oscillator/2/frequency')), isTrue);
        expect(pattern.matches(OscAddress('/oscillator/3/frequency')), isTrue);
        expect(pattern.matches(OscAddress('/oscillator/4/frequency')), isFalse);
      });

      test('should match multi-character alternatives', () {
        final OscAddressPattern pattern =
            OscAddressPattern('/synth/{osc,filter,env}/param');
        expect(pattern.matches(OscAddress('/synth/osc/param')), isTrue);
        expect(pattern.matches(OscAddress('/synth/filter/param')), isTrue);
        expect(pattern.matches(OscAddress('/synth/env/param')), isTrue);
        expect(pattern.matches(OscAddress('/synth/lfo/param')), isFalse);
      });

      test('should handle two alternatives', () {
        final OscAddressPattern pattern = OscAddressPattern('/test/{foo,bar}');
        expect(pattern.matches(OscAddress('/test/foo')), isTrue);
        expect(pattern.matches(OscAddress('/test/bar')), isTrue);
        expect(pattern.matches(OscAddress('/test/baz')), isFalse);
      });

      test('should handle single alternative', () {
        final OscAddressPattern pattern = OscAddressPattern('/test/{foo}');
        expect(pattern.matches(OscAddress('/test/foo')), isTrue);
        expect(pattern.matches(OscAddress('/test/bar')), isFalse);
      });

      test('should handle empty alternatives', () {
        final OscAddressPattern pattern = OscAddressPattern('/test/{,foo}');
        expect(pattern.matches(OscAddress('/test/')), isTrue);
        expect(pattern.matches(OscAddress('/test/foo')), isTrue);
        expect(pattern.matches(OscAddress('/test/bar')), isFalse);
      });

      test('should handle alternatives with special characters', () {
        final OscAddressPattern pattern =
            OscAddressPattern('/test/{a-b,c_d,e.f}');
        expect(pattern.matches(OscAddress('/test/a-b')), isTrue);
        expect(pattern.matches(OscAddress('/test/c_d')), isTrue);
        expect(pattern.matches(OscAddress('/test/e.f')), isTrue);
        expect(pattern.matches(OscAddress('/test/xyz')), isFalse);
      });

      test('should combine alternatives with other patterns', () {
        final OscAddressPattern pattern = OscAddressPattern('/*/{foo,bar}/?');
        expect(pattern.matches(OscAddress('/test/foo/a')), isTrue);
        expect(pattern.matches(OscAddress('/xyz/bar/1')), isTrue);
        expect(pattern.matches(OscAddress('/anything/foo/Z')), isTrue);
        expect(pattern.matches(OscAddress('/test/baz/a')), isFalse);
      });
    });

    group('Complex Pattern Combinations', () {
      test('should handle pattern from spec examples', () {
        final OscAddressPattern pattern = OscAddressPattern('/second/[1-2]');
        expect(pattern.matches(OscAddress('/second/1')), isTrue);
        expect(pattern.matches(OscAddress('/second/2')), isTrue);
        expect(pattern.matches(OscAddress('/second/3')), isFalse);
      });

      test('should handle wildcard pattern from spec examples', () {
        final OscAddressPattern pattern = OscAddressPattern('/third/*');
        expect(pattern.matches(OscAddress('/third/a')), isTrue);
        expect(pattern.matches(OscAddress('/third/b')), isTrue);
        expect(pattern.matches(OscAddress('/third/c')), isTrue);
        expect(pattern.matches(OscAddress('/third/anything')), isTrue);
        expect(pattern.matches(OscAddress('/fourth/a')), isFalse);
      });

      test('should handle all pattern types together', () {
        final OscAddressPattern pattern =
            OscAddressPattern('/*/{test,demo}/[a-c]?/end*');
        expect(pattern.matches(OscAddress('/prefix/test/a1/end')), isTrue);
        expect(pattern.matches(OscAddress('/x/demo/bZ/ending')), isTrue);
        expect(pattern.matches(OscAddress('/long/test/c9/end-result')), isTrue);
        expect(pattern.matches(OscAddress('/x/other/a1/end')), isFalse);
        expect(pattern.matches(OscAddress('/x/test/d1/end')), isFalse);
        expect(pattern.matches(OscAddress('/x/test/a/end')), isFalse);
      });

      test('should handle nested pattern structures', () {
        final OscAddressPattern pattern =
            OscAddressPattern('/osc[1-3]/{sin,saw}/*');
        expect(pattern.matches(OscAddress('/osc1/sin/frequency')), isTrue);
        expect(pattern.matches(OscAddress('/osc2/saw/amplitude')), isTrue);
        expect(pattern.matches(OscAddress('/osc3/sin/phase')), isTrue);
        expect(pattern.matches(OscAddress('/osc4/sin/frequency')), isFalse);
        expect(pattern.matches(OscAddress('/osc1/tri/frequency')), isFalse);
      });

      test('should be case sensitive', () {
        final OscAddressPattern pattern =
            OscAddressPattern('/Test/{FOO,bar}/[A-Z]');
        expect(pattern.matches(OscAddress('/Test/FOO/A')), isTrue);
        expect(pattern.matches(OscAddress('/Test/bar/Z')), isTrue);
        expect(pattern.matches(OscAddress('/test/FOO/A')), isFalse);
        expect(pattern.matches(OscAddress('/Test/foo/A')), isFalse);
        expect(pattern.matches(OscAddress('/Test/FOO/a')), isFalse);
      });
    });

    group('Pattern Validation', () {
      test('should reject malformed character classes', () {
        expect(() => OscAddressPattern('/test/[abc'), throwsFormatException);
        expect(() => OscAddressPattern('/test/abc]'), throwsFormatException);
        expect(() => OscAddressPattern('/test/['), throwsFormatException);
        expect(() => OscAddressPattern('/test/]'), throwsFormatException);
      });

      test('should reject malformed string alternatives', () {
        expect(
            () => OscAddressPattern('/test/{foo,bar'), throwsFormatException);
        expect(
            () => OscAddressPattern('/test/foo,bar}'), throwsFormatException);
        expect(() => OscAddressPattern('/test/{'), throwsFormatException);
        expect(() => OscAddressPattern('/test/}'), throwsFormatException);
      });

      test('should reject invalid character ranges', () {
        expect(() => OscAddressPattern('/test/[z-a]'), throwsFormatException);
        expect(() => OscAddressPattern('/test/[9-0]'), throwsFormatException);
      });

      test('should handle edge cases', () {
        expect(() => OscAddressPattern('/test/[]'), throwsFormatException);
        expect(() => OscAddressPattern('/test/{}'), returnsNormally);
      });
    });

    group('Address Creation and Validation', () {
      test('should create valid OSC addresses', () {
        expect(() => OscAddress('/test'), returnsNormally);
        expect(() => OscAddress('/oscillator/4/frequency'), returnsNormally);
        expect(() => OscAddress('/a/b/c/d/e'), returnsNormally);
      });

      test('should reject invalid OSC addresses', () {
        expect(() => OscAddress('test'), throwsArgumentError);
        expect(() => OscAddress(''), throwsArgumentError);
        expect(() => OscAddress('/test*'), throwsArgumentError);
        expect(() => OscAddress('/test?'), throwsArgumentError);
        expect(() => OscAddress('/test[abc]'), throwsArgumentError);
        expect(() => OscAddress('/test{foo,bar}'), throwsArgumentError);
      });

      test('should parse address parts correctly', () {
        final OscAddress address = OscAddress('/a/b/cde');
        expect(address.parts, equals(<String>['a', 'b', 'cde']));

        final OscAddress address2 = OscAddress('/resonators/3/frequency');
        expect(
            address2.parts, equals(<String>['resonators', '3', 'frequency']));
      });
    });
  });
}
