/// sedes
class Branch {
  const Branch({required this.id, required this.name, required this.address});

  final String id;
  final String name;
  final String address;
}

/// servicios_medicos
class MedicalService {
  const MedicalService({
    required this.id,
    required this.name,
    required this.durationMin,
    required this.basePrice,
    this.currency = 'USD',
  });

  final String id;
  final String name;
  final int durationMin;
  final double basePrice;
  final String currency;
}

/// tipos_prueba_laboratorio
class LabTestType {
  const LabTestType({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    this.defaultUnit,
  });

  final String id;
  final String code;
  final String name;
  final String? description;
  final String? defaultUnit;
}

/// Public information about the laboratory.
class Catalog {
  const Catalog({required this.branches, required this.services, required this.testTypes});

  final List<Branch> branches;
  final List<MedicalService> services;
  final List<LabTestType> testTypes;
}
