import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../models/shared_image.dart';
import 'image_processor.dart';

class SharedMediaHandler {
  static SharedMediaHandler? _instance;
  static SharedMediaHandler get instance => _instance ??= SharedMediaHandler._();
  
  SharedMediaHandler._();

  static const MethodChannel _channel = MethodChannel('depthlab.sharing');
  
  final StreamController<SharedImage> _sharedImageController = StreamController<SharedImage>.broadcast();
  Stream<SharedImage> get sharedImageStream => _sharedImageController.stream;

  bool _isInitialized = false;
  
  bool get isInitialized => _isInitialized;

  void initialize() {
    if (_isInitialized) {
      if (kDebugMode) {
        debugPrint('SharedMediaHandler already initialized');
      }
      return;
    }

    try {
      // Set up method channel handler
      _channel.setMethodCallHandler(_handleMethodCall);
      
      // Notify iOS that Flutter is ready
      _notifyFlutterReady();
      
      // Request any initial shared media with a delay to ensure iOS is ready
      Future.delayed(const Duration(milliseconds: 100), () {
        _getInitialSharedMedia();
      });

      _isInitialized = true;
      if (kDebugMode) {
        debugPrint('SharedMediaHandler initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error initializing SharedMediaHandler: $e');
      }
    }
  }

  Future<void> _notifyFlutterReady() async {
    try {
      await _channel.invokeMethod('flutterReady');
      if (kDebugMode) {
        debugPrint('Notified iOS that Flutter is ready');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error notifying iOS that Flutter is ready: $e');
      }
    }
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    if (kDebugMode) {
      debugPrint('Received method call: ${call.method}');
    }
    
    switch (call.method) {
      case 'onSharedMedia':
        final List<dynamic> paths = call.arguments as List<dynamic>;
        _handleSharedMediaPaths(paths.cast<String>());
        break;
      default:
        if (kDebugMode) {
          debugPrint('Unknown method call: ${call.method}');
        }
    }
  }

  Future<void> _getInitialSharedMedia() async {
    try {
      if (kDebugMode) {
        debugPrint('Requesting initial shared media from iOS');
      }
      
      final List<dynamic>? paths = await _channel.invokeMethod('getInitialSharedMedia');
      if (paths != null && paths.isNotEmpty) {
        if (kDebugMode) {
          debugPrint('Received initial shared media: ${paths.length} files');
          for (final path in paths) {
            debugPrint('  - $path');
          }
        }
        _handleSharedMediaPaths(paths.cast<String>());
      } else {
        if (kDebugMode) {
          debugPrint('No initial shared media found');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting initial shared media: $e');
      }
      
      // Retry once after a delay if the first attempt fails
      Future.delayed(const Duration(milliseconds: 500), () async {
        try {
          final List<dynamic>? paths = await _channel.invokeMethod('getInitialSharedMedia');
          if (paths != null && paths.isNotEmpty) {
            if (kDebugMode) {
              debugPrint('Retry: Received initial shared media: ${paths.length} files');
            }
            _handleSharedMediaPaths(paths.cast<String>());
          }
        } catch (retryError) {
          if (kDebugMode) {
            debugPrint('Retry failed for initial shared media: $retryError');
          }
        }
      });
    }
  }

  Future<void> _handleSharedMediaPaths(List<String> filePaths) async {
    if (filePaths.isEmpty) {
      if (kDebugMode) {
        debugPrint('No shared files to process');
      }
      return;
    }

    for (final filePath in filePaths) {
      if (kDebugMode) {
        debugPrint('Processing shared file: $filePath');
      }

      if (filePath.isEmpty) {
        if (kDebugMode) {
          debugPrint('Skipping empty file path');
        }
        continue;
      }

      try {
        // Check if file exists
        final file = File(filePath);
        if (!await file.exists()) {
          if (kDebugMode) {
            debugPrint('File does not exist: $filePath');
          }
          continue;
        }

        if (ImageProcessor.isValidImageFile(filePath)) {
          if (kDebugMode) {
            debugPrint('Processing valid image file: $filePath');
          }
          
          final sharedImage = await ImageProcessor.processImage(filePath);
          
          if (!_sharedImageController.isClosed) {
            _sharedImageController.add(sharedImage);
            if (kDebugMode) {
              debugPrint('Successfully processed and added shared image');
            }
          } else {
            if (kDebugMode) {
              debugPrint('Cannot add shared image - controller is closed');
            }
          }
        } else {
          if (kDebugMode) {
            debugPrint('File is not a valid image: $filePath');
          }
        }
      } catch (e, stackTrace) {
        if (kDebugMode) {
          debugPrint('Error processing shared image: $e');
          debugPrint('Stack trace: $stackTrace');
        }
      }
    }
  }

  void dispose() {
    if (kDebugMode) {
      debugPrint('Disposing SharedMediaHandler');
    }
    
    // Remove method channel handler
    _channel.setMethodCallHandler(null);
    
    if (!_sharedImageController.isClosed) {
      _sharedImageController.close();
    }
    
    _isInitialized = false;
  }

  void reset() {
    if (kDebugMode) {
      debugPrint('Resetting SharedMediaHandler');
    }
    dispose();
    _instance = null;
  }
}