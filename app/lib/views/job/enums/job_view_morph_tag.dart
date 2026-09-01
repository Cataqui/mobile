enum JobViewMorphTag {
  surface,
  header,
  edgeFade;

  String valueFor({required String jobId}) {
    return switch (this) {
      JobViewMorphTag.surface => 'job-$jobId-surface',
      JobViewMorphTag.header => 'job-$jobId-header',
      JobViewMorphTag.edgeFade => 'job-$jobId-edge-fade',
    };
  }
}
