/// Something the Analizando screen asks the PhotoAnalysisBloc to do.
abstract class PhotoAnalysisEvent {}

/// The import is over: describe the photos with the AI.
class PhotoAnalysisStarted extends PhotoAnalysisEvent {
  @override
  String toString() {
    return 'PhotoAnalysisStarted()';
  }
}

/// The person pressed «Reintentar» after the analysis failed.
class PhotoAnalysisRetried extends PhotoAnalysisEvent {
  @override
  String toString() {
    return 'PhotoAnalysisRetried()';
  }
}
