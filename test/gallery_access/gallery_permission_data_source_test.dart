import 'package:flutter_test/flutter_test.dart';
import 'package:memorylens/features/gallery_access/data/source/gallery_permission_data_source.dart';
import 'package:memorylens/features/gallery_access/domain/entities/gallery_permission_status.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  group('toDomain', () {
    test('granted and limited photo access both let the app read photos', () {
      expect(
        GalleryPermissionDataSource.toDomain(PermissionStatus.granted),
        GalleryPermissionStatus.granted,
      );
      expect(
        GalleryPermissionDataSource.toDomain(PermissionStatus.limited),
        GalleryPermissionStatus.granted,
      );
    });

    test('permanently denied is blocked, only the settings can fix it', () {
      expect(
        GalleryPermissionDataSource.toDomain(
          PermissionStatus.permanentlyDenied,
        ),
        GalleryPermissionStatus.blocked,
      );
    });

    test('denied, restricted and provisional are plain denials', () {
      for (final status in [
        PermissionStatus.denied,
        PermissionStatus.restricted,
        PermissionStatus.provisional,
      ]) {
        expect(
          GalleryPermissionDataSource.toDomain(status),
          GalleryPermissionStatus.denied,
          reason: status.name,
        );
      }
    });
  });
}
