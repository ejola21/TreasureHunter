// features/design/mission_setup_page.dart — SwiftUI MissionSetupView.swift 1:1.
// FormGroup 기반 그룹 폼: 기본 정보 / 설명 / 플레이 제한 시간 / 플레이 설정 / 공개 설정 / 뱃지 / 검증 / 지도 진입.
import 'dart:typed_data';
import 'package:dio/dio.dart' show DioException;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../design_system/duo_tokens.dart';
import '../../game/mission_validator.dart';
import '../../models/item_type.dart';
import 'image_crop_page.dart';
import '../../design_system/form_group.dart';
import '../../models/game_state.dart';
import '../../models/mission.dart';
import '../../network/app_config.dart';
import '../../network/builder_mission_req.dart';
import 'builder_page.dart';
import 'design_providers.dart';

/// `mission == null` → 새 미션, otherwise → 미션 편집.
class MissionSetupPage extends ConsumerStatefulWidget {
  final Mission? mission;
  const MissionSetupPage({super.key, this.mission});

  @override
  ConsumerState<MissionSetupPage> createState() => _MissionSetupPageState();
}

class _MissionSetupPageState extends ConsumerState<MissionSetupPage> {
  late final TextEditingController _title;
  late final TextEditingController _place;
  late final TextEditingController _desc;
  late bool _limitEnabled;
  late int _limitH, _limitM, _limitS;
  late bool _virtual;
  late bool _published;
  late String _lang;
  Uint8List? _badgeBytes; // 새로 선택+크롭된 PNG bytes (저장 시 업로드)
  String? _badgeRemoteName;
  bool _detailLoading = false; // mission != null 일 때 fetchMissionDetail 진행 여부
  /// 편집 대상 Mission — widget.mission 이 있으면 그것, 없으면 새 Mission(id:'').
  /// BuilderPage 가 items 를 *참조로* 공유하므로, 빌더에서 placeItem 한 결과가 여기에 그대로 반영됨.
  late final Mission _mission;
  bool _dirty = false;
  bool _saving = false;

  bool get _isNew => widget.mission == null;
  int get _limitSeconds => _limitH * 3600 + _limitM * 60 + _limitS;
  bool get _hasBadge => _badgeBytes != null || (_badgeRemoteName != null && _badgeRemoteName!.isNotEmpty);

  /// SwiftUI MissionValidator 와 동일한 규칙 + 서버 not-blank 요구 (place).
  /// 디테일 로딩 중에는 빈 리스트 — items 가 아직 없어서 잘못된 경고가 뜨는 것 방지.
  List<ValidationError> get _validationErrors {
    if (_detailLoading) return const [];
    return MissionValidator.validate(
      title: _title.text,
      description: _desc.text,
      place: _place.text,
      items: _mission.items,
    );
  }
  bool get _canSave =>
      !_detailLoading && !MissionValidator.hasBlocking(_validationErrors);

  @override
  void initState() {
    super.initState();
    final m = widget.mission;
    // _mission 은 SwiftUI MissionBuilderViewModel.mission 과 동등 — 새 미션 시 id 빈 채로 시작.
    // BuilderPage 가 items 를 참조 공유하므로, 빌더 결과가 여기에 그대로 반영됨.
    _mission = m ?? Mission(id: '');
    _title = TextEditingController(text: m?.title ?? '')..addListener(_markDirty);
    _place = TextEditingController(text: m?.place ?? '')..addListener(_markDirty);
    _desc = TextEditingController(text: m?.description ?? '')..addListener(_markDirty);
    _limitEnabled = (m?.limitTime ?? 0) > 0;
    final s = (m?.limitTime ?? 0) > 0 ? m!.limitTime : 600;
    _limitH = s ~/ 3600;
    _limitM = (s % 3600) ~/ 60;
    _limitS = s % 60;
    _virtual = (m?.isVirtual ?? PlayMode.real) == PlayMode.virtual;
    _published = (m?.status ?? MissionStatus.unpublished) == MissionStatus.published;
    _lang = (m?.lang.isEmpty ?? true) ? 'ko' : m!.lang;
    _badgeRemoteName = m?.badgeImageName;
    // 편집 모드 — 디자인 리스트 API 는 items 를 안 줘서 items=[] 인 상태.
    // 검증 정확도를 위해 fetchMissionDetail 로 items+quizzes 채우기.
    if (m != null && m.id.isNotEmpty && m.items.isEmpty) {
      _loadDetail();
    }
  }

