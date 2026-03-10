import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:video_player/video_player.dart';
import 'package:voice_message_package/voice_message_package.dart';

import '../../services/background/storage_service/local_storage_service.dart';
import '../../utils/constants/colors.dart';
import '../../utils/formatters/formatters.dart';
import '../../utils/helpers/helper_functions.dart';
import '../../widgets/navigations/app_bar.dart';

AppHelperFunctions appHelperFunctions = AppHelperFunctions();

class RecordingDetails extends StatelessWidget {
  final String? uid;
  final String date;

  const RecordingDetails({super.key, this.uid, required this.date});

  @override
  Widget build(BuildContext context) {
    if (uid == null) {
      return Scaffold(
        appBar: const CustomAppBar(),
        body: const Center(child: Text('User ID not found.')),
      );
    }

    final String formattedDate = Formatters.formatDateString(date);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(),
      body: Padding(
        padding: const EdgeInsets.only(left: 15.0, top: 3.0, right: 15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios,
                    color: Color(0xFF263238),
                    size: 15,
                  ),
                  onPressed: () => appHelperFunctions.goBack(context),
                ),
                Text(
                  'Recording of $formattedDate',
                  style: const TextStyle(
                    fontSize: 15,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 0.0),
            const Text(
              'Stored locally on your device.',
              style: TextStyle(
                fontSize: 11,
                fontFamily: 'Poppins',
                color: Colors.grey,
              ),
            ),
            const Divider(color: AppColors.dividerPrimary),
            const SizedBox(height: 10),

            // ── Dual Videos ────────────────────────────────────────────────
            FutureBuilder<List<DualVideoData>>(
              future: LocalStorageService.listDualVideos(uid!, date),
              builder: (context, snapshot) {
                final dualVideos = snapshot.data ?? [];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dual Camera Videos (${dualVideos.length})',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (snapshot.connectionState == ConnectionState.waiting)
                      const SizedBox(
                        height: 40,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (dualVideos.isEmpty)
                      const Text(
                        'No dual camera videos found for this date.',
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'Poppins',
                          color: Colors.grey,
                        ),
                      )
                    else
                      Column(
                        children: dualVideos
                            .map((videoData) => DualVideoTile(
                                  data: videoData,
                                ))
                            .toList(),
                      ),
                  ],
                );
              },
            ),

            const Divider(color: Color(0xFFEDEDED)),
            const SizedBox(height: 16),

