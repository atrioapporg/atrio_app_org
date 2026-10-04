import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IntroEncuentraScreen extends StatefulWidget {
  static const routeName = 'intro_encuentra_screen';
  const IntroEncuentraScreen({super.key});

  @override
  State createState() => _IntroEncuentraScreenState();
}

class _IntroEncuentraScreenState extends State {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _introData = [
    {
      'title': 'Encuentra tu\ncomunidad de fe',
      'subtitle': 'Descubre iglesias cercanas.',
      'image': 'assets/images/intro_encuentra.png',
    },
    {
      'title': 'Vive tu fe\nen comunidad',
      'subtitle': 'Recibe noticias, actividades\ny mensajes.',
      'image': 'assets/images/intro_conecta.png',
    },
    {
      'title': 'Todo más\ncerca de ti',
      'subtitle': 'Solicita orientación,\noración y servicios.',
      'image': 'assets/images/intro_solicitudes.png',
    },
    {
      'title': 'Crece y comparte\ntu fe',
      'subtitle': 'Accede a reflexiones,\ncursos y recursos.',
      'image': 'assets/images/intro_crece.png',
    },
  ];

  Future _finalizarIntro() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('intro_vista', true);
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      'inicio_sesion_screen',
      (route) => false,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final safeAreaTop = MediaQuery.of(context).padding.top;
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;
    final usableHeight = screenHeight - safeAreaTop - safeAreaBottom;

    const Color azulFondo = Color(0xFF072B4F);
    const Color amarilloOro = Color(0xFFE5A023);
    const Color blancoFondo = Color(0xFFFAF7F0);

    return Scaffold(
      backgroundColor: azulFondo,
      body: SafeArea(
        bottom: true,
        child: SizedBox(
          width: screenWidth,
          height: usableHeight,
          child: Column(
            children: [
              // 2. Encabezado Superior (Logo Horizontal Atrio)
              SizedBox(
                height: usableHeight * 0.08,
                child: Center(
                  child: Image.asset(
                    'assets/images/logo_encabezado_sinfondo.png',
                    height: usableHeight * 0.060,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              // Fin Encabezado Superior--------------

              // 3. Área dinámica PageView
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: _introData.length,
                  itemBuilder: (context, index) {
                    return _buildPageItem(
                      title: _introData[index]['title']!,
                      subtitle: _introData[index]['subtitle']!,
                      imagePath: _introData[index]['image']!,
                      screenWidth: screenWidth,
                      usableHeight: usableHeight,
                      blancoFondo: blancoFondo,
                    );
                  },
                ),
              ),

              // 4. Barra de navegación inferior fija
              Container(
                width: screenWidth,
                height: usableHeight * 0.12,
                color: blancoFondo,
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: _finalizarIntro,
                      child: Text(
                        'Saltar',
                        style: TextStyle(
                          color: azulFondo,
                          fontSize: screenWidth * 0.04,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Row(
                      children: List.generate(
                        _introData.length,
                        (index) => _buildDot(
                          index == _currentPage,
                          amarilloOro,
                          screenWidth,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: amarilloOro,
                        foregroundColor: azulFondo,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            screenWidth * 0.03,
                          ),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.05,
                          vertical: usableHeight * 0.015,
                        ),
                      ),
                      onPressed: () {
                        if (_currentPage == _introData.length - 1) {
                          _finalizarIntro();
                        } else {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      child: Text(
                        _currentPage == _introData.length - 1
                            ? 'Comenzar'
                            : 'Siguiente',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: screenWidth * 0.038,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageItem({
    required String title,
    required String subtitle,
    required String imagePath,
    required double screenWidth,
    required double usableHeight,
    required Color blancoFondo,
  }) {
    return Column(
      children: [
        SizedBox(height: usableHeight * 0.02),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: screenWidth * 0.068,
            fontWeight: FontWeight.bold,
            height: 1.15,
          ),
        ),
        SizedBox(height: usableHeight * 0.012),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white70,
            fontSize: screenWidth * 0.038,
          ),
        ),
        SizedBox(height: usableHeight * 0.02),
        Expanded(
          child: Container(
            width: screenWidth * 0.85,
            decoration: BoxDecoration(
              color: blancoFondo,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(screenWidth * 0.07),
                topRight: Radius.circular(screenWidth * 0.07),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(screenWidth * 0.07),
                topRight: Radius.circular(screenWidth * 0.07),
              ),
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(screenWidth * 0.07),
                        topRight: Radius.circular(screenWidth * 0.07),
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        size: screenWidth * 0.15,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDot(bool isActive, Color activeColor, double screenWidth) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.01),
      height: screenWidth * 0.02,
      width: isActive ? screenWidth * 0.035 : screenWidth * 0.02,
      decoration: BoxDecoration(
        color: isActive ? activeColor : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(screenWidth * 0.01),
      ),
    );
  }
}
