import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

import '../../core/platform_config.dart';
import '../../ui/clawfree_assets.dart';
import '../../ui/theme.dart';

class OnboardingModal extends StatefulWidget {
  const OnboardingModal({super.key, required this.onFinish});

  final VoidCallback onFinish;

  @override
  State<OnboardingModal> createState() => _OnboardingModalState();
}

class _OnboardingModalState extends State<OnboardingModal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _connectorController;

  @override
  void initState() {
    super.initState();
    _connectorController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _connectorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile =
        PlatformConfig.formFactor(context) == DeviceFormFactor.phone;

    final diagram = RepaintBoundary(child: _buildArchitectureDiagram(context));

    // Mobile scrolls; Control Tower fits to screen
    final Widget diagramArea = isMobile
        ? SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            child: diagram,
          )
        : Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            child: diagram,
          );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.1),
                    ClawfreeTheme.hudOverlayColor,
                    Theme.of(context)
                        .colorScheme
                        .secondary
                        .withValues(alpha: 0.1),
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: RepaintBoundary(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Container(color: ClawfreeTheme.hudContainerColor),
              ),
            ),
          ),
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              decoration: ClawfreeTheme.glassDecoration(
                context,
                elevation: 30,
                borderRadius: 32,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(context),
                  Expanded(child: diagramArea),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final formFactor = PlatformConfig.formFactor(context);
    final isLarge = formFactor != DeviceFormFactor.phone;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isLarge ? 64 : 24,
        vertical: isLarge ? 24 : 20,
      ),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: ClawfreeTheme.hudBorder)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Hero(tag: 'app-icon-modal', child: ClawfreeLogo(size: isLarge ? 100 : 48)),
          const SizedBox(width: 32),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final showBadge = constraints.maxWidth > 360;
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'CLAWFREE',
                          style: ClawfreeTheme.technicalStyle(
                            context: context,
                            fontSize: isLarge ? 48 : 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4.0,
                          ),
                        ),
                        if (showBadge) ...[
                          const SizedBox(width: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: ClawfreeTheme.hudActive.withValues(alpha: 0.1),
                              borderRadius: ClawfreeBorderRadius.tiny,
                              border: Border.all(
                                color: ClawfreeTheme.hudActive.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              'DEMO WORKFLOW',
                              style: ClawfreeTheme.technicalStyle(
                                context: context,
                                fontSize: isLarge ? 14 : 10,
                                color: ClawfreeTheme.hudActive,
                              ),
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'HANDS-FREE AI AGENTIC ORCHESTRATOR',
                  style: ClawfreeTheme.technicalStyle(
                    context: context,
                    fontSize: isLarge ? 18 : 12,
                    color: ClawfreeTheme.hudTextSecondary,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 2.0,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: isLarge ? 56 : 32),
            onPressed: widget.onFinish,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Architecture Diagram
  // ---------------------------------------------------------------------------

  // Connector line aligns to circle centers: badge(40) + gap(4) + title(~18) + gap(8) + r(110)
  static const _connectorTop = 180.0;

  Widget _buildArchitectureDiagram(BuildContext context) {
    final isMobile =
        PlatformConfig.formFactor(context) == DeviceFormFactor.phone;

    if (isMobile) {
      return Column(
        children: [
          _buildStationNode(context, 'CLAWFREE VOX', _ArchNodes.buildInputNode(context, isLarge: true),
              topIcon: _buildStationBadge(Icons.mic, Theme.of(context).colorScheme.primary)),
          _buildVerticalConnector(context, 'Encrypted SSE Stream'),
          _buildCodeSnippet(context, 'VOICE INPUT', _voiceInputCode(context)),
          _buildVerticalConnector(context, 'Context Orchestration'),
          _buildStationNode(context, 'CLOUD INFRA', _ArchNodes.buildGatewayNode(context, isLarge: true),
              topIcon: _buildStationBadge(Icons.cloud, _ArchNodes._infraColor)),
          _buildVerticalConnector(context, 'Enriched Prompt'),
          _buildCodeSnippet(context, 'CONTEXT ENRICHMENT', _contextCode(context)),
          _buildVerticalConnector(context, 'A2UI Protocol'),
          _buildStationNode(context, 'OPUS 4.6 REASONING', _ArchNodes.buildBrainNode(context, isLarge: true),
              topIcon: _buildStationBadge(Icons.psychology, _ArchNodes._reasoningColor)),
          _buildVerticalConnector(context, 'SSE Stream'),
          _buildCodeSnippet(context, 'A2UI STREAM', _a2uiStreamCode(context)),
          _buildVerticalConnector(context, 'Surface Render'),
          _buildStationNode(context, 'genUI RENDER', _ArchNodes.buildClientNode(context, isLarge: true),
              topIcon: _buildStationBadge(Icons.layers, _ArchNodes._renderColor)),
          _buildVerticalConnector(context, 'State Continuity'),
          _buildCodeSnippet(context, 'SURFACE STATE', _surfaceStateCode(context)),
          _buildVerticalConnector(context, 'Fleet Sync'),
          _buildStationNode(context, 'DEVICE FLEET', _ArchNodes.buildDeviceFanOut(context, isLarge: true),
              topIcon: _buildStationBadge(Icons.sync, _ArchNodes._fleetColor)),
        ],
      );
    }

    // Control Tower — fits to screen, no scroll
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Row 1: stations + connectors — circles aligned at top
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 5, child: _buildStationNode(context, 'CLAWFREE VOX', _ArchNodes.buildInputNode(context, isLarge: true),
                topIcon: _buildStationBadge(Icons.mic, Theme.of(context).colorScheme.primary))),
            Expanded(flex: 4, child: _buildHorizontalConnector(context, 'Encrypted SSE', topPadding: _connectorTop)),
            Expanded(flex: 5, child: _buildStationNode(context, 'CLOUD INFRA', _ArchNodes.buildGatewayNode(context, isLarge: true),
                topIcon: _buildStationBadge(Icons.cloud, _ArchNodes._infraColor))),
            Expanded(flex: 4, child: _buildHorizontalConnector(context, 'Enriched Prompt', topPadding: _connectorTop)),
            Expanded(flex: 5, child: _buildStationNode(context, 'OPUS 4.6', _ArchNodes.buildBrainNode(context, isLarge: true),
                topIcon: _buildStationBadge(Icons.psychology, _ArchNodes._reasoningColor))),
            Expanded(flex: 4, child: _buildHorizontalConnector(context, 'A2UI Protocol', topPadding: _connectorTop)),
            Expanded(flex: 5, child: _buildStationNode(context, 'genUI RENDER', _ArchNodes.buildClientNode(context, isLarge: true),
                topIcon: _buildStationBadge(Icons.layers, _ArchNodes._renderColor))),
            Expanded(flex: 4, child: _buildHorizontalConnector(context, 'Fleet Sync', topPadding: _connectorTop)),
            Expanded(flex: 5, child: _buildStationNode(context, 'DEVICE FLEET', _ArchNodes.buildDeviceFanOut(context, isLarge: true),
                topIcon: _buildStationBadge(Icons.sync, _ArchNodes._fleetColor))),
          ],
        ),
        const SizedBox(height: 20),
        // Row 2: code blocks — aligned center-to-center with stations above
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 5),
              Expanded(flex: 18, child: _buildCodeSnippet(context, 'VOICE INPUT', _voiceInputCode(context))),
              const SizedBox(width: 8),
              Expanded(flex: 18, child: _buildCodeSnippet(context, 'CONTEXT ENRICHMENT', _contextCode(context))),
              const SizedBox(width: 8),
              Expanded(flex: 18, child: _buildCodeSnippet(context, 'A2UI STREAM', _a2uiStreamCode(context))),
              const SizedBox(width: 8),
              Expanded(flex: 18, child: _buildCodeSnippet(context, 'SURFACE STATE', _surfaceStateCode(context))),
              const Spacer(flex: 5),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Connectors
  // ---------------------------------------------------------------------------

  Widget _buildVerticalConnector(BuildContext context, String label) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            textAlign: TextAlign.center,
            style: ClawfreeTheme.technicalStyle(
              context: context,
              fontSize: 11,
              color: ClawfreeTheme.hudTextSecondary,
              letterSpacing: 2.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            width: 4,
            child: AnimatedBuilder(
              animation: _connectorController,
              builder: (context, _) {
                return CustomPaint(
                  size: const Size(4, double.infinity),
                  painter: _MarchingAntsPainter(
                    progress: _connectorController.value,
                    color: Theme.of(context).colorScheme.secondary,
                    isVertical: true,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalConnector(BuildContext context, String label,
      {double topPadding = 155}) {
    return Column(
      children: [
        SizedBox(height: topPadding),
        AnimatedBuilder(
          animation: _connectorController,
          builder: (context, _) {
            return CustomPaint(
              size: const Size(double.infinity, 4),
              painter: _MarchingAntsPainter(
                progress: _connectorController.value,
                color: Theme.of(context).colorScheme.primary,
                isVertical: false,
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        Text(
          label.toUpperCase(),
          textAlign: TextAlign.center,
          style: ClawfreeTheme.technicalStyle(
            context: context,
            fontSize: 10,
            color: ClawfreeTheme.hudTextFaint,
            letterSpacing: 2.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Station helpers
  // ---------------------------------------------------------------------------

  Widget _buildStationBadge(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Icon(icon, size: 24, color: color),
    );
  }

  Widget _buildStationNode(BuildContext context, String title, Widget node,
      {Widget? topIcon}) {
    final isLarge =
        PlatformConfig.formFactor(context) != DeviceFormFactor.phone;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (topIcon != null) ...[
          topIcon,
          const SizedBox(height: 4),
        ],
        Text(
          title,
          textAlign: TextAlign.center,
          style: ClawfreeTheme.technicalStyle(
            context: context,
            fontSize: isLarge ? 14 : 12,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        node,
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Code block data boxes (JSON syntax-highlighted)
  // ---------------------------------------------------------------------------

  /// Colored text span helper for JSON syntax highlighting.
  TextSpan _c(String text, Color color) =>
      TextSpan(text: text, style: TextStyle(color: color));

  Widget _buildCodeSnippet(
    BuildContext context,
    String title,
    List<TextSpan> codeSpans,
  ) {
    final baseStyle = ClawfreeTheme.technicalStyle(
      context: context,
      fontSize: 16,
      color: ClawfreeTheme.hudTextPrimary,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
    ).copyWith(height: 1.6);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0F),
        borderRadius: ClawfreeBorderRadius.interactive,
        border: Border.all(color: ClawfreeTheme.hudBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .secondary
                  .withValues(alpha: 0.1),
              borderRadius: ClawfreeBorderRadius.tiny,
              border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .secondary
                    .withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              title,
              style: ClawfreeTheme.technicalStyle(
                context: context,
                fontSize: 9,
                color: Theme.of(context).colorScheme.secondary,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          RichText(text: TextSpan(style: baseStyle, children: codeSpans)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // JSON code block content builders
  // ---------------------------------------------------------------------------

  List<TextSpan> _voiceInputCode(BuildContext context) {
    final k = Theme.of(context).colorScheme.secondary;
    final s = ClawfreeTheme.hudActive;
    final p = ClawfreeTheme.hudTextMuted;
    return [
      _c('{\n', p),
      _c('  "transcript"', k), _c(': ', p),
      _c('"Plan a 3-day\n', s),
      _c('    foodie trip to Tokyo"', s), _c(',\n', p),
      _c('  "device"', k), _c(': ', p),
      _c('"Apple Watch"', s), _c(',\n', p),
      _c('  "mode"', k), _c(': ', p),
      _c('"voice-only"', s), _c('\n', p),
      _c('}', p),
    ];
  }

  List<TextSpan> _contextCode(BuildContext context) {
    final k = Theme.of(context).colorScheme.secondary;
    final s = ClawfreeTheme.hudActive;
    final n = const Color(0xFF00BCD4);
    final p = ClawfreeTheme.hudTextMuted;
    return [
      _c('{\n', p),
      _c('  "intent"', k), _c(': ', p),
      _c('"trip_planning"', s), _c(',\n', p),
      _c('  "destination"', k), _c(': ', p),
      _c('"Tokyo"', s), _c(',\n', p),
      _c('  "duration"', k), _c(': ', p),
      _c('3', n), _c(',\n', p),
      _c('  "vibe"', k), _c(': ', p),
      _c('"foodie"', s), _c('\n', p),
      _c('}', p),
    ];
  }

  List<TextSpan> _a2uiStreamCode(BuildContext context) {
    final k = Theme.of(context).colorScheme.secondary;
    final s = ClawfreeTheme.hudActive;
    final p = ClawfreeTheme.hudTextMuted;
    final nl = ClawfreeTheme.success;
    return [
      _c('\u25B8 ', p), _c('"Top flights..."', nl),
      _c('\n', p),
      _c('\u25B8 ', p), _c('{ ', p),
      _c('"component"', k), _c(': ', p),
      _c('"FlightTicket"', s), _c(',\n', p),
      _c('    ', p), _c('"airline"', k), _c(': ', p),
      _c('"ANA"', s), _c(' }\n', p),
      _c('\u25B8 ', p), _c('"For lodging..."', nl),
      _c('\n', p),
      _c('\u25B8 ', p), _c('{ ', p),
      _c('"component"', k), _c(': ', p),
      _c('"HotelCard"', s), _c(',\n', p),
      _c('    ', p), _c('"name"', k), _c(': ', p),
      _c('"Hoshinoya"', s), _c(' }', p),
    ];
  }

  List<TextSpan> _surfaceStateCode(BuildContext context) {
    final k = Theme.of(context).colorScheme.secondary;
    final s = ClawfreeTheme.hudActive;
    final p = ClawfreeTheme.hudTextMuted;
    final fn = ClawfreeTheme.hudTextPrimary;
    return [
      _c('SurfaceController', fn),
      _c('.sync', k), _c('({\n', p),
      _c('  ', p), _c('"watch"', k), _c(': ', p),
      _c('"\u2713"', s), _c(',\n', p),
      _c('  ', p), _c('"iPhone"', k), _c(': ', p),
      _c('[FlightTicket,\n', fn),
      _c('    HotelCard]', fn), _c(',\n', p),
      _c('  ', p), _c('"iPad"', k), _c(': ', p),
      _c('"SplitPanel"', s), _c('\n', p),
      _c('})', p),
    ];
  }
}

// =============================================================================
// Custom Painters
// =============================================================================

class _MarchingAntsPainter extends CustomPainter {
  _MarchingAntsPainter({
    required this.progress,
    required this.color,
    required this.isVertical,
  });

  final double progress;
  final Color color;
  final bool isVertical;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final dashPaint = Paint()
      ..color = color
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    if (isVertical) {
      canvas.drawLine(
          Offset(size.width / 2, 0), Offset(size.width / 2, size.height), paint);
      canvas.drawCircle(
          Offset(size.width / 2, progress * size.height), 5, dashPaint);
    } else {
      canvas.drawLine(
          Offset(0, size.height / 2), Offset(size.width, size.height / 2), paint);
      canvas.drawCircle(
          Offset(progress * size.width, size.height / 2), 5, dashPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MarchingAntsPainter oldDelegate) =>
      progress != oldDelegate.progress;
}

// =============================================================================
// Architecture Nodes
// =============================================================================

abstract final class _ArchNodes {
  // Station accent colors
  static const _infraColor = ClawfreeTheme.homeMode;
  static const _reasoningColor = ClawfreeTheme.onboardingMode;
  static const _renderColor = Color(0xFF00BCD4);
  static const _fleetColor = ClawfreeTheme.homeMode;
  static const _nodeBackground = Color(0xE6000000);

  /// Standardized node: pulsing radial background + inner HUD circle.
  static Widget _buildStandardNode(
    BuildContext context, {
    required Widget child,
    required Color color,
    required bool isLarge,
  }) {
    final outerSize = isLarge ? 220.0 : 140.0;
    final innerMargin = isLarge ? 20.0 : 12.0;

    return Container(
      width: outerSize,
      height: outerSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withValues(alpha: 0.35), Colors.transparent],
        ),
      ),
      child: Container(
        margin: EdgeInsets.all(innerMargin),
        padding: EdgeInsets.all(isLarge ? 32 : 20),
        decoration: BoxDecoration(
          color: _nodeBackground,
          shape: BoxShape.circle,
          border: Border.all(color: color, width: isLarge ? 4 : 2),
          boxShadow: ClawfreeTheme.technicalGlow(color),
        ),
        child: Center(child: child),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Station 1: CLAWFREE VOX
  // ---------------------------------------------------------------------------

  static Widget buildInputNode(BuildContext context, {bool isLarge = false}) {
    return _buildStandardNode(
      context,
      isLarge: isLarge,
      color: Colors.white,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: -35,
            child: Icon(Symbols.phone_iphone, size: 35, color: ClawfreeTheme.hudTextMuted),
          ),
          Positioned(
            right: -35,
            child: Icon(Symbols.laptop_mac, size: 35, color: ClawfreeTheme.hudTextMuted),
          ),
          Positioned(
            top: -35,
            child: Icon(Symbols.tablet_mac, size: 35, color: ClawfreeTheme.hudTextMuted),
          ),
          Positioned(
            bottom: -35,
            child: Icon(Symbols.eyeglasses, size: 35, color: ClawfreeTheme.hudTextMuted),
          ),
          const Icon(Symbols.watch, size: 72, color: Colors.white),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Station 2: CLOUD INFRA
  // ---------------------------------------------------------------------------

  static Widget buildGatewayNode(BuildContext context, {bool isLarge = false}) {
    final h = isLarge ? 200.0 : 130.0;
    return SizedBox(
      height: h,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: isLarge ? 220 : 140,
            height: isLarge ? 160 : 110,
            decoration: BoxDecoration(
              color: ClawfreeTheme.hudContainerColor,
              borderRadius: ClawfreeBorderRadius.element,
              border: Border.all(
                  color: _infraColor.withValues(alpha: 0.4), width: 2),
              boxShadow:
                  ClawfreeTheme.technicalGlow(_infraColor, intensity: 0.3),
            ),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  decoration: BoxDecoration(
                    color: _infraColor.withValues(alpha: 0.15),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(14)),
                  ),
                  child: Text(
                    'DEPLOYMENT CONTAINER',
                    style: ClawfreeTheme.technicalStyle(
                      context: context,
                      fontSize: isLarge ? 10 : 7,
                      color: _infraColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(isLarge ? 20 : 12),
                    child: Image.network(
                      'https://raw.githubusercontent.com/openclaw/openclaw/main/docs/assets/openclaw-logo-text.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => Icon(Icons.dns,
                          color: ClawfreeTheme.warning,
                          size: isLarge ? 64 : 32),
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _infraColor.withValues(alpha: 0.05),
                    borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(14)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Symbols.deployed_code,
                          color: _infraColor, size: isLarge ? 28 : 16),
                      const SizedBox(width: 10),
                      Text(
                        'DOCKER ENGINE',
                        style: ClawfreeTheme.technicalStyle(
                          context: context,
                          fontSize: isLarge ? 12 : 8,
                          color: _infraColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Station 3: OPUS 4.6 REASONING — Dual-track brain
  // ---------------------------------------------------------------------------

  static Widget buildBrainNode(BuildContext context, {bool isLarge = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildStandardNode(
          context,
          isLarge: isLarge,
          color: _reasoningColor,
          child: Image.network(
            'https://raw.githubusercontent.com/lobehub/lobe-icons/refs/heads/master/packages/static-png/dark/claude-color.png',
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => Icon(Icons.auto_awesome,
                color: _reasoningColor, size: isLarge ? 80 : 48),
          ),
        ),
        // Dual-track reasoning labels
        if (isLarge) ...[
          const SizedBox(height: 16),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildReasoningTrack(context, 'WHAT', 'Content\nSelection'),
              const SizedBox(width: 12),
              Container(
                  width: 1, height: 40, color: ClawfreeTheme.hudBorder),
              const SizedBox(width: 12),
              _buildReasoningTrack(context, 'HOW', 'Layout\nAdaptation'),
            ],
          ),
        ],
      ],
    );
  }

  static Widget _buildReasoningTrack(
      BuildContext context, String title, String subtitle) {
    return Column(
      children: [
        Text(
          title,
          style: ClawfreeTheme.technicalStyle(
            context: context,
            fontSize: 12,
            color: _reasoningColor,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: ClawfreeTheme.technicalStyle(
            context: context,
            fontSize: 9,
            color: ClawfreeTheme.hudTextMuted,
            fontWeight: FontWeight.w400,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Station 4: genUI RENDER — Adaptive layout fan-out
  // ---------------------------------------------------------------------------

  static Widget buildClientNode(BuildContext context, {bool isLarge = false}) {
    return _buildStandardNode(
      context,
      isLarge: isLarge,
      color: _renderColor,
      child: Image.network(
        'https://storage.googleapis.com/cms-storage-bucket/lockup_flutter_vertical.a9d6ce81aee44ae017ee.png',
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => Icon(Icons.flutter_dash,
            color: _renderColor, size: isLarge ? 72 : 40),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Station 5: DEVICE FLEET
  // ---------------------------------------------------------------------------

  static Widget buildDeviceFanOut(BuildContext context,
      {bool isLarge = false}) {
    return _buildStandardNode(
      context,
      isLarge: isLarge,
      color: _fleetColor,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: -35,
            child: Icon(Symbols.phone_iphone, size: 35, color: ClawfreeTheme.hudTextMuted),
          ),
          Positioned(
            right: -35,
            child: Icon(Symbols.laptop_mac, size: 35, color: ClawfreeTheme.hudTextMuted),
          ),
          Positioned(
            top: -35,
            child: Icon(Symbols.tablet_mac, size: 35, color: ClawfreeTheme.hudTextMuted),
          ),
          Positioned(
            bottom: -35,
            child: Icon(Symbols.eyeglasses, size: 35, color: ClawfreeTheme.hudTextMuted),
          ),
          const Icon(Symbols.watch, size: 72, color: Colors.white),
        ],
      ),
    );
  }
}
