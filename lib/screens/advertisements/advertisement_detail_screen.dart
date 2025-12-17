import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/providers/advertisement_provider.dart';
import '../../models/advertisement_model.dart';
import '../../models/agent_model.dart';
import 'register_agent_screen.dart';

class AdvertisementDetailScreen extends StatefulWidget {
  final int advertisementId;

  const AdvertisementDetailScreen({
    super.key,
    required this.advertisementId,
  });

  @override
  State<AdvertisementDetailScreen> createState() => _AdvertisementDetailScreenState();
}

class _AdvertisementDetailScreenState extends State<AdvertisementDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdvertisementProvider>(context, listen: false)
          .loadAdvertisement(widget.advertisementId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advertisement Details'),
      ),
      body: Consumer<AdvertisementProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final advertisement = provider.selectedAdvertisement;
          if (advertisement == null) {
            return const Center(child: Text('Advertisement not found'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (advertisement.productImage != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      advertisement.productImage!,
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200,
                          color: Colors.grey[300],
                          child: const Icon(Icons.image, size: 64),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  advertisement.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (advertisement.description != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    advertisement.description!,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
                const SizedBox(height: 24),
                _buildInfoCard(advertisement),
                const SizedBox(height: 24),
                if (advertisement.qrCode != null) _buildQRCodeCard(advertisement),
                const SizedBox(height: 24),
                _buildAgentsSection(provider.agents),
              ],
            ),
          );
        },
      ),
      floatingActionButton: Consumer<AdvertisementProvider>(
        builder: (context, provider, child) {
          final advertisement = provider.selectedAdvertisement;
          if (advertisement == null) return const SizedBox.shrink();

          return FloatingActionButton.extended(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => RegisterAgentScreen(
                    advertisementId: advertisement.id,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.person_add),
            label: const Text('Add Agent'),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(AdvertisementModel advertisement) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildInfoRow('Max Agents', '${advertisement.maxAgents}'),
            const Divider(),
            _buildInfoRow('Registered', '${advertisement.registeredAgentsCount}'),
            const Divider(),
            _buildInfoRow('Remaining Slots', '${advertisement.remainingSlots}'),
            const Divider(),
            _buildInfoRow('Commission', '${advertisement.commissionPercentage}%'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey[600]),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRCodeCard(AdvertisementModel advertisement) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'QR Code for Agent Registration',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            QrImageView(
              data: advertisement.qrCode!,
              version: QrVersions.auto,
              size: 200.0,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgentsSection(List<AgentModel> agents) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Registered Agents',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (agents.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(
                child: Text('No agents registered yet'),
              ),
            ),
          )
        else
          ...agents.map((agent) => _buildAgentCard(agent)),
      ],
    );
  }

  Widget _buildAgentCard(AgentModel agent) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(agent.name[0].toUpperCase()),
        ),
        title: Text(agent.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (agent.email != null) Text(agent.email!),
            if (agent.phone != null) Text(agent.phone!),
            Text('Referrals: ${agent.totalReferrals}'),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${agent.commissionEarned.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: agent.status == 'active' ? Colors.green : Colors.grey,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                agent.status.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
