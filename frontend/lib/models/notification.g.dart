// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$NotificationImpl _$$NotificationImplFromJson(Map<String, dynamic> json) =>
    _$NotificationImpl(
      id: (json['id'] as num).toInt(),
      recipientId: (json['recipientId'] as num).toInt(),
      senderId: (json['senderId'] as num?)?.toInt(),
      type: json['type'] as String,
      message: json['message'] as String,
      payload: json['payload'] as Map<String, dynamic>?,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$NotificationImplToJson(_$NotificationImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'recipientId': instance.recipientId,
      'senderId': instance.senderId,
      'type': instance.type,
      'message': instance.message,
      'payload': instance.payload,
      'isRead': instance.isRead,
      'createdAt': instance.createdAt.toIso8601String(),
    };
