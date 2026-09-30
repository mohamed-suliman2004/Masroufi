class CountryCode {
  final String name;
  final String code;
  final String flag;
  final String hint;
  final int expectedLength;

  const CountryCode({
    required this.name,
    required this.code,
    required this.flag,
    required this.hint,
    this.expectedLength = 9,
  });
}

const List<CountryCode> supportedCountries = [
  CountryCode(name: 'ليبيا', code: '+218', flag: '🇱🇾', hint: '91 357 8201', expectedLength: 9),
  CountryCode(name: 'تونس', code: '+216', flag: '🇹🇳', hint: '20 123 456', expectedLength: 8),
  CountryCode(name: 'مصر', code: '+20', flag: '🇪🇬', hint: '10 1234 5678', expectedLength: 10),
  CountryCode(name: 'الجزائر', code: '+213', flag: '🇩🇿', hint: '55 123 4567', expectedLength: 9),
  CountryCode(name: 'المغرب', code: '+212', flag: '🇲🇦', hint: '61 234 5678', expectedLength: 9),
  CountryCode(name: 'السعودية', code: '+966', flag: '🇸🇦', hint: '50 123 4567', expectedLength: 9),
  CountryCode(name: 'الإمارات', code: '+971', flag: '🇦🇪', hint: '50 123 4567', expectedLength: 9),
  CountryCode(name: 'تركيا', code: '+90', flag: '🇹🇷', hint: '501 234 5678', expectedLength: 10),
  CountryCode(name: 'بريطانيا', code: '+44', flag: '🇬🇧', hint: '7911 123456', expectedLength: 10),
  CountryCode(name: 'أمريكا', code: '+1', flag: '🇺🇸', hint: '202 555 0123', expectedLength: 10),
];
