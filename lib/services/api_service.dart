import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/producto.dart';

class ApiService {
  final String apiUrl = "http://127.0.0.1:3000/productos";
  
  // Credenciales de autenticación
  final String username = "admin";
  final String password = "secret";

  // Función para crear el encabezado de autorización
  Map<String, String> _createAuthHeader() {
    String basicAuth = 'Basic ' + base64Encode(utf8.encode('$username:$password'));
    return {
      'Content-Type': 'application/json',
      'Authorization': basicAuth,
    };
  }

  // Obtener la lista de productos
  Future<List<Producto>> getProductos() async {
    final response = await http.get(
      Uri.parse(apiUrl),
      headers: _createAuthHeader(),
    );
    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
      return jsonResponse.map((producto) => Producto.fromJson(producto)).toList();
    } else {
      throw Exception('Error al cargar productos');
    }
  }

  // Agregar un nuevo producto
  Future<Producto> addProducto(Producto producto) async {
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: _createAuthHeader(),
      body: jsonEncode(producto.toJson()),
    );
    if (response.statusCode == 201) {
      return Producto.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Error al agregar producto');
    }
  }

  // Método para eliminar un producto
  Future<void> deleteProducto(int id) async {
    final response = await http.delete(
      Uri.parse('$apiUrl/$id'),
      headers: _createAuthHeader(),
    );

    if (response.statusCode != 204) { // 204 es el código HTTP para "No Content", lo esperado en DELETE
      throw Exception('Error al eliminar el producto');
    }
  }


  // Método para actualizar un producto
  Future<Producto> updateProducto(int id, Producto producto) async {
    final response = await http.put(
      Uri.parse('$apiUrl/$id'),
      headers: _createAuthHeader(),
      body: jsonEncode(producto.toJson()),
    );

    if (response.statusCode == 200) {
      return Producto.fromJson(json.decode(response.body));
    } else {
      throw Exception('Error al actualizar el producto');
    }
  }

}
