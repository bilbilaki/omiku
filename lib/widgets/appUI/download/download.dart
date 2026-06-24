import 'dart:math';

import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/material.dart';
import 'package:omiku/services/contentApi/movie_service.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:lottie/lottie.dart';

// --- Placeholder for MovieService and DownloadTask/FileDownloader ---
// These are minimal implementations to allow the provided DownloadItem class
// to compile and run without needing actual external packages.
// In a real application, you would integrate actual packages like
// 'flutter_downloader' for file downloads and an API client for movie services.


  // This is a dummy implementation. In a real app, this would get the actual
  // temporary path where the file is being downloaded.


// --- End of placeholder services ---

// --- getTargetDirectory function ---
// This function needs access to `Platform` from 'dart:io' and `p` from 'package:path/path.dart'.
Future<Directory> getTargetDirectory({
  required String folderUnderApp,
  String userSubdir = '',
  String appFolderName = 'Miko',
  bool ensureExists = true,
}) async {
  late final Directory baseDir;
  if (Platform.isAndroid) {
    // For Android, usually `/storage/emulated/0/Download` is the public Downloads folder.
    // However, direct access requires MANAGE_EXTERNAL_STORAGE on Android 11+, which is highly restrictive.
    // For safer internal storage, or app-specific external, consider getExternalStorageDirectory()
    // or getApplicationDocumentsDirectory().
    // For this example, assuming permission for public Download is granted or it's an older Android version.
    baseDir = Directory('/storage/emulated/0/Download');
  } else if (Platform.isLinux) {
    baseDir = Directory(p.join(Platform.environment['HOME']!, 'Downloads'));
  } else if (Platform.isWindows) {
    baseDir = Directory(
      p.join(Platform.environment['USERPROFILE']!, 'Downloads'),
    );
  } else {
    // For iOS, macOS, Web (though downloads are browser-managed), and other platforms
    final Directory? downloadsDir = await getDownloadsDirectory();
    baseDir = downloadsDir ?? await getApplicationDocumentsDirectory();
  }

  String targetPath = p.join(baseDir.path, appFolderName);
  if (folderUnderApp.isNotEmpty) {
    targetPath = p.join(targetPath, folderUnderApp);
  }
  if (userSubdir.isNotEmpty) {
    targetPath = p.join(targetPath, userSubdir);
  }

  final dir = Directory(targetPath);

  if (ensureExists && !await dir.exists()) {
    try {
      await dir.create(recursive: true);
    } catch (e) {
      print('Error creating directory $targetPath: $e');
      // Handle error, e.g., show a user message or fall back to a different directory.
      // For this example, we'll proceed with the directory object even if creation failed,
      // subsequent file operations will then likely fail.
    }
  }
  return dir;
}

// --- DownloadItem class (Modified for UI state) ---
class DownloadItem {
  final bool isMovie;
  final int idC;
  final int? sessionNumber;
  final int? episodeNumber;
  final String? name;
  DownloadTask task;
  String? path; // This will store the final renamed path
  String? tempDownloadPath; // This will store the path during download process

  // UI specific fields, should be updated and then notify listeners
  String? imageUrl; // To hold the poster path
  double currentProgress; // For progress bar
  TaskStatus status; // To show current status (running, paused, complete, etc.)

  void Function(double)? _onProgressUpdate; // Internal callback for UI updates
  void Function(TaskStatus)?
  _onStatusUpdate; // Internal callback for UI updates
  MovieService movieService;

  DownloadItem(
    this.path,
    this.episodeNumber,
    this.sessionNumber,
    this.name, {
    required this.isMovie,
    required this.task,
    required this.idC,
    required this.movieService,
    this.imageUrl,
    this.currentProgress = 0.0,
    this.status = TaskStatus.enqueued,
  }) {
    // We explicitly call run() outside in DownloadListManager.addDownload
    // or let it run when the item is created. For this example, it's called
    // in the constructor as per the original code.
    run();
  }

