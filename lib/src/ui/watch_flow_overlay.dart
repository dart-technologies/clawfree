import 'package:flutter/material.dart';

/// 顯示 Watch 互動流程的即時狀態（iPhone/iPad/macOS 上同步顯示）
class WatchFlowOverlay extends StatelessWidget {
  const WatchFlowOverlay({super.key, required this.state});

  final Map<String, dynamic> state;

  @override
  Widget build(BuildContext context) {
    final flow = state['flow'] as String? ?? '';
    final step = state['step'] as int? ?? 0;

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: flow == 'agentConfig'
              ? const Color(0xFFFF6B35).withValues(alpha: 0.5)
              : const Color(0xFF00BFA5).withValues(alpha: 0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: (flow == 'agentConfig'
                    ? const Color(0xFFFF6B35)
                    : const Color(0xFF00BFA5))
                .withValues(alpha: 0.15),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 標題列
          Row(
            children: [
              Icon(
                Icons.watch,
                color: Colors.white70,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                '⌚ Watch',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              _buildProgressDots(flow == 'agentConfig' ? 3 : 4, step),
            ],
          ),
          const SizedBox(height: 10),

          if (flow == 'agentConfig') _buildAgentConfigState(step),
          if (flow == 'tripPlanner') _buildTripPlannerState(step),
        ],
      ),
    );
  }

  Widget _buildProgressDots(int total, int current) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(total, (i) {
        return Container(
          width: 20,
          height: 4,
          margin: const EdgeInsets.only(left: 3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            color: i <= current
                ? const Color(0xFFFF6B35)
                : Colors.white24,
          ),
        );
      }),
    );
  }

  Widget _buildAgentConfigState(int step) {
    final model = state['selectedModel'] as String? ?? '';
    final modelEmoji = state['selectedModelEmoji'] as String? ?? '🧠';
    final skills = (state['selectedSkills'] as List?)?.cast<String>() ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🔧 建立 Agent',
          style: TextStyle(
            color: const Color(0xFFFF6B35),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),

        // Step 0: 選模型
        _stepRow(0, step, '$modelEmoji 模型', model.isEmpty ? '選擇中...' : model),

        // Step 1: 選技能
        _stepRow(1, step, '🛠️ 技能',
            skills.isEmpty ? '選擇中...' : skills.join(', ')),

        // Step 2: 確認
        if (step >= 2)
          _stepRow(2, step, '✅ 確認', '準備建立'),
      ],
    );
  }

  Widget _buildTripPlannerState(int step) {
    final city = state['selectedCity'] as String? ?? '';
    final cityEmoji = state['selectedCityEmoji'] as String? ?? '🌍';
    final days = state['selectedDays'] as int? ?? 0;
    final attractions =
        (state['selectedAttractions'] as List?)?.cast<String>() ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🗾 規劃旅行',
          style: TextStyle(
            color: const Color(0xFF00BFA5),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),

        // Step 0: 目的地
        _stepRow(0, step, '$cityEmoji 目的地', city.isEmpty ? '選擇中...' : city),

        // Step 1: 天數
        _stepRow(1, step, '📅 天數', days > 0 ? '$days 天' : '選擇中...'),

        // Step 2: 景點
        _stepRow(2, step, '📍 景點',
            attractions.isEmpty ? '選擇中...' : '${attractions.length} 個景點'),

        // Step 3: 確認
        if (step >= 3)
          _stepRow(3, step, '✈️ 出發', '$city $days 天之旅'),
      ],
    );
  }

  Widget _stepRow(int stepIndex, int currentStep, String label, String value) {
    final isActive = stepIndex == currentStep;
    final isDone = stepIndex < currentStep;
    final isPending = stepIndex > currentStep;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          // 狀態圖示
          Icon(
            isDone
                ? Icons.check_circle
                : isActive
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
            size: 14,
            color: isDone
                ? const Color(0xFF00BFA5)
                : isActive
                    ? const Color(0xFFFF6B35)
                    : Colors.white24,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: isPending ? Colors.white30 : Colors.white70,
              fontSize: 13,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.white54,
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
