import 'package:flutter_test/flutter_test.dart';
import 'package:memorylens/features/gallery_access/domain/entities/gallery_permission_status.dart';
import 'package:memorylens/features/gallery_access/domain/repository/gallery_permission_repository.dart';
import 'package:memorylens/features/gallery_access/domain/usecases/request_gallery_access_usecase.dart';
import 'package:memorylens/injection_container.dart';

import 'fake_gallery_permission_repository.dart';

void main() {
  late FakeGalleryPermissionRepository permission;
  late RequestGalleryAccessUseCase request;

  setUp(() async {
    await sl.reset();
    permission = FakeGalleryPermissionRepository();
    sl.registerSingleton<GalleryPermissionRepository>(permission);
    request = RequestGalleryAccessUseCase();
  });

  test('without the in-app consent the device is never asked', () async {
    final status = await request(userConsented: false);

    expect(status, GalleryPermissionStatus.denied);
    expect(permission.requestCalls, 0);
  });

  test('with the in-app consent it returns what the device answers', () async {
    for (final answer in GalleryPermissionStatus.values) {
      permission.requestResult = answer;

      expect(await request(userConsented: true), answer);
    }
    expect(permission.requestCalls, GalleryPermissionStatus.values.length);
  });
}
