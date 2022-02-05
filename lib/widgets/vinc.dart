import 'package:meta/meta.dart';
import '../models/manufacturers.dart';
import './nhtsa_model.dart';
import '../models/year_map.dart';

class VINC {
  /// The VIN that the class was instantiated with.
  final String number;

  /// The World Manufacturer Identifier (WMI) code for the specified [number].
  final String wmi;

  /// The Vehicle Descriptor Section (VDS) code for the specified [number].
  final String vds;

  /// The Vehicle Identifier Section (VIS) code for the specified [number].
  final String vis;

  /// Try to obtain extended information for the VIN from the NHTSA database.
  final bool extended;
  ExtendedVehicleInfo _info;

  VINC({@required this.number, this.extended = false})
      : wmi = normalize(number).substring(0, 3),
        vds = normalize(number).substring(3, 9),
        vis = normalize(number).substring(9, 17);

  /// Carry out VIN validation. A valid [number] must be 17 characters long
  /// and contain only valid alphanumeric characters.
  bool valid([String number]) {
    String value = normalize(number != null ? number : this.number);
    return RegExp(r"^[a-zA-Z0-9]+$").hasMatch(value) && value.length == 17;
  }

  /// Provide a normalized VIN string, regardless of the input format.
  static String normalize(String number) =>
      number.toUpperCase().replaceAll('-', '');

  /// Obtain the encoded manufacturing year in YYYY format.
  int getYear() {
    return yearMap[modelYear()];
  }

  /// Obtain the 2-character region code for the manufacturing region.
  String getRegion() {
    if (RegExp(r"[A-H]", caseSensitive: false).hasMatch(this.number[0])) {
      return "AF";
    }
    if (RegExp(r"[J-R]", caseSensitive: false).hasMatch(this.number[0])) {
      return "AS";
    }
    if (RegExp(r"[S-Z]", caseSensitive: false).hasMatch(this.number[0])) {
      return "EU";
    }
    if (RegExp(r"[1-5]", caseSensitive: false).hasMatch(this.number[0])) {
      return "NA";
    }
    if (RegExp(r"[6-7]", caseSensitive: false).hasMatch(this.number[0])) {
      return "OC";
    }
    if (RegExp(r"[8-9]", caseSensitive: false).hasMatch(this.number[0])) {
      return "SA";
    }
    return "Unknown";
  }

  /// Get the full name of the vehicle manufacturer as defined by the [wmi].
  String getManufacturer() {
    if (manufacturers.containsKey(this.wmi)) {
      return manufacturers[this.wmi];
    } else {
      return "Unknown (WMI: ${this.wmi.toUpperCase()})";
    }
  }

  /// Returns the checksum for the VIN. Note that in the case of the EU region
  /// checksums are not implemented, so this becomes a no-op. More information
  /// is provided in ISO 3779:2009.
  String getChecksum() {
    return (getRegion() != "EU") ? normalize(this.number)[8] : null;
  }

  /// Extract the single-character model year from the [number].
  String modelYear() => normalize(this.number)[9];

  /// Extract the single-character assembly plant designator from the [number].
  String assemblyPlant() => normalize(this.number)[10];

  /// Extract the serial number from the [number].
  String serialNumber() => normalize(this.number).substring(12, 17);

  void _fetchExtendedVehicleInfo() async {
    if (this._info == null && extended == true) {
      this._info =
          await ExtendedVehicleInfo.getExtendedVehicleInfo(this.number);
      print('data - ${this._info}');
    }
  }

  /// Get the Make of the vehicle from the NHTSA database if [extended] mode
  /// is enabled.
  Future<String> getMakeAsync() async {
    await _fetchExtendedVehicleInfo();
    print('makkkkee - ${this._info.make}');
    return this._info?.make;
  }

  /// Get the Model of the vehicle from the NHTSA database if [extended] mode
  /// is enabled.
  Future<String> getModelAsync() async {
    await _fetchExtendedVehicleInfo();
    return this._info?.model;
  }

  /// Get the Vehicle Type from the NHTSA database if [extended] mode is
  /// enabled.
  Future<String> getVehicleTypeAsync() async {
    await _fetchExtendedVehicleInfo();
    return this._info?.vehicleType;
  }

  /// Get the Engine Number of Cylinders from the NHTSA database if [extended] mode is
  /// enabled.
  Future<String> getEngineNumberofCylindersAsync() async {
    await _fetchExtendedVehicleInfo();
    return this._info?.engineNumberofCylinders;
  }

  /// Get the Active Safety System Note from the NHTSA database if [extended] mode is
  /// enabled.
  Future<String> getActiveSafetySystemNoteAsync() async {
    await _fetchExtendedVehicleInfo();
    return this._info?.activeSafetySystemNote;
  }

  /// Get the Transmission Style from the NHTSA database if [extended] mode is
  /// enabled.
  Future<String> getTransmissionStyleAsync() async {
    await _fetchExtendedVehicleInfo();
    return this._info?.transmissionStyle;
  }

  /// Get the Steering Location from the NHTSA database if [extended] mode is
  /// enabled.
  Future<String> getSteeringLocationAsync() async {
    await _fetchExtendedVehicleInfo();
    return this._info?.steeringLocation;
  }

  /// Get the Fuel Type Primary from the NHTSA database if [extended] mode is
  /// enabled.
  Future<String> getFuelTypePrimaryAsync() async {
    await _fetchExtendedVehicleInfo();
    return this._info?.fuelTypePrimary;
  }

  /// Get the Trim from the NHTSA database if [extended] mode is
  /// enabled.
  Future<String> getTrimAsync() async {
    await _fetchExtendedVehicleInfo();
    return this._info?.trim;
  }

  /// Get the Drive Type from the NHTSA database if [extended] mode is
  /// enabled.
  Future<String> getDriveTypeAsync() async {
    await _fetchExtendedVehicleInfo();
    return this._info?.driveType;
  }

  /// Get the Body Type from the NHTSA database if [extended] mode is
  /// enabled.
  Future<String> getBodyTypeAsync() async {
    await _fetchExtendedVehicleInfo();
    return this._info?.bodyType;
  }

  /// Get the Displacement (L) from the NHTSA database if [extended] mode is
  /// enabled.
  Future<String> getDisplacementLAsync() async {
    await _fetchExtendedVehicleInfo();
    return this._info?.displacementL;
  }

  @override
  String toString() => this.wmi + this.vds + this.vis;
}
