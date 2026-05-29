// services/store_service.dart — StoreService 대응 (IAP).
// Apple Developer 미가입 동안 로컬 시뮬레이션. 출시 시 in_app_purchase 로 교체
// (상품: solution_add_10 / time_add_10). 구매 성공 → UserCounts 증가.
import '../features/myinfo/info_providers.dart';

enum StoreProduct {
  solutionAdd10('solution_add_10', 'Solution x10', 10),
  timeAdd10('time_add_10', 'Time Add x10', 10);

  final String id;
  final String label;
  final int amount;
  const StoreProduct(this.id, this.label, this.amount);
}

class StoreService {
  final UserCountsNotifier counts;
  StoreService(this.counts);

  /// 로컬 시뮬 구매. TODO(출시): in_app_purchase 실제 결제로 교체.
  Future<bool> purchase(StoreProduct p) async {
    switch (p) {
      case StoreProduct.solutionAdd10:
        counts.addSolution(p.amount);
      case StoreProduct.timeAdd10:
        counts.addTimeAdd(p.amount);
    }
    return true;
  }
}
