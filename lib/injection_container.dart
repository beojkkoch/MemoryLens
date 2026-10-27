import 'package:get_it/get_it.dart';
import 'package:memorylens/features/auth/data/repository/auth_repository_impl.dart';
import 'package:memorylens/features/auth/data/repository/interest_repository_impl.dart';
import 'package:memorylens/features/auth/data/repository/profile_repository_impl.dart';
import 'package:memorylens/features/auth/data/source/supabase_auth_data_source.dart';
import 'package:memorylens/features/auth/data/source/supabase_interest_data_source.dart';
import 'package:memorylens/features/auth/data/source/supabase_profile_data_source.dart';
import 'package:memorylens/features/auth/domain/repository/auth_repository.dart';
import 'package:memorylens/features/auth/domain/repository/interest_repository.dart';
import 'package:memorylens/features/auth/domain/repository/profile_repository.dart';
import 'package:memorylens/features/auth/domain/usecases/get_interests_usecase.dart';
import 'package:memorylens/features/auth/domain/usecases/sign_up_usecase.dart';
import 'package:memorylens/features/register/ui/bloc/register_bloc.dart';

final sl = GetIt.instance;

void initDependencies() {
  sl.registerLazySingleton(() => SupabaseAuthDataSource());
  sl.registerLazySingleton(() => SupabaseProfileDataSource());
  sl.registerLazySingleton(() => SupabaseInterestDataSource());

  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl());
  sl.registerLazySingleton<ProfileRepository>(() => ProfileRepositoryImpl());
  sl.registerLazySingleton<InterestRepository>(() => InterestRepositoryImpl());

  sl.registerLazySingleton(() => SignUpUseCase());
  sl.registerLazySingleton(() => GetInterestsUseCase());

  sl.registerFactory(() => RegisterBloc());
}
