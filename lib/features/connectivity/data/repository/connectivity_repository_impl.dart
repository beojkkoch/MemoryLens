import 'package:memorylens/features/connectivity/data/source/connectivity_data_source.dart';
import 'package:memorylens/features/connectivity/domain/repository/connectivity_repository.dart';
import 'package:memorylens/injection_container.dart';

class ConnectivityRepositoryImpl implements ConnectivityRepository {
  final ConnectivityDataSource _dataSource = sl();

  @override
  Stream<bool> watch() {
    return _dataSource.watch().distinct();
  }
}
