import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:omiku/main.dart';
import 'package:omiku/models/models.dart';
import 'package:omiku/services/localfiles/local_file_playlist_service.dart';
import 'package:path/path.dart' as p;

//var userdata = UserDataService().decoderPreference;

// ignore: must_be_immutable
class VideoPlayerScreenPl extends StatefulWidget {
  String seriesname;
  int tvSeriesId;
  Season season;
  List<Episode> playlist;
  int initialIndex;
  String url;
  bool isLocalSource = false;

  VideoPlayerScreenPl({
    required this.seriesname,
    required this.tvSeriesId,
    required this.season,
    required this.playlist,
    required this.initialIndex,
    required this.url,
    super.key,
  });

  @override
  State<VideoPlayerScreenPl> createState() => VideoPlayerScreenPlState();
}

class VideoPlayerScreenPlState extends State<VideoPlayerScreenPl> {
  Player player = Player();
  late final VideoController controller = VideoController(player);
  bool showControls = true;
  bool showEpisodeList = false;
  bool isFullScreen = false;
  bool isMuted = false;
  bool isPiPEnabled = false;
  Timer? _progressSaveTimer; // Timer to periodically save progress
  final ScrollController _seasonsScrollController = ScrollController();
  String urlToPlayQuality = '';
  double subtitleSize = 32.0;
  Color subtitleColor = const Color.fromARGB(255, 238, 230, 5);
  bool showSubtitleControls = false;
  late int currentIndex;
  Episode? get currentEpisode =>
      widget.playlist.isNotEmpty ? widget.playlist[currentIndex] : null;
  StreamSubscription? _completedSubscription;
  StreamSubscription? _errorSubscription;
  bool showSettings = false;
  Timer? _hideTimer;
  String currentQuality = 'Auto';
  bool streamHasError = false;
  late List<Episode> epiz;
  String formatDuration(Duration duration) {
    String hours = duration.inHours.toString().padLeft(2, '0');
    String minutes = duration.inMinutes
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    String seconds = duration.inSeconds
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    if (duration.inHours > 0) {
      return "$hours:$minutes:$seconds";
    }
    return "$minutes:$seconds";
  }

  List<BoxFit> fitOptions = [
    BoxFit.contain, // Standard
    BoxFit.cover, // Fill/Crop
    BoxFit.fill, // Stretch
    BoxFit.fitWidth,
    BoxFit.fitHeight,
  ];
  int currentFitIndex = 0;
  BoxFit get currentFit => fitOptions[currentFitIndex];
  final Map<BoxFit, IconData> _fitIcons = {
    BoxFit.contain: Icons.fullscreen_exit,
    BoxFit.cover: Icons.fullscreen,
    BoxFit.fill: Icons.photo_size_select_large,
    BoxFit.fitWidth: Icons.swap_horiz,
    BoxFit.fitHeight: Icons.swap_vert,
  };

  List<String> choicelist = ['Auto', '1080p', '720p', '540', '480p', 'DUBBED'];

  Future<Map<String, String?>> getAvailableQualityUrl() async {
    Episode episodeToPlay = widget.playlist[currentIndex];
    PlayableFile? currentchoi = await db.get<PlayableFile>(int.parse(episodeToPlay.playableFileId!));
    Map<String, String?> currentchoice = {};
    if (widget.url == currentchoi!.urls.url1080p &&
        currentchoi.urls.url1080p != '') {
      currentchoice['1080p'] = currentchoi.urls.url1080p;
    }
    if (widget.url == currentchoi.urls.url720p &&
        currentchoi.urls.url720p != '') {
      currentchoice['720p'] = currentchoi.urls.url720p;
    }
    if (widget.url == currentchoi.urls.url540p &&
        currentchoi.urls.url540p != '') {
      currentchoice['540p'] = currentchoi.urls.url540p;
    }
    if (widget.url == currentchoi.urls.url480p &&
        currentchoi.urls.url480p != '') {
      currentchoice['480p'] = currentchoi.urls.url480p;
    }

    return currentchoice;
  }

