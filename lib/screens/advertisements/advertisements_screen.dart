import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/advertisement_provider.dart';
import '../../models/advertisement_model.dart';
import 'advertisement_detail_screen.dart';

class AdvertisementsScreen extends StatefulWidget {
  const AdvertisementsScreen({super.key});

  @override
  State<AdvertisementsScreen> createState() => _AdvertisementsScreenState();
}

class _AdvertisementsScreenState extends State<AdvertisementsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdvertisementProvider>(context, listen: false)
          .loadAdvertisements();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advertisements'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search advertisements...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          Provider.of<AdvertisementProvider>(context,
                                  listen: false)
                              .loadAdvertisements();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                if (value.isEmpty) {
                  Provider.of<AdvertisementProvider>(context, listen: false)
                      .loadAdvertisements();
                }
              },
              onSubmitted: (value) {
                Provider.of<AdvertisementProvider>(context, listen: false)
                    .loadAdvertisements(search: value);
              },
            ),
          ),
          Expanded(
            child: Consumer<AdvertisementProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          provider.error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            provider.loadAdvertisements();
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (provider.advertisements.isEmpty) {
                  return const Center(
                    child: Text('No advertisements found'),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    await provider.loadAdvertisements();
                  },
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: provider.advertisements.length,
                    itemBuilder: (context, index) {
                      final advertisement = provider.advertisements[index];
                      return _AdvertisementCard(advertisement: advertisement);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AdvertisementCard extends StatelessWidget {
  final AdvertisementModel advertisement;

  const _AdvertisementCard({required this.advertisement});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AdvertisementDetailScreen(
                advertisementId: advertisement.id,
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: advertisement.productImage != null
                  ? Image.network(
                      advertisement.productImage!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.image, size: 48),
                        );
                      },
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.image, size: 48),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    advertisement.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${advertisement.registeredAgentsCount}/${advertisement.maxAgents}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '${advertisement.commissionPercentage}%',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

