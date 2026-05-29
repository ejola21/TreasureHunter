// features/design/design_list_page.dart — 디자인 탭 (Phase 3 에서 구현).
import 'package:flutter/material.dart';
import '../../design_system/duo_tokens.dart';

class DesignListPage extends StatelessWidget {
  const DesignListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('내 디자인')),
      body: const Center(
        child: Text(
          '디자인 탭 (Phase 3)',
          style: TextStyle(color: DuoColors.hare, fontSize: 16),
        ),
      ),
    );
  }
}
