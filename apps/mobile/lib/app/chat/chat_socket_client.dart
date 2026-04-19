import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'chat_api_client.dart';
import 'chat_models.dart';

class ChatSocketEvent {
  const ChatSocketEvent({
    required this.event,
    this.message,
  });

  final String event;
  final ChatMessageModel? message;
}

class ChatSocketClient {
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  final _eventsController = StreamController<ChatSocketEvent>.broadcast();
  String? _connectedToken;

  Stream<ChatSocketEvent> get events => _eventsController.stream;

  void connect(String accessToken) {
    if (_connectedToken == accessToken && _channel != null) {
      return;
    }

    disconnect();
    _connectedToken = accessToken;
    _channel = WebSocketChannel.connect(
      Uri.parse('${_toSocketBaseUrl()}?token=$accessToken'),
    );
    _subscription = _channel!.stream.listen(_handleRawEvent);
  }

  void joinConversation(String conversationId) {
    _send({
      'event': 'join_conversation',
      'data': {'conversationId': conversationId},
    });
  }

  void sendMessage({
    required String conversationId,
    required String body,
  }) {
    _send({
      'event': 'send_message',
      'data': {
        'conversationId': conversationId,
        'body': body,
      },
    });
  }

  void disconnect() {
    _subscription?.cancel();
    _subscription = null;
    _channel?.sink.close();
    _channel = null;
    _connectedToken = null;
  }

  void dispose() {
    disconnect();
    _eventsController.close();
  }

  void _send(Map<String, dynamic> payload) {
    _channel?.sink.add(jsonEncode(payload));
  }

  void _handleRawEvent(dynamic raw) {
    if (raw is! String) {
      return;
    }

    final dynamic decoded = jsonDecode(raw);
    if (decoded is! Map) {
      return;
    }

    final map = Map<String, dynamic>.from(decoded);
    final event = map['event'] as String?;
    if (event == null) {
      return;
    }

    if (event == 'message_created' && map['data'] is Map) {
      _eventsController.add(
        ChatSocketEvent(
          event: event,
          message: ChatMessageModel.fromJson(
            Map<String, dynamic>.from(map['data'] as Map),
          ),
        ),
      );
      return;
    }

    _eventsController.add(ChatSocketEvent(event: event));
  }

  String _toSocketBaseUrl() {
    final apiBaseUrl = ChatApiClient.baseUrl;
    final uri = Uri.parse(apiBaseUrl);
    final scheme = uri.scheme == 'https' ? 'wss' : 'ws';
    final path = uri.path.endsWith('/api')
        ? uri.path.substring(0, uri.path.length - 4)
        : uri.path;
    final socketPath = path.isEmpty ? '/chat' : '$path/chat';
    return uri.replace(scheme: scheme, path: socketPath, query: '').toString();
  }
}
