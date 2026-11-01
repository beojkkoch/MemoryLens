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
import 'package:memorylens/features/auth/domain/usecases/get_profile_usecase.dart';
import 'package:memorylens/features/auth/domain/usecases/sign_up_usecase.dart';
import 'package:memorylens/features/profile/ui/bloc/profile_bloc.dart';
import 'package:memorylens/features/register/ui/bloc/register_bloc.dart';
import 'package:memorylens/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:memorylens/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:memorylens/features/login/ui/bloc/login_bloc.dart';

final sl = GetIt.instance;

void initDependencies() {
  //Data sources
  sl.registerLazySingleton(() => SupabaseAuthDataSource());
  sl.registerLazySingleton(() => SupabaseProfileDataSource());
  sl.registerLazySingleton(() => SupabaseInterestDataSource());

  //Repositories
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl());
  sl.registerLazySingleton<ProfileRepository>(() => ProfileRepositoryImpl());
  sl.registerLazySingleton<InterestRepository>(() => InterestRepositoryImpl());

  //Use cases
  sl.registerLazySingleton(() => GetInterestsUseCase());
  sl.registerLazySingleton(() => SignUpUseCase());
  sl.registerLazySingleton(() => SignInUsecase());
  sl.registerLazySingleton(() => SignOutUsecase());
  sl.registerLazySingleton(() => GetProfileUseCase());

  //Blocs
  sl.registerFactory(() => RegisterBloc());
  sl.registerFactory(() => LoginBloc());
  sl.registerFactory(() => ProfileBloc());
}
