import 'package:flutter/foundation.dart';
import '../api/api_service.dart';
import '../../models/advertisement_model.dart';
import '../../models/agent_model.dart';

class AdvertisementProvider with ChangeNotifier {
  final ApiService _apiService = ApiService.instance;

  List<AdvertisementModel> _advertisements = [];
  AdvertisementModel? _selectedAdvertisement;
  List<AgentModel> _agents = [];
  bool _isLoading = false;
  String? _error;

  List<AdvertisementModel> get advertisements => _advertisements;
  AdvertisementModel? get selectedAdvertisement => _selectedAdvertisement;
  List<AgentModel> get agents => _agents;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadAdvertisements({String? search}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.getAdvertisements(search: search);
      if (response['success'] == true) {
        _advertisements = (response['data'] as List)
            .map((json) => AdvertisementModel.fromJson(json))
            .toList();
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAdvertisement(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.getAdvertisement(id);
      if (response['success'] == true) {
        _selectedAdvertisement = AdvertisementModel.fromJson(response['data']);
        await loadAgents(id);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAgents(int advertisementId) async {
    try {
      final response = await _apiService.getAgents(advertisementId);
      if (response['success'] == true) {
        _agents = (response['data'] as List)
            .map((json) => AgentModel.fromJson(json))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<bool> registerAgent({
    required int advertisementId,
    required String name,
    String? email,
    String? phone,
  }) async {
    try {
      final response = await _apiService.registerAgent(
        advertisementId: advertisementId,
        name: name,
        email: email,
        phone: phone,
      );

      if (response['success'] == true) {
        await loadAgents(advertisementId);
        await loadAdvertisements();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateAgent(int id, Map<String, dynamic> data) async {
    try {
      final response = await _apiService.updateAgent(id, data);
      if (response['success'] == true) {
        if (_selectedAdvertisement != null) {
          await loadAgents(_selectedAdvertisement!.id);
        }
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAgent(int id) async {
    try {
      await _apiService.deleteAgent(id);
      if (_selectedAdvertisement != null) {
        await loadAgents(_selectedAdvertisement!.id);
      }
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

