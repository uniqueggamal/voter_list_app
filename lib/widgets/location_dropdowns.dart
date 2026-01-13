import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

/// LocationDropdownsWidget provides five dependent dropdowns for Province, District, Municipality, Ward, and Booth.
/// It loads location data directly from JSON assets.
class LocationDropdownsWidget extends StatefulWidget {
  const LocationDropdownsWidget({super.key});

  @override
  State<LocationDropdownsWidget> createState() =>
      _LocationDropdownsWidgetState();
}

class _LocationDropdownsWidgetState extends State<LocationDropdownsWidget> {
  Map<String, dynamic> _locationData = {};
  bool _isLoading = true;
  String? _selectedProvince;
  String? _selectedDistrict;
  String? _selectedMunicipality;
  Map<String, dynamic>? _selectedWard;
  Map<String, dynamic>? _selectedBooth;

  @override
  void initState() {
    super.initState();
    _loadLocationData();
  }

  Future<void> _loadLocationData() async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/location_data.json',
      );
      _locationData = json.decode(jsonString);
    } catch (e) {
      debugPrint('Error loading location data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Location Selection',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Province Dropdown
        DropdownButtonFormField<String>(
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Province',
            border: OutlineInputBorder(),
          ),
          value: _selectedProvince,
          items: _locationData.keys.map((province) {
            return DropdownMenuItem<String>(
              value: province,
              child: Text(province),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedProvince = value;
              _selectedDistrict = null;
              _selectedMunicipality = null;
              _selectedWard = null;
              _selectedBooth = null;
            });
          },
        ),

        const SizedBox(height: 16),

        // District Dropdown
        DropdownButtonFormField<String>(
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'District',
            border: OutlineInputBorder(),
          ),
          value: _selectedDistrict,
          items:
              (_selectedProvince == null
                      ? _locationData.values
                            .expand(
                              (province) => province['districts']?.keys ?? [],
                            )
                            .cast<String>()
                      : (_locationData[_selectedProvince]?['districts']?.keys ??
                                [])
                            .cast<String>())
                  .map((district) {
                    return DropdownMenuItem<String>(
                      value: district,
                      child: Text(district),
                    );
                  })
                  .toList(),
          onChanged: _selectedProvince == null
              ? null
              : (value) {
                  setState(() {
                    _selectedDistrict = value;
                    _selectedMunicipality = null;
                    _selectedWard = null;
                    _selectedBooth = null;
                  });
                },
        ),

        const SizedBox(height: 16),

        // Municipality Dropdown
        DropdownButtonFormField<String?>(
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Municipality',
            border: OutlineInputBorder(),
          ),
          value: _selectedMunicipality,
          items: [
            if (_selectedDistrict != null)
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('All Municipalities'),
              ),
            ...(_selectedDistrict == null
                    ? const <String>[]
                    : (_locationData[_selectedProvince]?['districts']?[_selectedDistrict]?['municipalities']
                              ?.keys ??
                          []))
                .map(
                  (municipality) => DropdownMenuItem<String?>(
                    value: municipality,
                    child: Text(municipality),
                  ),
                ),
          ],
          onChanged: _selectedDistrict == null
              ? null
              : (value) {
                  setState(() {
                    _selectedMunicipality = value;
                    _selectedWard = null;
                    _selectedBooth = null;
                  });
                },
        ),

        const SizedBox(height: 16),

        // Ward Dropdown
        DropdownButtonFormField<Map<String, dynamic>>(
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Ward',
            border: OutlineInputBorder(),
          ),
          value: _selectedWard,
          items: [
            if (_selectedMunicipality != null)
              const DropdownMenuItem<Map<String, dynamic>>(
                value: null,
                child: Text('All Wards'),
              ),
            ...(_selectedMunicipality == null
                    ? _locationData.values
                          .expand(
                            (province) => province['districts']?.values ?? [],
                          )
                          .expand(
                            (district) =>
                                district['municipalities']?.values ?? [],
                          )
                          .expand(
                            (municipality) =>
                                municipality['wards']?.values ?? [],
                          )
                          .map((ward) => ward as Map<String, dynamic>)
                    : _locationData.values
                          .expand(
                            (province) => province['districts']?.values ?? [],
                          )
                          .expand(
                            (district) =>
                                district['municipalities']?.entries ?? [],
                          )
                          .where(
                            (municipalityEntry) =>
                                municipalityEntry.key == _selectedMunicipality,
                          )
                          .expand(
                            (municipalityEntry) =>
                                municipalityEntry.value['wards']?.values ?? [],
                          )
                          .map((ward) => ward as Map<String, dynamic>))
                .map((ward) {
                  return DropdownMenuItem<Map<String, dynamic>>(
                    value: ward,
                    child: Text('Ward ${ward['ward_no']}'),
                  );
                }),
          ],
          onChanged: _selectedMunicipality == null
              ? null
              : (value) {
                  setState(() {
                    _selectedWard = value;
                    _selectedBooth = null;
                  });
                },
        ),

        const SizedBox(height: 16),

        // Booth Dropdown
        DropdownButtonFormField<Map<String, dynamic>>(
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Booth',
            border: OutlineInputBorder(),
          ),
          value: _selectedBooth,
          items: [
            if (_selectedWard != null)
              const DropdownMenuItem<Map<String, dynamic>>(
                value: null,
                child: Text('All Booths'),
              ),
            ...(_selectedWard == null || _selectedMunicipality == null
                    ? _locationData.values
                          .expand(
                            (province) => province['districts']?.values ?? [],
                          )
                          .expand(
                            (district) =>
                                district['municipalities']?.values ?? [],
                          )
                          .expand(
                            (municipality) =>
                                municipality['wards']?.values ?? [],
                          )
                          .expand(
                            (ward) =>
                                ward['booths'] as List<Map<String, dynamic>>,
                          )
                    : _locationData.values
                          .expand(
                            (province) => province['districts']?.values ?? [],
                          )
                          .expand(
                            (district) =>
                                district['municipalities']?.entries ?? [],
                          )
                          .where(
                            (municipalityEntry) =>
                                municipalityEntry.key == _selectedMunicipality,
                          )
                          .expand(
                            (municipalityEntry) =>
                                municipalityEntry.value['wards']?.entries ?? [],
                          )
                          .where(
                            (wardEntry) =>
                                wardEntry.value['ward_no'] ==
                                _selectedWard!['ward_no'],
                          )
                          .expand(
                            (wardEntry) =>
                                wardEntry.value['booths']
                                    as List<Map<String, dynamic>>,
                          ))
                .map((booth) {
                  return DropdownMenuItem<Map<String, dynamic>>(
                    value: booth,
                    child: Text(
                      '${booth['booth_code']} - ${booth['booth_name']}',
                    ),
                  );
                }),
          ],
          onChanged: _selectedWard == null
              ? null
              : (value) {
                  setState(() {
                    _selectedBooth = value;
                  });
                },
        ),

        const SizedBox(height: 16),

        // Display selected values
        if (_selectedProvince != null ||
            _selectedDistrict != null ||
            _selectedMunicipality != null ||
            _selectedWard != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selected Location:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (_selectedProvince != null)
                  Text('Province: $_selectedProvince'),
                if (_selectedDistrict != null)
                  Text('District: $_selectedDistrict'),
                if (_selectedMunicipality != null)
                  Text('Municipality: $_selectedMunicipality'),
                if (_selectedWard != null)
                  Text('Ward: ${_selectedWard!['ward_no']}'),
                if (_selectedBooth != null)
                  Text(
                    'Booth: ${_selectedBooth!['booth_code']} - ${_selectedBooth!['booth_name']}',
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
