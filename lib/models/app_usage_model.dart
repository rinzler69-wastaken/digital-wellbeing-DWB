class AppUsageModel {
  final String appName;
  final String packageName;
  final Duration totalTimeUsed;

  AppUsageModel({
    required this.appName,
    required this.packageName,
    required this.totalTimeUsed,
  });
}