  // Setters for UI callbacks
  set onProgress(void Function(double)? callback) =>
      _onProgressUpdate = callback;
  set onStatus(void Function(TaskStatus)? callback) =>
      _onStatusUpdate = callback;

  Future<void> run() async {
    _onStatusUpdate?.call(TaskStatus.enqueued); // Notify enqueued status
    await pre();
    await post();
  }

  Future<void> pre() async {
    await prePair();
  }

  Future<void> prePair() async {
    // Fetch image URL regardless of path being null or not, so UI can display it
    if (isMovie) {
      final realItem = await movieService.getMovieDetailsNetwork(idC);
      imageUrl = realItem.moviedetail.posterPath;
      if (path == null) {
        Directory setDefaultPathIfNoneSet = await getTargetDirectory(
          folderUnderApp: "Downloads",
        );
        String origName = realItem.metaData.title;
        String fileName = name?.isEmpty==true ? (origName.isEmpty==true?task.filename:origName): (origName.isEmpty == true ? task.filename : origName);
        // Construct targetPath for movie: baseDir/Miko/Downloads/MovieTitle/MovieTitle.mp4
        final finalDirPath = p.join(setDefaultPathIfNoneSet.path, fileName);
        path = p.join(finalDirPath, fileName); // Assuming .mp4 extension
      }
    } else {
      final realItem = await movieService.getTvShowDetailsNetwork(idC);
      imageUrl = realItem.tvDetails?.posterPath;
      if (path == null) {
        Directory setDefaultPathIfNoneSet = await getTargetDirectory(
          folderUnderApp: "Downloads",
        );
        String origName = realItem.tvDetails!.name;
        String fileName = name ?? origName;
        final sessionStr = sessionNumber != null
            ? 'S${sessionNumber.toString().padLeft(2, '0')}'
            : '';
        final episodeStr = episodeNumber != null
            ? 'E${episodeNumber.toString().padLeft(2, '0')}'
            : '';
        // Construct targetPath for TV show: baseDir/Miko/Downloads/TVShowName/S<session>/E<episode>/<filename>.mp4
        final finalDirPath = p.join(
          setDefaultPathIfNoneSet.path,
          fileName,
          sessionStr,
        );
        path = p.join(
          finalDirPath,
          "${fileName}_$sessionStr$episodeStr.mp4",
        ); // Assuming .mp4
      }
    }

    // Ensure the directory for the final path exists before attempting transfer
    if (path != null) {
      final targetDir = Directory(p.dirname(path!));
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }
    }
  }

  Future<void> post() async {
    await inDownloading();
  }

  Future<void> inDownloading() async {
    try {
      _onStatusUpdate?.call(
        TaskStatus.running,
      ); // Notify UI that download is running

      final result = await FileDownloader().download(
        task,
        onProgress: (progress) {
          currentProgress = progress;
          _onProgressUpdate?.call(progress); // Notify UI of progress changes
        },
        onStatus: (s) {
          status = s; // Update internal status
          _onStatusUpdate?.call(s); // Notify UI of status changes
        },
      );

      switch (result.status) {
        case TaskStatus.complete:
          print('Download complete for ${task.taskId}');
          tempDownloadPath = await result.task
              .filePath(); // Get the temporary download path
          await inTransfering(tempDownloadPath!);
          _onStatusUpdate?.call(TaskStatus.complete);
          break;
        case TaskStatus.canceled:
          print('Download was canceled');
          _onStatusUpdate?.call(TaskStatus.canceled);
          break;
        case TaskStatus.paused:
          print('Download was paused');
          _onStatusUpdate?.call(TaskStatus.paused);
          break;
        case TaskStatus.failed:
          print('Download failed');
          _onStatusUpdate?.call(TaskStatus.failed);
          break;
        default:
          print('Download not successful (status: ${result.status})');
          _onStatusUpdate?.call(TaskStatus.failed);
          break;
      }
    } catch (e) {
      print('Download error for ${task.taskId}: ${e.toString()}');
      _onStatusUpdate?.call(TaskStatus.failed);
    }
  }

  Future<void> pauseDownload() async {
    await FileDownloader().pause(task);
    _onStatusUpdate?.call(TaskStatus.paused);
  }

  Future<void> cancelDownload() async {
    await FileDownloader().cancelTaskWithId(task.taskId).whenComplete(() {
      _onStatusUpdate?.call(TaskStatus.canceled);
    });
  }

  Future<void> resumeDownload() async {
    await FileDownloader().resume(task);
    _onStatusUpdate?.call(TaskStatus.running); // Assuming resume starts it
  }

  Future<void> inTransfering(String sourceFile) async {
    if (path == null) {
      print('Error: Target path is null for transferring file: $sourceFile');
      _onStatusUpdate?.call(TaskStatus.failed);
      return;
    }
    try {
      final File source = File(sourceFile);
      if (await source.exists()) {
        final target = File(path!);
        // Ensure the target directory exists (prePair already does this, but good to re-check)
        final targetDir = Directory(p.dirname(path!));
        if (!await targetDir.exists()) {
          await targetDir.create(recursive: true);
        }
        await source.rename(target.path);
        print('File moved successfully to ${target.path} from $sourceFile');
      } else {
        print('Source file does not exist for transfer: $sourceFile');
        _onStatusUpdate?.call(TaskStatus.failed);
      }
    } catch (e) {
      print('Failed to move file from $sourceFile to $path: $e');
      _onStatusUpdate?.call(TaskStatus.failed);
    }
  }
}

