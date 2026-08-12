import 'package:fund_nexus/core/network/api_client.dart';
import 'package:fund_nexus/core/network/api_signature.dart';
import 'package:fund_nexus/features/home/data/home_data.dart';

class HomeRepository {
  HomeRepository({required this.apiClient});

  final ApiClient apiClient;

  Future<HomeData> fetchHome() async {
    final response = await apiClient.get<HomeData>(
      '/viler/foresight',
      queryParameters: {
        'ever': ApiSignature.randomDigits(6),
        'rarefiers': ApiSignature.randomDigits(6),
      },
      decode: HomeData.fromJson,
    );
    return response.data;
  }
}
