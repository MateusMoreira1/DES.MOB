import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:pokedex/pokeapi/pokeapi.dart';
import 'package:pokedex/repositories/pokemon_repository.dart';
import 'package:pokedex/repositories/pokemon_repository_impl.dart';
import 'package:pokedex/viewmodels/home_view_model.dart';
import 'package:pokedex/views/pokedex_home.dart';
import 'package:pokedex/views/auth/login_screen.dart';
import 'package:provider/provider.dart';
import 'package:pokedex/services/auth_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar o Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final pokeApi = await PokeAPI.create();

  runApp(
    MultiProvider(
      providers: [
        Provider<PokeAPI>(create: (_) => pokeApi),
        Provider<PokemonRepository>(
          create: (context) => PokemonRepositoryImpl(context.read<PokeAPI>()),
        ),
        ChangeNotifierProvider<HomeViewModel>(
          create:
              (context) =>
                  HomeViewModel(context.read<PokemonRepository>())..init(),
        ),
        Provider<AuthService>(create: (_) => AuthService()),
      ],
      child: const PokedexApp(),
    ),
  );
}

class PokedexApp extends StatelessWidget {
  const PokedexApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return MaterialApp(
      title: 'Pokédex por Jose Eduardo',
      theme: ThemeData(
        primarySwatch: Colors.red,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: StreamBuilder<User?>(
        stream: authService.userStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.active) {
            final user = snapshot.data;
            if (user == null) {
              return const LoginScreen();
            }
            return const PokedexHome(title: 'Pokédex');
          }
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }
}