// --- DownloadListManager to hold and notify about DownloadItems ---
class DownloadListManager extends ValueNotifier<List<DownloadItem>> {
  DownloadListManager() : super([]);

  void addDownload(DownloadItem item) {
    // Attach listeners to the item to update the UI
    item.onProgress = (progress) {
      // Find the item and update its progress, then notify
      final index = value.indexWhere(
        (element) => element.task.taskId == item.task.taskId,
      );
      if (index != -1) {
        value[index].currentProgress = progress;
        notifyListeners();
      }
    };
    item.onStatus = (status) {
      // Find the item and update its status, then notify
      final index = value.indexWhere(
        (element) => element.task.taskId == item.task.taskId,
      );
      if (index != -1) {
        value[index].status = status;
        notifyListeners();
      }
    };

    value = [...value, item]; // Add to list and notify listeners
  }

  void removeDownload(DownloadItem item) {
    item.cancelDownload(); // Attempt to cancel the ongoing download
    value = List.from(value)..remove(item); // Remove from list and notify
  }

  // Example for handling item interaction (e.g., tap to retry/resume)
  void handleItemTap(DownloadItem item) {
    switch (item.status) {
      case TaskStatus.paused:
        item.resumeDownload();
        break;
      case TaskStatus.failed:
        // For failed, you might want to restart the download or offer retry options.
        // For simplicity, let's just re-enqueue it.
        print('Retrying download for ${item.task.taskId}');
        item.currentProgress = 0.0;
        item.status = TaskStatus.enqueued;
        item.run(); // Restart the download process
        break;
      default:
        // For complete items, maybe open the file. For running, maybe show progress dialog.
        print('Tapped on item in status: ${item.status}');
        break;
    }
  }
}

// --- DownloadListItem Widget ---
class DownloadListItem extends StatelessWidget {
  final DownloadItem item;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const DownloadListItem({
    super.key,
    required this.item,
    required this.onDelete,
    required this.onTap,
  });

  String _formatEpisodeInfo() {
    if (item.isMovie) {
      return 'Movie'; // Or actual movie info
    } else {
      String info = '';
      if (item.sessionNumber != null) {
        info += 'S${item.sessionNumber.toString().padLeft(2, '0')}';
      }
      if (item.episodeNumber != null) {
        info += 'E${item.episodeNumber.toString().padLeft(2, '0')}';
      }
      return info.isNotEmpty ? info : 'Episode';
    }
  }

