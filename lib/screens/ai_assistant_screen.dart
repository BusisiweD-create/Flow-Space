import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:math';
import '../services/backend_api_service.dart';
import '../services/report_export_service.dart';

class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _messages = <Map<String, String>>[
    {
      'role': 'system',
      'content':
          'You are a helpful assistant for a project delivery and sign-off tool. Keep responses concise, practical, and safe. Do not fabricate data. If the user changes topics or asks something unrelated to the current thread, switch immediately and answer the latest request without repeating the previous response.',
    },
  ];

  bool _isSending = false;
  List<String> _suggestions = [];

  List<String> _buildLocalSuggestions() {
    final pool = <String>[
      'Show me all projects.',
      'What sprints are currently active?',
      'Help me create a deliverable.',
      'Help me set up a new sprint.',
      'Show me what is overdue.',
      'What should I focus on next?',
      'Take me back to the dashboard.',
      'Can you summarize what changed most recently?',
    ];
    final r = Random(DateTime.now().microsecondsSinceEpoch);
    pool.shuffle(r);
    return pool.take(4).toList();
  }

  Future<void> _refreshSuggestions() async {
    setState(() => _suggestions = _buildLocalSuggestions());
    try {
      final resp = await BackendApiService().aiSuggestions();
      final root = resp.data is Map ? Map<String, dynamic>.from(resp.data as Map) : {};
      final raw = root['suggestions'] ??
          (root['data'] is Map ? (root['data']['suggestions']) : null);
      final suggestions = raw is List
          ? raw.map((e) => e.toString()).where((s) => s.trim().isNotEmpty).toList()
          : <String>[];
      if (!mounted) return;
      if (suggestions.isNotEmpty) {
        setState(() => _suggestions = suggestions);
      }
    } catch (_) {}
  }

  String _sanitizeAssistantText(String text) {
    var s = text;
    s = s.replaceAll('```', '');
    s = s.replaceAll('*', '');
    s = s.replaceAll('#', '');
    s = s.replaceAll('`', '');
    s = s.replaceAll(RegExp(r'^\s*terminal\s*\d+(?:\s*-\s*\d+)?\s*$', multiLine: true, caseSensitive: false), '');
    s = s.replaceAll(RegExp(r'^\s*•\s+', multiLine: true), '- ');
    s = s.replaceAll(RegExp(r'^\s*\*\s+', multiLine: true), '- ');
    s = s.replaceAll(RegExp(r'[^\S\r\n]+'), ' ');
    return s.trim();
  }

  @override
  void initState() {
    super.initState();
    _refreshSuggestions();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
      _messages.add({'role': 'user', 'content': text});
      _controller.clear();
      _suggestions = [];
    });

    try {
      debugPrint('AI Chat: sending messages...');
      final resp = await BackendApiService()
          .aiChat(_messages, temperature: 0.4, maxTokens: 500);
      debugPrint('AI Chat: response success=${resp.isSuccess}');
      final data = resp.data is Map ? Map<String, dynamic>.from(resp.data as Map) : {};
      debugPrint('AI Chat: data keys=${data.keys.toList()}');
      final content = (data['content'] ??
              (data['data'] is Map ? (data['data']['content'] ?? data['data']['message']) : null) ??
              data['message'])
          ?.toString()
          .trim();
      final actions = data['actions'];
      
      // Extract suggestions
      final rawSuggestions = data['suggestions'] ?? (data['data'] is Map ? data['data']['suggestions'] : null);
      debugPrint('AI Chat: rawSuggestions=$rawSuggestions');
      final suggestions = rawSuggestions is List ? rawSuggestions.cast<String>() : <String>[];

      bool navigated = false;
      bool silentNavigation = false;
      String? navigateRoute;

      if (resp.isSuccess && actions is List && actions.isNotEmpty) {
        for (final a in actions) {
          if (a is! Map) continue;
          final m = Map<String, dynamic>.from(a);
          final type = (m['type'] ?? '').toString().toLowerCase();
          if (type == 'navigate') {
            final route = (m['route'] ?? '').toString().trim();
            final silent = m['silent'] == true;
            if (route.isNotEmpty) {
              navigated = true;
              silentNavigation = silent;
              navigateRoute = route;
              break;
            }
          }
          if (type == 'export_pdf') {
            final title = (m['title'] ?? 'Report').toString();
            final contentForPdf = (m['content'] ?? content ?? '').toString();
            if (contentForPdf.trim().isNotEmpty && mounted) {
              try {
                await ReportExportService().exportTextAsPDF(title: title, content: contentForPdf);
              } catch (_) {}
            }
          }
        }
      }

      final shouldShowAssistantMessage = !(navigated && silentNavigation);
      if (shouldShowAssistantMessage) {
        final safeContent = resp.isSuccess
            ? (content?.isNotEmpty == true ? _sanitizeAssistantText(content!) : 'No response received.')
            : _sanitizeAssistantText(resp.error ?? 'Request failed.');
        setState(() {
          _messages.add({
            'role': 'assistant',
            'content': safeContent,
          });
          _suggestions = suggestions;
        });
      } else {
        setState(() {
          _suggestions = suggestions;
        });
      }

      if (navigated && navigateRoute != null && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (silentNavigation) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Navigating…')),
            );
          }
          GoRouter.of(context).go(navigateRoute!);
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({'role': 'assistant', 'content': 'Error: $e'});
      });
    } finally {
      setState(() => _isSending = false);
      if (mounted) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = _messages.where((m) => m['role'] != 'system').toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('FlowPilot'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: visible.length,
              itemBuilder: (context, index) {
                final m = visible[index];
                final role = (m['role'] ?? '').toLowerCase();
                final isUser = role == 'user';
                final content = m['content'] ?? '';
                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Card(
                      color: isUser
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(content),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_suggestions.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Text(
                    'Suggestions',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _suggestions.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final suggestion = _suggestions[index];
                        return ActionChip(
                          label: Text(suggestion),
                          // ignore: deprecated_member_use
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                          onPressed: () {
                            _controller.text = suggestion;
                            _send();
                          },
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'Ask a question…',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: _isSending ? null : _send,
                    child: Text(_isSending ? 'Sending…' : 'Send'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
