import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var sharedMediaFiles: [String] = []
  private var pendingSharedFiles: [String] = []
  private var sharingChannel: FlutterMethodChannel?
  private var isFlutterReady = false
  private var launchURL: URL?
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Check if app was launched via URL (shared content)
    if let url = launchOptions?[.url] as? URL {
      launchURL = url
      print("App launched with URL: \(url)")
    }
    
    // Set up sharing channel after Flutter is ready
    DispatchQueue.main.async {
      self.setupSharingChannel()
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  private func setupSharingChannel() {
    guard let controller = window?.rootViewController as? FlutterViewController else {
      // Retry setup after a delay if controller is not ready
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        self.setupSharingChannel()
      }
      return
    }
    
    sharingChannel = FlutterMethodChannel(
      name: "depthlab.sharing",
      binaryMessenger: controller.binaryMessenger
    )
    
    sharingChannel?.setMethodCallHandler({ [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
      guard let self = self else { return }
      
      switch call.method {
      case "getInitialSharedMedia":
        // Mark Flutter as ready
        self.isFlutterReady = true
        
        // Process any launch URL
        if let launchURL = self.launchURL {
          self.handleSharedFile(launchURL)
          self.launchURL = nil
        }
        
        // Process any pending shared files
        let allSharedFiles = self.sharedMediaFiles + self.pendingSharedFiles
        result(allSharedFiles)
        
        // Clear processed files
        self.sharedMediaFiles.removeAll()
        self.pendingSharedFiles.removeAll()
        
        print("Flutter ready, processed \(allSharedFiles.count) shared files")
        
      case "flutterReady":
        self.isFlutterReady = true
        self.processPendingSharedFiles()
        result(nil)
        
      default:
        result(FlutterMethodNotImplemented)
      }
    })
    
    print("Sharing channel setup complete")
  }
  
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    
    // Handle file URLs (shared images)
    if url.isFileURL {
      handleSharedFile(url)
      return true
    }
    
    if url.scheme == "depthlab" {
      handleSharedURL(url)
      return true
    }
    
    return super.application(app, open: url, options: options)
  }
  
  private func handleSharedFile(_ url: URL) {
    // Handle actual file sharing
    let path = url.path
    
    // Check if it's an image file
    let allowedExtensions = ["jpg", "jpeg", "png", "gif", "bmp", "heic", "webp"]
    let fileExtension = url.pathExtension.lowercased()
    
    if allowedExtensions.contains(fileExtension) {
      // Start accessing security-scoped resource
      let isAccessingSecurityScopedResource = url.startAccessingSecurityScopedResource()
      
      // Copy file to app's documents directory for access
      if let documentsPath = copyFileToDocuments(from: url) {
        addSharedMediaFile(documentsPath)
      }
      
      if isAccessingSecurityScopedResource {
        url.stopAccessingSecurityScopedResource()
      }
    }
  }
  
  private func copyFileToDocuments(from sourceURL: URL) -> String? {
    let fileManager = FileManager.default
    
    guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
      return nil
    }
    
    let fileName = sourceURL.lastPathComponent
    let destinationURL = documentsDirectory.appendingPathComponent("shared_\(UUID().uuidString)_\(fileName)")
    
    do {
      // Remove existing file if it exists
      if fileManager.fileExists(atPath: destinationURL.path) {
        try fileManager.removeItem(at: destinationURL)
      }
      
      // Copy the file
      try fileManager.copyItem(at: sourceURL, to: destinationURL)
      return destinationURL.path
    } catch {
      print("Error copying shared file: \(error)")
      return nil
    }
  }
  
  private func handleSharedURL(_ url: URL) {
    // Handle custom URL scheme
    let path = url.path
    if !path.isEmpty {
      addSharedMediaFile(path)
    }
  }
  
  override func application(
    _ application: UIApplication,
    continue userActivity: NSUserActivity,
    restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
  ) -> Bool {
    
    // Handle shared content from NSUserActivity
    if userActivity.activityType == NSUserActivityTypeBrowsingWeb {
      if let url = userActivity.webpageURL {
        handleSharedURL(url)
        return true
      }
    }
    
    return super.application(application, continue: userActivity, restorationHandler: restorationHandler)
  }
  
  private func addSharedMediaFile(_ filePath: String) {
    print("Adding shared media file: \(filePath)")
    
    if isFlutterReady && sharingChannel != nil {
      // Flutter is ready, process immediately
      sharedMediaFiles.append(filePath)
      DispatchQueue.main.async { [weak self] in
        self?.sharingChannel?.invokeMethod("onSharedMedia", arguments: [filePath]) { result in
          if let error = result as? FlutterError {
            print("Error notifying Flutter: \(error)")
          }
        }
      }
    } else {
      // Flutter not ready, queue for later processing
      pendingSharedFiles.append(filePath)
      print("Flutter not ready, queued file for later processing")
    }
  }
  
  private func processPendingSharedFiles() {
    guard !pendingSharedFiles.isEmpty else { return }
    
    print("Processing \(pendingSharedFiles.count) pending shared files")
    
    for filePath in pendingSharedFiles {
      sharedMediaFiles.append(filePath)
      DispatchQueue.main.async { [weak self] in
        self?.sharingChannel?.invokeMethod("onSharedMedia", arguments: [filePath]) { result in
          if let error = result as? FlutterError {
            print("Error notifying Flutter about pending file: \(error)")
          }
        }
      }
    }
    
    pendingSharedFiles.removeAll()
  }
}
