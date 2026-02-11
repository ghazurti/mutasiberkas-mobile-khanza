import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'services/api_service.dart';
import 'pages/home_page.dart';

void main() {
  final apiService = ApiService(baseUrl: 'http://172.17.103.47:3000');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AppProvider(apiService: apiService),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Berkas RM Mobile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A237E), // Deep Blue
          primary: const Color(0xFF1A237E),
          secondary: const Color(0xFF00BFA5), // Mint Green
          surface: const Color(0xFFF5F7FA),
        ),
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          titleTextStyle: GoogleFonts.inter(
            color: const Color(0xFF1A237E),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
          iconTheme: const IconThemeData(color: Color(0xFF1A237E)),
        ),
      ),
      home: const HomePage(),
    );
  }
}
