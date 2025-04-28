import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:pokedex/custom/progress_indicator.dart';
import 'package:pokedex/pokeapi/entities/common.dart';
import 'package:pokedex/pokeapi/entities/pokemon.dart';
import 'package:pokedex/utils/logging.dart';
import 'package:pokedex/viewmodels/home_view_model.dart';
import 'package:pokedex/views/pokedex_home_widgets/type_filter_dialog.dart';
import 'package:pokedex/views/pokemon_details.dart';
import 'package:provider/provider.dart';
import 'package:pokedex/utils/string.dart';

class PokedexHome extends StatefulWidget {
  const PokedexHome({super.key, required this.title});

  final String title;

  @override
  State<StatefulWidget> createState() => _PokedexHomeState();
}

class _PokedexHomeState extends State<PokedexHome> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _isLoadingMore = false;
  final ValueNotifier<bool> _showBackToTopButton = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
              _scrollController.position.maxScrollExtent &&
          !_isLoadingMore) {
        setState(() {
          _isLoadingMore = true;
        });

        context.read<HomeViewModel>().loadMore().whenComplete(() {
          setState(() {
            _isLoadingMore = false;
          });
        });
      }

      final shouldShowButton = _scrollController.position.pixels > 200;
      if (_showBackToTopButton.value != shouldShowButton) {
        _showBackToTopButton.value = shouldShowButton;
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildSearchField(HomeViewModel viewModel) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        textInputAction: TextInputAction.search,
        onChanged: viewModel.onSearchChanged,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          hintText: 'Search Pokémon...',
          prefixIcon: const Icon(Icons.search, color: Colors.red),
          suffixIcon:
              _searchController.text.isNotEmpty
                  ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: () {
                      _searchController.clear();
                      viewModel.onSearchChanged('');
                      FocusScope.of(context).unfocus();
                    },
                  )
                  : null,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 15,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No Pokémon found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try a different search term',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              _searchController.clear();
              context.read<HomeViewModel>().onSearchChanged('');
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Clear Search'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(HomeViewModel viewModel) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: _buildSearchField(viewModel),
          ),

          Container(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.catching_pokemon,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Total: ${viewModel.totalPokemonCount} Pokémon(s)',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPokemonGridView(
    List<NamedAPIResource> displayedPokemon,
    HomeViewModel viewModel,
  ) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
      ),
      itemCount: displayedPokemon.length,
      itemBuilder: (context, index) {
        final resource = displayedPokemon[index];
        return PokemonGridItem(
          key: ValueKey(resource.url),
          resource: resource,
          viewModel: viewModel,
        );
      },
    );
  }

  Widget _buildActiveFilters(HomeViewModel viewModel) {
    if (viewModel.selectedTypes.isEmpty &&
        viewModel.selectedGenerations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (viewModel.selectedTypes.isNotEmpty) ...[
            const Text(
              'Types:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  viewModel.selectedTypes
                      .map(
                        (type) => Chip(
                          backgroundColor:
                              typeColors[type.name]?.withValues(alpha: 0.8) ??
                              Colors.grey,
                          label: Text(
                            type.name.capitalize(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          deleteIconColor: Colors.white,
                          onDeleted: () {
                            viewModel.removeTypeFilter(type);
                          },
                        ),
                      )
                      .toList(),
            ),
          ],

          if (viewModel.selectedGenerations.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              'Generations:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  viewModel.selectedGenerations.map((generation) {
                    final genName = generation.name;
                    final displayName =
                        genName.split('-').length == 2 &&
                                genName.startsWith('generation')
                            ? 'Generation ${genName.split('-')[1].toUpperCase()}'
                            : genName.capitalize();

                    return Chip(
                      backgroundColor: Colors.blueGrey.withValues(alpha: 0.8),
                      label: Text(
                        displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      deleteIconColor: Colors.white,
                      onDeleted: () {
                        viewModel.removeGenerationFilter(generation);
                      },
                    );
                  }).toList(),
            ),
          ],

          const SizedBox(height: 8),
          // Clear all button
          if (viewModel.selectedTypes.isNotEmpty ||
              viewModel.selectedGenerations.isNotEmpty)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.clear, size: 16),
                label: const Text('Clear All Filters'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(30, 30),
                ),
                onPressed: () => viewModel.clearFilters(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorMsg(HomeViewModel viewModel) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.red[300]),
            const SizedBox(height: 24),
            Text(
              'Something went wrong!',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              viewModel.errorMsg!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => viewModel.init(),
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.red,
        elevation: 0,
        title: Text(
          widget.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onPressed: () {
              final viewModel = context.read<HomeViewModel>();
              showDialog(
                context: context,
                builder:
                    (context) => TypeFilterDialog(
                      initialSelectedTypes: viewModel.selectedTypes,
                      initialSelectedGenerations: viewModel.selectedGenerations,
                    ),
              );
            },
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Consumer<HomeViewModel>(
          builder: (context, viewModel, _) {
            if (viewModel.isLoading) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    PokeballProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading Pokédex...'),
                  ],
                ),
              );
            }

            if (viewModel.errorMsg != null) {
              return _buildErrorMsg(viewModel);
            }

            return RefreshIndicator(
              onRefresh: () => viewModel.init(),
              color: Colors.red,
              child: ListView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  _buildHeader(viewModel),
                  if (viewModel.selectedTypes.isNotEmpty ||
                      viewModel.selectedGenerations.isNotEmpty)
                    _buildActiveFilters(viewModel),

                  // Display Pokemon grid or empty state
                  if (viewModel.displayedPokemon.isEmpty &&
                      _searchController.text.isNotEmpty)
                    SizedBox(
                      height: MediaQuery.of(context).size.height - 200,
                      child: _buildEmptyState(),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: _buildPokemonGridView(
                        viewModel.displayedPokemon,
                        viewModel,
                      ),
                    ),

                  // Loading indicator at the bottom
                  if (viewModel.isLoading)
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: PokeballProgressIndicator()),
                    ),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: ValueListenableBuilder<bool>(
        valueListenable: _showBackToTopButton,
        builder: (context, shouldShow, child) {
          return shouldShow
              ? FloatingActionButton(
                backgroundColor: Colors.red,
                child: const Icon(Icons.arrow_upward),
                onPressed: () {
                  _scrollController.animateTo(
                    0,
                    duration: const Duration(seconds: 1),
                    curve: Curves.easeInOut,
                  );
                },
              )
              : const SizedBox.shrink();
        },
      ),
    );
  }
}

