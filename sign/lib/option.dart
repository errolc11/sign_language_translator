import 'package:flutter/material.dart';
import 'guide.dart';
import 'alphabet.dart';
import 'no.dart';
import 'package:url_launcher/url_launcher.dart';

class Option extends StatefulWidget {
  const Option({super.key});

  @override
  State<Option> createState() => OptionState();
}

class OptionState extends State<Option> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _launchURL(String url) async {
    final Uri _url = Uri.parse(url);
    if (!await launchUrl(_url, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          "Basic Signs",
          style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 22),
        ),
      ),
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return SingleChildScrollView(
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  width: double.infinity,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF00796B), Color(0xFF7B1FA2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildImageContainer('images/A.jpg', screenHeight),
                            _buildImageContainer('images/num.jpg', screenHeight),
                            _buildImageContainer('images/needs.webp', screenHeight),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildButton("Alphabets", const Color(0xFF0288D1), () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => alphabet()),
                              );
                            }),
                            _buildButton("Numbers", const Color(0xFF8E24AA), () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => no()),
                              );
                            }),
                            _buildButton("Words", const Color(0xFF673AB7), () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => guide()),
                              );
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      const Text(
                        'Videos',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                      const SizedBox(height: 15),
                      _buildVideoThumbnail(
                          'https://youtu.be/qcdivQfA41Y',
                          'https://img.youtube.com/vi/qcdivQfA41Y/hqdefault.jpg',
                          screenWidth),
                      const SizedBox(height: 15),
                      _buildVideoThumbnail(
                          'https://youtu.be/VtbYvVDItvg',
                          'https://img.youtube.com/vi/VtbYvVDItvg/hqdefault.jpg',
                          screenWidth),
                      const SizedBox(height: 15),
                      _buildVideoThumbnail(
                          'https://youtu.be/vnH2BmcSRMA',
                          'https://img.youtube.com/vi/vnH2BmcSRMA/hqdefault.jpg',
                          screenWidth),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildImageContainer(String imagePath, double screenHeight) {
    return Expanded(
      child: Container(
        height: screenHeight * 0.2,
        margin: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(20),
          image: DecorationImage(
            image: AssetImage(imagePath),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget _buildButton(String text, Color color, VoidCallback onPressed) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30.0),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            elevation: 5,
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoThumbnail(String url, String thumbnail, double screenWidth) {
    return GestureDetector(
      onTap: () {
        _launchURL(url);
      },
      child: Container(
        width: screenWidth * 0.8,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black45,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15.0),
          child: Image.network(
            thumbnail,
            width: screenWidth * 0.8,
            height: 180,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const Center(child: Icon(Icons.error, color: Colors.red));
            },
          ),
        ),
      ),
    );
  }
}
