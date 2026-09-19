import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../../service/analysis_api_service.dart';
import '../models/assistant_message.dart';
import '../models/context_resolution.dart';
import '../services/health_context_resolver.dart';

class HealthAssistantScreen extends StatefulWidget {
  const HealthAssistantScreen({super.key});

  @override
  State<HealthAssistantScreen> createState() =>
      _HealthAssistantScreenState();
}

class _HealthAssistantScreenState extends State<HealthAssistantScreen> {
  final AnalysisApiService _apiService = AnalysisApiService();

  final HealthContextResolver _contextResolver =
  HealthContextResolver();

  final TextEditingController _messageController =
  TextEditingController();

  final ScrollController _scrollController =
  ScrollController();

  final List<AssistantMessage> _messages = [];

  bool _isSending = false;

  Map<String, dynamic>? _selectedReport;
  Map<String, dynamic>? _selectedMedicine;
  Map<String, dynamic>? _selectedMeal;

  String? _pendingQuestion;

  List<Map<String, dynamic>>? _pendingHistory;

  HealthContextType? _pendingContextType;

  List<ContextCandidate> _pendingCandidates = [];

  @override
  void initState() {
    super.initState();

    _messages.add(
      AssistantMessage(
        role: 'assistant',
        text:
        'Hi, I’m your Health Assistant. Ask me about your saved reports, medicines, meals, or any general health question.',
        createdAt: DateTime.now(),
      ),
    );
  }

  String get _userUid {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('User is not logged in.');
    }