class PokemonGridItem extends StatefulWidget {
  final NamedAPIResource resource;
  final HomeViewModel viewModel;

  const PokemonGridItem({
    super.key,
    required this.resource,
    required this.viewModel,
  });

  @override
  State<StatefulWidget> createState() => _PokemonGridItemState();
}

class _PokemonGridItemState extends State<PokemonGridItem> {
  Future<Pokemon>? _pokemonFuture;

  @override
  void initState() {
    super.initState();

    _pokemonFuture = widget.viewModel.repository.getPokemonDetailsByUrl(
      widget.resource.url,
    );
  }

  Color _getTypeColor(String type) {
    return typeColors[type.toLowerCase()] ?? Colors.grey;
  }

  Widget _buildPokemonCard(Pokemon pokemon) {
    final primaryType =
        pokemon.types.isNotEmpty ? pokemon.types[0].type.name : 'normal';
    final cardColor = _getTypeColor(primaryType).withValues(alpha: 0.2);
    final imageUrl =
        pokemon.sprites.frontDefault ??
        pokemon.sprites.other.home.frontDefault ??
        '';

    return Material(
      color: Colors.transparent,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [cardColor, Colors.white],
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => PokemonDetails(pokemon),
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ID badge
                Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.1),
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(16),
                        bottomLeft: Radius.circular(8),
                      ),
                    ),
                    child: Text(
                      '#${pokemon.id.toString().padLeft(4, '0')}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ),

                // Pokemon image
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Hero(
                      tag: 'pokemon-${pokemon.id}',
                      transitionOnUserGestures: true,
                      child: _buildPokemonImage(imageUrl),
                    ),
                  ),
                ),

                // Pokemon name and types
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pokemon.formattedName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children:
                            pokemon.types
                                .take(2)
                                .map((type) => _buildTypeChip(type.type.name))
                                .toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChip(String type) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _getTypeColor(type),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        type.capitalize(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPokemonImage(String imageUrl) {
    if (imageUrl.isEmpty) {
      return const Center(
        child: Icon(Icons.catching_pokemon, size: 50, color: Colors.black26),
      );
    }

    if (imageUrl.endsWith('.svg')) {
      return SvgPicture.network(
        imageUrl,
        placeholderBuilder:
            (_) => const Center(child: PokeballProgressIndicator()),
        errorBuilder:
            (_, _, _) => const PokemonErrorCard(
              message: 'Image not available',
              compact: true,
            ),
      );
    } else {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.contain,
        placeholder: (_, _) => const Center(child: PokeballProgressIndicator()),
        errorWidget:
            (_, _, _) => const PokemonErrorCard(
              message: 'Image not available',
              compact: true,
            ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _pokemonFuture,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return _buildPokemonCard(snapshot.data!);
        } else if (snapshot.hasError) {
          logger.e(
            "Error loading pokemon data: ${widget.resource.url}",
            error: snapshot.error,
            stackTrace: snapshot.stackTrace,
          );
          return PokemonErrorCard(
            message: 'Error loading pokémon',
            onRetry: () {
              logger.i("Retrying loading pokémon: ${widget.resource.url}");
              setState(() {
                _pokemonFuture = widget.viewModel.repository
                    .getPokemonDetailsByUrl(widget.resource.url);
              });
            },
          );
        }
        return const PokemonLoadingCard();
      },
    );
  }
}

class PokemonLoadingCard extends StatelessWidget {
  const PokemonLoadingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const PokeballProgressIndicator(),
              const SizedBox(height: 12),
              Text(
                'Loading...',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PokemonErrorCard extends StatelessWidget {
  final String message;
  final bool compact;
  final Function()? onRetry;

  const PokemonErrorCard({
    super.key,
    this.message = "Failed to load Pokémon!",
    this.compact = false,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Center(
        child: Icon(Icons.broken_image, size: 30, color: Colors.grey[400]),
      );
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.red[300], size: 40),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(100, 36),
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
