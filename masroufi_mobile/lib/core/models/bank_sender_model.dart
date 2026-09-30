class BankSender {
  final String name;
  final String senderId;
  final bool isCustom;

  const BankSender({
    required this.name,
    required this.senderId,
    this.isCustom = false,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'senderId': senderId,
    'isCustom': isCustom,
  };

  factory BankSender.fromJson(Map<String, dynamic> json) => BankSender(
    name: json['name'] as String? ?? '',
    senderId: json['senderId'] as String? ?? '',
    isCustom: json['isCustom'] as bool? ?? false,
  );
}
