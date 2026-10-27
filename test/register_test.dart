import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memorylens/features/auth/domain/entities/app_user.dart';
import 'package:memorylens/features/auth/domain/entities/interest.dart';
import 'package:memorylens/features/auth/domain/entities/profile.dart';
import 'package:memorylens/features/auth/domain/repository/auth_repository.dart';
import 'package:memorylens/features/auth/domain/repository/interest_repository.dart';
import 'package:memorylens/features/auth/domain/repository/profile_repository.dart';
import 'package:memorylens/features/auth/domain/usecases/get_interests_usecase.dart';
import 'package:memorylens/features/auth/domain/usecases/sign_up_usecase.dart';
import 'package:memorylens/features/login/ui/screens/login_screen.dart';
import 'package:memorylens/features/profile/ui/screens/profile_screen.dart';
import 'package:memorylens/features/register/ui/bloc/register_bloc.dart';
import 'package:memorylens/features/register/ui/screens/register_screen.dart';
import 'package:memorylens/features/welcome/ui/screens/welcome_screen.dart';
import 'package:memorylens/injection_container.dart';

/// Records the sign up call instead of talking to Supabase Auth.
class FakeAuthRepository implements AuthRepository {
  String? email;
  String? password;
  Exception? error;

  @override
  Future<AppUser> signUp({
    required String email,
    required String password,
  }) async {
    if (error != null) throw error!;
    this.email = email;
    this.password = password;
    return AppUser(id: 'user-1', email: email);
  }

  @override
  AppUser? currentUser() => null;
}

/// Keeps the saved profile and interests in memory.
class FakeProfileRepository implements ProfileRepository {
  Profile? profile;
  List<int>? interestIds;

  @override
  Future<void> createProfile(Profile profile) async {
    this.profile = profile;
  }

  @override
  Future<void> saveInterests(String userId, List<int> interestIds) async {
    this.interestIds = interestIds;
  }
}

/// Serves the same catalog that the migration seeds.
class FakeInterestRepository implements InterestRepository {
  @override
  Future<List<Interest>> getInterests() async {
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

  setUp(() async {
    await sl.reset();
    auth = FakeAuthRepository();
    profiles = FakeProfileRepository();
    sl.registerSingleton<AuthRepository>(auth);
    sl.registerSingleton<ProfileRepository>(profiles);
    sl.registerSingleton<InterestRepository>(FakeInterestRepository());
    sl.registerLazySingleton(() => SignUpUseCase());
    sl.registerLazySingleton(() => GetInterestsUseCase());
    sl.registerFactory(() => RegisterBloc());
  });

  Future<void> pumpApp(WidgetTester tester, {String route = '/'}) async {
    tester.view.physicalSize = const Size(430, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: route,
        routes: {
          '/': (_) => const WelcomeScreen(),
          '/login': (_) => const LoginScreen(),
          '/register': (_) => BlocProvider(
            create: (_) => sl<RegisterBloc>(),
            child: const RegisterScreen(),
          ),
          '/profile': (_) => const ProfileScreen(),
        },
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> fillForm(
    WidgetTester tester, {
    String confirmPassword = 'secreto123',
  }) async {
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Ana Gómez');
    await tester.enterText(fields.at(1), 'ana@memorylens.ai');
    await tester.enterText(fields.at(2), 'secreto123');
    await tester.enterText(fields.at(3), confirmPassword);
    await tester.enterText(fields.at(4), 'Bogotá');
    await tester.enterText(fields.at(5), 'Diseñadora');
  }

  testWidgets('welcome opens the login screen', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Continuar con correo electrónico'));
    await tester.pumpAndSettle();
    expect(find.text('Iniciar sesión'), findsOneWidget);
  });

  testWidgets('welcome opens the register screen with the interests', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.text('Regístrate'));
    await tester.pumpAndSettle();
    expect(find.text('Crear cuenta'), findsOneWidget);
    expect(find.text('Viajes'), findsOneWidget);
  });

  testWidgets('empty form shows an error and does not sign up', (
    tester,
  ) async {
    await pumpApp(tester, route: '/register');
    await tester.tap(find.text('Comenzar'));
    await tester.pumpAndSettle();
    expect(find.text('Completa todos los campos'), findsOneWidget);
    expect(auth.email, isNull);
  });

  testWidgets('mismatched passwords show an error', (tester) async {
    await pumpApp(tester, route: '/register');
    await fillForm(tester, confirmPassword: 'otra-clave');
    await tester.tap(find.text('Viajes'));
    await tester.tap(find.text('Comenzar'));
    await tester.pumpAndSettle();
    expect(find.text('Las contraseñas no coinciden'), findsOneWidget);
    expect(auth.email, isNull);
  });

  testWidgets('form without interests shows an error', (tester) async {
    await pumpApp(tester, route: '/register');
    await fillForm(tester);
    await tester.tap(find.text('Comenzar'));
    await tester.pumpAndSettle();
    expect(find.text('Elige al menos un interés'), findsOneWidget);
    expect(auth.email, isNull);
  });

  testWidgets('valid form signs up, saves the profile and opens profile', (
    tester,
  ) async {
    await pumpApp(tester, route: '/register');
    await fillForm(tester);
    await tester.tap(find.text('Tecnología'));
    await tester.tap(find.text('Viajes'));
    await tester.pump();
    await tester.tap(find.text('Comenzar'));
    await tester.pumpAndSettle();

    expect(auth.email, 'ana@memorylens.ai');
    expect(auth.password, 'secreto123');
    expect(profiles.profile?.fullName, 'Ana Gómez');
    expect(profiles.profile?.city, 'Bogotá');
    expect(profiles.profile?.profession, 'Diseñadora');
    expect(profiles.interestIds, unorderedEquals([1, 6]));
    expect(find.text('Mi perfil'), findsOneWidget);
  });

  testWidgets('sign up failure shows the message from the backend', (
    tester,
  ) async {
    auth.error = Exception('Ya existe una cuenta con ese correo');
    await pumpApp(tester, route: '/register');
    await fillForm(tester);
    await tester.tap(find.text('Moda'));
    await tester.tap(find.text('Comenzar'));
    await tester.pumpAndSettle();
    expect(find.text('Ya existe una cuenta con ese correo'), findsOneWidget);
    expect(find.text('Mi perfil'), findsNothing);
  });
}
