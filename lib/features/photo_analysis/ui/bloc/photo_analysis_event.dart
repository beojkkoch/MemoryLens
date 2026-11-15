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

/// The person pressed «Reintentar» to analyze again only the photos
/// «No analizada» (HU-10, CA8).
class PhotoAnalysisFailedPhotosRetried extends PhotoAnalysisEvent {
  @override
  String toString() {
    return 'PhotoAnalysisFailedPhotosRetried()';
  }
}
