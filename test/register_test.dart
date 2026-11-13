import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:memorylens/components/interest_chip.dart';
import 'package:memorylens/features/auth/domain/entities/app_user.dart';
import 'package:memorylens/features/auth/domain/entities/interest.dart';
import 'package:memorylens/features/auth/domain/entities/profile.dart';
import 'package:memorylens/features/auth/domain/repository/auth_repository.dart';
import 'package:memorylens/features/auth/domain/repository/interest_repository.dart';
import 'package:memorylens/features/auth/domain/repository/profile_repository.dart';
import 'package:memorylens/features/auth/domain/usecases/get_interests_usecase.dart';
import 'package:memorylens/features/auth/domain/usecases/get_profile_usecase.dart';
import 'package:memorylens/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:memorylens/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:memorylens/features/auth/domain/usecases/sign_up_usecase.dart';
import 'package:memorylens/features/error_handling/data/mapper/exception_mapper.dart';
import 'package:memorylens/features/error_handling/domain/entities/app_exception.dart';
import 'package:memorylens/features/analyzing/ui/screens/analyzing_screen.dart';
import 'package:memorylens/features/gallery_access/domain/repository/gallery_permission_repository.dart';
import 'package:memorylens/features/gallery_access/domain/usecases/check_gallery_access_usecase.dart';
import 'package:memorylens/features/gallery_access/domain/usecases/open_gallery_settings_usecase.dart';
import 'package:memorylens/features/gallery_access/domain/usecases/request_gallery_access_usecase.dart';
import 'package:memorylens/features/login/ui/bloc/login_bloc.dart';
import 'package:memorylens/features/login/ui/screens/login_screen.dart';
import 'package:memorylens/features/memories/domain/repository/photo_repository.dart';
import 'package:memorylens/features/memories/domain/usecases/count_photos_usecase.dart';
import 'package:memorylens/features/memories/ui/bloc/memories_bloc.dart';
import 'package:memorylens/features/memories/ui/bloc/memories_event.dart';
import 'package:memorylens/features/memories/ui/screens/memories_screen.dart';
import 'package:memorylens/features/profile/ui/bloc/profile_bloc.dart';
import 'package:memorylens/features/profile/ui/bloc/profile_event.dart';
import 'package:memorylens/features/profile/ui/screens/profile_screen.dart';
import 'package:memorylens/features/register/ui/bloc/register_bloc.dart';
import 'package:memorylens/features/register/ui/screens/confirm_email_screen.dart';
import 'package:memorylens/features/register/ui/screens/register_screen.dart';
import 'package:memorylens/features/welcome/ui/screens/welcome_screen.dart';
import 'package:memorylens/injection_container.dart';
import 'package:memorylens/theme/app_theme.dart';

import 'gallery_access/fake_gallery_permission_repository.dart';
import 'memories/fake_photo_repository.dart';

/// Records the sign up call instead of talking to Supabase Auth.
class FakeAuthRepository implements AuthRepository {
  String? email;
  String? password;
  String? fullName;
  String? city;
  String? profession;
  List<int>? interestIds;
  List<String>? newInterestNames;
  Object? error;
  Object? signOutError;

  @override
  Future<AppUser> signUp({
    required String email,
    required String password,
    required String fullName,
    required String city,
    required String profession,
    required List<int> interestIds,
    required List<String> newInterestNames,
  }) async {
    if (error != null) throw error!;
    this.email = email;
    this.password = password;
    this.fullName = fullName;
    this.city = city;
    this.profession = profession;
    this.interestIds = interestIds;
    this.newInterestNames = newInterestNames;
    return AppUser(id: 'user-1', email: email);
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    if (error != null) throw error!;
    this.email = email;
    this.password = password;
    return AppUser(id: 'user-1', email: email);
  }

  @override
  Future<void> signOut() async {
    if (signOutError != null) throw signOutError!;
  }

  @override
  AppUser? currentUser() {
    final email = this.email;
    return email == null ? null : AppUser(id: 'user-1', email: email);
  }
}

/// Serves the profile the backend would have saved.
class FakeProfileRepository implements ProfileRepository {
  late Profile profile;
  Object? error;

  @override
  Future<Profile> getProfile(String userId) async {
    if (error != null) throw error!;
    return profile;
  }
}

/// Serves part of the seeded catalog.
class FakeInterestRepository implements InterestRepository {
  Object? error;

  @override
  Future<List<Interest>> getInterests() async {
    if (error != null) throw error!;
    return const [
      Interest(id: 1, name: 'Tecnología'),
      Interest(id: 2, name: 'Moda'),
      Interest(id: 6, name: 'Viajes'),
    ];
  }
}