  Future<void> _loadDetail() async {
    setState(() => _detailLoading = true);
    try {
      final (mission, items, quizzes) =
          await ref.read(dataSourceProvider).fetchMissionDetail(widget.mission!.id);
      // Quiz 아이템에 변형 attach — validator 가 정확히 인식하도록.
      for (final it in items) {
        if (it.itemType == ItemType.quiz || it.itemType == ItemType.quiz20) {
          it.quizzes = quizzes.where((q) => q.itemID == it.itemID).toList();
        }
      }
      if (!mounted) return;
      setState(() {
        // _mission 객체에 items 채우기 (placeholder Mission 그대로 사용).
        _mission.items = items;
        // 서버가 보낸 최신 description/place/badge 로도 동기화 (텍스트 컨트롤러는 그대로 두되 placeholder 갱신).
        if (_desc.text.isEmpty && mission.description.isNotEmpty) {
          _desc.text = mission.description;
        }
        if (_place.text.isEmpty && mission.place.isNotEmpty) {
          _place.text = mission.place;
        }
        if ((_badgeRemoteName ?? '').isEmpty && (mission.badgeImageName ?? '').isNotEmpty) {
          _badgeRemoteName = mission.badgeImageName;
        }
        _detailLoading = false;
      });
    } catch (e) {
      debugPrint('mission detail load failed: $e');
      if (mounted) setState(() => _detailLoading = false);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _place.dispose();
    _desc.dispose();
    super.dispose();
  }

  void _markDirty() {
    // 매 변경마다 setState — 검증 카드/Save 버튼이 입력 즉시 반영되도록.
    if (mounted) setState(() => _dirty = true);
  }

  Future<bool> _onWillPop() async {
    if (!_dirty) return true;
    final res = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('변경사항을 저장하시겠습니까?'),
        content: Text(_canSave
            ? '‘저장 후 닫기’ 는 서버에 저장합니다.'
            : '필수 항목이 비어 있어 저장할 수 없습니다. 저장하지 않고 닫거나 계속 편집하세요.'),
        actions: [
          if (_canSave)
            TextButton(onPressed: () => Navigator.pop(ctx, 'save'), child: const Text('저장 후 닫기')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, 'discard'),
              child: const Text('저장 안 함', style: TextStyle(color: DuoColors.cardinal))),
          TextButton(onPressed: () => Navigator.pop(ctx, 'cancel'), child: const Text('취소')),
        ],
      ),
    );
    if (res == 'save') {
      final ok = await _save();
      return ok;
    }
    return res == 'discard';
  }

  Future<bool> _save() async {
    if (!_canSave) return false;
    setState(() => _saving = true);
    final m = _mission;
    m.title = _title.text.trim();
    m.place = _place.text.trim();
    m.description = _desc.text.trim();
    m.limitTime = _limitEnabled ? _limitSeconds : 0;
    m.isVirtual = _virtual ? PlayMode.virtual : PlayMode.real;
    m.status = _published ? MissionStatus.published : MissionStatus.unpublished;
    m.lang = _lang;

    try {
      final ds = ref.read(dataSourceProvider);
      // 1) 새로 선택한 뱃지 파일이 있으면 먼저 업로드 → 받은 URL/이름 으로 mission.badgeImageName 갱신.
      if (_badgeBytes != null) {
        try {
          // SwiftUI MissionBuilderViewModel.save() 1:1 — POST /api/v1/files/upload.
          // 응답 fileUrl (S3 https URL) 을 그대로 BadgeImageName 에 저장.
          final uploaded = await ds.uploadFile(
              _badgeBytes!, 'badge-${DateTime.now().millisecondsSinceEpoch}.png');
          if (uploaded != null && uploaded.isNotEmpty) {
            m.badgeImageName = uploaded;
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('뱃지 업로드 응답이 비어 있어 저장 중단')));
              setState(() => _saving = false);
            }
            return false;
          }
        } catch (e) {
          debugPrint('badge upload failed: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('뱃지 업로드 실패: $e\n다시 시도해주세요.')));
            setState(() => _saving = false);
          }
          return false;
        }
      } else {
        m.badgeImageName = _badgeRemoteName;
      }
      if (_isNew) {
        final id = await ds.createMission(BuilderMissionReq.fromMission(m));
        m.id = id;
      } else {
        await ds.updateMission(m.id, BuilderMissionReq.fromMission(m));
      }
      ref.invalidate(myDesignedProvider);
      if (!mounted) return true;
      if (_isNew) {
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => BuilderPage(missionID: m.id, initial: m)));
      } else {
        Navigator.of(context).pop(true);
      }
      return true;
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(_humanReadableError(e)),
            duration: const Duration(seconds: 5)));
      }
      return false;
    }
  }

  /// DioException 400 (VALIDATION_FAILED) 본문을 사용자 친화적 메시지로 변환.
  /// 서버 응답: `{"code":"VALIDATION_FAILED","message":"…","details":[{"field":"…","reason":"…"}]}`
  String _humanReadableError(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map) {
        final details = data['details'];
        if (details is List && details.isNotEmpty) {
          final lines = details
              .whereType<Map>()
              .map((d) => '• ${_fieldLabel(d['field']?.toString() ?? '')}: ${d['reason'] ?? ''}')
              .join('\n');
          return '저장 실패 — 다음을 확인하세요:\n$lines';
        }
        final msg = data['message']?.toString();
        if (msg != null && msg.isNotEmpty) return '저장 실패: $msg';
      }
      return '저장 실패 (${e.response?.statusCode ?? '?'}): ${e.message ?? ''}';
    }
    return '저장 실패: $e';
  }

  String _fieldLabel(String field) => switch (field) {
        'mission.title' => '미션 제목',
        'mission.description' => '미션 설명',
        'mission.place' => '미션 장소',
        'mission.limitTime' => '제한 시간',
        'mission.lang' => '언어',
        'items' => '아이템 목록',
        _ => field.replaceFirst('mission.', '').replaceFirst('items.', '아이템 '),
      };

  Future<void> _autoFillPlace() async {
    // geocoding 패키지 미설치. 좌표 기반 reverse geocoding 은 후속 작업으로.
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('좌표 → 장소 자동 채우기는 곧 지원 예정')));
  }

  Future<void> _pickBadge() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final picker = ImagePicker();
      final x = await picker.pickImage(
          source: ImageSource.gallery, maxWidth: 1600, imageQuality: 90);
      if (x == null) {
        messenger.showSnackBar(const SnackBar(
            content: Text('이미지를 선택하지 않았습니다.')));
        return;
      }
      final raw = await x.readAsBytes();
      if (!mounted) return;
      // SwiftUI ImageCropView 1:1 — 1:1 정사각 크롭 페이지 진입.
      final cropped = await Navigator.of(context).push<Uint8List?>(MaterialPageRoute(
          fullscreenDialog: true, builder: (_) => ImageCropPage(imageBytes: raw)));
      if (cropped == null) {
        messenger.showSnackBar(const SnackBar(content: Text('크롭 취소됨')));
        return;
      }
      if (!mounted) return;
      setState(() {
        _badgeBytes = cropped;
        _markDirty();
      });
      messenger.showSnackBar(const SnackBar(
          content: Text('이미지 크롭됨 — 저장을 누르면 업로드됩니다.'),
          duration: Duration(seconds: 2)));
    } catch (e) {
      // PlatformException 등 — 플랫폼 채널 실패 시 사용자가 원인을 알 수 있도록.
      debugPrint('image_picker error: $e');
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('이미지 선택 실패: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final canPopReady = !_dirty;
    return PopScope(
      canPop: canPopReady,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final ok = await _onWillPop();
        if (ok && mounted) Navigator.of(this.context).pop();
      },
      child: Scaffold(
        backgroundColor: DuoColors.snow,
        appBar: AppBar(
          backgroundColor: DuoColors.snow,
          elevation: 0,
          leading: TextButton(
            onPressed: _saving
                ? null
                : () async {
                    final ok = await _onWillPop();
                    if (ok && mounted) Navigator.of(this.context).pop();
                  },
            child: const Text('취소',
                style: TextStyle(color: DuoColors.macaw, fontFamily: DuoFonts.display)),
          ),
          leadingWidth: 72,
          actions: [
            TextButton(
              onPressed: (_canSave && !_saving) ? _save : null,
              child: Text('저장',
                  style: TextStyle(
                      color: _canSave ? DuoColors.macaw : DuoColors.hare,
                      fontFamily: DuoFonts.display,
                      fontWeight: FontWeight.w900)),
            ),
          ],
          centerTitle: true,
        ),
        body: Stack(children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 12),
                child: Text(_isNew ? '새 미션' : '미션 편집',
                    style: const TextStyle(
                        fontFamily: DuoFonts.display, fontSize: 28, color: DuoColors.eel2)),
              ),
              FormGroup(title: '기본 정보', children: [
                _kickerTextRow(label: '미션 제목', controller: _title, hint: '예: 강남역 추리극'),
                _rowDivider,
                _kickerTextRow(label: '장소', controller: _place, hint: '예: 강남역 11번 출구'),
                _rowDivider,
                _autoFillRow(),
              ]),
              const SizedBox(height: 20),
              FormGroup(title: '설명', children: [
                _multiLineEditor(_desc, minHeight: 100),
              ]),
              const SizedBox(height: 20),
              _limitGroup(),
              const SizedBox(height: 20),
              FormGroup(title: '플레이 설정', children: [
                _toggleRow(
                  label: 'Virtual 모드 허용',
                  value: _virtual,
                  onChanged: (v) => setState(() {
                    _virtual = v;
                    _markDirty();
                  }),
                ),
                _rowDivider,
                _languageRow(),
              ]),
              const SizedBox(height: 20),
              FormGroup(
                title: '공개 설정',
                subtitle: _published
                    ? '다른 사용자가 Missions 탭에서 플레이할 수 있습니다.'
                    : '비공개 — 내 디자인 목록에만 보이고 Missions 탭에는 노출되지 않습니다.',
                children: [
                  _toggleRow(
                    label: '공개 (Missions 탭에 노출)',
                    value: _published,
                    onChanged: (v) => setState(() {
                      _published = v;
                      _markDirty();
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              FormGroup(title: '뱃지 이미지', children: [
                Padding(padding: const EdgeInsets.all(14), child: _badgeBlock()),
              ]),
              const SizedBox(height: 16),
              if (_validationErrors.isNotEmpty) _validationCard(),
              const SizedBox(height: 12),
              _mapEntryButton(),
              const SizedBox(height: 24),
            ],
          ),
          if (_saving) _progressOverlay('저장 중…'),
          if (_detailLoading) _progressOverlay('아이템 불러오는 중…'),
        ]),
      ),
    );
  }

  // ─── 행 헬퍼들 ───

  Widget _kickerTextRow(
      {required String label, required TextEditingController controller, required String hint}) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Text(label.toUpperCase(),
            style: const TextStyle(
                fontFamily: DuoFonts.display, fontSize: 11, letterSpacing: 0.6, color: DuoColors.hare)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: DuoColors.eel2),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: DuoColors.hare),
            border: InputBorder.none,
            isCollapsed: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 4),
          ),
        ),
      ]),
    );
  }

  Widget _multiLineEditor(TextEditingController controller, {double minHeight = 100}) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: minHeight),
        child: TextField(
          controller: controller,
          maxLines: null,
          minLines: 4,
          style: const TextStyle(fontSize: 14, color: DuoColors.eel2),
          decoration: const InputDecoration(border: InputBorder.none, isCollapsed: true),
        ),
      ),
    );
  }

  Widget _autoFillRow() {
    final hasItems = _mission.items.isNotEmpty;
    final tint = hasItems ? DuoColors.macaw : DuoColors.hare;
    return InkWell(
      onTap: hasItems ? _autoFillPlace : null,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          Icon(Icons.travel_explore, size: 14, color: tint),
          const SizedBox(width: 8),
          Text('좌표로 장소 자동 채우기',
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.bold, color: tint)),
          const Spacer(),
          Icon(Icons.arrow_forward, size: 12, color: tint),
        ]),
      ),
    );
  }

  Widget _toggleRow({required String label, required bool value, required ValueChanged<bool> onChanged}) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600, color: DuoColors.eel2))),
        Switch.adaptive(
            activeThumbColor: DuoColors.green500, value: value, onChanged: onChanged),
      ]),
    );
  }

  Widget _languageRow() {
    return InkWell(
      onTap: () async {
        final v = await showModalBottomSheet<String>(
          context: context,
          builder: (_) => SafeArea(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              ListTile(
                title: const Text('한국어'),
                trailing: _lang == 'ko' ? const Icon(Icons.check, color: DuoColors.macaw) : null,
                onTap: () => Navigator.pop(context, 'ko'),
              ),
              ListTile(
                title: const Text('English'),
                trailing: _lang == 'en' ? const Icon(Icons.check, color: DuoColors.macaw) : null,
                onTap: () => Navigator.pop(context, 'en'),
              ),
            ]),
          ),
        );
        if (v != null) setState(() { _lang = v; _markDirty(); });
      },
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          const Expanded(
              child: Text('언어',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: DuoColors.eel2))),
          Text(_lang == 'ko' ? '한국어' : 'English',
              style: const TextStyle(fontSize: 14, color: DuoColors.macaw, fontWeight: FontWeight.w700)),
          const SizedBox(width: 6),
          const Icon(Icons.unfold_more, size: 16, color: DuoColors.macaw),
        ]),
      ),
    );
  }

  Widget _limitGroup() {
    return FormGroup(
      title: '플레이 제한 시간',
      subtitle: _limitEnabled
          ? '플레이 중 남은 시간이 표시되고, 시간이 초과되면 미션이 종료됩니다.'
          : '시간 제한 없음 — 경과 시간만 표시됩니다.',
      children: [
        _toggleRow(
          label: '시간 제한',
          value: _limitEnabled,
          onChanged: (v) => setState(() {
            _limitEnabled = v;
            _markDirty();
          }),
        ),
        if (_limitEnabled) ...[
          _rowDivider,
          SizedBox(height: 130, child: _limitWheels()),
        ],
      ],
    );
  }

  Widget _limitWheels() {
    Widget col(int value, int max, String suffix, ValueChanged<int> onChanged) {
      return Expanded(
        child: Column(children: [
          Expanded(
            child: CupertinoPicker(
              itemExtent: 32,
              scrollController: FixedExtentScrollController(initialItem: value),
              onSelectedItemChanged: onChanged,
              children: [
                for (int i = 0; i < max; i++)
                  Center(
                      child: Text(i.toString().padLeft(2, '0'),
                          style: const TextStyle(fontSize: 18, color: DuoColors.eel2))),
              ],
            ),
          ),
          Text(suffix,
              style: const TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w600, color: DuoColors.hare)),
        ]),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        col(_limitH, 24, '시', (i) => setState(() { _limitH = i; _markDirty(); })),
        const Text(':',
            style: TextStyle(fontFamily: DuoFonts.display, fontSize: 22, color: DuoColors.hare)),
        col(_limitM, 60, '분', (i) => setState(() { _limitM = i; _markDirty(); })),
        const Text(':',
            style: TextStyle(fontFamily: DuoFonts.display, fontSize: 22, color: DuoColors.hare)),
        col(_limitS, 60, '초', (i) => setState(() { _limitS = i; _markDirty(); })),
      ]),
    );
  }

  Widget _badgeBlock() {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _badgePreview(),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(
          child: SizedBox(
            height: 36,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                  backgroundColor: DuoColors.macaw,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: _pickBadge,
              icon: const Icon(Icons.add_photo_alternate, size: 14, color: Colors.white),
              label: Text(_hasBadge ? '이미지 변경' : '이미지 선택',
                  style: const TextStyle(
                      fontFamily: DuoFonts.display, fontSize: 12, color: Colors.white, letterSpacing: 0.6)),
            ),
          ),
        ),
        if (_hasBadge) ...[
          const SizedBox(width: 10),
          SizedBox(
            height: 36,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                  backgroundColor: DuoColors.cardinal,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () => setState(() {
                _badgeBytes = null;
                _badgeRemoteName = null;
                _markDirty();
              }),
              icon: const Icon(Icons.delete_outline, size: 14, color: Colors.white),
              label: const Text('제거',
                  style: TextStyle(
                      fontFamily: DuoFonts.display, fontSize: 12, color: Colors.white, letterSpacing: 0.6)),
            ),
          ),
        ],
      ]),
    ]);
  }

  Widget _badgePreview() {
    Widget content;
    if (_badgeBytes != null) {
      content = Image.memory(_badgeBytes!, fit: BoxFit.contain);
    } else if (_badgeRemoteName != null && _badgeRemoteName!.isNotEmpty) {
      // Mission.badgeImageUrl 헬퍼와 동일 규칙 (http 스킴이면 그대로, 아니면 baseURL prefix).
      final name = _badgeRemoteName!;
      final url = (name.startsWith('http://') || name.startsWith('https://'))
          ? name
          : 'http://43.201.188.35:8080/playspot/badge/$name';
      content = Image.network(url,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => _badgeEmpty(error: true));
    } else {
      content = _badgeEmpty();
    }
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: DuoColors.snow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: DuoColors.swan, width: 1.5),
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(10), child: Center(child: content)),
    );
  }

  Widget _badgeEmpty({bool error = false}) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(error ? Icons.broken_image : Icons.add_photo_alternate, size: 36, color: DuoColors.hare),
      const SizedBox(height: 6),
      Text(error ? '이미지를 불러올 수 없어요' : '뱃지 미설정',
          style: const TextStyle(fontSize: 11, color: DuoColors.hare)),
    ]);
  }

  /// SwiftUI MissionSetupView.validationCard 이식. blocking → cardinal / 경고 → fox.
  Widget _validationCard() {
    final errs = _validationErrors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DuoColors.cardinalBg.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DuoColors.cardinal, width: 1.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('검증',
            style: TextStyle(
                fontFamily: DuoFonts.display,
                fontSize: 11,
                letterSpacing: 0.6,
                color: DuoColors.cardinalDeep)),
        const SizedBox(height: 6),
        for (final e in errs)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(e.isBlocking ? Icons.warning_amber : Icons.info_outline,
                  size: 14,
                  color: e.isBlocking ? DuoColors.cardinalDeep : DuoColors.foxDeep),
              const SizedBox(width: 6),
              Expanded(
                  child: Text(e.message,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: e.isBlocking ? DuoColors.cardinalDeep : DuoColors.foxDeep))),
            ]),
          ),
      ]),
    );
  }

  Widget _mapEntryButton() {
    // SwiftUI MissionSetupView 와 동일 — 새 미션이라도 항상 진입 가능.
    // _mission 을 BuilderPage 에 *참조 공유* 로 넘기므로, 빌더에서 placeItem 한 결과가
    // 부모(_mission.items) 에 즉시 반영되어 검증 카드가 갱신됨.
    return Stack(children: [
      Container(
        height: 48 + 4,
        margin: const EdgeInsets.only(top: 4),
        decoration: BoxDecoration(
          color: DuoColors.beetleDeep,
          borderRadius: BorderRadius.circular(DuoRadius.lg),
        ),
      ),
      Material(
        color: DuoColors.beetle,
        borderRadius: BorderRadius.circular(DuoRadius.lg),
        child: InkWell(
          borderRadius: BorderRadius.circular(DuoRadius.lg),
          onTap: () async {
            await Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => BuilderPage(missionID: _mission.id, initial: _mission)));
            // 빌더에서 _mission.items 가 갱신됐을 수 있음 → 검증 카드 재평가.
            if (mounted) setState(() {});
          },
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(children: [
              const Icon(Icons.map, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              const Text('아이템 배치 (지도 진입)',
                  style: TextStyle(
                      fontFamily: DuoFonts.display, fontSize: 14, color: Colors.white, letterSpacing: 0.84)),
              const Spacer(),
              const Icon(Icons.arrow_forward, color: Colors.white, size: 14),
            ]),
          ),
        ),
      ),
    ]);
  }

  Widget _progressOverlay(String label) {
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black26,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const CircularProgressIndicator(strokeWidth: 2, color: DuoColors.macaw),
              const SizedBox(width: 12),
              Text(label,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: DuoColors.eel)),
            ]),
          ),
        ),
      ),
    );
  }

  Widget get _rowDivider =>
      Container(height: 1, margin: const EdgeInsets.only(left: 14), color: DuoColors.swan);
}
