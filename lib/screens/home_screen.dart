import 'dart:async';

import 'package:flutter/material.dart';

import '../models/toeic_part.dart';
import '../services/attempt_store.dart';
import '../services/playback_service.dart';
import '../theme.dart';
import 'exam_tab.dart';
import 'overview_tab.dart';
import 'part_tab.dart';
import 'settings_screen.dart';
import 'recording_list.dart';

/// 상단에 가로 스크롤 탭을 두고, 탭마다 파트 화면을 보여 주는 메인 화면.
///
/// 탭 구성: 전체 → Q1-2 → Q3-4 → Q5-7 → Q8-10 → Q11 → 실전 모의고사 → 녹음 기록 (총 8개)
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _controller;

  /// 0 = 전체, 1..5 = 파트, 6 = 실전 모의고사, 7 = 녹음 기록
  int get _tabCount => kToeicParts.length + 3;

  @override
  void initState() {
    super.initState();
    _controller = TabController(length: _tabCount, vsync: this);
    _controller.addListener(_onTabChanged);
    unawaited(AttemptStore.instance.load());
  }

  void _onTabChanged() {
    // 탭을 옮기면 재생 중이던 녹음을 멈춘다.
    if (_controller.indexIsChanging) {
      unawaited(PlaybackService.instance.stop());
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onTabChanged);
    _controller.dispose();
    super.dispose();
  }

  void _goToPart(PartId partId) {
    final int index = kToeicParts.indexWhere((ToeicPart p) => p.id == partId);
    if (index >= 0) _controller.animateTo(index + 1);
  }

  /// 현재 탭에 해당하는 강조 색 (탭 인디케이터·라벨에 사용).
  Color get _currentColor {
    final int i = _controller.index;
    if (i >= 1 && i <= kToeicParts.length) {
      return AppTheme.partColor(kToeicParts[i - 1].id);
    }
    return AppTheme.seed;
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color accent = _currentColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('TOEIC Speaking 연습'),
        actions: <Widget>[
          IconButton(
            tooltip: '설정',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (BuildContext context) => const SettingsScreen(),
              ),
            ),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: scheme.outlineVariant),
              ),
            ),
            child: TabBar(
              controller: _controller,
              // ▼ 상단 탭을 가로로 스크롤할 수 있게 하는 핵심 옵션
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              labelPadding: const EdgeInsets.symmetric(horizontal: 12),
              indicatorSize: TabBarIndicatorSize.label,
              indicatorWeight: 3,
              indicatorColor: accent,
              labelColor: accent,
              unselectedLabelColor: scheme.onSurfaceVariant,
              dividerColor: Colors.transparent,
              labelStyle: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
              ),
              tabs: <Widget>[
                const Tab(text: '전체'),
                for (final ToeicPart part in kToeicParts)
                  Tab(text: part.tabLabel),
                const Tab(text: '실전 모의고사'),
                const Tab(text: '녹음 기록'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _controller,
        children: <Widget>[
          OverviewTab(onSelectPart: _goToPart),
          for (final ToeicPart part in kToeicParts) PartTab(part: part),
          const ExamTab(),
          const HistoryTab(),
        ],
      ),
    );
  }
}