void main() {
  late FakeAuthRepository auth;
  late FakeProfileRepository profiles;
  late FakeInterestRepository interests;

  setUp(() async {
    await sl.reset();
    auth = FakeAuthRepository();
    profiles = FakeProfileRepository();
    interests = FakeInterestRepository();
    sl.registerSingleton<AuthRepository>(auth);
    sl.registerSingleton<ProfileRepository>(profiles);
    sl.registerSingleton<InterestRepository>(interests);
    sl.registerLazySingleton<SignUpUseCase>(() => SignUpUseCase());
    sl.registerLazySingleton(() => GetInterestsUseCase());
    sl.registerFactory(() => RegisterBloc());
    sl.registerLazySingleton(() => GetProfileUseCase());
    sl.registerLazySingleton(() => SignOutUsecase());
    sl.registerLazySingleton(() => SignInUsecase());
    sl.registerFactory(() => LoginBloc());
    sl.registerFactory(() => ProfileBloc());
    // Login now lands on Recuerdos, which needs the gallery and photo fakes.
    sl.registerSingleton<GalleryPermissionRepository>(
      FakeGalleryPermissionRepository(),
    );
    sl.registerSingleton<PhotoRepository>(FakePhotoRepository());
    sl.registerLazySingleton(() => RequestGalleryAccessUseCase());
    sl.registerLazySingleton(() => CheckGalleryAccessUseCase());
    sl.registerLazySingleton(() => OpenGallerySettingsUseCase());
    sl.registerLazySingleton(() => CountPhotosUseCase());
    sl.registerFactory(() => MemoriesBloc());
  });

  Future<void> pumpApp(WidgetTester tester, {String route = '/'}) async {
    tester.view.physicalSize = const Size(430, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: route,
        routes: {
          '/': (_) => const WelcomeScreen(),
          '/login': (_) => BlocProvider(
            create: (_) => sl<LoginBloc>(),
            child: const LoginScreen(),
          ),
          '/register': (_) => BlocProvider(
            create: (_) => sl<RegisterBloc>(),
            child: const RegisterScreen(),
          ),
          '/confirm-email': (_) => const ConfirmEmailScreen(),
          '/recuerdos': (_) => BlocProvider(
            create: (_) => sl<MemoriesBloc>()..add(MemoriesStarted()),
            child: const MemoriesScreen(),
          ),
          '/analizando': (_) => const AnalyzingScreen(),
          '/profile': (_) => BlocProvider(
            create: (_) => sl<ProfileBloc>()..add(ProfileRequested()),
            child: const ProfileScreen(),
          ),
        },
      ),
    );
    await tester.pumpAndSettle();
  }

  Color barColor(WidgetTester tester, int index) {
    final bar = tester.widget<AnimatedContainer>(
      find.byKey(Key('step-bar-$index')),
    );
    return (bar.decoration! as BoxDecoration).color!;
  }

  Future<void> fillAccount(
    WidgetTester tester, {
    String confirmPassword = 'secreto123',
  }) async {
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Ana Gómez');
    await tester.enterText(fields.at(1), 'ana@memorylens.ai');
    await tester.enterText(fields.at(2), 'secreto123');
    await tester.enterText(fields.at(3), confirmPassword);
    await tester.enterText(fields.at(4), 'Bogotá');
  }

  Future<void> goToCharacterization(WidgetTester tester) async {
    await pumpApp(tester, route: '/register');
    await fillAccount(tester);
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'Diseñadora');
  }

  testWidgets('welcome opens the login screen', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Continuar con correo electrónico'));
    await tester.pumpAndSettle();
    expect(find.text('Iniciar sesión'), findsOneWidget);
  });

  testWidgets('login with valid credentials opens Recuerdos and then the '
      'profile', (tester) async {
    profiles.profile = const Profile(
      id: 'user-1',
      fullName: 'Ana Gómez',
      email: 'ana@memorylens.ai',
      city: 'Bogotá',
      profession: 'Diseñadora',
    );
    await pumpApp(tester, route: '/login');
    await tester.enterText(find.byType(TextField).at(0), 'ana@memorylens.ai');
    await tester.enterText(find.byType(TextField).at(1), 'secreto123');
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expect(auth.email, 'ana@memorylens.ai');
    expect(auth.password, 'secreto123');
    expect(find.text('Recuerdos'), findsOneWidget);
    expect(find.text('Mi perfil'), findsNothing);

    await tester.tap(find.byTooltip('Mi perfil'));
    await tester.pumpAndSettle();
    expect(find.text('Mi perfil'), findsOneWidget);
    expect(find.text('Ana Gómez'), findsOneWidget);
  });

  testWidgets('login with empty fields shows a message', (tester) async {
    await pumpApp(tester, route: '/login');
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();
    expect(find.text('Completa todos los campos'), findsOneWidget);
    expect(auth.email, isNull);
  });

  testWidgets('login failure shows the message from the backend', (
    tester,
  ) async {
    auth.error = const AppException('Correo o contraseña incorrectos');
    await pumpApp(tester, route: '/login');
    await tester.enterText(find.byType(TextField).at(0), 'ana@memorylens.ai');
    await tester.enterText(find.byType(TextField).at(1), 'mala-clave');
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();
    expect(find.text('Correo o contraseña incorrectos'), findsOneWidget);
    expect(find.text('Mi perfil'), findsNothing);
  });

  testWidgets('welcome opens the register screen on step one', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Regístrate'));
    await tester.pumpAndSettle();
    expect(find.text('Crear cuenta'), findsOneWidget);
    expect(find.text('Paso 1 de 2'), findsOneWidget);
    expect(barColor(tester, 0), AppColors.primary);
    expect(barColor(tester, 1), AppColors.border);
  });

  testWidgets('step one does not continue with empty fields', (tester) async {
    await pumpApp(tester, route: '/register');
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(find.text('Completa todos los campos'), findsOneWidget);
    expect(find.text('Paso 1 de 2'), findsOneWidget);
    expect(find.text('CARACTERIZACIÓN'), findsNothing);
  });

  testWidgets('step one does not continue with mismatched passwords', (
    tester,
  ) async {
    await pumpApp(tester, route: '/register');
    await fillAccount(tester, confirmPassword: 'otra-clave');
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(find.text('Las contraseñas no coinciden'), findsOneWidget);
    expect(find.text('CARACTERIZACIÓN'), findsNothing);
  });

  testWidgets('eye button shows and hides the password', (tester) async {
    await pumpApp(tester, route: '/register');
    bool passwordHidden() =>
        tester.widget<TextField>(find.byType(TextField).at(2)).obscureText;
    expect(passwordHidden(), isTrue);
    await tester.tap(find.byTooltip('Mostrar contraseña').first);
    await tester.pump();
    expect(passwordHidden(), isFalse);
    await tester.tap(find.byTooltip('Ocultar contraseña'));
    await tester.pump();
    expect(passwordHidden(), isTrue);
  });

  testWidgets('complete step one opens step two and fills both bars', (
    tester,
  ) async {
    await goToCharacterization(tester);
    expect(find.text('CARACTERIZACIÓN'), findsOneWidget);
    expect(find.text('Paso 2 de 2'), findsOneWidget);
    expect(barColor(tester, 1), AppColors.primary);
    expect(find.text('Viajes'), findsOneWidget);
  });

  testWidgets('back arrow on step two returns to step one with the data', (
    tester,
  ) async {
    await goToCharacterization(tester);
    await tester.tap(find.byTooltip('Volver'));
    await tester.pumpAndSettle();
    expect(find.text('Paso 1 de 2'), findsOneWidget);
    expect(find.text('ana@memorylens.ai'), findsOneWidget);
  });

  testWidgets('step two without interests shows an error', (tester) async {
    await goToCharacterization(tester);
    await tester.tap(find.text('Comenzar'));
    await tester.pumpAndSettle();
    expect(find.text('Elige al menos un interés'), findsOneWidget);
    expect(auth.email, isNull);
  });

  testWidgets('typing an existing interest selects it instead of duplicating', (
    tester,
  ) async {
    await goToCharacterization(tester);
    await tester.enterText(find.byType(TextField).at(1), '  viajes ');
    await tester.tap(find.byTooltip('Agregar interés'));
    await tester.pumpAndSettle();
    expect(find.text('Viajes'), findsOneWidget);
    await tester.tap(find.text('Comenzar'));
    await tester.pumpAndSettle();
    expect(auth.interestIds, [6]);
    expect(auth.newInterestNames, isEmpty);
  });

  testWidgets(
    'valid form signs up with a new interest and asks to confirm the email',
    (tester) async {
      await goToCharacterization(tester);
      await tester.tap(find.text('Tecnología'));
      await tester.enterText(find.byType(TextField).at(1), 'fotografía');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.text('Fotografía'), findsOneWidget);
      await tester.tap(find.text('Comenzar'));
      await tester.pumpAndSettle();

      expect(auth.email, 'ana@memorylens.ai');
      expect(auth.password, 'secreto123');
      expect(auth.fullName, 'Ana Gómez');
      expect(auth.city, 'Bogotá');
      expect(auth.profession, 'Diseñadora');
      expect(auth.interestIds, [1]);
      expect(auth.newInterestNames, ['Fotografía']);
      expect(find.text('Revisa tu correo'), findsOneWidget);
      expect(find.textContaining('ana@memorylens.ai'), findsOneWidget);
      expect(find.text('Mi perfil'), findsNothing);
    },
  );

  testWidgets('confirm email screen leads to the login', (tester) async {
    await goToCharacterization(tester);
    await tester.tap(find.text('Moda'));
    await tester.tap(find.text('Comenzar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ir a iniciar sesión'));
    await tester.pumpAndSettle();
    expect(find.text('Bienvenido de nuevo'), findsOneWidget);
  });

  testWidgets('sign up failure shows the message from the backend', (
    tester,
  ) async {
    auth.error = const AppException('Ya existe una cuenta con ese correo');
    await goToCharacterization(tester);
    await tester.tap(find.text('Moda'));
    await tester.tap(find.text('Comenzar'));
    await tester.pumpAndSettle();
    expect(find.text('Ya existe una cuenta con ese correo'), findsOneWidget);
    expect(find.text('Mi perfil'), findsNothing);
  });

  group('connection and unexpected failures', () {
    final networkError = ExceptionMapper.map(
      http.ClientException('Failed host lookup'),
    );
    const ana = Profile(
      id: 'user-1',
      fullName: 'Ana Gómez',
      email: 'ana@memorylens.ai',
      city: 'Bogotá',
      profession: 'Diseñadora',
    );

    String typed(WidgetTester tester, int index) {
      return tester
          .widget<TextField>(find.byType(TextField).at(index))
          .controller!
          .text;
    }

    testWidgets('login without connection shows a friendly message and keeps '
        'what was typed', (tester) async {
      auth.error = networkError;
      profiles.profile = ana;
      await pumpApp(tester, route: '/login');
      await tester.enterText(find.byType(TextField).at(0), 'ana@memorylens.ai');
      await tester.enterText(find.byType(TextField).at(1), 'secreto123');
      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();

      expect(find.text(networkError.message), findsOneWidget);
      expect(find.textContaining('ClientException'), findsNothing);
      expect(typed(tester, 0), 'ana@memorylens.ai');
      expect(typed(tester, 1), 'secreto123');

      auth.error = null;
      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();
      expect(find.text('Recuerdos'), findsOneWidget);
    });

    testWidgets('login with an unexpected error shows the generic message', (
      tester,
    ) async {
      auth.error = StateError('Bad state: secret detail');
      await pumpApp(tester, route: '/login');
      await tester.enterText(find.byType(TextField).at(0), 'ana@memorylens.ai');
      await tester.enterText(find.byType(TextField).at(1), 'secreto123');
      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();

      expect(find.text(AppException.genericMessage), findsOneWidget);
      expect(find.textContaining('secret detail'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('sign up without connection keeps the second step as it was', (
      tester,
    ) async {
      auth.error = networkError;
      await goToCharacterization(tester);
      await tester.tap(find.text('Moda'));
      await tester.tap(find.text('Comenzar'));
      await tester.pumpAndSettle();

      expect(find.text(networkError.message), findsOneWidget);
      expect(typed(tester, 0), 'Diseñadora');
      final chip = tester.widget<InterestChip>(
        find.widgetWithText(InterestChip, 'Moda'),
      );
      expect(chip.selected, isTrue);

      auth.error = null;
      await tester.tap(find.text('Comenzar'));
      await tester.pumpAndSettle();
      expect(find.text('Revisa tu correo'), findsOneWidget);
    });

    testWidgets('interests that fail to load offer a retry with the reason', (
      tester,
    ) async {
      interests.error = networkError;
      await goToCharacterization(tester);
      expect(find.text(networkError.message), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);

      interests.error = null;
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();
      expect(find.text('Viajes'), findsOneWidget);
    });

    testWidgets('profile that fails to load offers a retry that recovers', (
      tester,
    ) async {
      auth.email = 'ana@memorylens.ai';
      profiles.profile = ana;
      profiles.error = networkError;
      await pumpApp(tester, route: '/profile');

      expect(find.text(networkError.message), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);

      profiles.error = null;
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();
      expect(find.text('Ana Gómez'), findsOneWidget);
    });

    testWidgets('profile hit by an unexpected error does not stay loading', (
      tester,
    ) async {
      auth.email = 'ana@memorylens.ai';
      profiles.error = TypeError();
      await pumpApp(tester, route: '/profile');

      expect(find.text(AppException.genericMessage), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('a failed sign out leaves the button usable again', (
      tester,
    ) async {
      auth.email = 'ana@memorylens.ai';
      profiles.profile = ana;
      auth.signOutError = networkError;
      await pumpApp(tester, route: '/profile');
      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();

      expect(find.text(networkError.message), findsOneWidget);
      final button = tester.widget<OutlinedButton>(
        find.byWidgetPredicate((widget) => widget is OutlinedButton),
      );
      expect(button.onPressed, isNotNull);
    });
  });
}
