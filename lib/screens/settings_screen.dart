import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../services/file_download.dart';
import '../services/local_storage.dart';
import '../services/question_store.dart';
import '../services/question_transfer.dart';
import '../services/settings_store.dart';
import '../services/tts_service.dart';
import '../theme.dart';

/// 읽어주기 음성 설정. 값은 모두 이 브라우저에만 저장된다.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const String _sampleText =
      'Attention, passengers. Flight seven-two-four to Vancouver '
      'will begin boarding in approximately fifteen minutes at gate twelve.';

  late final TextEditingController _apiKey;
  bool _obscured = true;
  bool _testing = false;
  String? _testResult;
  bool _testFailed = false;
  int _cacheCount = 0;
  bool _transferring = false;

  @override
  void initState() {
    super.initState();
    _apiKey = TextEditingController(text: SettingsStore.instance.apiKey ?? '');
    _refreshCacheCount();
  }

  @override
  void dispose() {
    _apiKey.dispose();
    super.dispose();
  }

  Future<void> _refreshCacheCount() async {
    final int count = await LocalStorage.instance.ttsCacheCount();
    if (mounted) setState(() => _cacheCount = count);
  }

  Future<void> _saveKey() async {
    await SettingsStore.instance.setApiKey(_apiKey.text);
    if (!mounted) return;
    setState(() {
      _testResult = null;
      _testFailed = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          SettingsStore.instance.hasApiKey
              ? 'API 키를 저장했습니다. 이제 Google 음성으로 읽습니다.'
              : 'API 키를 지웠습니다. 브라우저 내장 음성으로 읽습니다.',
        ),
      ),
    );
  }

  /// 저장하지 않고 입력된 키로 바로 한 문장을 만들어 본다.
  Future<void> _test() async {
    final String key = _apiKey.text.trim();
    if (key.isEmpty) {
      setState(() {
        _testFailed = true;
        _testResult = 'API 키를 먼저 입력해 주세요.';
      });
      return;
    }

    setState(() {
      _testing = true;
      _testResult = null;
      _testFailed = false;
    });

    String? error;
    final Uint8List? audio = await TtsService.synthesize(
      text: _sampleText,
      apiKey: key,
      voice: SettingsStore.instance.voice,
      rate: TtsService.normalRate,
      onError: (String message) => error = message,
    );

    if (!mounted) return;
    setState(() {
      _testing = false;
      _testFailed = audio == null;
      _testResult =
          audio == null ? (error ?? '음성을 만들지 못했습니다.') : '성공했습니다. 아래에서 들어 보세요.';
    });

    if (audio != null) {
      await SettingsStore.instance.setApiKey(key);
      await TtsService.instance.speak(_sampleText);
      await _refreshCacheCount();
    }
  }

  Future<void> _exportQuestions() async {
    setState(() => _transferring = true);
    try {
      final List<QuestionBundle> bundles =
          await QuestionStore.instance.exportBundles();
      if (bundles.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('내보낼 문항이 없습니다. 먼저 문항을 등록해 주세요.')),
        );
        return;
      }
      final DateTime now = DateTime.now();
      downloadBytes(
        bytes: Uint8List.fromList(
          utf8.encode(QuestionTransfer.encode(bundles, exportedAt: now)),
        ),
        fileName: QuestionTransfer.fileName(now),
        mimeType: 'application/json',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('문항 ${bundles.length}개를 파일로 내보냈습니다.')),
      );
    } on Object catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('내보내기에 실패했습니다: $e')),
      );
    } finally {
      if (mounted) setState(() => _transferring = false);
    }
  }

  Future<void> _importQuestions() async {
    final PlatformFile? file;
    try {
      file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: <String>['json'],
        dialogTitle: '문항 파일 선택',
      );
    } on Object catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('파일을 열지 못했습니다: $e')),
      );
      return;
    }
    if (file == null) return;

    setState(() => _transferring = true);
    try {
      final Uint8List bytes = await file.readAsBytes();
      final ImportResult result = QuestionTransfer.decode(utf8.decode(bytes));

      if (!mounted) return;
      if (result.isFailure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.error!)),
        );
        return;
      }
      if (result.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('파일에 읽을 수 있는 문항이 없습니다.')),
        );
        return;
      }

      final ({int added, int replaced, int failed}) counts =
          await QuestionStore.instance.importBundles(result.bundles);

      if (!mounted) return;
      final List<String> parts = <String>[
        if (counts.added > 0) '새로 ${counts.added}개',
        if (counts.replaced > 0) '덮어쓰기 ${counts.replaced}개',
        if (counts.failed > 0) '실패 ${counts.failed}개',
        if (result.skipped > 0) '건너뜀 ${result.skipped}개',
      ];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('문항을 가져왔습니다 — ${parts.join(' · ')}')),
      );
    } on FormatException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('파일을 읽지 못했습니다. UTF-8 JSON 파일인지 확인해 주세요.')),
      );
    } on Object catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('가져오기에 실패했습니다: $e')),
      );
    } finally {
      if (mounted) setState(() => _transferring = false);
    }
  }

  Widget _questionBackupSection(ColorScheme scheme) {
    return AnimatedBuilder(
      animation: QuestionStore.instance,
      builder: (BuildContext context, Widget? _) {
        final int count = QuestionStore.instance.customQuestions.length;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              '내가 등록한 문항',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              '앱에서 등록한 문항은 이 브라우저에만 있습니다. 파일로 내보내 두면 '
              '백업하거나 다른 기기·다른 브라우저로 옮길 수 있습니다. '
              '사진과 예시 음성도 파일 하나에 같이 담깁니다.',
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '현재 $count개 등록됨',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                        _transferring || count == 0 ? null : _exportQuestions,
                    icon: const Icon(Icons.download_outlined, size: 18),
                    label: const Text('내보내기'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _transferring ? null : _importQuestions,
                    icon: const Icon(Icons.upload_outlined, size: 18),
                    label: const Text('가져오기'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '가져오기는 같은 문항(같은 id)이 있으면 덮어씁니다. '
              '기본 제공 문항은 영향을 받지 않습니다.',
              style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    const Color accent = AppTheme.seed;

    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: AnimatedBuilder(
        animation: Listenable.merge(
          <Listenable>[SettingsStore.instance, TtsService.instance],
        ),
        builder: (BuildContext context, Widget? _) {
          final SettingsStore settings = SettingsStore.instance;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: <Widget>[
              _EngineBanner(usingGoogle: settings.hasApiKey),
              const SizedBox(height: 20),
              const Text(
                'Google Cloud Text-to-Speech API 키',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                '키를 넣으면 사람 목소리에 가까운 Neural2 음성으로 읽어 줍니다. '
                '비우면 브라우저 내장 음성을 씁니다.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _apiKey,
                obscureText: _obscured,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(
                  labelText: 'API 키',
                  hintText: 'AIza...',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    tooltip: _obscured ? '보이기' : '가리기',
                    onPressed: () => setState(() => _obscured = !_obscured),
                    icon: Icon(
                      _obscured ? Icons.visibility_off : Icons.visibility,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _testing ? null : _test,
                      style: FilledButton.styleFrom(backgroundColor: accent),
                      icon: _testing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.play_arrow_rounded),
                      label: const Text('테스트하고 저장'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton(
                    onPressed: _testing ? null : _saveKey,
                    child: const Text('저장만'),
                  ),
                ],
              ),
              if (_testResult != null) ...<Widget>[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: _testFailed
                        ? scheme.errorContainer.withValues(alpha: 0.5)
                        : accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Icon(
                        _testFailed ? Icons.error_outline : Icons.check_circle,
                        size: 18,
                        color: _testFailed ? scheme.onErrorContainer : accent,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _testResult!,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: _testFailed
                                ? scheme.onErrorContainer
                                : scheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 26),
              const Text(
                '음성',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: settings.voice.name,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: kTtsVoices
                    .map(
                      (TtsVoice v) => DropdownMenuItem<String>(
                        value: v.name,
                        child: Text(v.label),
                      ),
                    )
                    .toList(),
                onChanged: (String? value) {
                  if (value != null) SettingsStore.instance.setVoice(value);
                },
              ),
              const SizedBox(height: 8),
              Text(
                '음성을 바꾸면 그 음성으로 새로 만들어야 하므로 한 번은 API 를 다시 부릅니다.',
                style:
                    TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 26),
              const Text(
                '저장된 음성',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                '한 번 만든 음성은 이 브라우저에 저장되어, 같은 지문을 다시 들을 때는 '
                'API 를 부르지 않습니다. 요금은 처음 만들 때 한 번만 발생합니다.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Text(
                    '현재 $_cacheCount개 저장됨',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _cacheCount == 0
                        ? null
                        : () async {
                            await LocalStorage.instance.clearTtsCache();
                            await _refreshCacheCount();
                          },
                    icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                    label: const Text('비우기'),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              _questionBackupSection(scheme),
              const SizedBox(height: 26),
              const _KeyGuide(),
            ],
          );
        },
      ),
    );
  }
}

class _EngineBanner extends StatelessWidget {
  const _EngineBanner({required this.usingGoogle});

  final bool usingGoogle;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    const Color accent = AppTheme.seed;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: usingGoogle
            ? accent.withValues(alpha: 0.1)
            : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            usingGoogle ? Icons.graphic_eq : Icons.record_voice_over_outlined,
            color: usingGoogle ? accent : scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  usingGoogle ? 'Google 음성 사용 중' : '브라우저 내장 음성 사용 중',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  usingGoogle
                      ? '자연스러운 Neural2 음성으로 읽습니다.'
                      : 'API 키를 넣으면 더 자연스러운 음성으로 바꿀 수 있습니다.',
                  style: TextStyle(
                    fontSize: 13,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KeyGuide extends StatelessWidget {
  const _KeyGuide();

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'API 키 만드는 법',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          const _Step(
              1,
              'Google Cloud 콘솔에서 프로젝트를 고릅니다. '
              'Firebase 프로젝트를 쓰고 있다면 그대로 쓰면 됩니다.'),
          const _Step(
              2,
              'API 및 서비스 → 라이브러리에서 '
              '"Cloud Text-to-Speech API" 를 켭니다.'),
          const _Step(
              3,
              'API 및 서비스 → 사용자 인증 정보 → 사용자 인증 정보 만들기 → '
              'API 키를 누릅니다.'),
          const _Step(
              4,
              '만든 키를 눌러 제한을 겁니다. '
              'API 제한은 Cloud Text-to-Speech API 만, '
              '애플리케이션 제한은 HTTP 리퍼러로 이 사이트 주소만 허용하세요.'),
          const _Step(5, '키를 복사해 위에 붙여넣고 "테스트하고 저장"을 누릅니다.'),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: scheme.errorContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  Icons.lock_outline,
                  size: 18,
                  color: scheme.onErrorContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '키는 이 브라우저에만 저장되고 어디로도 전송되지 않습니다. '
                    '다만 같은 브라우저를 쓰는 사람은 볼 수 있으니, 공용 PC 에서는 '
                    '쓰고 나서 키를 지워 주세요. 반드시 위 4번의 제한을 걸어 두세요.',
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.5,
                      color: scheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '요금: Neural2 음성은 월 100만 자까지 무료입니다. '
            '지문 하나가 400자 안팎이므로 한 달에 2,000개 넘게 만들어도 무료 한도 안입니다. '
            '게다가 한 번 만든 음성은 저장해 두므로 같은 지문은 다시 부르지 않습니다.',
            style: TextStyle(
              fontSize: 12.5,
              height: 1.5,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step(this.number, this.text);

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.seed.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$number',
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: AppTheme.seed,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13.5, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
