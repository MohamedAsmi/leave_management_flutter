import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:leave_management/data/models/duty_type_model.dart';
import 'package:leave_management/data/services/duty_type_service.dart';

class DutyTypeProvider with ChangeNotifier {
  final DutyTypeService _dutyTypeService;
  List<DutyType> _dutyTypes = [];
  bool _isLoading = false;

  DutyTypeProvider(this._dutyTypeService);

  List<DutyType> get dutyTypes => _dutyTypes;
  bool get isLoading => _isLoading;

  Future<void> fetchAndCacheDutyTypes() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Fetch from API
      final types = await _dutyTypeService.getDutyTypes();
      
      // 2. Save to Hive
      final box = Hive.box<DutyType>('duty_types');
      await box.clear();
      await box.addAll(types);

      // 3. Update State
      _dutyTypes = types;
    } catch (e) {
      debugPrint('Error fetching duty types: $e');
      // If fetch fails, try to load from cache
      loadFromCache();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void loadFromCache() {
    try {
      final box = Hive.box<DutyType>('duty_types');
      _dutyTypes = box.values.toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading cached duty types: $e');
    }
  }
}
