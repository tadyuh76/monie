import 'package:dartz/dartz.dart';
import 'package:monie/core/errors/exceptions.dart';
import 'package:monie/core/errors/failures.dart';
import 'package:monie/features/notifications/data/datasources/notification_local_data_source.dart';
import 'package:monie/features/notifications/data/datasources/notification_remote_data_source.dart';
import 'package:monie/features/notifications/data/models/notification_model.dart';
import 'package:monie/features/notifications/domain/entities/notification.dart';
import 'package:monie/features/notifications/domain/repositories/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource remoteDataSource;
  final NotificationLocalDataSource localDataSource;

  NotificationRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

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
  Future<Either<Failure, bool>> markAsRead(String notificationId) async {
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
  Future<Either<Failure, bool>> markAllAsRead() async {
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
  Future<Either<Failure, bool>> deleteNotification(String notificationId) async {
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