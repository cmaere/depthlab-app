import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'services/shared_media_handler.dart';
import 'models/shared_image.dart';
import 'screens/shared_image_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Don't initialize SharedMediaHandler here - do it after the first frame
  // to ensure Flutter is fully ready and avoid cold start crashes
  
  runApp(const DepthlabApp());
}

class DepthlabApp extends StatelessWidget {
  const DepthlabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Depthlab',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  StreamSubscription<SharedImage>? _sharedImageSubscription;
  final List<SharedImage> _receivedImages = [];

  @override
  void initState() {
    super.initState();
    
    if (kDebugMode) {
      debugPrint('HomePage initState called');
    }
    
    // Initialize SharedMediaHandler after the first frame to ensure Flutter is fully ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSharedMediaHandler();
    });
  }

  void _initializeSharedMediaHandler() {
    if (kDebugMode) {
      debugPrint('Initializing SharedMediaHandler after first frame');
    }
    
    try {
      // Ensure SharedMediaHandler is initialized
      if (!SharedMediaHandler.instance.isInitialized) {
        SharedMediaHandler.instance.initialize();
      }
      
      _sharedImageSubscription = SharedMediaHandler.instance.sharedImageStream.listen(
        (SharedImage sharedImage) {
          if (kDebugMode) {
            debugPrint('HomePage received shared image: ${sharedImage.fileName}');
          }
          
          if (mounted) {
            setState(() {
              _receivedImages.insert(0, sharedImage);
            });
            
            // Navigate to the shared image screen
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => SharedImageScreen(sharedImage: sharedImage),
              ),
            );
          } else {
            if (kDebugMode) {
              debugPrint('HomePage not mounted, cannot update UI');
            }
          }
        },
        onError: (error) {
          if (kDebugMode) {
            debugPrint('Error in shared image stream: $error');
          }
        },
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error initializing SharedMediaHandler: $e');
      }
    }
  }

  @override
  void dispose() {
    if (kDebugMode) {
      debugPrint('HomePage dispose called');
    }
    
    _sharedImageSubscription?.cancel();
    _sharedImageSubscription = null;
    
    // Don't dispose the SharedMediaHandler here as it should persist
    // across widget rebuilds and app lifecycle changes
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Depthlab'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _receivedImages.isEmpty
          ? _buildWelcomeScreen()
          : _buildImageHistory(),
    );
  }

  Widget _buildWelcomeScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Welcome to Depthlab',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Share images from your Photos app to see them here!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How to share images:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('1. Open Photos app'),
                    const Text('2. Select an image'),
                    const Text('3. Tap Share button'),
                    const Text('4. Choose Depthlab from the list'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageHistory() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Received Images (${_receivedImages.length})',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _receivedImages.length,
            itemBuilder: (context, index) {
              final sharedImage = _receivedImages[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: ListTile(
                  leading: const Icon(Icons.image),
                  title: Text(sharedImage.fileName),
                  subtitle: Text(
                    'Received: ${sharedImage.receivedAt.toString().split('.').first}',
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => SharedImageScreen(sharedImage: sharedImage),
                      ),
                    );
                  },
                  trailing: const Icon(Icons.arrow_forward_ios),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
