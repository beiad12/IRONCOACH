import 'package:logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'shared_providers.g.dart';

@Riverpod(keepAlive: true)
Uuid uuid(Ref ref) => const Uuid();

@Riverpod(keepAlive: true)
Logger appLogger(Ref ref) => Logger(printer: PrettyPrinter(methodCount: 1));
