import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

// Configure routes
final _router = Router()
  ..get('/', _rootHandler)
  ..get('/products', _getProductsHandler) // Route to serve products
  ..get('/static/<file>', _staticFileHandler); // Serve static files

// Root handler
Response _rootHandler(Request req) {
  return Response.ok('Hello, World!\n');
}

// Products handler
Response _getProductsHandler(Request req) {
  // Convert the data map to JSON and send as the response
  return Response.ok(jsonEncode(data), headers: {
    'Content-Type': 'application/json',
  });
}

// Static file handler
Response _staticFileHandler(Request request) {
  final fileName = request.params['file'];
  final file = File('public/$fileName'); // Ensure your images are in a "public" folder
  if (file.existsSync()) {
    return Response.ok(file.openRead(),
        headers: {'Content-Type': 'image/png'}); // Adjust MIME type if needed
  } else {
    return Response.notFound('File not found');
  }
}

void main(List<String> args) async {
  final ip = InternetAddress.anyIPv4;
  final handler = Pipeline().addMiddleware(logRequests()).addHandler(_router.call);

  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await serve(handler, ip, port);
  print('Server listening on port ${server.port}');
}

final data = {
  "1": {
    "name": "Big burger",
    "price": 8.99,
    "images": "static/big_burger.png",
  },
  "2": {
    "name": "Wendy's",
    "price": 5.00,
    "images": "static/wendys_burger.png",
  },
  "3": {
    "name": "Black burger",
    "price": 7.67,
    "images": "static/black_burger.png",
  },
  "4": {
    "name": "Hot Dog",
    "price": 3.50,
    "images": "static/hot_dog.png",
  }
};
