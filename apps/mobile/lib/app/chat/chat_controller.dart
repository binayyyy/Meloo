import 'dart:async';
import '../ai/ai_api_client.dart';
import '../ai/ai_models.dart';
import '../core/safe_change_notifier.dart';
import '../session/auth_models.dart';
import '../uploads/upload_models.dart';
import 'chat_api_client.dart';
import 'chat_models.dart';
import 'chat_socket_client.dart';

class ChatController extends SafeChangeNotifier {
  ChatController({
    ChatApiClient? apiClient,
    ChatSocketClient? socketClient,
    AiApiClient? aiApiClient,
  })  : _apiClient = apiClient ?? ChatApiClient(),
        _socketClient = socketClient ?? ChatSocketClient(),
        _aiApiClient = aiApiClient ?? AiApiClient() {
    _socketSubscription = _socketClient.events.listen(_handleSocketEvent);
  }

  final ChatApiClient _apiClient;
  final ChatSocketClient _socketClient;
  final AiApiClient _aiApiClient;
  late final StreamSubscription<ChatSocketEvent> _socketSubscription;

  bool _isLoading = false;
  bool _isOpeningConversation = false;
  bool _isSending = false;
  bool _isDrafting = false;
  List<ConversationModel> _conversations = const [];
  List<ChatMessageModel> _activeMessages = const [];
  String? _activeConversationId;
  String? _currentUserId;
  String? _connectedAccessToken;
  String? _activeAccessToken;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  bool get isOpeningConversation => _isOpeningConversation;
  bool get isSending => _isSending;
  bool get isDrafting => _isDrafting;
  List<ConversationModel> get conversations => _conversations;
  List<ChatMessageModel> get activeMessages => _activeMessages;
  String? get activeConversationId => _activeConversationId;
  String? get errorMessage => _errorMessage;

  Future<void> load(AuthSession session) async {
    _isLoading = true;
    _errorMessage = null;
    _currentUserId = session.user.id;
    _activeAccessToken = session.tokens.accessToken;
    notifyListeners();

    try {
      if (_connectedAccessToken != session.tokens.accessToken) {
        _connectedAccessToken = session.tokens.accessToken;
        _socketClient.connect(session.tokens.accessToken);
      }
      _conversations = await _apiClient.fetchMyConversations(
        accessToken: session.tokens.accessToken,
      );
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<ConversationModel> createDirectConversation(
    AuthSession session,
    String participantUserId,
  ) async {
    _errorMessage = null;
    notifyListeners();

    try {
      final conversation = await _apiClient.createDirectConversation(
        accessToken: session.tokens.accessToken,
        participantUserId: participantUserId,
      );
      await load(session);
      return conversation;
    } catch (error) {
      _errorMessage = error.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<ConversationModel> createDirectConversationByEmail(
    AuthSession session,
    String participantEmail,
  ) async {
    _errorMessage = null;
    notifyListeners();

    try {
      final conversation = await _apiClient.createDirectConversation(
        accessToken: session.tokens.accessToken,
        participantEmail: participantEmail,
      );
      await load(session);
      return conversation;
    } catch (error) {
      _errorMessage = error.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> openConversation(
    AuthSession session,
    ConversationModel conversation,
  ) async {
    _isOpeningConversation = true;
    _errorMessage = null;
    _activeConversationId = conversation.id;
    _activeMessages = const [];
    notifyListeners();

    try {
      _activeMessages = await _apiClient.fetchMessages(
        accessToken: session.tokens.accessToken,
        conversationId: conversation.id,
      );
      _socketClient.joinConversation(conversation.id);
    } catch (error) {
      _errorMessage = error.toString();
      rethrow;
    } finally {
      _isOpeningConversation = false;
      notifyListeners();
    }
  }

  Future<void> sendMessage(String body) async {
    final conversationId = _activeConversationId;
    final accessToken = _activeAccessToken;
    final trimmedBody = body.trim();

    if (conversationId == null || accessToken == null || trimmedBody.isEmpty) {
      return;
    }

    _isSending = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final message = await _apiClient.sendMessage(
        accessToken: accessToken,
        conversationId: conversationId,
        body: trimmedBody,
      );
      _mergeMessage(message);
    } catch (error) {
      _errorMessage = error.toString();
      notifyListeners();
      rethrow;
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  Future<void> sendAttachment(
    UploadedAssetModel asset, {
    String? note,
  }) async {
    await sendMessage(encodeChatAttachmentBody(asset, note: note));
  }

  Future<AiAssistantDraftModel> generateAssistantDraft(
    AuthSession session, {
    required AiAssistantDraftIntent intent,
    String? prompt,
  }) async {
    final conversationId = _activeConversationId;
    if (conversationId == null) {
      throw StateError('Open a conversation before using AI drafting.');
    }

    _isDrafting = true;
    _errorMessage = null;
    notifyListeners();
    try {
      return await _aiApiClient.generateAssistantDraft(
        accessToken: session.tokens.accessToken,
        intent: intent,
        conversationId: conversationId,
        prompt: prompt,
      );
    } catch (error) {
      _errorMessage = error.toString();
      rethrow;
    } finally {
      _isDrafting = false;
      notifyListeners();
    }
  }

  ChatParticipantModel? counterpartFor(ConversationModel conversation) {
    final currentUserId = _currentUserId;
    if (currentUserId == null) {
      return conversation.participants.isEmpty ? null : conversation.participants.first;
    }
    return conversation.counterpartFor(currentUserId);
  }

  @override
  void dispose() {
    _socketSubscription.cancel();
    _socketClient.dispose();
    super.dispose();
  }

  void _handleSocketEvent(ChatSocketEvent event) {
    final message = event.message;
    if (event.event != 'message_created' || message == null) {
      return;
    }

    _mergeMessage(message);
    notifyListeners();
  }

  void _mergeMessage(ChatMessageModel message) {
    if (_activeConversationId == message.conversationId &&
        !_activeMessages.any((item) => item.id == message.id)) {
      _activeMessages = [..._activeMessages, message];
    }

    final index = _conversations.indexWhere(
      (conversation) => conversation.id == message.conversationId,
    );

    if (index != -1) {
      final existing = _conversations[index];
      final updated = ConversationModel(
        id: existing.id,
        type: existing.type,
        participants: existing.participants,
        lastMessage: message,
        createdAt: existing.createdAt,
      );
      final next = [..._conversations];
      next.removeAt(index);
      _conversations = [updated, ...next];
    }
  }
}
