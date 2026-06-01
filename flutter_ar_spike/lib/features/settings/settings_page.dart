// features/settings/settings_page.dart — SwiftUI SettingsView.swift 1:1 이식.
// 그룹 순서: ACCOUNT / API BACKEND / [DEBUG 401 시뮬] / GUIDE / ABOUT / [REDESIGN PREVIEW]
// 배경 duoSnow. 본문 시작 헤더 "Settings"(duoDisplay 28). AppBar 없음.
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../design_system/candy_button.dart';
import '../../design_system/duo_tokens.dart';
import '../../design_system/form_group.dart';
import '../../design_system/seg_btn_pair.dart';
import '../../network/app_config.dart';
import '../../network/rest_api_client.dart';
import '../help/help_root.dart';
import '../tutorial/tutorial_view.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  // pubspec.yaml 1.0.0+1 → version "1.0.0", build "1"
  static const _appVersion = '1.0.0';
  static const _appBuild = '1';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(authSessionProvider).userId ?? '-';
    final isGuest = userId.startsWith('Guest@') || userId == '-';
    final backend = ref.watch(backendProvider);

    return Scaffold(
      backgroundColor: DuoColors.snow,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // 본문 헤더 "Settings" — AppBar 대신.
            const Padding(
              padding: EdgeInsets.only(top: 4, bottom: 16),
              child: Text('Settings',
                  style: TextStyle(fontFamily: DuoFonts.display, fontSize: 28, color: DuoColors.eel2)),
            ),

            // ACCOUNT.
            FormGroup(title: 'ACCOUNT', children: [
              FormRow(label: 'User ID', value: userId, muted: true),
              if (isGuest)
                FormRow(
                  label: 'Login',
                  isLast: true,
                  trailing: const Icon(Icons.chevron_right, size: 18, color: DuoColors.macaw),
                  onTap: () => _showLogin(context, ref),
                )
              else
                FormRow(
                  label: 'Logout',
                  isLast: true,
                  trailing: const Icon(Icons.chevron_right, size: 18, color: DuoColors.cardinal),
                  onTap: () => _confirmLogout(context, ref),
                ),
            ]),
            const SizedBox(height: 20),

            // API BACKEND.
            FormGroup(
              title: 'API BACKEND',
              subtitle: 'REST 로 전환 시 다음 호출부터 /api/v1/** 사용. 재로그인 필요.',
              children: [
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(children: [
                    const Text('Backend',
                        style: TextStyle(fontFamily: DuoFonts.display, fontSize: 15, color: DuoColors.eel)),
                    const Spacer(),
                    SizedBox(
                      width: 180,
                      child: SegBtnPair<APIBackend>(
                        selection: backend,
                        options: const [(APIBackend.legacy, 'Legacy'), (APIBackend.rest, 'REST')],
                        onChanged: (v) async {
                          if (v == APIBackend.legacy) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                              content: Text('Legacy 백엔드는 Flutter 에서 아직 미구현 — REST 유지'),
                              duration: Duration(seconds: 2),
                            ));
                            return;
                          }
                          ref.read(backendProvider.notifier).state = v;
                          await ref.read(authSessionProvider).reset();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('백엔드 REST · 토큰 초기화')));
                          }
                        },
                      ),
                    ),
                  ]),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // DEBUG — 401 시뮬 (개발 빌드 한정).
            if (kDebugMode) ...[
              FormGroup(
                title: 'DEBUG — 401 자동 재로그인 검증',
                subtitle: "Console 로그에서 'auto re-login' 출력 확인.",
                children: [
                  FormRow(
                    label: 'Simulate 401: token 손상 + fetch 시도',
                    isLast: true,
                    trailing: const Icon(Icons.chevron_right, size: 18, color: DuoColors.macaw),
                    onTap: () async {
                      await ref.read(authSessionProvider).setToken('invalid_test_token');
                      try {
                        await ref.read(dataSourceProvider).fetchMissionList();
                      } catch (_) {}
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('401 시뮬 호출 보냈음 — 콘솔 확인')));
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],

            // GUIDE · 가이드.
            FormGroup(title: 'GUIDE · 가이드', children: [
              FormRow(
                label: 'Tutorial · 튜토리얼',
                trailing: const Icon(Icons.chevron_right, size: 18, color: DuoColors.macaw),
                onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const TutorialView(), fullscreenDialog: true)),
              ),
              FormRow(
                label: 'Help · 아이템 도움말',
                isLast: true,
                trailing: const Icon(Icons.chevron_right, size: 18, color: DuoColors.macaw),
                onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const HelpRoot(), fullscreenDialog: true)),
              ),
            ]),
            const SizedBox(height: 20),

            // ABOUT.
            const FormGroup(title: 'ABOUT', children: [
              FormRow(label: 'Version', value: _appVersion, muted: true),
              FormRow(label: 'Build', value: _appBuild, muted: true, isLast: true),
            ]),
            const SizedBox(height: 20),

            // REDESIGN — DEBUG (개발 빌드 한정).
            if (kDebugMode) ...[
              FormGroup(title: 'REDESIGN — PHASE 1/2 PREVIEW', children: [
                FormRow(
                  label: 'Design System Catalog',
                  trailing: const Icon(Icons.chevron_right, size: 18, color: DuoColors.macaw),
                  onTap: () => _showComingSoon(context, 'Design System Catalog'),
                ),
                FormRow(
                  label: 'AR Search Demo',
                  isLast: true,
                  trailing: const Icon(Icons.chevron_right, size: 18, color: DuoColors.macaw),
                  onTap: () => _showComingSoon(context, 'AR Search Demo'),
                ),
              ]),
              const SizedBox(height: 24),
            ],
          ]),
        ),
      ),
    );
  }

  void _showLogin(BuildContext context, WidgetRef ref) {
    // 시트가 닫혀도 살아있는 부모 ScaffoldMessenger 를 미리 캡처해서 전달.
    final messenger = ScaffoldMessenger.of(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: _LoginSheet(parentRef: ref, messenger: messenger),
      ),
    );
  }

  /// SwiftUI: `.alert("로그아웃 하시겠어요?", ...)` 취소 + 로그아웃(destructive).
  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('로그아웃 하시겠어요?', style: TextStyle(fontFamily: DuoFonts.display)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authSessionProvider).reset();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('로그아웃됨 — 다음 실행 시 새 게스트')));
              }
            },
            style: TextButton.styleFrom(foregroundColor: DuoColors.cardinal),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context, String name) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$name — 곧 추가됩니다')));
  }
}

