class PhilippineSchool {
  final String name;
  final String logoUrl;
  final String id;
  final String affiliatedHospital;
  final String supportContact;

  const PhilippineSchool({
    required this.name,
    required this.logoUrl,
    required this.id,
    required this.affiliatedHospital,
    required this.supportContact,
  });
}

class AppSchools {
  AppSchools._();

  static const List<PhilippineSchool> capizNursingSchools = [
    PhilippineSchool(
      id: 'fcu',
      name: 'Filamer Christian University, Inc.',
      logoUrl: 'https://upload.wikimedia.org/wikipedia/en/b/b3/Filamer_Christian_University_logo.png',
      affiliatedHospital: 'Capiz Emmanuel Hospital',
      supportContact: 'College of Nursing Office',
    ),
    PhilippineSchool(
      id: 'uph',
      name: 'University of Perpetual Help System Pueblo de Panay Campus',
      logoUrl: 'https://upload.wikimedia.org/wikipedia/en/thumb/f/f1/University_of_Perpetual_Help_System_DALTA_logo.svg/1200px-University_of_Perpetual_Help_System_DALTA_logo.svg.png',
      affiliatedHospital: 'UPH Designated Clinical Hospital',
      supportContact: 'Guidance and Counseling Center',
    ),
    PhilippineSchool(
      id: 'sacri',
      name: 'St. Anthony College of Roxas City, Inc.',
      logoUrl: 'https://upload.wikimedia.org/wikipedia/en/a/ad/St._Anthony_College_of_Roxas_City_logo.png',
      affiliatedHospital: 'St. Anthony College Hospital',
      supportContact: 'Student Affairs Office',
    ),
    PhilippineSchool(
      id: 'csj',
      name: 'College of St. John - Roxas',
      logoUrl: 'https://upload.wikimedia.org/wikipedia/en/thumb/d/d4/College_of_St._John_%28Roxas%29_logo.png/150px-College_of_St._John_%28Roxas%29_logo.png',
      affiliatedHospital: 'CSJ Designated Clinical Partner',
      supportContact: 'Student Support Services',
    ),
  ];

  static const List<String> yearLevels = [
    '1st Year',
    '2nd Year',
    '3rd Year',
    '4th Year',
  ];
}
