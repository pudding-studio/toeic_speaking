import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/question.dart';
import '../models/toeic_part.dart';
import '../services/question_store.dart';
import '../services/sample_audio_service.dart';
import '../theme.dart';

/// 앱에서 직접 문항을 등록/수정하는 화면.
/// 파트에 따라 필요한 입력만 보여 준다.
class QuestionEditorScreen extends StatefulWidget {
  const QuestionEditorScreen({super.key, required this.partId, this.existing});

  final PartId partId;

  /// 수정할 문항. null 이면 새로 등록한다.
  final Question? existing;

  @override
  State<QuestionEditorScreen> createState() => _QuestionEditorScreenState();
}

class _QuestionEditorScreenState extends State<QuestionEditorScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _title;
  late final TextEditingController _passage;
  late final TextEditingController _scenePlace;
  late final TextEditingController _sceneDetails;
  late final TextEditingController _sampleAnswer;
  late final TextEditingController _keyExpressions;
  late final TextEditingController _tableTitle;
  late final TextEditingController _tableSubtitle;

  final List<_PromptFields> _prompts = <_PromptFields>[];
  final List<_TableRowFields> _rows = <_TableRowFields>[];

  Uint8List? _imageBytes;

  /// 새로 고른 예시 음성. null 이면 기존 것을 그대로 둔다.
  Uint8List? _audioBytes;
  String? _audioName;

  /// 저장돼 있던 예시 음성을 지울지.
  bool _removeAudio = false;

  /// 수정 중인 문항에 이미 예시 음성이 붙어 있는지.
  bool _hadAudio = false;

  bool _saving = false;

  bool get _hasAudio => _audioBytes != null || (_hadAudio && !_removeAudio);

  ToeicPart get _part => partById(widget.partId);
  Color get _color => AppTheme.partColor(widget.partId);
  bool get _isEditing => widget.existing != null;

  bool get _needsPassage => widget.partId == PartId.readAloud;
  bool get _needsImage => widget.partId == PartId.describePicture;
  bool get _needsTable => widget.partId == PartId.respondWithInfo;
  bool get _needsPrompts =>
      widget.partId != PartId.readAloud &&
      widget.partId != PartId.describePicture;

  @override
  void initState() {
    super.initState();
    final Question? q = widget.existing;

    _title = TextEditingController(text: q?.title ?? '');
    _passage = TextEditingController(text: q?.passage ?? '');
    _scenePlace = TextEditingController(text: q?.scene?.place ?? '');
    _sceneDetails =
        TextEditingController(text: q?.scene?.details.join('\n') ?? '');
    _sampleAnswer = TextEditingController(text: q?.sampleAnswer ?? '');
    _keyExpressions =
        TextEditingController(text: q?.keyExpressions.join('\n') ?? '');
    _tableTitle = TextEditingController(text: q?.table?.title ?? '');
    _tableSubtitle = TextEditingController(text: q?.table?.subtitle ?? '');

    if (_needsTable) {
      final List<List<String>> rows = q?.table?.rows ?? const <List<String>>[];
      if (rows.isEmpty) {
        _rows.addAll(<_TableRowFields>[_TableRowFields(), _TableRowFields()]);
      } else {
        _rows.addAll(rows.map(_TableRowFields.from));
      }
    }

    if (_needsPrompts) {
      final List<Prompt> existing = q?.prompts ?? const <Prompt>[];
      if (existing.isEmpty) {
        for (final Prompt p in _defaultPrompts()) {
          _prompts.add(_PromptFields.from(p));
        }
      } else {
        _prompts.addAll(existing.map(_PromptFields.from));
      }
    }

    _hadAudio = q?.hasSampleAudio ?? false;

    if (_isEditing && q!.isCustom) {
      QuestionStore.instance.imageOf(q.id).then((Uint8List? bytes) {
        if (mounted && bytes != null) setState(() => _imageBytes = bytes);
      });
    }
  }

  /// 파트별 실제 시험 구성에 맞춘 기본 질문 묶음.
  List<Prompt> _defaultPrompts() {
    switch (widget.partId) {
      case PartId.respondQuestions:
        return const <Prompt>[
          Prompt(
              label: 'Question 5', text: '', prepSeconds: 3, answerSeconds: 15),
          Prompt(
              label: 'Question 6', text: '', prepSeconds: 3, answerSeconds: 15),
          Prompt(
              label: 'Question 7', text: '', prepSeconds: 3, answerSeconds: 30),
        ];
      case PartId.respondWithInfo:
        return const <Prompt>[
          Prompt(
              label: 'Question 8', text: '', prepSeconds: 3, answerSeconds: 15),
          Prompt(
              label: 'Question 9', text: '', prepSeconds: 3, answerSeconds: 15),
          Prompt(
            label: 'Question 10',
            text: '',
            prepSeconds: 3,
            answerSeconds: 30,
          ),
        ];
      case PartId.expressOpinion:
        return const <Prompt>[
          Prompt(
            label: 'Question 11',
            text: '',
            prepSeconds: 45,
            answerSeconds: 60,
          ),
        ];
      case PartId.readAloud:
      case PartId.describePicture:
        return const <Prompt>[];
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _passage.dispose();
    _scenePlace.dispose();
    _sceneDetails.dispose();
    _sampleAnswer.dispose();
    _keyExpressions.dispose();
    _tableTitle.dispose();
    _tableSubtitle.dispose();
    for (final _PromptFields p in _prompts) {
      p.dispose();
    }
    for (final _TableRowFields r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (file == null) return;
      final Uint8List bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() => _imageBytes = bytes);
    } on Object catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('사진을 불러오지 못했습니다: $e')),
      );
    }
  }

  Future<void> _pickAudio() async {
    try {
      final PlatformFile? file = await FilePicker.pickFile(
        type: FileType.audio,
        dialogTitle: '예시 음성 파일 선택',
      );
      if (file == null) return;
      final Uint8List bytes = await file.readAsBytes();
      if (!mounted) return;
      if (bytes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('빈 파일입니다.')),
        );
        return;
      }
      setState(() {
        _audioBytes = bytes;
        _audioName = file.name;
        _removeAudio = false;
      });
    } on Object catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('음성 파일을 불러오지 못했습니다: $e')),
      );
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_needsImage && _imageBytes == null && _scenePlace.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('사진을 넣거나 장면 설명을 채워 주세요.')),
      );
      return;
    }

    setState(() => _saving = true);

    final String id =
        widget.existing?.id ?? QuestionStore.instance.newId(widget.partId);

    final Question question = Question(
      id: id,
      partId: widget.partId,
      title: _title.text.trim(),
      passage: _needsPassage ? _passage.text.trim() : null,
      scene: _needsImage && _scenePlace.text.trim().isNotEmpty
          ? SceneHint(
              place: _scenePlace.text.trim(),
              details: _lines(_sceneDetails.text),
            )
          : null,
      table: _needsTable
          ? InfoTable(
              title: _tableTitle.text.trim(),
              subtitle: _tableSubtitle.text.trim(),
              rows: _rows
                  .map((_TableRowFields r) => r.values)
                  .where((List<String> v) => v.any((String s) => s.isNotEmpty))
                  .toList(),
            )
          : null,
      prompts: _needsPrompts
          ? _prompts.map((_PromptFields p) => p.toPrompt()).toList()
          : const <Prompt>[],
      sampleAnswer:
          _sampleAnswer.text.trim().isEmpty ? null : _sampleAnswer.text.trim(),
      keyExpressions: _lines(_keyExpressions.text),
      isCustom: true,
      hasSampleAudio: _hasAudio,
    );

    final bool ok = await QuestionStore.instance.save(
      question,
      imageBytes: _imageBytes,
      audioBytes: _audioBytes,
      removeAudio: _removeAudio,
    );

    if (!mounted) return;
    setState(() => _saving = false);

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('저장하지 못했습니다. 브라우저 저장소를 쓸 수 없는 상태일 수 있습니다.'),
        ),
      );
      return;
    }
    Navigator.of(context).pop(true);
  }

  static List<String> _lines(String text) => text
      .split('\n')
      .map((String s) => s.trim())
      .where((String s) => s.isNotEmpty)
      .toList(growable: false);

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '문항 수정' : '문항 등록'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(32),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              children: <Widget>[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _part.title,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: _color,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '준비 ${_part.defaultPrepSeconds}초 · 답변 ${_part.defaultAnswerSeconds}초',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: <Widget>[
            _field(
              controller: _title,
              label: '문항 제목',
              hint: '목록에 표시됩니다. 예) 박물관 안내 방송',
              required: true,
            ),
            if (_needsPassage)
              _field(
                controller: _passage,
                label: '읽을 지문',
                hint: '실제로 소리 내어 읽을 영어 지문',
                required: true,
                maxLines: 8,
              ),
            if (_needsImage) ...<Widget>[
              _imageField(scheme),
              _field(
                controller: _scenePlace,
                label: '장면 설명 — 장소 (사진이 없을 때 사용)',
                hint: '예) 도심 공원의 산책로',
              ),
              _field(
                controller: _sceneDetails,
                label: '장면 설명 — 상세 (한 줄에 하나)',
                hint: '두 사람이 조깅하고 있음\n벤치에 노인이 앉아 있음',
                maxLines: 5,
              ),
            ],
            if (_needsTable) ...<Widget>[
              _field(
                controller: _tableTitle,
                label: '자료 제목',
                hint: '예) Digital Marketing Workshop',
                required: true,
              ),
              _field(
                controller: _tableSubtitle,
                label: '자료 부제',
                hint: '예) Saturday, June 14 · Grand Hall',
              ),
              _tableEditor(scheme),
            ],
            if (_needsPrompts) _promptEditor(scheme),
            _audioField(scheme),
            _field(
              controller: _sampleAnswer,
              label: '모범 답안 (선택)',
              hint: '연습 시작 전과 끝난 뒤에 보입니다.',
              maxLines: 6,
            ),
            _field(
              controller: _keyExpressions,
              label: '핵심 표현 (선택, 한 줄에 하나)',
              hint: 'This picture was taken at ~\nOverall, it looks like ~',
              maxLines: 5,
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(backgroundColor: _color),
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check),
              label: Text(_isEditing ? '수정 저장' : '등록'),
            ),
            const SizedBox(height: 12),
            Text(
              '등록한 문항은 이 브라우저에만 저장됩니다. '
              '다른 기기나 다른 사람에게는 보이지 않습니다.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    String? hint,
    bool required = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          hintText: hint,
          alignLabelWithHint: maxLines > 1,
          border: const OutlineInputBorder(),
        ),
        validator: required
            ? (String? value) =>
                (value == null || value.trim().isEmpty) ? '필수 입력입니다' : null
            : null,
      ),
    );
  }

  Widget _imageField(ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            '사진',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (_imageBytes != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: Image.memory(_imageBytes!, fit: BoxFit.cover),
              ),
            )
          else
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  '사진 없음 — 아래 장면 설명만으로도 연습할 수 있습니다',
                  style: TextStyle(
                    fontSize: 13,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.photo_library_outlined, size: 18),
                label: Text(_imageBytes == null ? '사진 선택' : '사진 바꾸기'),
              ),
              if (_imageBytes != null) ...<Widget>[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => setState(() => _imageBytes = null),
                  child: const Text('사진 빼기'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _audioField(ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            '예시 음성 (선택)',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            '직접 녹음했거나 다른 도구로 만든 mp3·m4a·wav 파일을 올리면, '
            '연습 화면에서 모범 낭독으로 들을 수 있습니다.',
            style: TextStyle(
              fontSize: 12.5,
              height: 1.5,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  _hasAudio ? Icons.audiotrack : Icons.music_off_outlined,
                  size: 18,
                  color: _hasAudio ? _color : scheme.outline,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _audioName ?? (_hasAudio ? '저장된 예시 음성이 있습니다' : '예시 음성 없음'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: _hasAudio ? FontWeight.w700 : FontWeight.w500,
                      color: _hasAudio
                          ? scheme.onSurface
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                if (_hadAudio && !_removeAudio && _audioBytes == null)
                  IconButton(
                    tooltip: '들어보기',
                    onPressed: () =>
                        SampleAudioService.instance.toggle(widget.existing!.id),
                    icon: Icon(Icons.play_arrow_rounded, color: _color),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              OutlinedButton.icon(
                onPressed: _pickAudio,
                icon: const Icon(Icons.upload_file, size: 18),
                label: Text(_hasAudio ? '음성 바꾸기' : '음성 파일 선택'),
              ),
              if (_hasAudio) ...<Widget>[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => setState(() {
                    _audioBytes = null;
                    _audioName = null;
                    _removeAudio = true;
                  }),
                  child: const Text('음성 빼기'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _promptEditor(ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Text(
                '질문',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => setState(() => _prompts.add(_PromptFields())),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('질문 추가'),
              ),
            ],
          ),
          for (int i = 0; i < _prompts.length; i++)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: TextFormField(
                          controller: _prompts[i].label,
                          decoration: const InputDecoration(
                            labelText: '라벨',
                            hintText: 'Question 5',
                            isDense: true,
                          ),
                        ),
                      ),
                      if (_prompts.length > 1)
                        IconButton(
                          tooltip: '이 질문 삭제',
                          onPressed: () => setState(() {
                            _prompts.removeAt(i).dispose();
                          }),
                          icon: Icon(Icons.close, color: scheme.outline),
                        ),
                    ],
                  ),
                  TextFormField(
                    controller: _prompts[i].text,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: '질문 내용 *',
                      alignLabelWithHint: true,
                    ),
                    validator: (String? v) =>
                        (v == null || v.trim().isEmpty) ? '필수 입력입니다' : null,
                  ),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: TextFormField(
                          controller: _prompts[i].prep,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: '준비(초)',
                            isDense: true,
                          ),
                          validator: _positiveOrZero,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _prompts[i].answer,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: '답변(초)',
                            isDense: true,
                          ),
                          validator: _positive,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _tableEditor(ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Text(
                '자료 표',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => setState(() => _rows.add(_TableRowFields())),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('행 추가'),
              ),
            ],
          ),
          Text(
            '시간 / 내용 / 장소 순서로 채웁니다. 빈 행은 저장되지 않습니다.',
            style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          for (int i = 0; i < _rows.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  SizedBox(
                    width: 88,
                    child: TextFormField(
                      controller: _rows[i].time,
                      decoration: const InputDecoration(
                        labelText: '시간',
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _rows[i].content,
                      decoration: const InputDecoration(
                        labelText: '내용',
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 88,
                    child: TextFormField(
                      controller: _rows[i].place,
                      decoration: const InputDecoration(
                        labelText: '장소',
                        isDense: true,
                      ),
                    ),
                  ),
                  if (_rows.length > 1)
                    IconButton(
                      tooltip: '이 행 삭제',
                      onPressed: () =>
                          setState(() => _rows.removeAt(i).dispose()),
                      icon: Icon(Icons.close, size: 18, color: scheme.outline),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static String? _positive(String? value) {
    final int? n = int.tryParse((value ?? '').trim());
    if (n == null || n <= 0) return '1 이상';
    return null;
  }

  static String? _positiveOrZero(String? value) {
    final int? n = int.tryParse((value ?? '').trim());
    if (n == null || n < 0) return '0 이상';
    return null;
  }
}

class _PromptFields {
  _PromptFields()
      : label = TextEditingController(),
        text = TextEditingController(),
        prep = TextEditingController(text: '3'),
        answer = TextEditingController(text: '15');

  _PromptFields.from(Prompt p)
      : label = TextEditingController(text: p.label ?? ''),
        text = TextEditingController(text: p.text),
        prep = TextEditingController(text: '${p.prepSeconds}'),
        answer = TextEditingController(text: '${p.answerSeconds}');

  final TextEditingController label;
  final TextEditingController text;
  final TextEditingController prep;
  final TextEditingController answer;

  Prompt toPrompt() => Prompt(
        label: label.text.trim().isEmpty ? null : label.text.trim(),
        text: text.text.trim(),
        prepSeconds: int.tryParse(prep.text.trim()) ?? 0,
        answerSeconds: int.tryParse(answer.text.trim()) ?? 15,
      );

  void dispose() {
    label.dispose();
    text.dispose();
    prep.dispose();
    answer.dispose();
  }
}

class _TableRowFields {
  _TableRowFields()
      : time = TextEditingController(),
        content = TextEditingController(),
        place = TextEditingController();

  _TableRowFields.from(List<String> row)
      : time = TextEditingController(text: row.isNotEmpty ? row[0] : ''),
        content = TextEditingController(text: row.length > 1 ? row[1] : ''),
        place = TextEditingController(text: row.length > 2 ? row[2] : '');

  final TextEditingController time;
  final TextEditingController content;
  final TextEditingController place;

  List<String> get values => <String>[
        time.text.trim(),
        content.text.trim(),
        place.text.trim(),
      ];

  void dispose() {
    time.dispose();
    content.dispose();
    place.dispose();
  }
}