/// SwiftUI LoginView 의 핵심 — Email + Password + Login 버튼.
class _LoginSheet extends StatefulWidget {
  final WidgetRef parentRef;
  /// 시트가 닫힌 후에도 살아있는 부모 Scaffold 의 messenger.
  final ScaffoldMessengerState messenger;
  const _LoginSheet({required this.parentRef, required this.messenger});

  @override
  State<_LoginSheet> createState() => _LoginSheetState();
}

class _LoginSheetState extends State<_LoginSheet> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _autoLogin = true; // 기본 ON — 다음 앱 실행 시 자격증명으로 자동 재로그인
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final e = _email.text.trim();
    final p = _password.text;
    if (e.isEmpty || p.isEmpty) {
      setState(() => _error = '이메일과 비밀번호를 입력하세요');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final ds = widget.parentRef.read(dataSourceProvider);
      // 10초 타임아웃 — 서버 무응답 시 무한 대기 방지.
      final ok = await ds.login(e, p).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          if (mounted) setState(() => _error = '서버 응답 없음 (10초 타임아웃)');
          return false;
        },
      );
      if (!mounted) return;
      if (ok) {
        // _autoLogin 해제 시: 토큰만 유지하고 자격증명 삭제 → 다음 앱 실행에 자동 로그인 X.
        if (!_autoLogin) {
          await widget.parentRef.read(authSessionProvider).clearStoredCredentials();
        }
        if (!mounted) return;
        // 시트 닫기 → 그 다음 부모 messenger 로 snackbar (popped context 회피).
        Navigator.pop(context);
        widget.messenger.showSnackBar(const SnackBar(content: Text('로그인 성공')));
      } else if (_error == null) {
        setState(() => _error = '로그인 실패 — 이메일/비밀번호 확인');
      }
    } catch (err) {
      if (mounted) setState(() => _error = '오류: $err');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// SwiftUI LoginView "Create Account · 회원가입" 분기 — register → 자동 login.
  Future<void> _register() async {
    final e = _email.text.trim();
    final p = _password.text;
    if (e.isEmpty || p.isEmpty) {
      setState(() => _error = '이메일과 비밀번호를 입력하세요');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final ds = widget.parentRef.read(dataSourceProvider);
      final regOk = await ds.register(e, p).timeout(const Duration(seconds: 10), onTimeout: () => false);
      if (!regOk) {
        if (mounted) setState(() => _error = '회원가입 실패 (이미 가입된 이메일일 수 있어요)');
        return;
      }
      final loginOk = await ds.login(e, p).timeout(const Duration(seconds: 10), onTimeout: () => false);
      if (!mounted) return;
      if (loginOk) {
        if (!_autoLogin) {
          await widget.parentRef.read(authSessionProvider).clearStoredCredentials();
        }
        if (!mounted) return;
        Navigator.pop(context);
        widget.messenger.showSnackBar(const SnackBar(content: Text('회원가입 + 로그인 완료')));
        return;
      } else {
        setState(() => _error = '가입은 됐지만 로그인 실패');
      }
    } catch (err) {
      if (mounted) setState(() => _error = '오류: $err');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// SwiftUI LoginView "Continue as Guest" 분기 — 세션 reset → bootstrap 으로 새 게스트 발급.
  Future<void> _continueAsGuest() async {
    setState(() { _loading = true; _error = null; });
    try {
      final auth = widget.parentRef.read(authSessionProvider);
      await auth.reset();
      await widget.parentRef.read(authBootstrapProvider).ensureAuthenticated();
      if (!mounted) return;
      Navigator.pop(context);
      widget.messenger.showSnackBar(const SnackBar(content: Text('새 게스트로 시작')));
    } catch (err) {
      if (mounted) setState(() => _error = '게스트 시작 실패: $err');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('SIGN IN · 로그인',
            style: TextStyle(fontFamily: DuoFonts.display, fontSize: 12, color: DuoColors.macaw, letterSpacing: 1.5)),
        const SizedBox(height: 4),
        const Text('환영합니다!',
            style: TextStyle(fontFamily: DuoFonts.display, fontSize: 24, color: DuoColors.eel2)),
        const SizedBox(height: 18),
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          textCapitalization: TextCapitalization.none,
          decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _password,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
          onSubmitted: (_) => _submit(),
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: DuoColors.cardinalBg, borderRadius: BorderRadius.circular(20)),
            child: Row(children: [
              const Icon(Icons.warning_amber_rounded, color: DuoColors.cardinalDeep, size: 16),
              const SizedBox(width: 6),
              Expanded(child: Text(_error!, style: const TextStyle(color: DuoColors.cardinalDeep, fontSize: 12))),
            ]),
          ),
        ],
        const SizedBox(height: 8),
        // 자동 로그인 체크박스 — ON 시 다음 앱 실행 때 저장된 자격증명으로 자동 재로그인.
        GestureDetector(
          onTap: () => setState(() => _autoLogin = !_autoLogin),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(children: [
              SizedBox(
                width: 24, height: 24,
                child: Checkbox(
                  value: _autoLogin,
                  activeColor: DuoColors.macaw,
                  onChanged: (v) => setState(() => _autoLogin = v ?? true),
                ),
              ),
              const SizedBox(width: 8),
              const Text('자동 로그인 (다음 앱 실행 시 유지)',
                  style: TextStyle(fontSize: 13, color: DuoColors.eel)),
            ]),
          ),
        ),
        const SizedBox(height: 8),
        CandyButton(
          label: _loading ? '로그인 중...' : 'Login · 로그인',
          tint: DuoColors.macaw, shadowColor: DuoColors.macawDeep,
          onPressed: _loading ? null : _submit,
        ),
        const SizedBox(height: 12),
        // OR 구분선 — SwiftUI 동일.
        Row(children: const [
          Expanded(child: Divider(color: DuoColors.swan, height: 1, thickness: 1)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Text('OR',
                style: TextStyle(fontFamily: DuoFonts.display, fontSize: 10, letterSpacing: 0.66, color: DuoColors.hare)),
          ),
          Expanded(child: Divider(color: DuoColors.swan, height: 1, thickness: 1)),
        ]),
        const SizedBox(height: 12),
        // Create Account · 회원가입 — 초록 candy.
        CandyButton(
          label: 'Create Account · 회원가입',
          tint: DuoColors.green500, shadowColor: DuoColors.green700,
          onPressed: _loading ? null : _register,
        ),
        const SizedBox(height: 8),
        // Continue as Guest · 게스트로 시작 — 텍스트 버튼.
        TextButton(
          onPressed: _loading ? null : _continueAsGuest,
          child: const Text('Continue as Guest · 게스트로 시작',
              style: TextStyle(fontSize: 14, color: DuoColors.hare, fontWeight: FontWeight.w600)),
        ),
        // Server 표시 (현재 백엔드).
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text('서버: ${RestApiClient.baseUrl.replaceFirst(RegExp(r'^https?://'), '')}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: DuoColors.hare)),
        ),
      ]),
    );
  }
}
