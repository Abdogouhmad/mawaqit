import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mawaqit/core/qibla/qibla.dart';

void main() {
  group('qibla bearing', () {
    test('points south from a point due north on the same meridian', () {
      expect(qiblaBearing(50, qiblaLongitude), closeTo(180, 0.001));
    });

    test('points north from a point due south on the same meridian', () {
      expect(qiblaBearing(0, qiblaLongitude), closeTo(0, 0.001));
    });

    test('points approximately east from the same latitude to the west', () {
      expect(qiblaBearing(qiblaLatitude, 30), inInclusiveRange(88, 91));
    });

    test('wraps the antimeridian instead of taking the long way round', () {
      final west = qiblaBearing(20, -179.9);
      final equivalentEast = qiblaBearing(20, 180.1);
      expect(west, closeTo(equivalentEast, 0.0001));
      expect(west, inInclusiveRange(0, 360));
    });

    test('is stable for longitudes beyond the usual range', () {
      expect(
        qiblaBearing(34.0209, -6.8416),
        closeTo(qiblaBearing(34.0209, 353.1584), 0.0001),
      );
    });

    test('agrees with adhan_dart at representative cities', () {
      for (final (lat, lng) in [
        (34.0209, -6.8416), // Rabat
        (51.5074, -0.1278), // London
        (24.7136, 46.6753), // Riyadh
        (-33.8688, 151.2093), // Sydney
        (35.6895, 139.6917), // Tokyo
      ]) {
        final reference = Qibla.qibla(Coordinates(lat, lng));
        expect(qiblaBearing(lat, lng), closeTo(reference, 0.01));
      }
    });
  });

  group('qibla distance', () {
    test('is zero at the Kaaba', () {
      expect(qiblaDistanceKm(qiblaLatitude, qiblaLongitude), closeTo(0, 0.01));
    });

    test('matches the known Rabat–Mecca range', () {
      expect(qiblaDistanceKm(34.0209, -6.8416), inInclusiveRange(4700, 4800));
    });
  });

  group('needle angle', () {
    test('takes the short turn across north', () {
      expect(qiblaNeedleAngle(10, 350), closeTo(20, 0.001));
      expect(qiblaNeedleAngle(350, 10), closeTo(-20, 0.001));
    });

    test('is zero when the phone already faces the Qibla', () {
      expect(qiblaNeedleAngle(142, 142), 0);
    });
  });
}
