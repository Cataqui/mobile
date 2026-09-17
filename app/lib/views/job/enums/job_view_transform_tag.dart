enum JobViewTransformTag {
  surface,
  header;

  String valueFor({required String jobId}) {
    return switch (this) {
      JobViewTransformTag.surface => 'job-$jobId-surface',
      JobViewTransformTag.header => 'job-$jobId-header',
    };
  }
}
