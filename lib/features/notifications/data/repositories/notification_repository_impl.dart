import 'package:dartz/dartz.dart';
import 'package:monie/core/errors/exceptions.dart';
import 'package:monie/core/errors/failures.dart';
import 'package:monie/features/notifications/data/datasources/notification_local_data_source.dart';
import 'package:monie/features/notifications/data/datasources/notification_remote_data_source.dart';
import 'package:monie/features/notifications/data/datasources/notification_datasource.dart';
import 'package:monie/features/notifications/data/models/notification_model.dart';
import 'package:monie/features/notifications/domain/entities/notification.dart';
import 'package:monie/features/notifications/domain/repositories/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource remoteDataSource;
  final NotificationLocalDataSource localDataSource;
  final NotificationDataSource dataSource;

  NotificationRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.dataSource,
  });

  // Database operations for notifications
  @override
  Future<List<Notification>> getUserNotifications(String userId) async {
    return await dataSource.getUserNotifications(userId);
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    await dataSource.markAsRead(notificationId);
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    await dataSource.markAllAsRead(userId);
  }

  @override
  Future<void> createNotification(Notification notification) async {
    final notificationModel = NotificationModel(
      id: notification.id,
      userId: notification.userId,
      amount: notification.amount,
      type: notification.type,
      title: notification.title,
      message: notification.message,
      isRead: notification.isRead,
      createdAt: notification.createdAt,
    );
    await dataSource.createNotification(notificationModel);
  }

  @override
  Future<void> createGroupNotifications({
    required String groupId,
    required String title,
    required String message,
    required NotificationType type,
    double? amount,
  }) async {
    await dataSource.createGroupNotifications(
      groupId: groupId,
      title: title,
      message: message,
      type: type,
      amount: amount,
    );
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    await dataSource.deleteNotification(notificationId);
  }

  @override
  Future<int> getUnreadCount(String userId) async {
    return await dataSource.getUnreadCount(userId);
  }

  // Push notification operations with error handling
  @override
  Future<Either<Failure, String>> registerDevice() async {
    try {
      final token = await remoteDataSource.registerDevice();
      return Right(token);
    } on ServerException {
      return const Left(ServerFailure(message: 'Failed to register device'));
    } on PermissionException {
      return const Left(PermissionFailure(message: 'Notification permission denied'));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> updateFcmToken(String token) async {
    try {
      final result = await remoteDataSource.updateFcmToken(token);
      return Right(result);
    } on ServerException {
      return const Left(ServerFailure(message: 'Failed to update FCM token'));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Notification>>> getNotifications() async {
    try {
      final notificationModels = await localDataSource.getCachedNotifications();
      return Right(notificationModels);
    } on CacheException {
      return const Left(CacheFailure(message: 'Failed to get cached notifications'));
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> markNotificationAsRead(String notificationId) async {
    try {
      await localDataSource.markAsRead(notificationId);
      return const Right(true);
    } on CacheException {
      return const Left(CacheFailure(message: 'Failed to mark notification as read'));
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> markAllNotificationsAsRead() async {
    try {
      await localDataSource.markAllAsRead();
      return const Right(true);
    } on CacheException {
      return const Left(CacheFailure(message: 'Failed to mark all notifications as read'));
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteNotificationWithResult(String notificationId) async {
    try {
      await localDataSource.deleteNotification(notificationId);
      return const Right(true);
    } on CacheException {
      return const Left(CacheFailure(message: 'Failed to delete notification'));
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> setupNotificationListeners() async {
    try {
      final result = await remoteDataSource.setupNotificationListeners();
      return Right(result);
    } on ServerException {
      return const Left(ServerFailure(message: 'Failed to setup notification listeners'));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> getFcmToken() async {
    try {
      final token = await remoteDataSource.getFcmToken();
      return Right(token);
    } on ServerException {
      return const Left(ServerFailure(message: 'Failed to get FCM token'));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> sendAppStateChangeNotification(String state) async {
    try {
      final result = await remoteDataSource.sendAppStateChangeNotification(state);
      return Right(result);
    } on ServerException {
      return const Left(ServerFailure(message: 'Failed to send app state change notification'));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