    return user.uid;
  }

  List<Map<String, dynamic>> _buildHistory() {
    final recentMessages = _messages.length > 10
        ? _messages.sublist(_messages.length - 10)
        : _messages;

    return recentMessages.map((message) {
      return {
        'role': message.role,
        'content': message.text,
      };
    }).toList();
  }

  bool get _hasManualContext {
    return _selectedReport != null ||
        _selectedMedicine != null ||
        _selectedMeal != null;
  }

  Map<String, dynamic> _buildManualContext() {
    final context = <String, dynamic>{};

    if (_selectedReport != null) {
      context['report'] =
          _makeJsonSafe(_selectedReport);
    }

    if (_selectedMedicine != null) {
      context['medicine'] =
          _makeJsonSafe(_selectedMedicine);
    }

    if (_selectedMeal != null) {
      context['meal'] =
          _makeJsonSafe(_selectedMeal);
    }

    return context;
  }

  dynamic _makeJsonSafe(dynamic value) {
    if (value is Timestamp) {
      return value.toDate().toIso8601String();
    }

    if (value is DocumentReference) {
      return value.path;
    }

    if (value is Map) {
      final result = <String, dynamic>{};

      for (final entry in value.entries) {
        final key = entry.key.toString().toLowerCase();

        if (key == 'imagebase64' ||
            key == 'base64' ||
            key == 'imagedata' ||
            key == 'image_data') {
          continue;
        }

        result[entry.key.toString()] =
            _makeJsonSafe(entry.value);
      }

      return result;
    }

    if (value is List) {
      return value
          .map(
            (item) => _makeJsonSafe(item),
      )
          .toList();
    }

    return value;
  }

  String _contextKey(
      HealthContextType type,
      ) {
    switch (type) {
      case HealthContextType.report:
        return 'report';

      case HealthContextType.medicine:
        return 'medicine';

      case HealthContextType.meal:
        return 'meal';
    }
  }

  Future<void> _sendMessage() async {
    final message =
    _messageController.text.trim();

    if (message.isEmpty || _isSending) {
      return;
    }

    final history = _buildHistory();

    _messageController.clear();

    setState(() {
      _messages.add(
        AssistantMessage(
          role: 'user',
          text: message,
          createdAt: DateTime.now(),
          contextLabels:
          _buildManualContextLabels(),
        ),
      );

      _isSending = true;

      _pendingCandidates = [];
      _pendingQuestion = null;
      _pendingHistory = null;
      _pendingContextType = null;
    });

    _scrollToBottom();

    try {
      // Manual attachment always has priority.
      if (_hasManualContext) {
        final context =
        _buildManualContext();

        _clearManualContext();

        await _sendToApi(
          message: message,
          history: history,
          context: context,
        );

        return;
      }

      // Automatically check user's Firestore data.
      final resolution =
      await _contextResolver.resolve(
        message: message,
      );

      switch (resolution.status) {
        case ContextResolutionStatus.general:
          await _sendToApi(
            message: message,
            history: history,
            context: {},
          );
          break;

        case ContextResolutionStatus.ready:
          final candidate =
              resolution.selected;

          if (candidate == null) {
            throw Exception(
              'Context could not be resolved.',
            );
          }

          final key = _contextKey(
            candidate.type,
          );

          await _sendToApi(
            message: message,
            history: history,
            context: {
              key: _makeJsonSafe(
                candidate.data,
              ),
            },
          );

          break;

        case ContextResolutionStatus.missing:
          if (!mounted) return;

          setState(() {
            _isSending = false;

            _messages.add(
              AssistantMessage(
                role: 'assistant',
                text: resolution.message ??
                    'I could not find the saved health data you asked about.',
                createdAt:
                DateTime.now(),
              ),
            );
          });

          _scrollToBottom();

          break;

        case ContextResolutionStatus.needsSelection:
          if (!mounted) return;

          final type =
              resolution.contextType;

          setState(() {
            _isSending = false;

            _pendingQuestion =
                message;

            _pendingHistory =
                history;

            _pendingContextType =
                type;

            _pendingCandidates =
                resolution.candidates;

            _messages.add(
              AssistantMessage(
                role: 'assistant',
                text:
                _selectionMessage(type),
                createdAt:
                DateTime.now(),
              ),
            );
          });

          _scrollToBottom();

          break;
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSending = false;

        _messages.add(
          AssistantMessage(
            role: 'assistant',
            text:
            'Sorry, I could not process that request right now.',
            createdAt:
            DateTime.now(),
          ),
        );
      });

      _scrollToBottom();
    }
  }

  String _selectionMessage(
      HealthContextType? type,
      ) {
    switch (type) {
      case HealthContextType.report:
        return 'I found multiple saved reports. Which report would you like me to use?';

      case HealthContextType.medicine:
        return 'I found multiple saved medicines. Which medicine would you like me to use?';

      case HealthContextType.meal:
        return 'I found multiple saved meals. Which meal would you like me to use?';

      case null:
        return 'I found multiple saved items. Which one would you like me to use?';
    }
  }

  Future<void> _selectCandidate(
      ContextCandidate candidate,
      ) async {
    final question =
        _pendingQuestion;

    final history =
        _pendingHistory;

    if (question == null ||
        history == null) {
      return;
    }

    setState(() {
      _isSending = true;

      _pendingCandidates = [];
      _pendingQuestion = null;
      _pendingHistory = null;
      _pendingContextType = null;
    });

    final key =
    _contextKey(candidate.type);

    try {
      await _sendToApi(
        message: question,
        history: history,
        context: {
          key: _makeJsonSafe(
            candidate.data,
          ),
        },
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSending = false;

        _messages.add(
          AssistantMessage(
            role: 'assistant',
            text:
            'Sorry, I could not process that saved item right now.',
            createdAt:
            DateTime.now(),
          ),
        );
      });
    }
  }

  Future<void> _sendToApi({
    required String message,
    required List<Map<String, dynamic>>
    history,
    required Map<String, dynamic>
    context,
  }) async {
    try {
      final result =
      await _apiService.sendMessage(
        message: message,
        history: history,
        context: context,
      );

      final responseMessage =
          result['message']?.toString() ??
              'I could not generate a response right now.';

      Map<String, dynamic>?
      doctorRecommendation;

      final doctor =
      result['doctor_recommendation'];

      if (doctor is Map) {
        doctorRecommendation =
        Map<String, dynamic>.from(
          doctor,
        );
      }

      if (!mounted) return;

      setState(() {
        _messages.add(
          AssistantMessage(
            role: 'assistant',
            text: responseMessage,
            createdAt:
            DateTime.now(),
            doctorRecommendation:
            doctorRecommendation,
          ),
        );

        _isSending = false;
      });

      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSending = false;

        _messages.add(
          AssistantMessage(
            role: 'assistant',
            text:
            'Sorry, I could not connect to the AI service right now.',
            createdAt:
            DateTime.now(),
          ),
        );
      });

      _scrollToBottom();
    }
  }

  List<String>
  _buildManualContextLabels() {
    final labels = <String>[];

    if (_selectedReport != null) {
      labels.add(
        _getReportLabel(
          _selectedReport!,
        ),
      );
    }

    if (_selectedMedicine != null) {
      labels.add(
        _getMedicineLabel(
          _selectedMedicine!,
        ),
      );
    }

    if (_selectedMeal != null) {
      labels.add(
        _getMealLabel(
          _selectedMeal!,
        ),
      );
    }

    return labels;
  }

  void _clearManualContext() {
    _selectedReport = null;
    _selectedMedicine = null;
    _selectedMeal = null;
  }

  void _scrollToBottom() {
    Future.delayed(
      const Duration(
        milliseconds: 200,
      ),
          () {
        if (!_scrollController
            .hasClients) {
          return;
        }

        _scrollController.animateTo(
          _scrollController
              .position.maxScrollExtent,
          duration:
          const Duration(
            milliseconds: 250,
          ),
          curve: Curves.easeOut,
        );
      },
    );
  }

  void _showAttachmentMenu() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder:
          (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding:
            const EdgeInsets.all(
              16,
            ),
            child: Column(
              mainAxisSize:
              MainAxisSize.min,
              children: [
                const Align(
                  alignment:
                  Alignment.centerLeft,
                  child: Text(
                    'Attach saved health data',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight:
                      FontWeight.w700,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 12,
                ),

                ListTile(
                  leading: const Icon(
                    Icons
                        .description_rounded,
                  ),
                  title: const Text(
                    'Report',
                  ),
                  onTap: () async {
                    Navigator.pop(
                      bottomSheetContext,
                    );

                    await _pickReport();
                  },
                ),

                ListTile(
                  leading: const Icon(
                    Icons
                        .medication_rounded,
                  ),
                  title: const Text(
                    'Medicine',
                  ),
                  onTap: () async {
                    Navigator.pop(
                      bottomSheetContext,
                    );

                    await _pickMedicine();
                  },
                ),

                ListTile(
                  leading: const Icon(
                    Icons
                        .restaurant_rounded,
                  ),
                  title: const Text(
                    'Meal',
                  ),
                  onTap: () async {
                    Navigator.pop(
                      bottomSheetContext,
                    );

                    await _pickMeal();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickReport() async {
    final document =
    await _pickFirestoreDocument(
      collectionName: 'reports',
      title: 'Select Report',
    );

    if (document == null) {
      return;
    }

    setState(() {
      _selectedReport = {
        'id': document.id,
        ...document.data(),
      };
    });
  }

  Future<void> _pickMedicine() async {
    final document =
    await _pickFirestoreDocument(
      collectionName: 'medicines',
      title: 'Select Medicine',
    );

    if (document == null) {
      return;
    }

    setState(() {
      _selectedMedicine = {
        'id': document.id,
        ...document.data(),
      };
    });
  }

  Future<void> _pickMeal() async {
    final document =
    await _pickFirestoreDocument(
      collectionName: 'meals',
      title: 'Select Meal',
    );

    if (document == null) {
      return;
    }

    setState(() {
      _selectedMeal = {
        'id': document.id,
        ...document.data(),
      };
    });
  }

  Future<
      QueryDocumentSnapshot<
          Map<String, dynamic>>?>
  _pickFirestoreDocument({
    required String collectionName,
    required String title,
  }) async {
    final snapshot =
    await FirebaseFirestore.instance
        .collection('users')
        .doc(_userUid)
        .collection(
      collectionName,
    )
        .limit(30)
        .get();

    if (!mounted) {
      return null;
    }

    if (snapshot.docs.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'No saved $collectionName found.',
          ),
        ),
      );

      return null;
    }

    return showModalBottomSheet<
        QueryDocumentSnapshot<
            Map<String, dynamic>>>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (context) {
        return SafeArea(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount:
            snapshot.docs.length,
            itemBuilder:
                (context, index) {
              final doc =
              snapshot.docs[index];

              final data =
              doc.data();

              return ListTile(
                title: Text(
                  _documentTitle(
                    collectionName,
                    data,
                  ),
                ),
                trailing: const Icon(
                  Icons
                      .chevron_right_rounded,
                ),
                onTap: () {
                  Navigator.pop(
                    context,
                    doc,
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  String _documentTitle(
      String collection,
      Map<String, dynamic> data,
      ) {
    if (collection == 'reports') {
      final report =
      data['report'];

      return data['title']
          ?.toString() ??
          (report is Map
              ? report['title']
              ?.toString()
              : null) ??
          'Medical Report';
    }

    if (collection == 'medicines') {
      final medicine =
      data['medicine'];

      return data['name']
          ?.toString() ??
          (medicine is Map
              ? medicine['name']
              ?.toString()
              : null) ??
          'Medicine';
    }

    if (collection == 'meals') {
      final foods = data['foods'];

      if (foods is List &&
          foods.isNotEmpty) {
        final food = foods.first;

        if (food is Map &&
            food['name'] != null) {
          return food['name']
              .toString();
        }
      }

      return 'Meal';
    }

    return 'Health item';
  }

  String _getReportLabel(
      Map<String, dynamic> report,
      ) {
    return _documentTitle(
      'reports',
      report,
    );
  }

  String _getMedicineLabel(
      Map<String, dynamic> medicine,
      ) {
    return _documentTitle(
      'medicines',
      medicine,
    );
  }

  String _getMealLabel(
      Map<String, dynamic> meal,
      ) {
    return _documentTitle(
      'meals',
      meal,
    );
  }

  void _setQuickQuestion(
      String question,
      ) {
    _messageController.text =
        question;

    _messageController.selection =
        TextSelection.fromPosition(
          TextPosition(
            offset: _messageController
                .text.length,
          ),
        );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      const Color(0xFFF5F6F6),
      appBar: AppBar(
        backgroundColor:
        Colors.white,
        surfaceTintColor:
        Colors.white,
        elevation: 0,
        automaticallyImplyLeading:
        false,
        title: const Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Text(
              'Health Assistant',
              style: TextStyle(
                color:
                Color(0xFF101828),
                fontWeight:
                FontWeight.w700,
              ),
            ),
            Text(
              'Knows your saved health data',
              style: TextStyle(
                color:
                Color(0xFF667085),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          if (_hasManualContext)
            _buildContextBar(),

          Expanded(
            child:
            ListView.builder(
              controller:
              _scrollController,
              padding:
              const EdgeInsets
                  .all(16),
              itemCount:
              _messages.length,
              itemBuilder:
                  (context, index) {
                return _MessageBubble(
                  message:
                  _messages[index],
                );
              },
            ),
          ),

          if (_pendingCandidates
              .isNotEmpty)
            _buildPendingSelection(),

          if (_isSending)
            const _SevaThinkingIndicator(),

          _buildQuickSuggestions(),

          _buildComposer(),
        ],
      ),
    );
  }

  Widget _buildPendingSelection() {
    return Container(
      constraints:
      const BoxConstraints(
        maxHeight: 220,
      ),
      color: Colors.white,
      child: ListView.separated(
        shrinkWrap: true,
        padding:
        const EdgeInsets.all(12),
        itemCount:
        _pendingCandidates.length,
        separatorBuilder:
            (_, __) =>
        const SizedBox(
          height: 8,
        ),
        itemBuilder:
            (context, index) {
          final candidate =
          _pendingCandidates[index];

          return InkWell(
            onTap: () {
              _selectCandidate(
                candidate,
              );
            },
            borderRadius:
            BorderRadius.circular(
              14,
            ),
            child: Container(
              padding:
              const EdgeInsets.all(
                14,
              ),
              decoration:
              BoxDecoration(
                color:
                const Color(
                    0xFFF4F7F6),
                borderRadius:
                BorderRadius.circular(
                  14,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _candidateIcon(
                      candidate.type,
                    ),
                    color:
                    const Color(
                        0xFF07966A),
                  ),

                  const SizedBox(
                    width: 12,
                  ),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                      children: [
                        Text(
                          candidate.title,
                          style:
                          const TextStyle(
                            fontWeight:
                            FontWeight
                                .w700,
                          ),
                        ),

                        if (candidate
                            .subtitle
                            .isNotEmpty)
                          Text(
                            candidate
                                .subtitle,
                            style:
                            const TextStyle(
                              color:
                              Color(
                                  0xFF667085),
                              fontSize:
                              12,
                            ),
                          ),
                      ],
                    ),
                  ),

                  const Icon(
                    Icons
                        .chevron_right_rounded,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _candidateIcon(
      HealthContextType type,
      ) {
    switch (type) {
      case HealthContextType.report:
        return Icons
            .description_rounded;

      case HealthContextType.medicine:
        return Icons
            .medication_rounded;

      case HealthContextType.meal:
        return Icons
            .restaurant_rounded;
    }
  }

  Widget _buildContextBar() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding:
      const EdgeInsets.all(
        10,
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (_selectedReport != null)
            Chip(
              label: Text(
                _getReportLabel(
                  _selectedReport!,
                ),
              ),
              onDeleted: () {
                setState(() {
                  _selectedReport =
                  null;
                });
              },
            ),

          if (_selectedMedicine !=
              null)
            Chip(
              label: Text(
                _getMedicineLabel(
                  _selectedMedicine!,
                ),
              ),
              onDeleted: () {
                setState(() {
                  _selectedMedicine =
                  null;
                });
              },
            ),

          if (_selectedMeal != null)
            Chip(
              label: Text(
                _getMealLabel(
                  _selectedMeal!,
                ),
              ),
              onDeleted: () {
                setState(() {
                  _selectedMeal =
                  null;
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildQuickSuggestions() {
    final suggestions = [
      'Explain my latest report',
      'Tell me about my medicine',
      'How was my last meal?',
      'What foods contain vitamin D?',
    ];

    return SizedBox(
      height: 52,
      child:
      ListView.separated(
        padding:
        const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 6,
        ),
        scrollDirection:
        Axis.horizontal,
        itemCount:
        suggestions.length,
        separatorBuilder:
            (_, __) =>
        const SizedBox(
          width: 8,
        ),
        itemBuilder:
            (context, index) {
          return ActionChip(
            label: Text(
              suggestions[index],
            ),
            onPressed: () {
              _setQuickQuestion(
                suggestions[index],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildComposer() {
    return SafeArea(
      top: false,
      child: Container(
        color: Colors.white,
        padding:
        const EdgeInsets.all(
          10,
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller:
                _messageController,
                minLines: 1,
                maxLines: 5,
                decoration:
                InputDecoration(
                  hintText:
                  'Ask about your health...',
                  filled: true,
                  fillColor:
                  const Color(
                      0xFFF2F4F7),
                  border:
                  OutlineInputBorder(
                    borderRadius:
                    BorderRadius
                        .circular(22),
                    borderSide:
                    BorderSide.none,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 8),

            IconButton(
              onPressed: _isSending
                  ? null
                  : _sendMessage,
              icon: const Icon(
                Icons
                    .arrow_upward_rounded,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble
    extends StatelessWidget {
  final AssistantMessage message;

  const _MessageBubble({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final isUser =
        message.role == 'user';

    return Align(
      alignment: isUser
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        constraints:
        const BoxConstraints(
          maxWidth: 320,
        ),
        margin:
        const EdgeInsets.only(
          bottom: 12,
        ),
        padding:
        const EdgeInsets.all(
          14,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? const Color(
              0xFF06271F)
              : Colors.white,
          borderRadius:
          BorderRadius.circular(
            18,
          ),
        ),
        child: isUser
            ? Text(
          message.text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14.5,
            height: 1.45,
          ),
        )
            : MarkdownBody(
          data: message.text,
          selectable: true,
          styleSheet: MarkdownStyleSheet(
            p: const TextStyle(
              color: Color(0xFF101828),
              fontSize: 14.5,
              height: 1.5,
            ),
            strong: const TextStyle(
              color: Color(0xFF101828),
              fontWeight: FontWeight.w800,
            ),
            em: const TextStyle(
              color: Color(0xFF101828),
              fontStyle: FontStyle.italic,
            ),
            h1: const TextStyle(
              color: Color(0xFF101828),
              fontSize: 20,
              fontWeight: FontWeight.w800,
              height: 1.3,
            ),
            h2: const TextStyle(
              color: Color(0xFF101828),
              fontSize: 18,
              fontWeight: FontWeight.w800,
              height: 1.3,
            ),
            h3: const TextStyle(
              color: Color(0xFF101828),
              fontSize: 16,
              fontWeight: FontWeight.w800,
              height: 1.3,
            ),
            listBullet: const TextStyle(
              color: Color(0xFF07966A),
              fontWeight: FontWeight.w800,
            ),
            blockquote: const TextStyle(
              color: Color(0xFF667085),
              fontSize: 14,
              height: 1.5,
            ),
            blockquoteDecoration: BoxDecoration(
              color: const Color(0xFFF4F7F6),
              borderRadius: BorderRadius.circular(10),
            ),
            code: const TextStyle(
              color: Color(0xFF101828),
              fontSize: 13,
              backgroundColor: Color(0xFFF2F4F7),
            ),
            codeblockDecoration: BoxDecoration(
              color: const Color(0xFFF2F4F7),
              borderRadius: BorderRadius.circular(10),
            ),
            horizontalRuleDecoration: const BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Color(0xFFE4E7EC),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SevaThinkingIndicator extends StatefulWidget {
  const _SevaThinkingIndicator();

  @override
  State<_SevaThinkingIndicator> createState() =>
      _SevaThinkingIndicatorState();
}

class _SevaThinkingIndicatorState
    extends State<_SevaThinkingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 1200,
      ),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.fromLTRB(
          16,
          4,
          16,
          12,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 11,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(
            18,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5F1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                size: 17,
                color: Color(0xFF07966A),
              ),
            ),
            const SizedBox(
              width: 10,
            ),
            const Text(
              'SEVA AI is thinking',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF344054),
              ),
            ),
            const SizedBox(
              width: 7,
            ),
            AnimatedBuilder(
              animation: _controller,
              builder: (
                  context,
                  child,
                  ) {
                final activeIndex =
                    (_controller.value * 3).floor() % 3;

                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    3,
                        (index) {
                      final active =
                          index == activeIndex;

                      return AnimatedContainer(
                        duration: const Duration(
                          milliseconds: 180,
                        ),
                        width: active ? 7 : 5,
                        height: active ? 7 : 5,
                        margin: const EdgeInsets.symmetric(
                          horizontal: 2,
                        ),
                        decoration: BoxDecoration(
                          color: active
                              ? const Color(
                            0xFF07966A,
                          )
                              : const Color(
                            0xFFB7C5C0,
                          ),
                          shape: BoxShape.circle,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