  String _getDownloadSizeDisplay() {
    // This is a dummy for display. In a real app, `FileDownloader` might
    // provide total size and current size.
    final totalSizeMB =
        200 + (item.idC % 5 * 10) + (item.episodeNumber ?? 0) * 5;
    final currentSizeMB = (totalSizeMB * item.currentProgress);

    switch (item.status) {
      case TaskStatus.running:
        return '${currentSizeMB.toStringAsFixed(1)} / ${totalSizeMB.toStringAsFixed(1)} MB';
      case TaskStatus.complete:
        return '${totalSizeMB.toStringAsFixed(1)} MB';
      case TaskStatus.paused:
      case TaskStatus.failed:
      case TaskStatus.enqueued:
      case TaskStatus.canceled:
      default:
        return '--- MB'; // Or provide an estimated size if available
    }
  }

  String _getStatusText() {
    switch (item.status) {
      case TaskStatus.enqueued:
        return 'Queued';
      case TaskStatus.running:
        return '${(item.currentProgress * 100).toInt()}%';
      case TaskStatus.complete:
        return 'Completed';
      case TaskStatus.failed:
        return 'Failed';
      case TaskStatus.canceled:
        return 'Canceled';
      case TaskStatus.paused:
        return 'Paused';
      case TaskStatus.notFound:
      return 'notFound';
        // TODO: Handle this case.
      case TaskStatus.waitingToRetry
      :return 'waitingToRetry';
        // TODO: Handle this case.
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDownloadingOrPaused =
        item.status == TaskStatus.running ||
        item.status == TaskStatus.enqueued ||
        item.status == TaskStatus.paused;

    return GestureDetector(
      onTap: onTap, // Handle tap for retry/resume logic
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color:
              theme.colorScheme.surface, // Dark grey for list item background
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Image and Play Icon Overlay
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  item.imageUrl != null && item.imageUrl!.isNotEmpty
                      ? Image.network(
                          item.imageUrl!,
                          width: 90,
                          height: 120,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                width: 90,
                                height: 120,
                                color: Colors.grey.shade800,
                                child: const Icon(
                                  Icons.broken_image,
                                  color: Colors.white70,
                                ),
                              ),
                        )
                      : Container(
                          width: 90,
                          height: 120,
                          color: Colors.grey.shade800,
                          child: const Icon(
                            Icons.movie_filter_outlined,
                            color: Colors.white70,
                          ),
                        ),
                  // Static play button (as seen in image)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 128),
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(4.0),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16.0),
            // Title, Episode, Size/Progress, Status
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name ??
                        (item.isMovie ? 'Unknown Movie' : 'Unknown Series'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    _formatEpisodeInfo(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  if (isDownloadingOrPaused)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LinearProgressIndicator(
                          value: item.currentProgress,
                          backgroundColor: Colors.grey.shade700,
                          color: Colors.green.shade600,
                        ),
                        const SizedBox(height: 4.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _getDownloadSizeDisplay(),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white54,
                              ),
                            ),
                            Text(
                              _getStatusText(),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: item.status == TaskStatus.paused
                                    ? Colors.orange.shade400
                                    : (item.status == TaskStatus.enqueued
                                          ? Colors.blue.shade400
                                          : Colors.green.shade400),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  else if (item.status == TaskStatus.complete)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 4.0,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade700.withValues(alpha: 77),
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: Text(
                        _getDownloadSizeDisplay(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.green.shade300,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else if (item.status == TaskStatus.failed)
                    Text(
                      'Failed: Tap to retry',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.red.shade400,
                      ),
                    ),
                ],
              ),
            ),
            // Delete Icon
            IconButton(
              icon: Icon(Icons.delete_outline, color: Colors.grey.shade500),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

// --- DownloadScreen Widget ---
class DownloadScreen extends StatefulWidget {
  final DownloadListManager downloadManager;

  const DownloadScreen({super.key, required this.downloadManager});

  @override
  State<DownloadScreen> createState() => _DownloadScreenState();
}

class _DownloadScreenState extends State<DownloadScreen> {
    final _urlController = TextEditingController();
  final _fileNameController = TextEditingController();
  final _sessionNumberController = TextEditingController();
  final _episodeNumberController = TextEditingController();
  final _idCController = TextEditingController();
  bool _isMovie = false;
  final _formKey = GlobalKey<FormState>(); // Key for form validation

  @override
  void dispose() {
    _urlController.dispose();
    _fileNameController.dispose();
    _sessionNumberController.dispose();
    _episodeNumberController.dispose();
    _idCController.dispose();
    super.dispose();
  }
 @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black, // Overall dark background
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AppBar(
          backgroundColor: Colors.transparent, // Transparent to blend with scaffold
          elevation: 0,
          title: Row(
            children: [
              // Green "A" logo
              Container(
                padding: const EdgeInsets.all(4.0),
                decoration: BoxDecoration(
                  color: Colors.green.shade600,
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Text(
                  'A',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8.0),
              Text(
                'Download',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.search, color: Colors.white),
              onPressed: () {
                // Handle search functionality
                print('Search icon pressed');
              },
            ),
          ],
        ),
      ),
      body: ValueListenableBuilder<List<DownloadItem>>(
        valueListenable: widget.downloadManager,
        builder: (context, downloads, child) {
          if (downloads.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Lottie.asset(
                      'assets/Lottie/empty_list.json',
                      width: 200,
                      height: 200,
                      fit: BoxFit.contain,
                      repeat: true, // Loop the animation
                    ),
                    const SizedBox(height: 20.0),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Your ',
                            style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white),
                          ),
                          TextSpan(
                            text: 'Download is Empty',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: Colors.green.shade600, // Green highlight
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      'Looks like you haven\'t downloaded anything yet', // Updated text
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      onPressed: () => _showAddDownloadDialog(), // Call the dialog function
                      icon: const Icon(Icons.add, color: Colors.black),
                      label: Text(
                        'Add a Download',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: Colors.black,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          } else {
            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              itemCount: downloads.length,
              itemBuilder: (context, index) {
                final item = downloads[index];
                return DownloadListItem(
                  item: item,
                  onDelete: () {
                    widget.downloadManager.removeDownload(item);
                  },
                  onTap: () {
                    widget.downloadManager.handleItemTap(item);
                  },
                );
              },
            );
          }
        },
      ),
    );
  }

    Future<void> _showAddDownloadDialog() async {
    // Reset controllers and state for a fresh dialog
    _urlController.clear();
    _fileNameController.clear();
    _sessionNumberController.clear();
    _episodeNumberController.clear();
    _idCController.clear();
    _isMovie = false;

    return showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        // Use a StatefulWidget inside the dialog to manage its internal state (like checkbox)
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              backgroundColor: Theme.of(
                context,
              ).colorScheme.surface, // Dark grey background
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                'Add New Download',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: Colors.white),
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _urlController,
                        decoration: InputDecoration(
                          labelText: 'Download URL',
                          hintText: 'e.g., https://example.com/video.mp4',
                          labelStyle: TextStyle(color: Colors.white70),
                          hintStyle: TextStyle(color: Colors.white54),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey.shade700),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        style: TextStyle(color: Colors.white),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'URL cannot be empty';
                          }
                          if (!Uri.tryParse(value)!.hasAbsolutePath == true) {
                            return 'Enter a valid URL';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _fileNameController,
                        decoration: InputDecoration(
                          labelText: 'File Name (Optional)',
                          hintText: 'e.g., MyCoolVideo.mp4',
                          labelStyle: TextStyle(color: Colors.white70),
                          hintStyle: TextStyle(color: Colors.white54),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey.shade700),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        style: TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Checkbox(
                            value: _isMovie,
                            onChanged: (bool? value) {
                              setState(() {
                                _isMovie = value ?? false;
                              });
                            },
                            activeColor: Theme.of(context).colorScheme.primary,
                            checkColor: Colors.black,
                          ),
                          Text(
                            'Is a Movie?',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (!_isMovie) ...[
                        TextFormField(
                          controller: _sessionNumberController,
                          decoration: InputDecoration(
                            labelText: 'Session Number (Optional)',
                            hintText: 'e.g., 1',
                            labelStyle: TextStyle(color: Colors.white70),
                            hintStyle: TextStyle(color: Colors.white54),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.grey.shade700,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _episodeNumberController,
                          decoration: InputDecoration(
                            labelText: 'Episode Number (Optional)',
                            hintText: 'e.g., 5',
                            labelStyle: TextStyle(color: Colors.white70),
                            hintStyle: TextStyle(color: Colors.white54),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.grey.shade700,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 16),
                      ],
                      TextFormField(
                        controller: _idCController,
                        decoration: InputDecoration(
                          labelText:
                              'Content ID (Optional - Auto-generated if empty)',
                          hintText: 'e.g., 12345',
                          labelStyle: TextStyle(color: Colors.white70),
                          hintStyle: TextStyle(color: Colors.white54),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey.shade700),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: Colors.white),
                        validator: (value) {
                          if (value != null &&
                              value.isNotEmpty &&
                              int.tryParse(value) == null) {
                            return 'Must be a valid number';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(); // Close dialog
                  },
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey.shade400),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      final url = _urlController.text.trim();
                      final fileName = _fileNameController.text.trim();
                      final sessionNumber = int.tryParse(
                        _sessionNumberController.text.trim(),
                      );
                      final episodeNumber = int.tryParse(
                        _episodeNumberController.text.trim(),
                      );
                      final idC =
                          int.tryParse(_idCController.text.trim()) ??
                          Random().nextInt(1000000); // Generate if empty

                      final newItem = DownloadItem(
                        null, // Path will be determined by getTargetDirectory
                        episodeNumber,
                        sessionNumber,
                        fileName.isNotEmpty
                            ? fileName
                            : null, // Pass null if empty
                        isMovie: _isMovie,
                        task: DownloadTask(
                          url: url,
                          taskId:
                              'user_dl_${DateTime.now().millisecondsSinceEpoch}', // Unique task ID
                          filename: fileName.isNotEmpty ? fileName : null,
                        ),
                        idC: idC,
                        movieService:
                            MovieService(), // Use your MovieService instance
                      );

                      widget.downloadManager.addDownload(newItem);
                      Navigator.of(dialogContext).pop(); // Close dialog
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primary, // Green button
                    foregroundColor: Theme.of(
                      context,
                    ).colorScheme.onPrimary, // Black text on green
                  ),
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

}

// --- Main Application Widget ---
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize the download manager once and pass it down
  final downloadManager = DownloadListManager();

  // Add some initial dummy downloads to populate the list view for testing.
  // These will automatically start their `run()` method upon creation.
  downloadManager.addDownload(
    DownloadItem(
      null, // path will be set internally
      24, // episodeNumber
      1, // sessionNumber
      'Demon Slayer: Kimetsu no Yaiba Entertainment District Arc', // name
      isMovie: false,
      task: DownloadTask(
        url: 'https://example.com/demonslayer.mp4',
        taskId: 'ds_ep24_1',
        filename: 'demon_slayer_ep24.mp4',
      ),
      idC: 12345, // Dummy ID
      movieService: MovieService(),
      // Initial state to demonstrate a download in progress
      currentProgress: 0.25,
      status: TaskStatus.running,
    ),
  );

  downloadManager.addDownload(
    DownloadItem(
      null,
      5,
      1,
      'Spy x Family',
      isMovie: false,
      task: DownloadTask(
        url: 'https://example.com/spyxfamily.mp4',
        taskId: 'sxf_ep05_1',
        filename: 'spy_x_family_ep05.mp4',
      ),
      idC: 67890,
      movieService: MovieService(),
      // Initial state to demonstrate a completed download
      currentProgress: 1.0,
      status: TaskStatus.complete,
    ),
  );

  downloadManager.addDownload(
    DownloadItem(
      null,
      1080,
      1, // Assuming session 1 for TV shows if not specified
      'One Piece',
      isMovie: false,
      task: DownloadTask(
        url: 'https://example.com/onepiece.mp4',
        taskId: 'op_ep1080_1',
        filename: 'one_piece_ep1080.mp4',
      ),
      idC: 11223,
      movieService: MovieService(),
      // Initial state to demonstrate a paused download
      currentProgress: 0.5,
      status: TaskStatus.paused,
    ),
  );

  downloadManager.addDownload(
    DownloadItem(
      null,
      12,
      4,
      'Attack on Titan: Final Season Part 2',
      isMovie: false,
      task: DownloadTask(
        url: 'https://example.com/aot.mp4',
        taskId: 'aot_ep12_1',
        filename: 'aot_ep12.mp4',
      ),
      idC: 98765,
      movieService: MovieService(),
      currentProgress: 0.0,
      status: TaskStatus.enqueued, // Example: Enqueued, not yet started
    ),
  );

  downloadManager.addDownload(
    DownloadItem(
      null,
      4,
      1,
      'Chainsaw Man',
      isMovie: false,
      task: DownloadTask(
        url: 'https://example.com/chainsawman.mp4',
        taskId: 'csm_ep04_1',
        filename: 'chainsaw_man_ep04.mp4',
      ),
      idC: 54321,
      movieService: MovieService(),
      currentProgress: 0.7,
      status: TaskStatus.running,
    ),
  );

  downloadManager.addDownload(
    DownloadItem(
      null,
      null, // This could be a movie or just a placeholder for a series part
      null,
      'Jujutsu Kaisen: Season 2',
      isMovie: false,
      task: DownloadTask(
        url: 'https://example.com/jujutsukaisen.mp4',
        taskId: 'jk_s2_full',
        filename: 'jujutsu_kaisen_s2.mp4',
      ),
      idC: 22334,
      movieService: MovieService(),
      currentProgress: 1.0,
      status: TaskStatus.complete,
    ),
  );

  runApp(MyApp(downloadManager: downloadManager));
}

class MyApp extends StatelessWidget {
  final DownloadListManager downloadManager;

  const MyApp({super.key, required this.downloadManager});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Download App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors
            .green, // Primary color for app (e.g., buttons, progress indicators)
        scaffoldBackgroundColor:
            Colors.black, // Background for the entire screen
        appBarTheme: const AppBarTheme(
          backgroundColor:
              Colors.transparent, // AppBar background matches scaffold
          elevation: 0,
        ),
        colorScheme: ColorScheme.dark(
          primary: Colors.green.shade600,
          onPrimary: Colors.black,
          surface: Colors.grey.shade900, // Used for list item backgrounds
          onSurface: Colors.white,
        ),
        textTheme:
            TextTheme(
              headlineSmall: const TextStyle(color: Colors.white),
              titleLarge: const TextStyle(color: Colors.white),
              titleMedium: const TextStyle(color: Colors.white),
              bodyMedium: TextStyle(color: Colors.white70),
              bodySmall: TextStyle(color: Colors.white54),
              labelLarge: const TextStyle(color: Colors.black),
            ).apply(
              bodyColor: Colors.white, // Default text color
              displayColor: Colors.white, // For larger text
            ),
      ),
      home: DownloadScreen(downloadManager: downloadManager),
    );
  }
}
