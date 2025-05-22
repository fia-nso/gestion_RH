// import 'dart:convert';
// import 'dart:io';

// class ApiFetcher {
//   HttpClient client;

//     String? accessToken;
//   String? refreshToken;

//   ApiFetcher() : client = HttpClient();

//   Future<FetcherResponse> get(String url) async {
//     // client url API_URL + / + url
//     url = Uri.parse("http://127.0.0.1:3000/$url") as String;
//     // http://127.0.0.1:3000/url
//     try {
//             final request = await client.getUrl(url as Uri);
//       request.headers.set(HttpHeaders.contentTypeHeader, "application/json");
//       if (accessToken != null) {
//         request.headers.set(HttpHeaders.authorizationHeader, "Bearer $accessToken");
//       }

//       final response = await request.close();
//       final responseBody = await response.transform(utf8.decoder).join();

//       return FetcherResponse(
//         status: response.statusCode,
//         url: url.toString(),
//         data: jsonDecode(responseBody),
//         error: response.statusCode >= 400 ? responseBody : null,
//       );

//     } catch (e) {

//     }

//     // add refresh token and access token

// client.get('localhost', 3000, 'path');

//   }
//   Future<FetcherResponse> post() async {}
// }

// //Model: FetcherResponse url, status, data<T>

// ApiFetcher().post('user', object);

// class FetcherResponse<T> {
//   final int status;
//   final String url;
//   final T? data;
//   final String? error;

//   FetcherResponse({
//     required this.status,
//     required this.url,
//     this.data,
//     this.error,
//   });

//   bool get isSuccess => status >= 200 && status < 300;
// }

// import 'dart:convert';

// import 'dart:io';
// import 'package:http/http.dart' as http;

// class ApiFetcher {
//   final String baseUrl = "http://localhost:3000"; // Replace with your URL
//   String? accessToken;
//   String? refreshToken;

//   ApiFetcher({this.accessToken, this.refreshToken});

//   Future<FetcherResponse> get(String path) async {
//     final url = Uri.parse('$baseUrl/$path');
//     final client = HttpClient();

//     try {
//       final request = await client.getUrl(url);
//       request.headers.set(HttpHeaders.contentTypeHeader, "application/json");
//       if (accessToken != null) {
//         request.headers
//             .set(HttpHeaders.authorizationHeader, "Bearer $accessToken");
//       }

//       final response = await request.close();
//       final responseBody = await response.transform(utf8.decoder).join();

//       return FetcherResponse(
//         status: response.statusCode,
//         url: url.toString(),
//         data: jsonDecode(responseBody),
//         error: response.statusCode >= 400 ? responseBody : null,
//       );
//     } catch (e) {
//       return FetcherResponse(
//         status: 0,
//         url: path,
//         error: e.toString(),
//       );
//     } finally {
//       client.close();
//     }
//   }

//   Future<FetcherResponse> post(String path, Map<String, dynamic> body) async {
//     final url = Uri.parse('$baseUrl/$path');
//     final client = HttpClient();

//     try {
//       final request = await client.postUrl(url);
//       request.headers.set(HttpHeaders.contentTypeHeader, "application/json");
//       if (accessToken != null) {
//         request.headers
//             .set(HttpHeaders.authorizationHeader, "Bearer $accessToken");
//       }

//       request.write(jsonEncode(body));

//       final response = await request.close();
//       final responseBody = await response.transform(utf8.decoder).join();

//       return FetcherResponse(
//         status: response.statusCode,
//         url: url.toString(),
//         data: jsonDecode(responseBody),
//         error: response.statusCode >= 400 ? responseBody : null,
//       );
//     } catch (e) {
//       return FetcherResponse(
//         status: 0,
//         url: path,
//         error: e.toString(),
//       );
//     } finally {
//       client.close();
//     }
//   }
// }

// class FetcherResponse<T> {
//   final int status;
//   final String url;
//   final T? data;
//   final String? error;

//   FetcherResponse({
//     required this.status,
//     required this.url,
//     this.data,
//     this.error,
//   });

//   bool get isSuccess => status >= 200 && status < 300;
// }

import 'dart:convert';
import 'package:dio/browser.dart';
import 'package:dio/dio.dart';

class ApiFetcher {
  final String baseUrl = "https://02cf-41-188-117-99.ngrok-free.app";
  String? accessToken;
  String? refreshToken;

  ApiFetcher({this.accessToken, this.refreshToken});

  Future<FetcherResponse> get(String path) async {
    final dio = Dio();

    dio
      ..httpClientAdapter = BrowserHttpClientAdapter()
      ..options.baseUrl = baseUrl
      ..options.headers = {
        'Content-Type': 'application/json',
        'ngrok-skip-browser-warning': 'aby',
        if (accessToken != null) 'Authorization': 'Bearer $accessToken',
      };

    try {
      final response = await dio.get('/$path');

      final responseBody = response.data;

      return FetcherResponse(
        status: response.statusCode ?? 200,
        url: '',
        data: _tryDecodeJson(responseBody),
        error: response.statusCode == 200 ? responseBody : null,
      );
    } catch (e) {
      return FetcherResponse(
        status: 0,
        url: path,
        error: e.toString(),
      );
    }
  }

  Future<FetcherResponse> post(String path, Map<String, dynamic> body) async {
    final dio = Dio();

    dio
      ..httpClientAdapter = BrowserHttpClientAdapter()
      ..options.baseUrl = baseUrl
      ..options.headers = {
        'Content-Type': 'application/json',
        'ngrok-skip-browser-warning': 'aby',
        if (accessToken != null) 'Authorization': 'Bearer $accessToken',
      };

    try {
      final response = await dio.post('/$path');

      print(
          'Received response: status ${response.statusCode}, body ${response.data}');
      final responseBody = response.data;
      print('Decoding response body: $responseBody');

      return FetcherResponse(
        status: response.statusCode ?? 400,
        url: '',
        data: _tryDecodeJson(responseBody) as dynamic,
        error: response.statusCode == 200 ? responseBody : null,
      );
    } catch (e, stackTrace) {
      print('POST request failed: $e');
      print('Stack trace: $stackTrace');
      return FetcherResponse(
        status: 0,
        url: path,
        error: e.toString(),
      );
    }
  }

  dynamic _tryDecodeJson(String source) {
    try {
      return jsonDecode(source);
    } catch (_) {
      return source; // fallback to raw string if not JSON
    }
  }
}

class FetcherResponse<T> {
  final int status;
  final String url;
  final T? data;
  final String? error;

  FetcherResponse({
    required this.status,
    required this.url,
    this.data,
    this.error,
  });

  bool get isSuccess => status >= 200 && status < 300;
}
