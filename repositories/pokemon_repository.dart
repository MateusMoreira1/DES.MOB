import 'package:pokedex/pokeapi/entities/common.dart';
import 'package:pokedex/pokeapi/entities/evolution.dart';
import 'package:pokedex/pokeapi/entities/games.dart';
import 'package:pokedex/pokeapi/entities/items.dart';
import 'package:pokedex/pokeapi/entities/moves.dart';
import 'package:pokedex/pokeapi/entities/pokemon.dart';

abstract class PokemonRepository {
  Future<Pokemon> getPokemonDetailsByUrl(String url);
  Future<NamedAPIResourceList> getAllPokemons();
  Future<PokemonSpecies> getPokemonSpeciesByUrl(String url);
  Future<Version> getGameVersionByUrl(String url);
  Future<EvolutionChain> getEvolutionChain(String url);
  Future<Move> getMoveByUrl(String url);
  Future<Ability> getAbilityByUrl(String url);
  Future<Type> getTypeByUrl(String url);
  Future<Item> getItemByName(String name);
  Future<Item> getItemByUrl(String url);
  Future<Generation> getGenerationByUrl(String url);
  Future<NamedAPIResourceList> getAllTypes();
  Future<NamedAPIResourceList> getAllGenerations();
}
