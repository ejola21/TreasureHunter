// heading_sample.dart — 플랫폼 공용 heading 모델.
class HeadingSample {
  final double heading; // 0~360, 진북 기준
  final String source; // 'webkitCompass' | 'alpha' | 'flutter_compass' | 'mock'
  const HeadingSample(this.heading, this.source);
}