            // ── Single Videos ────────────────────────────────────────────────
            FutureBuilder<List<LocalVideoData>>(
              future: LocalStorageService.listVideos(uid!, date),
              builder: (context, snapshot) {
                final videos = snapshot.data ?? [];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Single Videos (${videos.length})',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (snapshot.connectionState == ConnectionState.waiting)
                      const SizedBox(
                        height: 40,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (videos.isEmpty)
                      const Text(
                        'No single videos found for this date.',
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'Poppins',
                          color: Colors.grey,
                        ),
                      )
                    else
                      Column(
                        children: videos
                            .map((videoData) => VideoFileTile(data: videoData))
                            .toList(),
                      ),
                  ],
                );
              },
            ),

            const Divider(color: Color(0xFFEDEDED)),
            const SizedBox(height: 16),
            
            // ── Photos ─────────────────────────────────────────────────────
            FutureBuilder<List<LocalImageData>>(
              future: LocalStorageService.listImages(uid!, date),
              builder: (context, snapshot) {
                final images = snapshot.data ?? [];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Photos (${images.length})',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (snapshot.connectionState == ConnectionState.waiting)
                      const SizedBox(
                          height: 40,
                          child:
                              Center(child: CircularProgressIndicator()))
                    else if (images.isEmpty)
                      const Text(
                        'No images found for this date.',
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'Poppins',
                          color: Colors.grey,
                        ),
                      )
                    else
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: images
                              .map((data) => LocalPhotoWidget(data: data))
                              .toList(),
                        ),
                      ),
                  ],
                );
              },
            ),

            const Divider(color: Color(0xFFEDEDED)),
            const SizedBox(height: 16),

            // ── Audios ─────────────────────────────────────────────────────
            const Text(
              'Audios',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            Expanded(
              child: FutureBuilder<List<String>>(
                future: LocalStorageService.listAudios(uid!, date),
                builder: (context, audioSnapshot) {
                  if (audioSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final audioPaths = audioSnapshot.data ?? [];

                  if (audioPaths.isEmpty) {
                    return const Text(
                      'No audio recordings found for this date.',
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'Poppins',
                        color: Colors.grey,
                      ),
                    );
                  }

                  return ListView(
                    children: audioPaths
                        .map(
                          (filePath) => Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: SizedBox(
                              width: 350,
                              child: VoiceMessageView(
                                controller: VoiceController(
                                  audioSrc: filePath,
                                  onComplete: () {},
                                  onPause: () {},
                                  onPlaying: () {},
                                  onError: (err) {
                                    log('Audio playback error: $err');
                                  },
                                  maxDuration: const Duration(minutes: 30),
                                  isFile: true, // ← local file, not a URL
                                  noiseCount: 50,
                                ),
                                size: 50.0,
                                innerPadding: 3,
                                playIcon: const Icon(
                                  Icons.play_arrow_rounded,
                                  size: 30.0,
                                  color: Colors.white,
                                ),
                                pauseIcon: const Icon(
                                  Icons.pause_rounded,
                                  size: 30.0,
                                  color: Colors.white,
                                ),
                                activeSliderColor: AppColors.secondary,
                                circlesTextStyle: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.white,
                                ),
                                circlesColor: AppColors.secondary,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class LocalPhotoWidget extends StatelessWidget {
  final LocalImageData data;

  const LocalPhotoWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        appHelperFunctions.goToScreenAndComeBack(
            context, LocalZoomableImagePage(filePath: data.filePath));
      },
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: FileImage(File(data.filePath)),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            data.time,
            style: const TextStyle(fontFamily: 'Poppins', fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class LocalZoomableImagePage extends StatelessWidget {
  final String filePath;

  const LocalZoomableImagePage({super.key, required this.filePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Photo')),
      body: Center(
        child: PhotoView(
          imageProvider: FileImage(File(filePath)),
          backgroundDecoration: BoxDecoration(
            color: Theme.of(context).canvasColor,
          ),
        ),
      ),
    );
  }
}

// ── Dual Video Tile ────────────────────────────────────────────────────────

class DualVideoTile extends StatelessWidget {
  final DualVideoData data;

  const DualVideoTile({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final frontExists = data.frontPath != null && File(data.frontPath!).existsSync();
    final backExists = data.backPath != null && File(data.backPath!).existsSync();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recording at ${data.time}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Size: ${data.totalSize}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontFamily: 'Poppins',
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                // Front Camera Video
                Expanded(
                  child: GestureDetector(
                    onTap: frontExists
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => VideoPlayerPage(
                                  filePath: data.frontPath!,
                                  title: 'Front Camera Video',
                                ),
                              ),
                            );
                          }
                        : null,
                    child: Container(
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.secondary.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.videocam,
                            color: frontExists ? AppColors.secondary : Colors.grey,
                            size: 30,
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Front',
                            style: TextStyle(
                              fontSize: 11,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (frontExists)
                            Text(
                              '${(data.frontSize / (1024 * 1024)).toStringAsFixed(1)} MB',
                              style: const TextStyle(
                                fontSize: 9,
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Back Camera Video
                Expanded(
                  child: GestureDetector(
                    onTap: backExists
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => VideoPlayerPage(
                                  filePath: data.backPath!,
                                  title: 'Back Camera Video',
                                ),
                              ),
                            );
                          }
                        : null,
                    child: Container(
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.secondary.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.videocam,
                            color: backExists ? AppColors.secondary : Colors.grey,
                            size: 30,
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Back',
                            style: TextStyle(
                              fontSize: 11,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (backExists)
                            Text(
                              '${(data.backSize / (1024 * 1024)).toStringAsFixed(1)} MB',
                              style: const TextStyle(
                                fontSize: 9,
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Single Video Tile ──────────────────────────────────────────────────────

class VideoFileTile extends StatelessWidget {
  final LocalVideoData data;

  const VideoFileTile({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final fileExists = File(data.filePath).existsSync();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: Icon(
          Icons.video_file,
          color: fileExists ? AppColors.secondary : Colors.grey,
        ),
        title: Text(
          'Video - ${data.time}',
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
          ),
        ),
        trailing: const Icon(Icons.play_circle, color: AppColors.secondary),
        onTap: fileExists
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VideoPlayerPage(
                      filePath: data.filePath,
                      title: 'Video Playback',
                    ),
                  ),
                );
              }
            : null,
      ),
    );
  }
}

// ── Video Player Page ──────────────────────────────────────────────────────

class VideoPlayerPage extends StatefulWidget {
  final String filePath;
  final String title;

  const VideoPlayerPage({
    super.key,
    required this.filePath,
    required this.title,
  });

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      final file = File(widget.filePath);
      if (!await file.exists()) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Video file not found';
        });
        return;
      }

      _controller = VideoPlayerController.file(file);
      await _controller.initialize();

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to load video: $e';
      });
      log('❌ Error loading video: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: AppColors.secondary,
        elevation: 0,
      ),
      body: _buildBody(),
      backgroundColor: Colors.black,
    );
  }

  Widget _buildBody() {
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back'),
            ),
          ],
        ),
      );
    }

    if (!_isInitialized) {
      return const Center(
        child: SizedBox(
          width: 50,
          height: 50,
          child: CircularProgressIndicator(
            color: AppColors.secondary,
          ),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: Container(
            color: Colors.black,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                VideoPlayer(_controller),
                VideoProgressIndicator(
                  _controller,
                  allowScrubbing: true,
                  colors: VideoProgressColors(
                    playedColor: AppColors.secondary,
                    bufferedColor: Colors.grey[600]!,
                    backgroundColor: Colors.grey[800]!,
                  ),
                ),
              ],
            ),
          ),
        ),
        _buildPlayerControls(),
        _buildVideoInfo(),
      ],
    );
  }

  Widget _buildPlayerControls() {
    return Container(
      color: Colors.black87,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Play/Pause button
          GestureDetector(
            onTap: () {
              setState(() {
                if (_controller.value.isPlaying) {
                  _controller.pause();
                } else {
                  _controller.play();
                }
              });
            },
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.secondary,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(12),
              child: Icon(
                _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          // Duration display
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ValueListenableBuilder<VideoPlayerValue>(
                valueListenable: _controller,
                builder: (context, value, child) {
                  final position = _formatDuration(value.position);
                  final total = _formatDuration(value.duration);
                  return Text(
                    '$position / $total',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  );
                },
              ),
            ],
          ),
          // Speed button
          GestureDetector(
            onTap: _showSpeedMenu,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.secondary, width: 2),
                borderRadius: BorderRadius.circular(4),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ValueListenableBuilder<VideoPlayerValue>(
                valueListenable: _controller,
                builder: (context, value, child) {
                  return Text(
                    '${value.playbackSpeed.toStringAsFixed(1)}x',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoInfo() {
    return Container(
      color: Colors.black87,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'File Information',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          FutureBuilder<int>(
            future: File(widget.filePath).length(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final sizeInMB = snapshot.data! / (1024 * 1024);
                return Text(
                  'File size: ${sizeInMB.toStringAsFixed(2)} MB',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                );
              }
              return const Text(
                'Loading file info...',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: Colors.grey,
                ),
              );
            },
          ),
          const SizedBox(height: 4),
          Text(
            'Path: ${widget.filePath}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));

    if (duration.inHours > 0) {
      return '$hours:$minutes:$seconds';
    } else {
      return '$minutes:$seconds';
    }
  }

  void _showSpeedMenu() {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(100, 100, 0, 0),
      items: [
        PopupMenuItem(
          value: 0.5,
          child: const Text('0.5x'),
          onTap: () => _setPlaybackSpeed(0.5),
        ),
        PopupMenuItem(
          value: 1.0,
          child: const Text('1.0x (Normal)'),
          onTap: () => _setPlaybackSpeed(1.0),
        ),
        PopupMenuItem(
          value: 1.5,
          child: const Text('1.5x'),
          onTap: () => _setPlaybackSpeed(1.5),
        ),
        PopupMenuItem(
          value: 2.0,
          child: const Text('2.0x'),
          onTap: () => _setPlaybackSpeed(2.0),
        ),
      ],
    );
  }

  void _setPlaybackSpeed(double speed) {
    _controller.setPlaybackSpeed(speed);
  }
}