  void _showSettings() {
    setState(() {
      showSettings = true;
    });

    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 5), () {
      // Increased timer slightly for usability
      if (mounted) {
        setState(() {
          showSettings = false;
        });
      }
    });
  }

  // New method to select and set external subtitle
  Future<void> _selectSubtitle() async {
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['srt', 'ass', 'vtt', 'sub'],
    );
    if (result != null && result.files.single.path != null) {
      player.setSubtitleTrack(SubtitleTrack.uri(result.files.single.path!));
      // Optionally hide settings after selection
      setState(() {
        showSettings = false;
      });
    }
  }

  // New method to select and set external audio
  Future<void> _selectAudio() async {
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'aac', 'm4a', 'wav'],
    );
    if (result != null && result.files.single.path != null) {
      player.setAudioTrack(AudioTrack.uri(result.files.single.path!));
      // Optionally hide settings after selection
      setState(() {
        showSettings = false;
      });
    }
  }

  Future<String> _showQualitySelectionDialog() async {
    Map<String, String?> currentSelectedOptions =
        await getAvailableQualityUrl();
    Episode episodeToPlay = widget.playlist[currentIndex];
    PlayableFile epistoPlay = await db.get(
      int.parse(episodeToPlay.playableFileId!),
    );

    //TODO not so import
    Map<String, String> availableQualities = epistoPlay
        .getAvailableQualityUrls();

    var selectedQuality = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Quality'),
          content: SingleChildScrollView(
            child: ListBody(
              children: availableQualities.entries.map((entry) {
                return ListTile(
                  title: Text(entry.key),
                  selected: entry.key == currentQuality,
                  selectedColor: Colors.purple,
                  onTap: () {
                    _changeQuality(entry.key);
                    Navigator.of(context).pop(entry.key);
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
    if (selectedQuality != null &&
        availableQualities.containsKey(selectedQuality)) {
      urlToPlayQuality = availableQualities[selectedQuality]!;
      currentQuality = selectedQuality;
      return _cycleQuality(currentQuality);
    } else {
      return 'Invalid selection';
    }
  }

  String _cycleQuality(String currentQuality) {
    List<String> qualityList = [
      'Auto',
      '1080p',
      '720p',
      '540p',
      '480p',
      'DUBBED',
    ];
    int currentIndex = qualityList.indexOf(currentQuality);
    currentIndex = (currentIndex + 1) % qualityList.length;
    return qualityList[currentIndex];
  }

  void _changeQuality(String newQuality) {
    setState(() {
      currentQuality = newQuality;
    });
    playEpisodeByUrl(currentQuality, currentIndex);
  }

  @override
  void initState() {
    super.initState();

    currentIndex = widget.initialIndex;

    _completedSubscription = player.stream.completed.listen((completed) {
      debugPrint(
        'VideoPlayerScreenPlState: Player completed stream event: $completed',
      );
      if (completed) {
        _clearPlaybackProgress();
        debugPrint('VideoPlayerScreenPlState: Video completed. Playing next.');
        playNext();
      }
    });

    _progressSaveTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _savePlaybackProgress();
    });
    debugPrint('VideoPlayerScreenPlState: _progressSaveTimer started.');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAndPlayEpisode(widget.initialIndex, isInitialPlay: true);
    });
  }

  Future<void> _loadAndPlayEpisode(
    int index, {
    bool isInitialPlay = true,
    String? specificUrl,
  }) async {
    epiz = await db.getEpisodesForSeason('${widget.season.id}');

    if (index < 0 || index >= widget.playlist.length) {
      debugPrint("Invalid episode index: $index. Not playing.");
      if (!isInitialPlay) Navigator.of(context).pop();
      return;
    }

    // 2. Update state
    setState(() {
      currentIndex = index;
    });

    Episode episodeToPlay = widget.playlist[currentIndex];
    PlayableFile f = await db.get(int.parse(episodeToPlay.playableFileId!));
    String urlToPlay;
    if (specificUrl != null) {
      urlToPlay = specificUrl;
    } else {
      //TODO in list todo
      Map<String, String> availableUrls = f.getAvailableQualityUrls();
      if (availableUrls.isEmpty) {
        debugPrint('No URLs found for this episode. Cannot play.');

        return;
      }
      urlToPlay = availableUrls.values.first;
    }

    debugPrint("Opening media: $urlToPlay");
    if (widget.isLocalSource) {
      final playlist = await LocalFilePlaylistService.buildPlaylistFromFolder(
        urlToPlay,
        "video",
      );

      if (playlist.isEmpty) {
        debugPrint('No video files found in folder');
        await player.open(Media(Uri.decodeComponent(urlToPlay)), play: false);
      }

      // Find current file index

      await player.open(Playlist(playlist), play: false);
    } else {
      await player.open(Media(Uri.decodeComponent(urlToPlay)), play: false);
    }
    PlayableFile p = await db.get(int.parse(episodeToPlay.playableFileId!));
    PlayState s = p.watchState;
    s.isPlayed = true;
    await db.put(p);

    Duration? savedPosition = Duration(milliseconds: s.watchingTimeMs.last);

    if (isInitialPlay) {
      if (savedPosition.inMilliseconds > 50) {
        final shouldResume = await _showResumeDialog(savedPosition);
        if (shouldResume == true) {
          await player.seek(savedPosition);
          await player.play();
        } else if (shouldResume == false) {
          await _clearPlaybackProgress();
        }
      }
    }

    await player.play();
  }

  void playNext() {
    _loadAndPlayEpisode(currentIndex + 1, isInitialPlay: true);
  }

  void playPrevious() {
    _loadAndPlayEpisode(currentIndex - 1, isInitialPlay: true);
  }

  void playEpisode(int index) {
    _loadAndPlayEpisode(index, isInitialPlay: true);
  }

  void changeQuality(String newQualityUrl) {
    _savePlaybackProgress();
    _loadAndPlayEpisode(
      currentIndex,
      isInitialPlay: true,
      specificUrl: newQualityUrl,
    );
  }

  @override
  void dispose() {
    debugPrint("VideoPlayerScreenPl disposing. Saving final progress.");
    _progressSaveTimer?.cancel();
    _completedSubscription?.cancel();
    _errorSubscription?.cancel();

    nimdispose(); // Your existing method is fine
    super.dispose();
  }

  void playEpisodeByUrl(String url, int index, {bool isInitialPlay = false}) {
    _loadAndPlayEpisode(index, isInitialPlay: true, specificUrl: url);
  }

  void nimdispose() async {
    await _savePlaybackProgress();
    await player.dispose();
  }

  Future<void> _savePlaybackProgress() async {
  if (player.state.duration.inSeconds > 10) {
    final position = player.state.position;
    final PlayableFile? f = await db.get<PlayableFile>(int.parse(currentEpisode!.playableFileId!));
    
    if (f != null) {
      // 1. Create a modifiable copy of the existing list
      final List<int> updatedTimes = List.from(f.watchState.watchingTimeMs);
      
      // 2. Append or overwrite safely
      if (updatedTimes.isEmpty) {
        updatedTimes.add(position.inMilliseconds);
      } else {
        updatedTimes[updatedTimes.length - 1] = position.inMilliseconds;
      }
      
      // 3. Assign and save
      f.watchState.watchingTimeMs = updatedTimes;
      await db.put(f);
    }
  }
}

  Future<void> _clearPlaybackProgress() async {
    PlayableFile f = await db.get(int.parse(currentEpisode!.playableFileId!));
    f.watchState.watchingTimeMs.last = 0;
    await db.put(f);
  }

  Future<bool?> _showResumeDialog(Duration savedPosition) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // User must make a choice
      builder: (context) => AlertDialog(
        title: const Text('Resume Playback?'),
        content: Text(
          'You previously stopped watching at ${formatDuration(savedPosition)}. Would you like to resume?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false); // Return false
            },
            child: const Text('START OVER'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(true); // Return true
            },
            child: const Text('RESUME'),
          ),
        ],
      ),
    );
  }

  // Helper to format duration strings

  void _showSubtitleControls() {
    setState(() {
      showSubtitleControls = true;
    });

    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          showSubtitleControls = false;
        });
      }
    });
  }

  // --- 1. BoxFit Feature: Function to cycle modes ---
  void _cycleBoxFit() {
    setState(() {
      currentFitIndex = (currentFitIndex + 1) % fitOptions.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: _buildPlaylistDrawer(context),
      endDrawerEnableOpenDragGesture: true,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          '${widget.seriesname}'
          '${currentEpisode?.episodeIndex ?? 'Loading...'}',
        ),
      ),
      body: _buildPlayerWithControls(),
    );
  }

  // A new widget for the playlist drawer
  Widget _buildPlaylistDrawer(context) {
    return Drawer(
      backgroundColor: Colors.black.withValues(alpha: 0.85),
      child: _buildSeasonsList(context, [widget.season], widget.tvSeriesId),
    );
  }

  void toggleEpisodeList() {
    setState(() {
      showEpisodeList = !showEpisodeList;
    });
  }

  void togglePlayPause() async {
    await player.playOrPause();
  }

  void playNextEpisode() async {
    setState(() {
      currentIndex = currentIndex + 1; // Direct update, consider safety check
    });
    playEpisode(currentIndex);
  }

  void playPreviousEpisode() async {
    setState(() {
      currentIndex = currentIndex - 1; // Direct update, consider safety check
    });
    playEpisode(currentIndex);
  }

  void seekForward() {
    Duration position = player.state.position;
    Duration duration = player.state.duration;
    Duration newPosition = position + const Duration(seconds: 10);

    if (newPosition < duration) {
      player.seek(newPosition);
    } else {
      player.seek(duration);
    }
  }

  void seekBackward() {
    Duration position = player.state.position;
    Duration newPosition = position - const Duration(seconds: 10);

    if (newPosition > Duration.zero) {
      player.seek(newPosition);
    } else {
      player.seek(Duration.zero);
    }
  }

  void toggleMute() {
    setState(() {
      isMuted = !isMuted;
      player.setVolume(isMuted ? 0 : 100);
    });
  }

  Widget _buildSeasonsList(
    // ignore: non_constant_identifier_names
    BuildContext context,
    List<Season> seasons,
    int tvseriesId,
  ) {
    bool defaultExpansion = seasons.length == 1;

    return SizedBox(
      height: 500,
      child: ListView.builder(
        controller: _seasonsScrollController,
        shrinkWrap: false,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: seasons.length,
        itemBuilder: (context, index) {
          Season season = seasons[index];

          return Card(
            elevation: 1,
            margin: const EdgeInsets.symmetric(vertical: 6.0),
            //           color: AppColors.secondaryBackground.withValues(alpha: 0.4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            clipBehavior: Clip.antiAlias,
            child: ExpansionTile(
              key: PageStorageKey('season_${season.seasonNumber}'),
              title: Text(
                'Season ${season.seasonNumber}',
                style: const TextStyle(
                  //           color: AppColors.primaryText,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              subtitle: Text(
                '${epiz.length} Episode${epiz.length == 1 ? '' : 's'}',
                style: const TextStyle(
                  //           color: AppColors.secondaryText,
                  fontSize: 12,
                ),
              ),
              //    iconColor: AppColors.accentColor,
              //     collapsedIconColor: AppColors.secondaryText,
              initiallyExpanded: defaultExpansion || season.seasonNumber == 1,
              childrenPadding: const EdgeInsets.only(
                bottom: 8.0,
                left: 4,
                right: 4,
              ),
              children: ListTile.divideTiles(
                context: context,
                //           color: AppColors.dividerColor.withValues(alpha: 0.3),
                tiles: epiz
                    .map(
                      (episode) => epistile(
                        context,
                        seriesname: widget.seriesname,
                        episode: episode,
                        season: season,
                        id: tvseriesId,
                      ),
                    )
                    .toList(),
              ).toList(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlayerWithControls() {
    return Stack(
      children: [
        Video(
          controller: controller,
          controls: AdaptiveVideoControls,
          fit: currentFit,
          filterQuality: FilterQuality.high,
          wakelock: true,
          subtitleViewConfiguration: SubtitleViewConfiguration(
            visible: true,
            style: TextStyle(
              height: 1.4,
              fontSize: subtitleSize,
              letterSpacing: 0.0,
              wordSpacing: 0.0,
              color: subtitleColor,
              fontWeight: FontWeight.w600,
              backgroundColor: const Color(0xaa000000),
            ),
            padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 24.0),
          ),
        ),
        Positioned(
          top: 14,
          right: 10,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showSettings)
                  Container(
                    width: 250, // Wider to accommodate buttons
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Subtitle size slider row
                        Row(
                          children: [
                            const Icon(
                              Icons.text_fields,
                              color: Colors.white,
                              size: 20,
                            ),
                            Expanded(
                              child: Slider(
                                value: subtitleSize,
                                min: 16.0,
                                max: 48.0,
                                onChanged: (value) {
                                  setState(() {
                                    subtitleSize = value;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Button for selecting external subtitle
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _selectSubtitle,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Select External Subtitle'),
                          ),
                        ),
                        const SizedBox(height: 5),
                        // Button for selecting external audio
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _selectAudio,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Select External Audio'),
                          ),
                        ),
                        const SizedBox(height: 5),
                        // Optional close button
                        TextButton(
                          onPressed: () {
                            setState(() {
                              showSettings = false;
                            });
                          },
                          child: const Text(
                            'Close',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                IconButton(
                  onPressed: _showQualitySelectionDialog,
                  icon: Icon(Icons.hd_rounded),
                ),
                IconButton(
                  icon: Icon(
                    _fitIcons[currentFit] ?? Icons.aspect_ratio,
                    color: Colors.white,
                  ),
                  tooltip: 'Change display mode',
                  onPressed: _cycleBoxFit,
                ),
                IconButton(
                  icon: Icon(
                    _playModeIcons[currentPlayMode] ?? Icons.aspect_ratio,
                    color: Colors.white,
                  ),
                  tooltip: 'Change playList mode',
                  onPressed: () async {
                    setState(() {
                      playlistMode(player);
                    });
                  },
                ),

                if (showSubtitleControls)
                  Container(
                    width: 200,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.text_fields,
                          color: Colors.white,
                          size: 20,
                        ),
                        Expanded(
                          child: Slider(
                            value: subtitleSize,
                            min: 16.0,
                            max: 48.0,
                            onChanged: (value) {
                              setState(() {
                                subtitleSize = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                IconButton(
                  icon: Icon(Icons.screenshot, color: Colors.blueAccent),
                  tooltip: 'Get Video Shot',
                  onPressed: () async {
                    await getshot(
                      player,
                      "${widget.seriesname}-${currentEpisode?.episodeIndex}",
                    );
                  },
                ),

                IconButton(
                  icon: const Icon(
                    Icons.closed_caption,
                    color: Color.fromARGB(255, 178, 246, 255),
                  ),
                  onPressed: _showSubtitleControls,
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: () async {
                    playEpisode(currentIndex);
                  },
                ),
                IconButton(
                  icon: const Icon(
                    Icons.skip_previous,
                    color: Color.fromARGB(255, 250, 109, 109),
                    size: 28,
                  ),
                  onPressed: () async {
                    playEpisode(currentIndex - 1); // Consider bounds check
                  },
                ),
                IconButton(
                  icon: const Icon(
                    Icons.skip_next,
                    color: Color.fromARGB(255, 97, 166, 251),
                    size: 28,
                  ),
                  onPressed: () async {
                    playEpisode(currentIndex + 1); // Consider bounds check
                  },
                ),
                IconButton(
                  icon: Icon(Icons.settings, color: Colors.white),
                  onPressed: _showSettings, // Updated to show settings panel
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget epistile(
    BuildContext context, {
    required String seriesname,
    required Episode episode,
    required Season season,
    required int id,
  }) {
    return
    FutureBuilder<PlayableFile?>(
      future: db.get<PlayableFile>(int.parse(episode.playableFileId!)),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();
        final fileData = snapshot.data!;
        final availableQualities = fileData.getAvailableQualityUrls();

        void playEpisodes(BuildContext context, String url) async {
          List<Episode> epis = await db.getEpisodesForSeason('${season.id}');
          int initialIndex = epis.indexOf(episode);

          playEpisodeByUrl(url, initialIndex);
        }

        // final displayTitle = 'Episode ${episode.episodeNumber}'; // Original commented line
        bool isInWatchlist = fileData.watchState.isPlayed;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Episode ${episode.episodeIndex}',
                      style: const TextStyle(
                        //           color: AppColors.primaryText,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // if (episode.episodeIndex !=
                    //     'Episode ${episode.episodeNumber}')
                    //   Text(
                    //     episode.episodeIdentifier,
                    //     style: const TextStyle(
                    //       //           color: AppColors.secondaryText,
                    //       fontSize: 11,
                    //     ),
                    //   ),
                  ],
                ),
              ),
              // --- ADDED THIS: The watched icon ---
              if (isInWatchlist)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Icon(
                    Icons.check_circle,
                    //           color: AppColors.accentColor,
                    size: 18.0,
                  ),
                ),

              const SizedBox(width: 12),
              if (availableQualities.isNotEmpty)
                Expanded(
                  flex: 4,
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 6.0,
                    runSpacing: 4.0,
                    children: availableQualities.entries.map<Widget>((entry) {
                      // final quality = entry.key; // Original commented line
                      final url = entry.value;

                      return ElevatedButton(
                        onPressed: () {
                          // final int episodeIndex = widget.playlist.indexOf(episode); // Original commented line

                          playEpisodes(context, url);
                        },
                        style: ElevatedButton.styleFrom(
                          // backgroundColor: AppColors.accentColor.withValues(
                          //   alpha: 0.7,
                          // ),
                          // foregroundColor: AppColors.primaryText,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          minimumSize: const Size(45, 28),
                          textStyle: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          elevation: 1,
                        ),
                        child: Text(entry.key.toUpperCase()),
                      );
                    }).toList(),
                  ),
                )
              else
                const Text(
                  'No links',
                  style: TextStyle(
                    //           color: AppColors.secondaryText,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

List<PlaylistMode> playModeOptions = [
  PlaylistMode.none,
  PlaylistMode.single,
  PlaylistMode.loop,
];
int currentPlayModeIndex = 0;
PlaylistMode get currentPlayMode => playModeOptions[currentPlayModeIndex];
final Map<PlaylistMode, IconData> _playModeIcons = {
  PlaylistMode.none: Icons.arrow_forward_ios,
  PlaylistMode.single: Icons.repeat_on,
  PlaylistMode.loop: Icons.loop,
};
void playlistMode(Player player) async {
  currentPlayModeIndex = (currentPlayModeIndex + 1) % playModeOptions.length;
  await player.setPlaylistMode(currentPlayMode);
}

Future<void> getshot(Player player, String videoName) async {
  final Uint8List? screenshot = await player.screenshot();
  if (screenshot != null) {
    //   Directory basedir = await getTargetDirectory(folderUnderApp: "ScreenShots");
    //   final fdir = await File(
    //     p.join(basedir.path, videoName, '${DateTime.now()}.png'),
    //   ).create();
    //   await File(fdir.path).writeAsBytes((screenshot).toList());
    // }
  }
}

// ignore: must_be_immutable
class VideoPlayerScreen extends StatefulWidget {
  PlayableFile videoFile;
  String? exterSubtitle;
  String? exterAudio;
  List? playlistitem;
  VideoPlayerScreen({
    required this.videoFile,
    this.playlistitem,
    super.key,
    this.exterSubtitle,
    this.exterAudio,
  });

  @override
  State<VideoPlayerScreen> createState() => VideoPlayerScreenState();
}

class VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late final Player player = Player();
  late final VideoController controller = VideoController(player);
  bool showControls = true;
  bool showEpisodeList = false;
  bool isFullScreen = false;
  bool isMuted = false;
  bool isPiPEnabled = false;
  Timer? _progressSaveTimer; // Timer to periodically save progress
  String urlToPlayQuality = '';
  double subtitleSize = 32.0;
  Color subtitleColor = const Color.fromARGB(255, 238, 230, 5);
  bool showSettings =
      false; // Renamed from showSubtitleControls to showSettings
  late int currentIndex;
  StreamSubscription? _completedSubscription;
  StreamSubscription? _errorSubscription;
  Timer? _hideTimer;
  String currentQuality = 'Auto';
  bool streamHasError = false;
  bool isFileSource = false;
  @override
  void initState() {
    super.initState();
    currentIndex = 0;
    // _userDataService = Provider.of<UserDataService>(context, listen: false);

    _completedSubscription = player.stream.completed.listen((completed) {
      if (completed) {
        _clearPlaybackProgress();
        playNext();
      }
    });

    _progressSaveTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _savePlaybackProgress();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAndPlayEpisode(0, isInitialPlay: true);

      // Build playlist from local folder in background if it's a local file
    });
  }

  /// Initialize playlist from local folder in background

  Future<void> _loadAndPlayEpisode(
    int index, {
    bool isInitialPlay = true,
    String? specificUrl,
  }) async {
    setState(() {
      currentIndex = index;
    });

    String urlToPlay;

    if (specificUrl != null) {
      urlToPlay = specificUrl;
    } else {
      urlToPlay = widget.videoFile.filePath.isNotEmpty
          ? widget.videoFile.filePath
          : widget.videoFile.urls.url1080p.isNotEmpty
          ? widget.videoFile.urls.url1080p
          : widget.videoFile.urls.url720p.isNotEmpty
          ? widget.videoFile.urls.url720p
          : widget.videoFile.urls.url540p.isNotEmpty
          ? widget.videoFile.urls.url540p
          : widget.videoFile.urls.url480p.isNotEmpty
          ? widget.videoFile.urls.url480p
          : widget.videoFile.urls.url360p;
    }
    String videoname = p.basenameWithoutExtension(urlToPlay);
    String parentfolder = p.dirname(urlToPlay);
    if (widget.videoFile.filePath.isNotEmpty) {
      final playlist = await LocalFilePlaylistService.buildPlaylistFromFolder(
        urlToPlay,
        "video",
      );

      if (playlist.isEmpty) {
        debugPrint('No video files found in folder');
        await player.open(Media(Uri.decodeComponent(urlToPlay)), play: false);
      }

      // Find current file index

      await player.open(Playlist(playlist), play: false);
    } else {
      await player.open(Media(Uri.decodeComponent(urlToPlay)), play: false);
    } // Set external subtitle if provided
    if (widget.exterSubtitle != null) {
      player.setSubtitleTrack(SubtitleTrack.uri(widget.exterSubtitle!));
    } else if (File('$parentfolder/$videoname.srt').existsSync() ||
        File('$parentfolder/$videoname.ass').existsSync() ||
        File('$parentfolder/$videoname.vtt').existsSync() ||
        File('$parentfolder/$videoname.sub').existsSync()) {
      await player.setSubtitleTrack(SubtitleTrack.uri(urlToPlay));
    }
    // Fixed condition: set audio if not null and not empty
    if (widget.exterAudio != null) {
      await player.setAudioTrack(AudioTrack.uri(widget.exterAudio!));
    }

    widget.videoFile.watchState.isPlayed = true;
    await db.put(widget.videoFile);
    Duration? savedPosition = Duration(
      milliseconds: widget.videoFile.watchState.watchingTimeMs.last,
    );

    if (isInitialPlay) {
      if (savedPosition.inMilliseconds > 50) {
        final shouldResume = await _showResumeDialog(savedPosition);
        if (shouldResume == true) {
          await player.seek(savedPosition);
          await player.play();
        } else if (shouldResume == false) {
          await _clearPlaybackProgress();
        }
      }
    }

    await player.play();
  }

  // New method to select and set external subtitle
  Future<void> _selectSubtitle() async {
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['srt', 'ass', 'vtt', 'sub'],
    );
    if (result != null && result.files.single.path != null) {
      player.setSubtitleTrack(SubtitleTrack.uri(result.files.single.path!));
      // Optionally hide settings after selection
      setState(() {
        showSettings = false;
      });
    }
  }

  // New method to select and set external audio
  Future<void> _selectAudio() async {
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'aac', 'm4a', 'wav'],
    );
    if (result != null && result.files.single.path != null) {
      player.setAudioTrack(AudioTrack.uri(result.files.single.path!));
      // Optionally hide settings after selection
      setState(() {
        showSettings = false;
      });
    }
  }

  void playNext() {
    _loadAndPlayEpisode(currentIndex + 1, isInitialPlay: true);
  }

  void playPrevious() {
    _loadAndPlayEpisode(currentIndex - 1, isInitialPlay: true);
  }

  void playEpisode(int index) {
    _loadAndPlayEpisode(index, isInitialPlay: true);
  }

  final List<String> qualityOptions = ['Auto', '1080p', '720p', '480p', '360p'];
  String formatDuration(Duration duration) {
    String hours = duration.inHours.toString().padLeft(2, '0');
    String minutes = duration.inMinutes
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    String seconds = duration.inSeconds
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    if (duration.inHours > 0) {
      return "$hours:$minutes:$seconds";
    }
    return "$minutes:$seconds";
  }

  List<BoxFit> fitOptions = [
    BoxFit.contain, // Standard
    BoxFit.cover, // Fill/Crop
    BoxFit.fill, // Stretch
    BoxFit.fitWidth,
    BoxFit.fitHeight,
  ];
  int currentFitIndex = 0;
  BoxFit get currentFit => fitOptions[currentFitIndex];
  final Map<BoxFit, IconData> _fitIcons = {
    BoxFit.contain: Icons.fullscreen_exit,
    BoxFit.cover: Icons.fullscreen,
    BoxFit.fill: Icons.photo_size_select_large,
    BoxFit.fitWidth: Icons.swap_horiz,
    BoxFit.fitHeight: Icons.swap_vert,
  };

  List<String> choicelist = ['Auto', '1080p', '720p', '540', '480p', 'DUBBED'];

  void _showSettings() {
    setState(() {
      showSettings = true;
    });

    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 5), () {
      // Increased timer slightly for usability
      if (mounted) {
        setState(() {
          showSettings = false;
        });
      }
    });
  }

  @override
  void dispose() {
    // Release PiP plugin resources
    _progressSaveTimer?.cancel();
    _completedSubscription?.cancel();
    _errorSubscription?.cancel();

    nimdispose(); // Your existing method is fine
    super.dispose();
  }

  void nimdispose() async {
    await _savePlaybackProgress();
    await player.dispose();
  }

Future<void> _savePlaybackProgress() async {
  if (player.state.duration.inSeconds > 10) {
    final position = player.state.position;
    final PlayableFile? f = await db.get<PlayableFile>(int.parse('${widget.videoFile.id}'));
    
    if (f != null) {
      // 1. Create a modifiable copy of the existing list
      final List<int> updatedTimes = List.from(f.watchState.watchingTimeMs);
      
      // 2. Append or overwrite safely
      if (updatedTimes.isEmpty) {
        updatedTimes.add(position.inMilliseconds);
      } else {
        updatedTimes[updatedTimes.length - 1] = position.inMilliseconds;
      }
      
      // 3. Assign and save
      f.watchState.watchingTimeMs = updatedTimes;
      await db.put(f);
    }
  }
}  Future<void> _clearPlaybackProgress() async {
    widget.videoFile.watchState.watchingTimeMs.last = 0;
    await db.put(widget.videoFile);
  }

  Future<bool?> _showResumeDialog(Duration savedPosition) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // User must make a choice
      builder: (context) => AlertDialog(
        title: const Text('Resume Playback?'),
        content: Text(
          'You previously stopped watching at ${formatDuration(savedPosition)}. Would you like to resume?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false); // Return false
            },
            child: const Text('START OVER'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(true); // Return true
            },
            child: const Text('RESUME'),
          ),
        ],
      ),
    );
  }

  final List<BoxFit> _fitOptions = [
    BoxFit.contain, // Standard
    BoxFit.cover, // Fill/Crop
    BoxFit.fill, // Stretch
    BoxFit.fitWidth,
    BoxFit.fitHeight,
  ];
  // late final UserDataService _userDataService;

  void _cycleBoxFit() {
    setState(() {
      currentFitIndex = (currentFitIndex + 1) % _fitOptions.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.black, actions: []),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Video(
            controller: controller,
            controls: AdaptiveVideoControls,
            fit: currentFit,
            filterQuality: FilterQuality.high,
            wakelock: true,
            subtitleViewConfiguration: SubtitleViewConfiguration(
              visible: true,
              style: TextStyle(
                height: 1.4,
                fontSize: subtitleSize,
                letterSpacing: 0.0,
                wordSpacing: 0.0,
                color: subtitleColor,
                fontWeight: FontWeight.w700,
                backgroundColor: const Color(0xaa000000),
              ),
              padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 24.0),
            ),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showSettings)
                    Container(
                      width: 250, // Wider to accommodate buttons
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Subtitle size slider row
                          Row(
                            children: [
                              const Icon(
                                Icons.text_fields,
                                color: Colors.white,
                                size: 20,
                              ),
                              Expanded(
                                child: Slider(
                                  value: subtitleSize,
                                  min: 16.0,
                                  max: 48.0,
                                  onChanged: (value) {
                                    setState(() {
                                      subtitleSize = value;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // Button for selecting external subtitle
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _selectSubtitle,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Select External Subtitle'),
                            ),
                          ),
                          const SizedBox(height: 5),
                          // Button for selecting external audio
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _selectAudio,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Select External Audio'),
                            ),
                          ),
                          const SizedBox(height: 5),
                          // Optional close button
                          TextButton(
                            onPressed: () {
                              setState(() {
                                showSettings = false;
                              });
                            },
                            child: const Text(
                              'Close',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  IconButton(
                    icon: Icon(Icons.screenshot, color: Colors.blueAccent),
                    tooltip: 'Get Video Shot',
                    onPressed: () async {
                      await getshot(
                        player,
                        p.basenameWithoutExtension(
                          widget.videoFile.filePath.isNotEmpty
                              ? widget.videoFile.filePath
                              : widget.videoFile.urls.url1080p.isNotEmpty
                              ? widget.videoFile.urls.url1080p
                              : widget.videoFile.urls.url720p.isNotEmpty
                              ? widget.videoFile.urls.url720p
                              : widget.videoFile.urls.url540p.isNotEmpty
                              ? widget.videoFile.urls.url540p
                              : widget.videoFile.urls.url480p.isNotEmpty
                              ? widget.videoFile.urls.url480p
                              : widget.videoFile.urls.url360p,
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      _fitIcons[currentFit] ?? Icons.aspect_ratio,
                      color: Colors.white,
                    ),
                    tooltip: 'Change display mode',
                    onPressed: _cycleBoxFit,
                  ),
                  IconButton(
                    icon: Icon(
                      _playModeIcons[currentPlayMode] ?? Icons.aspect_ratio,
                      color: Colors.white,
                    ),
                    tooltip: 'Change playList mode',
                    onPressed: () async {
                      setState(() {
                        playlistMode(player);
                      });
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.picture_in_picture_outlined,
                      color: Colors.white,
                    ),
                    onPressed: () async {},
                  ),
                  IconButton(
                    icon: Icon(Icons.settings, color: Colors.white),
                    onPressed: _showSettings, // Updated to show settings panel
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
