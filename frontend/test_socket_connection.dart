// ignore_for_file: avoid_print

import 'package:socket_io_client/socket_io_client.dart' as io;

void main() async {
  print('Testing Socket.IO connection to backend...');
  
  // Create socket connection with authentication token in handshake
  final socket = io.io(
    'http://localhost:8000',
    io.OptionBuilder()
      .setTransports(['websocket'])
      .enableAutoConnect()
      .setExtraHeaders({
        'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJhY2ExNjUxZS03NmM0LTQ4ZjItYTIzNi04MTdhYjIyNzg3YTAiLCJlbWFpbCI6InRlc3RAZXhhbXBsZS5jb20iLCJyb2xlIjoidGVhbV9tZW1iZXIiLCJ0eXBlIjoiYWNjZXNzIiwiaWF0IjoxNzYyNzYzNTAxLCJleHAiOjE3NjI4NDk5MDF9.e3SsJ2fvM7RK-MZ0ZfFqEJA24-U0w5WE0xDtIFs4uwI',
      })
      .build(),
  );

  // Set up event handlers
  socket
    ..onConnect((_) => print('✅ Connected to Socket.IO server'))
    ..onDisconnect((_) => print('❌ Disconnected from Socket.IO server'))
    ..onError((data) => print('⚠️ Socket error: \$data'))
    ..on('connect_error', (data) => print('⚠️ Connection error: \$data'))
    ..on('connected', (data) => print('✅ Socket connection confirmed: \$data'))
    ..on('user_online', (data) => print('👤 User online: \$data'))
    ..on('user_offline', (data) => print('👤 User offline: \$data'));

  // Connect to server
  socket.connect();
  
  // Wait for connection
  await Future.delayed(const Duration(seconds: 10));
  
  print('Socket connection test completed');
  socket.disconnect();
}